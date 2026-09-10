%% gwbook.cls -- lecture-notes / textbook class for ta.gwlab.page
%%
%% Old-school physics-monograph typesetting in the spirit of Kerson Huang's
%% "Statistical Mechanics" and Mukhanov's "Physical Foundations of Cosmology":
%% a book trim rather than a letter sheet, a fixed comfortable measure, and
%% generously spaced displayed equations.
%%
%% Requires LuaLaTeX (fontspec + unicode-math). Build with latexmk, which is
%% not optional: minted 3 needs two passes (see the "code" section below).
%%
%% Usage:
%%     \documentclass{gwbook}              % Schola, 7x10in trim
%%     \documentclass[charter]{gwbook}     % XCharter instead
%%     \documentclass[letterpaper]{gwbook} % same text block, Letter sheet

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gwbook}[2026/09/10 v1.0 GW lab lecture-notes book class]

\RequirePackage{etoolbox}

%% ---------------------------------------------------------------------------
%% Options
%% ---------------------------------------------------------------------------
%% The typeface and its leading are a single choice, not two: Schola sets
%% denser than XCharter and wants tighter leading to look right. Coupling them
%% here is what keeps the two from drifting apart.

\newif\ifgwb@charter  \gwb@charterfalse
\newif\ifgwb@twoside  \gwb@twosidefalse
\newif\ifgwb@nocolor  \gwb@nocolorfalse
\newif\ifgwb@draft    \gwb@draftfalse
\def\gwb@paper{trim}

\DeclareOption{schola}{\gwb@charterfalse}
\DeclareOption{charter}{\gwb@chartertrue}
\DeclareOption{letterpaper}{\def\gwb@paper{letter}}
\DeclareOption{a4paper}{\def\gwb@paper{a4}}
\DeclareOption{oneside}{\gwb@twosidefalse}
\DeclareOption{twoside}{\gwb@twosidetrue}
\DeclareOption{nocolor}{\gwb@nocolortrue}
% draft: skip syntax highlighting. Highlighting is the slowest part of a
% rebuild, and while you are writing prose you do not need it.
\DeclareOption{draft}{\gwb@drafttrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ExecuteOptions{schola}
\ProcessOptions\relax

\ifgwb@twoside
  \PassOptionsToClass{twoside,openright}{book}
\else
  \PassOptionsToClass{oneside,openany}{book}
\fi
\LoadClass[12pt]{book}

%% ---------------------------------------------------------------------------
%% Page geometry
%% ---------------------------------------------------------------------------
%% The measure is fixed at 5.6in in every configuration. Tighter margins come
%% from a smaller sheet, never from longer lines -- a wider text block was
%% tried and is markedly worse to read.

\RequirePackage{geometry}

\ifdefstring{\gwb@paper}{letter}{\def\gwb@paperopt{letterpaper}}{}
\ifdefstring{\gwb@paper}{a4}{\def\gwb@paperopt{a4paper}}{}
\ifdefstring{\gwb@paper}{trim}{\def\gwb@paperopt{paperwidth=7in,paperheight=10in}}{}

\edef\gwb@geom{\gwb@paperopt,textwidth=5.6in,textheight=7.9in,centering%
  \ifgwb@twoside ,bindingoffset=0.3in\fi}
\expandafter\geometry\expandafter{\gwb@geom}

%% ---------------------------------------------------------------------------
%% Fonts
%% ---------------------------------------------------------------------------
%% Both faces are deliberately sturdy. Light faces (Times, Libertinus,
%% Computer Modern) render inconsistently across PDF viewers -- Chrome's
%% pdf.js and Acrobat thin their stems noticeably -- which is distracting in a
%% document read mostly on screen.

\RequirePackage{amsmath}
\RequirePackage{mathtools}
\RequirePackage{fontspec}
\RequirePackage{unicode-math}

\ifgwb@charter
  \setmainfont{XCharter}[
    Extension=.otf, UprightFont=*-Roman, ItalicFont=*-Italic,
    BoldFont=*-Bold, BoldItalicFont=*-BoldItalic]
  \setmathfont{XCharter-Math.otf}
  \linespread{1.16}
\else
  \setmainfont{texgyreschola}[
    Extension=.otf, UprightFont=*-regular, ItalicFont=*-italic,
    BoldFont=*-bold, BoldItalicFont=*-bolditalic]
  \setmathfont{texgyreschola-math.otf}
  \linespread{1.10}
\fi

\setsansfont{texgyreheros}[
  Extension=.otf, UprightFont=*-regular, ItalicFont=*-italic,
  BoldFont=*-bold, BoldItalicFont=*-bolditalic, Scale=MatchLowercase]

% Ligatures are switched off in the mono font on purpose: a "fi" ligature in a
% code listing is a single glyph, and copying it out of the PDF yields one
% character where the source had two.
% The oblique is needed, not decorative: syntax styles set comments in italic,
% and without a real italic shape LaTeX warns and substitutes the upright.
\setmonofont{FiraMono}[
  Extension=.otf, UprightFont=*-Regular, BoldFont=*-Bold,
  ItalicFont=*-Oblique, BoldItalicFont=*-Bold,
  Scale=MatchLowercase, Ligatures=NoCommon]

\RequirePackage{microtype}

%% ---------------------------------------------------------------------------
%% Vertical rhythm
%% ---------------------------------------------------------------------------
%% Glyphs stay at their natural size; the "generous equations" feel comes from
%% the space around displays, not from scaling the math font up.

\setlength{\abovedisplayskip}{24pt plus 5pt minus 3pt}
\setlength{\belowdisplayskip}{24pt plus 5pt minus 3pt}
\setlength{\abovedisplayshortskip}{12pt plus 4pt}
\setlength{\belowdisplayshortskip}{17pt plus 4pt minus 2pt}

\setlength{\parindent}{1.5em}
\setlength{\emergencystretch}{3em}
\raggedbottom

%% ---------------------------------------------------------------------------
%% Headings and running heads
%% ---------------------------------------------------------------------------

\RequirePackage{titlesec}
\RequirePackage{fancyhdr}

\titleformat{\chapter}[display]
  {\normalfont\huge\bfseries}
  {\normalsize\normalfont\scshape\chaptertitlename\ \thechapter}
  {10pt}{\Huge}[\vspace{8pt}\titlerule]
\titlespacing*{\chapter}{0pt}{0pt}{30pt}

\titleformat{\section}{\normalfont\Large\bfseries}{\thesection}{1em}{}
\titlespacing*{\section}{0pt}{22pt plus 4pt minus 2pt}{8pt}

\titleformat{\subsection}{\normalfont\large\bfseries}{\thesubsection}{1em}{}
\titlespacing*{\subsection}{0pt}{16pt plus 3pt minus 2pt}{6pt}

\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.4pt}
\ifgwb@twoside
  \fancyhead[LE]{\footnotesize\itshape\leftmark}
  \fancyhead[RO]{\footnotesize\itshape\rightmark}
  \fancyhead[RE,LO]{\footnotesize\thepage}
