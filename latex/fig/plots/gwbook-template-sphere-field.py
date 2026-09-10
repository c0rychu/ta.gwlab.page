#!/usr/bin/env python3
"""E(r) for a uniformly charged sphere: linear inside, inverse-square outside.

Demo figure for the gwbook template -- delete once the notes have real ones.
Vector output, which is what you want for anything drawn or plotted.

Styling comes from https://c0rychu.github.io/physics-plot/ so every figure in
the notes shares one look. Swap `colors.ggplot` for `colors.colorblind` if a
figure ever needs more than a couple of distinguishable series.
"""
import pathlib

import matplotlib
matplotlib.use("Agg")          # headless: this runs in CI
import matplotlib.pyplot as plt
import numpy as np

plt.style.use(["physics_plot.pp_base", "physics_plot.colors.ggplot"])

OUT = pathlib.Path(__file__).with_suffix(".pdf")

R = 1.0
r_in = np.linspace(0, R, 200)
r_out = np.linspace(R, 3.2, 400)
E_in = r_in / R                      # units of Q/4*pi*eps0*R^2
E_out = (R / r_out) ** 2

fig, ax = plt.subplots()
# One curve, drawn in two pieces -- so both pieces take the same colour rather
# than stepping the cycle, which would read as two different quantities.
line, = ax.plot(r_in, E_in)
ax.plot(r_out, E_out, color=line.get_color())
ax.axvline(R, color="0.6", ls="--", lw=0.8)   # a guide, not data

# One curve in two regimes, so label them directly rather than with a legend.
ax.annotate(r"$E \propto r$", xy=(0.18, 0.80))
ax.annotate(r"$E \propto 1/r^{2}$", xy=(1.55, 0.62))

ax.set_xlabel("distance from centre $r$")
ax.set_ylabel("field $E$")
ax.set_xlim(0, 3.2)
ax.set_ylim(0, 1.15)
ax.set_yticks([])
# R is the only x value worth marking, and it belongs on the axis: as a free
# annotation it collided with the axis label.
ax.set_xticks([R])
ax.set_xticklabels(["$R$"])

fig.tight_layout(pad=0.3)
fig.savefig(OUT, bbox_inches="tight")
print("wrote", OUT.name)
