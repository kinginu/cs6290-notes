#!/usr/bin/env bash
# Commit a cross-chapter pass (terminology, cross-references, layout) and push.
#
#   tools/commit-pass.sh "<subject line>" ["<body paragraph>" ...]
#
# Stages only the content directories, never build output or local tooling.
# COMMIT_SCOPE=en|ja limits the commit to one edition (plus the shared
# figures, bibliography and glossary), so two agents working on the two
# editions at the same time do not commit each other's unfinished edits.
# Trailer lines: see tools/lib.sh (commit_trailers).
set -euo pipefail
source "$(dirname "$0")/lib.sh"
subject=${1:?usage: $0 "<subject>" ["<body>" ...]}
shift || true
cd "$root"
exec 9>"$root/.git/commit-lesson.lock"
flock -w 900 9
add() { for p in "$@"; do [ -e "$p" ] && git add -- "$p"; done; return 0; }
case "${COMMIT_SCOPE:-all}" in
  en) add en/lessons figures bib glossary.tsv ;;
  ja) add ja/lessons figures glossary.tsv ;;
  *)  add en/lessons ja/lessons figures bib glossary.tsv docs en/main.tex ja/main.tex ;;
esac
if git diff --cached --quiet; then echo "nothing to commit"; exit 0; fi
args=(-m "$subject")
for line in "$@"; do args+=(-m "$line"); done
trailers=$(commit_trailers)
[ -n "$trailers" ] && args+=(-m "$trailers")
git commit -q "${args[@]}"
git push -q origin HEAD:main
git log --oneline -1
