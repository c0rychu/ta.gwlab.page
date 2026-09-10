# Figure assets for the notes.
#
# Every subdirectory is self-contained: sources and the output built from them
# sit together, and all four are on the class's \graphicspath, so a figure is
# included by bare filename regardless of which one it lives in.
#
# Layout
#   fig/plots/    plotting scripts + the PDF/PNG they write
#   fig/svg/      SVG sources + the PDF converted from them
#   fig/tikz/     TikZ sources + one exported PDF each. The book \inputs the
#                 .tex (via \tikzfig) so labels take the document's own fonts;
#                 the exported PDFs are for reuse elsewhere -- slides, posters.
#   fig/others/   figures from anywhere else; nothing to build, no Makefile
#
# Generated output is gitignored — only sources are committed — so run `make`
# here after a fresh clone as well as after changing a figure. CI does the same
# before typesetting (plots and svg only; the TikZ exports are not needed to
# build the notes).
#
#   make            regenerate every figure asset
#   make tikz       export just the TikZ figures
#   make clean      remove generated assets -- note these are COMMITTED files,
#                   so this is for regenerating deliberately, not for tidying

.PHONY: all tikz svg plots clean

# No ordering between these: each subdirectory owns its own sources and output
# and never reaches into a sibling, so they are independent and -j safe.
all: tikz plots svg

tikz:
	@$(MAKE) --no-print-directory -C tikz

svg:
	@$(MAKE) --no-print-directory -C svg

plots:
	@$(MAKE) --no-print-directory -C plots

clean:
	@$(MAKE) --no-print-directory -C svg clean
	@$(MAKE) --no-print-directory -C plots clean
	@$(MAKE) --no-print-directory -C tikz clean
