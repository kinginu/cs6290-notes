# Producing a book

How a book made from this template is written, checked and published.
The writing rules are in [`style-guide.md`](style-guide.md), the book's own
settings in [`book.md`](book.md).  The stages below were used for two
complete books (38 chapters, ~200 pages per edition); each stage exists
because skipping it let real defects through.

## 1. Start a book

1. Create the repository from the template and build the image once:
   ```sh
   gh repo create <name>-notes --template <owner>/latex-lecture-notes-template --public --clone
   cd <name>-notes && make docker-build
   ```
2. Fill in `docs/book.md` (source material, citation formats, textbook,
   code language, exclusions) and `docs/syllabus.json` (one entry per
   chapter: `number`, `slug`, `title`, `title_ja`, `units`; optional
   `parts`; `unit` is the word used in commit messages).  `title_ja` is
   required: `tools/sync-main.py` writes it into `ja/main.tex`.  `units` is
   **mandatory** before any chapter is written: it is the ordered list of
   the source's units for the chapter (for a course, the video titles of the
   lesson, from the public course outline or video list; for a tutorial,
   its section headings), and writers and reviewers verify coverage against
   it.  A book without it (cs6200-notes) left the reviewers reconstructing
   the lecture structure from memory.
3. Set the title block and class options in `en/main.tex` and `ja/main.tex`
   (`chapter` option for "Chapter 3" instead of "Lesson 3"), delete the two
   sample chapters and their `glossary.tsv` rows, and run
   `tools/sync-main.py`.
