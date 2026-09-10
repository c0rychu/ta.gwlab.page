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

.PHONY: all site latex serve clean distclean help

all: site latex

## site: render markdown + templates into dist/, then compile the CSS
# The CSS step must run after the HTML exists: Tailwind only emits the classes it
# finds in the sources it scans.
site: $(TAILWIND)
	uv run site/build.py
	$(TAILWIND) -i site/src/input.css -o $(DIST)/assets/app.css --minify

## latex: build PDFs into dist/notes/ — a no-op until a latex/ directory exists
latex:
	@if [ -d latex ]; then \
	  mkdir -p $(DIST)/notes; \
	  for f in latex/*.tex; do \
	    echo "latexmk $$f"; \
	    latexmk -pdf -interaction=nonstopmode -halt-on-error \
	      -outdir=$(CURDIR)/$(DIST)/notes "$$f" || exit 1; \
	  done; \
	  find $(DIST)/notes -type f ! -name '*.pdf' -delete; \
	else \
	  echo "no latex/ directory — skipping"; \
	fi

## serve: build, then serve dist/ on http://localhost:8000 (override with PORT=)
serve: site
	@echo "serving $(DIST)/ at http://localhost:$(PORT)  (re-run 'make site' after edits)"
	@python3 -m http.server $(PORT) -d $(DIST)

## clean: remove build output
clean:
	rm -rf $(DIST)

## distclean: also remove the downloaded toolchain
distclean: clean
	rm -rf $(TOOLS)

$(TAILWIND):
	@mkdir -p $(TOOLS)
	@echo "downloading tailwindcss $(TAILWIND_VERSION) ($(TAILWIND_OS)-$(TAILWIND_ARCH))"
	@curl -fsSL -o $@ $(TAILWIND_URL)
	@chmod +x $@

help:
	@grep -hE '^## ' $(MAKEFILE_LIST) | sed 's/## /  make /'
