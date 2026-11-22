/// The leading, trailing and count adornments a space sidebar row is built
/// from. Split out of `space_sidebar_item.dart` so that file stays inside the
/// presentation size budget. `SpaceRow` composes them.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

part 'space_row_leading_icon.dart';
part 'space_row_overflow_menu.dart';

/// Side of the overflow trigger and the conversations caret.
const double kSpaceSidebarTrailingControl = 22;

/// The spinner a running space or conversation hangs in front of its title,
/// small enough to sit in the row's start inset.
const double kSpaceRowSignalSize = 8;

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

/// The one leading signal a space or conversation row carries besides the
/// running spinner: unseen agent messages, or a question waiting on the user.
/// Rows with neither lead with nothing.
class AttentionDot extends StatelessWidget {
  /// Creates an [AttentionDot].
  const AttentionDot({super.key, required this.selected});

  /// On the selected row's solid brand fill the accent would vanish (it is
  /// the fill's hue), so the dot takes the fill's foreground.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: selected ? t.accentOn : t.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}
