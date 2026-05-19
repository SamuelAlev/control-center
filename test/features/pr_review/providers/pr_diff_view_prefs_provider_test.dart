import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_diff_view_prefs_provider.dart';
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
  group('prTreeVisibleProvider', () {
    test('defaults to visible', () {
      final container = _container(AppPreferences.inMemory());
      expect(container.read(prTreeVisibleProvider), isTrue);
    });

    test('toggle flips the state and persists it', () {
      final prefs = AppPreferences.inMemory();
      final container = _container(prefs);

      container.read(prTreeVisibleProvider.notifier).toggle();

      expect(container.read(prTreeVisibleProvider), isFalse);
      expect(prefs.getBool(prTreeVisibleKey), isFalse);

      // A fresh container (a new session) reads the persisted value back.
      final next = _container(prefs);
      expect(next.read(prTreeVisibleProvider), isFalse);
    });
  });

  group('prDiffSplitViewProvider', () {
    test('defaults to unified', () {
      final container = _container(AppPreferences.inMemory());
      expect(container.read(prDiffSplitViewProvider), isFalse);
    });

    test('setSplit persists across containers', () {
      final prefs = AppPreferences.inMemory();
      final container = _container(prefs);

      container.read(prDiffSplitViewProvider.notifier).setSplit(split: true);

      expect(container.read(prDiffSplitViewProvider), isTrue);
      expect(prefs.getBool(prDiffSplitViewKey), isTrue);

      final next = _container(prefs);
      expect(next.read(prDiffSplitViewProvider), isTrue);
    });
  });
}
