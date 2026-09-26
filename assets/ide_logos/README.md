# IDE and editor logos

Assets for the PR `OpenInIdeButton`. Existing files are placeholders; replace with licensed, attribution-appropriate logos. Name each `<id>.svg` (preferred) or `<id>.png`:

| Full color | Monochrome |
| --- | --- |
| `vscode`, `antigravity`, `intellij`, `webstorm`, `pycharm`, `sublime`, `warp` | `cursor`, `zed`, `windsurf` |

Use a square transparent canvas. PNGs should be about 48–64px square for 18–20px rendering on HiDPI screens. A monochrome SVG should contain a single-color mark; a PNG must have transparent alpha defining the mark. `OpenInIdeButton` tints these three logos via `BlendMode.srcIn`; full-color marks keep their colors. Update `_monochromeLogos` in `lib/features/pr_review/presentation/widgets/open_in_ide_button.dart` if this set changes.

Assets are declared under `flutter.assets` in `pubspec.yaml`. When both formats exist, SVG wins. Missing/invalid assets fall back to a generic code/terminal glyph. After adding a file, use `fvm flutter pub get` if hot restart does not pick it up.
