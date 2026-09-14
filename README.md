# cs6290-notes

Bilingual (English / 日本語) lecture notes for **CS 6290 High Performance
Computer Architecture** (Georgia Tech OMSCS, Fall 2026), written as a
textbook-style summary of what the lectures cover.  Built with
[latex-lecture-notes-template](https://github.com/kinginu/latex-lecture-notes-template).

- `en/` English edition, `ja/` Japanese edition — same chapter files under
  `lessons/`, one chapter per lesson.
- `figures/` and `references.bib` are shared by both editions.
- **Read the latest PDFs in the browser** (rebuilt by CI on every push):
  [English](../../blob/pdf/notes-en.pdf) · [日本語](../../blob/pdf/notes-ja.pdf)
- Local build: `make docker-all` → `en/build/main.pdf`, `ja/build/main.pdf`.

## Status

| Lesson | Title | en | ja |
|---|---|---|---|
| 1 | Introduction | ✅ | ✅ |
| 2 | Metrics and Evaluation | ✅ | ✅ |
| 3 | Pipelining | ✅ | ✅ |
| 4 | Branches | | |
| 5 | Predication | | |
| 6 | ILP | | |
| 7 | Instruction Scheduling (Tomasulo) | | |
| 8 | ReOrder Buffer | | |
| 9 | Memory Ordering | | |
| 10 | Compiler ILP | | |
| 11 | VLIW | | |
| 12 | Cache Review | | |
| 13 | Virtual Memory | | |
| 14 | Advanced Caches | | |
| 15 | Memory | | |
| 16 | Storage | | |
| 17 | Fault Tolerance | | |
| 18 | Multi-Processing | | |
| 19 | Cache Coherence | | |
| 20 | Synchronization | | |
| 21 | Memory Consistency | | |
| 22 | Many Cores | | |

## Writing conventions

- Textbook register: no lecture anecdotes or metaphors; scope limited to
  what the lectures cover.  Textbook pointers (Hennessy & Patterson, 6th
  ed.) go in the margin via `\source{}`.
- Every new term is introduced with `\term[reading]{word}[gloss]` so it
  lands in the index; the gloss shows the other language's term in the
  margin.
- Numbers in worked examples are our own; **no assignment, quiz or exam
  content is reproduced** (Georgia Tech honor code).
- Build a single chapter in VS Code by opening `lessons/NN-*.tex`.

## License

`format/` and the build files come from the template (MIT).  The notes
themselves (`en/`, `ja/`, `figures/`) are © kinginu and released under
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
