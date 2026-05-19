# IDE / editor logos

Brand logos for the PR **"open in editor"** split button + dropdown
(`OpenInIdeButton`). Drop one logo per editor here — **`.svg` or `.png`** — named
by its **editor id** (see the list below). The files currently in this folder
are **placeholders** — replace them with the real logos.

## Rules

- **Format:** `.svg` (preferred — scales crisply at any size) **or** `.png`
  (used when only a raster logo is available). The widget resolves the format
  from the asset manifest at runtime: if both `<id>.svg` and `<id>.png` are
  bundled, the SVG wins.
- **PNG sizing:** logos render at 18–20 px, so supply PNGs at **2–3×** that
  (≈ 48–64 px square) for crisp rendering on HiDPI displays.
- **Viewport:** square (e.g. `viewBox="0 0 24 24"` for SVG, a square canvas for
  PNG), transparent background.
- **Filename:** exactly `<id>.svg` or `<id>.png` from the table below
  (lowercase, no spaces).
- A **missing or invalid** file is safe: the button automatically falls back to
  a generic Lucide glyph (a code / terminal icon), so nothing breaks while logos
  are being added.

## Editor ids

| id            | Editor          | Logo type   |
|---------------|-----------------|-------------|
| `vscode`      | VS Code         | full-color  |
| `cursor`      | Cursor          | **monochrome** |
| `zed`         | Zed             | **monochrome** |
| `windsurf`    | Windsurf        | **monochrome** |
| `antigravity` | Antigravity     | full-color  |
| `intellij`    | IntelliJ IDEA   | full-color  |
| `webstorm`    | WebStorm        | full-color  |
| `pycharm`     | PyCharm         | full-color  |
| `sublime`     | Sublime Text    | full-color  |
| `warp`        | Warp            | full-color  |

### Monochrome logos

`cursor`, `zed`, and `windsurf` are **single-color** marks. They are tinted at
render time to the theme's foreground color (via `BlendMode.srcIn`), so they
read correctly in both light and dark mode — supply them as a **single-color**
SVG (the fill color is ignored) or a **transparent PNG whose alpha is the mark**
(the RGB is replaced by the tint). Full-color logos keep their own palette
untouched.

To change which logos are treated as monochrome, edit `_monochromeLogos` in
`lib/features/pr_review/presentation/widgets/open_in_ide_button.dart`.

After adding or renaming files, no code change is needed — the folder is already
declared under `flutter:` → `assets:` in `pubspec.yaml`. Run `flutter pub get`
if a hot restart doesn't pick up new files.
