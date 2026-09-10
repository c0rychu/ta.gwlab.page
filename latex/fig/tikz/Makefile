# TikZ figures -> one standalone PDF each.
#
# Each .tex here is a fragment: a single tikzpicture, no preamble. _wrapper.tex
# supplies the preamble and the book's fonts around it, and `standalone` crops
# tight to the drawing.
#
# The PDFs are committed and reusable -- drop them into slides, a poster, or any
# other document. The book itself does NOT use them: \tikzfig \inputs the .tex
# so the labels are typeset in the document's own fonts, which is what keeps a
# figure consistent when the book is built with a different typeface. Source of
# truth is the .tex; the PDF is an export of it.
#
#   make                     export every figure
#   make gwbook-template-gauss-sphere.pdf    just one, while you are drawing it
#   make clean

FIGS := $(patsubst %.tex,%.pdf,$(filter-out _wrapper.tex,$(wildcard *.tex)))

.PHONY: all clean
all: $(FIGS)
	@[ -n "$(FIGS)" ] || echo "no .tex figures here yet"

# One pass is enough: a figure has no references, citations or listings.
%.pdf: %.tex _wrapper.tex
	@lualatex -interaction=nonstopmode -halt-on-error -jobname=$* \
	    "\def\FIG{$<}\input{_wrapper}" >/dev/null 2>&1 \
	  || { echo "FAILED $< -- rerun without >/dev/null to see the error"; exit 1; }
	@rm -f $*.aux $*.log
	@echo "tikz: $< -> $@"

clean:
	@rm -f *.pdf *.aux *.log *.fls *.fdb_latexmk *.xdv *.synctex.gz
