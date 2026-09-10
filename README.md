# ta.gwlab.page

Classroom tools for teaching, live at **<https://ta.gwlab.page>**.

| Tab | What it does |
| --- | --- |
| **Home** | Canvas, Colab notebooks, references — generated from [`site/content/links.md`](site/content/links.md), with a filter box. This is the landing tab. |
| **Timer** | Big countdown. Default 10 min, ±5 min, presets, or type `10` / `7:30` / `90s`. Space starts and pauses. Turns red and flashes at zero. |
| **Picker** | Picks a random number from 1 to N with a decelerating reveal — for calling on students. Optional *no repeats* until you clear. |
| **Black Screen** | Blanks the screen (and the projector). Click or <kbd>Esc</kbd> to come back; there is a fullscreen button. The on-screen hint fades out once the mouse stops moving and returns when it moves again. |

Each tab has its own URL (`#home`, `#timer`, `#picker`, `#black`), so you can bookmark
the one you open most.

## Editing the links

Edit `site/content/links.md` and push. That is the whole workflow — CI rebuilds and
redeploys. It is ordinary markdown: `## Heading` starts a section, each `- [Title](URL)`
is a link, and any text after the link on the same line becomes the grey description.
Indent a `-` under another to nest it (any indent works), and fenced ` ```python `
blocks render as code. Rendering is CommonMark via
[markdown-it-py](https://markdown-it-py.readthedocs.io/), so what GitHub shows you in
the file preview is what the page will look like.

To link a notebook, commit it under `ipynb/` and prefix its path with the Colab base:

```
https://colab.research.google.com/github/c0rychu/ta.gwlab.page/blob/main/ipynb/lab01.ipynb
└──────────────────── fixed ────────────────────┘└─── repo ───┘└ branch ┘└─ path in repo ─┘
```

## Local development

```sh
make serve     # build and serve http://localhost:8000
make site      # build into dist/ only
make clean     # remove LaTeX aux files (keeps dist/)
make distclean # also remove dist/ and the downloaded toolchain
make help      # list targets
```

`make` downloads the Tailwind standalone binary into `.tools/` on first run (no Node
required) and uses [uv](https://docs.astral.sh/uv/) to run the build script. Both
`.tools/` and `dist/` are gitignored — nothing generated is ever committed. Re-run
`make site` after editing and reload the page.

The build script needs no project setup: its one dependency is declared in its own
[PEP 723](https://peps.python.org/pep-0723/) header, so `uv run site/build.py` resolves
it in an isolated environment. Without uv, `pip install markdown && python site/build.py`
does the same thing.

## Working on the notebooks

```sh
uv sync
```

That creates `.venv/` with `ipykernel`, `numpy`, `matplotlib` and `astropy` from the
`notebooks` dependency group in `pyproject.toml`, pinned by the committed `uv.lock`.
Point Jupyter or VS Code at `.venv` as the kernel. To add a package:

```sh
uv add --group notebooks scipy
```

`pyproject.toml` exists only for this environment — the repo is not a Python package
(`package = false`), and the site build does not read it, so CI never installs the
scientific stack just to render a page.

## Layout

```
site/           the website
  build.py        the entire static-site generator (~60 lines)
  content/        markdown you edit  →  rendered into the page
  src/            index.html template, app.js, Tailwind entry CSS
  static/         copied verbatim to the site root (CNAME, favicon)
ipynb/          notebooks, linked from links.md via Colab
latex/          the lecture notes — gwbook.cls, book.tex, chapters/
dist/           build output — gitignored, and exactly what Pages serves
pyproject.toml  notebook dev environment only (uv sync); not used by the site build
```

One top-level directory per kind of source. `dist/` is the only output.

## The lecture notes

`latex/` holds a book built with `gwbook.cls`, a class for old-school physics-monograph
typesetting: a 7×10in trim rather than a letter sheet, a fixed 5.6in measure, and
generously spaced displayed equations.

```
make latex                  # book.pdf plus one PDF per chapter → dist/notes/
make latex CH=ch01-electrostatics   # just that chapter, for fast iteration
make latex-check            # fail if any listing was left unhighlighted
```

Published as `https://ta.gwlab.page/notes/book.pdf` and
`…/notes/ch01-electrostatics.pdf`. PDFs are gitignored by design — the source is the source of
truth.

