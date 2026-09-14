#!/usr/bin/env bash
# Build one chapter on its own (subfiles) in the TeX Live container, then
# summarize problems and render the pages to PNG for visual inspection.
#
#   tools/chapter-check.sh <en|ja> <lesson-slug> [--no-render]
#   e.g. tools/chapter-check.sh en 04-branches
#
# Output PNGs: .png/<lang>-<slug>-NN.png   (git-ignored)
# Exit code: 0 = PDF built without LaTeX errors, 1 = errors, 2 = usage.
set -uo pipefail
lang=${1:-}; slug=${2:-}; render=1
[ "${3:-}" = "--no-render" ] && render=0
if [[ ! "$lang" =~ ^(en|ja)$ ]] || [ -z "$slug" ]; then
  echo "usage: $0 <en|ja> <lesson-slug> [--no-render]" >&2; exit 2
fi
root=$(cd "$(dirname "$0")/.." && pwd)
tex="$lang/lessons/$slug.tex"
[ -f "$root/$tex" ] || { echo "no such file: $tex" >&2; exit 2; }
mkdir -p "$HOME/.cache/texmf-var-docker" "$root/.png"
rm -f "$root/$lang/lessons/build/$slug".{aux,bbl,bcf,idx,ind,ilg,log,pdf,toc,fdb_latexmk,fls,run.xml,out}

run() {
  timeout 900 docker run --rm -v "$root":/work -w /work -u "$(id -u):$(id -g)" \
    -e HOME=/home/texlive -e TEXMFVAR=/texmf-var \
    -v "$HOME/.cache/texmf-var-docker":/texmf-var \
    latex-lecture-notes:tl2025 "$@"
}

echo "== building $tex"
run latexmk -cd "$tex" > "$root/.png/$lang-$slug.latexmk.txt" 2>&1
status=$?
log="$root/$lang/lessons/build/$slug.log"
pdf="$root/$lang/lessons/build/$slug.pdf"

python3 - "$log" "$root" "$lang" "$slug" <<'PY'
import re, sys, os, glob
log, root, lang, slug = sys.argv[1:5]
if not os.path.exists(log):
    print("!! no log file produced"); sys.exit(0)
text = open(log, encoding='utf-8', errors='replace').read()
# LaTeX wraps log lines at 79 chars; join them back for matching
joined = re.sub(r'(?m)^(.{79})\n', r'\1', text)
errs = re.findall(r'(?m)^(?:\./|\.\./)?[^\s:]+\.tex:\d+: .*$|^! .*$', joined)
print(f"== errors: {len(errs)}")
for e in dict.fromkeys(errs): print("   ", e[:200])
undef = sorted(set(re.findall(r"Reference `([^']+)' on page \d+ undefined", joined)))
# labels defined in other chapters of the same edition are fine in a chapter build
defined_elsewhere = {}
for f in glob.glob(os.path.join(root, lang, 'lessons', '*.tex')):
    if os.path.basename(f) == slug + '.tex': continue
    for m in re.finditer(r'\\label\{([^}]+)\}', open(f, encoding='utf-8').read()):
        defined_elsewhere[m.group(1)] = os.path.basename(f)
really = [u for u in undef if u not in defined_elsewhere]
other = [f"{u} ({defined_elsewhere[u]})" for u in undef if u in defined_elsewhere]
print(f"== undefined references: {len(really)}" + (" -> " + ", ".join(really) if really else ""))
if other: print("   (defined in other chapters, OK: " + ", ".join(other) + ")")
cites = sorted(set(re.findall(r"Citation '([^']+)' on page \d+ undefined", joined)))
print(f"== undefined citations: {len(cites)}" + (" -> " + ", ".join(cites) if cites else ""))
multi = sorted(set(re.findall(r"Label `([^']+)' multiply defined", joined)))
print(f"== multiply-defined labels: {len(multi)}" + (" -> " + ", ".join(multi) if multi else ""))
miss = sorted(set(re.findall(r'Missing character: There is no (\S+)', joined)))
print(f"== missing glyphs: {len(miss)}" + (" -> " + " ".join(miss) if miss else ""))
over = re.findall(r'Overfull \\hbox \((\d+\.\d+)pt too wide\) (?:in paragraph|detected) at lines? (\d+)', joined)
big = [(float(w), l) for w, l in over if float(w) > 3.0]
print(f"== overfull hboxes > 3pt: {len(big)}" + ("" if not big else " -> " + ", ".join(f"line {l} ({w:.1f}pt)" for w, l in big[:15])))
moved = len(re.findall(r'Marginpar on page \d+ moved', joined))
print(f"== margin notes moved down (crowded margin): {moved}")
pages = re.findall(r'Output written on \S+ \((\d+) pages?', joined)
print(f"== pages: {pages[-1] if pages else '?'}")
PY

if [ -f "$pdf" ] && [ $render = 1 ]; then
  rm -f "$root/.png/$lang-$slug-"*.png
  run gs -q -sDEVICE=png16m -r60 -o "/work/.png/$lang-$slug-%02d.png" "/work/$lang/lessons/build/$slug.pdf"
  echo "== rendered: $(ls "$root/.png/$lang-$slug-"*.png | tr '\n' ' ')"
fi
if [ $status -ne 0 ] || [ ! -f "$pdf" ]; then
  echo "== latexmk exit status $status; tail of latexmk output:"; tail -25 "$root/.png/$lang-$slug.latexmk.txt"
  exit 1
fi
exit 0
