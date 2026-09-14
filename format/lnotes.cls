%% lnotes.cls -- bilingual (en/ja) lecture notes with a sidebar column
%%
%% Layout: single-column body on the left, a narrow margin column on the
%% right (Tufte-style sidenotes) separated by a thin vertical rule.
%% Engine:  LuaLaTeX only (luatexja for Japanese).
%%
%% Class options
%%   en | ja        document language (default: en)
%%   norule         do not draw the vertical rule between body and margin
%%   <anything else> is passed to scrbook (e.g. fontsize=11pt)
%%
%% Public macros (see README for details)
%%   \iflangja{<ja>}{<en>}   \ja{...}  \en{...}
%%   \sidenote{...}  \margin{...}  \source{...}  \tip{...}  \caution{...}
%%   \term[<sort key>]{<word>}[<margin gloss>]   \term*  (no index entry)
%%   \lessoninfo{video=..., textbook=..., keywords=...}
%%   \definitionname, \keypointname, ... -- localized strings (renewable)
%% Environments
%%   definition  example  note  keypoint
%%   marginfigure  margintable  widefigure  widetable

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{lnotes}[2026/09/14 v0.1 Bilingual sidebar lecture notes]

\RequirePackage{iftex}
\RequireLuaTeX

%% ------------------------------------------------------------------ options
\newif\ifln@ja
\newif\ifln@rule \ln@ruletrue
\DeclareOption{en}{\ln@jafalse}
\DeclareOption{ja}{\ln@jatrue}
\DeclareOption{norule}{\ln@rulefalse}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{scrbook}}
\ExecuteOptions{en}
\ProcessOptions\relax

\LoadClass[%
  paper=a4,
  fontsize=10pt,
  oneside,            % margin column is always on the right (screen reading)
  open=any,
  numbers=noenddot,
  chapterprefix=true,
  headings=normal,
  bibliography=totoc,
  index=totoc,
  listof=totoc,
]{scrbook}

\RequirePackage{etoolbox}

