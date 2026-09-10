# SVG -> PDF.
#
# LaTeX cannot include SVG directly. The `svg` package can, but only by shelling
# out to Inkscape mid-compile, which needs -shell-escape and an Inkscape the CI
# container does not have. Converting here instead keeps the document build
# hermetic: the generated PDF is committed alongside its SVG, and CI just
# typesets what it is given.
#
# Needs one of:
#   rsvg-convert   (brew install librsvg)   -- preferred: ~30x faster
#   inkscape       (brew install --cask inkscape)
#
#   make          convert every changed .svg
#   make clean    remove the generated PDFs

# The PDF lands next to its SVG. Everything under fig/ is self-contained: the
# class puts each figure subdirectory on \graphicspath, so \includegraphics
# finds it by bare filename regardless of which one it sits in.
SVGS := $(wildcard *.svg)
PDFS := $(patsubst %.svg,%.pdf,$(SVGS))

.PHONY: all clean
all: $(PDFS)

%.pdf: %.svg
	@if command -v rsvg-convert >/dev/null 2>&1; then \
	  rsvg-convert -f pdf -o $@ $<; \
	elif command -v inkscape >/dev/null 2>&1; then \
	  inkscape $< --export-type=pdf --export-filename=$@ >/dev/null 2>&1; \
	else \
	  echo "need rsvg-convert or inkscape: brew install librsvg"; exit 1; \
	fi
	@echo "svg: $< -> $@"

clean:
	@rm -f $(PDFS)
