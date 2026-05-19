import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Newsfeed: the signed-in user's feed registry — enable,
/// refresh, remove and add feeds. The list is per-user; another user's feeds
/// are never visible here.
class NewsfeedFeedsSection extends ConsumerWidget {
  /// Creates a [NewsfeedFeedsSection].
  const NewsfeedFeedsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feedsAsync = ref.watch(feedsProvider);
    final refreshing = ref.watch(newsfeedRefreshControllerProvider);

    return feedsAsync.when(
      data: (feeds) => _FeedsCard(feeds: feeds, refreshing: refreshing),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CcSpinner()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.failedToLoadFeeds('$e')),
      ),
    );
  }
}

class _FeedsCard extends ConsumerWidget {
  const _FeedsCard({required this.feeds, required this.refreshing});

  final List<RssFeed> feeds;
  final bool refreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.feedsCount(feeds.length),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        loading: refreshing,
        icon: AppIcons.refreshCw,
        onPressed: refreshing
            ? null
            : () => ref
                  .read(newsfeedRefreshControllerProvider.notifier)
                  .refreshAll(),
        child: Text(l10n.refreshAll),
      ),
      child: feeds.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.noFeedsYet,
                style: CcTypography.caption.copyWith(
                  color:
                      tokens?.textTertiary ??
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feeds.length,
              separatorBuilder: (_, _) => const CcDivider(),
              itemBuilder: (_, i) => _FeedRow(feed: feeds[i]),
            ),
    );
  }
}

class _FeedRow extends ConsumerWidget {
  const _FeedRow({required this.feed});

  final RssFeed feed;

