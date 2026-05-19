import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adapterModelsProvider', () {
    test('returns empty list when adapterId is null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        adapterModelsProvider(null as String?).future,
      );
      expect(result, isEmpty);
    });

    test('returns empty list when adapterId is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(adapterModelsProvider('').future);
      expect(result, isEmpty);
    });
  });

  group('detectedAdaptersProvider', () {
    test('build initializes adapters in checking state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final detected = container.read(detectedAdaptersProvider);

      expect(detected.isNotEmpty, isTrue);
      for (final d in detected) {
        expect(d.status, DetectionStatus.checking);
      }
    });

    test('refresh resets all adapters to checking', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(detectedAdaptersProvider.notifier).refresh();

      final detected = container.read(detectedAdaptersProvider);
      for (final d in detected) {
        expect(d.status, DetectionStatus.checking);
      }
    });
  });

  group('AdapterDetectionNotifier', () {
    test('notifier is created successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(detectedAdaptersProvider.notifier);
      expect(notifier, isA<AdapterDetectionNotifier>());
    });

    test('initial state has predefined adapters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(detectedAdaptersProvider);
      expect(state.any((d) => d.adapter.id == 'pi-dev'), isTrue);
    });

    test('all initial adapters are in checking state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(detectedAdaptersProvider);
      for (final d in state) {
        expect(d.status, DetectionStatus.checking);
        expect(d.isResolved, isFalse);
        expect(d.isFound, isFalse);
      }
    });
  });

  group('DetectedAdapter domain model', () {
    test('copyWith updates status', () {
      final detected = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.checking,
      );

      final updated = detected.copyWith(status: DetectionStatus.found);
      expect(updated.status, DetectionStatus.found);
      expect(updated.isFound, isTrue);
      expect(updated.adapter, predefinedAdapters[0]);
    });

    test('copyWith clears version', () {
      final detected = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.found,
        version: '1.0.0',
      );

      final cleared = detected.copyWith(clearVersion: true);
      expect(cleared.version, isNull);
    });

    test('equality', () {
      final a = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.checking,
      );
      final b = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.checking,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.found,
      );
      expect(a, isNot(equals(c)));
    });

    test('isResolved property', () {
      final checking = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.checking,
      );
      expect(checking.isResolved, isFalse);

      final found = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.found,
      );
      expect(found.isResolved, isTrue);

      final notFound = DetectedAdapter(
        adapter: predefinedAdapters[0],
        status: DetectionStatus.notFound,
      );
      expect(notFound.isResolved, isTrue);
    });
  });
}
