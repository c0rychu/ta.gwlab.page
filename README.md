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

To link a notebook, commit it under `ipynb/` and prefix its path with the Colab base:

```
https://colab.research.google.com/github/c0rychu/ta.gwlab.page/blob/main/ipynb/lab01.ipynb
└──────────────────── fixed ────────────────────┘└─── repo ───┘└ branch ┘└─ path in repo ─┘
```

## Local development

```sh
make serve     # build and serve http://localhost:8000
make site      # build into dist/ only
make clean     # remove dist/
make help      # list targets
```

`make` downloads the Tailwind standalone binary into `.tools/` on first run (no Node
required) and uses [uv](https://docs.astral.sh/uv/) to run the build script. Both
`.tools/` and `dist/` are gitignored — nothing generated is ever committed. Re-run
`make site` after editing and reload the page.

## Layout

```
site/           the website
  build.py        the entire static-site generator (~60 lines)
  content/        markdown you edit  →  rendered into the page
  src/            index.html template, app.js, Tailwind entry CSS
  static/         copied verbatim to the site root (CNAME, favicon)
ipynb/          notebooks, linked from links.md via Colab
dist/           build output — gitignored, and exactly what Pages serves
```

One top-level directory per kind of source. `dist/` is the only output.

## Adding LaTeX lecture notes later

Create `latex/` and put document roots directly in it (`latex/week01.tex`). Nothing
else needs changing: `make latex` builds them locally with `latexmk`, and the CI
workflow's LaTeX step activates itself as soon as a `.tex` file exists, publishing the
PDFs to `https://ta.gwlab.page/notes/week01.pdf`. PDFs are gitignored by design — the
source is the source of truth.

## Deployment

Push to `main` → `.github/workflows/deploy.yml` builds and publishes to GitHub Pages.
Pull requests run the build only. One-time setup on the repo:

1. **Settings → Pages → Source: GitHub Actions**
2. DNS on `gwlab.page`: `CNAME` record `ta` → `c0rychu.github.io`
3. **Settings → Pages → Custom domain:** `ta.gwlab.page`, then tick **Enforce HTTPS**
   once the certificate is issued.

`site/static/CNAME` keeps the custom domain attached across redeploys.
