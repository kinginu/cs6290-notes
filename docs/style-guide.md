# Writing style guide

These rules apply to every chapter in `en/lessons/` and `ja/lessons/` of a
book made from this template.  What is specific to one book — what the
source material is, how to cite it, the textbook, the code language,
what must never be included — is in [`book.md`](book.md); the chapter list is
[`syllabus.json`](syllabus.json); the terminology is
[`../glossary.tsv`](../glossary.tsv).  How chapters are produced and checked
is in [`workflow.md`](workflow.md).

## 1. What a chapter is

- A **textbook-style summary of what the source unit covers**: one chapter
  per unit (a lecture lesson, a tutorial chapter, a documentation topic —
  see `book.md`), sections following the order of the source.
- **Scope = the source.**  Add background from the textbook or the reference
  documentation only where it is needed to make a statement precise or
  correct.  Do not add topics the source does not discuss.
- **Register**: impersonal, declarative, textbook prose.  Remove everything
  that belongs to the delivery format: analogies and metaphors used as
  teaching devices, jokes, "in this video", "as the speaker said", "let's",
  "you", rhetorical questions.  The textbook "we" ("we now compute …") is
  fine.  A named law, principle or design rule that the source introduces is
  content and stays, stated precisely.
- **The chapter speaks for itself.**  Body text never refers to the
  delivery medium ("the lecture", "the video", "the slides" / 「講義では」
  「動画では」); write "this chapter" (「本章」) or state the content
  directly.  Where the source's own wording matters (a term it uses
  differently from the textbook), say so in a `\caution`; the `\source`
  note is where the lecture or video is named.
- **Detail beyond the unit goes to the margin.**  Vendor specifics, named
  products and later history that the source unit does not discuss (what
  shipped after the lecture, how a vendor implements the idea) belong in a
  `\margin` or `\sidenote`, not in the body.
