import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(AppPreferences prefs) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('prListDisplayPrefsProvider', () {
    test('defaults: repository grouping, drafts on, repo property off', () {
      final container = _container(AppPreferences.inMemory());
      final prefs = container.read(prListDisplayPrefsProvider);
      expect(prefs.grouping, PrListGrouping.repository);
      expect(prefs.showDrafts, isTrue);
      expect(prefs.properties, PrListDisplayPrefs.defaultProperties);
      expect(prefs.properties.contains(PrRowProperty.repository), isFalse);
    });

    test('setGrouping persists across containers', () {
      final store = AppPreferences.inMemory();
      final container = _container(store);

      container
          .read(prListDisplayPrefsProvider.notifier)
          .setGrouping(PrListGrouping.author);

      expect(
        container.read(prListDisplayPrefsProvider).grouping,
        PrListGrouping.author,
      );
      expect(store.getString(prListGroupingKey), 'author');

      final next = _container(store);
      expect(
        next.read(prListDisplayPrefsProvider).grouping,
        PrListGrouping.author,
      );
    });

    test('mergedWindow defaults to a week and persists', () {
      final store = AppPreferences.inMemory();
      final container = _container(store);
      expect(
        container.read(prListDisplayPrefsProvider).mergedWindow,
        PrMergedWindow.week,
      );

      container
          .read(prListDisplayPrefsProvider.notifier)
          .setMergedWindow(PrMergedWindow.month);

      expect(
        container.read(prListDisplayPrefsProvider).mergedWindow,
        PrMergedWindow.month,
      );
      expect(store.getString(prListMergedWindowKey), 'month');
      expect(
        _container(store).read(prListDisplayPrefsProvider).mergedWindow,
        PrMergedWindow.month,
      );
    });

    test('setShowDrafts persists', () {
      final store = AppPreferences.inMemory();
      final container = _container(store);

      container
          .read(prListDisplayPrefsProvider.notifier)
          .setShowDrafts(showDrafts: false);

      expect(container.read(prListDisplayPrefsProvider).showDrafts, isFalse);
      expect(
        _container(store).read(prListDisplayPrefsProvider).showDrafts,
        isFalse,
      );
    });

    test('toggleProperty adds/removes and persists', () {
      final store = AppPreferences.inMemory();
      final container = _container(store);
      final notifier = container.read(prListDisplayPrefsProvider.notifier);

      notifier.toggleProperty(PrRowProperty.repository);
      expect(
        container
            .read(prListDisplayPrefsProvider)
            .properties
            .contains(PrRowProperty.repository),
        isTrue,
      );

      notifier.toggleProperty(PrRowProperty.comments);
      final reloaded = _container(store).read(prListDisplayPrefsProvider);
      expect(reloaded.properties.contains(PrRowProperty.repository), isTrue);
      expect(reloaded.properties.contains(PrRowProperty.comments), isFalse);
    });

    test('unknown persisted property names are ignored', () {
      final store = AppPreferences.inMemory();
      store.setStringList(prListRowPropertiesKey, ['id', 'no-such-property']);
      final container = _container(store);
      expect(container.read(prListDisplayPrefsProvider).properties, {
        PrRowProperty.id,
      });
    });
  });
}
