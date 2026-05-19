// TODO: update to use Forui component (FSelect / FDropdown / FFlyout) instead of PopupMenuButton.
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension ConversationModeL10n on ConversationMode {
  String get displayName => switch (this) {
    ConversationMode.chat => 'Agent',
    ConversationMode.plan => 'Plan',
    ConversationMode.review => 'Review',
  };

  static List<ConversationMode> get selectable => const [
    ConversationMode.chat,
    ConversationMode.plan,
  ];
}

/// Compact mode selector rendered on the far-left of the composer toolbar.
///
/// Displays the current [ConversationMode] as a label (e.g. "Agent", "Plan")
/// and opens a popup menu with the selectable subset of modes.
/// When [ConversationMode.plan] is active the label is tinted amber so the
/// restriction is visually obvious.
class ModeDropdown extends StatelessWidget {
  /// Creates a [ModeDropdown].
  const ModeDropdown({
    required this.currentMode,
    required this.onChanged,
    super.key,
  });

  /// The currently selected conversation mode.
  final ConversationMode currentMode;

  /// Called when the user selects a different mode from the popup menu.
  final ValueChanged<ConversationMode> onChanged;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final isPlan = currentMode == ConversationMode.plan;
    final foregroundColor = isPlan
        ? (tokens?.fgBrandPrimary ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final backgroundColor = isPlan
        ? (tokens?.accentSoft ??
            Colors.orange.shade100.withValues(alpha: 0.25))
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return PopupMenuButton<ConversationMode>(
      tooltip: l10n.conversationMode,
      offset: const Offset(0, -_height - 4),
      constraints: const BoxConstraints(minWidth: 120),
      itemBuilder: (context) => [
        for (final mode in ConversationModeL10n.selectable)
          PopupMenuItem<ConversationMode>(
            value: mode,
            height: 40,
            child: Row(
              children: [
                Icon(
                  _iconFor(mode),
                  size: 18,
                  color: mode == currentMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Text(
                  mode.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: mode == currentMode ? FontWeight.w600 : FontWeight.normal,
                    color: mode == currentMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: onChanged,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.brLg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(currentMode),
              size: 16,
              color: foregroundColor,
            ),
            const SizedBox(width: 6),
            Text(
              currentMode.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: foregroundColor,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ConversationMode mode) => switch (mode) {
    ConversationMode.chat => Icons.auto_awesome,
    ConversationMode.plan => Icons.edit_note,
    ConversationMode.review => Icons.rate_review,
  };
}