\else
  \fancyhead[L]{\footnotesize\itshape\rightmark}
  \fancyhead[R]{\footnotesize\thepage}
\fi
\fancypagestyle{plain}{%
  \fancyhf{}\renewcommand{\headrulewidth}{0pt}%
  \fancyfoot[C]{\footnotesize\thepage}}

%% ---------------------------------------------------------------------------
%% Figures
%% ---------------------------------------------------------------------------
%% All artwork lives in latex/fig/, sorted by how it is produced -- plots/,
%% svg/, tikz/ and others/ -- with each subdirectory self-contained: sources and
%% their generated output sit together.
%%
%% Every one of them is on the search path, so \includegraphics takes a bare
%% filename and does not care which subdirectory a figure lives in (move a file
%% between them and nothing needs editing). Each appears twice because a chapter
%% compiled on its own runs from latex/chapters/, one level down, while book.tex
%% and the templates run from latex/.
%%
%% Filenames must therefore be unique across the four directories; on a clash
%% the first match in this list wins.

\RequirePackage{graphicx}
\RequirePackage{tikz}

\graphicspath{
  {fig/plots/}{fig/svg/}{fig/tikz/}{fig/others/}
  {../fig/plots/}{../fig/svg/}{../fig/tikz/}{../fig/others/}
}

