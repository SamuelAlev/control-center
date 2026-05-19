import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/newsfeed/providers/site_allowlist_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Newsfeed settings screen.
class NewsfeedSettingsScreen extends ConsumerWidget {
  /// Creates a new [NewsfeedSettingsScreen].
  const NewsfeedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(feedsProvider);
    final openMode = ref.watch(articleOpenModeProvider);
    final blockContent = ref.watch(contentBlockingProvider);
    final refreshing = ref.watch(newsfeedRefreshControllerProvider);
    final filterState = ref.watch(filterListUpdateProvider);
    final l10n = AppLocalizations.of(context);

    return PageWrapper(
      title: l10n.newsfeedSettingsTitle,
      subtitle: l10n.newsfeedSettingsDescription,
      actions: [
        FButton(
          onPress: () => _showAddFeedDialog(context, ref),
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(LucideIcons.plus, size: 16),
          child: Text(l10n.addFeed),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          SectionCard(
            label: l10n.readerPreferences,
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
            headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(
              children: [
                _PreferenceTile(
                  icon: LucideIcons.appWindow,
                  title: l10n.openArticlesInApp,
                  subtitle: l10n.openArticlesInAppDescription,
                  trailing: FSwitch(
                    value: openMode == ArticleOpenMode.inApp,
                    onChange: (v) => ref
                        .read(articleOpenModeProvider.notifier)
                        .set(
                          v
                              ? ArticleOpenMode.inApp
                              : ArticleOpenMode.externalBrowser,
                        ),
                  ),
                ),
                const FDivider(),
                _PreferenceTile(
                  icon: LucideIcons.shield,
                  title: l10n.blockAdsTrackers,
                  subtitle: l10n.blockAdsTrackersDescription,
                  trailing: FSwitch(
                    value: blockContent,
                    onChange: (v) => ref
                        .read(contentBlockingProvider.notifier)
                        .set(enabled: v),
                  ),
                ),
              ],
            ),
          ),
          if (blockContent) ...[
            const SizedBox(height: 16),
            _FilterListStatus(state: filterState),
            const SizedBox(height: 16),
            const _TrustedSitesSection(),
          ],
          const SizedBox(height: 16),
          feedsAsync.when(
            data: (feeds) =>
                _FeedsSection(feeds: feeds, refreshing: refreshing),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: FCircularProgress()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.failedToLoadFeeds('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          tokens?.textTertiary ??
                          theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _FeedsSection extends ConsumerWidget {
  const _FeedsSection({required this.feeds, required this.refreshing});
  final List<RssFeed> feeds;
  final bool refreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fColors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.feedsCount(feeds.length),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: FButton(
        variant: FButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        onPress: refreshing
            ? null
            : () => ref
                  .read(newsfeedRefreshControllerProvider.notifier)
                  .refreshAll(),
        prefix: refreshing
            ? const SizedBox(width: 14, height: 14, child: FCircularProgress())
            : const Icon(LucideIcons.refreshCw, size: 14),
        child: Text(l10n.refreshAll),
      ),
      child: feeds.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.noFeedsYet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens?.textTertiary ?? fColors.mutedForeground,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feeds.length,
              separatorBuilder: (_, _) => const FDivider(),
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
    final fColors = FTheme.of(context).colors;
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens?.textPrimary ?? fColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
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
            FSwitch(
              value: feed.enabled,
              onChange: (v) => ref
                  .read(newsfeedRepositoryProvider)
                  .setFeedEnabled(feed.id, enabled: v),
            ),
            const SizedBox(width: 8),
            FTooltip(
              tipBuilder: (_, _) => Text(l10n.refresh),
              child: FButton.icon(
                variant: FButtonVariant.ghost,
                onPress: () => ref
                    .read(newsfeedRefreshControllerProvider.notifier)
                    .refreshFeed(feed.id),
                child: const Icon(LucideIcons.refreshCw, size: 16),
              ),
            ),
            const SizedBox(width: 4),
            FTooltip(
              tipBuilder: (_, _) => Text(l10n.delete),
              child: FButton.icon(
                variant: FButtonVariant.ghost,
                onPress: () => _confirmDelete(context, ref),
                child: const Icon(LucideIcons.trash2, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteFeedConfirm(feed.name)),
        body: Text(l10n.deleteFeedBody),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(dialogContext, false),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(dialogContext, true),
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.delete),
                ),
              ],
            ),
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
    final fColors = FTheme.of(context).colors;
    final dotColor = feed.hasError
        ? (tokens?.fgWarningPrimary ?? Colors.amber)
        : feed.enabled
        ? (tokens?.fgSuccessPrimary ?? Colors.green)
        : (tokens?.fgDisabled ?? fColors.mutedForeground);
    final ringColor = tokens?.bgPrimary ?? fColors.card;
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

class _FilterListStatus extends ConsumerWidget {
  const _FilterListStatus({required this.state});

  final FilterListUpdateState state;

  String _lastUpdatedLabel(AppLocalizations l10n) {
    if (state.lastSuccess == null) {
      return l10n.bundledDefaultsNeverUpdated;
    }
    final ago = DateTime.now().difference(state.lastSuccess!);
    if (ago.inDays > 0) {
      return l10n.updatedDaysAgo(ago.inDays);
    } else if (ago.inHours > 0) {
      return l10n.updatedHoursAgo(ago.inHours);
    } else if (ago.inMinutes > 0) {
      return l10n.updatedMinutesAgo(ago.inMinutes);
    }
    return l10n.updatedJustNow;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fColors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final isUpdating = state.isUpdating;
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.filterLists,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _lastUpdatedLabel(l10n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens?.textTertiary ?? fColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          FButton(
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            onPress: isUpdating
                ? null
                : () => ref.read(filterListUpdateProvider.notifier).refresh(),
            prefix: isUpdating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: FCircularProgress(),
                  )
                : const Icon(LucideIcons.refreshCw, size: 14),
            child: Text(l10n.checkForUpdates),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _CountChip(
                  icon: LucideIcons.cookie,
                  label: l10n.cookieRulesCount(state.cookieHidingRules),
                ),
                _CountChip(
                  icon: LucideIcons.shield,
                  label: l10n.adRulesCount(state.adHidingRules),
                ),
                _CountChip(
                  icon: LucideIcons.globe,
                  label: l10n.networkBlockCount(state.networkBlockRules),
                ),
                _CountChip(
                  icon: LucideIcons.link,
                  label: l10n.trackingParamsCount(state.removeParamsCount),
                ),
              ],
            ),
          ),
          if (state.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final error in state.errors)
                    Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fColors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens?.bgSecondary ?? fColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  tokens?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
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

Future<void> _showAddFeedDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final existingFeeds = await ref.read(feedsProvider.future);
  if (!context.mounted) {
    return;
  }
  final result = await showFDialog<_AddFeedResult?>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.addFeed),
      body: SizedBox(
        width: 420,
        child: _AddFeedForm(
          existingFeeds: existingFeeds,
          onSubmit: (r) => Navigator.pop(dialogContext, r),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.feedAlreadyExists)));
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
        FTextField(
          autofocus: true,
          label: Text(l10n.nameLabel),
          hint: l10n.egTheVerge,
          control: FTextFieldControl.managed(controller: _nameCtrl),
        ),
        const SizedBox(height: 12),
        FTextField(
          label: Text(l10n.feedUrlLabel),
          hint: l10n.feedUrlExample,
          control: FTextFieldControl.managed(controller: _urlCtrl),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showAdvanced
                    ? LucideIcons.chevronDown
                    : LucideIcons.chevronRight,
                size: 16,
                color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.advancedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
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
          FTextField(
            label: Text(l10n.userAgent),
            hint: l10n.mozillaUserAgent,
            description: Text(l10n.userAgentDescription),
            control: FTextFieldControl.managed(controller: _uaCtrl),
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
            FButton(
              onPress: _submitting ? null : widget.onCancel,
              variant: FButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            FButton(
              onPress: _submitting ? null : _submit,
              mainAxisSize: MainAxisSize.min,
              child: Text(_submitting ? l10n.addingEllipsis : l10n.addFeed),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustedSitesSection extends ConsumerWidget {
  const _TrustedSitesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final fColors = FTheme.of(context).colors;
    final l10n = AppLocalizations.of(context);
    final allowedAsync = ref.watch(siteAllowlistProvider);

    return SectionCard(
      label: l10n.trustedSitesSectionTitle,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: FButton(
        variant: FButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        onPress: () => _showAddTrustedSiteDialog(context, ref),
        prefix: const Icon(LucideIcons.plus, size: 14),
        child: Text(l10n.addTrustedSite),
      ),
      child: allowedAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: FCircularProgress()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$e',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        data: (domains) {
          final sorted = domains.toList()..sort();
          if (sorted.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.trustedSitesEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens?.textTertiary ?? fColors.mutedForeground,
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const FDivider(),
            itemBuilder: (_, i) => _TrustedSiteRow(domain: sorted[i]),
          );
        },
      ),
    );
  }
}

class _TrustedSiteRow extends ConsumerWidget {
  const _TrustedSiteRow({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final fColors = FTheme.of(context).colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            LucideIcons.shieldOff,
            size: 18,
            color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              domain,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens?.textPrimary ?? fColors.foreground,
              ),
            ),
          ),
          FTooltip(
            tipBuilder: (_, _) => Text(l10n.removeTrustedSite),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: () =>
                  ref.read(siteAllowlistRepositoryProvider).remove(domain),
              child: const Icon(LucideIcons.trash2, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddTrustedSiteDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  String? error;
  await showFDialog<String?>(
    context: context,
    builder: (dialogContext, style, animation) {
      return StatefulBuilder(
        builder: (sbContext, setState) {
          Future<void> submit() async {
            final raw = controller.text.trim();
            if (raw.isEmpty) {
              setState(() => error = l10n.invalidDomain);
              return;
            }
            final repo = ref.read(siteAllowlistRepositoryProvider);
            final normalised = repo.normalizeDomain(raw);
            if (normalised.isEmpty) {
              setState(() => error = l10n.invalidDomain);
              return;
            }
            await repo.add(normalised);
            if (sbContext.mounted) {
              Navigator.pop(dialogContext, normalised);
            }
          }

          return FDialog(
            style: style,
            animation: animation,
            title: Text(l10n.addTrustedSite),
            body: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  FTextField(
                    autofocus: true,
                    label: Text(l10n.trustedSitesSectionTitle),
                    hint: l10n.enterDomainHint,
                    control: FTextFieldControl.managed(controller: controller),
                    onSubmit: (_) => submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(sbContext).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FButton(
                        onPress: () => Navigator.pop(dialogContext),
                        variant: FButtonVariant.ghost,
                        mainAxisSize: MainAxisSize.min,
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      FButton(
                        onPress: submit,
                        mainAxisSize: MainAxisSize.min,
                        child: Text(l10n.addTrustedSite),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: const [],
          );
        },
      );
    },
  );
}
