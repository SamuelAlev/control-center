import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';
import 'package:cc_domain/features/workspaces/domain/constants/specialist_agent_seeds.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/workspaces/create_specialist_agents.dart';

/// Puts the content synthesizer on a workspace's roster exactly once.
///
/// New workspaces get it from [CreateSpecialistAgentsUseCase] with the rest of
/// the roster; this covers workspaces created before it existed. It also
/// retires the workspace "short task" runner: an adapter+model pair chosen
/// there moves onto the agent, and the old settings are deleted.
///
/// The [kContentSynthesizerSeededSettingKey] marker makes it one-shot, so an
/// operator who deletes the agent turns those features off for good instead
/// of finding it back after the next restart.
class ContentSynthesizerSeeder {
  /// Creates a [ContentSynthesizerSeeder].
  const ContentSynthesizerSeeder({
    required this._agentRepository,
    required this._filesystem,
    required this._settings,
  });

  final AgentRepository _agentRepository;
  final WorkspaceFilesystemPort _filesystem;
  final WorkspaceSettingsRepository _settings;

  /// Ensures [workspaceId] has had its content synthesizer seeded. Never
  /// throws: a failure is logged and retried on the next boot, because the
  /// marker is only written after the agent is in place.
  Future<void> ensure(String workspaceId) async {
    try {
      if (_nonEmpty(
            await _settings.get(
              workspaceId,
              kContentSynthesizerSeededSettingKey,
            ),
          ) !=
          null) {
        return;
      }
      final legacyAdapter = _nonEmpty(
        await _settings.get(workspaceId, kLegacyShortTaskAdapterSettingKey),
      );
      // A model belongs to the adapter that serves it, so it only carries over
      // with that adapter.
      final legacyModel = legacyAdapter == null
          ? null
          : _nonEmpty(
              await _settings.get(workspaceId, kLegacyShortTaskModelSettingKey),
            );

      final existing = await _agentRepository.findByWorkspaceAndName(
        workspaceId,
        kContentSynthesizerSlug,
      );
      if (existing == null) {
        final ceo = await _agentRepository.findByWorkspaceAndName(
          workspaceId,
          'ceo',
        );
        await _filesystem.ensureWorkspaceDirs(workspaceId);
        await CreateSpecialistAgentsUseCase(
          agentRepository: _agentRepository,
          filesystemService: _filesystem,
        ).seedOne(
          spec: defaultSpecialistAgents.firstWhere(
            (s) => s.slug == kContentSynthesizerSlug,
          ),
          workspaceId: workspaceId,
          ceoAgentId: ceo?.id,
          adapterId: legacyAdapter,
          modelId: legacyModel,
        );
      } else if (legacyAdapter != null && existing.adapterId == null) {
        await _agentRepository.upsert(
          existing.copyWith(adapterId: legacyAdapter, modelId: legacyModel),
        );
      }

      await _settings.set(
        workspaceId,
        kContentSynthesizerSeededSettingKey,
        '1',
      );
      await _settings.set(workspaceId, kLegacyShortTaskAdapterSettingKey, null);
      await _settings.set(workspaceId, kLegacyShortTaskModelSettingKey, null);
    } on Object catch (e, st) {
      CcInfraLog.error(
        'ContentSynthesizerSeeder: failed for workspace $workspaceId',
        e,
        st,
      );
    }
  }

  static String? _nonEmpty(String? raw) {
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
