part of 'space_row_adornments.dart';

/// The leading icon for a space row: a spinner while an agent is running,
/// otherwise the aggregate PR-status badge (with a count of open PRs) when the
/// space is linked to a PR or one of its worktree branches has an open PR.
/// With neither, it shows [absent], or a pencil glyph when [absent] is null.
/// Association state hydrates from cache; a PR opened outside the app arrives
/// with the branch match. The row renders immediately and never blocks on
/// either.
class SpaceLeadingIcon extends ConsumerWidget {
  /// Creates the leading icon.
  const SpaceLeadingIcon({
    super.key,
    required this.spaceId,
    required this.running,
    required this.selected,
    this.absent,
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

  /// Mark shown when the space has no pull request. Null keeps the pencil.
  final Widget? absent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (running) {
      return CcSpinner(size: 18, color: selected ? t.accentOn : null);
    }
    final (:status, :openCount) = ref.watch(_spacePrBadgeProvider(spaceId));
    if (status == null) {
      // Nothing open and nothing linked — a fresh conversation.
      return absent ?? const Icon(AppIcons.pencil, size: 18);
    }
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

/// What a space row's PR badge shows: the aggregate status (null for none)
/// and how many of the PRs are open.
///
/// A record, compared by value: the linked-PR list is rebuilt on every
/// association or PR refresh, and the branch matches on every poller sweep,
/// yet the badge rarely changes — so the row repaints only when it does.
final _spacePrBadgeProvider = Provider.autoDispose
    .family<({PrSidebarStatus? status, int openCount}), String>((ref, spaceId) {
      final prs = pullRequestsForSpaceRow(
        linked: ref.watch(spacePrsProvider(spaceId)),
        branchMatched:
            ref
                .watch(spaceBranchPullRequestsProvider(spaceId))
                .value
                ?.map((match) => match.pr) ??
            const <PullRequest>[],
      );
      return (
        status: PrSidebarStatus.aggregate(prs),
        openCount: prs.where((pr) => pr.isOpen).length,
      );
    });

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
        PositionedDirectional(
          top: -6,
          end: -8,
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
