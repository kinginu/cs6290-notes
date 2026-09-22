#!/usr/bin/env bash
# Commit one finished chapter (English + Japanese, its figures and
# bibliography, and the glossary if it changed) and push it to origin/main.
# Serialized with flock so that several writers finishing at the same time
# do not collide on the git index.
#
#   tools/commit-lesson.sh <chapter-slug>      e.g. tools/commit-lesson.sh 05-predication
#
# Commit message: "<unit> N: <title> (en + ja)" with unit and title from
# docs/syllabus.json.  Trailer lines: see tools/lib.sh (commit_trailers).
set -euo pipefail
source "$(dirname "$0")/lib.sh"
slug=${1:?usage: $0 <chapter-slug>}
cd "$root"
n=${slug%%-*}
for f in "en/lessons/$slug.tex" "ja/lessons/$slug.tex"; do
  [ -f "$f" ] || { echo "missing $f: the chapter is not finished" >&2; exit 1; }
done
read -r unit title < <(python3 - "$slug" <<'PY'
import json, sys
d = json.load(open("docs/syllabus.json"))
l = next(l for l in d["lessons"] if l["slug"] == sys.argv[1])
print(d.get("unit", "Lesson"), l["title"])
PY
)

exec 9>"$root/.git/commit-lesson.lock"
flock -w 900 9

paths=("en/lessons/$slug.tex" "ja/lessons/$slug.tex")
[ -f "bib/$slug.bib" ] && paths+=("bib/$slug.bib")
for f in figures/l"$n"-*.tex; do [ -f "$f" ] && paths+=("$f"); done
git diff --quiet -- glossary.tsv || paths+=(glossary.tsv)
git diff --quiet -- en/main.tex ja/main.tex || paths+=(en/main.tex ja/main.tex)

git add -- "${paths[@]}"
if git diff --cached --quiet; then
  echo "nothing new to commit for $slug"
else
  msg=(-m "$unit $((10#$n)): $title (en + ja)")
  trailers=$(commit_trailers)
  [ -n "$trailers" ] && msg+=(-m "$trailers")
  git commit -q "${msg[@]}"
fi
git push -q origin HEAD:main
git log --oneline -1
