import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// The profile's PR-state rail: three tappable cards — Open, Merged, Closed —
/// that replace the old segmented control and mirror the queue's lane cards.
/// Open is on by default and reads from the already-loaded workspace data;
/// Merged and Closed are opt-in and fetch the user's history on first click.
/// Selection is multi-select, so e.g. Open + Merged can be shown together.
class UserProfileStateRail extends ConsumerWidget {
  /// Creates a [UserProfileStateRail] for [login].
  const UserProfileStateRail({super.key, required this.login});

  /// The profile this rail filters.
  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(userProfileStateFilterProvider(login));
    final notifier = ref.read(userProfileStateFilterProvider(login).notifier);

    // Open + draft come from the already-loaded workspace queue.
    final openGroups = ref.watch(prsByAuthorInWorkspaceProvider(login)).value;
    final openCount = _count(openGroups, ProfilePrState.open);
    final draftCount = _count(openGroups, ProfilePrState.draft);

    // Fetch merged/closed only once either of their cards is active.
    final wantClosed =
        active.contains(ProfilePrState.merged) ||
        active.contains(ProfilePrState.closed);
    final closedAsync = wantClosed
        ? ref.watch(userClosedPrsProvider(login))
        : null;
    final mergedCount = _count(closedAsync?.value, ProfilePrState.merged);
    final closedCount = _count(closedAsync?.value, ProfilePrState.closed);
    final historyLoaded = closedAsync?.hasValue ?? false;
    final historyLoading = closedAsync?.isLoading ?? false;

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
            card(
              _StateCard(
                profileState: ProfilePrState.open,
                active: active.contains(ProfilePrState.open),
                count: openCount,
                loaded: true,
                onTap: () => notifier.toggle(ProfilePrState.open),
              ),
            ),
            card(
              _StateCard(
                profileState: ProfilePrState.draft,
                active: active.contains(ProfilePrState.draft),
                count: draftCount,
                loaded: true,
                onTap: () => notifier.toggle(ProfilePrState.draft),
              ),
            ),
            card(
              _StateCard(
                profileState: ProfilePrState.merged,
                active: active.contains(ProfilePrState.merged),
                count: mergedCount,
                loaded: historyLoaded,
                loading: historyLoading,
                onTap: () => notifier.toggle(ProfilePrState.merged),
              ),
            ),
            card(
              _StateCard(
                profileState: ProfilePrState.closed,
                active: active.contains(ProfilePrState.closed),
                count: closedCount,
                loaded: historyLoaded,
                loading: historyLoading,
                onTap: () => notifier.toggle(ProfilePrState.closed),
              ),
            ),
          ],
        );
      },
    );
  }

  int _count(List<RepoPullRequests>? groups, ProfilePrState target) {
    if (groups == null) {
      return 0;
    }
    var n = 0;
    for (final group in groups) {
      for (final pr in group.prs) {
        if (profilePrStateOf(pr) == target) {
          n++;
        }
      }
    }
    return n;
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

class _StateCard extends StatefulWidget {
  const _StateCard({
    required this.profileState,
    required this.active,
    required this.count,
    required this.loaded,
    required this.onTap,
    this.loading = false,
  });

  final ProfilePrState profileState;
  final bool active;
  final int count;

  /// Whether the count is known (open is always loaded; merged/closed only once
  /// fetched). When false and not [loading], the card invites a click instead
  /// of showing a number.
  final bool loaded;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<_StateCard> {
  bool _hovered = false;

  void _setHovered(bool v) {
    if (_hovered == v) {
      return;
    }
    setState(() => _hovered = v);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = _styleFor(widget.profileState, tokens, l10n);
    final theme = Theme.of(context);

    final border = widget.active ? tokens.lineStrong : tokens.borderSecondary;
    final shadow = widget.active || _hovered ? AppShadows.soft : null;

    final countLabel = widget.loading
        ? l10n.profileClickToLoad // (a spinner replaces the number while loading)
        : widget.loaded
        ? '${widget.count}'
        : l10n.profileClickToLoad;

    return Semantics(
      button: true,
      selected: widget.active,
      label: '${style.label}: $countLabel. ${style.hint}',
      child: FTappable.static(
        onPress: widget.onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.active ? style.soft : tokens.panel,
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
                    loading: widget.loading,
                    loaded: widget.loaded,
                    count: widget.count,
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
          ),
        ),
      ),
    );
  }
}

/// The card's count slot: a big tabular number once known, a spinner while the
/// history loads, or a quiet "click to load" prompt before the first fetch.
class _CountArea extends StatelessWidget {
  const _CountArea({
    required this.loading,
    required this.loaded,
    required this.count,
    required this.color,
  });

  final bool loading;
  final bool loaded;
  final int count;
  final Color color;

  /// Fixed slot height so every card is the same height regardless of whether
  /// its count slot holds a number, a spinner, or the "click to load" prompt.
  static const double _slotHeight = 30;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final colors = context.theme.colors;
    final theme = Theme.of(context);

    final Widget inner;
    if (loading) {
      inner = const SizedBox(width: 18, height: 18, child: FCircularProgress());
    } else if (!loaded) {
      inner = Text(
        AppLocalizations.of(context).profileClickToLoad,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tokens.muted,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      inner = Text(
        '$count',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: count == 0 ? tokens.idle : colors.foreground,
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
