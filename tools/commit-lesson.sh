#!/usr/bin/env bash
# Commit one finished lesson (English + Japanese chapter, its figures and
# bibliography) and push it to origin/main.  Serialized with flock so that
# several writers finishing at the same time do not collide on the git index.
#
#   tools/commit-lesson.sh <lesson-slug>      e.g. tools/commit-lesson.sh 05-predication
set -euo pipefail
slug=${1:?usage: $0 <lesson-slug>}
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
n=${slug%%-*}
for f in "en/lessons/$slug.tex" "ja/lessons/$slug.tex"; do
  [ -f "$f" ] || { echo "missing $f: the lesson is not finished" >&2; exit 1; }
done
title=$(python3 -c 'import json,sys; d=json.load(open("docs/syllabus.json")); print(next(l["title"] for l in d["lessons"] if l["slug"]==sys.argv[1]))' "$slug")

exec 9>"$root/.git/commit-lesson.lock"
flock -w 900 9

paths=("en/lessons/$slug.tex" "ja/lessons/$slug.tex")
[ -f "bib/$slug.bib" ] && paths+=("bib/$slug.bib")
for f in figures/l"$n"-*.tex; do [ -f "$f" ] && paths+=("$f"); done
git diff --quiet -- glossary.tsv || paths+=(glossary.tsv)

git add -- "${paths[@]}"
if git diff --cached --quiet; then
  echo "nothing new to commit for $slug"
else
  git commit -q -m "Lesson $((10#$n)): $title (en + ja)" \
    -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019cz7bNRfZGYEDmVsQnfQoW"
fi
git push -q origin HEAD:main
git log --oneline -1
