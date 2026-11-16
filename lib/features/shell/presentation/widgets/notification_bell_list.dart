part of 'notification_bell.dart';

/// How close to the end of the list (in logical pixels) the next page starts
/// loading, so it usually arrives before the reader hits the bottom.
const double _loadAheadExtent = 240;

/// The bell's scrolling history: rows are built lazily, and the feed window
/// grows a page at a time as the list nears its end.
class _NotificationList extends ConsumerStatefulWidget {
  const _NotificationList({
    required this.entries,
    required this.tokens,
    required this.onNavigate,
  });

  final List<NotificationEntry> entries;
  final DesignSystemTokens tokens;
  final ValueChanged<String> onNavigate;

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scroll.hasClients) {
      return;
    }
    if (_scroll.position.extentAfter > _loadAheadExtent ||
        !ref.read(notificationFeedHasMoreProvider) ||
        ref.read(notificationFeedLoadingMoreProvider)) {
      return;
    }
    // The action refuses the same cases again, so a scroll tick racing a
    // provider update cannot stack requests either.
    ref.read(notificationCenterActionsProvider).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasMore = ref.watch(notificationFeedHasMoreProvider);
    final loadingMore = ref.watch(notificationFeedLoadingMoreProvider);
    if (hasMore && !loadingMore) {
      // A window whose rows were mostly filtered out (muted repositories,
      // switched-off categories, cleared rows) may not fill the viewport, and
      // a list that cannot scroll never reports a scroll: check after layout
      // too.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    }
    final entries = widget.entries;

    return CcScrollbar(
      controller: _scroll,
      child: ListView.builder(
        controller: _scroll,
        // Sized to its rows up to the popover's height cap, so a short history
        // keeps the panel short.
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        itemCount: entries.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: CcSpinner(size: 16, semanticLabel: l10n.loadingEllipsis),
              ),
            );
          }
          final entry = entries[index];
          return _EntryTile(
            key: ValueKey(entry.id),
            entry: entry,
            tokens: widget.tokens,
            onNavigate: widget.onNavigate,
          );
        },
      ),
    );
  }
}
