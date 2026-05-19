import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/events/workspace_events.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_ceo_agent.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_specialist_agents.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_workspace.dart'
    show CreateWorkspaceCommand, CreateWorkspaceUseCase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const String _activeWorkspaceIdKey = 'active_workspace_id';
const String _activeRepoIdKeyPrefix = 'active_repo_id:';

/// Watches all workspaces ordered by updated time.
final workspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll();
});

/// Watches a single workspace by id.
///
/// Uses `watchAll()` + in-memory filter because `WorkspaceDao.getById()`
/// returns a `Future`, not a `Stream` — it would not react to changes.
final workspaceDetailProvider = StreamProvider.autoDispose.family<Workspace?, String>((
  ref,
  id,
) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll().map((list) {
    try {
      return list.firstWhere((w) => w.id == id);
    } on StateError {
      return null;
    }
  });
});

/// Tracks the id of the workspace currently scoped in the UI.
///
/// Persists to shared_preferences so the choice survives restarts.
/// Falls back to the first available workspace, or null when there are none.
class ActiveWorkspaceIdNotifier extends Notifier<String?> {
  String? _cachedStoredId;

  @override
  String? build() {
    _cachedStoredId ??= ref
        .watch(sharedPreferencesProvider)
        .getString(_activeWorkspaceIdKey);
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    if (workspaces.isEmpty) {
      return null;
    }

    if (_cachedStoredId != null &&
        workspaces.any((w) => w.id == _cachedStoredId)) {
      return _cachedStoredId;
    }
    return workspaces.first.id;
  }

  /// Sets the active workspace id and persists it.
  Future<void> setActive(String id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_activeWorkspaceIdKey, id);
    _cachedStoredId = id;
    state = id;
  }
}

/// Active workspace id (persisted across restarts).
final activeWorkspaceIdProvider =
    NotifierProvider<ActiveWorkspaceIdNotifier, String?>(
      ActiveWorkspaceIdNotifier.new,
    );

/// Convenience accessor for the active workspace row.
final activeWorkspaceProvider = Provider<Workspace?>((ref) {
  final id = ref.watch(activeWorkspaceIdProvider);
  if (id == null) {
    return null;
  }

  final workspaces = ref.watch(workspacesProvider).value ?? const [];
  for (final w in workspaces) {
    if (w.id == id) {
      return w;
    }
  }
  return null;
});

/// Tracks the id of the repo currently scoped within the active workspace.
///
/// Falls back to the first linked repo, or null if the workspace has none.
class ActiveRepoIdNotifier extends Notifier<String?> {
  String? _cachedStoredId;

  @override
  String? build() {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }

    final prefs = ref.watch(sharedPreferencesProvider);
    _cachedStoredId = prefs.getString('$_activeRepoIdKeyPrefix$workspaceId');
    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
    if (repos.isEmpty) {
      return null;
    }

    if (_cachedStoredId != null && repos.any((r) => r.id == _cachedStoredId)) {
      return _cachedStoredId;
    }
    return repos.first.id;
  }

  /// Sets the active repo for the current workspace and persists it.
  Future<void> setActive(String repoId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('$_activeRepoIdKeyPrefix$workspaceId', repoId);
    _cachedStoredId = repoId;
    state = repoId;
  }
}

/// Active repo id within the active workspace (persisted across restarts).
final activeRepoIdProvider = NotifierProvider<ActiveRepoIdNotifier, String?>(
  ActiveRepoIdNotifier.new,
);

/// The currently active [Repo] in the active workspace, or `null`.
final activeRepoProvider = Provider<Repo?>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }

  final repoId = ref.watch(activeRepoIdProvider);
  if (repoId == null) {
    return null;
  }

  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  for (final r in repos) {
    if (r.id == repoId) {
      return r;
    }
  }
  return null;
});

/// Reacts to [WorkspaceCreated] events by seeding a CEO agent, default
/// skills, and memory access grants into the newly created workspace.
class CeoAgentSeedNotifier extends Notifier<void> {
  StreamSubscription<WorkspaceCreated>? _sub;

  /// Workspaces already seeded this session — guards against a duplicate
  /// `WorkspaceCreated` (e.g. event re-published) re-running the seed and
  /// re-writing agent files. Agent rows are already idempotent via
  /// `findByWorkspaceAndName`, but this also skips the redundant filesystem I/O.
  final Set<String> _seeded = {};