%% -------------------------------------------------------- language helpers
\newcommand*{\iflangja}{\ifln@ja\expandafter\@firstoftwo\else\expandafter\@secondoftwo\fi}
\newcommand*{\ja}[1]{\iflangja{#1}{}}
\newcommand*{\en}[1]{\iflangja{}{#1}}
\newcommand*{\ln@langcode}{\iflangja{ja}{en}}

%% ------------------------------------------------------------------- fonts
\RequirePackage{fontspec}
\RequirePackage{unicode-math}
\ifln@ja
  \setmainfont{Libertinus Serif}
  \setsansfont{Libertinus Sans}
  \setmonofont{Libertinus Mono}[Scale=MatchLowercase]
  % Harano Aji fonts ship with TeX Live, nothing to install.
  % match  -> \sffamily also switches the Japanese font to gothic
  % deluxe -> bold/medium weights for both mincho and gothic
  \RequirePackage[haranoaji,match,deluxe]{luatexja-preset}
  \ltjsetparameter{jacharrange={-2}} % Greek/Cyrillic are Latin-side chars
\else
  % The English edition still needs Japanese glyphs for margin glosses
  % (\term{pipeline}[パイプライン]).  Use luaotfload's font fallback so
  % CJK characters silently switch to Harano Aji without loading luatexja.
  \directlua{
    luaotfload.add_fallback("lnserifjp", {"HaranoAjiMincho-Regular:mode=node;script=hani;"})
    luaotfload.add_fallback("lnsansjp",  {"HaranoAjiGothic-Regular:mode=node;script=hani;"})
  }
  \setmainfont{Libertinus Serif}[RawFeature={fallback=lnserifjp}]
  \setsansfont{Libertinus Sans}[RawFeature={fallback=lnsansjp}]
  \setmonofont{Libertinus Mono}[Scale=MatchLowercase, RawFeature={fallback=lnsansjp}]
\fi
\setmathfont{Libertinus Math}
\RequirePackage{microtype}

%% ------------------------------------------------------------------ colors
\RequirePackage{xcolor}
\definecolor{ln-accent}{HTML}{1F4E79}   % headings, labels
\definecolor{ln-rule}{HTML}{B0B0B0}     % vertical rule, frames
\definecolor{ln-muted}{HTML}{555555}    % margin text
\definecolor{ln-tip}{HTML}{2E7D32}
\definecolor{ln-caution}{HTML}{C62828}
\definecolor{ln-source}{HTML}{6A1B9A}
\definecolor{ln-box}{HTML}{F4F6F8}

%% ---------------------------------------------------------------- geometry
%% A4 = 210 x 297 mm.  Body 120 mm, gap 8 mm, margin column 50 mm.
%% The margin column is ~24% of the page width.
\RequirePackage[%
  a4paper,
  left=20mm,
  top=25mm,
  bottom=25mm,
  textwidth=120mm,
  marginparsep=8mm,
  marginparwidth=50mm,
  headsep=6mm,
  footskip=12mm,
]{geometry}
\setlength{\marginparpush}{4pt}
%% Full width (body + gap + margin column) for wide floats
\newlength{\fullwidth}
\setlength{\fullwidth}{\dimexpr\textwidth+\marginparsep+\marginparwidth\relax}

%% ---------------------------------------------------------- vertical rule
\RequirePackage{eso-pic}
\ifln@rule
  \AddToShipoutPictureBG{%
    \AtTextLowerLeft{%
      \makebox[0pt][l]{%
        \hspace*{\dimexpr\textwidth+0.5\marginparsep\relax}%
        \color{ln-rule}\rule[-6pt]{0.4pt}{\dimexpr\textheight+12pt\relax}}}}
\fi

%% --------------------------------------------------------------- headings
\RequirePackage[automark, autooneside=false, headwidth=textwithmarginpar, footwidth=textwithmarginpar]{scrlayer-scrpage}
\pagestyle{scrheadings}
\clearpairofpagestyles
\automark[section]{chapter}
\ihead{\small\sffamily\color{ln-muted}\leftmark}
\ohead{\small\sffamily\color{ln-muted}\rightmark}
\ofoot*{\small\sffamily\pagemark}
\setkomafont{disposition}{\sffamily\bfseries\color{ln-accent}}
\setkomafont{chapterprefix}{\normalfont\sffamily\normalsize\color{ln-muted}}
\setkomafont{chapter}{\sffamily\bfseries\LARGE\color{ln-accent}}
\RedeclareSectionCommand[beforeskip=0pt, afterskip=1.5\baselineskip]{chapter}
\setcounter{secnumdepth}{2}
\setcounter{tocdepth}{1}

%% --------------------------------------------------------- localized text
%% Every string is a macro so a document can \renewcommand it.
%% KOMA-Script's own names (\chaptername, \indexname, ...) are re-applied at
%% \begin{document}, hence the \AtBeginDocument for those.
\ifln@ja
  \AtBeginDocument{%
    \renewcommand*{\chapterformat}{第\thechapter 章}%
    \renewcommand*{\chaptermarkformat}{第\thechapter 章\enskip}%
    \renewcommand*{\partformat}{第\thepart 部}%
    \renewcommand*{\partname}{部}%
    \renewcommand*{\contentsname}{目次}%
    \renewcommand*{\listfigurename}{図目次}%
    \renewcommand*{\listtablename}{表目次}%
    \renewcommand*{\indexname}{索引}%
    \renewcommand*{\bibname}{参考文献}%
    \renewcommand*{\figurename}{図}%
    \renewcommand*{\tablename}{表}%
    \renewcommand*{\appendixname}{付録}%
  }
  \newcommand*{\definitionname}{定義}
  \newcommand*{\examplename}{例}
  \newcommand*{\notename}{注}
  \newcommand*{\keypointname}{要点}
  \newcommand*{\sourcename}{出典}
  \newcommand*{\tipname}{ヒント}
  \newcommand*{\cautionname}{注意}
  \newcommand*{\videoname}{講義動画}
  \newcommand*{\textbookname}{教科書}
  \newcommand*{\keywordsname}{キーワード}
\else
  \AtBeginDocument{\renewcommand*{\chaptername}{Lesson}}
  \newcommand*{\definitionname}{Definition}
  \newcommand*{\examplename}{Example}
  \newcommand*{\notename}{Note}
  \newcommand*{\keypointname}{Key point}
  \newcommand*{\sourcename}{Source}
  \newcommand*{\tipname}{Tip}
  \newcommand*{\cautionname}{Caution}
  \newcommand*{\videoname}{Lecture}
  \newcommand*{\textbookname}{Textbook}
  \newcommand*{\keywordsname}{Keywords}
\fi

%% ------------------------------------------------------------- margin core
\RequirePackage{marginnote}
\RequirePackage{ragged2e}
\newcommand*{\ln@marginfont}{\footnotesize\sffamily\color{ln-muted}\RaggedRight}
\renewcommand*{\marginfont}{\ln@marginfont}
\renewcommand*{\raggedrightmarginnote}{\RaggedRight}
%% Inside boxes (tcolorbox, minipage, floats) \marginpar is lost, so the
%% margin macros fall back to \marginnote there.  Set by the box envs below.
\newif\ifln@inbox
\newcommand{\ln@margin}[1]{%
  \ifln@inbox
    \marginnote{#1}%
  \else
    \marginpar{\ln@marginfont #1}%
  \fi}

%% \sidenote{text}  numbered per chapter, number in text and margin
\newcounter{sidenote}[chapter]
\renewcommand*{\thesidenote}{\arabic{sidenote}}
\newcommand{\sidenote}[1]{%
  \refstepcounter{sidenote}%
  \textsuperscript{\thesidenote}%
  \ln@margin{\textsuperscript{\thesidenote}\,#1}}

%% \margin{text}  unnumbered margin note
\newcommand{\margin}[1]{\ln@margin{#1}}

%% Labelled margin notes
\newcommand{\ln@labelled}[3]{% color, label, text
  \ln@margin{\textcolor{#1}{\textbf{#2}}\enspace #3}}
\newcommand{\source}[1]{\ln@labelled{ln-source}{\sourcename}{#1}}
\newcommand{\tip}[1]{\ln@labelled{ln-tip}{\tipname}{#1}}
\newcommand{\caution}[1]{\ln@labelled{ln-caution}{\cautionname}{#1}}

%% ------------------------------------------------------------------- index
%% upmendex sorts both English and Japanese (kana) correctly.
%% Japanese entries need a reading for sorting: \index{よみ@語}.
%% The upmendex style file (format/lnotes-<lang>.ist) is selected in
%% .latexmkrc, because latexmk -- not imakeidx -- runs the index processor.
\RequirePackage{imakeidx}
\makeindex[intoc,columns=2]
%% Cross-references inside the index: \index{BTB|see{branch target buffer}}
\ifln@ja
  \renewcommand*{\seename}{→}
  \renewcommand*{\alsoname}{→ 関連:}
\fi

%% How a term looks in the body text: italics in English, bold gothic in
%% Japanese (Japanese fonts have no italics).
\newcommand{\termformat}[1]{\iflangja{\textsf{\textbf{#1}}}{\emph{#1}}}

%% \term[<sort key>]{<word>}[<margin gloss>]
%%   - typesets <word> with \termformat
%%   - adds an index entry (sorted by <sort key> when given)
%%   - shows <margin gloss> (e.g. the English term) in the margin
%% \term* does the same without the index entry (for repeated mentions).
\NewDocumentCommand{\term}{s o m o}{%
  \termformat{#3}%
  \IfBooleanF{#1}{%
    \IfValueTF{#2}{\index{#2@#3}}{\index{#3}}%
  }%
  \IfValueT{#4}{\ln@margin{\textcolor{ln-accent}{$\triangleright$}\,#4}}%
}

%% ------------------------------------------------------------- theorem envs
\RequirePackage{amsthm}
\newtheoremstyle{lnplain}%
  {0.6\baselineskip}{0.6\baselineskip}% above / below
  {\normalfont}%                        body font
  {}%                                   indent
  {\sffamily\bfseries\color{ln-accent}}% head font
  {.}{0.6em}%                           punctuation, space after head
  {\thmname{#1}\thmnumber{ #2}\thmnote{ \normalfont\sffamily(#3)}}
%% The environments themselves are declared after cleveref (end of class).

%% keypoint: shaded box for take-aways.  Optional argument = subtitle.
\RequirePackage[skins,breakable]{tcolorbox}
\newtcolorbox{keypoint}[1][]{%
  enhanced, breakable, sharp corners,
  colback=ln-box, colframe=ln-accent, boxrule=0pt, leftrule=2pt,
  left=6pt, right=6pt, top=4pt, bottom=4pt,
  fontupper=\normalfont,
  title={\keypointname\notblank{#1}{ --- #1}{}},
  fonttitle=\sffamily\bfseries, coltitle=ln-accent,
  detach title,
  before upper={\ln@inboxtrue\tcbtitle\par},
}

%% ------------------------------------------------------------ lesson info
%% \lessoninfo{video={...}, textbook={...}, keywords={...}}
%% Keys are parsed with the LaTeX kernel key system (\DeclareKeys/\SetKeys).
\RequirePackage{enumitem}
\DeclareKeys[lessoninfo]{
  video    .store = \ln@li@video,
  textbook .store = \ln@li@textbook,
  keywords .store = \ln@li@keywords,
}
\newcommand{\lessoninfo}[1]{%
  \begingroup
  \def\ln@li@video{}\def\ln@li@textbook{}\def\ln@li@keywords{}%
  \SetKeys[lessoninfo]{#1}%
  \ifboolexpr{ test {\ifdefempty{\ln@li@video}}
           and test {\ifdefempty{\ln@li@textbook}}
           and test {\ifdefempty{\ln@li@keywords}} }{}{%
    \begin{tcolorbox}[enhanced, sharp corners, colback=white,
        colframe=ln-rule, boxrule=0.4pt, left=6pt, right=6pt,
        top=4pt, bottom=4pt, fontupper=\small\sffamily]
      \begin{description}[nosep, leftmargin=7em, labelwidth=6em, font=\bfseries\color{ln-muted}]
        \ifdefempty{\ln@li@video}{}{\item[\videoname] \ln@li@video}%
        \ifdefempty{\ln@li@textbook}{}{\item[\textbookname] \ln@li@textbook}%
        \ifdefempty{\ln@li@keywords}{}{\item[\keywordsname] \ln@li@keywords}%
      \end{description}
    \end{tcolorbox}}%
  \endgroup}

%% ------------------------------------------------------------------ floats
\RequirePackage{graphicx}
\RequirePackage{booktabs}
\RequirePackage{caption}
\captionsetup{font={small,sf}, labelfont={bf,color=ln-accent}, skip=4pt}
\newsavebox{\ln@marginbox}

%% marginfigure / margintable: figures/tables placed in the margin column
\newenvironment{marginfigure}{%
  \begin{lrbox}{\ln@marginbox}%
  \begin{minipage}{\marginparwidth}\ln@inboxtrue
  \captionsetup{type=figure,font={footnotesize,sf}}\ln@marginfont\centering}%
  {\end{minipage}\end{lrbox}\marginpar{\usebox{\ln@marginbox}}}
\newenvironment{margintable}{%
  \begin{lrbox}{\ln@marginbox}%
  \begin{minipage}{\marginparwidth}\ln@inboxtrue
  \captionsetup{type=table,font={footnotesize,sf}}\ln@marginfont\centering}%
  {\end{minipage}\end{lrbox}\marginpar{\usebox{\ln@marginbox}}}

%% widefigure / widetable: floats spanning body + margin column
\newenvironment{widefigure}[1][tbp]{%
  \begin{figure}[#1]\ln@inboxtrue
  \begin{minipage}{\fullwidth}\centering}%
  {\end{minipage}\end{figure}}
\newenvironment{widetable}[1][tbp]{%
  \begin{table}[#1]\ln@inboxtrue
  \begin{minipage}{\fullwidth}\centering}%
  {\end{minipage}\end{table}}

%% ------------------------------------------------------- code & algorithms
\RequirePackage{listings}
\lstset{%
  basicstyle=\small\ttfamily,
  keywordstyle=\color{ln-accent}\bfseries,
  commentstyle=\color{ln-muted}\itshape,
  numberstyle=\tiny\color{ln-muted},
  numbers=left, numbersep=6pt,
  frame=leftline, framerule=0.4pt, rulecolor=\color{ln-rule},
  xleftmargin=1.2em,
  breaklines=true, columns=fullflexible, keepspaces=true,
  showstringspaces=false,
  aboveskip=0.6\baselineskip, belowskip=0.6\baselineskip,
}
\RequirePackage{algorithm}
\RequirePackage{algpseudocode}

%% ------------------------------------------------------------- math & misc
\RequirePackage{amsmath}
\RequirePackage{mathtools}
\RequirePackage{siunitx}
\RequirePackage{tikz}
\usetikzlibrary{arrows.meta,positioning,shapes,calc,fit,backgrounds}
\RequirePackage{csquotes}
\RequirePackage{needspace}
\RequirePackage{subfiles}

%% ------------------------------------------------------------ bibliography
\RequirePackage[backend=biber,style=numeric,sorting=none]{biblatex}
\ifln@ja
  \DefineBibliographyStrings{english}{bibliography={参考文献}, references={参考文献}}
\fi

%% ---------------------------------------------------------------- hyperref
\RequirePackage[%
  colorlinks=true,
  linkcolor=ln-accent, citecolor=ln-source, urlcolor=ln-accent,
  bookmarksnumbered=true,
  pdfusetitle,
]{hyperref}
\AtBeginDocument{\hypersetup{pdflang=\ln@langcode}}
\RequirePackage[capitalise,noabbrev]{cleveref}
\ifln@ja
  \crefformat{chapter}{第#2#1#3章}
  \Crefformat{chapter}{第#2#1#3章}
  \crefformat{section}{#2#1#3~節}
  \Crefformat{section}{#2#1#3~節}
  \crefformat{subsection}{#2#1#3~節}
  \Crefformat{subsection}{#2#1#3~節}
  \crefname{figure}{図}{図}          \Crefname{figure}{図}{図}
  \crefname{table}{表}{表}           \Crefname{table}{表}{表}
  \crefname{equation}{式}{式}        \Crefname{equation}{式}{式}
  \crefname{algorithm}{アルゴリズム}{アルゴリズム}
  \Crefname{algorithm}{アルゴリズム}{アルゴリズム}
  \crefname{lstlisting}{リスト}{リスト} \Crefname{lstlisting}{リスト}{リスト}
  \crefname{definition}{定義}{定義}  \Crefname{definition}{定義}{定義}
  \crefname{example}{例}{例}         \Crefname{example}{例}{例}
  \crefname{note}{注}{注}            \Crefname{note}{注}{注}
  \crefname{sidenote}{注}{注}        \Crefname{sidenote}{注}{注}
  \crefname{page}{ページ}{ページ}    \Crefname{page}{ページ}{ページ}
  \crefformat{part}{第#2#1#3部}      \Crefformat{part}{第#2#1#3部}
\else
  \crefname{definition}{Definition}{Definitions}
  \crefname{example}{Example}{Examples}
  \crefname{note}{Note}{Notes}
\fi

%% definition / example / note share one counter per chapter
\theoremstyle{lnplain}
\newtheorem{definition}{\definitionname}[chapter]
\newtheorem{example}[definition]{\examplename}
\newtheorem{note}[definition]{\notename}
%% cleveref would name all three after the shared counter ("Definition");
%% alias the counter inside each environment so \cref prints the right name.
\AtBeginEnvironment{example}{\crefalias{definition}{example}}
\AtBeginEnvironment{note}{\crefalias{definition}{note}}

%% --------------------------------------------------------- misc typography
\setlength{\parskip}{0pt}
\ifln@ja
  \setlength{\parindent}{1\zw}
\fi
\setlist{nosep}

\endinput
