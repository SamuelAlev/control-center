part of '../cc_server_runtime.dart';

/// Who the commits made on this server name, credit and are signed by
/// ([AgentCommitIdentities]): a person's own (runs they asked for, IDE
/// commits) or the agent's (runs nobody asked for).
AgentCommitIdentities _wireCommitIdentities({
  required GitHubClients githubClients,
  required _GitHubAutomation githubAutomation,
  required ForgeCredentials forgeCredentials,
  required DaoUserRepository userRepository,
  required DaoUserPreferencesRepository userPreferences,
  required WorkspaceSettingsRepository workspaceSettings,
  required DaoAgentRunLogRepository agentRunLogs,
  required PipelineRunRepositoryImpl pipelineRuns,
  required CommitSigningKeys signingKeys,
}) => AgentCommitIdentities.forServer(
  github: githubClients,
  userExists: (userId) async => await userRepository.getById(userId) != null,
  githubAccount: githubAutomation.personAccount,
  personToken: (forge, userId, workspaceId) =>
      forgeCredentials.personToken(forge, userId, workspaceId: workspaceId),
  // Co-author credit: the workspace's override, else the person's own
  // preference, else on.
  creditsCoAuthor: (userId, workspaceId) async =>
      resolveAgentCommitAttribution(
        userPreference: await userPreferences.get(
          userId,
          agentCommitAttributionSettingKey,
        ),
        workspaceOverride: workspaceId == null || workspaceId.isEmpty
            ? null
            : await workspaceSettings.get(
                workspaceId,
                agentCommitAttributionSettingKey,
              ),
      ),
  signingKeyOf: signingKeys.publicKeyOf,
  // A run nobody asked for was started by an armed trigger's pipeline: the
  // engine recorded everyone who armed it on the pipeline run.
  accountableFor: (workspaceId, runLogId) async {
    final log = await agentRunLogs.getById(workspaceId, runLogId);
    final pipelineRunId = log?.pipelineRunId;
    if (pipelineRunId == null || pipelineRunId.isEmpty) {
      return const {};
    }
    final run = await pipelineRuns.getRun(pipelineRunId);
    return run == null || run.workspaceId != workspaceId
        ? const {}
        : pipelineArmedByOf(run.triggerPayload);
  },
);