  @override
  void build() {
    final eventBus = ref.watch(domainEventBusProvider);
    final agentRepo = ref.watch(agentRepositoryProvider);
    final fsService = ref.watch(workspaceFilesystemPortProvider);
    final templateRepo = ref.watch(pipelineTemplateRepositoryProvider);
    final triggerRepo = ref.watch(pipelineTriggerRepositoryProvider);

    _sub = eventBus.on<WorkspaceCreated>().listen((event) {
      if (!_seeded.add(event.workspaceId)) {
        return;
      }
      // The seed is async but the listener returns void. Run it inside a
      // guarded async closure so exceptions surface via AppLog instead of
      // disappearing into an unhandled-Future error — that's what used to
      // leave new workspaces with CEO files on disk but no agent row.
      unawaited(() async {
        try {
          final adapterId = ref.read(defaultChatAdapterProvider);
          final modelId = ref.read(defaultChatModelProvider);
          final ceo = await CreateCeoAgentUseCase(
            agentRepository: agentRepo,
            filesystemService: fsService,
          ).execute(
            event.workspaceId,
            adapterId: adapterId,
            modelId: modelId,
          );
          final specialists = await CreateSpecialistAgentsUseCase(
            agentRepository: agentRepo,
            filesystemService: fsService,
          ).execute(
            event.workspaceId,
            ceoAgentId: ceo.id,
            adapterId: adapterId,
            modelId: modelId,
          );
          await _seedBuiltInPipelineTemplates(
            workspaceId: event.workspaceId,
            ceo: ceo,
            specialists: specialists,
            templateRepo: templateRepo,
            triggerRepo: triggerRepo,
          );
        } on Object catch (e, st) {
          // Allow a later re-fire to retry a failed seed.
          _seeded.remove(event.workspaceId);
          AppLog.e(
            'CeoAgentSeed',
            'Failed to seed default agents for workspace ${event.workspaceId}',
            e,
            st,
          );
        }
      }());
    });

    ref.onDispose(() => _sub?.cancel());
  }
}

/// Keeps the CEO agent seed listener alive across the app lifetime.
final ceoAgentSeedProvider = NotifierProvider<CeoAgentSeedNotifier, void>(
  CeoAgentSeedNotifier.new,
);

/// Seeds the built-in pipeline templates for a workspace, wiring per-node
/// `agentId` config to the just-created specialist agents.
Future<void> _seedBuiltInPipelineTemplates({
  required String workspaceId,
  required PipelineTemplateRepository templateRepo,
  required PipelineTriggerRepository triggerRepo,
  Agent? ceo,
  List<Agent> specialists = const [],
}) async {
  // The code indexer is agentless — always ensure it (template + trigger),
  // even for workspaces whose specialist agents aren't available.
  await _ensureIndexCodeTemplate(workspaceId, templateRepo, triggerRepo);

  Agent? bySlug(String slug) {
    for (final a in specialists) {
      if (a.name == slug) {
        return a;
      }
    }
    return null;
  }

  final qa = bySlug('qa');
  final architect = bySlug('architect');
  final engineer = bySlug('engineer');
  final librarian = bySlug('librarian');
  if (ceo == null ||
      qa == null ||
      architect == null ||
      engineer == null ||
      librarian == null) {
    // Specialists weren't fully created — skip the agent-based templates (the
    // agentless index_code template above is still seeded).
    return;
  }

  final ids = BuiltInAgentIds(
    qa: qa.id,
    architect: architect.id,
    engineer: engineer.id,
    librarian: librarian.id,
    ceo: ceo.id,
  );
  // Reconcile each template's built-in trigger rows (manual / event / cron).
  // Existing rows are left untouched so the user's enable/filter choices
  // survive a re-seed.
  final existingTriggerKeys = (await triggerRepo.forWorkspace(workspaceId))
      .map((t) => '${t.templateId}|${t.eventType}')
      .toSet();

  for (final seed in builtInTemplateSeeds(
    workspaceId: workspaceId,
    agentIds: ids,
  )) {
    // index_code's triggers + agentless fallback are ensured above; the loop
    // still upserts its full (agent-bearing) definition here.
    // Preserve the user's isEnabled choice across re-seeds; copyWith keeps the
    // declared inputs (and steps) so manual-run forms survive a re-seed.
    final existing = await templateRepo.getById(workspaceId, seed.templateId);
    final enabled = existing?.isEnabled ?? seed.isEnabled;
    await templateRepo.upsert(seed.copyWith(isEnabled: enabled));
    await _seedBuiltInTriggers(
      workspaceId: workspaceId,
      templateId: seed.templateId,
      triggerRepo: triggerRepo,
      existingKeys: existingTriggerKeys,
    );
  }
}

