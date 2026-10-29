# Writing style guide — CS 6290 notes

These rules apply to every chapter in `en/lessons/` and `ja/lessons/`.
Lessons 1–3 of `cs6290-notes` are the reference implementation of this guide;
when in doubt, imitate them.

## 1. What a chapter is

- A **textbook-style summary of what the lecture covers**, one chapter per
  lesson (module), sections following the order of the lecture videos.
- **Scope = the lecture.**  Add background from the textbook only where it is
  needed to make a lecture statement precise or correct.  Do not add topics
  the lecture does not discuss.
- **Register**: impersonal, declarative, textbook prose.  Remove everything
  that belongs to the video format: analogies and metaphors used as teaching
  devices (laundry, car factories, …), jokes, "in this video", "as the
  professor said", "let's", "you", rhetorical questions.  The textbook "we"
  ("we now compute …") is fine, as in H&P.  A named
  law or principle the lecture introduces (e.g. "Lhadma's law") is content
  and stays, stated precisely.
- **The chapter speaks for itself.**  Body text never refers to the
  delivery medium ("the lecture", "the video", "the slides" / 「講義では」
  「動画では」); write "this chapter" (「本章」) or state the content
  directly.  Where the lecture's own wording matters (a term it uses
  differently from the textbook), say so in a `\caution`; the `\source`
  note is where the lecture or video is named.
- **Detail beyond the lesson goes to the margin.**  Vendor specifics, named
  products and later history that the lesson does not discuss (what
  shipped after the lecture, how a vendor implements the idea) belong in a
  `\margin` or `\sidenote`, not in the body.
