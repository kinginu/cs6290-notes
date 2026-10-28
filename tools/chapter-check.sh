#!/usr/bin/env bash
# Build one chapter on its own (subfiles) in the TeX Live container, then
# summarize problems and render the pages to PNG for visual inspection.
#
#   tools/chapter-check.sh <en|ja> <chapter-slug> [--no-render] [--max-moved N]
#   e.g. tools/chapter-check.sh en 04-branches
#
# --max-moved N  fail when more than N margin notes are moved down (default:
#                reported only).  A proofreading pass passes the chapter's
#                pre-edit count, so that an edit cannot crowd the margin more.
#
# Output PNGs: .png/<lang>-<slug>-NN.png   (git-ignored)
# Exit code: 0 = built and clean, 1 = LaTeX errors or reported problems,
# 2 = usage.  Memory cap: $CHAPTER_MEM (default 1500m).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
usage="usage: $0 <en|ja> <chapter-slug> [--no-render] [--max-moved N]"
lang=${1:-}; slug=${2:-}; render=1; summary_opts=()
shift 2 2>/dev/null || true
while [ $# -gt 0 ]; do
  case $1 in
    --no-render) render=0 ;;
    --max-moved)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "$usage" >&2; exit 2; }
      summary_opts=(--max-moved "$2"); shift ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
  shift
done
if [[ ! "$lang" =~ ^(en|ja)$ ]] || [ -z "$slug" ]; then
  echo "$usage" >&2; exit 2
fi
tex="$lang/lessons/$slug.tex"
[ -f "$root/$tex" ] || { echo "no such file: $tex" >&2; exit 2; }
mkdir -p "$root/.png"
rm -f "$root/$lang/lessons/build/$slug".{aux,bbl,bcf,idx,ind,ilg,log,pdf,toc,fdb_latexmk,fls,run.xml,out}

echo "== building $tex"
in_container "${CHAPTER_MEM:-1500m}" latexmk -cd "$tex" > "$root/.png/$lang-$slug.latexmk.txt" 2>&1
status=$?
log="$root/$lang/lessons/build/$slug.log"
pdf="$root/$lang/lessons/build/$slug.pdf"

python3 "$root/tools/log-summary.py" "$log" "$lang" "$slug" "${summary_opts[@]}"
clean=$?

if [ -f "$pdf" ] && [ $render = 1 ]; then
  rm -f "$root/.png/$lang-$slug-"*.png
  in_container 1000m gs -q -sDEVICE=png16m -r60 \
    -o "/work/.png/$lang-$slug-%02d.png" "/work/$lang/lessons/build/$slug.pdf"
  echo "== rendered: $(ls "$root/.png/$lang-$slug-"*.png | tr '\n' ' ')"
fi
if [ $status -ne 0 ] || [ ! -f "$pdf" ]; then
  echo "== latexmk exit status $status; tail of latexmk output:"
  tail -25 "$root/.png/$lang-$slug.latexmk.txt"
  exit 1
fi
exit $clean
