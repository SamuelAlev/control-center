import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/skill_evaluation_observations.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AdmittedSkillEvaluationSnapshot,
        EvaluationCorpus,
        EvaluationRunResult,
        SkillEvaluationSnapshotStore,
        skillEvaluationCorpusById;
import 'package:cc_server_core/src/evals/skill_evaluation_evidence.dart';
import 'package:uuid/uuid.dart';

/// Authority is rechecked for background work, not inherited from an old RPC.
typedef SkillCampaignAuthorization =
    Future<void> Function(
      String workspaceId,
      Principal actor, {
      required bool write,
      String? repoId,
    });

/// An admitted immutable job; only the server composition supplies an executor.
class SkillEvaluationJob {
  /// Captures all immutable inputs and the attempt recorder for one job.
  const SkillEvaluationJob({
    required this.campaign,
    required this.corpus,
    required this.candidate,
    required this.ambient,
    required this.cancellation,
    required this.onAttempt,
    this.previous,
  });

  /// Campaign identity, policy and accounting persisted for this job.
  final SkillEvaluationCampaign campaign;

  /// Trusted task corpus selected at admission.
  final EvaluationCorpus corpus;

  /// Admitted candidate package, unaffected by later source edits.
  final AdmittedSkillEvaluationSnapshot candidate;

  /// Captured baseline for a previous-revision comparison, if selected.
  final AdmittedSkillEvaluationSnapshot? previous;

  /// Other packages held constant during a composition comparison.
  final List<AdmittedSkillEvaluationSnapshot> ambient;

  /// Signals cancellation to the controlled executor.
  final CancellationToken cancellation;

  /// Persists each completed attempt before advancing campaign accounting.
  final Future<void> Function(EvaluationAttempt) onAttempt;
}

/// One deliberately selected intervention. No mutable model/skill defaults.
class SkillEvaluationSettings {
  /// Validates the explicit corpus, model, comparison and spending limit.
  SkillEvaluationSettings({
    required this.skillSlug,
    required this.corpusId,
    required this.providerId,
    required this.modelId,
    required this.comparison,
    required this.repetitions,
    required this.budgetMicros,
    this.adapter = 'builtin',
    this.baselineHash,
    this.repoId,
    this.skillPath,
    this.ambientSkillSlugs = const [],
  }) {
    SkillEvaluationSnapshotStore.validateSlug(skillSlug);
    if (adapter != 'builtin' && adapter != 'claude-cli') {
      throw ArgumentError('Unsupported skill evaluation adapter: $adapter');
    }
    if (corpusId.isEmpty ||
        providerId.isEmpty ||
        modelId.isEmpty ||
        repetitions < 1 ||
        repetitions > 20 ||
        budgetMicros < 1 ||
        budgetMicros > 1000000000) {
      throw ArgumentError(
        'Select a corpus, provider, model, 1–20 repeats and a budget up to USD 1000',
      );
    }
    if (ambientSkillSlugs.length > 32 ||
        ambientSkillSlugs.toSet().length != ambientSkillSlugs.length ||
        ambientSkillSlugs.contains(skillSlug)) {
      throw ArgumentError(
        'Ambient skills must be distinct and exclude the candidate',
      );
    }
    for (final slug in ambientSkillSlugs) {
      SkillEvaluationSnapshotStore.validateSlug(slug);
    }
    if (comparison == SkillEvaluationComparison.previous &&
        baselineHash == null) {
      throw ArgumentError(
        'Previous revision comparison requires baseline_hash',
      );
    }
    if (comparison == SkillEvaluationComparison.composition &&
        ambientSkillSlugs.isEmpty) {
      throw ArgumentError('Composition requires a fixed ambient skill set');
    }
    if (comparison != SkillEvaluationComparison.composition &&
        ambientSkillSlugs.isNotEmpty) {
      throw ArgumentError('Ambient skills require a composition comparison');
    }
  }

  /// Reads the wire configuration, accepting snake-case and camel-case keys.
  factory SkillEvaluationSettings.fromJson(Map<String, dynamic> json) {
    dynamic field(String snake, String camel) => json[snake] ?? json[camel];
    final providerId = field('provider_id', 'providerId') as String;
    final selectedModel = field('model_id', 'modelId') as String;
    return SkillEvaluationSettings(
      skillSlug: field('skill_slug', 'skillSlug') as String,
      corpusId: field('corpus_id', 'corpusId') as String,
      adapter: json['adapter'] as String? ?? 'builtin',
      providerId: providerId,
      modelId: selectedModel.startsWith('$providerId/')
          ? selectedModel.substring(providerId.length + 1)
          : selectedModel,
      comparison: SkillEvaluationComparison.fromWire(
        json['comparison'] as String,
      ),
      repetitions: json['repetitions'] as int,
      budgetMicros: field('budget_micros', 'budgetMicros') as int,
      baselineHash: field('baseline_hash', 'baselineHash') as String?,
      repoId: field('repo_id', 'repoId') as String?,
      skillPath: field('skill_path', 'skillPath') as String?,
      ambientSkillSlugs:
          (field('ambient_skill_slugs', 'ambientSkillSlugs') as List?)
              ?.cast<String>() ??
          const [],
    );
  }

