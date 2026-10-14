part of 'space_row_adornments.dart';

/// The leading icon for a space row: a spinner while an agent is running,
/// otherwise the aggregate PR-status glyph. Its numeric badge counts unread
/// conversations, never pull requests. With neither, it shows [absent], or a
/// pencil glyph when [absent] is null.
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
    this.unreadConversationCount = 0,
  });

  /// The space whose PRs the badge aggregates.
  final String spaceId;

  /// Whether an agent is currently running in the space.
  final bool running;

  /// Distinct conversations with unseen agent messages.
  final int unreadConversationCount;

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
    Widget mark;
    if (running) {
      mark = CcSpinner(size: 18, color: selected ? t.accentOn : null);
    } else {
      final status = ref.watch(_spacePrBadgeProvider(spaceId));
      mark = status == null
          ? absent ?? const Icon(AppIcons.pencil, size: 18)
          : PrStatusBadge(status: status, color: selected ? t.accentOn : null);
      if (status == PrSidebarStatus.merged) {
        final label = AppLocalizations.of(context).spaceAllPrsMergedLabel;
        mark = CcTooltip(
          message: label,
          child: Semantics(label: label, child: mark),
        );
      }
    }
    if (unreadConversationCount == 0) {
      return mark;
    }
    return _UnreadConversationAdornment(
      count: unreadConversationCount,
      selected: selected,
      child: mark,
    );
  }
}

/// The aggregate PR status (null for none), without a numeric PR inventory.
/// Compared by value: the linked-PR list is rebuilt on every
/// association or PR refresh, and the branch matches on every poller sweep,
/// yet the badge rarely changes — so the row repaints only when it does.
final _spacePrBadgeProvider = Provider.autoDispose
    .family<PrSidebarStatus?, String>((ref, spaceId) {
      final prs = ref.watch(spacePullRequestsProvider(spaceId));
      final allMerged = ref.watch(spaceAllPrsMergedProvider(spaceId));
      final status = PrSidebarStatus.aggregate(prs);
      return status == PrSidebarStatus.merged && !allMerged ? null : status;
    });

/// Overlays the unread-conversation count on a space's status glyph.
class _UnreadConversationAdornment extends StatelessWidget {
  const _UnreadConversationAdornment({
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
    final l10n = AppLocalizations.of(context);
    final label = '${l10n.filterUnread}: ${l10n.conversationCount(count)}';
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(count);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: -6,
          end: -8,
          child: CcTooltip(
            message: label,
            child: Semantics(
              label: label,
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 14),
                decoration: BoxDecoration(
                  color: selected ? t.accentOn : t.accent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  textAlign: TextAlign.center,
                  style: CcFonts.code(textStyle: CcTypography.monoNum).copyWith(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: selected ? t.bgBrandSolid : t.accentOn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
