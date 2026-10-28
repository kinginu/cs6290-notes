#!/usr/bin/env bash
# Build one whole edition in the TeX Live container, summarize the log and
# render every page to PNG for page-by-page reading.
#
#   tools/book-check.sh <en|ja> [--print <size>] [--no-render] [--dpi N]
#
# Output: <lang>/build/main.pdf, .png/book-<lang>-NNN.png (git-ignored).
# --print a5|b5|b6|shinsho builds the print edition instead (make <lang>-<size>):
# <lang>/build/main-<size>.pdf, .png/book-<lang>-<size>-NNN.png.
# A whole book needs far more memory than one chapter (~2.5 GB for 200
# pages).  Only one book build runs at a time on this machine, across all
# book repositories: the script waits for ~/.cache/lnotes-book.lock.
# Memory cap: $BOOK_MEM (default 2500m).  Exit code as chapter-check.sh.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
lang=${1:-}; shift || true
render=1; dpi=110; size=""
while [ $# -gt 0 ]; do
  case $1 in
    --no-render) render=0 ;;
    --dpi) dpi=$2; shift ;;
    --print) size=${2:-}; shift ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
  shift
done
if [[ ! "$lang" =~ ^(en|ja)$ ]]; then
  echo "usage: $0 <en|ja> [--print <size>] [--no-render] [--dpi N]" >&2; exit 2
fi
if [ -n "$size" ] && [[ ! "$size" =~ ^(a5|b5|b6|shinsho)$ ]]; then
  echo "unknown print size '$size' (a5, b5, b6, shinsho)" >&2; exit 2
fi
job=main${size:+-$size}            # main or main-<size>
tag=$lang${size:+-$size}           # en or en-a5
target=$tag                        # make en / make en-a5
mkdir -p "$root/.png" "$HOME/.cache"
exec 8>"$HOME/.cache/lnotes-book.lock"
if ! flock -n 8; then
  echo "== waiting for another book build to finish"
  flock 8
fi

echo "== building $lang/main.tex${size:+ (print=$size)} ($(date +%H:%M))"
in_container "${BOOK_MEM:-2500m}" make "$target" > "$root/.png/book-$tag.make.txt" 2>&1
status=$?
python3 "$root/tools/log-summary.py" "$root/$lang/build/$job.log" "$lang"
clean=$?

pdf="$root/$lang/build/$job.pdf"
if [ -f "$pdf" ] && [ $render = 1 ]; then
  rm -f "$root/.png/book-$tag-"[0-9]*.png
  in_container 1500m gs -q -sDEVICE=png16m -r"$dpi" \
    -o "/work/.png/book-$tag-%03d.png" "/work/$lang/build/$job.pdf"
  echo "== rendered $(ls "$root/.png/book-$tag-"[0-9]*.png | wc -l) pages to .png/book-$tag-NNN.png"
fi
if [ $status -ne 0 ] || [ ! -f "$pdf" ]; then
  echo "== make exit status $status; tail of make output:"
  tail -25 "$root/.png/book-$tag.make.txt"
  exit 1
fi
exit $clean