  /// Selected skill and execution backend identifiers.
  final String skillSlug, corpusId, providerId, modelId, adapter;

  /// Intervention used to compare candidate and control attempts.
  final SkillEvaluationComparison comparison;

  /// Number of repeats and maximum charge in millionths of a US dollar.
  final int repetitions, budgetMicros;

  /// Optional baseline revision and repository-scoped skill identity.
  final String? baselineHash, repoId, skillPath;

  /// Fixed neighboring skill slugs for composition comparisons.
  final List<String> ambientSkillSlugs;

  /// Scope-qualified identity used for policy and revision tracking.
  String get skillKey =>
      repoId == null ? 'workspace:$skillSlug' : 'repo:$repoId:$skillPath';

  /// Serializes the pinned settings for campaign storage and hashing.
  Map<String, dynamic> toJson() => {
    'skillSlug': skillSlug,
    'corpusId': corpusId,
    'adapter': adapter,
    'providerId': providerId,
    'modelId': modelId,
    'comparison': comparison.name,
    'repetitions': repetitions,
    'budgetMicros': budgetMicros,
    'baselineHash': baselineHash,
    'repoId': repoId,
    'skillPath': skillPath,
    'ambientSkillSlugs': ambientSkillSlugs,
  };
}

/// Revision-specific campaigns are local server jobs, not fleet git probes.
/// The queue is serial: one campaign cannot contend with another's enclosure.
class SkillEvaluationService {
  /// Creates a serial executor with workspace authorization on every read
  /// and mutation, including background revision reconciliation.
  SkillEvaluationService({
    required this.repository,
    required this.snapshots,
    required this.authorize,
    required this.workspaceExists,
    required this.registeredWorkspaceIds,
    required this.capability,
    required this.validateModel,
    required this.authorizeExecution,
    required this.execute,
    required this.eventBus,
    this.evidence = const SkillEvaluationEvidence(),
    this.onWarning,
    DateTime Function()? now,
    String Function()? newId,
    this.disposeExecutor,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  /// Workspace-scoped storage for campaign, policy and attempt records.
  final EvalsRepository repository;

  /// Captures immutable skill revisions at admission.
  final SkillEvaluationSnapshotStore snapshots;

  /// Rechecks actor access, including optional repository scope.
  final SkillCampaignAuthorization authorize;

  /// Checks registration before opening a workspace's storage.
  final Future<bool> Function(String workspaceId) workspaceExists;

  /// Enumerates registered workspaces for recovery and revision watching.
  final Future<List<String>> Function() registeredWorkspaceIds;

  /// Reports controlled execution availability and supported adapters.
  final Future<Map<String, dynamic>> Function() capability;

  /// Validates and pins an explicit provider model and its charge basis.
  final Future<Map<String, dynamic>> Function(SkillEvaluationSettings settings)
  validateModel;

  /// Rechecks whether an actor may launch paid local execution.
  final Future<void> Function(
    String workspaceId,
    Principal actor,
    bool automatic,
  )
  authorizeExecution;

  /// Runs a captured job and returns its outcome and attempt evidence.
  final Future<EvaluationRunResult> Function(SkillEvaluationJob job) execute;

  /// Publishes skill revision events used by background reconciliation.
  final DomainEventBus eventBus;

  /// Bounds and redacts public attempt and report evidence.
  final SkillEvaluationEvidence evidence;

  /// Receives redacted nonfatal reconciliation and persistence failures.
  final void Function(String message)? onWarning;

  /// Releases process-scoped execution resources after every job has stopped.
  final Future<void> Function()? disposeExecutor;
  final DateTime Function() _now;
  final String Function() _newId;
  final _queue = <SkillEvaluationJob>[];
  final _sources = <String, CancellationTokenSource>{};
  final _mutations = <String, Future<void>>{};
  final _observedRevisions = <String, Map<String, String>>{};
  StreamSubscription<SkillUpdated>? _updates;
  Timer? _repoTimer;
  Future<void>? _draining;
  Future<void> _revisionWork = Future<void>.value();
  bool _stopping = false;

  /// Restore truthful lifecycle after restart; never silently resume spending.
  Future<void> start() async {
    // CROSS-WORKSPACE BY DESIGN: boot recovery visits registered workspace IDs,
    // then uses only that workspace's repository. No candidate content is read.
    for (final workspaceId in await registeredWorkspaceIds()) {
      if (!await workspaceExists(workspaceId)) {
        continue;
      }
      for (final campaign in await repository.skillCampaigns(
        workspaceId,
        limit: 100000,
      )) {
        if (!campaign.isTerminal) {
          await repository.upsertSkillCampaign(
            campaign.copyWith(
              status: SkillEvaluationCampaignStatus.interrupted,
              finishedAt: _now(),
              error: 'Server stopped before this campaign finished.',
              clearSpentMicros:
                  campaign.status != SkillEvaluationCampaignStatus.queued,
            ),
          );
        }
      }
    }
    _updates = eventBus.on<SkillUpdated>().listen((event) {
      _scheduleRevision(
        () => _changed(
          event.workspaceId,
          'workspace:${event.slug}',
          event.computedHash,
        ),
      );
    });
    // Repo catalogs do not publish SkillUpdated. Reconcile only explicitly
    // enabled policies and prior campaign scopes, with live actor authorization.
    _repoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(refreshRevisions());
    });
    unawaited(refreshRevisions());
  }