/// Inserts any missing built-in trigger rows for [templateId] (see
/// [builtInTriggerSeeds]). Records inserted `templateId|eventType` keys in
/// [existingKeys] so a single seed pass never double-inserts, and so existing
/// rows (with the user's enable/filter choices) are preserved.
Future<void> _seedBuiltInTriggers({
  required String workspaceId,
  required String templateId,
  required PipelineTriggerRepository triggerRepo,
  required Set<String> existingKeys,
}) async {
  final specs = builtInTriggerSeeds()[templateId];
  if (specs == null) {
    return;
  }
  for (final spec in specs) {
    final key = '$templateId|${spec.eventType}';
    if (existingKeys.contains(key)) {
      continue;
    }
    await triggerRepo.insert(
      PipelineTrigger(
        id: const Uuid().v4(),
        eventType: spec.eventType,
        templateId: templateId,
        workspaceId: workspaceId,
        enabled: spec.enabled,
        cronExpression: spec.cronExpression,
        match: spec.match,
      ),
    );
    existingKeys.add(key);
  }
}

/// Ensures the agentless `index_code` template + its `RepoAdded` trigger exist
/// for [workspaceId] (idempotent; preserves the user's enabled choice). Lets
/// workspaces created before the template existed pick it up.
Future<void> _ensureIndexCodeTemplate(
  String workspaceId,
  PipelineTemplateRepository templateRepo,
  PipelineTriggerRepository triggerRepo,
) async {
  final seed = indexCodeTemplate(workspaceId);
  final existing = await templateRepo.getById(workspaceId, seed.templateId);
  await templateRepo.upsert(
    seed.copyWith(isBuiltIn: true, isEnabled: existing?.isEnabled ?? seed.isEnabled),
  );

  final existingKeys = (await triggerRepo.forWorkspace(workspaceId))
      .map((t) => '${t.templateId}|${t.eventType}')
      .toSet();
  await _seedBuiltInTriggers(
    workspaceId: workspaceId,
    templateId: 'index_code',
    triggerRepo: triggerRepo,
    existingKeys: existingKeys,
  );
}

/// Re-seeds built-in pipeline templates for every existing workspace on app
/// launch, so templates added in newer versions (e.g. `index_code`) appear for
/// workspaces created earlier. Upserts preserve each template's enabled state.
class BuiltInTemplateReseedNotifier extends Notifier<void> {
  @override
  void build() {
    unawaited(_reseed());
  }

  Future<void> _reseed() async {
    try {
      final workspaces = await ref
          .read(workspaceRepositoryProvider)
          .watchAll()
          .first;
      final templateRepo = ref.read(pipelineTemplateRepositoryProvider);
      final triggerRepo = ref.read(pipelineTriggerRepositoryProvider);
      final agentRepo = ref.read(agentRepositoryProvider);
      for (final workspace in workspaces) {
        try {
          final ceo = await agentRepo.findByWorkspaceAndName(
            workspace.id,
            'ceo',
          );
          final specialists = await agentRepo
              .watchByWorkspace(workspace.id)
              .first;
          await _seedBuiltInPipelineTemplates(
            workspaceId: workspace.id,
            templateRepo: templateRepo,
            triggerRepo: triggerRepo,
            ceo: ceo,
            specialists: specialists,
          );
        } on Object catch (e, st) {
          AppLog.e(
            'TemplateReseed',
            'Failed to re-seed templates for workspace ${workspace.id}',
            e,
            st,
          );
        }
      }
    } on Object catch (e, st) {
      AppLog.e('TemplateReseed', 'Built-in template re-seed failed', e, st);
    }
  }
}

/// Keeps the built-in template re-seed alive across the app lifetime.
final builtInTemplateReseedProvider =
    NotifierProvider<BuiltInTemplateReseedNotifier, void>(
      BuiltInTemplateReseedNotifier.new,
    );

/// Manages workspace creation state and side effects.
class CreateWorkspaceNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// Creates a workspace and returns its id when successful.
  Future<String?> create({required String name, String? logoPath}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(workspaceRepositoryProvider);
      final eventBus = ref.read(domainEventBusProvider);
      final filesystem = ref.read(workspaceFilesystemPortProvider);
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        eventBus: eventBus,
        filesystem: filesystem,
      );
      final workspace = await useCase.execute(
        CreateWorkspaceCommand(name: name, logoPath: logoPath),
      );
      await ref.read(activeWorkspaceIdProvider.notifier).setActive(workspace.id);
      state = AsyncData(workspace.id);
      return workspace.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

/// Provider that exposes [CreateWorkspaceNotifier] to the UI.
final createWorkspaceProvider =
    NotifierProvider<CreateWorkspaceNotifier, AsyncValue<String?>>(
      CreateWorkspaceNotifier.new,
    );

