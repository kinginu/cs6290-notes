# Bilingual notes book (latex-lecture-notes-template)

English/Japanese LaTeX notes, one chapter per source unit, built with
LuaLaTeX in Docker.  Read before writing or reviewing anything:

- `docs/style-guide.md` — how chapters are written, margin policy, layout
- `docs/book.md` — this book: sources, citation formats, code, exclusions
- `docs/syllabus.json` — chapter numbers, slugs, titles, source units
- `glossary.tsv` — term ownership, Japanese terms and readings
- `docs/workflow.md` — production stages, class changes, resources, git

## Commands

- `tools/chapter-check.sh <en|ja> <slug>` — build one chapter, summarize
  problems, render pages to `.png/`; a chapter is done only when clean
  **and** every rendered page has been read.
- `tools/book-check.sh <en|ja>` — whole edition (one at a time on this
  machine; the script waits for a lock).
- `tools/layout-diff.sh <en|ja>` — page-by-page text diff against the
  published PDF, after a class or layout change.
- `tools/glossary-check.py` / `tools/parity-check.py [--lint]` — `\term`
  use against `glossary.tsv`; EN/JA structure, margin anchors and
  delivery-format wording.  Run before reviewing or proofreading.
- `tools/chapter-lint.py <slug>` (or `--all`) — no-TeX checks of both
  editions of a chapter; run before every push.
- `tools/layout-report.py <main.log> [--toc main.toc]` — overfull boxes and
  moved margin notes per chapter and page of a whole-book log.
- Without a local TeX, CI is the build: download the `build-logs` artifact
  and read it with `tools/log-summary.py` and `tools/layout-report.py`
  (`docs/workflow.md` §6).
- `tools/sync-main.py` — regenerate the chapter and bibliography lists in
  both `main.tex` after changing `docs/syllabus.json` or adding `bib/*.bib`.
- `tools/commit-lesson.sh <slug>` / `tools/commit-pass.sh "<subject>" …` —
  the only way to commit; they push to `main`.

## Rules

- The English and Japanese chapters are exact mirrors; change both.
- Never include what `docs/book.md` excludes (for courses: quiz, exam,
  homework and project content).
- `format/` is shared by every book.  In a book repository never edit it;
  report the needed change.  Class changes are made in the template
  repository and copied to each book (`docs/workflow.md` §8).
- Never force-push, reset or rewrite history.  Commit trailers come from
  `.git/commit-trailers`.
- Whole-book builds need ~2.5 GB: never run two at once, and keep chapter
  builds to about six in parallel.
