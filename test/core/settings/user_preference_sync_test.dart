import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/settings/synced_preference.dart';
import 'package:control_center/core/settings/user_preference_sync.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the two-way per-user preference sync.
///
/// The two failure modes worth pinning are not "does a value arrive" but:
///
///  * **Echo loops.** Push observes the key-value store rather than N
///    providers, so applying a pulled value must not immediately push it back.
///    A missed guard here is an infinite RPC loop, not one wasted write.
///  * **Resurrection.** Without the promotion marker, deleting a synced key on
///    one device lets another device that still holds the local copy re-promote
///    it and the setting becomes undeletable.
void main() {
  const keyA = 'theme_mode';
  const keyB = 'app_locale';

  late ProviderContainer container;
  late ObservableKeyValueBackend backend;
  late List<({String key, String? value})> pushes;
  late Ref hostRef;
  late ProviderSubscription<Ref> hostSub;
  final syncs = <UserPreferenceSync>[];

  /// Records every push instead of hitting a server.
  Future<void> record(String key, String? value) async {
    pushes.add((key: key, value: value));
  }

  /// Builds a sync and registers it for teardown, so a failing expectation
  /// cannot leak a pending timer into the next test.
  UserPreferenceSync buildSync({List<SyncedPreference>? registry}) {
    final sync = UserPreferenceSync(
      ref: hostRef,
      registry:
          registry ?? const [SyncedPreference(keyA), SyncedPreference(keyB)],
      push: record,
      debounce: Duration.zero,
    );
    syncs.add(sync);
    return sync;
  }

  setUp(() {
    pushes = [];
    backend = ObservableKeyValueBackend(InMemoryStorage());
    container = ProviderContainer(
      overrides: [
        keyValueBackendProvider.overrideWithValue(backend),
        appPreferencesProvider.overrideWithValue(AppPreferences(backend)),
      ],
    );
    // Riverpod 3 disposes a provider with no listeners, which would invalidate
    // the Ref the sync holds. Keep it alive for the test's lifetime.
    hostSub = container.listen(_refProvider, (_, _) {});
    hostRef = hostSub.read();
  });

  tearDown(() {
    for (final sync in syncs) {
      // Cancels the local-write subscription and any debounced push timers.
      // Without this every test leaves a live subscription and pending timers
      // behind, which bleeds pushes into later tests.
      sync.dispose();
    }
    syncs.clear();
    hostSub.close();
    container.dispose();
    backend.dispose();
  });

  /// Drains the event loop far enough for a push to land.
  ///
  /// A local write reaches the sync through a broadcast stream (a microtask),
  /// which then schedules the debounce timer (a macrotask), whose callback
  /// fires the push (another microtask). One turn is not enough.
  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('promotion', () {
    test('pushes a local value the server has never seen and marks it', () async {
      backend.set(keyA, 'dark');
      final sync = buildSync();

      await sync.bootstrap({});
      await settle();

      expect(
        pushes.where((p) => p.key == keyA).map((p) => p.value),
        ['dark'],
      );
      final marker = pushes.lastWhere((p) => p.key == promotionMarkerKey);
      expect(jsonDecode(marker.value!), contains(keyA));
    });

    test('adopts the server value and does NOT push when the server has the key', () async {
      backend.set(keyA, 'dark');
      final sync = buildSync();

      await sync.bootstrap({keyA: 'light'});
      await settle();

      expect(backend.get(keyA), 'light', reason: 'server wins');
      expect(
        pushes.where((p) => p.key == keyA),
        isEmpty,
        reason: 'adopting a remote value must not echo it back',
      );
    });

    test('does not resurrect a key deleted on another device', () async {
      // This device still holds the local value, the server no longer has the
      // key, but the marker records that it was already promoted once.
      backend.set(keyA, 'dark');
      final sync = buildSync();

      await sync.bootstrap({
        promotionMarkerKey: jsonEncode([keyA]),
      });
      await settle();

      expect(
        pushes.where((p) => p.key == keyA),
        isEmpty,
        reason:
            'Re-promoting an already-promoted key makes a deleted setting '
            'permanently undeletable.',
      );
    });

    test('leaves an absent key alone', () async {
      final sync = buildSync();
      await sync.bootstrap({});
      await settle();

      expect(pushes, isEmpty);
    });

    test('three devices against one server converge to a single push', () async {
      // Device 1 seeds.
      backend.set(keyA, 'dark');
      final first = buildSync();
      await first.bootstrap({});
      await settle();
      final seeded = pushes.where((p) => p.key == keyA).length;

      // Devices 2 and 3 arrive with their own divergent local values and see
      // the server's.
      for (final divergent in ['light', 'system']) {
        pushes.clear();
        backend.set(divergent == 'light' ? keyA : keyA, divergent);
        final later = buildSync();
        await later.bootstrap({keyA: 'dark'});
        await settle();
        expect(
          pushes.where((p) => p.key == keyA),
          isEmpty,
          reason: 'a later device adopts, it does not overwrite',
        );
        expect(backend.get(keyA), 'dark');
      }
      expect(seeded, 1);
    });
  });

  group('steady state', () {
    test('a local write pushes exactly once', () async {
      final sync = buildSync();
      await sync.bootstrap({});
      await settle();
      pushes.clear();

      backend.set(keyA, 'dark');
      await settle();

      expect(pushes.where((p) => p.key == keyA).map((p) => p.value), ['dark']);
    });

    test('applying a server snapshot produces zero pushes', () async {
      final sync = buildSync();
      await sync.bootstrap({});
      await settle();
      pushes.clear();

      sync.applyServerSnapshot({keyA: 'dark', keyB: 'fr'});
      await settle();

      expect(
        pushes,
        isEmpty,
        reason: 'the muted write + server mirror must both suppress the echo',
      );
      expect(backend.get(keyA), 'dark');
      expect(backend.get(keyB), 'fr');
    });

    test('re-applying an identical snapshot does not re-notify', () async {
      var pulls = 0;
      final sync = buildSync(
        registry: [
          SyncedPreference(keyA, onPulled: (_) => pulls++),
        ],
      );
      await sync.bootstrap({keyA: 'dark'});
      await settle();
      expect(pulls, 1);

      sync.applyServerSnapshot({keyA: 'dark'});
      await settle();

      expect(pulls, 1, reason: 'an unchanged value must not churn readers');
    });

    test('pushes are dropped until bootstrap arms the sync', () async {
      // Deliberately NOT bootstrapped — the sync only has to exist (and be
      // subscribed) for this to be a real test of the pre-arm gate.
      buildSync();

      // A write racing the promotion pass must not push a value the pass is
      // about to reconcile.
      backend.set(keyA, 'dark');
      await settle();
      expect(pushes, isEmpty);
    });

    test('a value over its byte limit is not pushed', () async {
      final sync = buildSync(
        registry: const [SyncedPreference(keyA, maxBytes: 8)],
      );
      await sync.bootstrap({});
      await settle();
      pushes.clear();

      backend.set(keyA, 'x' * 9);
      await settle();

      expect(pushes, isEmpty);
    });

    test('a key outside the registry is ignored', () async {
      final sync = buildSync();
      await sync.bootstrap({});
      await settle();
      pushes.clear();

      backend.set('window_x', '100');
      await settle();

      expect(pushes, isEmpty);
    });

    test('dispose stops further pushes', () async {
      final sync = buildSync();
      await sync.bootstrap({});
      await settle();
      pushes.clear();

      sync.dispose();
      backend.set(keyA, 'dark');
      await settle();

      expect(
        pushes,
        isEmpty,
        reason:
            'A disposed sync must not keep writing — a server switch rebuilds '
            'the container around the same process-wide backend.',
      );
    });
  });
}

/// Exposes a [Ref] for constructing the sync under test.
final _refProvider = Provider<Ref>((ref) => ref);
