%% lnotes.cls -- bilingual (en/ja) lecture notes with a sidebar column
%%
%% Layout: single-column body on the left, a narrow margin column on the
%% right (Tufte-style sidenotes) separated by a thin vertical rule.
%% The title page, contents, bibliography and index span the full width.
%% An empty page follows the title page in every edition, so the contents
%% start on page 3 (two-sided: on a recto); two-sided, the body also starts
%% on a recto.
%% Engine:  LuaLaTeX only (luatexja for Japanese).
%% Files:   format/lnmarginfix.sty lays out the \marginpar notes (a fork of
%%          marginfix; LPPL 1.3c, unlike the MIT class); format/lnotes-en.ist,
%%          format/lnotes-ja.ist are the upmendex styles.
%%
%% Class options (key=value)
%%   en | ja        document language (default: en)
%%   lesson|chapter English chapter label "Lesson 3" (default) or "Chapter 3";
%%                  the Japanese edition always prints 第3章
%%   norule         do not draw the vertical rule between body and margin
%%   gloss=false    \term prints no margin gloss (default true)
%%   index=dual     a second index of the glosses, after the first (default single)
%%   print=<size>   a4 (default: screen edition, one-sided) or a compact
%%                  two-sided print edition: a5, b5, b6, shinsho (新書判)
%%   scale=<factor> print editions: override the size's scale factor
%%                  (body font = 10pt x factor; see the size table below)
%%   fontsize=<dim> body font size (default 10pt, or 10pt x scale in print)
%%   twoside[=..] | oneside   default: oneside for a4, twoside for print
%%   <anything else> is passed to scrbook
%%
%% Public macros (see README for details)
%%   \iflangja{<ja>}{<en>}   \ja{...}  \en{...}
%%   \sidenote{...}  \margin{...}  \source{...}  \tip{...}  \caution{...}
%%   \term[<sort key>]{<word>}[<margin gloss>]   \term*  (no index entry)
%%   \lessoninfo{video=..., sources=..., textbook=..., keywords=...}
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
\newif\ifln@print
\newif\ifln@gloss \ln@glosstrue
\def\ln@unitname{Lesson}
\def\ln@print{a4}
\def\ln@scale{}
\def\ln@fontsize{}
\def\ln@twoside{}
\newif\ifln@dualindex
\def\ln@str@single{single}
\def\ln@str@dual{dual}
\def\ln@setindex#1{\def\ln@tmp{#1}%
  \ifx\ln@tmp\ln@str@dual \ln@dualindextrue
  \else\ifx\ln@tmp\ln@str@single \ln@dualindexfalse
  \else\ClassError{lnotes}{Unknown value index=#1}{Use index=single or index=dual.}%
  \fi\fi}
