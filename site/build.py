#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=3.0", "linkify-it-py>=2.0"]
# ///
"""Build the static site into dist/.

The whole "static site generator" is this file. It renders the editable markdown
in site/content/ into HTML, drops it into the placeholders in site/src/index.html,
and copies the static assets across. Run it with `uv run site/build.py` (uv reads
the dependency block above) or via `make site`, which also compiles the CSS.
"""

import re
import shutil
from datetime import date
from pathlib import Path

from markdown_it import MarkdownIt

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
DIST = ROOT / "dist"

# Outbound links (Canvas, Colab, ...) should not replace the tool page itself,
# which may be mid-countdown. Applied to the rendered markdown, not the template.
LINK_ATTRS = ' target="_blank" rel="noopener noreferrer"'


# CommonMark, so the file renders exactly as GitHub previews it — in particular
# nested lists work at any indent, which Python-Markdown silently flattened at
# two spaces. "gfm-like" adds tables, strikethrough and bare-URL autolinking.
MD = MarkdownIt("gfm-like")


def render_markdown(path: Path) -> str:
    html = MD.render(path.read_text(encoding="utf-8"))
    html = re.sub(r"<!--.*?-->", "", html, flags=re.DOTALL)  # editing notes stay in the source
    return re.sub(r"<a (?![^>]*\btarget=)", f"<a{LINK_ATTRS} ", html)


def build() -> None:
    if DIST.exists():
        shutil.rmtree(DIST)
    (DIST / "assets").mkdir(parents=True)

    tokens = {
        "{{LINKS}}": render_markdown(SITE / "content" / "links.md"),
        "{{BUILD_DATE}}": date.today().isoformat(),
    }

    html = (SITE / "src" / "index.html").read_text(encoding="utf-8")
    for token, value in tokens.items():
        html = html.replace(token, value)
    if leftover := re.findall(r"\{\{[A-Z_]+\}\}", html):
        raise SystemExit(f"unsubstituted token(s) in index.html: {sorted(set(leftover))}")
    (DIST / "index.html").write_text(html, encoding="utf-8")

    shutil.copy2(SITE / "src" / "app.js", DIST / "assets" / "app.js")
    shutil.copytree(SITE / "static", DIST, dirs_exist_ok=True)

    print(f"built {DIST.relative_to(ROOT)}/ ({tokens['{{BUILD_DATE}}']})")


if __name__ == "__main__":
    build()