- **Lecture vs paper.**  Where the source simplifies a result of the paper
  or documentation it cites (a rounded number, a dropped condition, an
  older version of the design), the body keeps the source's statement and a
  `\caution` beside it says what the paper states ("lecture vs paper:
  the paper measures … under …").  Do not silently replace the source's
  statement, and do not keep it without the caution.
- **No graded or restricted material.**  For a course: never reproduce quiz,
  exam, homework or project questions, their numbers or their answers
  (honor code); the concept a quiz tests may be explained with our own
  example.  `book.md` lists what else is excluded for a book.
- Length follows content, never padded (a 5-minute video is roughly a page
  or less).

## 2. Chapter skeleton

```latex
\documentclass[../main.tex]{subfiles}
\begin{document}

\chapter{<Unit title>}
\lessoninfo{
  video={<lecture reference>},        % recorded lectures (omit otherwise)
  sources={<primary material>},       % docs, tutorial, paper, talk (omit if none)
  textbook={<book §…>},               % e.g. H\&P \cite{hennessy2017} §3.3
  keywords={<about 6–15 comma-separated key terms>},
}

<3–5 sentence introduction: what the unit is about, why it matters, and
how it connects to the previous chapter.>

\section{…}
<first sentence of the section>\source{<source ref>; <textbook ref>.}
…
\begin{keypoint}[Lesson summary]   % ja: [章のまとめ]  (a book with the
  …                                 % class option "chapter": [Chapter summary])
\end{keypoint}

\end{document}
```

- Every `\section` carries one `\source{}` margin note near its first
  sentence: which part of the source it summarizes and where the textbook or
  reference documentation covers it (formats in `book.md`).  Cite a section
  number only when you are sure of it; otherwise cite the chapter
  ("H\&P ch.~3").
- `\lessoninfo`: `keywords` lists about 6–15 key terms (a guideline, not a
  limit); `textbook=` names the textbook chapters or sections.  Papers and
  RFCs the unit discusses go into `sources=`, each with a bib entry; a book
  that does not use `sources=` may list them in `textbook=` after the
  textbooks.
- Sources without a bib entry are cited inline in a fixed form: man pages
  as `(sched(7))`, `(proc(5))`; vendor manuals as `(Intel SDM vol.~3A,
  §4.10)`, `(Arm ARM, D1.3)`.  Everything else gets a `\cite`.
- Use `definition` for every concept the source defines, `example` for
  worked numeric/trace examples, `note` for remarks, `keypoint` for
  take-aways (sparingly: ≈1 per 2–3 sections plus the final summary).
- The final `keypoint` titled `[Lesson summary]` is required in every
  chapter.  Mid-chapter key points are untitled unless the title adds
  information that the box itself does not state.
- `description`/`itemize` for enumerations; tables for comparisons; TikZ
  figures for structures, timing diagrams, state machines, data flow.
- Tables use `booktabs` rules only (`\toprule`, `\midrule`,
  `\bottomrule`; no vertical rules, no `\hline`), text columns as
  `>{\raggedright\arraybackslash}p{<width>}`, and `\addlinespace` between
  groups of rows.  A wide table may reduce `\tabcolsep` to 4pt (§8).

## 3. Macros

| Macro | Use |
|---|---|
| `\term[sort]{word}[gloss]` | **first definition** of a term in the book. EN: gloss = Japanese term. JA: `sort` = hiragana reading (required when the word has kana or kanji, katakana included; none for a Latin acronym), gloss = English term. |
| `\term*{word}` | a later emphasized mention of a term the glossary owns (no index entry, no gloss) |
| `\emph{word}` | first use of a word that is **not** a glossary term, or plain emphasis |
| `\index{key}` | extra index entry without emphasis, e.g. a concept re-used in a later chapter that should also point here; acronyms: `\index{BTB\|see{branch target buffer}}` (JA: `\index{BTB\|see{分岐先バッファ}}`) |
| `\source{}` | where the section's material comes from |
| `\tip{}` | practical rule of thumb, calculation shortcut |
| `\caution{}` | common misconception / pitfall |
| `\margin{}` | short supporting remark (≤ 3 lines) |
| `\sidenote{}` | numbered aside, for anything longer than ~3 lines or tied to one sentence |
| `marginfigure` / `margintable` | small figure or table in the margin (50 mm) |
| `widefigure` / `widetable` | float spanning body + margin; only when the body width (120 mm) really is too narrow |

- `\term` is only for words that have a row in `glossary.tsv`; a new word
  that is not a glossary term is set with `\emph` at its first use.  A later
  emphasised mention of a glossary term is `\term*`, never `\emph`.
- The template's English `main.tex` passes the class option `gloss=false`
  (no margin glosses; the word and the index entry stay); write the gloss
  anyway: the Japanese edition's English index (`index=dual`) and a later
  edition with glosses need it.
- The optional first argument of `\term` is the **index sort key** and the last
  one is the **margin gloss**: `\term{Amdahl's law}[Amdahl の法則]` — never
  put `key@display` into the gloss.
- English index entries are lowercase except proper nouns and acronyms, so do
  not place a `\term` at the start of a sentence (it would be indexed
  capitalized); rephrase, e.g. "The power consumed … is called
  \term{dynamic power}".
- The glossary column `lesson` says which chapter **owns** a term (defines it
  with `\term`).  Other chapters mention it plainly or with `\term*`; a term
  defined in an earlier chapter is never re-`\term`ed — refer back
  ("Lesson 3" / "第3章") if helpful.
- Index keys follow `glossary.tsv` (canonical English form, lowercase except
  proper nouns and acronyms; canonical Japanese form and reading).  If a
  needed term is missing, choose the standard term and add the row (or report
  it so the glossary can be updated).
- Index aliases point both ways: the short form refers to the long one
  (`\index{BTB|see{branch target buffer}}`), and, when the long form is
  rarely used in the text, the long form also refers to the short one
  (`\index{branch target buffer|see{BTB}}`).
- The `note` column of `glossary.tsv` is `see: X` for an alias row (parsed:
  the row is a cross-reference, not a term to define), `also: X` for a
  synonym that the index should mention, and free text otherwise (`cf. X`,
  "named after …").  `tools/glossary-check.py` notes an `also called X` or a
  bare synonym in that column.
- Code identifiers (`mlir::Operation`, `pthread_create`) are set with
  `\texttt{}` (or `\lstinline`) and indexed with a plain `\index{}` if at all;
  they are not glossary terms.
- No line break inside the braces of a Japanese `\term` argument (the
  word, its reading, or the Japanese gloss in the English edition): the
  break becomes a space in the gloss and in the index key.  Break the
  source line before or after the `\term`.
- No `\term` inside `\margin`, `\sidenote`, `\tip`, `\caution` or
  `\source`: a margin note cannot carry its own gloss.  Define the term in
  the body; the note may use `\term*` or plain text.
- `\source` names the part of the source and the reference only; words
  about the delivery format ("visual metaphor", "in this video", 比喩,
  この動画) never appear in it.
- These rules, the label and listing rules and the `\term` ownership are
  checked by `tools/chapter-lint.py <slug>`.

### 3.1 What goes in the margin column

The margin is a quarter of the page: it must carry real content, not only
`\source` notes.  **Aim for 3–4 margin items per page** counting `\source`
and `\term` glosses — roughly 10–20 items in a 5-page chapter, 30–50 in a
long one — and **write them while writing the chapter**, not as a later
pass.  The body keeps the single line of argument; everything that supports
it goes to the margin.

| Put in the margin | Macro | Example |
|---|---|---|
| Where the material comes from | `\source` | one per section (required) |
| Term in the other language | `\term` | automatic |
| **Real-world numbers** | `\margin` | "L1: 32 KiB, 4 cycles; L2: 256 KiB, 12 cycles on Intel Skylake" |
| **Notation and assumptions** | `\margin` | what a symbol means, units, "a write takes one cycle here" |
| **Link to another chapter** | `\margin` | "same idea as the reservation stations of Lesson 7" |
| **Source vs textbook terminology** | `\caution` | a term the source uses with a different meaning than the textbook |
| **Common misconception, sign error** | `\caution` | "a speedup below 1 is a slowdown" |
| **Rule of thumb, shortcut, mnemonic** | `\tip` | "tag width = address − index − offset" |
| **Longer aside (> 3 lines)** | `\sidenote` | why a design exists, a named implementation, a short history |
| **Version or API caveat** | `\caution` / `\margin` | "renamed in LLVM 17", "deprecated since …" |
| Small illustration | `marginfigure` | state diagram, small plot |

- **Density limit**: at most ~3 margin items within a short run of text;
  the checker reports "margin notes moved down".  A new chapter keeps it at
  0–2.  During a pass over finished chapters (e.g. the proofreading pass,
  `workflow.md` §4) a chapter's count must never rise above its count
  before the pass (`tools/chapter-check.sh … --max-moved <baseline>`).  A
  chapter that stays above 2 for a documented reason is listed, with the
  reason, in `book.md`.
- **Copyfitting is automatic.**  The class aligns a margin note's first
  line with the baseline of its anchor line, lifts a note that would run
  below the text block into free space above it (a note never hangs below
  the block), and as a last resort carries it to the top of the next page
  with a "Marginpar on page N carried over to the next page" warning in the
  log.  So the "moved down" count above means notes pushed below their
  anchors by crowding, not notes running off the page; a "carried over"
  warning means the page's margin is full and the chapter should thin it
  out.
- **Real-world numbers are welcome even when the source does not give
  them** — they are what makes the notes usable later.  Name where the
  number comes from in the same note or an adjacent `\source` (vendor
  manual, textbook figure, paper, official documentation), so that source
  content and added context stay distinguishable.  Verify every number;
  keep them few, current and uncontroversial; never invent one.
- **One number per fact across the book.**  A real-world number that
  appears in more than one chapter is identical everywhere, with the same
  source: in cs6290-notes the Skylake branch-misprediction penalty is
  16–20 cycles and its L3 latency 44 cycles in every chapter that mentions
  them.  When a pass corrects such a number, it corrects every occurrence
  (`grep -rn` both editions).
- Do not park body-level reasoning in the margin: if a reader needs it to
  follow the argument, it belongs in the body.

### 3.2 Units, quotations, references in prose

- Every quantity with a unit is set with `siunitx`: `\SI{4}{\milli\second}`,
  `\num{1e6}`, `\SIrange{10}{20}{\nano\second}`.  Binary sizes use the
  IEC prefixes (`\SI{4}{\kibi\byte}`, `\mebi`, `\gibi`, `\tebi`), never a
  literal "KB" or "MB" inside `\SI`.
- Quotation marks are `\enquote{…}`, never typed quote characters.
- Other chapters in prose: `Lesson~7` / `Chapter~7`, with a tie (JA: 第7章).
  Textbook chapters as `ch.~N` (`OSTEP ch.~7`), sections with the `§`
  character, never `\S` (`Silberschatz et al.\ §3.4`).

## 4. Labels, figures, bibliography

- Labels are unique across the whole book and carry the chapter number:
  `sec:l04-btb`, `fig:l04-btb`, `tab:l04-…`, `eq:l04-…`, `def:l04-…`,
  `ex:l04-…`, `lst:l04-…`.  EN and JA use the **same** labels.
- **Terms at first use.**  A term that `glossary.tsv` assigns to a chapter
  (column `lesson`) is `\term`ed at its first use in that chapter, in both
  editions; other chapters do not `\term` it again (§3).
  `tools/glossary-check.py` lists terms that are missing, re-`\term`ed
  elsewhere, absent from the glossary, or carry a gloss or reading that
  differs from it.
- Plain `\label{…}` inside `example`/`note` is enough — `\cref` prints
  "Example"/"Note".
- Cross-references: `\cref{…}` (a list or range such as
  `\cref{sec:a,sec:b,sec:c}` is fine in both editions); to another chapter
  in prose: `Lesson~7` (EN, §3.2) / "第7章" (JA), numbers from
  `syllabus.json`, and only to a chapter that actually treats the topic.
  Japanese chapters do not use `\Cref`.
- Figures shared by both editions: `figures/lNN-<name>.tex`, pure TikZ,
  language-dependent text via `\iflangja{日本語}{English}`, must fit the
  body width (120 mm) — or the margin (50 mm) in `marginfigure` (wrap in
  `\resizebox{\linewidth}{!}{…}` if needed).  Japanese labels are wider than
  English ones: size boxes for the Japanese text (§8).
- Every figure file starts with a header comment: a one-line description,
  what the figure shows, `Usage: \input{figures/lNN-name}`, and the intended
  width (body 120 mm or margin 50 mm).  Language-dependent text appears only
  inside `\iflangja{}{}` (the template's sample `figures/l01-pipeline-stages.tex`
  shows the form).
- Bibliography: new entries go only into `bib/<NN-slug>.bib` of your chapter
  (listed in both `main.tex` by `tools/sync-main.py`), after checking with
  `grep -rn "{key," references.bib bib/` that the key does not exist.  Only
  cite works you are certain exist, with correct authors/venue/year; for
  online documentation use `@online` with `url` and `urldate`.

## 5. Code

- `lstlisting` with the language given in `book.md`; `numbers=none` for
  short snippets.  Languages that `listings` does not know (LLVM IR, MLIR,
  TableGen, …) are defined in `book-preamble.tex`, never in the class.
- Lines ≤ 60 characters (the body is 120 mm wide).
- `\end{lstlisting}` must start at column 0 (no indentation), even inside
  `example`: leading spaces before it add an empty last line to the listing.
- Code copied from a project must respect its license; prefer short,
  self-written snippets that show the idea.

## 6. Japanese edition

- Mirrors the English chapter **exactly**: same sections in the same order,
  same equations, figures, tables, labels, examples, margin notes, key
  points.  Translate, do not summarize or extend.
- である調．Punctuation `，` and `．` (full-width comma and period).  Keep
  established English acronyms and identifiers (CPI, TLB, RPC, SSA, IR).
  Use `glossary.tsv` for every technical term.
- `\term[よみ]{語}[English term]` — reading in hiragana, English gloss.
  With `index=dual` the Japanese edition also carries an English index
  built from the glosses, so give every defining `\term` its gloss.
- `\lessoninfo` keywords separated by `，`; items in `\source` and
  `textbook=` separated by `；`; `video={Lesson 4，動画 1--48}`; key point
  summary title `[章のまとめ]`; other chapters as `第N章`.
- Author names in the text: 「Silberschatz ら」, 「Birrell と Nelson」.
- Every `\term` whose word contains kana or kanji (katakana included) gets
  a hiragana reading; a Latin acronym (TLB, RPC) has none.
- A space between a Latin word and adjacent Japanese text (`CPU スケジューラ`,
  `wait 操作`); none between a numeral and a unit or counter (`3個`,
  `16ビット`).  Numeric ranges as `N--N` (`1--48`), never `〜`.
- Numbers, units, math and code identical to the English edition.
- **Parity is checked mechanically**: the ordered sequence of commands of
  the two editions — sections, labels, `\input`, `\source`, `\margin`,
  `\sidenote`, `\tip`, `\caution`, `\term`, environments — must be
  identical (`tools/parity-check.py`).  Each margin item is anchored at the
  **same sentence** in both editions; a difference kept for layout is
  marked with a `%` comment next to the item (`workflow.md` §4).

## 7. Checking a chapter

```sh
tools/chapter-check.sh en 04-branches     # or ja
```

Required before a chapter is done: 0 errors, 0 undefined references
(references to other chapters are listed separately and are fine), 0
undefined citations, 0 multiply-defined labels, 0 missing glyphs, 0 overfull
boxes > 3 pt, at most 2 "margin notes moved down" (during a pass: at most
the chapter's count before it, §3.1).  Then **read every
rendered page** `.png/<lang>-<slug>-NN.png`: a clean log does not mean a
correct page (a font-loading bug once printed `\underbrace` as black boxes
with no warning at all).

## 8. Page layout

Layout is judged on the rendered pages of the **whole book**
(`tools/book-check.sh`), because page breaks in a chapter-only build differ.
Fix layout only in the chapter sources; never edit `format/lnotes.cls` in a
book repository (see `workflow.md`, *Class changes*).

- **Margin notes below the text block.**  A note anchored on one of the last
  lines of a page runs past the bottom of the text block.  Re-anchor it
  earlier in the same passage (the sentence it refers to usually allows
  that); do not delete information to make it fit.  A one-line gloss that
  ends ~2 mm low is acceptable.
- **Pages holding only the summary box.**  `keypoint` boxes do not break
  across pages, and `\needspace` directly before one has no effect.  Keep the
  last paragraph, item or figure together with the summary instead
  (`\Needspace{<lines>\baselineskip}` before that paragraph, or move a
  float), or tighten the chapter's last page.
- **Headings at the bottom of a page.**  `\Needspace{5\baselineskip}` (capital
  N: it also works right after a paragraph) before the heading.  Use the
  smallest value that works; a large value leaves a visibly empty page end.
- **`\Needspace` is a last resort** for a heading or listing that must not
  be split from what follows.  Add it only once the page layout is final,
  and remove the ones before headings whose break no longer matters.
- **Floats.**  Prefer `[tb]` or `[htbp]`; a float that lands in the middle of
  a listing or splits an example is moved before the paragraph it
  illustrates.  Float pages are top-aligned by the class.
- **Listings.**  Do not let a short listing (< 6 lines) split across pages;
  `\Needspace` before it.  A listing that opens an `example` starts on its
  own line automatically.
- **Tables.**  Balance `p{}` column widths so short entries do not break
  mid-word; Japanese cells need more width than English ones.
  `widetable` spans body + margin, but try a narrower `\tabcolsep` first
  (`\setlength{\tabcolsep}{4pt}` inside the table; §2).
- **Japanese figures.**  Boxes sized for English labels overflow with
  Japanese ones: widen the box or break the label inside the `\iflangja`
  branch only — the English output must not change.
- **Figure text size.**  Nothing smaller than `\scriptsize` in a figure; if a
  figure only fits with `\tiny`, redesign it.
- **Print editions.**  Layout is judged on the A4 screen edition only.
  `print=a5|b5|b6|shinsho` (`make en-a5`, `tools/book-check.sh en --print a5`)
  scales that design to a two-sided compact page (body font 10 pt × `scale`:
  0.7, 0.85, 0.65, 0.65; `scale=` overrides); figures and tables are scaled
  and, if still too wide, shrunk to the measure (`lnotes-fit:` in the log).
  Never edit a chapter for a print size.  Below `scale=0.6` text is not
  readable; figure labels fall to about 4.5 pt.
