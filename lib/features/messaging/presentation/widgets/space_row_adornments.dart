/// The leading, trailing and count adornments a space sidebar row is built
/// from. Split out of `space_sidebar_item.dart` so that file stays inside the
/// presentation size budget. `SpaceRow` composes them.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'space_row_leading_icon.dart';
part 'space_row_overflow_menu.dart';

/// Side of the overflow trigger and the conversations caret.
const double kSpaceSidebarTrailingControl = 22;

/// The quiet numeric chip after a space name: how many parallel conversations
/// the space holds. Neutral tones on purpose — an inventory count, not a
/// notification, so it never reads as an unread signal.
class SpaceCountChip extends StatelessWidget {
  /// Creates the conversation-count chip.
  const SpaceCountChip({
    super.key,
    required this.count,
    required this.selected,
  });

  /// How many parallel conversations the space holds.
  final int count;

  /// On the selected row's solid brand fill the neutral wash + tertiary ink
  /// would wash out, so the chip inverts to translucent-and-solid `accentOn`.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: selected ? t.accentOn.withValues(alpha: 0.18) : t.hoverStrong,
        borderRadius: AppRadii.brSm,
      ),
      // No `alignment`: the row's fixed 32px height reaches this container
      // as a bounded constraint, and a Container WITH an alignment expands
      // to fill it — the chip would stretch to the full row height instead
      // of hugging the digits. The enclosing Row already centers it.
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 10,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: selected ? t.accentOn : t.textTertiary,
        ),
      ),
    );
  }
}

/// Trailing indicator on a space row. Differentiated by shape as well as
/// colour (never status-by-colour-alone per DESIGN.md):
/// - `needsInput` → a ringed accent target (the actionable "answer me" signal).
/// - `running` → handled on the leading slot (a spinner), so nothing renders
///   here to avoid a redundant double indicator.
/// - `idle` + unread → a filled accent dot (the "agent finished, you have
///   unseen messages" notification). Needs-input wins over it.
class SpaceTrailingIndicator extends StatelessWidget {
  /// Creates the trailing indicator.
  const SpaceTrailingIndicator({
    super.key,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.selected,
  });

  /// The space's live status, which picks the shape.
  final SpaceStatus status;

  /// Whether the space holds messages the user has not seen.
  final bool unread;

  /// Whether the leading slot already shows the running spinner.
  final bool leadingHandlesRunning;

  /// On the selected row's solid brand fill the accent signals would vanish
  /// (they ARE the fill's hue), so every indicator renders in `accentOn`
  /// instead — the shape differentiation (ring vs dot) is untouched.
  final bool selected;

  /// Whether anything should render at all (avoids reserving trailing space
  /// when there's no signal).
  static bool shouldShow({
    required SpaceStatus status,
    required bool unread,
    required bool leadingHandlesRunning,
  }) {
    switch (status) {
      case SpaceStatus.needsInput:
        return true;
      case SpaceStatus.running:
        return !leadingHandlesRunning;
      case SpaceStatus.idle:
        return unread;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final signal = selected ? t.accentOn : t.accent;
    switch (status) {
      case SpaceStatus.needsInput:
        // Ringed accent target — the strongest call to action.
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: signal, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: signal, shape: BoxShape.circle),
          ),
        );
      case SpaceStatus.running:
        // Fallback only — spaces spin on the leading slot.
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: selected
                ? t.accentOn.withValues(alpha: 0.6)
                : t.textTertiary,
            shape: BoxShape.circle,
          ),
        );
      case SpaceStatus.idle:
        // The unseen-messages notification dot (accent, distinct from the
        // muted running dot by colour).
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: signal, shape: BoxShape.circle),
        );
    }
  }
}

/// Reveals the overflow trigger of the [SpaceRowOverflowMenu]s below from an
/// enclosing card's hover or keyboard focus (the global sidebar's space card,
/// which owns the press for its whole surface).
///
/// An inherited flag rather than a row parameter so the card builds its
/// content once and re-wraps only this scope as hover changes: the trigger
/// that reads it rebuilds, the title, reveal and conversation rows do not.
class SpaceMenuReveal extends InheritedWidget {
  /// Creates a [SpaceMenuReveal].
  const SpaceMenuReveal({
    super.key,
    required this.revealed,
    required super.child,
  });

  /// Whether the pointer or keyboard focus is on the enclosing card.
  final bool revealed;

  /// The nearest card's reveal, or false outside one.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpaceMenuReveal>()?.revealed ??
      false;

  @override
  bool updateShouldNotify(SpaceMenuReveal oldWidget) =>
      revealed != oldWidget.revealed;
}