  /// Reconciles registered revision scopes and waits for earlier watcher work.
  /// CROSS-WORKSPACE BY DESIGN: only explicitly authorized historical scopes
  /// and opted-in policies are visited; this never enables a policy.
  Future<void> refreshRevisions() {
    _scheduleRevision(_reconcileRepositories);
    return _revisionWork;
  }

  void _scheduleRevision(Future<void> Function() work) {
    if (_stopping) {
      return;
    }
    _revisionWork = _revisionWork.then((_) => work()).catchError((
      Object error,
    ) {
      onWarning?.call(
        'Skill evaluation revision reconciliation: ${_safeError(error)}',
      );
    });
  }

  /// Admits and queues a pinned evaluation after rechecking actor, policy,
  /// model and spending authority; [automatic] requires an enabled policy.
  Future<SkillEvaluationCampaign> launch({
    required String workspaceId,
    required Principal actor,
    required SkillEvaluationSettings settings,
    bool automatic = false,
  }) async {
    if (_stopping) {
      throw StateError('Evaluation service is stopping');
    }
    await authorize(workspaceId, actor, write: true, repoId: settings.repoId);
    final automaticPolicy = automatic
        ? await _checkAutomaticPolicy(workspaceId, settings, actor: actor)
        : null;
    await authorizeExecution(workspaceId, actor, automatic);
    final caps = await capability();
    if (caps['available'] != true) {
      throw StateError(
        caps['reason'] as String? ?? 'Controlled execution is unavailable',
      );
    }
    if (!(caps['backends'] as List? ?? const []).contains(settings.adapter)) {
      final reasons = caps['unavailableBackends'] as Map? ?? const {};
      throw StateError(
        reasons[settings.adapter] as String? ??
            'The selected skill evaluation adapter is unavailable',
      );
    }
    final modelPin = await validateModel(settings);
    final corpus = skillEvaluationCorpusById(settings.corpusId);
    if (corpus == null) {
      throw ArgumentError('Unknown trusted skill evaluation corpus');
    }
    final candidate = await snapshots.capture(
      workspaceId: workspaceId,
      slug: settings.skillSlug,
      repoId: settings.repoId,
      skillPath: settings.skillPath,
    );
    final previous = settings.comparison == SkillEvaluationComparison.previous
        ? await snapshots.previous(
            workspaceId: workspaceId,
            skillKey: candidate.skillKey,
            hash: settings.baselineHash!,
          )
        : null;
    if (settings.comparison == SkillEvaluationComparison.previous &&
        previous == null) {
      throw StateError(
        'That baseline revision has not been captured for this skill',
      );
    }
    final ambient = <AdmittedSkillEvaluationSnapshot>[];
    for (final slug in settings.ambientSkillSlugs) {
      ambient.add(
        await snapshots.capture(workspaceId: workspaceId, slug: slug),
      );
    }
    final configuration = <String, dynamic>{
      ...settings.toJson(),
      'candidate': candidate.identity,
      'previous': previous?.identity,
      'ambient': [for (final item in ambient) item.identity],
      'corpusHash': corpus.corpusHash,
      'protocolVersion': 'cc-skill/1',
      'modelPin': modelPin,
      'executor': settings.adapter,
      'alpha': 0.05,
      'nonInferiorityMargin': 0.05,
      'executionCapability': caps,
      if (automaticPolicy != null)
        'policyRevision': _policyRevision(automaticPolicy),
    };
    final configurationHash = canonicalHash(configuration);
    final id = automatic
        ? 'auto-${canonicalHash({'workspaceId': workspaceId, 'skillKey': candidate.skillKey, 'configurationHash': configurationHash})}'
        : _newId();
    if (automatic) {
      final existing = await repository.skillCampaignById(workspaceId, id);
      if (existing != null) {
        return existing;
      }
    }
    final campaign = SkillEvaluationCampaign(
      id: id,
      workspaceId: workspaceId,
      skillKey: candidate.skillKey,
      skillSlug: settings.skillSlug,
      skillHash: candidate.package.packageHash,
      baselineHash: previous?.package.packageHash,
      repoId: settings.repoId,
      corpusId: corpus.id,
      providerId: settings.providerId,
      modelId: settings.modelId,
      configurationHash: configurationHash,
      comparison: settings.comparison,
      status: SkillEvaluationCampaignStatus.queued,
      repetitions: settings.repetitions,
      budgetMicros: settings.budgetMicros,
      plannedAttempts: corpus.tasks.length * settings.repetitions * 2,
      completedAttempts: 0,
      spentMicros: 0,
      createdAt: _now(),
      actor: actor,
      triggeredBy: automatic ? 'skill_update' : 'manual',
      configuration: configuration,
    );
    if (_stopping) {
      throw StateError('Evaluation service is stopping');
    }
    await authorize(workspaceId, actor, write: true, repoId: settings.repoId);
    if (automaticPolicy != null) {
      await _checkAutomaticPolicy(
        workspaceId,
        settings,
        actor: actor,
        expectedRevision: _policyRevision(automaticPolicy),
      );
    }
    await repository.upsertSkillCampaign(campaign);
    // A watcher may have finished invalidating an older capture before this
    // row existed. Recheck after insertion so that race cannot bless stale data.
    await _checkCapturedRevisions(campaign, [candidate, ...ambient]);
    if (_stopping) {
      return _change(
        workspaceId,
        id,
        (current) => current.copyWith(
          status: SkillEvaluationCampaignStatus.interrupted,
          finishedAt: _now(),
          error: 'Server stopped during campaign admission.',
        ),
      );
    }
    final source = CancellationTokenSource();
    _sources[id] = source;
    _queue.add(
      SkillEvaluationJob(
        campaign: campaign,
        corpus: corpus,
        candidate: candidate,
        previous: previous,
        ambient: ambient,
        cancellation: source.token,
        onAttempt: (attempt) => _recordAttempt(campaign, attempt, source.token),
      ),
    );
    _startQueuedWork();
    return (await repository.skillCampaignById(workspaceId, id))!;
  }

