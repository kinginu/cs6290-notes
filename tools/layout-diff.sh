#!/usr/bin/env bash
# Compare the current build of one edition with the published PDF, page by
# page, to see what a class or layout change really moved.
#
#   tools/layout-diff.sh <en|ja> [<git ref>]      (default ref: origin/pdf)
#
# Run tools/book-check.sh <lang> first so <lang>/build/main.pdf is current.
# The reference PDF is notes-<lang>.pdf on the `pdf` branch that CI
# publishes, i.e. the last pushed state.  The text of every page is
# extracted (Ghostscript txtwrite) and compared with whitespace removed, so
# a pure horizontal shift is not reported but any change of line breaks,
# page breaks or running heads is.  Vertical moves of floats and margin notes
# without a text change are not detected: look at those pages.
# Exit code: 0 = no text differences, 1 = differences, 2 = usage/error.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
lang=${1:-}; ref=${2:-origin/pdf}
[[ "$lang" =~ ^(en|ja)$ ]] || { echo "usage: $0 <en|ja> [<git ref>]" >&2; exit 2; }
new="$root/$lang/build/main.pdf"
[ -f "$new" ] || { echo "no $lang/build/main.pdf: run tools/book-check.sh $lang first" >&2; exit 2; }
[ "$ref" = origin/pdf ] && git -C "$root" fetch -q origin pdf
work="$root/.png/layout-diff-$lang"
rm -rf "$work"; mkdir -p "$work"
git -C "$root" show "$ref:notes-$lang.pdf" > "$work/old.pdf" || exit 2
cp "$new" "$work/new.pdf"
in_container 1500m sh -c "cd /work/.png/layout-diff-$lang &&
  gs -q -dNOPAUSE -dBATCH -sDEVICE=txtwrite -o old-%03d.txt old.pdf &&
  gs -q -dNOPAUSE -dBATCH -sDEVICE=txtwrite -o new-%03d.txt new.pdf" || exit 2

python3 - "$work" <<'PY'
import glob, re, sys
work = sys.argv[1]
def pages(prefix):
    out = []
    for f in sorted(glob.glob(f"{work}/{prefix}-*.txt")):
        lines = [re.sub(r"\s+", "", l) for l in open(f, encoding="utf-8", errors="replace")]
        out.append([l for l in lines if l])
    return out
old, new = pages("old"), pages("new")
print(f"== pages: {len(old)} -> {len(new)}")
changed = 0
for i, (a, b) in enumerate(zip(old, new), 1):
    if a == b:
        continue
    changed += 1
    sa, sb = set(a), set(b)
    gone = [l[:50] for l in a if l not in sb][:3]
    came = [l[:50] for l in b if l not in sa][:3]
    print(f"   page {i}: lines {len(a)} -> {len(b)}")
    for l in gone: print(f"      - {l}")
    for l in came: print(f"      + {l}")
print(f"== pages with text changes: {changed}")
sys.exit(1 if changed or len(old) != len(new) else 0)
PY
