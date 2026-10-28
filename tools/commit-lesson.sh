#!/usr/bin/env bash
# Commit one finished chapter (English + Japanese, its figures and
# bibliography, and its own glossary rows) and push it to origin/main.
# Serialized with flock so that several writers finishing at the same time
# do not collide on the git index.
#
# glossary.tsv: only the rows of this lesson are staged.  The staged file is
# HEAD's glossary.tsv with this lesson's rows (column `lesson` = the
# chapter's `number` in docs/syllabus.json, matched by the `en` column)
# taken from the working tree: edited rows replaced in place, deleted rows
# dropped, new rows appended at the end.  It is written as a blob
# (git hash-object -w) and put into the index with update-index; rows that
# other agents appended for their chapters stay unstaged for their own
# commits.  Because new rows go at the end, the committed order can differ
# from the working tree when rows of several lessons are interleaved there;
# that is harmless (the next commit-lesson.sh of the other lesson appends
# its rows the same way).
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
git diff --quiet -- en/main.tex ja/main.tex || paths+=(en/main.tex ja/main.tex)

git add -- "${paths[@]}"
if ! git diff --quiet -- glossary.tsv; then
  blob=$(python3 - "$slug" <<'PY' | git hash-object -w --stdin
import json, subprocess, sys
d = json.load(open("docs/syllabus.json", encoding="utf-8"))
num = str(next(l["number"] for l in d["lessons"] if l["slug"] == sys.argv[1]))
head = subprocess.run(["git", "show", "HEAD:glossary.tsv"], capture_output=True,
                      encoding="utf-8").stdout.splitlines()
work = open("glossary.tsv", encoding="utf-8").read().splitlines()
if not head:                       # glossary not in HEAD yet: keep the header
    head = work[:1]
i = head[0].split("\t").index("lesson")
own = lambda line: (lambda f: len(f) > i and f[i].strip() == num)(line.split("\t"))
mine = {line.split("\t")[0]: line for line in work[1:] if own(line)}
out, done = [], set()
for k, line in enumerate(head):    # this lesson's rows: edited or deleted
    en = line.split("\t")[0]
    if k and own(line):
        if en in mine:
            out.append(mine[en])
            done.add(en)
        continue
    out.append(line)
out += [l for en, l in mine.items() if en not in done]  # new rows at the end
sys.stdout.write("".join(l + "\n" for l in out))
PY
)
  git update-index --cacheinfo "100644,$blob,glossary.tsv"
fi
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
