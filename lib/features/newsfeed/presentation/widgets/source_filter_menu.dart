import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact multi-select dropdown for filtering articles by source feed.
///
/// Selection is bidirectionally bound to [provider] (an unmodifiable set of
/// feed IDs). An empty selection means "all sources". The field collapses to a
/// single summary line (source name, or a count) instead of rendering tags.
class SourceFilterMenu extends ConsumerWidget {
  /// Creates a new [SourceFilterMenu].
  const SourceFilterMenu({super.key, required this.provider});

  /// The notifier provider holding the selected feed ID set.
  final NotifierProvider<SelectedFeedIdsController, Set<String>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(feedsProvider);
    final selected = ref.watch(provider);
    final l10n = AppLocalizations.of(context);
    final feeds =
        (feedsAsync.value ?? const <RssFeed>[]).where((f) => f.enabled).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (feeds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Map<label, id>
    final items = <String, String>{for (final f in feeds) f.name: f.id};
    final byId = {for (final f in feeds) f.id: f};

    // Drop any selected ids that no longer correspond to an enabled feed.
    final knownIds = feeds.map((f) => f.id).toSet();
    final effectiveSelected = selected.intersection(knownIds);

    return Semantics(
      label: l10n.filterBySource,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240, minWidth: 180),
        child: CcMultiSelect<String>(
          hintText: l10n.allSources,
          options: [
            for (final entry in items.entries)
              CcSelectOption(value: entry.value, label: entry.key),
          ],
          values: effectiveSelected,
          countLabel: (count) => count == 1
              ? (byId[effectiveSelected.first]?.name ?? l10n.sourceCount(1))
              : l10n.sourceCountPlural(count),
          onChanged: (values) =>
              ref.read(provider.notifier).replaceAll(values),
        ),
      ),
    );
  }
}
