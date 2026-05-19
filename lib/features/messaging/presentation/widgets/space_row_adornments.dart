/// The leading, trailing and count adornments a space sidebar row is built
/// from.
///
/// Split out of `space_sidebar_item.dart` so that file stays inside the
/// presentation size budget. These are pure presentation with no knowledge of
/// navigation, the archive menu or the rename dialog — `SpaceRow` composes
/// them.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// The leading icon for a space row: a spinner while an agent is running,
/// otherwise the aggregate PR-status badge (with a count of open PRs) when the
/// conversation is linked to one or more PRs and a pencil glyph as the default
/// for a space with no PR yet. The PR state hydrates from cache after the
/// first paint, so the row renders instantly and never blocks.
class SpaceLeadingIcon extends ConsumerWidget {
  /// Creates the leading icon.
  const SpaceLeadingIcon({
    super.key,
    required this.spaceId,
    required this.running,
    required this.selected,
  });

  /// The space whose PRs the badge aggregates.
  final String spaceId;

  /// Whether an agent is currently running in the space.
  final bool running;

  /// On the selected row's solid brand fill the default accent spinner and
  /// the accent count adornment would vanish into the fill, so both switch to
  /// `accentOn` — and the status-colored PR glyph with them (a gray/green
  /// glyph on the burnt fill fails the 3:1 non-text floor).
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (running) {
      return CcSpinner(size: 18, color: selected ? t.accentOn : null);
    }
    final prs = ref.watch(spacePrsProvider(spaceId));
    final status = PrSidebarStatus.aggregate(prs);
    if (status == null) {
      // No PR linked yet — a fresh conversation in the editing stage.
      return const Icon(AppIcons.pencil, size: 18);
    }
    final openCount = prs.where((pr) => pr.isOpen).length;
    final badge = PrStatusBadge(
      status: status,
      color: selected ? t.accentOn : null,
    );
    if (openCount < 1) {
      return badge;
    }
    // The badge already conveys the (aggregate) state; the count tells the user
    // how many PRs are open across the space's repo(s).
    return _PrCountAdornment(
      count: openCount,
      selected: selected,
      child: badge,
    );
  }
}

/// Overlays a small numeric badge on the top-right of [child] — the count of a
/// space's open PRs. A number (not colour) is the differentiator, per
/// DESIGN.md's never-status-by-colour-alone rule.
class _PrCountAdornment extends StatelessWidget {
  const _PrCountAdornment({
    required this.count,
    required this.selected,
    required this.child,
  });

  final int count;

  /// On the selected row's solid brand fill the accent pill would disappear,
  /// so it inverts: `accentOn` pill, `bgBrandSolid` digits (the fill's own
  /// hue, 4.5:1+ on white in both brightnesses).
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 14),
            decoration: BoxDecoration(
              color: selected ? t.accentOn : t.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w600,
                color: selected ? t.bgBrandSolid : t.accentOn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
