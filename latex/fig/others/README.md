# fig/others

Figures that are not generated from anything in this repository — a diagram
drawn in another application, an exported chart, a screenshot, a photograph.

Drop the file in and include it by bare filename; this directory is on the
class's `\graphicspath`, so no path is needed:

```latex
\includegraphics[width=0.8\textwidth]{apparatus.png}
```

There is no `Makefile` here because there is nothing to build. The sibling
directories each hold a source plus the output built from it:

| Directory | Source | Built by |
|---|---|---|
| `plots/` | `make-figs.py` | matplotlib |
| `svg/` | `*.svg` | `rsvg-convert` / `inkscape` |
| `tikz/` | `*.tex` | LuaLaTeX (`standalone`) |

Prefer PDF for anything vector; use PNG only for genuinely raster content.
Filenames must be unique across all four directories, since they share one
search path.
