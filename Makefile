# Build everything into dist/, which is gitignored and is exactly what GitHub
# Pages serves. Each top-level source directory (site/, latex/, ...) gets one
# target here; `make` builds them all.

TAILWIND_VERSION := v4.3.3
TOOLS           := .tools
TAILWIND        := $(TOOLS)/tailwindcss
DIST            := dist
PORT            ?= 8000

# Map uname to the asset names published on the tailwindcss releases page.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S),Darwin)
  TAILWIND_OS := macos
else
  TAILWIND_OS := linux
endif
ifeq ($(UNAME_M),arm64)
  TAILWIND_ARCH := arm64
else ifeq ($(UNAME_M),aarch64)
  TAILWIND_ARCH := arm64
else
  TAILWIND_ARCH := x64
endif
TAILWIND_URL := https://github.com/tailwindlabs/tailwindcss/releases/download/$(TAILWIND_VERSION)/tailwindcss-$(TAILWIND_OS)-$(TAILWIND_ARCH)

.PHONY: all site latex latex-check fig serve clean distclean help

all: site latex

## site: render markdown + templates into dist/, then compile the CSS
# The CSS step must run after the HTML exists: Tailwind only emits the classes it
# finds in the sources it scans.
site: $(TAILWIND)
	uv run site/build.py
	$(TAILWIND) -i site/src/input.css -o $(DIST)/assets/app.css --minify