### Writing a chapter

**`latex/gwbook-template.tex` is the reference for all of this** — it shows every environment
with its source next to its output. Read that first; the summary below is just an index.

It is published twice from one source, once per typeface, so you can compare the two on
real material: `/notes/gwbook-template.pdf` (TeX Gyre Schola) and `/notes/gwbook-template-charter.pdf`
(XCharter). The two roots differ only in the class option; the content lives in
`latex/include/gwbook-template-body.tex`. Anything under `latex/include/` is a shared fragment
rather than a document root, which is what keeps `make latex` from trying to compile it
on its own.

Chapters live in `latex/chapters/` and are `subfiles`, so each one is *also* a complete
document you can compile on its own. Start a new one by copying an existing chapter's
first two lines, add a `\subfile{}` for it in `book.tex`, and you are done. Chapter order
lives only in `book.tex`.

The class provides `keyeq` (a boxed key equation, and `keyeq*` / `keyalign` variants),
`theorem`, `definition`, `example`, `remark`, a plain `gwbox`, and `code`:

```latex
\begin{code}{python}          % syntax highlighted, no line numbers
\begin{code}[linenos]{python} % with line numbers
```

Listings are built to survive being copied out of the PDF: indentation is preserved, and
line numbers carry an empty `ActualText` so they are skipped by text extraction and never
land in your paste.

### Citations

Add entries to `latex/refs.bib` and cite with `\cite{key}`. Rendering is Physical Review
style via `biblatex-phys` — numeric labels, journal abbreviations, no article titles.

`\chapterbib` at the end of a chapter prints that chapter's **References**; `\bookbib` in
the back matter prints the **Bibliography**, meaning everything cited anywhere in the book
and nothing else. Entries sitting unused in `refs.bib` never appear.

This uses biblatex's `refsegment=chapter` rather than `refsection`: segments subdivide one
reference section, so the back-matter list can be the union of every chapter's citations.
Separate refsections cannot be merged that way — filling a back-matter list would need
`\nocite{*}`, which lists the whole `.bib` regardless of what the text cites. The
trade-off is that labels run continuously through the book instead of restarting at `[1]`
in each chapter, which is the right behaviour for a numeric style: one key keeps one
number throughout.

### Figures

Artwork goes in `latex/fig/`, sorted by how it is made. You never write those directory
names — the class puts all of them on `\graphicspath`, each twice, so the same
`\includegraphics` resolves from the book build and from a standalone chapter build.

```
latex/fig/plots/    plotting scripts  + the PDF/PNG they write   (make)
          svg/      SVG sources       + the PDF converted from them (make)
          tikz/     TikZ sources      + one exported PDF each    (make)
          others/   figures from anywhere else; nothing to build
```

Each subdirectory is self-contained — source and generated output together — and all
four are on `\graphicspath`, so a figure is included by bare filename regardless of which
one it lives in. Filenames must therefore be unique across the four.

| Format | How |
|---|---|
| PDF, PNG, JPG | `\includegraphics[width=0.8\textwidth]{gwbook-template-sphere-field.pdf}` |
| TikZ | `\tikzfig{gwbook-template-gauss-sphere.tex}` — a file holding one `tikzpicture`, no preamble |
| SVG | `make fig` converts it, then include the resulting `.pdf` |

`make fig` regenerates everything; each subdirectory also has its own `Makefile` so you
can work on one figure without touching the rest — e.g.
`make -C latex/fig/tikz gwbook-template-gauss-sphere.pdf` while drawing.

