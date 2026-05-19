import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bookmark toggle shared by the article card, the featured hero, and the
/// digest list row.
///
/// State is conveyed by three channels, never colour alone: the glyph swaps
/// ([LucideIcons.bookmarkCheck] vs [LucideIcons.bookmark]), the tint shifts to
/// brand when saved, and the control carries a [Semantics] label plus a
/// tooltip so screen-reader and pointer users both get "Save article" /
/// "Remove from saved".
class SaveToggleButton extends StatelessWidget {
  /// Creates a [SaveToggleButton].
  const SaveToggleButton({
    super.key,
    required this.saved,
    required this.onToggle,
    this.size = 16,
  });

  /// Whether the article is currently bookmarked.
  final bool saved;

  /// Invoked when the user toggles the saved state.
  final VoidCallback onToggle;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final label = saved ? l10n.removeFromSaved : l10n.saveArticle;

    return Semantics(
      button: true,
      toggled: saved,
      label: label,
      child: CcTooltip(
        message: label,
        child: InkWell(
          onTap: onToggle,
          borderRadius: AppRadii.brSm,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
              size: size,
              color: saved
                  ? (tokens?.fgBrandPrimary ?? theme.colorScheme.primary)
                  : (tokens?.textTertiary ??
                        theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