  void _startQueuedWork() {
    if (_draining != null || _queue.isEmpty) {
      return;
    }
    _draining = _drain().whenComplete(() {
      _draining = null;
      // Admission may enqueue between the drain's final check and this callback.
      _startQueuedWork();
    });
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      final campaign = job.campaign;
      try {
        job.cancellation.throwIfCancelled();
        await authorize(
          campaign.workspaceId,
          campaign.actor,
          write: true,
          repoId: campaign.repoId,
        );
        if (campaign.triggeredBy != 'manual') {
          await _checkAutomaticPolicy(
            campaign.workspaceId,
            SkillEvaluationSettings.fromJson(campaign.configuration),
            actor: campaign.actor,
            expectedRevision:
                campaign.configuration['policyRevision'] as String,
          );
        }
        await authorizeExecution(
          campaign.workspaceId,
          campaign.actor,
          campaign.triggeredBy != 'manual',
        );
        await _change(
          campaign.workspaceId,
          campaign.id,
          (current) => current.copyWith(
            status: SkillEvaluationCampaignStatus.running,
            startedAt: _now(),
          ),
        );
        final result = await execute(job);
        final report = result.report.toJson()..remove('attempts');
        report['skillBehavior'] = summarizeSkillObservations(
          tasks: job.corpus.tasks,
          attempts: result.report.attempts,
          candidateSkillHash: campaign.skillHash,
          baselineSkillHash: campaign.baselineHash,
        );
        await _change(
          campaign.workspaceId,
          campaign.id,
          (current) => current.copyWith(
            status: _stopping
                ? SkillEvaluationCampaignStatus.interrupted
                : job.cancellation.isCancelled
                ? SkillEvaluationCampaignStatus.cancelled
                : result.report.coverageComplete
                ? SkillEvaluationCampaignStatus.completed
                : SkillEvaluationCampaignStatus.failed,
            finishedAt: _now(),
            report: _stopping || job.cancellation.isCancelled
                ? null
                : evidence.project(report),
            error:
                result.report.coverageComplete || job.cancellation.isCancelled
                ? null
                : 'The attempt budget or execution stopped before planned coverage.',
          ),
        );
      } on Object catch (error) {
        try {
          await _change(campaign.workspaceId, campaign.id, (current) {
            if (current.isTerminal) {
              return current;
            }
            return current.copyWith(
              status: _stopping
                  ? SkillEvaluationCampaignStatus.interrupted
                  : job.cancellation.isCancelled
                  ? SkillEvaluationCampaignStatus.cancelled
                  : SkillEvaluationCampaignStatus.failed,
              finishedAt: _now(),
              error: _safeError(error),
              clearSpentMicros:
                  current.status != SkillEvaluationCampaignStatus.queued,
            );
          });
        } on Object catch (persistenceError) {
          // A deleted workspace must never be reopened to record a failure.
          onWarning?.call(
            'Campaign could not be finalized: ${_safeError(persistenceError)}',
          );
        }
      } finally {
        _sources.remove(campaign.id);
      }
    }
  }

  Future<void> _recordAttempt(
    SkillEvaluationCampaign campaign,
    EvaluationAttempt attempt,
    CancellationToken cancellation,
  ) async {
    await authorize(
      campaign.workspaceId,
      campaign.actor,
      write: true,
      repoId: campaign.repoId,
    );
    await repository.upsertSkillAttempt(
      SkillEvaluationAttemptRecord(
        id: attempt.attemptId,
        workspaceId: campaign.workspaceId,
        campaignId: campaign.id,
        taskId: attempt.taskId,
        armId: attempt.armId,
        repetition: attempt.repetition,
        ordinal: attempt.ordinal,
        evidence: evidence.attempt(attempt.toJson()),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          attempt.startedAtEpochMs,
          isUtc: true,
        ),
      ),
    );
    await _change(campaign.workspaceId, campaign.id, (current) {
      final cost = attempt.attemptCostMicros;
      return current.copyWith(
        status: cancellation.isCancelled
            ? SkillEvaluationCampaignStatus.cancelling
            : current.status,
        completedAttempts: current.completedAttempts + 1,
        spentMicros: current.spentMicros == null || cost == null
            ? null
            : current.spentMicros! + cost,
        clearSpentMicros: current.spentMicros == null || cost == null,
      );
    });
  }

  /// Cancels a workspace campaign, preserving terminal outcomes.
  Future<SkillEvaluationCampaign> cancel(
    String workspaceId,
    Principal actor,
    String id,
  ) async {
    final current = await get(workspaceId, actor, id, write: true);
    if (current.isTerminal) {
      return current;
    }
    _sources[id]?.cancel('Operator cancelled campaign');
    return _change(
      workspaceId,
      id,
      (latest) => latest.isTerminal
          ? latest
          : latest.copyWith(
              status: latest.status == SkillEvaluationCampaignStatus.queued
                  ? SkillEvaluationCampaignStatus.cancelled
                  : SkillEvaluationCampaignStatus.cancelling,
              finishedAt: latest.status == SkillEvaluationCampaignStatus.queued
                  ? _now()
                  : null,
            ),
    );
  }

  /// Returns an authorized workspace campaign, with repository access checked
  /// after its repository scope is read from storage.
  Future<SkillEvaluationCampaign> get(
    String workspaceId,
    Principal actor,
    String id, {
    bool write = false,
  }) async {
    await authorize(workspaceId, actor, write: write);
    final campaign = await repository.skillCampaignById(workspaceId, id);
    if (campaign == null) {
      throw StateError('Unknown workspace campaign');
    }
    await authorize(workspaceId, actor, write: write, repoId: campaign.repoId);
    return campaign;
  }

  /// Streams campaigns visible to [actor], filtering each repository-scoped
  /// row against the actor's current grants.
  Stream<List<SkillEvaluationCampaign>> watch(
    String workspaceId,
    Principal actor, {
    String? skillKey,
  }) async* {
    await authorize(workspaceId, actor, write: false);
    await for (final rows in repository.watchSkillCampaigns(
      workspaceId,
      skillKey: skillKey,
    )) {
      await authorize(workspaceId, actor, write: false);
      final visible = <SkillEvaluationCampaign>[];
      for (final row in rows) {
        if (await _canRead(row, actor)) {
          visible.add(row);
        }
      }
      yield visible;
    }
  }

  /// Streams one campaign, rechecking authorization for every update.
  Stream<SkillEvaluationCampaign?> watchOne(
    String workspaceId,
    Principal actor,
    String id,
  ) async* {
    await get(workspaceId, actor, id);
    await for (final row in repository.watchSkillCampaign(workspaceId, id)) {
      await authorize(workspaceId, actor, write: false, repoId: row?.repoId);
      yield row;
    }
  }

  Future<bool> _canRead(
    SkillEvaluationCampaign campaign,
    Principal actor,
  ) async {
    try {
      await authorize(
        campaign.workspaceId,
        actor,
        write: false,
        repoId: campaign.repoId,
      );
      return true;
    } on Object {
      // Fail closed for this row: a stale grant must never leak repo evidence.
      return false;
    }
  }

  /// Lists attempt identities and accounting without their full evidence.
  Future<List<SkillEvaluationAttemptRecord>> attempts(
    String workspaceId,
    Principal actor,
    String id,
  ) async {
    await get(workspaceId, actor, id);
    final rows = await repository.skillAttempts(workspaceId, id);
    // The list drives navigation; fetch bounded evidence only for the selected
    // attempt instead of shipping every trace in one websocket message.
    return [
      for (final row in rows)
        SkillEvaluationAttemptRecord(
          id: row.id,
          workspaceId: row.workspaceId,
          campaignId: row.campaignId,
          taskId: row.taskId,
          armId: row.armId,
          repetition: row.repetition,
          ordinal: row.ordinal,
          evidence: const {},
          createdAt: row.createdAt,
        ),
    ];
  }

  /// Loads a single attempt's bounded evidence after campaign authorization.
  Future<SkillEvaluationAttemptRecord> attempt(
    String workspaceId,
    Principal actor,
    String campaignId,
    String id,
  ) async {
    await get(workspaceId, actor, campaignId);
    final record = await repository.skillAttemptById(
      workspaceId,
      campaignId,
      id,
    );
    if (record == null) {
      throw StateError('Unknown campaign attempt');
    }
    return record;
  }

  /// Exports bounded, redacted campaign and attempt evidence as JSON content.
  Future<Map<String, dynamic>> export(
    String workspaceId,
    Principal actor,
    String id,
  ) async {
    final campaign = await get(workspaceId, actor, id);
    final rows = await repository.skillAttempts(workspaceId, id);
    return {
      'filename': 'skill-evaluation-${campaign.id}.json',
      'content': evidence.export({
        'format': 'cc-skill-evaluation/1',
        'campaign': campaign.toJson(),
        'attemptCount': rows.length,
        'attempts': rows.map((row) => row.toJson()),
      }),
    };
  }

  /// Returns the policy for an authorized workspace or repository skill.
  Future<SkillEvaluationPolicy?> policy(
    String workspaceId,
    Principal actor,
    String skillKey,
  ) async {
    await authorize(
      workspaceId,
      actor,
      write: false,
      repoId: _repoForKey(skillKey),
    );
    return repository.skillPolicy(workspaceId, skillKey);
  }

  /// Saves opt-in policy configuration without launching a campaign.
  Future<SkillEvaluationPolicy> setPolicy(
    String workspaceId,
    Principal actor,
    String skillKey,
    bool enabled,
    Map<String, dynamic> configuration,
  ) async {
    await authorize(
      workspaceId,
      actor,
      write: true,
      repoId: _repoForKey(skillKey),
    );
    final settings = SkillEvaluationSettings.fromJson(configuration);
    if (settings.skillKey != skillKey) {
      throw ArgumentError('Policy skill identity mismatch');
    }
    if (skillEvaluationCorpusById(settings.corpusId) == null) {
      throw ArgumentError('Unknown corpus');
    }
    final observed = <String, String>{};
    if (enabled) {
      await validateModel(settings);
      for (final scope in _scopes(settings)) {
        final captured = await snapshots.capture(
          workspaceId: workspaceId,
          slug: scope.slug,
          repoId: scope.repoId,
          skillPath: scope.path,
        );
        observed[captured.skillKey] = captured.package.packageHash;
      }
    }
    final value = SkillEvaluationPolicy(
      workspaceId: workspaceId,
      skillKey: skillKey,
      enabled: enabled,
      actor: actor,
      configuration: {
        ...settings.toJson(),
        'observedRevisions': observed,
        'policyRevision': _newId(),
      },
      updatedAt: _now(),
    );
    await _updatePolicy(workspaceId, skillKey, (_) => value);
    if (!enabled) {
      for (final campaign in await repository.skillCampaigns(
        workspaceId,
        skillKey: skillKey,
        limit: 100000,
      )) {
        if (!campaign.isTerminal && campaign.triggeredBy != 'manual') {
          _sources[campaign.id]?.cancel(
            'Automatic evaluation policy was disabled',
          );
        }
      }
    }
    // Saving a policy is not an execution request. Only a later revision event
    // may spend its explicit budget; content+configuration addresses dedupe it.
    return value;
  }

  static String? _repoForKey(String key) {
    if (key.startsWith('workspace:')) {
      SkillEvaluationSnapshotStore.validateSlug(key.substring(10));
      return null;
    }
    if (!key.startsWith('repo:')) {
      throw ArgumentError('Invalid skill scope');
    }
    final separator = key.indexOf(':', 5);
    if (separator <= 5 || separator == key.length - 1) {
      throw ArgumentError('Invalid skill scope');
    }
    return key.substring(5, separator);
  }

  Future<void> _changed(
    String workspaceId,
    String skillKey,
    String currentHash,
  ) async {
    if (!await workspaceExists(workspaceId)) {
      return;
    }
    final observed = _observedRevisions.putIfAbsent(workspaceId, () => {});
    observed[skillKey] = currentHash;
    for (final campaign in await repository.skillCampaigns(
      workspaceId,
      limit: 100000,
    )) {
      final dependencies = _dependencies(campaign);
      if (!dependencies.containsKey(skillKey)) {
        continue;
      }
      final mismatch = dependencies.entries.any(
        (entry) =>
            observed[entry.key] != null && observed[entry.key] != entry.value,
      );
      final allCurrent = dependencies.entries.every(
        (entry) => observed[entry.key] == entry.value,
      );
      if (mismatch && campaign.staleReason == null ||
          allCurrent && campaign.staleReason != null) {
        await _change(
          workspaceId,
          campaign.id,
          (current) => current.copyWith(
            staleReason: mismatch
                ? 'A current skill dependency differs from this campaign.'
                : null,
            clearStaleReason: allCurrent,
          ),
        );
      }
    }
    for (final policy in await repository.enabledSkillPolicies(workspaceId)) {
      try {
        final settings = SkillEvaluationSettings.fromJson(policy.configuration);
        if (!_scopes(settings).any((scope) => scope.key == skillKey) ||
            _stopping) {
          continue;
        }
        final checkpoint =
            policy.configuration['observedRevisions'] as Map? ?? const {};
        if (checkpoint[skillKey] == currentHash) {
          continue;
        }
        // Initial checkpoints do not spend. Only later changes can launch.
        if (checkpoint[skillKey] != null) {
          await launch(
            workspaceId: workspaceId,
            actor: policy.actor,
            settings: settings,
            automatic: true,
          );
        }
        await _updatePolicy(workspaceId, policy.skillKey, (current) {
          if (current == null ||
              !current.enabled ||
              _policyRevision(current) != _policyRevision(policy)) {
            return null;
          }
          return SkillEvaluationPolicy(
            workspaceId: workspaceId,
            skillKey: current.skillKey,
            enabled: true,
            actor: current.actor,
            updatedAt: current.updatedAt,
            configuration: {
              ...current.configuration,
              'observedRevisions': <String, dynamic>{
                ...?current.configuration['observedRevisions']
                    as Map<String, dynamic>?,
                skillKey: currentHash,
              },
            },
          );
        });
      } on Object catch (error) {
        // A revoked actor or invalid model must not starve another opted-in
        // policy sharing this dependency.
        onWarning?.call(
          'Automatic skill evaluation was not admitted: ${_safeError(error)}',
        );
      }
    }
  }

  Future<void> _reconcileRepositories() async {
    // CROSS-WORKSPACE BY DESIGN: explicitly opted-in policies and historical
    // scopes only. This also catches workspace edits missed during admission.
    for (final workspaceId in await registeredWorkspaceIds()) {
      if (!await workspaceExists(workspaceId)) {
        continue;
      }
      final seen = <String>{};
      final campaigns = await repository.skillCampaigns(
        workspaceId,
        limit: 100000,
      );
      final policies = await repository.enabledSkillPolicies(workspaceId);
      final specs = <(Principal, Map<String, dynamic>)>[
        for (final policy in policies) (policy.actor, policy.configuration),
        for (final campaign in campaigns)
          (campaign.actor, campaign.configuration),
      ];
      for (final (actor, config) in specs) {
        for (final scope in _scopes(SkillEvaluationSettings.fromJson(config))) {
          if (seen.contains(scope.key)) {
            continue;
          }
          try {
            await authorize(
              workspaceId,
              actor,
              write: false,
              repoId: scope.repoId,
            );
            final current = await snapshots.capture(
              workspaceId: workspaceId,
              slug: scope.slug,
              repoId: scope.repoId,
              skillPath: scope.path,
            );
            seen.add(scope.key);
            await _changed(
              workspaceId,
              current.skillKey,
              current.package.packageHash,
            );
          } on Object catch (error) {
            onWarning?.call(
              'Skill evaluation reconciliation: ${_safeError(error)}',
            );
          }
        }
      }
    }
  }

  static List<({String key, String slug, String? repoId, String? path})>
  _scopes(SkillEvaluationSettings settings) => [
    (
      key: settings.skillKey,
      slug: settings.skillSlug,
      repoId: settings.repoId,
      path: settings.skillPath,
    ),
    for (final slug in settings.ambientSkillSlugs)
      (key: 'workspace:$slug', slug: slug, repoId: null, path: null),
  ];

  static Map<String, String> _dependencies(SkillEvaluationCampaign campaign) =>
      {
        campaign.skillKey: campaign.skillHash,
        for (final identity
            in campaign.configuration['ambient'] as List? ?? const [])
          if (identity is Map &&
              identity['skillKey'] is String &&
              identity['packageHash'] is String)
            identity['skillKey'] as String: identity['packageHash'] as String,
      };

  static String _policyRevision(SkillEvaluationPolicy policy) =>
      policy.configuration['policyRevision'] as String? ??
      canonicalHash({
        'actor': policy.actor.wire,
        'updatedAt': policy.updatedAt.toIso8601String(),
      });

  Future<SkillEvaluationPolicy> _checkAutomaticPolicy(
    String workspaceId,
    SkillEvaluationSettings settings, {
    required Principal actor,
    String? expectedRevision,
  }) async {
    final policy = await repository.skillPolicy(workspaceId, settings.skillKey);
    if (policy == null ||
        !policy.enabled ||
        policy.actor != actor ||
        expectedRevision != null &&
            _policyRevision(policy) != expectedRevision ||
        canonicalHash(
              SkillEvaluationSettings.fromJson(policy.configuration).toJson(),
            ) !=
            canonicalHash(settings.toJson())) {
      throw StateError(
        'The automatic evaluation policy is no longer enabled with this configuration',
      );
    }
    return policy;
  }

  Future<void> _checkCapturedRevisions(
    SkillEvaluationCampaign campaign,
    List<AdmittedSkillEvaluationSnapshot> captured,
  ) async {
    for (final original in captured) {
      try {
        final current = await snapshots.capture(
          workspaceId: campaign.workspaceId,
          slug: original.package.slug,
          repoId: original.package.repoId,
          skillPath: original.skillPath,
        );
        if (current.package.packageHash == original.package.packageHash) {
          continue;
        }
      } on Object {
        // Unreadable/quarantined current content cannot certify an old capture.
      }
      await _change(
        campaign.workspaceId,
        campaign.id,
        (current) => current.copyWith(
          staleReason:
              'The skill dependency changed while this campaign was being admitted.',
        ),
      );
      return;
    }
  }

  Future<SkillEvaluationCampaign> _change(
    String workspaceId,
    String id,
    SkillEvaluationCampaign Function(SkillEvaluationCampaign) update,
  ) => _serializeMutation('$workspaceId\u0000campaign\u0000$id', () async {
    if (!await workspaceExists(workspaceId)) {
      throw StateError('Workspace is no longer registered');
    }
    final current = await repository.skillCampaignById(workspaceId, id);
    if (current == null) {
      throw StateError('Campaign disappeared during execution');
    }
    final next = update(current);
    await repository.upsertSkillCampaign(next);
    return next;
  });

  Future<SkillEvaluationPolicy?> _updatePolicy(
    String workspaceId,
    String skillKey,
    SkillEvaluationPolicy? Function(SkillEvaluationPolicy?) update,
  ) => _serializeMutation('$workspaceId\u0000policy\u0000$skillKey', () async {
    if (!await workspaceExists(workspaceId)) {
      throw StateError('Workspace is no longer registered');
    }
    final next = update(await repository.skillPolicy(workspaceId, skillKey));
    if (next != null) {
      await repository.upsertSkillPolicy(next);
    }
    return next;
  });

  Future<T> _serializeMutation<T>(String key, Future<T> Function() work) async {
    final previous = _mutations[key] ?? Future<void>.value();
    final result = previous
        .then((_) {}, onError: (Object _, StackTrace _) {})
        .then((_) => work());
    final barrier = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _mutations[key] = barrier;
    try {
      return await result;
    } finally {
      if (identical(_mutations[key], barrier)) {
        unawaited(_mutations.remove(key));
      }
    }
  }

  String _safeError(Object error) =>
      evidence.project({'error': error.toString()})['error'] as String;

  /// Stops watchers, cancels queued and active jobs, then releases executor
  /// resources once pending mutations and running work have settled.
  Future<void> dispose() async {
    _stopping = true;
    _repoTimer?.cancel();
    await _updates?.cancel();
    for (final source in _sources.values) {
      source.cancel('Server is stopping');
    }
    await _revisionWork;
    while (_draining != null) {
      await _draining;
    }
    await disposeExecutor?.call();
  }
}
