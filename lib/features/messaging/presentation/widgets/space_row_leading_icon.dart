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

  /// Single-status glyphs and activity adornments invert on the selected
  /// row. Mixed-status glyphs retain their colors on a neutral backing.
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
      final statusMask = ref.watch(_spacePrBadgeProvider(spaceId));
      mark = statusMask == 0
          ? absent ?? const Icon(AppIcons.pencil, size: 18)
          : PrStatusBadge(
              statusMask: statusMask,
              selected: selected,
              semanticLabel: statusMask == PrSidebarStatus.merged.mask
                  ? AppLocalizations.of(context).spaceAllPrsMergedLabel
                  : null,
            );
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

/// A value-compared mask of distinct PR states (zero for none).
/// Compared by value: the linked-PR list is rebuilt on every
/// association or PR refresh, and the branch matches on every poller sweep,
/// yet the badge rarely changes — so the row repaints only when it does.
final _spacePrBadgeProvider = Provider.autoDispose.family<int, String>((
  ref,
  spaceId,
) {
  final prs = ref.watch(spacePullRequestsProvider(spaceId));
  final statusMask = PrSidebarStatus.aggregate(prs);
  if (statusMask == PrSidebarStatus.merged.mask &&
      !ref.watch(spaceAllPrsMergedProvider(spaceId))) {
    return 0;
  }
  return statusMask;
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