\DeclareKeys[lnotes]{
  en       .code     = \ln@jafalse,
  ja       .code     = \ln@jatrue,
  norule   .code     = \ln@rulefalse,
  gloss    .if       = ln@gloss,
  index    .code     = \ln@setindex{#1},
  lesson   .code     = \def\ln@unitname{Lesson},
  chapter  .code     = \def\ln@unitname{Chapter},
  print    .store    = \ln@print,
  scale    .store    = \ln@scale,
  fontsize .store    = \ln@fontsize,
  twoside  .code     = \def\ln@twoside{#1}%
                       \ifx\ln@twoside\@empty\def\ln@twoside{true}\fi,
  oneside  .code     = \def\ln@twoside{false},
}
\DeclareUnknownKeyHandler[lnotes]{\PassOptionsToClass{\CurrentOption}{scrbook}}
\ProcessKeyOptions[lnotes]

%% Print sizes, in mm:
%%   {paper w}{paper h}{inner margin}{textwidth}{marginparsep}{marginparwidth}
%%   {top}{bottom}{scale}
%% The scale shrinks the A4 design (fonts, skips, figures) to the page; the
%% body font is 10pt x scale.  \@namedef, not \def: a digit ends a csname.
\@namedef{ln@sz@a5}{{148}{210}{15}{93}{3.5}{30}{13}{14}{0.7}}
\@namedef{ln@sz@b5}{{182}{257}{18}{106}{4.5}{43.5}{16}{18}{0.85}}
\@namedef{ln@sz@b6}{{128}{182}{13}{73}{3}{32}{12}{13}{0.65}}
\@namedef{ln@sz@shinsho}{{113}{176}{13}{63}{3}{27}{12}{13}{0.65}}
\def\ln@tmp{a4}
\ifx\ln@print\ln@tmp \ln@printfalse \else \ln@printtrue \fi
\ifln@print
  \ifcsname ln@sz@\ln@print\endcsname\else
    \ClassError{lnotes}{Unknown print size `\ln@print'}%
      {Use print=a4, a5, b5, b6 or shinsho.  Using a5.}%
    \def\ln@print{a5}%
  \fi
  \def\ln@getsz#1#2#3#4#5#6#7#8#9{%
    \def\ln@pw{#1mm}\def\ln@ph{#2mm}\def\ln@in{#3mm}\def\ln@tw{#4mm}%
    \def\ln@sep{#5mm}\def\ln@mpw{#6mm}\def\ln@top{#7mm}\def\ln@bot{#8mm}%
    \ifx\ln@scale\@empty \def\ln@scale{#9}\fi}
  \expandafter\expandafter\expandafter\ln@getsz\csname ln@sz@\ln@print\endcsname
  \ifx\ln@fontsize\@empty \edef\ln@fontsize{\fpeval{round(10*\ln@scale,2)}pt}\fi
  \ifx\ln@twoside\@empty \def\ln@twoside{true}\fi
\else
  \ifx\ln@scale\@empty\else
    \ClassWarningNoLine{lnotes}{scale=\ln@scale\space ignored without print=<size>}\fi
  \def\ln@scale{1}
  \ifx\ln@fontsize\@empty \def\ln@fontsize{10pt}\fi
  %% screen edition: the margin column is always on the right
  \ifx\ln@twoside\@empty \def\ln@twoside{false}\fi
\fi
%% \ln@sdim{<number>}{<unit>}: the A4 design length scaled for the edition,
%% as a plain string ("6pt" at A4).
\newcommand*{\ln@sdim}[2]{\fpeval{#1*\ln@scale}#2}

%% The option list is expanded first: scrbook must see the values.
\edef\ln@tmp{\noexpand\LoadClass[%
  paper=a4,
  fontsize=\ln@fontsize,
  twoside=\ln@twoside,
  open=any,
  numbers=noenddot,
  chapterprefix=true,
  headings=normal,
  bibliography=totoc,
  index=totoc,
  listof=totoc,
]{scrbook}}
\ln@tmp

\RequirePackage{etoolbox}

%% -------------------------------------------------------- language helpers
\newcommand*{\iflangja}{\ifln@ja\expandafter\@firstoftwo\else\expandafter\@secondoftwo\fi}
\newcommand*{\ja}[1]{\iflangja{#1}{}}
\newcommand*{\en}[1]{\iflangja{}{#1}}
\newcommand*{\ln@langcode}{\iflangja{ja}{en}}

%% ------------------------------------------------------------------- fonts
\RequirePackage{fontspec}
%% amsmath and mathtools must come BEFORE unicode-math: loaded after it they
%% reinstate the Computer-Modern \underbrace/\overbrace, whose extensible
%% pieces then print as literal "z{}" characters and black boxes.
\RequirePackage{amsmath}
\RequirePackage{mathtools}
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
%% Print editions take the page from the size table; the margin column is on
%% the outer side (geometry follows the class's twoside setting).
%% \ln@geomfull: the layout of the front and back matter (title page,
%% contents, bibliography, index), which has no margin column: the text
%% block spans body + gap + margin column (see "Full-width matter" below).
\ifln@print
\edef\ln@hsep{\ln@sdim{6}{mm}}
\edef\ln@fskip{\ln@sdim{10}{mm}}
\RequirePackage[%
  paperwidth=\ln@pw, paperheight=\ln@ph,
  inner=\ln@in, textwidth=\ln@tw, top=\ln@top, bottom=\ln@bot,
  marginparsep=\ln@sep, marginparwidth=\ln@mpw,
  headsep=\ln@hsep, footskip=\ln@fskip,
]{geometry}
\edef\ln@geomfull{%
  inner=\ln@in, textwidth=\the\dimexpr\ln@tw+\ln@sep+\ln@mpw\relax,
  top=\ln@top, bottom=\ln@bot, marginparsep=0pt, marginparwidth=0pt,
  headsep=\ln@hsep, footskip=\ln@fskip}
\edef\ln@tmp{\ln@sdim{4}{pt}}
\setlength{\marginparpush}{\ln@tmp}
\else
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
\def\ln@geomfull{%
  left=20mm, top=25mm, bottom=25mm, textwidth=178mm,
  marginparsep=0pt, marginparwidth=0pt, headsep=6mm, footskip=12mm}
\setlength{\marginparpush}{4pt}
\fi
%% Full width (body + gap + margin column) for wide floats
\newlength{\fullwidth}
\setlength{\fullwidth}{\dimexpr\textwidth+\marginparsep+\marginparwidth\relax}

%% ---------------------------------------------------------- vertical rule
\RequirePackage{eso-pic}
%% Pages shipped out inside the titlepage environment or in full-width
%% matter (\ifln@fullwidth, below) get no rule.
%% Two-sided (print): the rule is on the outer side, left of the body on
%% even pages.
\newcommand*{\ln@rulepos}{\dimexpr\textwidth+0.5\marginparsep\relax}
\if@twoside
  \renewcommand*{\ln@rulepos}{%
    \ifodd\value{page}\dimexpr\textwidth+0.5\marginparsep\relax
    \else-0.5\marginparsep\fi}
\fi
\newif\ifln@rulehere \ln@ruleheretrue
\newif\ifln@fullwidth
\ifln@rule
  \AddToShipoutPictureBG{%
    \ifln@rulehere\ifln@fullwidth\else
    \AtTextLowerLeft{%
      \makebox[0pt][l]{%
        \hspace*{\ln@rulepos}%
        \color{ln-rule}\rule[-6pt]{0.4pt}{\dimexpr\textheight+12pt\relax}}}%
    \fi\fi}
  \AddToHook{env/titlepage/begin}{\global\ln@ruleherefalse}
  \AddToHook{env/titlepage/after}{\global\ln@ruleheretrue}
\fi

%% --------------------------------------------------------------- headings
%% The foot spans the BODY only: \ofoot puts the page number at the right
%% edge of the text block, clear of the margin column.  With the foot
%% spanning body+margin the page number sits underneath the margin column,
%% where a margin note that overruns the text block prints on top of it.
\RequirePackage[automark, autooneside=false, headwidth=textwithmarginpar, footwidth=text]{scrlayer-scrpage}
\pagestyle{scrheadings}
\clearpairofpagestyles
\automark[section]{chapter}
\ihead{\small\sffamily\color{ln-muted}\leftmark}
\ohead{\small\sffamily\color{ln-muted}\ln@rightmark}
%% Contents, Bibliography and Index set both marks to their title; print it
%% once (left) instead of on both sides.
\newcommand*{\ln@rightmark}{%
  \begingroup
    \protected@edef\ln@marka{\leftmark}%
    \protected@edef\ln@markb{\rightmark}%
    \ifx\ln@marka\ln@markb\else\rightmark\fi
  \endgroup}
\ofoot*{\small\sffamily\pagemark}

%% ------------------------------------------------------ full-width matter
%% The title page, contents, bibliography and index have no margin column:
%% \ln@fullwidthmatter switches to \ln@geomfull at a page boundary (the text
%% block then spans body + gap + margin column, on the outer side in the
%% two-sided print editions), \ln@bodymatter switches back.  Both are
%% no-ops when already in that state.  The header and foot widths are
%% stored lengths, so they are set again for each layout; the vertical rule
%% is not drawn while \ifln@fullwidth.  The commands are wrapped at
%% \begin{document} (end of the class).
\newcommand*{\ln@hfwidths}{\KOMAoptions{headwidth=textwithmarginpar, footwidth=text}}
\newcommand*{\ln@fullwidthmatter}{%
  \ifln@fullwidth\else
    \expandafter\newgeometry\expandafter{\ln@geomfull}% \clearpage first
    \ln@hfwidths\global\ln@fullwidthtrue
  \fi}
\newcommand*{\ln@bodymatter}{%
  \ifln@fullwidth
    \restoregeometry% \clearpage first: the last page still has no rule
    \ln@hfwidths\global\ln@fullwidthfalse
  \fi}
\setkomafont{disposition}{\sffamily\bfseries\color{ln-accent}}
\setkomafont{chapterprefix}{\normalfont\sffamily\normalsize\color{ln-muted}}
\setkomafont{chapter}{\sffamily\bfseries\LARGE\color{ln-accent}}
\RedeclareSectionCommand[beforeskip=0pt, afterskip=1.5\baselineskip]{chapter}
\setcounter{secnumdepth}{2}
\setcounter{tocdepth}{1}
%% Table of contents.  The LaTeX defaults (\@pnumwidth 1.55em) are too narrow
%% for a three-digit page number set in the bold part-entry font, and the
%% section number box has to hold a two-digit number such as "13.14".
\renewcommand*{\@pnumwidth}{2.4em}
\renewcommand*{\@tocrmarg}{3.4em}
\RedeclareSectionCommand[tocnumwidth=2.9em]{section}

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
  \newcommand*{\sourcesname}{資料}
  \newcommand*{\textbookname}{教科書}
  \newcommand*{\keywordsname}{キーワード}
  \newcommand*{\secondindexname}{English index}% index=dual: of the glosses
\else
  \AtBeginDocument{\renewcommand*{\chaptername}{\ln@unitname}}
  \newcommand*{\definitionname}{Definition}
  \newcommand*{\examplename}{Example}
  \newcommand*{\notename}{Note}
  \newcommand*{\keypointname}{Key point}
  \newcommand*{\sourcename}{Source}
  \newcommand*{\tipname}{Tip}
  \newcommand*{\cautionname}{Caution}
  \newcommand*{\videoname}{Lecture}
  \newcommand*{\sourcesname}{Sources}
  \newcommand*{\textbookname}{Textbook}
  \newcommand*{\keywordsname}{Keywords}
  \newcommand*{\secondindexname}{日本語索引}% index=dual: of the glosses
\fi

%% ------------------------------------------------------------- margin core
\RequirePackage{marginnote}
\RequirePackage{ragged2e}
%% \marginpar notes are laid out per page by lnmarginfix (format/, a fork of
%% marginfix, LuaTeX only): a note that would run below the text block is
%% moved up into free space above it, and what still does not fit is carried
%% to the top of the next page, as is a note whose anchor line the page
%% builder moved to the next page.  A note's first baseline sits on its
%% anchor's baseline.  The side (outer column when two-sided) is picked when
%% the page is built, so mparhack is not needed.  Load it after any package
%% that patches \marginpar or \@addmarginpar.  \marginnote (in boxes,
%% below) is placed where it is called, as before, and is not moved.
\RequirePackage{lnmarginfix}
%% Print: 0.75 of the body font (A4 \footnotesize is 0.8), against crowding.
\ifln@print
  \edef\ln@mfs{\ln@sdim{7.5}{pt}}
  \edef\ln@mbs{\ln@sdim{9}{pt}}
  \newcommand*{\ln@marginfont}{%
    \fontsize{\ln@mfs}{\ln@mbs}\selectfont\sffamily\color{ln-muted}\RaggedRight}
\else
  \newcommand*{\ln@marginfont}{\footnotesize\sffamily\color{ln-muted}\RaggedRight}
\fi
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
%% ja: \inhibitglue drops the half-em space after a preceding "．" or "，",
%% so the marker sits right after the punctuation.
\newcommand{\sidenote}[1]{%
  \ifln@ja\inhibitglue\fi
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
%% index=dual: a second index of the glosses (\term's last argument), named
%% <jobname>-second so the print jobs sharing build/ keep their own files
%% (main-second.idx, main-a5-second.idx).  The glosses are in the other
%% edition's language; .latexmkrc sorts this index with that edition's style.
\ifln@dualindex
  \edef\ln@secondidx{\jobname-second}
  \makeindex[name=\ln@secondidx,title=\secondindexname,intoc,columns=2]
\fi
\indexsetup{headers={{\indexname}{\indexname}}}% imakeidx uppercases by default
%% Cross-references inside the index: \index{BTB|see{branch target buffer}}
\ifln@ja
  \renewcommand*{\seename}{→}
  \renewcommand*{\alsoname}{→ 関連:}
\fi

%% How a term looks in the body text: italics in English, bold gothic in
%% Japanese (Japanese fonts have no italics).
\newcommand{\termformat}[1]{\iflangja{\textsf{\textbf{#1}}}{\emph{#1}}}

%% English edition: a Japanese gloss in the fallback font has no line-break
%% points (luatexja is not loaded), so a long one overflows the margin.  A
%% pre_linebreak_filter inserts a \exhyphenpenalty between two CJK glyphs
%% carrying \ln@glossattr, skipping the usual kinsoku pairs.  Print only:
%% A4 margin glosses are unchanged.
\newcommand*{\ln@gloss}[1]{#1}
\ifln@ja\else\ifln@print
  \newattribute\ln@glossattr
  \renewcommand*{\ln@gloss}[1]{{\setattribute\ln@glossattr{1}#1}}
  \directlua{
    local attr = luatexbase.registernumber("ln@glossattr")
    local GLYPH = node.id("glyph")
    local nobefore, noafter = {}, {}
    for _, c in ipairs({0x3001, 0x3002, 0xFF0C, 0xFF0E, 0x30FB, 0x30FC,
        0xFF09, 0x300D, 0x300F, 0x3011, 0x3009, 0x300B, 0xFF1F, 0xFF01,
        0x3041, 0x3043, 0x3045, 0x3047, 0x3049, 0x3063, 0x3083, 0x3085,
        0x3087, 0x308E, 0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30C3,
        0x30E3, 0x30E5, 0x30E7, 0x30EE, 0x30F5, 0x30F6, 0x3005}) do
      nobefore[c] = true end
    for _, c in ipairs({0xFF08, 0x300C, 0x300E, 0x3010, 0x3008, 0x300A}) do
      noafter[c] = true end
    local function cjk(c)
      return (c >= 0x3000 and c <= 0x30FF) or (c >= 0x3400 and c <= 0x9FFF)
        or (c >= 0xF900 and c <= 0xFAFF) or (c >= 0xFF00 and c <= 0xFFEF)
    end
    luatexbase.add_to_callback("pre_linebreak_filter", function(head)
      for n in node.traverse_id(GLYPH, head) do
        local nx = n.next
        if nx and nx.id == GLYPH and node.has_attribute(n, attr)
            and node.has_attribute(nx, attr) and cjk(n.char) and cjk(nx.char)
            and not noafter[n.char] and not nobefore[nx.char] then
          local p = node.new("penalty")
          p.penalty = tex.exhyphenpenalty
          node.insert_after(head, n, p)
        end
      end
      return true
    end, "lnotes.glossbreak")
  }
\fi\fi

%% \term[<sort key>]{<word>}[<margin gloss>]
%%   - typesets <word> with \termformat
%%   - adds an index entry (sorted by <sort key> when given)
%%   - shows <margin gloss> (e.g. the English term) in the margin, unless
%%     the class option gloss=false is set
%%   - index=dual: also indexes <margin gloss> in the second index
%% \term* does the same without the index entries (for repeated mentions).
\NewDocumentCommand{\term}{s o m o}{%
  \termformat{#3}%
  \IfBooleanF{#1}{%
    \IfValueTF{#2}{\index{#2@#3}}{\index{#3}}%
    \ifln@dualindex\IfValueT{#4}{\index[\ln@secondidx]{#4}}\fi
  }%
  \ifln@gloss\IfValueT{#4}{\ln@margin{\textcolor{ln-accent}{$\triangleright$}\,\ln@gloss{#4}}}\fi
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
%% NOT breakable: a summary split across a page boundary leaves a one-line
%% shaded fragment (and lets a float slip between the two halves).  The boxes
%% are short, so moving one whole to the next page is always safe.
\newtcolorbox{keypoint}[1][]{%
  enhanced, sharp corners,
  colback=ln-box, colframe=ln-accent, boxrule=0pt, leftrule=2pt,
  left=\ln@sdim{6}{pt}, right=\ln@sdim{6}{pt},
  top=\ln@sdim{4}{pt}, bottom=\ln@sdim{4}{pt},
  fontupper=\normalfont,
  title={\keypointname\notblank{#1}{ --- #1}{}},
  fonttitle=\sffamily\bfseries, coltitle=ln-accent,
  detach title,
  before upper={\ln@inboxtrue\tcbtitle\par},
}

%% ------------------------------------------------------------ lesson info
%% \lessoninfo{video={...}, sources={...}, textbook={...}, keywords={...}}
%% video = lecture recording(s); sources = other primary material
%% (documentation, tutorial, paper, talk).  Empty keys are not printed.
%% Keys are parsed with the LaTeX kernel key system (\DeclareKeys/\SetKeys).
%% The frame is a 0.4pt stroke along the middle of the boxrule, with no
%% interior fill (the page is white).  The skin's default draws it as a gray
%% rectangle with the white interior filled over it, leaving 0.4pt strips:
%% a renderer without anti-aliasing (Ghostscript at 110 dpi, the page
%% renders) rounds a sub-pixel strip away and the edge disappears, and at
%% higher resolution the edges come out 1 or 2 px wide.  A stroke is always
%% drawn at least one device pixel wide.
\RequirePackage{enumitem}
\DeclareKeys[lessoninfo]{
  video    .store = \ln@li@video,
  sources  .store = \ln@li@sources,
  textbook .store = \ln@li@textbook,
  keywords .store = \ln@li@keywords,
}
\newcommand{\lessoninfo}[1]{%
  \begingroup
  \def\ln@li@video{}\def\ln@li@sources{}\def\ln@li@textbook{}\def\ln@li@keywords{}%
  \SetKeys[lessoninfo]{#1}%
  \ifboolexpr{ test {\ifdefempty{\ln@li@video}}
           and test {\ifdefempty{\ln@li@sources}}
           and test {\ifdefempty{\ln@li@textbook}}
           and test {\ifdefempty{\ln@li@keywords}} }{}{%
    \begin{tcolorbox}[enhanced, sharp corners, boxrule=0.4pt,
        frame code={\draw[ln-rule, line width=0.4pt]
          ([shift={(0.2pt,0.2pt)}]frame.south west) rectangle
          ([shift={(-0.2pt,-0.2pt)}]frame.north east);},
        interior code={}, left=\ln@sdim{6}{pt},
        right=\ln@sdim{6}{pt}, top=\ln@sdim{4}{pt}, bottom=\ln@sdim{4}{pt},
        fontupper=\small\sffamily]
      \begin{description}[nosep, leftmargin=7em, labelwidth=6em, font=\bfseries\color{ln-muted}]
        \ifdefempty{\ln@li@video}{}{\item[\videoname] \ln@li@video}%
        \ifdefempty{\ln@li@sources}{}{\item[\sourcesname] \ln@li@sources}%
        \ifdefempty{\ln@li@textbook}{}{\item[\textbookname] \ln@li@textbook}%
        \ifdefempty{\ln@li@keywords}{}{\item[\keywordsname] \ln@li@keywords}%
      \end{description}
    \end{tcolorbox}}%
  \endgroup}

%% ------------------------------------------------------------------ floats
\RequirePackage{graphicx}
\RequirePackage{booktabs}
\RequirePackage{caption}
\captionsetup{font={small,sf}, labelfont={bf,color=ln-accent}, skip=\ln@sdim{4}{pt}}
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

%% Float pages: floats stack from the top of the page instead of being
%% spread over it with large empty bands.  The natural gap is KOMA's, so the
%% choice of floats for a float page is unchanged.
\AtBeginDocument{%
  \setlength{\@fptop}{0pt}%
  \setlength{\@fpsep}{\dimexpr\@fpsep\relax}%
  \setlength{\@fpbot}{0pt plus 1fil}}

%% widefigure / widetable: floats spanning body + margin column.
%% The \fullwidth minipage is wider than the measure on purpose, so the line
%% holding it is overfull by exactly the gap plus the margin column; \hfuzz is
%% raised inside the float so that intentional overflow is not reported.
%% The vertical rule is drawn in the page background, so it would run
%% through a wide float; \ln@putwide lays a white rectangle, reaching 7pt
%% beyond the float (past the 6pt overhang of the rule), under the float body.
%% The rectangle is smashed and has no width, so the layout is unchanged.
%% Two-sided: on even pages the margin column is on the left, so the float
%% is shifted left by the gap plus the margin column (changepage, strict:
%% the page is known only at shipout, hence a second run).
\newlength{\ln@wideslack}
\setlength{\ln@wideslack}{\dimexpr\marginparsep+\marginparwidth+1pt\relax}
\newsavebox{\ln@widebox}
\newif\ifln@wide
\if@twoside
  \RequirePackage[strict]{changepage}
\fi
\newcommand*{\ln@wideshift}{\if@twoside\expandafter\ln@wideshift@\fi}
\newcommand*{\ln@wideshift@}{% two-sided only: changepage is loaded
  \checkoddpage
  \ifoddpage\else\kern-\dimexpr\marginparsep+\marginparwidth\relax\fi}
\edef\ln@widemask{\ln@sdim{7}{pt}}
\edef\ln@widemaskk{\ln@sdim{14}{pt}}
\newcommand*{\ln@putwide}{%
  \leavevmode\ln@wideshift
  \rlap{\smash{\color{white}%
    \rule[\dimexpr-\dp\ln@widebox-\ln@widemask\relax]{\wd\ln@widebox}%
      {\dimexpr\ht\ln@widebox+\dp\ln@widebox+\ln@widemaskk\relax}}}%
  \usebox{\ln@widebox}}
\newenvironment{widefigure}[1][tbp]{%
  \begin{figure}[#1]\ln@inboxtrue\ln@widetrue\hfuzz\ln@wideslack
  \begin{lrbox}{\ln@widebox}\begin{minipage}{\fullwidth}\centering}%
  {\end{minipage}\end{lrbox}\ln@putwide\end{figure}}
\newenvironment{widetable}[1][tbp]{%
  \begin{table}[#1]\ln@inboxtrue\ln@widetrue\hfuzz\ln@wideslack
  \begin{lrbox}{\ln@widebox}\begin{minipage}{\fullwidth}\centering}%
  {\end{minipage}\end{lrbox}\ln@putwide\end{table}}

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
%% Print: the listing font fits 60 columns in the body (Libertinus Mono is
%% 0.5547 em wide: 60 columns = 33.28 em) and is at most 9pt x scale.
\ifln@print
  \edef\ln@lfs{\fpeval{min(9*\ln@scale,
    (\strip@pt\textwidth - 1.2*\strip@pt\dimexpr\ln@fontsize\relax)/33.28)}pt}
  \edef\ln@lbs{\fpeval{1.2*\strip@pt\dimexpr\ln@lfs\relax}pt}
  \ClassInfo{lnotes}{listings font \ln@lfs}
  \edef\ln@tmp{\ln@sdim{6}{pt}}\edef\ln@tmpb{\ln@sdim{0.4}{pt}}
  \lstset{basicstyle=\fontsize{\ln@lfs}{\ln@lbs}\selectfont\ttfamily,
    numbersep=\ln@tmp, framerule=\ln@tmpb}
\fi
%% A listing that opens a theorem-like environment (example, note) would start
%% on the heading line; set the pending heading as its own line first.
\AddToHook{env/lstlisting/before}{\if@inlabel\leavevmode\fi}
\RequirePackage{algorithm}
\RequirePackage{algpseudocode}

%% ------------------------------------------------------------- math & misc
\RequirePackage{siunitx}
\RequirePackage{tikz}
\usetikzlibrary{arrows.meta,positioning,shapes,calc,fit,backgrounds}

%% Print editions: figures and tables are drawn at the A4 design sizes and
%% scaled down, so chapters need no per-size edits.
%% - tikzpicture: fonts at the A4 sizes (\ln@designsizes), the picture
%%   scaled by the edition's scale, then shrunk to \linewidth only if it is
%%   still wider (logged as "lnotes-fit: ...").
%% - tabular: shrunk to \linewidth only if wider (logged).  Not inside a
%%   box environment (\ln@inbox: margin figures, keypoint) except wide
%%   floats, not inside a tikzpicture, not for a tabular nested in another.
\newcount\ln@picdepth
\newcount\ln@tabdepth
\newif\ifln@tabboxed
\newif\ifln@nofit
\ifln@print
  \newsavebox{\ln@picbox}
  \newsavebox{\ln@tabbox}
  \newcommand*{\ln@designsizes}{%
    \def\normalsize{\@setfontsize\normalsize{10}{12}}%
    \def\small{\@setfontsize\small{9}{11}}%
    \def\footnotesize{\@setfontsize\footnotesize{8}{9.5}}%
    \def\scriptsize{\@setfontsize\scriptsize{7}{8}}%
    \def\tiny{\@setfontsize\tiny{5}{6}}%
    \def\large{\@setfontsize\large{12}{14}}%
    \def\Large{\@setfontsize\Large{14.4}{18}}%
    \fontsize{\fpeval{\f@size/\ln@scale}pt}%
      {\fpeval{\strip@pt\dimexpr\f@baselineskip\relax/\ln@scale}pt}\selectfont}
  \newcommand*{\ln@fitlog}[2]{% kind, box
    \typeout{lnotes-fit: \CurrentFile:\the\inputlineno\space #1
      \the\wd#2\space -> \the\linewidth}}
  %% tcolorbox (keypoint, \lessoninfo) draws its frame as a tikzpicture
  %% around the box it has already typeset at the body size and \linewidth:
  %% that picture must not be scaled (it set the boxes at scale x width and
  %% scale x font size).  \ifln@nofit is local to the drawing.
  \AddToHook{env/tikzpicture/before}{%
    \ifln@nofit\else
    \ifnum\ln@picdepth=0 \begin{lrbox}{\ln@picbox}\ln@designsizes\fi
    \global\advance\ln@picdepth 1 \fi}
  \AddToHook{env/tikzpicture/after}{%
    \ifln@nofit\else
    \global\advance\ln@picdepth -1
    \ifnum\ln@picdepth=0 \end{lrbox}\ln@fitpic\fi\fi}
  \AddToHook{env/tcb@drawing/begin}{\ln@nofittrue}
  \pretocmd{\tcb@draw@pseudo@segmentation}{\ln@nofittrue}{}%
    {\ClassWarningNoLine{lnotes}{tcolorbox segmentation not patched}}
  \newcommand*{\ln@fitpic}{%
    \sbox{\ln@picbox}{\scalebox{\ln@scale}{\usebox{\ln@picbox}}}%
    \ifdim\wd\ln@picbox>\linewidth
      \ln@fitlog{tikzpicture}\ln@picbox
      \resizebox{\linewidth}{!}{\usebox{\ln@picbox}}%
    \else\usebox{\ln@picbox}\fi}
  \AddToHook{env/tabular/before}{%
    \ifnum\ln@tabdepth=0
      \global\ln@tabboxedtrue
      \ifln@inbox\ifln@wide\else\global\ln@tabboxedfalse\fi\fi
      \ifnum\ln@picdepth>0 \global\ln@tabboxedfalse\fi
      \ifln@tabboxed\begin{lrbox}{\ln@tabbox}\fi
    \fi
    \global\advance\ln@tabdepth 1 }
  \AddToHook{env/tabular/after}{%
    \global\advance\ln@tabdepth -1
    \ifnum\ln@tabdepth=0 \ifln@tabboxed
      \end{lrbox}%
      \ifdim\wd\ln@tabbox>\linewidth
        \ln@fitlog{tabular}\ln@tabbox
        \resizebox{\linewidth}{!}{\usebox{\ln@tabbox}}%
      \else\usebox{\ln@tabbox}\fi
    \fi\fi}
\fi
\RequirePackage{csquotes}
\RequirePackage{needspace}
\RequirePackage{subfiles}

%% ------------------------------------------------------------ bibliography
\RequirePackage[backend=biber,style=numeric,sorting=none]{biblatex}
%% Long URLs (@online entries) must break, or the entry overflows the body.
\setcounter{biburlnumpenalty}{9000}
\setcounter{biburlucpenalty}{9000}
\setcounter{biburllcpenalty}{9000}
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
\ifln@print\hypersetup{hidelinks}\fi
\RequirePackage[capitalise,noabbrev]{cleveref}
\ifln@ja
  %% Numbered units read 第3章 / 3.2 節.  Besides the single format, the
  %% range and list formats are set too; otherwise cleveref falls back to its
  %% English names there (\cref{sec:a,sec:b,sec:c} gave "Sections 3.1 to 3.3").
  %% \ln@jacref{type}{prefix}{suffix}
  \newcommand*{\ln@jacref}[3]{%
    \crefformat{#1}{#2##2##1##3#3}\Crefformat{#1}{#2##2##1##3#3}%
    \crefrangeformat{#1}{#2##3##1##4\crefrangeconjunction##5##2##6#3}%
    \Crefrangeformat{#1}{#2##3##1##4\crefrangeconjunction##5##2##6#3}%
    \crefmultiformat{#1}{#2##2##1##3}{\crefpairconjunction##2##1##3#3}%
      {\crefmiddleconjunction##2##1##3}{\creflastconjunction##2##1##3#3}%
    \Crefmultiformat{#1}{#2##2##1##3}{\crefpairconjunction##2##1##3#3}%
      {\crefmiddleconjunction##2##1##3}{\creflastconjunction##2##1##3#3}%
    \crefrangemultiformat{#1}%
      {#2##3##1##4\crefrangeconjunction##5##2##6}%
      {\crefpairconjunction##3##1##4\crefrangeconjunction##5##2##6#3}%
      {\crefmiddleconjunction##3##1##4\crefrangeconjunction##5##2##6}%
      {\creflastconjunction##3##1##4\crefrangeconjunction##5##2##6#3}%
    \Crefrangemultiformat{#1}%
      {#2##3##1##4\crefrangeconjunction##5##2##6}%
      {\crefpairconjunction##3##1##4\crefrangeconjunction##5##2##6#3}%
      {\crefmiddleconjunction##3##1##4\crefrangeconjunction##5##2##6}%
      {\creflastconjunction##3##1##4\crefrangeconjunction##5##2##6#3}}
  \ln@jacref{chapter}{第}{章}
  \ln@jacref{section}{}{~節}
  \ln@jacref{subsection}{}{~節}
  \ln@jacref{part}{第}{部}
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
  %% list conjunctions: 図 1.1，表 1.2 / 式 (1.1)〜(1.3)
  %% (cleveref sets its English defaults at \begin{document})
  \AtBeginDocument{%
    \def\crefpairconjunction{，}\def\crefmiddleconjunction{，}%
    \def\creflastconjunction{，}\def\crefpairgroupconjunction{，}%
    \def\crefmiddlegroupconjunction{，}\def\creflastgroupconjunction{，}%
    \def\crefrangeconjunction{〜}}
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

%% Full-width matter (see above): the title page, contents, bibliography and
%% index.  Wrapped at \begin{document}, after every package has defined them.
\newcommand*{\ln@emptyafter@title}{%
  \clearpage
  \if@twoside
    \cleardoubleoddpageusingstyle{empty}%
  \else
    \thispagestyle{empty}\null\clearpage
  \fi}
\AtBeginDocument{%
  \NewCommandCopy\ln@orig@maketitle\maketitle
  %% An empty page follows the title in every edition (no head, foot or
  %% rule: still full-width matter, page style empty), so the contents start
  %% on page 3; two-sided, the empty page is the verso and the contents
  %% start on a recto whatever the length of the title.
  \RenewDocumentCommand\maketitle{o}{%
    \ln@fullwidthmatter
    \IfValueTF{#1}{\ln@orig@maketitle[#1]}{\ln@orig@maketitle}%
    \ln@emptyafter@title
    \ln@bodymatter}%
  \NewCommandCopy\ln@orig@tableofcontents\tableofcontents
  %% Two-sided: the body starts on a recto (\mainmatter would add the blank
  %% verso after the switch, with the rule).
  \renewcommand*\tableofcontents{%
    \ln@fullwidthmatter\ln@orig@tableofcontents
    \if@twoside\cleardoubleoddpage\fi\ln@bodymatter}%
  \NewCommandCopy\ln@orig@printbibliography\printbibliography
  \RenewDocumentCommand\printbibliography{o}{%
    \ln@fullwidthmatter
    \IfValueTF{#1}{\ln@orig@printbibliography[#1]}{\ln@orig@printbibliography}%
    \ln@bodymatter}%
  %% index=dual: \printindex without an argument prints both indexes.
  \NewCommandCopy\ln@orig@printindex\printindex
  \RenewDocumentCommand\printindex{o}{%
    \ln@fullwidthmatter
    \IfValueTF{#1}{\ln@orig@printindex[#1]}{%
      \ln@orig@printindex
      \ifln@dualindex\ln@orig@printindex[\ln@secondidx]\fi}%
    \ln@bodymatter}}

\endinput
