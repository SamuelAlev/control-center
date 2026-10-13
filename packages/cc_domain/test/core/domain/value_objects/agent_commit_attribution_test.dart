import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/services/resolve_agent_attribution.dart';
import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:test/test.dart';

class _UserPreferences implements UserPreferencesRepository {
  final values = <String, String>{};

  @override
  Future<String?> get(String userId, String key) async => values[userId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkspaceSettings implements WorkspaceSettingsRepository {
  final values = <String, String>{};

  @override
  Future<String?> get(String workspaceId, String key) async =>
      values[workspaceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'workspace choices override users and clearing restores their preferences',
    () {
      for (final user in ['true', 'false']) {
        expect(
          resolveAgentCommitAttribution(
            userPreference: user,
            workspaceOverride: 'false',
          ),
          isFalse,
        );
        expect(
          resolveAgentCommitAttribution(
            userPreference: user,
            workspaceOverride: 'true',
          ),
          isTrue,
        );
        expect(
          resolveAgentCommitAttribution(
            userPreference: user,
            workspaceOverride: AgentAttributionOverride.inherit.storedValue,
          ),
          user == 'true',
        );
      }
      expect(
        resolveAgentCommitAttribution(
          userPreference: null,
          workspaceOverride: null,
        ),
        isTrue,
      );
      expect(
        resolveAgentCommitAttribution(
          userPreference: 'invalid',
          workspaceOverride: 'invalid',
        ),
        isTrue,
      );
    },
  );

  test(
    'stored choices remain isolated per user and workspace and update between runs',
    () async {
      final users = _UserPreferences()..values['alice'] = 'false';
      final workspaces = _WorkspaceSettings()
        ..values['forced-on'] = 'true'
        ..values['forced-off'] = 'false';
      Future<bool> resolve(String user, String workspace) =>
          resolveStoredAgentAttribution(
            preferences: users,
            workspaceSettings: workspaces,
            userId: user,
            workspaceId: workspace,
          );
      expect(await resolve('alice', 'personal'), isFalse);
      expect(await resolve('bob', 'personal'), isTrue);
      expect(await resolve('alice', 'forced-on'), isTrue);
      expect(await resolve('bob', 'forced-off'), isFalse);
      expect(await resolve('bob', 'personal'), isTrue);
      workspaces.values.remove('forced-off');
      expect(await resolve('bob', 'forced-off'), isTrue);
      users.values['bob'] = 'false';
      expect(await resolve('bob', 'personal'), isFalse);
    },
  );
}