## latex: build book.tex and every chapter into dist/notes/ (no-op without latex/)
## latex CH=ch01-electrostatics: build just that one chapter
# The recipe cds into latex/ so that latexmk picks up latex/.latexmkrc, which is
# what selects LuaLaTeX and allows enough passes for minted and biblatex. Engine
# flags deliberately live there and not here, so the CI action gets them too.
# -cd then moves latexmk into each file's own directory, which is what lets a
# chapter subfile resolve ../book.tex.
# Build order matters: book.tex first, so that latex/build/book.aux exists by
# the time the chapters are typeset. Each chapter reads it via xr-hyper, which
# is what makes a reference into another chapter resolve — and stay clickable —
# in a standalone chapter PDF. The intermediate files go to build/ ($aux_dir in
# .latexmkrc) rather than next to the sources; the PDFs still land in latex/ and
# latex/chapters, which is what the collect step below and the CI action expect.
latex:
	@if [ ! -d latex ]; then echo "no latex/ directory — skipping"; exit 0; fi; \
	if [ -d latex/fig ] \
	   && [ -n "`find latex/fig -name '*.py' -o -name '*.svg' 2>/dev/null | head -1`" ] \
	   && [ -z "`find latex/fig -name '*.pdf' -o -name '*.png' 2>/dev/null | head -1`" ]; then \
	  echo "figures have not been generated — run 'make fig' first"; exit 1; \
	fi; \
	out=$(CURDIR)/$(DIST)/notes; mkdir -p $$out; \
	cd latex || exit 1; \
	if [ -n "$(CH)" ]; then \
	  set -- chapters/$(CH).tex; \
	else \
	  set -- *.tex chapters/*.tex; \
	fi; \
	for f in "$$@"; do \
	  [ -e "$$f" ] || continue; \
	  echo "latexmk $$f"; \
	  latexmk -cd "$$f" || exit 1; \
	done; \
	for d in . chapters; do \
	  [ -d "$$d" ] || continue; \
	  find "$$d" -maxdepth 1 -name '*.pdf' -exec mv {} $$out/ \; ; \
	done
# Only the two directories that hold document roots are collected. A blanket
# -maxdepth 2 would also sweep up latex/fig/*.pdf, which are source artwork,
# not build output — and moving them breaks the next build.
# The .aux/.fdb_latexmk files are deliberately left in latex/. They are all
# gitignored, they let latexmk skip unchanged chapters on the next run, and a
# surviving book.aux is what lets `make latex CH=...` still resolve references
# into other chapters. `make clean` removes them.

## fig: regenerate figure assets (TikZ exports, SVG conversion, plots)
# Figure generation is deliberately NOT a prerequisite of `latex`: it needs
# matplotlib, rsvg-convert and LuaLaTeX, and wiring it in would put all three
# between you and a one-line typo fix. The `latex` target only checks that the
# assets are present and tells you to run this; CI runs it as its own step.
# Run this after changing a figure source.
# See latex/fig/Makefile; each subdirectory has its own for working on one kind.
fig:
	@[ -d latex/fig ] || { echo "no latex/fig — skipping"; exit 0; }; \
	$(MAKE) --no-print-directory -C latex/fig

## latex-check: verify no code listing was left unhighlighted
# minted 3 needs two passes and fails *silently* — a one-pass build emits a red
# "<MINTED>" placeholder and still exits 0. This is the guard against shipping
# that to the site.
latex-check:
	@command -v pdftotext >/dev/null 2>&1 || { echo "pdftotext not installed — skipping"; exit 0; }; \
	fail=0; \
	for p in $(DIST)/notes/*.pdf; do \
	  [ -e "$$p" ] || continue; \
	  n=`pdftotext "$$p" - 2>/dev/null | grep -cE '^[[:space:]]*<MINTED>[[:space:]]*$$' || true`; \
	  if [ "$$n" != "0" ]; then echo "FAIL $$p: $$n unhighlighted listing(s)"; fail=1; fi; \
	done; \
	if [ $$fail -eq 0 ]; then echo "minted: all listings highlighted"; else exit 1; fi

## serve: build, then serve dist/ on http://localhost:8000 (override with PORT=)
serve: site
	@echo "serving $(DIST)/ at http://localhost:$(PORT)  (re-run 'make site' after edits)"
	@python3 -m http.server $(PORT) -d $(DIST)

## clean: remove the LaTeX build files left in latex/ (keeps dist/)
# dist/ is left alone: it is gitignored, harmless to keep, and throwing it away
# forces a full site rebuild for no benefit. `make distclean` removes it.
#
# The *.pdf line is what makes this work after an interrupted `make latex`.
# latexmk writes each PDF next to its source, and the recipe above only moves
# them into dist/notes once every file has been typeset -- so a Ctrl-C partway
# through strands the finished ones here. Exactly the two directories that hold
# document roots, and at depth 1 -- latex/fig/**/*.pdf is figure artwork, see
# the note under the recipe.
#
# latex/fig/tikz still needs the old per-extension sweep: it drives the engine
# itself rather than latexmk, so .latexmkrc's $aux_dir never reaches it.
clean:
	@rm -rf latex/build latex/chapters/build
	@rm -f latex/*.pdf latex/chapters/*.pdf
	@for d in latex/fig/tikz; do \
	  [ -d "$$d" ] || continue; \
	  rm -f $$d/*.aux $$d/*.log $$d/*.fls $$d/*.fdb_latexmk $$d/*.out \
	        $$d/*.synctex.gz $$d/*.xdv; \
	done
# Figure assets are NOT touched here, and not because they are tracked — they
# are gitignored, one .gitignore per latex/fig/ subdirectory. It is that
# regenerating them needs matplotlib, rsvg-convert and LuaLaTeX, none of which
# the document build otherwise requires, so deleting them to tidy up would turn
# the next `make latex` into a toolchain install. CI regenerates plots and svg
# before typesetting for that same reason; the TikZ exports it skips entirely,
# since the book \inputs the .tex via \tikzfig and never the exported PDF.
# `make -C latex/fig clean` is the deliberate way to discard them.

## distclean: also remove dist/ and the downloaded toolchain
distclean: clean
	rm -rf $(DIST) $(TOOLS)

$(TAILWIND):
	@mkdir -p $(TOOLS)
	@echo "downloading tailwindcss $(TAILWIND_VERSION) ($(TAILWIND_OS)-$(TAILWIND_ARCH))"
	@curl -fsSL -o $@ $(TAILWIND_URL)
	@chmod +x $@

help:
	@grep -hE '^## ' $(MAKEFILE_LIST) | sed 's/## /  make /'
