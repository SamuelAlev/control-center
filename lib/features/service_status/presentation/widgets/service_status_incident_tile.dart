part of 'service_status_indicator.dart';

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final GitHubStatusIncident incident;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: () => _open(incident.shortlink),
      borderRadius: BorderRadius.circular(8),
      semanticLabel: incident.name,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered) || pressed;
        // The tile is now the block's only link, so it has to read as one at
        // rest and CHANGE visibly on hover in BOTH themes. Half-alpha fills
        // and borders did neither in dark: `bgSecondary` IS `panel` there, so
        // a 50% wash of it over the flyout was the flyout, and a 50%
        // `borderSecondary` (gray800 on gray900) had nothing left to see.
        // So: a solid `bgTertiary` fill, which is a step off `panel` on both
        // palettes, washed further by the same `hover`/`hoverStrong` overlays
        // every other tappable surface uses (they invert per theme, so the
        // fill darkens in light and lightens in dark). The border pair is
        // `CcButtonVariant.line`'s verbatim — `borderPrimary` at rest (one
        // rung darker than before) firming to `fg` on hover — so this card
        // and the app's other bordered surfaces speak one language.
        final fill = tokens.bgTertiary;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: pressed
                ? Color.alphaBlend(tokens.hoverStrong, fill)
                : hovered
                ? Color.alphaBlend(tokens.hover, fill)
                : fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hovered ? tokens.fg : tokens.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.circleAlert, size: 14, color: tokens.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      incident.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textTertiary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // The affordance itself: quiet at rest, full ink on hover, so
              // the card reports "this opens the incident" the moment the
              // pointer lands rather than only through the fill.
              Icon(
                AppIcons.externalLink,
                size: 12,
                color: hovered ? tokens.textPrimary : tokens.textTertiary,
              ),
            ],
          ),
        );
      },
    );
  }
}
