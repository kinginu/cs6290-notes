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
- Margin density: at most ~3 margin items within a short paragraph run; the
  checker reports "margin notes moved down" — keep it at 0–2.

## 4. Labels, figures, bibliography

- Labels are unique across the whole book and carry the lesson number:
  `sec:l04-btb`, `fig:l04-btb`, `tab:l04-…`, `eq:l04-…`, `def:l04-…`,
  `ex:l04-…`.  (Lessons 1–3 of cs6290 predate this rule and are unprefixed.)
  EN and JA use the **same** labels.
- Cross-references: `\cref{…}`; to another chapter in prose: "Lesson 7"
  (EN) / "第7章" (JA), numbers from the chapter list.
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

## 6. Japanese edition

- Mirrors the English chapter **exactly**: same sections in the same order,
  same equations, figures, tables, labels, examples, margin notes, key
  points.  Translate, do not summarize or extend.
- である調．Punctuation `，` and `．` (full-width comma and period), as in
  the existing chapters.  Keep established English acronyms (CPI, BTB, TLB,
  RPC).  Use `glossary.tsv` for every technical term.
- `\term[よみ]{語}[English term]` — reading in hiragana, English gloss.
- `\lessoninfo` keywords separated by `，`; `video={Lesson 4，動画 1--48}` /
  `video={P2L1}`; key point summary title `[章のまとめ]`.
- Numbers, units, math identical to the English edition.

## 7. Checking your work

```sh
tools/chapter-check.sh en 04-branches     # or ja
```

Required before a chapter is done: 0 errors, 0 undefined references
(references to other chapters are listed separately and are fine), 0
undefined citations, 0 multiply-defined labels, 0 missing glyphs, 0 overfull
boxes > 3 pt.  Then open the rendered pages `.png/<lang>-<slug>-NN.png` and
check that figures fit, tables do not overflow, and margin notes do not
collide.  Do not commit; the maintainer commits.
