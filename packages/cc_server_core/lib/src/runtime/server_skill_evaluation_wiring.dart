import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ValidationException;
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_role_repository.dart';
import 'package:cc_domain/core/domain/services/permission_resolver.dart';
import 'package:cc_domain/core/domain/services/redaction/secret_scanner.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart'
    show ShellActionClassifier;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AcpModelsService,
        ClaudeAccountStore,
        ControlledEvaluationProcess,
        ControlledSkillEvaluation,
        SkillEvaluationSnapshotStore,
        resolveBinaryPath,
        SkillComparison;
import 'package:cc_persistence/cc_persistence.dart' show GlobalDatabase;
import 'package:cc_server_core/src/evals/skill_evaluation_evidence.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_model_policy.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Server authority, credentials, pricing and native isolation share the same
/// production dependencies as dispatch, but never its permissive fallback.
SkillEvaluationService buildSkillEvaluationService({
  required EvalsRepository repository,
  required GlobalDatabase globalDb,
  required WorkspaceMembershipRepository memberships,
  required WorkspaceRoleRepository roles,
  required WorkspaceRepository workspaces,
  required RepoRepository repositories,
  required WorkspaceFilesystemPort filesystem,
  required SkillBundlePort bundles,
  required SkillScanPort scanner,
  required ActionGuardService actionGuard,
  required DomainEventBus eventBus,
  required ProviderCredentialStore credentials,
  required ClaudeAccountStore claudeAccounts,
  required Future<ProviderCredential> Function(ProviderCredential)
  refreshCredential,
  required Future<ModelInfo?> Function(String qualified) resolveModel,
  required String dataDir,
  required bool executionEnabled,
  required Map<String, String> environment,
  HarnessProviderFactory factory = const HarnessProviderFactory(),
  void Function(String message)? onWarning,
}) {
  Future<bool> workspaceExists(String id) async =>
      await globalDb.workspaceRegistryDao.getById(id) != null;

  Future<void> authorize(
    String workspaceId,
    Principal actor, {
    required bool write,
    String? repoId,
  }) async {
    // Opening a workspace DAO creates its file: registry must precede even
    // the membership lookup, including on event/restart/background paths.
    if (!actor.isUser || !await workspaceExists(workspaceId)) {
      throw const AuthException('Unknown workspace or actor');
    }
    final member = await memberships.getMember(workspaceId, actor.id);
    final customId = RoleDefinition.customIdOf(member?.roleWire);
    final role = member == null
        ? null
        : customId == null
        ? RoleDefinition.preset(member.role)
        : await roles.byId(workspaceId, customId);
    final verdict = const PermissionResolver().can(
      PermissionPrincipal(
        userId: actor.id,
        role: role,
        repoGrants: repoId == null
            ? const {}
            : await memberships.getRepoGrants(workspaceId, actor.id),
      ),
      Permission('evals', write ? PermissionTier.write : PermissionTier.read),
      resource: repoId == null ? null : ResourceRef.repo(repoId),
    );
    if (!verdict.allowed) {
      throw AuthException(verdict.reason ?? 'Evaluation access denied');
    }
    if (repoId != null &&
        !await workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
      throw const AuthException('Repository is not linked to this workspace');
    }
  }

  Future<ProviderCredential> credential(String providerId) async {
    final selected = await credentials.activeCredential(providerId);
    if (selected == null ||
        selected.secret == null ||
        selected.disabledCause != null) {
      throw const AuthException(
        'Connect an enabled provider account before evaluation',
      );
    }
    return refreshCredential(selected);
  }

  Future<({String executable, String accountId, String configDir})>
  claudeAccount({String? accountId}) async {
    final configured = claudeAccounts.claudeExecutable;
    final executable = p.isAbsolute(configured)
        ? configured
        : await resolveBinaryPath(configured);
    if (executable == null || !p.isAbsolute(executable)) {
      throw const ValidationException(
        'Install Claude Code on the server before evaluating with its adapter',
      );
    }
    final plan = await claudeAccounts.resolveForDispatch(
      pinnedAccountId: accountId,
    );
    final active = plan.active;
    if (active == null ||
        (accountId != null && active.accountId != accountId)) {
      throw AuthException(
        plan.allSpent == null
            ? 'Connect an available Claude Code account in Settings → Adapters'
            : 'Claude Code account unavailable: ${plan.allSpent!.reason.name}',
      );
    }
    // Dispatch may borrow caller environment; this evaluator intentionally
    // cannot. Require a credential belonging to this managed account.
    if (!File(p.join(active.configDir, '.credentials.json')).existsSync()) {
      throw const AuthException(
        'Sign in to the default Claude Code account in Settings → Adapters',
      );
    }
    final reason = await ControlledSkillEvaluation.claudeCapabilityReason(
      executable: executable,
      configDir: active.configDir,
    );
    if (reason != null) {
      throw ValidationException(reason);
    }
    return (
      executable: executable,
      accountId: active.accountId,
      configDir: active.configDir,
    );
  }

  final claudeModels = AcpModelsService();
  Future<Map<String, dynamic>> validateModel(
    SkillEvaluationSettings settings,
  ) async {
    if (settings.adapter == 'claude-cli') {
      final models = await claudeModels.listModels('claude-code');
      if (settings.providerId != 'anthropic' ||
          !settings.modelId.startsWith('claude-') ||
          !models.any((model) => model.id == settings.modelId)) {
        throw const ValidationException(
          'Select a concrete Claude Code model, not a moving model alias',
        );
      }
      final account = await claudeAccount();
      return {
        'providerId': settings.providerId,
        'modelId': settings.modelId,
        'accountId': account.accountId,
        'priceBasis': 'native_api_equivalent',
        'budgetEnforcement': 'stop_after_call',
      };
    }
    final selected = await credential(settings.providerId);
    return admitSkillEvaluationModel(
      providerId: settings.providerId,
      modelId: settings.modelId,
      model: await resolveModel('${settings.providerId}/${settings.modelId}'),
      budgetMicros: settings.budgetMicros,
      credentialMethod: selected.method,
    );
  }

  return SkillEvaluationService(
    repository: repository,
    snapshots: SkillEvaluationSnapshotStore(
      filesystem: filesystem,
      repositories: repositories,
      workspaces: workspaces,
      bundles: bundles,
      scanner: scanner,
      dataDir: dataDir,
    ),
    authorize: authorize,
    workspaceExists: workspaceExists,
    registeredWorkspaceIds: () async => [
      for (final row in await globalDb.workspaceRegistryDao.getAll()) row.id,
    ],
    capability: () async {
      final reason = !executionEnabled
          ? 'Controlled skill evaluation is disabled on this server'
          : await ControlledEvaluationProcess.probeCapability();
      String? nativeReason = reason;
      if (reason == null) {
        try {
          await claudeAccount();
        } on Object catch (error) {
          nativeReason = '$error';
        }
      }
      final codex = await credentials.activeCredential('codex');
      return {
        'available': reason == null,
        'reason': reason,
        'backends': [
          if (reason == null) 'builtin',
          if (nativeReason == null) 'claude-cli',
        ],
        'usageBudgetProviders': [
          if (codex?.method == HarnessAuthMethod.oauth) 'codex',
        ],
        'unavailableBackends': {
          'claude-cli': ?nativeReason,
          'fleet':
              'Worker evalBatch jobs do not implement controlled skill execution',
        },
        'guestMemoryQuota': Platform.isLinux
            ? '512 MiB address space'
            : 'not available',
        'guestFileQuota': '16 MiB per file; 8 MiB accepted artifacts',
      };
    },
    validateModel: validateModel,
    authorizeExecution: (workspaceId, actor, automatic) async {
      await authorize(workspaceId, actor, write: true);
      final resolution = await actionGuard.resolve(
        workspaceId: workspaceId,
        classes: {ActionClass.processSpawn, ActionClass.networkEgress},
        mode: Mode.chat,
      );
      if (resolution.decision == ActionDecision.deny ||
          (automatic && resolution.decision != ActionDecision.allow)) {
        throw const AuthException(
          'Current action policy does not allow this evaluation launch',
        );
      }
    },
    execute: (job) async {
      final campaign = job.campaign;
      final native = campaign.configuration['executor'] == 'claude-cli';
      final pin = (campaign.configuration['modelPin'] as Map)
          .cast<String, dynamic>();
      final account = native
          ? await claudeAccount(accountId: pin['accountId'] as String)
          : null;
      final selected = native ? null : await credential(campaign.providerId);
      if (!native &&
          pin['budgetEnforcement'] == 'stop_after_call' &&
          (campaign.providerId != 'codex' ||
              selected!.method != HarnessAuthMethod.oauth)) {
        throw const AuthException(
          'The subscription account changed; start a new evaluation before using an API key',
        );
      }
      final price = native ? null : skillEvaluationModelCostFromPin(pin);
      final workspaceSegment = sha256
          .convert(utf8.encode(campaign.workspaceId))
          .toString();
      final run = ControlledSkillEvaluation(
        adapter: native ? 'claude-cli' : 'builtin',
        claudeExecutable: account?.executable,
        claudeConfigDir: account?.configDir,
        budgetEnforcement: pin['budgetEnforcement'] as String,
        workspaceId: campaign.workspaceId,
        campaignId: campaign.id,
        skillKey: campaign.skillKey,
        configurationHash: campaign.configurationHash,
        corpus: job.corpus,
        candidate: job.candidate.package,
        previous: job.previous?.package,
        ambient: [for (final item in job.ambient) item.package],
        comparison: SkillComparison.values.byName(campaign.comparison.name),
        providerId: campaign.providerId,
        modelId: campaign.modelId,
        credential: selected,
        factory: factory,
        priceLookup: price == null
            ? null
            : (record) {
                if (record.providerId != campaign.providerId ||
                    record.model != campaign.modelId ||
                    (record.outcome != ProviderCallOutcome.success &&
                        record.usage.inputTokens == 0 &&
                        record.usage.outputTokens == 0)) {
                  return null;
                }
                return ProviderCallCost(
                  (price.estimate(
                            inputTokens: record.usage.inputTokens,
                            outputTokens: record.usage.outputTokens,
                            cacheReadTokens: record.usage.cacheReadTokens,
                            cacheWriteTokens: record.usage.cacheWriteTokens,
                          ) *
                          1000000)
                      .ceil(),
                );
              },
        maxCallMicros: (pin['maxCallMicros'] as num?)?.toInt(),
        budgetMicros: campaign.budgetMicros,
        repetitions: campaign.repetitions,
        outDir: p.join(
          dataDir,
          'skill-evaluations',
          workspaceSegment,
          'campaigns',
          campaign.id,
        ),
        cancellation: job.cancellation,
        onAttempt: job.onAttempt,
        commandGuard: (command) async {
          await authorize(
            campaign.workspaceId,
            campaign.actor,
            write: true,
            repoId: campaign.repoId,
          );
          final verdict = await actionGuard.check(
            workspaceId: campaign.workspaceId,
            classes: {
              ActionClass.processSpawn,
              ...const ShellActionClassifier().classify(command),
            },
            command: command,
            mode: Mode.chat,
            onBehalfOfUserId: campaign.actor.id,
            runId: campaign.id,
            actionSummary: 'Skill evaluation command',
          );
          return verdict.allowed
              ? null
              : verdict.reason ?? 'Command denied by action policy';
        },
      );
      return run.run();
    },
    eventBus: eventBus,
    evidence: SkillEvaluationEvidence(
      secrets: SecretScanner(environment: environment),
    ),
    onWarning: onWarning,
    disposeExecutor: ControlledEvaluationProcess.disposeRuntime,
  );
}
