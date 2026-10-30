# Book profile

Everything that is specific to **this** book.  The generic rules are in
[`style-guide.md`](style-guide.md); writers and reviewers read both.  Keep
this file current.

## Identity

- **Title**: High Performance Computer Architecture — Lecture Notes
  (CS 6290, Georgia Tech OMSCS, Fall 2026)
- **Kind**: course notes
- **Field**: computer architecture
- **Chapter label**: Lesson  <!-- class default ("lesson") -->

## Source material

What each chapter summarizes, in the order the chapters follow.

- **Primary source**: the Georgia Tech CS 6290 lectures, one chapter per
  lesson (module), sections following the order of the lecture videos.
- **Version pinned**: not applicable (recorded lectures).
- **Unit list**: `docs/syllabus.json` (one entry per chapter; `videos`
  lists the lecture videos in order, from the Canvas module list of Fall
  2026, quiz answer pages and duplicate quiz items omitted).
- **Reference in `\source` and `\lessoninfo`**: the lesson and video
  numbers, e.g. `video={Lesson 4, videos 1--48}` (JA
  `video={Lesson 4，動画 1--48}`) and `\source{Lesson 5, video 8; H\&P
  §H.4.}`.
- **Textbook / reference**: Hennessy & Patterson, *Computer Architecture:
  A Quantitative Approach*, 6th ed. (bib key `hennessy2017`; cite as
  "H\&P §3.3", or "H\&P ch.~3" when the section is not certain).
- **Papers the source discusses**: listed per chapter in `bib/<slug>.bib`.
- **Terms the lecture names itself**: a named law or principle the lecture
  introduces (e.g. "Lhadma's law", Lesson 2) is content and stays, stated
  precisely; a `\caution` says where the name comes from.

## Code

- **Language in listings**: `language={[x86masm]Assembler}` for
  assembly-like examples, written with MIPS-style mnemonics;
  `language=C` for C examples; `numbers=none` for short snippets.
- **Conventions**: lines ≤ 60 characters (style guide §5).

## Excluded

Never include (the reviewers treat any of it as a major issue):

- quiz, exam, homework and project questions, numbers and answers of the
  course (Georgia Tech honor code); the concept a quiz tests may be
  explained with our own example.

## Real-world numbers

Typical kinds of numbers worth adding in margin notes (style guide §3.1),
and where they come from:

- cache sizes and latencies, branch-predictor sizes and misprediction
  penalties, pipeline depths — vendor optimization manuals, H\&P figures;
- one number per fact across the book: the Skylake branch-misprediction
  penalty is 16–20 cycles and its L3 latency 44 cycles in every chapter
  that mentions them.

## Labels

- Lessons 1–3 predate the chapter-number label rule (style guide §4) and
  keep their unprefixed labels.

## Reference chapters

Chapters whose style, density and macro use are approved and should be
imitated by new chapters (both editions):

- `en/lessons/01-introduction.tex`, `en/lessons/02-metrics-and-evaluation.tex`,
  `en/lessons/03-pipelining.tex` and their `ja/` mirrors.
