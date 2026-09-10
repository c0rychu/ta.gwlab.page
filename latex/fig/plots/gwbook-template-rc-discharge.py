#!/usr/bin/env python3
"""Capacitor discharge, with the time constant marked.

Demo figure for the gwbook template -- delete once the notes have real ones.
Raster output, purely to exercise the PNG path; a real figure like this should
be vector.

Styling comes from https://c0rychu.github.io/physics-plot/ so every figure in
the notes shares one look.
"""
import pathlib

import matplotlib
matplotlib.use("Agg")          # headless: this runs in CI
import matplotlib.pyplot as plt
import numpy as np

plt.style.use(["physics_plot.pp_base", "physics_plot.colors.ggplot"])

OUT = pathlib.Path(__file__).with_suffix(".png")

t = np.linspace(0, 5, 400)
v = np.exp(-t)

fig, ax = plt.subplots()
line, = ax.plot(t, v)
# Same colour as the curve: this marks a point *on* it, not a second series.
ax.plot([1], [np.exp(-1)], "o", color=line.get_color())
ax.annotate(r"$V = V_0/e$ at $t = RC$", xy=(1, np.exp(-1)), xytext=(1.35, 0.52),
            arrowprops=dict(arrowstyle="-", lw=0.7))

ax.set_xlabel(r"time $t / RC$")
ax.set_ylabel(r"voltage $V / V_0$")
ax.set_xlim(0, 5)
ax.set_ylim(0, 1.05)

fig.tight_layout(pad=0.3)
fig.savefig(OUT, bbox_inches="tight")
print("wrote", OUT.name)