% \tikzfig{name.tex} -- pull in a TikZ figure from fig/tikz/. The fragment is
% \input rather than imported as a picture, so its labels are typeset in this
% document's fonts. \includegraphics gets the two search paths above for free;
% \input does not, so this tries each in turn rather than depending on subfiles'
% \subfix (which is undefined in the templates, as those are not subfiles).
\newcommand{\tikzfig}[1]{%
  \IfFileExists{fig/tikz/#1}{\input{fig/tikz/#1}}{\input{../fig/tikz/#1}}}

%% ---------------------------------------------------------------------------
%% Boxes: key equations, theorems, examples
%% ---------------------------------------------------------------------------

\RequirePackage[most]{tcolorbox}

% Every box is drawn with rules on white -- no tinted panels anywhere. Shaded
% blocks make a page look like a web page and muddy it in print; the rules on
% their own are quieter and the titles already say what each box is.
\definecolor{gwbRule}{gray}{0}

% One rule weight for every box in the class -- boxed equations, theorem-like
% boxes and \gwbox alike. Defined once so they cannot drift apart.
\newcommand{\gwb@boxrule}{0.7pt}

% Boxed display equation. The "ams equation" key is what keeps the equation
% number where it belongs; wrapping a bare \begin{equation} in a tcolorbox
% loses it.
\newtcolorbox{keyeq}{%
  ams equation, enhanced, sharp corners, boxrule=\gwb@boxrule,
  colback=white, colframe=gwbRule,
  left=10pt, right=10pt, top=10pt, bottom=10pt}

\newtcolorbox{keyeq*}{%
  ams equation*, enhanced, sharp corners, boxrule=\gwb@boxrule,
  colback=white, colframe=gwbRule,
  left=10pt, right=10pt, top=10pt, bottom=10pt}

\newtcolorbox{keyalign}{%
  ams align, enhanced, sharp corners, boxrule=\gwb@boxrule,
  colback=white, colframe=gwbRule,
  left=10pt, right=10pt, top=10pt, bottom=10pt}

% All four theorem-like boxes share one hairline frame -- the same rule the
% Example box and \gwbox use. Differentiating them by rule weight or a coloured
% edge made them read as UI callouts rather than book furniture; the title
% already says which is which.
%   #1 environment name   #2 printed label
\newcommand{\gwb@thmbox}[2]{%
  \newtcolorbox[auto counter, number within=chapter]{#1}[1][]{%
    enhanced, breakable, sharp corners,
    colback=white, colframe=gwbRule, boxrule=\gwb@boxrule,
    left=10pt, right=10pt, top=8pt, bottom=8pt,
    fonttitle=\bfseries, coltitle=black,
    title={#2~\thetcbcounter\ifstrempty{##1}{}{\ (##1)}},
    attach title to upper={\ \ }}}

% Each keeps its own counter. Sharing one would avoid a Theorem 2.1 and an
% Example 2.1 coexisting, but tcolorbox would then report every box under the
% theorem counter and \autoref would call a definition "Theorem".
\gwb@thmbox{theorem}{Theorem}
\gwb@thmbox{definition}{Definition}
\gwb@thmbox{example}{Example}
\gwb@thmbox{remark}{Remark}

% A plain framed box for anything that is not theorem-like. The title is
% genuinely optional, so this needs tcolorbox's own IfValueT key -- an
% \ifstrempty at key-list level (rather than inside a key's value, as in
% \gwb@thmbox above) is read by pgfkeys before TeX evaluates it and fails.
\NewTColorBox{gwbox}{o}{%
  enhanced, breakable, sharp corners, boxrule=\gwb@boxrule,
  colback=white, colframe=gwbRule,
  left=10pt, right=10pt, top=8pt, bottom=8pt,
  fonttitle=\bfseries, coltitle=black,
  IfValueT={#1}{title={#1}, attach title to upper={\ \ }}}

%% ---------------------------------------------------------------------------
%% Code listings
%% ---------------------------------------------------------------------------
%% minted 3 is a two-pass package: on the first run it writes a .config.minted
%% data file and typesets a red "<MINTED>" placeholder, and only the second run
%% reads the highlighted result back. It does this WITHOUT raising an error, so
%% a single lualatex run silently produces a PDF full of placeholders. Always
%% build through latexmk. It needs no -shell-escape: TeX Live whitelists the
%% latexminted helper under restricted shell escape.

\RequirePackage{minted}
\RequirePackage{accsupp}

% Conditionals are kept out of the key list on purpose: the keyval parser reads
% its argument before TeX evaluates \if..\fi, so an inline conditional here
% breaks with a bare "Incomplete \iffalse".
\setminted{
  frame=lines, framesep=8pt, fontsize=\small,
  autogobble,          % strip the indentation the .tex source adds
  breaklines, breakanywhere,
  tabsize=4,
}
\ifgwb@nocolor\setminted{style=bw}\else\setminted{style=tango}\fi
\ifgwb@draft\setminted{draft}\fi

% Line numbers are decoration, not content. ActualText={} makes them invisible
% to PDF text extraction, so selecting a listing and pasting it into an editor
% yields runnable code instead of code with a column of integers down the left.
\renewcommand{\theFancyVerbLine}{%
  \BeginAccSupp{ActualText={}}%
  \footnotesize\textcolor{gray}{\arabic{FancyVerbLine}}%
  \EndAccSupp{}}

% \begin{code}{python} ... or \begin{code}[linenos]{python} ...
\NewDocumentEnvironment{code}{O{} m}
  {\VerbatimEnvironment\begin{minted}[#1]{#2}}
  {\end{minted}}

% Inline code: \cd{np.pi}
\newcommand{\cd}[1]{\mintinline{text}{#1}}

%% ---------------------------------------------------------------------------
%% Links
%% ---------------------------------------------------------------------------
%% hyperref must come BEFORE biblatex: biblatex decides whether to make its
%% citation labels into links by looking for hyperref as it loads, so with the
%% order reversed \cite silently produces plain text.

% xr-hyper lets a standalone chapter read the book's .aux and resolve -- and
% link -- references into other chapters. It must precede hyperref.
\RequirePackage{xr-hyper}

\RequirePackage{hyperref}
\hypersetup{
  bookmarksnumbered=true,
  pdfpagemode=UseOutlines,
  linktoc=all,           % in the TOC, link the title as well as the page number
}

% Links are coloured rather than boxed -- a frame around every reference would
% wreck the page. The colour is dark enough to read as ordinary text in print
% and still be obviously clickable on screen.
\ifgwb@nocolor
  \hypersetup{hidelinks}
\else
  \definecolor{gwbLink}{HTML}{26308F}
  \hypersetup{colorlinks=true, linkcolor=gwbLink, citecolor=gwbLink,
              urlcolor=gwbLink, filecolor=gwbLink}
\fi

% Carry the document's own metadata into the PDF properties.
\AtBeginDocument{\hypersetup{pdftitle={\@title}, pdfauthor={\@author}}}

% \autoref names. With \ref, only the numeral is clickable ("Chapter 1"); with
% \autoref the whole phrase is one link, which is a far easier target and reads
% better. The tcb@cnt@* counters are the ones tcolorbox creates for the
% auto-counter boxes above, so theorems and examples get the same treatment.
\def\chapterautorefname{Chapter}
\def\sectionautorefname{Section}
\def\subsectionautorefname{Section}
\def\equationautorefname{Eq.}
\def\figureautorefname{Figure}
\def\tableautorefname{Table}
\def\tcb@cnt@theoremautorefname{Theorem}
\def\tcb@cnt@definitionautorefname{Definition}
\def\tcb@cnt@exampleautorefname{Example}
\def\tcb@cnt@remarkautorefname{Remark}

%% ---------------------------------------------------------------------------
%% Bibliography (Physical Review style)
%% ---------------------------------------------------------------------------
%% refsegment=chapter, not refsection: segments subdivide a single reference
%% section, so each chapter can print just its own citations AND the back matter
%% can print the union of everything actually cited. Separate refsections cannot
%% be merged like that -- the only way to fill a back-matter list would be
%% \nocite{*}, which drags in every entry in the .bib whether cited or not.
%%
%% The cost is that labels run continuously through the book rather than
%% restarting at [1] each chapter. That is the right trade for a numeric style:
%% one key always carries one number, so [7] means the same thing everywhere.

\RequirePackage[
  backend=biber,
  style=phys,
  biblabel=brackets,
  articletitle=false,
  chaptertitle=false,
  pageranges=false,
  sorting=none,        % citation order, so numeric labels ascend down the list
  refsegment=chapter,
]{biblatex}

\defbibheading{subbibliography}[References]{\section*{#1}\markright{#1}}

% \chapterbib -- this chapter's own citations. biblatex prints nothing (bar a
% log warning) when the segment is empty, so it can sit unconditionally at the
% end of every chapter file, including ones that cite nothing yet.
\newcommand{\chapterbib}{%
  \printbibliography[segment=\therefsegment,heading=subbibliography]}

% \bookbib -- the back-matter list: everything cited anywhere in the book, and
% nothing else. Deliberately no \nocite{*} -- that lists every entry in the .bib
% whether or not the text ever refers to it.
\newcommand{\bookbib}{%
  \printbibliography[heading=bibintoc]}

%% ---------------------------------------------------------------------------
%% Title page
%% ---------------------------------------------------------------------------

\newcommand{\gwb@subtitle}{}
\newcommand{\subtitle}[1]{\renewcommand{\gwb@subtitle}{#1}}

\renewcommand{\maketitle}{%
  \begin{titlepage}
    \centering
    \vspace*{0.18\textheight}
    {\Huge\bfseries\@title\par}
    \ifdefempty{\gwb@subtitle}{}{\vspace{12pt}{\Large\gwb@subtitle\par}}
    \vspace{28pt}
    {\large\@author\par}
    \vfill
    {\large\@date\par}
    \vspace{0.10\textheight}
  \end{titlepage}}

\endinput
