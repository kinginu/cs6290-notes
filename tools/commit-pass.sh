#!/usr/bin/env bash
# Commit a cross-chapter pass (terminology, cross-references, layout) and push.
#
#   tools/commit-pass.sh "<subject line>" ["<body line>" ...]
#
# Stages only the content directories, never build output or local tooling.
set -euo pipefail
subject=${1:?usage: $0 "<subject>" ["<body>" ...]}
shift || true
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
exec 9>"$root/.git/commit-lesson.lock"
flock -w 900 9
git add -- en/lessons ja/lessons figures bib glossary.tsv docs en/main.tex ja/main.tex
if git diff --cached --quiet; then echo "nothing to commit"; exit 0; fi
args=(-m "$subject")
for line in "$@"; do args+=(-m "$line"); done
args+=(-m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01R34md1hCP62By53jjEJ9Ls")
git commit -q "${args[@]}"
git push -q origin HEAD:main
git log --oneline -1
