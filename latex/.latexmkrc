# latexmk settings for the notes. Picked up automatically by `make latex` and
# by the CI action, both of which run latexmk from this directory.

# LuaLaTeX. gwbook.cls uses fontspec/unicode-math, so pdfLaTeX will not work.
$pdf_mode = 4;

# minted 3 needs a second pass to pick up its highlighting, and biblatex needs
# one after biber. Give latexmk room to reach a fixed point rather than
# stopping at its default of 5.
$max_repeat = 7;

# -shell-escape is deliberately NOT enabled: TeX Live whitelists minted's
# latexminted helper under restricted shell escape, so highlighting works
# without opening the build up to arbitrary commands.
$lualatex = 'lualatex -interaction=nonstopmode -halt-on-error -file-line-error %O %S';

$bibtex_use = 2;   # run biber, and clean its output on `latexmk -c`

# minted 3 scratch files are named after a hash of the document, so they need
# glob patterns rather than fixed names.
$clean_ext .= ' bbl run.xml bcf %R.synctex.gz';
push @generated_exts, 'config.minted', 'data.minted', 'message.minted';

# Keep the intermediate files out of the source directories: everything above
# (plus minted's _minted/) is written here instead. The PDF still lands next to
# its source, so the Makefile and the CI action collect it exactly as before.
# Relative, so it resolves per-directory under latexmk -cd: latex/build for the
# book, latex/chapters/build for the chapters.
#
# The chapters' \externaldocument path has to agree with this name -- see the
# \IfFileExists line at the top of each one. Renaming this directory without
# renaming that path breaks cross-chapter references *silently*, since the
# \IfFileExists guard turns a missing book.aux into a no-op rather than an error.
$aux_dir = 'build';