- **Lecture vs paper.**  Where the lecture simplifies a result of the paper
  it cites (a rounded number, a dropped condition, an older version of the
  design), the body keeps the lecture's statement and a `\caution` beside
  it says what the paper states ("lecture vs paper: the paper measures …
  under …").  Do not silently replace the lecture's statement, and do not
  keep it without the caution.
- **No quiz or exam content.**  Do not reproduce quiz questions, their numbers
  or their answers.  Worked examples use our own numbers; the concept a quiz
  tests may of course be explained.
- Length follows content: roughly 1 page per 5–8 videos, never padded.

## 2. Chapter skeleton

```latex
\documentclass[../main.tex]{subfiles}
\begin{document}

\chapter{<Lesson title>}
\lessoninfo{
  video={<lesson reference>},            % CS6290: Lesson 4, videos 1--48 / CS6200: P2L1
  textbook={<book §…>},                  % H\&P \cite{hennessy2017} §3.3 / OSTEP \cite{ostep} ch.~4--6
  keywords={<6–14 comma-separated key terms>},
}

<2–4 sentence introduction: what the lesson is about and why it matters,
and how it connects to the previous lesson.>

\section{…}
<first sentence of the section>\source{<lecture ref>; <textbook ref>.}
…
\begin{keypoint}[Lesson summary]   % ja: [章のまとめ]
  …
\end{keypoint}

\end{document}
```

- Every `\section` carries one `\source{}` margin note near its first
  sentence: which videos it summarizes and where the textbook covers it.
  Cite a textbook section number only when you are sure of it; otherwise
  cite the chapter ("H\&P ch.~3").
- Use `definition` for every concept the lecture defines, `example` for
  worked numeric/trace examples, `note` for remarks, `keypoint` for
  take-aways (sparingly: ≈1 per 2–3 sections plus the final summary).
- `description`/`itemize` for enumerations; tables (`booktabs`) for
  comparisons; TikZ figures for structures, timing diagrams, state machines.

## 3. Macros

| Macro | Use |
|---|---|
| `\term[sort]{word}[gloss]` | **first definition** of a term in the book. EN: gloss = Japanese term. JA: `sort` = hiragana reading (required when the word has kanji; katakana/Latin may omit), gloss = English term. |
| `\term*{word}` | a later emphasized mention in the same chapter (no index entry, no gloss) |
| `\index{key}` | extra index entry without emphasis, e.g. a concept re-used in a later chapter that should also point here; acronyms: `\index{BTB\|see{branch target buffer}}` (JA: `\index{BTB\|see{分岐先バッファ}}`) |
| `\source{}` | where the section's material comes from |
| `\tip{}` | practical rule of thumb, calculation shortcut |
| `\caution{}` | common misconception / pitfall |
| `\margin{}` / `\sidenote{}` | short supporting remark (≤ 3 lines) |
| `marginfigure` / `widefigure` / `widetable` | small figure in the margin / figure or table spanning body + margin |

- The English edition sets `gloss=false` (`en/main.tex`) and prints no margin
  glosses; write the Japanese gloss anyway.
- The optional first argument of `\term` is the **index sort key** and the last
  one is the **margin gloss**: `\term{Amdahl's law}[Amdahl の法則]` — never
  put `key@display` into the gloss.
- English index entries are lowercase except proper nouns and acronyms, so do
  not place a `\term` at the start of a sentence (it would be indexed
  capitalized); rephrase, e.g. "The power consumed … is called
  \term{dynamic power}".
- The glossary column `lesson` says which chapter **owns** a term (defines it
  with `\term`).  Other chapters mention it plainly or with `\term*`.
- A term defined in an **earlier chapter** is not re-`\term`ed; write it
  plainly or use `\term*`, and refer back ("Lesson 3" / "第3章") if helpful.
- Index keys follow `glossary.tsv` (canonical English form, lowercase except
  proper nouns and acronyms; canonical Japanese form and reading).  If a
  needed term is missing from the glossary, choose the standard term and
  report it so the glossary can be updated.
- No line break inside the braces of a Japanese `\term` argument (the
  word, its reading, or the Japanese gloss in the English edition): the
  break becomes a space in the gloss and in the index key.  Break the
  source line before or after the `\term`.
- No `\term` inside `\margin`, `\sidenote`, `\tip`, `\caution` or
  `\source`: a margin note cannot carry its own gloss.  Define the term in
  the body; the note may use `\term*` or plain text.
- `\source` names the part of the lecture and the reference only; words
  about the delivery format ("visual metaphor", "in this video", 比喩,
  この動画) never appear in it.
- These rules, the label and listing rules and the `\term` ownership are
  checked by `tools/chapter-lint.py <slug>`.
- Margin density: at most ~3 margin items within a short paragraph run; the
  checker reports "margin notes moved down".  A new chapter keeps it at
  0–2.  During a pass over finished chapters (e.g. the proofreading pass,
  `workflow.md` §4) a chapter's count must never rise above its count
  before the pass (`tools/chapter-check.sh … --max-moved <baseline>`).

### 3.1 What goes in the margin column

The margin is a quarter of the page: it must carry real content, not only
`\source` notes.  **Aim for 3–4 margin items per page** counting `\source`
and `\term` glosses — i.e. roughly 10–20 items in a 5-page chapter, 30–50 in
a long one — while respecting the density limit above.  The body keeps the
single line of argument; everything that supports it goes to the margin.

| Put in the margin | Macro | Example |
|---|---|---|
| Where the material comes from | `\source` | one per section (required) |
| Term in the other language | `\term` | automatic |
| **Real-world numbers** | `\margin` | "L1: 32 KB, 4 cycles; L2: 256 KB, 12 cycles on Intel Skylake" |
| **Notation and assumptions** | `\margin` | what a symbol means, units, "a write takes one cycle here" |
| **Link to another lesson** | `\margin` | "same idea as the reservation stations of Lesson 7" |
| **Lecture vs textbook terminology** | `\caution` | a term the lecture uses with a different meaning than the textbook |
| **Common misconception, sign error** | `\caution` | "a speedup below 1 is a slowdown" |
| **Rule of thumb, shortcut, mnemonic** | `\tip` | "tag width = address − index − offset" |
| **Longer aside (> 3 lines)** | `\sidenote` | why a design exists, a named implementation (Pentium M's hierarchical predictor), a historical note |
| Small illustration | `marginfigure` | state diagram, small plot |

- `\sidenote` is numbered and anchored to one spot in the text: use it when
  the aside is longer than about three lines or when it must be tied to a
  precise sentence.  Shorter remarks stay `\margin`.
- **Real-world numbers are welcome even when the lecture does not give them**
  — they are what makes the notes usable later.  Name where the number comes
  from in the same note or an adjacent `\source` (vendor optimization
  manual, H\&P figure, a paper), so that lecture content and added context
  stay distinguishable.  Verify every number; keep them few, current and
  uncontroversial; never invent one.
- **One number per fact across the book.**  A real-world number that
  appears in more than one chapter is identical everywhere, with the same
  source: the Skylake branch-misprediction penalty is 16–20 cycles and its
  L3 latency 44 cycles in every chapter that mentions them.  When a pass
  corrects such a number, it corrects every occurrence (`grep -rn` both
  editions).
- Do not park body-level reasoning in the margin: if a reader needs it to
  follow the argument, it belongs in the body.

## 4. Labels, figures, bibliography

- Labels are unique across the whole book and carry the lesson number:
  `sec:l04-btb`, `fig:l04-btb`, `tab:l04-…`, `eq:l04-…`, `def:l04-…`,
  `ex:l04-…`.  (Lessons 1–3 of cs6290 predate this rule and are unprefixed.)
  EN and JA use the **same** labels.
- **Terms at first use.**  A term that `glossary.tsv` assigns to a chapter
  (column `lesson`) is `\term`ed at its first use in that chapter, in both
  editions; other chapters do not `\term` it again (§3).
  `tools/glossary-check.py` lists terms that are missing, re-`\term`ed
  elsewhere, absent from the glossary, or carry a gloss or reading that
  differs from it.
- Plain `\label{…}` inside `example`/`note` is enough — `\cref` prints
  "Example"/"Note" (no `\label[example]{…}` needed).
- Cross-references: `\cref{…}`; to another chapter in prose: "Lesson 7"
  (EN) / "第7章" (JA), numbers from the chapter list, and only to a chapter
  that actually treats the topic.
- Figures shared by both editions: `figures/lNN-<name>.tex`, pure TikZ,
  language-dependent text via `\iflangja{日本語}{English}`, must fit the
  body width (120 mm) — or the margin (50 mm) when used in `marginfigure`
  (wrap in `\resizebox{\linewidth}{!}{…}` if needed).
- Bibliography: add new entries only to `bib/<NN-slug>.bib` of your lesson,
  after checking with `grep -rn "{key," references.bib bib/` that the key
  does not exist.  Only cite works you are certain exist, with correct
  authors/venue/year.  Existing keys: see `references.bib`.

## 5. Code

- CS6290: `lstlisting` with `language={[x86masm]Assembler}` for assembly-like
  examples (MIPS-style mnemonics), `numbers=none` for short snippets.
- CS6200: `lstlisting` with `language=C`.
- Lines ≤ 60 characters (body is 120 mm wide).
- `\end{lstlisting}` must start at column 0 (no indentation), even inside
  `example`: leading spaces before it add an empty last line to the listing.

## 6. Japanese edition

- Mirrors the English chapter **exactly**: same sections in the same order,
  same equations, figures, tables, labels, examples, margin notes, key
  points.  Translate, do not summarize or extend.
- である調．Punctuation `，` and `．` (full-width comma and period), as in
  the existing chapters.  Keep established English acronyms (CPI, BTB, TLB,
  RPC).  Use `glossary.tsv` for every technical term.
- `\term[よみ]{語}[English term]` — reading in hiragana, English gloss.
  The Japanese edition (`index=dual`) also carries an English index built
  from the glosses, so give every defining `\term` its gloss.
- `\lessoninfo` keywords separated by `，`; `video={Lesson 4，動画 1--48}` /
  `video={P2L1}`; key point summary title `[章のまとめ]`.
- Numbers, units, math identical to the English edition.
- **Parity is checked mechanically**: the ordered sequence of commands of
  the two editions — sections, labels, `\input`, `\source`, `\margin`,
  `\sidenote`, `\tip`, `\caution`, `\term`, environments — must be
  identical (`tools/parity-check.py`).  Each margin item is anchored at the
  **same sentence** in both editions; a difference kept for layout is
  marked with a `%` comment next to the item (`workflow.md` §4).

## 7. Checking your work

```sh
tools/chapter-check.sh en 04-branches     # or ja
```

Required before a chapter is done: 0 errors, 0 undefined references
(references to other chapters are listed separately and are fine), 0
undefined citations, 0 multiply-defined labels, 0 missing glyphs, 0 overfull
boxes > 3 pt, at most 2 "margin notes moved down" (during a pass: at most
the chapter's count before it, §3).  Then open the rendered pages `.png/<lang>-<slug>-NN.png` and
check that figures fit, tables do not overflow, and margin notes do not
collide.  Do not commit; the maintainer commits.

## 8. Page layout

- **Print editions.**  Layout is judged on the A4 screen edition only.
  `print=a5|b5|b6|shinsho` (`make en-a5`, `tools/book-check.sh en --print a5`)
  scales that design to a two-sided compact page (body font 10 pt × `scale`:
  0.7, 0.85, 0.65, 0.65; `scale=` overrides); figures and tables are scaled
  and, if still too wide, shrunk to the measure (`lnotes-fit:` in the log).
  Never edit a chapter for a print size.  Below `scale=0.6` text is not
  readable; figure labels fall to about 4.5 pt.
