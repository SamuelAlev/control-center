import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The profile's PR-state rail: four tappable cards — Open, Draft, Merged,
/// Closed — that mirror the queue's lane cards. Each shows the author's true
/// total for that state (from one batched GitHub search via
/// [userPrCountsProvider]), not a count of the loaded rows. Open is on by
/// default; selection is multi-select, so e.g. Open + Merged can be shown
/// together. The rail no longer triggers the row fetch — the queue does that
/// when a Merged/Closed card is active.
class UserProfileStateRail extends ConsumerWidget {
  /// Creates a [UserProfileStateRail] for [login].
  const UserProfileStateRail({super.key, required this.login});

  /// The profile this rail filters.
  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(userProfileStateFilterProvider(login));
    final notifier = ref.read(userProfileStateFilterProvider(login).notifier);

    // All four counts are true totals from one batched GitHub search
    // (`userPrCountsProvider`) — accurate regardless of how many PRs exist,
    // unlike counting the 100/repo-capped row lists. Loaded eagerly but
    // rendered non-blocking: the cards show immediately and the numbers fill in
    // (spinner -> number) when the query resolves.
    final countsAsync = ref.watch(userPrCountsProvider(login));
    final counts = countsAsync.value;
    final countsLoading = countsAsync.isLoading && !countsAsync.hasValue;
    int countFor(ProfilePrState s) => switch (s) {
      ProfilePrState.open => counts?.open ?? 0,
      ProfilePrState.draft => counts?.draft ?? 0,
      ProfilePrState.merged => counts?.merged ?? 0,
      ProfilePrState.closed => counts?.closed ?? 0,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 680
            ? 4
            : width >= 460
            ? 2
            : 1;
        const gap = AppSpacing.md;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        Widget card(_StateCard child) =>
            SizedBox(width: cardWidth, child: child);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in ProfilePrState.values)
              card(
                _StateCard(
                  profileState: s,
                  active: active.contains(s),
                  count: countFor(s),
                  loading: countsLoading,
                  onTap: () => notifier.toggle(s),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Resolved colour + copy for a state card.
({Color color, Color soft, String label, String hint}) _styleFor(
  ProfilePrState profileState,
  DesignSystemTokens tokens,
  AppLocalizations l10n,
) {
  return switch (profileState) {
    ProfilePrState.open => (
      color: tokens.success,
      soft: tokens.successSoft,
      label: l10n.openStatus,
      hint: l10n.profileStateOpenHint,
    ),
    ProfilePrState.draft => (
      color: tokens.idle,
      soft: tokens.idle.withValues(alpha: 0.12),
      label: l10n.draft,
      hint: l10n.laneDraftsHint,
    ),
    ProfilePrState.merged => (
      color: tokens.fgBrandPrimary,
      soft: tokens.fgBrandPrimary.withValues(alpha: 0.12),
      label: l10n.merged,
      hint: l10n.profileStateMergedHint,
    ),
    ProfilePrState.closed => (
      color: tokens.danger,
      soft: tokens.dangerSoft,
      label: l10n.closed,
      hint: l10n.profileStateClosedHint,
    ),
  };
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.profileState,
    required this.active,
    required this.count,
    required this.onTap,
    this.loading = false,
  });

  final ProfilePrState profileState;
  final bool active;
  final int count;

  /// Whether the (shared) counts query is still resolving — a spinner stands in
  /// for the number until it does.
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = _styleFor(profileState, tokens, l10n);
    final theme = Theme.of(context);

    final border = active ? tokens.lineStrong : tokens.borderSecondary;

    // While the counts query resolves a spinner replaces the number; '…' keeps
    // the accessibility label sensible for that transient state.
    final countLabel = loading ? '…' : '$count';

    return Semantics(
      button: true,
      selected: active,
      label: '${style.label}: $countLabel. ${style.hint}',
      child: CcTappable(
        onPressed: onTap,
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final shadow = active || hovered ? AppShadows.soft : null;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active ? style.soft : tokens.panel,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: border),
              boxShadow: shadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _StateDot(color: style.color),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          style.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CountArea(
                    loading: loading,
                    count: count,
                    color: style.color,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The card's count slot: a big tabular number, or a spinner while the shared
/// counts query is still resolving.
class _CountArea extends StatelessWidget {
  const _CountArea({
    required this.loading,
    required this.count,
    required this.color,
  });

  final bool loading;
  final int count;
  final Color color;

  /// Fixed slot height so every card is the same height whether its count slot
  /// holds a number or a spinner.
  static const double _slotHeight = 30;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);

    final Widget inner;
    if (loading) {
      inner = const SizedBox(width: 18, height: 18, child: CcSpinner());
    } else {
      inner = Text(
        '$count',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: count == 0 ? tokens.idle : tokens.textPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1,
        ),
      );
    }

    return SizedBox(
      height: _slotHeight,
      child: Align(alignment: Alignment.centerLeft, child: inner),
    );
  }
}

class _StateDot extends StatelessWidget {
  const _StateDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
