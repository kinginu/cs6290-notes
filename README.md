# latex-lecture-notes-template

A LaTeX template for **bilingual (English / Japanese) lecture notes** with a
Tufte-style sidebar: the body text on the left, a narrow right-hand column
(separated by a thin vertical rule) for sidenotes, sources, tips and
small figures.  The whole toolchain lives in a Docker image so it can be
moved between machines without installing TeX.

[日本語の説明はこちら](#日本語)

## Features

- `lnotes.cls` — one class, `\documentclass[en]{lnotes}` or
  `[ja]`; fonts, hyphenation and all fixed strings switch with the option.
- Margin column macros: `\sidenote`, `\margin`, `\source`, `\tip`,
  `\caution`, `marginfigure`, `margintable`; wide floats with `widefigure`.
- `\term` registers a term in the index and shows its translation in the
  margin.  The index is built with `upmendex`, so Japanese entries sort in
  kana order.
- `definition` / `example` / `note` environments and a shaded `keypoint` box.
- `\lessoninfo{video=…, textbook=…, keywords=…}` header block per chapter.
- Chapters are `subfiles`: a single chapter can be compiled on its own
  (fast edit loop in VS Code) or as part of the whole book.
- Pinned TeX Live 2025 Docker image, VS Code dev container, GitHub Actions
  that build both PDFs on every push and attach them to `v*` releases.

## Layout

```
.
├── format/                 shared class, index styles   (do not edit per course)
│   ├── lnotes.cls
│   ├── lnotes-en.ist
│   └── lnotes-ja.ist
├── en/  main.tex  lessons/NN-slug.tex     English edition
├── ja/  main.tex  lessons/NN-slug.tex     Japanese edition (same file names)
├── figures/                TikZ / images shared by both editions
├── references.bib
├── .latexmkrc  Makefile  Dockerfile  compose.yml
├── .devcontainer/  .vscode/  .github/workflows/
└── README.md  LICENSE
```

Page geometry (A4): body 120 mm, gap 8 mm, margin column 50 mm
(~24 % of the page width).  The margin is always on the right (one-sided,
intended for on-screen reading).

## Quick start

```sh
# 1. Create a course repository from this template
gh repo create cs6290-notes --template <owner>/latex-lecture-notes-template --private --clone
cd cs6290-notes

# 2. Build the image once (~3 GB download), then build both editions
make docker-build
make docker-all          # -> en/build/main.pdf, ja/build/main.pdf
make docker-en           # one edition
make docker-dist         # -> dist/notes-en.pdf, dist/notes-ja.pdf
make docker-shell        # a shell inside the container
```

Inside the container (or on any machine with TeX Live 2025) the same targets
work without the `docker-` prefix: `make en`, `make ja`, `make all`, `make clean`.

### VS Code

Open the folder and choose **Reopen in Container**; LaTeX Workshop is
installed and configured (`.vscode/settings.json`) to run `latexmk` with the
repo's `.latexmkrc`.

- Open `en/main.tex` and build → whole English book.
- Open `en/lessons/03-foo.tex` and build → **that chapter only**
  (`latex-workshop.latex.rootFile.useSubFile` is on).  Cross references to
  other chapters show as `??` in a chapter-only build; that is expected.

### Writing a new lesson

1. Copy `en/lessons/02-lesson-skeleton.tex` to `en/lessons/NN-slug.tex` and
   the same under `ja/`.
2. Add `\subfile{lessons/NN-slug}` to **both** `main.tex` files.
3. Write.  Keep figures in `figures/` and switch labels with
   `\iflangja{日本語}{English}`.

## Macro reference

| Macro / environment | Purpose |
|---|---|
| `\sidenote{…}` | numbered margin note (numbers restart each chapter) |
| `\margin{…}` | unnumbered margin note |
| `\source{…}` | labelled *Source / 出典* note, e.g. `\source{H\&P §3.2}` or `\cite` |
| `\tip{…}` / `\caution{…}` | labelled *Tip / ヒント*, *Caution / 注意* notes |
| `\term[sortkey]{word}[gloss]` | emphasize `word`, index it (sorted by `sortkey` if given), print `gloss` in the margin |
| `\term*{word}` | same without an index entry (repeat mentions) |
| `\index{よみ@語}` | plain index entry with a reading |
| `definition`, `example`, `note` | numbered per chapter, shared counter, `\cref`-able |
| `keypoint` (`[subtitle]`) | shaded take-away box |
| `\lessoninfo{video=…, textbook=…, keywords=…}` | info block after `\chapter` |
| `marginfigure`, `margintable` | float in the margin column |
| `widefigure`, `widetable` | float spanning body + margin (`\fullwidth`) |
| `\iflangja{ja}{en}`, `\ja{…}`, `\en{…}` | language switches for shared files |
| `\definitionname`, `\keypointname`, `\sourcename`, … | localized strings; `\renewcommand` to change |

Class options: `en` (default) / `ja`, `norule` (no vertical rule), anything
else is passed to KOMA-Script `scrbook` (e.g. `fontsize=11pt`).

### Index readings (Japanese)

`upmendex` sorts by the string before `@`.  Katakana words need no reading;
words containing kanji do:

```latex
\term[きゃっしゅ]{キャッシュ}[cache]        % reading optional for katakana
\term[ぶんきよそく]{分岐予測}[branch prediction]
```

## Customizing

- Fonts: `format/lnotes.cls`, *fonts* section (Libertinus + Harano Aji;
  both ship with TeX Live).
- Column widths / rule: *geometry* and *vertical rule* sections.
- Chapter label (`Lesson 3` / `第3章`): `\chaptername` / `\chapterformat`
  in the *localized text* section — override in `main.tex` if a course uses
  "Module" or "Week".
- Colors: `ln-accent`, `ln-rule`, `ln-muted`, `ln-tip`, `ln-caution`,
  `ln-source`, `ln-box`.

## CI

`.github/workflows/build.yml` builds `dist/notes-en.pdf` and
`dist/notes-ja.pdf` in the same TeX Live image on every push / PR and
uploads them as a workflow artifact.  Pushing a tag `v*` attaches the PDFs
to a GitHub release.

## License

MIT for the template (`format/`, build files).  Notes written with it are
yours; choose a license for the content in your course repository.

---

## 日本語

英語・日本語の二言語で講義ノートを書くための LaTeX テンプレートです。
本文の右に細い縦罫線で区切った余白列（Tufte スタイルのサイドノート）を持ち、
補足・出典・ヒント・小さな図をそこに置きます。TeX 環境は Docker イメージに
閉じ込めてあるので、マシンを変えてもそのまま使えます。

### 使い方の要点

- `\documentclass[en]{lnotes}` / `[ja]` で言語を切り替え。フォント・
  見出し語（定義／Definition など）は自動で切り替わります。
- `en/` と `ja/` は同じファイル名で対応させ、`figures/` と
  `references.bib` は共有します。共有ファイル内の言語分岐は
  `\iflangja{日本語}{English}`。
- 章ごとのビルド: VS Code で `lessons/NN-slug.tex` を開いてビルドすると
  その章だけがコンパイルされます（他章への参照は `??` になります）。
- 索引: `\term[よみ]{語}[対訳]` で本文強調・索引登録・余白への対訳表示を
  一度に行います。漢字を含む語には読みを付けてください（カタカナ語は省略可）。
- ビルド: `make docker-build`（初回のみ）→ `make docker-all`。
  PDF は `en/build/main.pdf`, `ja/build/main.pdf` に出力されます。

### 新しい講義でのリポジトリ作成

GitHub の **Use this template** から新しいリポジトリを作成してください
（`gh repo create <name> --template <owner>/latex-lecture-notes-template`）。