  String _subtitle(AppLocalizations l10n) {
    if (feed.hasError) {
      return feed.lastError!;
    }
    final fetched = _relativeUpdatedLabel(l10n, feed.lastFetchedAt);
    if (feed.description.isNotEmpty) {
      return fetched == null
          ? feed.description
          : '${feed.description}  ·  $fetched';
    }
    return fetched ?? feed.url;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final dimmed = !feed.enabled && !feed.hasError;
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            _FaviconBadge(feed: feed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feed.name,
                    style: CcTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens?.textPrimary ?? colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(l10n),
                    style: CcTypography.caption.copyWith(
                      color: feed.hasError
                          ? (tokens?.textWarningPrimary ??
                                Colors.amber.shade800)
                          : (tokens?.textTertiary ?? colors.onSurfaceVariant),
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            CcSwitch(
              value: feed.enabled,
              onChanged: (v) => ref
                  .read(newsfeedRepositoryProvider)
                  .setFeedEnabled(feed.id, enabled: v),
            ),
            const SizedBox(width: 8),
            CcTooltip(
              message: l10n.refresh,
              child: CcIconButton(
                icon: AppIcons.refreshCw,
                semanticLabel: l10n.refresh,
                onPressed: () => ref
                    .read(newsfeedRefreshControllerProvider.notifier)
                    .refreshFeed(feed.id),
              ),
            ),
            const SizedBox(width: 4),
            CcTooltip(
              message: l10n.delete,
              child: CcIconButton(
                icon: AppIcons.trash2,
                semanticLabel: l10n.delete,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deleteFeedConfirm(feed.name),
        content: Text(l10n.deleteFeedBody),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(newsfeedRepositoryProvider).deleteFeed(feed.id);
    }
  }
}

/// Favicon with a small status dot overlay (error / disabled / active).
class _FaviconBadge extends StatelessWidget {
  const _FaviconBadge({required this.feed});

  final RssFeed feed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = Theme.of(context).colorScheme;
    final dotColor = feed.hasError
        ? (tokens?.fgWarningPrimary ?? Colors.amber)
        : feed.enabled
        ? (tokens?.fgSuccessPrimary ?? Colors.green)
        : (tokens?.fgDisabled ?? colors.onSurfaceVariant);
    final ringColor = tokens?.bgPrimary ?? colors.surface;
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: FeedFavicon(feed: feed, size: 28)),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a feed's last-fetched timestamp as a relative "Updated …" label,
/// or null when it has never been fetched.
String? _relativeUpdatedLabel(AppLocalizations l10n, DateTime? when) {
  if (when == null) {
    return null;
  }
  final ago = DateTime.now().difference(when);
  if (ago.inDays > 0) {
    return l10n.updatedDaysAgo(ago.inDays);
  } else if (ago.inHours > 0) {
    return l10n.updatedHoursAgo(ago.inHours);
  } else if (ago.inMinutes > 0) {
    return l10n.updatedMinutesAgo(ago.inMinutes);
  }
  return l10n.updatedJustNow;
}

/// Opens the add-feed dialog and, on submit, registers the feed host-side and
/// fetches it once so the list shows content immediately.
Future<void> showAddFeedDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final existingFeeds = await ref.read(feedsProvider.future);
  if (!context.mounted) {
    return;
  }
  final result = await showCcDialog<_AddFeedResult?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addFeed,
      content: SizedBox(
        width: 420,
        child: _AddFeedForm(
          existingFeeds: existingFeeds,
          onSubmit: (r) => Navigator.pop(dialogContext, r),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
    ),
  );

  if (result == null) {
    return;
  }

  final repo = ref.read(newsfeedRepositoryProvider);
  final feed = await repo.addFeed(
    name: result.name,
    url: result.url,
    userAgent: result.userAgent,
  );
  await repo.refreshFeed(feed.id);
}

/// Result payload from the add-feed dialog.
class _AddFeedResult {
  const _AddFeedResult({
    required this.name,
    required this.url,
    required this.userAgent,
  });

  final String name;
  final String url;
  final String userAgent;
}

class _AddFeedForm extends ConsumerStatefulWidget {
  const _AddFeedForm({
    required this.existingFeeds,
    required this.onSubmit,
    required this.onCancel,
  });

  final List<RssFeed> existingFeeds;
  final void Function(_AddFeedResult result) onSubmit;
  final VoidCallback onCancel;

  @override
  ConsumerState<_AddFeedForm> createState() => _AddFeedFormState();
}

class _AddFeedFormState extends ConsumerState<_AddFeedForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _uaCtrl;
  bool _showAdvanced = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _urlCtrl = TextEditingController();
    _uaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _uaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final l10n = AppLocalizations.of(context);
    final url = _urlCtrl.text.trim();
    final userAgent = _uaCtrl.text.trim();

    if (name.isEmpty || url.isEmpty) {
      setState(() => _error = l10n.nameAndUrlRequired);
      return;
    }

    final normalizedUrl = url.toLowerCase();
    final alreadyExists = widget.existingFeeds.any(
      (f) => f.url.toLowerCase() == normalizedUrl,
    );
    if (alreadyExists) {
      if (mounted) {
        CcToastScope.of(context).show(l10n.feedAlreadyExists);
      }
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    widget.onSubmit(_AddFeedResult(name: name, url: url, userAgent: userAgent));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.nameLabel),
            const SizedBox(height: 6),
            CcTextField(
              autofocus: true,
              hintText: l10n.egTheVerge,
              controller: _nameCtrl,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.feedUrlLabel),
            const SizedBox(height: 6),
            CcTextField(hintText: l10n.feedUrlExample, controller: _urlCtrl),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showAdvanced ? AppIcons.chevronDown : AppIcons.chevronRight,
                size: 16,
                color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.advancedLabel,
                style: CcTypography.caption.copyWith(
                  color:
                      tokens?.textTertiary ??
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userAgent),
              const SizedBox(height: 6),
              CcTextField(hintText: l10n.mozillaUserAgent, controller: _uaCtrl),
              const SizedBox(height: 6),
              Text(
                l10n.userAgentDescription,
                style: CcTypography.caption.copyWith(
                  color:
                      tokens?.textTertiary ??
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CcButton(
              onPressed: _submitting ? null : widget.onCancel,
              variant: CcButtonVariant.ghost,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            CcButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? l10n.addingEllipsis : l10n.addFeed),
            ),
          ],
        ),
      ],
    );
  }
}
