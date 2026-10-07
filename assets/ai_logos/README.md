# AI brand logos

Monochrome marks drawn by `AiBrandLogo` (`lib/shared/widgets/ai_brand_logo.dart`) in the subscription-usage pill, the runner and provider rails, provider model lists, the model browser and the service status flyout and sidebar entry. Each file is named after an `AiBrand` value; `AiBrand.forProvider` maps provider, harness and adapter ids to a brand and `AiBrand.forModel` maps a model id or name to the vendor that made it.

- `control-center.svg` is `assets/logo_white.svg` with its drop-shadow filter removed and a single fill.
- `github.svg` is the GitHub mark from [Simple Icons](https://simpleicons.org) (CC0), on the same 24×24 canvas with one `#000000` fill. It is not an AI brand; it ships here so the service status surfaces draw every provider through one widget.
- Every other mark comes from [LobeHub Icons](https://github.com/lobehub/lobe-icons) (`@lobehub/icons-static-svg`, MIT), reduced to one `#000000` fill on a 24×24 canvas.

The widget tints each mark with `BlendMode.srcIn`, so a replacement must stay a single-colour mark. A brand without a file, or a file that fails to parse, falls back to a generic glyph.
