#!/usr/bin/env python3
"""Regenerate the macOS app-icon PNG set following Apple's Big Sur HIG.

Apple macOS app icon grid (https://developer.apple.com/design/human-interface-guidelines/app-icons):
  - 1024x1024 canvas, fully transparent outside the icon body.
  - Icon body is 824x824, centered -> 100px clear gutter on all four sides.
  - Corner radius 185.4px (the Big Sur rounded-rectangle).
  - Drop shadow: ~28px blur, 12px downward Y offset (no X), pure black @ 50%.

The brand gradient and the paragliding figure are sourced from
assets/logo_with_background.svg so the icon stays in sync with the rest of the
brand. Run after changing the source SVG:

    python3 scripts/generate_macos_app_icons.py

Requires rsvg-convert (brew install librsvg).
"""
import os
import pathlib
import re
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "logo_with_background.svg"
OUT = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

# Apple Big Sur grid.
CANVAS = 1024
BODY = 824
GUTTER = (CANVAS - BODY) / 2  # 100
RADIUS = 185.4
# Figure inset inside the body (~10% of the body), centered on the canvas.
FIGURE = 660
FIGURE_XY = (CANVAS - FIGURE) / 2  # 182

SIZES = (16, 32, 64, 128, 256, 512, 1024)

source = SRC.read_text()

# Pull the inner figure <svg ...>...</svg> (the white paraglider + its shadow)
# out of the brand source and reposition it inside the icon body.
match = re.search(r'<svg x="128".*?</svg>', source, re.DOTALL)
if not match:
    raise SystemExit("Could not find the figure <svg> block in logo_with_background.svg")
figure = match.group(0)
figure = re.sub(
    r'x="128" y="128" width="768" height="768"',
    f'x="{FIGURE_XY:g}" y="{FIGURE_XY:g}" width="{FIGURE:g}" height="{FIGURE:g}"',
    figure,
)

template = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" viewBox="0 0 {CANVAS} {CANVAS}">
  <defs>
    <linearGradient id="brandBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#ffb83e"/>
      <stop offset="0.34" stop-color="#ff8105"/>
      <stop offset="0.7" stop-color="#fa520f"/>
      <stop offset="1" stop-color="#c0400f"/>
    </linearGradient>
    <clipPath id="squircle">
      <rect x="{GUTTER:g}" y="{GUTTER:g}" width="{BODY}" height="{BODY}" rx="{RADIUS}" ry="{RADIUS}"/>
    </clipPath>
    <filter id="iconShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000000" flood-opacity="0.5"/>
    </filter>
  </defs>
  <g filter="url(#iconShadow)">
    <g clip-path="url(#squircle)">
      <rect x="{GUTTER:g}" y="{GUTTER:g}" width="{BODY}" height="{BODY}" fill="url(#brandBg)"/>
      {figure}
    </g>
  </g>
</svg>
"""

with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as fh:
    fh.write(template)
    tmp = fh.name

try:
    for size in SIZES:
        subprocess.run(
            ["rsvg-convert", "-w", str(size), "-h", str(size), tmp,
             "-o", str(OUT / f"app_icon_{size}.png")],
            check=True,
        )
finally:
    os.unlink(tmp)

print(f"Regenerated {len(SIZES)} macOS app icons in {OUT.relative_to(ROOT)}")
