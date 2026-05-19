import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SharedPreferencesNotificationPreferences prefs;

  setUp(() {
    prefs = SharedPreferencesNotificationPreferences(
      AppPreferences.inMemory(),
    );
  });

  group('muted repositories round-trip', () {
    test('nothing is muted by default', () async {
      expect(await prefs.getMutedRepos(), isEmpty);
    });

    test('a mute persists and un-muting removes it', () async {
      await prefs.setRepoMuted('acme/widgets', muted: true);
      expect(await prefs.getMutedRepos(), {'acme/widgets'});

      await prefs.setRepoMuted('acme/widgets', muted: false);
      expect(await prefs.getMutedRepos(), isEmpty);
    });

    test('mutes are stored lowercased so matching is case-insensitive', () async {
      await prefs.setRepoMuted('ACME/Widgets', muted: true);
      expect(await prefs.getMutedRepos(), {'acme/widgets'});
      // And un-muting under different casing still finds it.
      await prefs.setRepoMuted('acme/WIDGETS', muted: false);
      expect(await prefs.getMutedRepos(), isEmpty);
    });

    test('several repositories coexist', () async {
      await prefs.setRepoMuted('acme/widgets', muted: true);
      await prefs.setRepoMuted('acme/gadgets', muted: true);
      expect(await prefs.getMutedRepos(), {'acme/widgets', 'acme/gadgets'});
    });

    test('muting twice is idempotent', () async {
      await prefs.setRepoMuted('acme/widgets', muted: true);
      await prefs.setRepoMuted('acme/widgets', muted: true);
      expect(await prefs.getMutedRepos(), hasLength(1));
    });

    test('un-muting something never muted is a no-op', () async {
      await prefs.setRepoMuted('acme/widgets', muted: false);
      expect(await prefs.getMutedRepos(), isEmpty);
    });

    test('an empty name is ignored rather than stored', () async {
      await prefs.setRepoMuted('   ', muted: true);
      expect(await prefs.getMutedRepos(), isEmpty);
    });
  });

  group('the stored value is sync-friendly', () {
    test('it rides the cross-device preference lane', () {
      // A mute is about the person, not the machine, so it has to reach the
      // phone too — and `syncedKeys` is the ONLY registration that makes that
      // happen.
      expect(
        SharedPreferencesNotificationPreferences.syncedKeys,
        contains('notifications_muted_repos'),
      );
    });

    test('the new categories sync automatically', () {
      // They derive from NotificationCategory.values, so this is really a
      // check that nobody hand-listed the categories.
      for (final category in [
        NotificationCategory.prMergeReadiness,
        NotificationCategory.prReviewDecision,
        NotificationCategory.prChecksStatus,
        NotificationCategory.prThreadActivity,
      ]) {
        expect(
          SharedPreferencesNotificationPreferences.syncedKeys,
          contains('notifications_category_${category.name}'),
        );
      }
    });

    test('a corrupt stored value mutes nothing instead of throwing', () async {
      final corrupt = SharedPreferencesNotificationPreferences(
        AppPreferences.inMemory({
          'notifications_muted_repos': 'not json at all',
        }),
      );
      expect(await corrupt.getMutedRepos(), isEmpty);
    });

    test('a JSON value of the wrong shape mutes nothing', () async {
      final wrongShape = SharedPreferencesNotificationPreferences(
        AppPreferences.inMemory({
          'notifications_muted_repos': '{"acme/widgets": true}',
        }),
      );
      expect(await wrongShape.getMutedRepos(), isEmpty);
    });
  });
}
