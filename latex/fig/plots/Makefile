# Plotted figures.
#
# One script per figure, each writing its output next to itself. Add a figure by
# dropping in another .py -- nothing here names individual files.
#
# Scripts starting with _ are treated as modules rather than figures, so a
# shared helper can live here without the Makefile trying to run it.
#
# Output is gitignored; CI regenerates it before typesetting.
#
# Uses the project's notebook venv, which already has matplotlib
# (`uv sync --group notebooks` if .venv is missing).
#
#   make          regenerate every figure
#   make clean    remove the generated images

PYTHON  := ../../../.venv/bin/python
SCRIPTS := $(filter-out _%,$(wildcard *.py))

.PHONY: all clean
all:
	@[ -n "$(SCRIPTS)" ] || { echo "no figure scripts here yet"; exit 0; }; \
	command -v latex >/dev/null 2>&1 || { \
	  echo "no 'latex' on PATH — physics-plot sets text.usetex, so matplotlib"; \
	  echo "typesets every label with a real LaTeX. Install TeX Live (or MacTeX)."; \
	  exit 1; }; \
	if [ -x $(PYTHON) ]; then py=$(PYTHON); \
	elif command -v uv >/dev/null 2>&1; then py="uv run --group notebooks python"; \
	else echo "need the project venv: uv sync --group notebooks"; exit 1; fi; \
	for s in $(SCRIPTS); do $$py "$$s" || exit 1; done

# Only this directory's own output. Sibling directories clean themselves.
clean:
	@rm -f *.pdf *.png
