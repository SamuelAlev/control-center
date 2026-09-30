import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:control_center/features/repos/providers/repo_link_workspace_choices.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoLinkWorkspaceChoices', () {
    test('matches the repository case-insensitively, like GitHub', () {
      final choices = const RepoLinkWorkspaceChoices().remember(
        'SamuelAlev/control-center',
        'ws-a',
      );

      expect(choices.workspaceFor('samuelalev/Control-Center'), 'ws-a');
      expect(choices.workspaceFor('acme/widgets'), isNull);
    });

    test('remembering a differently-cased name replaces the old entry', () {
      final choices = const RepoLinkWorkspaceChoices()
          .remember('acme/widgets', 'ws-a')
          .remember('Acme/Widgets', 'ws-b');

      expect(choices.byRepo, {'Acme/Widgets': 'ws-b'});
    });

    test('forgetting drops only that repository', () {
      final choices = const RepoLinkWorkspaceChoices()
          .remember('acme/widgets', 'ws-a')
          .remember('acme/gadgets', 'ws-b')
          .forget('ACME/widgets');

      expect(choices.byRepo, {'acme/gadgets': 'ws-b'});
    });

    test('round-trips through its stored form', () {
      final choices = const RepoLinkWorkspaceChoices()
          .remember('acme/widgets', 'ws-a')
          .remember('acme/gadgets', 'ws-b');

      expect(RepoLinkWorkspaceChoices.decode(choices.encode()), choices);
    });

    test('reads a malformed value as no choices', () {
      for (final raw in [
        null,
        '',
        'not json',
        '[1, 2]',
        '{"acme/widgets": 3}',
      ]) {
        expect(
          RepoLinkWorkspaceChoices.decode(raw).byRepo,
          isEmpty,
          reason: '$raw',
        );
      }
    });
  });

  group('repoLinkWorkspaceWithoutAsking', () {
    test('a repository in one workspace never asks', () {
      expect(
        repoLinkWorkspaceWithoutAsking(candidates: ['ws-a'], remembered: null),
        'ws-a',
      );
    });

    test('several workspaces ask unless a choice was remembered', () {
      expect(
        repoLinkWorkspaceWithoutAsking(
          candidates: ['ws-a', 'ws-b'],
          remembered: null,
        ),
        isNull,
      );
      expect(
        repoLinkWorkspaceWithoutAsking(
          candidates: ['ws-a', 'ws-b'],
          remembered: 'ws-b',
        ),
        'ws-b',
      );
    });

    test('a remembered workspace that no longer links the repo asks again', () {
      expect(
        repoLinkWorkspaceWithoutAsking(
          candidates: ['ws-a', 'ws-b'],
          remembered: 'ws-gone',
        ),
        isNull,
      );
    });
  });

  group('repoLinkWorkspaceChoicesProvider', () {
    test('persists choices and removes the key once none remain', () async {
      final preferences = AppPreferences.inMemory();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        repoLinkWorkspaceChoicesProvider.notifier,
      );

      await notifier.remember('acme/widgets', 'ws-a');

      expect(
        container
            .read(repoLinkWorkspaceChoicesProvider)
            .workspaceFor('acme/widgets'),
        'ws-a',
      );
      expect(
        RepoLinkWorkspaceChoices.decode(
          preferences.getString(repoLinkWorkspaceChoicesKey),
        ).byRepo,
        {'acme/widgets': 'ws-a'},
      );

      await notifier.forget('acme/widgets');

      expect(container.read(repoLinkWorkspaceChoicesProvider).byRepo, isEmpty);
      expect(preferences.getString(repoLinkWorkspaceChoicesKey), isNull);
    });

    test('reads choices stored by another device', () {
      final preferences = AppPreferences.inMemory({
        repoLinkWorkspaceChoicesKey: '{"acme/widgets":"ws-b"}',
      });
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(repoLinkWorkspaceChoicesProvider)
            .workspaceFor('acme/widgets'),
        'ws-b',
      );
    });

    test('follows the user across devices', () {
      final syncedKeys = buildSyncedPreferences().map((p) => p.key).toSet();

      expect(syncedKeys, contains(repoLinkWorkspaceChoicesKey));
    });
  });
}
