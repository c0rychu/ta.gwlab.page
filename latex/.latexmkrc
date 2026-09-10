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
