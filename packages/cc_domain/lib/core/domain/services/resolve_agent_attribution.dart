import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';

/// Reads the run's workspace override before its requesting user's preference.
///
/// Callers supply an authenticated dispatch scope. No settings are cached: a
/// workspace switch or a preference change takes effect on the next run.
Future<bool> resolveStoredAgentAttribution({
  required UserPreferencesRepository preferences,
  required WorkspaceSettingsRepository workspaceSettings,
  required String userId,
  required String? workspaceId,
}) async {
  final workspaceValue = workspaceId == null
      ? null
      : await workspaceSettings.get(
          workspaceId,
          agentCommitAttributionSettingKey,
        );
  final override = AgentAttributionOverride.fromStored(workspaceValue).value;
  if (override != null) {
    return override;
  }
  return resolveAgentCommitAttribution(
    userPreference: await preferences.get(
      userId,
      agentCommitAttributionSettingKey,
    ),
    workspaceOverride: null,
  );
}