**TikZ figures are `\input` as `.tex`, not included as PDFs.** That is what lets their
labels take the document's own fonts, so they still match if the book is built with
`[charter]`. The exported PDFs in `fig/tikz/` exist so the same drawing can be reused in
slides or a poster; they are gitignored like the other generated output, and the `.tex`
remains the source of truth.

**SVG is converted rather than included directly.** The `svg` package works only by
shelling out to Inkscape mid-compile, which needs `-shell-escape` and an Inkscape the CI
container does not have.

**Only sources are committed.** Each subdirectory has its own `.gitignore` for its output,
so nothing generated is in the repo — the same rule as `dist/` and `.tools/`. Run
`make fig` after a fresh clone, and again whenever you change a figure source; `make latex`
stops with a reminder if you forget. CI regenerates them before typesetting.

The exception is `others/`, whose contents are committed: those files come from elsewhere
and have no source here to rebuild them from.

#### Tools needed to build figures

| Tool | For | Install |
|---|---|---|
| `rsvg-convert` | SVG → PDF (preferred, ~30× faster) | `brew install librsvg` |
| `inkscape` | SVG → PDF fallback | `brew install --cask inkscape` |
| project venv | the plotting scripts (matplotlib, physics-plot) | `uv sync` |
| LuaLaTeX | exporting TikZ figures | already required for the notes |

Plots share one look via [physics-plot](https://c0rychu.github.io/physics-plot/); each
script starts with

```python
plt.style.use(["physics_plot.pp_base", "physics_plot.colors.ggplot"])
```

which gives serif labels matching the book's type, and sets figure size and
`savefig.dpi`. Swap `colors.ggplot` for `colors.colorblind` on any figure that needs
more than a couple of distinguishable series.

CI installs `librsvg2-bin` and runs `uv sync`, then builds `plots` and `svg` only — the
TikZ exports are for reuse in slides and are not needed to typeset the notes, since the
book `\input`s the `.tex`.

### Cross-references

Everything is clickable — the TOC, citations, and every `\ref`. Prefer `\autoref` over
`\ref`, because it makes the whole phrase one link rather than just the numeral:

```latex
\autoref{ch:gauss}          % → "Chapter 2", all of it clickable
\autoref{eq:gauss-integral} % → "Eq. 2.1"
\autoref{thm:divergence}    % → "Theorem 2.1"
```

`\label` works inside `keyeq` and inside the theorem-like boxes. References that point
into *another* chapter resolve in standalone chapter PDFs too, via `xr-hyper` reading
`book.aux` — so build the book at least once before relying on them.

Class options: `charter` swaps the typeface from TeX Gyre Schola to XCharter (each
carries its own leading); `letterpaper` / `a4paper` put the same text block on a
printable sheet; `twoside` mirrors the margins; `draft` skips syntax highlighting for
faster rebuilds; `nocolor` makes the boxes and code black-and-white.

### Two things worth knowing

**Build with `latexmk`, never a bare `lualatex`.** minted 3 highlights on its *second*
pass, and a single pass produces a red `<MINTED>` placeholder while still exiting 0 —
a silent failure. `make latex-check` is the guard, and CI runs it.

**`latex/` keeps its `.aux` files between builds.** They are gitignored, they let
latexmk skip unchanged chapters, and a surviving `book.aux` is what lets a single-chapter
build still resolve references into other chapters. `make clean` clears them.

## Deployment

Push to `main` → `.github/workflows/deploy.yml` builds and publishes to GitHub Pages.
Pull requests run the build only. One-time setup on the repo:

1. **Settings → Pages → Source: GitHub Actions**
2. DNS on `gwlab.page`: `CNAME` record `ta` → `c0rychu.github.io`
3. **Settings → Pages → Custom domain:** `ta.gwlab.page`, then tick **Enforce HTTPS**
   once the certificate is issued.

`site/static/CNAME` keeps the custom domain attached across redeploys.
