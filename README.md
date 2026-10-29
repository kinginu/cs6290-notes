# cs6290-notes

Bilingual (English / 日本語) lecture notes for **CS 6290 High Performance
Computer Architecture** (Georgia Tech OMSCS, Fall 2026), written as a
textbook-style summary of what the lectures cover.  Built with
[latex-lecture-notes-template](https://github.com/kinginu/latex-lecture-notes-template).

- `en/` English edition, `ja/` Japanese edition — same chapter files under
  `lessons/`, one chapter per lesson.
- `figures/` and `references.bib` are shared by both editions.
- **Read the latest PDFs in the browser** (rebuilt by CI on every push):
  <https://kinginu.github.io/cs6290-notes/> —
  [English](https://kinginu.github.io/cs6290-notes/notes-en.pdf) ·
  [日本語](https://kinginu.github.io/cs6290-notes/notes-ja.pdf)
- Local build: `make docker-all` → `en/build/main.pdf`, `ja/build/main.pdf`.
- Print editions: compact two-sided books scaled from the A4 layout
  (class option `print=`, no chapter changes): `make docker-print-a5`
  (also `b6`, `shinsho` = 新書判, `b5`) → `dist/notes-<lang>-<size>.pdf`.
  Body font 7 pt (A5), 6.5 pt (B6, 新書判).  CI builds the A4 and A5
  editions (repository variable `PRINT_VARIANTS`), each also as a grayscale
  PDF, and lists them on the Pages index as a size × language × colour table.

## Status

| Lesson | Title | en | ja |
|---|---|---|---|
| 1 | Introduction | ✅ | ✅ |
| 2 | Metrics and Evaluation | ✅ | ✅ |
| 3 | Pipelining | ✅ | ✅ |
| 4 | Branches | ✅ | ✅ |
| 5 | Predication | ✅ | ✅ |
| 6 | ILP | ✅ | ✅ |
| 7 | Instruction Scheduling (Tomasulo) | ✅ | ✅ |
| 8 | ReOrder Buffer | ✅ | ✅ |
| 9 | Memory Ordering | ✅ | ✅ |
| 10 | Compiler ILP | ✅ | ✅ |
| 11 | VLIW | ✅ | ✅ |
| 12 | Cache Review | ✅ | ✅ |
| 13 | Virtual Memory | ✅ | ✅ |
| 14 | Advanced Caches | ✅ | ✅ |
| 15 | Memory | ✅ | ✅ |
| 16 | Storage | ✅ | ✅ |
| 17 | Fault Tolerance | ✅ | ✅ |
| 18 | Multi-Processing | ✅ | ✅ |
| 19 | Cache Coherence | ✅ | ✅ |
| 20 | Synchronization | ✅ | ✅ |
| 21 | Memory Consistency | ✅ | ✅ |
| 22 | Many Cores | ✅ | ✅ |

## Writing conventions

See [`docs/style-guide.md`](docs/style-guide.md); the production and review
passes are in [`docs/workflow.md`](docs/workflow.md).  In short:

- Textbook register: no lecture anecdotes or metaphors; scope limited to
  what the lectures cover.  Textbook pointers (Hennessy & Patterson, 6th
  ed.) go in the margin via `\source{}`.
- Every new term is introduced with `\term[reading]{word}[gloss]` so it
  lands in the index; the gloss shows the other language's term in the
  margin.
- Numbers in worked examples are our own; **no assignment, quiz or exam
  content is reproduced** (Georgia Tech honor code).
- Build a single chapter with `tools/chapter-check.sh en 04-branches`, or
  by opening it in VS Code (LaTeX Workshop builds the subfile alone);
  `tools/chapter-lint.py 04-branches` checks both editions without TeX.

## License

`format/` and the build files come from the template (MIT), except
`format/lnmarginfix.sty`, a modified copy of `marginfix` under the LPPL
1.3c.  The notes
themselves (`en/`, `ja/`, `figures/`) are © kinginu and released under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
