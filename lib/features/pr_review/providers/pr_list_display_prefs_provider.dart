import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the PR queue groups its rows into sections.
enum PrListGrouping {
  /// One collapsible section per repository (the default).
  repository,

  /// One section per PR author, the operator's own PRs first.
  author,

  /// One section per status bucket (needs review, changes requested, …).
  status,

  /// A single flat list, no section headers.
  none,
}

/// The visual properties a PR row can render. Toggled from the display
/// options popover; the row simply omits a disabled property's chip/segment.
enum PrRowProperty {
  /// The repo full name in the metadata line (also forced on whenever the
  /// queue is not grouped by repository, so repo context never disappears).
  repository,

  /// The `#number` id segment.
  id,

  /// The `base ← head` branch segment.
  branch,

  /// The relative updated-age segment.
  updated,

  /// The author avatar + login chip.
  author,

  /// The rolled-up CI checks pill.
  checks,

  /// The `+adds −dels` diff stat.
  diff,

  /// The conversation count chip.
  comments,
}

/// How far back the inbox's "Merging and recently merged" section reaches.
/// Shared display state: the popover (identical on the PR list and the inbox)
/// edits it everywhere; the inbox classifier is its consumer (the PR queue
/// carries no merged history to narrow).
enum PrMergedWindow {
  /// The past 24 hours.
  day,

  /// The past 7 days.
  week,

  /// The past 30 days.
  month;

  /// The window as a [Duration].
  Duration get duration => switch (this) {
    PrMergedWindow.day => const Duration(days: 1),
    PrMergedWindow.week => const Duration(days: 7),
    PrMergedWindow.month => const Duration(days: 30),
  };
}

/// The persisted display preferences shared by the PR queue and the inbox:
/// grouping, draft visibility, the recently-merged window, and which row
/// properties render. Ordering lives in `prListSortProvider` (session-scoped)
/// and is surfaced by the same popover.
class PrListDisplayPrefs {
  /// Creates a [PrListDisplayPrefs].
  const PrListDisplayPrefs({
    this.grouping = PrListGrouping.repository,
    this.showDrafts = true,
    this.mergedWindow = PrMergedWindow.week,
    this.properties = defaultProperties,
  });

  /// Row properties rendered by default: everything except the repo name,
  /// which the default repository grouping already shows as section headers.
  static const Set<PrRowProperty> defaultProperties = {
    PrRowProperty.id,
    PrRowProperty.branch,
    PrRowProperty.updated,
    PrRowProperty.author,
    PrRowProperty.checks,
    PrRowProperty.diff,
    PrRowProperty.comments,
  };

  /// The active grouping.
  final PrListGrouping grouping;

  /// Whether draft PRs appear in the queue and the inbox (and their counts).
  final bool showDrafts;

  /// The recently-merged window (consumed by the inbox classifier).
  final PrMergedWindow mergedWindow;

  /// The row properties currently rendered.
  final Set<PrRowProperty> properties;

  /// Returns a copy with the given fields replaced.
  PrListDisplayPrefs copyWith({
    PrListGrouping? grouping,
    bool? showDrafts,
    PrMergedWindow? mergedWindow,
    Set<PrRowProperty>? properties,
  }) {
    return PrListDisplayPrefs(
      grouping: grouping ?? this.grouping,
      showDrafts: showDrafts ?? this.showDrafts,
      mergedWindow: mergedWindow ?? this.mergedWindow,
      properties: properties ?? this.properties,
    );
  }
}

/// Reads/writes the queue display preferences through [AppPreferences] so
/// they survive restarts (same pattern as the diff-view prefs).
class PrListDisplayPrefsNotifier extends Notifier<PrListDisplayPrefs> {
  late AppPreferences _prefs;

  @override
  PrListDisplayPrefs build() {
    _prefs = ref.watch(appPreferencesProvider);
    final grouping = PrListGrouping.values
        .asNameMap()[_prefs.getString(prListGroupingKey)];
    final showDrafts = _prefs.getBool(prListShowDraftsKey);
    final mergedWindow = PrMergedWindow.values
        .asNameMap()[_prefs.getString(prListMergedWindowKey)];
    final names = _prefs.getStringList(prListRowPropertiesKey);
    final propertyByName = PrRowProperty.values.asNameMap();
    return PrListDisplayPrefs(
      grouping: grouping ?? PrListGrouping.repository,
      showDrafts: showDrafts ?? true,
      mergedWindow: mergedWindow ?? PrMergedWindow.week,
      properties: names == null
          ? PrListDisplayPrefs.defaultProperties
          : {
              for (final name in names)
                if (propertyByName[name] != null) propertyByName[name]!,
            },
    );
  }

  /// Persists [grouping] and updates the state.
  void setGrouping(PrListGrouping grouping) {
    _prefs.setString(prListGroupingKey, grouping.name);
    state = state.copyWith(grouping: grouping);
  }

  /// Persists draft visibility and updates the state.
  void setShowDrafts({required bool showDrafts}) {
    _prefs.setBool(prListShowDraftsKey, value: showDrafts);
    state = state.copyWith(showDrafts: showDrafts);
  }

  /// Persists the recently-merged window and updates the state.
  void setMergedWindow(PrMergedWindow window) {
    _prefs.setString(prListMergedWindowKey, window.name);
    state = state.copyWith(mergedWindow: window);
  }

  /// Toggles [property] in the rendered set and persists the result.
  void toggleProperty(PrRowProperty property) {
    final next = Set<PrRowProperty>.from(state.properties);
    if (!next.add(property)) {
      next.remove(property);
    }
    _prefs.setStringList(prListRowPropertiesKey, [
      for (final p in next) p.name,
    ]);
    state = state.copyWith(properties: next);
  }
}

/// Provides the persisted PR queue display preferences.
final prListDisplayPrefsProvider =
    NotifierProvider<PrListDisplayPrefsNotifier, PrListDisplayPrefs>(
      PrListDisplayPrefsNotifier.new,
    );