4. Replace `README.md` with the book's own: title, links to the PDFs,
   status table, and a licence section that keeps the two licences apart
   (`format/` and the build files are MIT from the template, except
   `format/lnmarginfix.sty`, which stays LPPL 1.3c; the notes in
   `en/`, `ja/` and `figures/` need their own line, e.g. "© <holder>,
   CC BY-NC-SA 4.0").  Put the copyright holder of the book into
   `LICENSE`.
5. Publishing: GitHub Pages is **not** enabled by the template; for a
   public repository enable it by hand on the `pdf` branch (Settings →
   Pages → Deploy from a branch: `pdf`, `/`).  CI publishes both PDFs there
   on every push to `main`.  The index page shows the repository name and
   a subtitle (default "Lecture notes — English / 日本語"); set the
   repository variable `PAGES_SUBTITLE` (Settings → Secrets and variables
   → Actions → Variables) to change it
   (`.github/scripts/pdf-index.sh`).
   CI builds the A4 editions and the A5, B6 and 新書判 print editions,
   each in colour and grayscale; a book restricts the sizes with the
   repository variable `PRINT_VARIANTS`, a JSON list that must contain
   `"a4"`, e.g. `["a4","a5"]` (the template leaves it unset and keeps all
   sizes; `"b5"` can be added).  The `lint` job's summary shows what
   `tools/parity-check.py --lint`, `tools/glossary-check.py` and
   `tools/chapter-lint.py --all` find, with each tool's exit code in its
   heading; the job is report-only (it always succeeds) and never blocks
   publishing.
6. Write `glossary.tsv` **before** the chapters: one row per concept with
   the chapter that first defines it (`lesson`), the Japanese term and its
   reading.  Term ownership is what keeps 20 independently written chapters
   from defining the same term five times.

## 2. Write chapters

Each chapter goes through five stages; chapters are independent and can
run in parallel (see §9 for how many).

| Stage | What happens | Output |
|---|---|---|
| Write EN | reconstruct the outline of the source unit, write the English chapter with its figures, margin items (style guide §3.1) and bibliography; `tools/chapter-check.sh en`, read every page | `en/lessons/NN-slug.tex`, `figures/lNN-*`, `bib/NN-slug.bib` |
| Review EN | two independent reviewers, in parallel, who do not edit: **technical** (recompute every number, re-trace every example, check every citation exists) and **scope/conventions** (every source unit covered, nothing beyond it, register, excluded material, macros, labels, layout) | issue lists |
| Fix EN | verify each finding (reviewers can be wrong), fix the real ones, rebuild, read the pages | revised chapter |
| Write JA | mirror translation per style guide §6, Japanese branches in shared figures | `ja/lessons/NN-slug.tex` |
| Check JA + commit | adversarial mirror check against the current English chapter, Japanese quality, index readings; fix; rebuild both editions; `tools/commit-lesson.sh NN-slug` | one commit per chapter, pushed |

A chapter is pushed as soon as it is finished, so the published PDFs grow
chapter by chapter.

## 3. Finish the book

After the last chapter, one edition or one concern at a time:

1. **Margin enrichment** (only if chapters fell short of style guide §3.1):
   add real-world numbers, cautions, tips, cross-chapter links and
   sidenotes to both editions without touching the body.
2. **Terminology and index**: one inventory of every `\term`/`\index` of
   both editions against `glossary.tsv`; unify translations, case and
   plural variants of index keys, readings, `see` entries, term ownership.
3. **Cross-references**: chapter numbers in prose against the syllabus,
   `\cref` targets, label prefixes and identity across editions,
   `\lessoninfo` and summaries, orphan figures.
4. **Full-book visual QA**, strictly one edition at a time:
   `tools/book-check.sh <lang>`, then read **every** rendered page and fix
   layout in the chapter sources (style guide §8).  Commit each edition with
   `COMMIT_SCOPE=<lang> tools/commit-pass.sh "<subject>" "<body>"`.
   Defects that only the class can fix are collected, not patched locally
   (§8).

Each pass commits with `tools/commit-pass.sh`.

## 4. Proofreading pass

A finished book is read once more, chapter by chapter, for technical
correctness, scope, EN/JA parity and style-guide compliance.  The model is
the pass recorded in cs6290-notes commit `2e0ec80` (22 chapters, about 110
findings applied); its commit message is the template for the one below.

1. **Mechanical first step.**  Before any reader starts, run
   `tools/glossary-check.py` (term ownership, glosses, readings against
   `glossary.tsv`) and `tools/parity-check.py --lint` (ordered structure and
   margin anchors of the two editions, delivery-format wording in the
   body).  Their output goes to the reviewers with the chapters it concerns;
   a reported item is a candidate, not yet a finding.
2. **Review.**  Each reviewer takes two chapters, both editions, with their
   figures and bibliography, and reports findings only — reviewers never
   edit.  Every finding has:
   - the location `file:line`;
   - a severity: **ERROR** (wrong fact, number or figure), **MISMATCH**
     (EN and JA differ: omitted, added or mistranslated text, an item
     anchored at a different sentence), **SCOPE** (beyond the source unit or
     in the wrong place, e.g. vendor detail in the body), **STYLE** (a
     style-guide rule is broken), **NIT** (typo, punctuation);
   - the quoted text, and the concrete replacement **in both languages**.
3. **Vetting.**  A lead checks every finding (recomputes, looks the fact
   up), drops those that cannot be verified or are only a matter of taste,
   and hands the accepted list to an implementer.
4. **Applying.**  The implementer applies the list keeping the two editions
   structurally identical (style guide §6), runs `tools/chapter-check.sh`
   for both editions of every touched chapter and reads the rendered pages
   that changed.
5. **Layout rules.**
   - The "margin notes moved down" count of a chapter must not exceed its
     count before the pass.  Measure the baseline by building the `HEAD`
     version under a temporary slug
     (`git show HEAD:en/lessons/NN-slug.tex > en/lessons/NN-slug-base.tex`,
     `tools/chapter-check.sh en NN-slug-base --no-render`; the same for
     `ja`), then delete the temporary `.tex`, its
     `<lang>/lessons/build/NN-slug-base.*` and `.png/<lang>-NN-slug-base*`
     files; check the edited chapter with
     `tools/chapter-check.sh en NN-slug --max-moved <baseline>`.
   - On a touched page no margin note may run below the text block.
   - Fix a crowded margin by shortening a note or anchoring it one
     sentence earlier or later — in **both** editions.  Where the editions
     must keep different anchors for layout, mark the difference with a
     `%` comment next to the item in the edition that deviates
     (`parity-check.py` still reports it).
6. **Finish.**  `tools/book-check.sh` for each edition, then one commit
   (`tools/commit-pass.sh`) whose message lists: facts corrected (per
   chapter, what was wrong and what it is now), scope moves, margin sources
   added or aligned, EN/JA parity fixes, index additions, layout (moved-down
   counts against the baseline, chapters that keep a deliberate
   difference) and the build totals of both editions (pages, errors,
   undefined references and citations, multiply-defined labels, missing
   glyphs, overfull boxes, index warnings).

The `notes-proofread` workflow (§11) runs step 2 and returns the findings
grouped by chapter; steps 3–6 stay with the lead.

## 5. Review pass on a finished book

The Review EN stage of §2 (two reviewers, then a fixer) can also be run
afterwards over a finished book, e.g. one whose chapters were written
before the stage existed.  Unlike the proofreading pass (§4) there is no
lead between reviewers and fixer: the fixer vets the findings itself.  It
was run this way on cs6200-notes (16 chapters).  Per chapter:

1. **Two read-only reviewers in parallel.**
   - *Technical*: recompute every number and re-trace every example and
     table; fetch and read the cited papers, manuals and documentation and
     check every claim attributed to them (a claim that the paper does not
     make, or makes differently, is a finding); verify every bibliography
     entry (authors, title, venue, year, URL); check real-world numbers in
     the margin and their sources.
   - *Scope and conventions*: walk the `units` of the chapter
     (`docs/syllabus.json`) in order and decide for each whether the
     chapter covers it; flag material beyond the units, register
     (style guide §1), excluded material (`book.md`), macro and label
     conventions (`tools/chapter-lint.py` output), "Lesson N" references
     that point to a chapter which does not treat the topic, margin notes
     with real-world numbers and no named source, and margin density
     (style guide §3.1).  For a thin chapter it proposes concrete margin
     items, each with its source.
2. **One fixer** verifies every finding (recompute, look it up) and may
   reject one with a one-line reason.  Where the lecture simplifies against
   the paper, it keeps the lecture's statement and adds a `\caution`
   "lecture vs paper" (style guide §1).  It edits EN, mirrors every change
   into JA (same items, same anchors), adds the margin items it accepted,
   runs `tools/chapter-lint.py <slug>` until clean (and
   `tools/chapter-check.sh` for both editions where TeX is available), and
   commits with `tools/commit-lesson.sh <slug>`.

Parallel agents: one chapter per agent set, never two agents on one
chapter's files.  New glossary rows are appended with `printf '…\t…\n' >>
glossary.tsv`, never by rewriting the file; `commit-lesson.sh` stages only
the rows of its own lesson.  With a cap of about 20 concurrent agents and 3
agents per chapter, run about 6 chapters at a time.  The pass changes
layout (on cs6200-notes overfull boxes > 3 pt went from 0 to 8 and moved
margin notes from 24 to 108 in EN, 39 to 126 in JA): plan a layout pass
(§7) after it.  The `notes-review` workflow (§11) runs this section.

## 6. Working without a local TeX

When the machine has no TeX installation (or no room for the Docker
image), CI is the only build.

- **Pre-push gate**: `tools/chapter-lint.py <slug>` (or `--all`) checks
  both editions of a chapter without TeX: syntax, labels, EN/JA counts,
  citations and references, `\term` against `glossary.tsv`, and the
  recurrent style defects of style guide §3.  Run it, with
  `tools/parity-check.py` and `tools/glossary-check.py`, before every push.
- **Logs**: CI uploads the artifact `build-logs` (`en/build/main.log`,
  `ja/build/main.log`, `main.toc` of both) even when the build fails:
  ```sh
  gh run download <run-id> -n build-logs -D /tmp/logs
  tools/log-summary.py /tmp/logs/en/build/main.log en     # no slug: whole book
  tools/layout-report.py /tmp/logs/en/build/main.log --toc /tmp/logs/en/build/main.toc
  ```
  `log-summary.py` gives the totals (errors, undefined references, overfull
  boxes, moved margin notes, pages); `layout-report.py` places overfull
  boxes and moved notes on chapters and pages.
- **One build per batch**: a push cancels the CI run of the previous push,
  so only the last push of a batch is built.  Push a batch, wait for its
  run (`gh run watch --exit-status`), read the logs, then push the fixes.
- Rendered pages cannot be read locally; the PDFs are in the artifact
  `notes-pdf` and on the `pdf` branch.

## 7. Layout pass

A content pass over finished chapters (§4, §5) moves page breaks and
crowds margins.  A layout pass restores the book; it changes no content.

- **Metrics** (whole-book logs, both editions): 0 errors, 0 overfull boxes
  > 3 pt, fewer than 3 moved margin notes on every page, and a total of
  moved notes near the baseline before the content pass.  On cs6200-notes
  the pass went from 108 / 126 (EN / JA) to 33 / 47 against a baseline of
  24 / 39.
- **Remedies, in this order**:
  1. move the item to an emptier paragraph nearby (the sentence it
     supports usually allows one or two paragraphs of freedom);
  2. merge adjacent notes on the same point;
  3. shorten the note;
  4. demote it to a parenthesis in the body (only if it is short and the
     body reads well with it);
  5. turn a note of more than 3 lines into a `\sidenote`;
  6. overfull lines: `\allowbreak` inside long `\texttt` paths and
     identifiers; `\setlength{\tabcolsep}{4pt}` for a wide table;
     `sloppypar` around one paragraph as the last resort.
- EN and JA keep identical margin counts and anchors
  (`tools/chapter-lint.py`, `tools/parity-check.py`): a remedy applied to
  one edition is applied to the other, unless a `%` comment documents a
  deliberate anchor difference.
- Iterate with CI (§6): batch the edits for all affected chapters, push
  once, compare `layout-report.py` with the previous run.

## 8. Class changes

`format/` is shared by every book made from the template and must stay
identical everywhere.

1. Change the class files (`format/lnotes.cls`, `format/lnmarginfix.sty`,
   `format/lnotes-*.ist`) in the **template** repository only; build the
   template book and a small test document that exercises the change.
2. Copy every changed file of `format/` (and `.github/workflows/build.yml`
   when it changed) into each book repository, then for each edition:
   `tools/book-check.sh <lang>` and `tools/layout-diff.sh <lang>`.  The
   diff shows every page whose text moved; a change meant to be cosmetic
   must not change page counts or page breaks.
3. Commit the template, then each book ("Class …, synced from the
   template").

Loading order matters in the class: `amsmath` and `mathtools` must be
loaded before `unicode-math`, or `\underbrace` prints black boxes while the
log stays clean.  This is why every stage reads the rendered pages.

## 9. Machine resources

- A chapter build needs ~1.5 GB (`CHAPTER_MEM`), a whole-book build ~2.5 GB
  (`BOOK_MEM`) plus rendering.  `tools/book-check.sh` lets only one book
  build run on the machine at a time; do not start whole-book builds by
  hand in parallel.
- On a 12 GB machine, about six agents writing chapters in parallel is the
  limit.  When the session is killed, check
  `/sys/fs/cgroup/user.slice/user-$(id -u).slice/memory.events`
  (`oom_kill`): a rising count with the container's own limit untouched
  means the host ran out of memory — reduce parallelism.
- Long runs belong in a terminal multiplexer that survives the editor
  (e.g. a systemd user service running tmux).

## 10. Git and publishing

- Commit only through `tools/commit-lesson.sh` and `tools/commit-pass.sh`;
  they stage the content directories only and serialize concurrent commits.
  Never force-push or rewrite history — CI and Pages follow `main`.
- Trailer lines for every commit (e.g. `Co-Authored-By:`) go into
  `.git/commit-trailers` (not tracked) or `$COMMIT_TRAILERS`.
- CI builds both editions on every push, publishes them to the `pdf` branch
  (and Pages) and attaches them to `v*` releases; a newer push cancels a
  running build.

## 11. With Claude Code

The stages above exist as saved workflows in `.claude/workflows/`
(run them by name, e.g. "run the notes-chapters workflow for chapters
4–9").  Each reads `docs/book.md`, `docs/syllabus.json` and this guide from
the repository it runs in.

| Workflow | Args | Does |
|---|---|---|
| `notes-glossary` | — | writes `glossary.tsv` from the syllabus and the source |
| `notes-chapters` | `{chapters: [4, 5, …]}` | §2 for each chapter, committed one by one |
| `notes-margins` | `{chapters: [...]}` | §3.1 margin enrichment |
| `notes-integration` | — | §3.2 terminology and §3.3 cross-references |
| `notes-visual-qa` | `{langs: ["en", "ja"]}` | §3.4, one edition after the other |
| `notes-proofread` | `{chapters: [...], perReviewer?: 2}` | §4 step 2: reviewers, two chapters each; returns the findings for vetting |
| `notes-review` | `{chapters: [...], maxParallel?: 6}` | §5: technical + scope reviewers, then a fixer that applies, mirrors and commits each chapter |

Before running them, write the commit trailers to `.git/commit-trailers`.
A workflow that is interrupted part-way is best continued by looking at
what each chapter already has (files, commits) and starting a fresh run
for the remaining stages, rather than by resuming.
