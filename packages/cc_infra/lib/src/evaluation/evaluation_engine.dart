import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/evaluation/backends/replay_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_benchmark_bridge.dart';
import 'package:cc_infra/src/evaluation/evaluation_verifier_runner.dart';
import 'package:cc_infra/src/evaluation/isolated_task_workspace.dart';
import 'package:path/path.dart' as p;

/// Progress sink for the run loop.
typedef EvaluationProgressCallback = void Function(String message);

/// Everything one campaign needs.
class EvaluationEngineConfig {
  /// Creates an [EvaluationEngineConfig].
  const EvaluationEngineConfig({
    required this.corpus,
    required this.manifest,
    required this.plan,
    required this.backend,
    required this.outDir,
    this.fixtureDirectory,
    this.onlyTaskId,
    this.onlyArmId,
    this.maxAttempts,
    this.keepWorkspaces = false,
    this.dryRun = false,
    this.onProgress,
    this.now,
    this.cancelled,
    this.cancellation,
    this.onAttempt,
    this.prepareWorkspace,
    this.validateWorkspace,
    this.controlled = false,
  });

  /// The tasks to run.
  final EvaluationCorpus corpus;

  /// The pinned reproducibility manifest.
  final EvaluationManifest manifest;

  /// The campaign plan (arms, strata, seed, gates).
  final EvaluationPlan plan;

  /// The adapter under test. A [ReplayEvaluationBackend] switches the campaign
  /// to offline replay.
  final EvaluationBackendPort backend;

  /// Base directory for the run's artifacts.
  final String outDir;

  /// Base directory a task's `fixtureRef` resolves against (a fixture
  /// repository the runner clones — never the live source checkout).
  final String? fixtureDirectory;

  /// Restrict to one task id.
  final String? onlyTaskId;

  /// Restrict to one arm id.
  final String? onlyArmId;

  /// Stop after this many trials (a smoke-run affordance).
  final int? maxAttempts;

  /// Leave workspaces on disk for inspection.
  final bool keepWorkspaces;

  /// Print the schedule and stop before executing anything.
  final bool dryRun;

  /// Progress sink.
  final EvaluationProgressCallback? onProgress;

  /// Clock override (determinism in tests).
  final DateTime Function()? now;

  /// Checked before scheduling and after each paid attempt.
  final bool Function()? cancelled;

  /// Actively interrupts contained setup, tools and verifier subprocesses.
  final CancellationToken? cancellation;

  /// Receives a fully verified attempt before the next attempt is scheduled.
  final Future<void> Function(EvaluationAttempt attempt)? onAttempt;

  /// Prepares contained workspace assets before handing control to the agent.
  final Future<void> Function(EvaluationAttemptRequest request)?
  prepareWorkspace;

  /// Disables host-executed fixture setup and git commands after agent access.
  final bool controlled;

  /// Called after the agent stops to attest mounted immutable assets.
  final Future<List<String>> Function(EvaluationAttemptRequest request)?
  validateWorkspace;
}

/// The result of one campaign.
class EvaluationRunResult {
  /// Creates an [EvaluationRunResult].
  const EvaluationRunResult({
    required this.report,
    required this.benchmark,
    required this.artifacts,
    required this.trials,
  });

  /// The paired analysis.
  final EvaluationReport report;

  /// The same attempts projected onto the existing benchmark value objects.
  final BenchmarkRun benchmark;

  /// Where everything was written.
  final EvaluationArtifacts artifacts;

  /// The scheduled trials that ran (or would run, in a dry run).
  final List<EvaluationTrial> trials;
}

/// Executes a paired evaluation campaign: real isolated workspaces, real
/// backends, real independent verification, auditable artifacts.
///
/// The engine refuses to run a plan that could silently replace a user-selected
/// quality default (see [EvaluationPlan.violations]) and refuses to pair a
/// manifest with a corpus it does not describe. Everything else it *records*
/// rather than refuses: a faulted attempt is an error attempt, an unverifiable
/// attempt is an unverified one, and both are reported as such.
class EvaluationEngine {
  /// Creates an [EvaluationEngine].
  EvaluationEngine({
    required this.config,
    this.verifierRunner = const EvaluationVerifierRunner(),
    this.bridge = const EvaluationBenchmarkBridge(),
  });

  /// The campaign configuration.
  final EvaluationEngineConfig config;

  /// The behavioral verifier runner.
  final EvaluationVerifierRunner verifierRunner;

  /// The benchmark projection.
  final EvaluationBenchmarkBridge bridge;

  /// Runs the campaign.
  Future<EvaluationRunResult> run() async {
    final corpus = config.corpus;
    final plan = config.plan;
    _validate(corpus, plan);

    final selectedTasks = [
      for (final task in corpus.tasks)
        if (config.onlyTaskId == null || task.id == config.onlyTaskId) task,
    ];
    if (selectedTasks.isEmpty) {
      throw StateError('no corpus task matches "${config.onlyTaskId}"');
    }

    final replaying = config.backend is ReplayEvaluationBackend;
    final trials = [
      for (final trial in plan.schedule(
        selectedTasks,
        executionMode: replaying
            ? EvaluationExecutionMode.offlineReplay
            : EvaluationExecutionMode.live,
      ))
        if (config.onlyArmId == null || trial.armId == config.onlyArmId) trial,
    ];
    final limited = config.maxAttempts == null
        ? trials
        : trials.take(config.maxAttempts!).toList();

    // Preflight BEFORE anything is spent: an arm whose experimental policy this
    // backend cannot actually execute must be refused, never run as the default
    // and reported as if the policy had applied.
    _refuseUnimplementableArms(limited, plan, corpus);

    final artifacts = await EvaluationArtifacts.create(
      config.outDir,
      plan.id,
      now: config.now?.call(),
    );
    await artifacts.writeManifest(config.manifest);
    await artifacts.writePlan(plan);
    await artifacts.writeCorpus(corpus);
    _progress(
      'run directory ${artifacts.runDir} · '
      '${limited.length} trial(s) · mode ${replaying ? 'offline replay' : 'live'}',
    );

    // The paired arms deliberately share one provider cache, and only the
    // operator can know which account served them: record it rather than
    // pretending the strata are independent.
    final planned = plan.withAdditionalCaveats([
      if (plan.arms.length > 1)
        const EvaluationCaveat(
          code: 'paired_cache_carryover',
          message:
              'Arms of a pair share one provider prompt cache: within a '
              'stratum the second run of a prompt starts warmer than the '
              'first, so a within-pair cost difference can reflect cache order '
              'rather than the arm. The trial order is randomized per stratum '
              'to spread this.',
        ),
      if (plan.arms.length > 1)
        const EvaluationCaveat(
          code: 'account_attribution_unobserved',
          message:
              'Which account/quota served each attempt is not observable from '
              'this harness; per-attempt cost roles may mix subscription and '
              'billed bases.',
        ),
    ]);

    final attempts = <EvaluationAttempt>[];
    final extraUnknowns = <String>[];
    // The first observed tool surface per adapter is the campaign's canonical
    // surface: a later attempt that reports a different one is not comparable
    // with it, which a manifest pin alone cannot detect for a native CLI.
    final observedSurfaces = <String, String>{};
    if (!config.dryRun) {
      for (final stratum in CacheStratum.values) {
        final bucket = [
          for (final trial in limited)
            if (trial.stratum == stratum) trial,
        ];
        if (bucket.isEmpty) {
          continue;
        }
        final spec = _stratumSpec(plan, stratum);
        final idle = spec?.idleFor;
        if (stratum == CacheStratum.postIdle &&
            idle != null &&
            idle > Duration.zero) {
          _progress('idling ${idle.inMinutes} min before post-idle stratum');
          await Future<void>.delayed(idle);
        }
        for (final trial in bucket) {
          if (config.cancelled?.call() ?? false) break;
          final attempt = await _runTrial(
            trial: trial,
            corpus: corpus,
            plan: planned,
            artifacts: artifacts,
            extraUnknowns: extraUnknowns,
            observedSurfaces: observedSurfaces,
          );
          attempts.add(attempt);
          await config.onAttempt?.call(attempt);
        }
      }
    } else {
      for (final trial in limited) {
        _progress(
          '${trial.ordinal}. ${trial.taskId} · ${trial.armId} · '
          '${trial.stratum.wire} · rep ${trial.repetition} · seed ${trial.seed}',
        );
      }
    }

    final report = const EvaluationReportBuilder().build(
      manifest: config.manifest,
      plan: planned,
      tasks: selectedTasks,
      attempts: attempts,
      generatedAtEpochMs:
          (config.now?.call() ?? DateTime.now()).millisecondsSinceEpoch,
      extraUnknowns: extraUnknowns,
    );
    await artifacts.writeReport(report);
    _progress(
      'report: ${report.overallRecommendation.label} · '
      '${report.attempts.length} attempt(s)',
    );

    final benchmark = bridge.toBenchmarkRun(report);
    return EvaluationRunResult(
      report: report,
      benchmark: benchmark,
      artifacts: artifacts,
      trials: limited,
    );
  }

  void _validate(EvaluationCorpus corpus, EvaluationPlan plan) {
    if (!corpus.idsAreUnique) {
      throw StateError('corpus "${corpus.id}" has duplicate task ids');
    }
    if (config.backend.callsModel && config.manifest.modelId.trim().isEmpty) {
      throw StateError(
        'the manifest pins no model, so a live run would silently use the '
        'provider default',
      );
    }
    if (config.manifest.corpusHash.isNotEmpty &&
        config.manifest.corpusHash != corpus.corpusHash) {
      throw StateError(
        'manifest corpusHash ${config.manifest.corpusHash} does not match the '
        'corpus (${corpus.corpusHash}) — the campaign would not be reproducible',
      );
    }
    final violations = plan.violations(corpus.tasks);
    if (violations.isNotEmpty) {
      throw StateError(
        'refusing to run an unsafe plan:\n- ${violations.join('\n- ')}',
      );
    }
  }

  /// Refuses the campaign when any scheduled arm asks for behaviour this
  /// backend cannot execute.
  ///
  /// Grouped by (arm, effective config) so the message names the arm and the
  /// exact policy rather than one line per trial.
  void _refuseUnimplementableArms(
    List<EvaluationTrial> trials,
    EvaluationPlan plan,
    EvaluationCorpus corpus,
  ) {
    final refusals = <String>{};
    for (final trial in trials) {
      final task = corpus.taskById(trial.taskId);
      final arm = _armById(plan, trial.armId);
      if (task == null || arm == null) {
        continue;
      }
      final effective = _routeFor(task, arm, plan).effective;
      final reason = config.backend.unsupportedReason(effective);
      if (reason != null) {
        refusals.add('arm "${arm.id}" (${effective.label}): $reason');
      }
    }
    if (refusals.isEmpty) {
      return;
    }
    throw StateError(
      'refusing to run ${refusals.length} unimplementable arm(s) — nothing was '
      'spent:\n- ${refusals.join('\n- ')}',
    );
  }

  /// How many authoritative checks this trial DECLARED (task checks plus any
  /// arm-scoped fidelity checks). A skipped one leaves a hole that blocks
  /// verified success.
  int _declaredAuthoritativeChecks(
    EvaluationTask task,
    EvaluationPlan plan,
    EvaluationEffectiveConfig effective,
  ) => _verifiersFor(
    task,
    plan,
    effective,
  ).where((verifier) => verifier.authoritative).length;

  /// Observed contradictions of the campaign pin.
  ///
  /// A mismatch does not fail the run — the observation is still recorded — it
  /// makes the attempt INELIGIBLE as evidence, which is the honest reading of
  /// "the adapter served something other than what we pinned".
  List<String> _identityMismatches(
    EvaluationAttempt attempt, {
    required Map<String, String> observedSurfaces,
  }) {
    final mismatches = <String>[];
    final served = attempt.servedModel;
    if (served != null && served != config.manifest.modelId) {
      mismatches.add(
        'served model $served (pinned ${config.manifest.modelId})',
      );
    }
    final observedCli = attempt.observedCliVersion;
    final pinnedCli = config.manifest.cliVersion;
    if (observedCli != null &&
        pinnedCli != null &&
        pinnedCli.isNotEmpty &&
        observedCli != pinnedCli) {
      mismatches.add('cli version $observedCli (pinned $pinnedCli)');
    }
    final surface = attempt.observedToolSurfaceHash;
    if (surface != null) {
      final adapter = attempt.effective.adapter;
      final canonical = observedSurfaces.putIfAbsent(adapter, () => surface);
      if (canonical != surface) {
        mismatches.add(
          'tool surface $surface differs from the campaign surface $canonical',
        );
      }
    }
    return mismatches;
  }

  Future<EvaluationAttempt> _runTrial({
    required EvaluationTrial trial,
    required EvaluationCorpus corpus,
    required EvaluationPlan plan,
    required EvaluationArtifacts artifacts,
    required List<String> extraUnknowns,
    required Map<String, String> observedSurfaces,
  }) async {
    final task = corpus.taskById(trial.taskId);
    final arm = _armById(plan, trial.armId);
    if (task == null || arm == null) {
      throw StateError(
        'trial ${trial.ordinal} references unknown '
        '${task == null ? 'task ${trial.taskId}' : 'arm ${trial.armId}'}',
      );
    }
    final route = _routeFor(task, arm, plan);
    final effective = route.effective;
    final attemptId = _attemptId(plan, trial, task, arm);
    _progress(
      '▶ ${trial.ordinal} ${task.id} · ${arm.id} · ${trial.stratum.wire} · '
      'rep ${trial.repetition}',
    );
    if (config.cancelled?.call() ?? false) {
      throw StateError('evaluation cancelled');
    }

    final workspace = await IsolatedTaskWorkspace.create(
      task: task,
      parentDir: Directory('${config.outDir}/work'),
      fixtureRepoPath: _fixtureFor(task),
      keep: config.keepWorkspaces,
      controlled: config.controlled,
      cancellation: config.cancellation,
    );
    try {
      final agentRoot = workspace.subdirectory(task.workspaceSubpath);
      final request = EvaluationAttemptRequest(
        task: task,
        arm: arm,
        effective: effective,
        manifest: config.manifest,
        workspaceRoot: agentRoot,
        stratum: trial.stratum,
        repetition: trial.repetition,
        seed: trial.seed,
        ordinal: trial.ordinal,
        attemptId: attemptId,
        executionMode: trial.executionMode,
        replaySourceDir: artifacts.recordingsDir,
        outputDir: artifacts.runDir,
      );
      await config.prepareWorkspace?.call(request);
      if (config.controlled) {
        final fixtureChecks = await verifierRunner.run(
          verifiers: task
              .effectiveVerifiers()
              .where((v) => v.kind == EvaluationVerifierKind.fileUnchanged)
              .toList(),
          workspaceRoot: agentRoot,
          mode: EvaluationExecutionMode.live,
          cancellation: config.cancellation,
        );
        if (fixtureChecks.any((check) => !check.passed)) {
          throw StateError(
            'Protected fixture does not match its declared digest',
          );
        }
      }

      var attempt = await _execute(request);
      final assetMismatches =
          await config.validateWorkspace?.call(request) ?? const <String>[];
      if (route.note.isNotEmpty) {
        attempt = attempt.copyWith(
          notes: [
            attempt.notes,
            route.note,
          ].where((value) => value.trim().isNotEmpty).join('; '),
        );
      }

      final verification = await verifierRunner.run(
        verifiers: _verifiersFor(task, plan, effective),
        workspaceRoot: agentRoot,
        // Git-backed checks must run against the repository ROOT, which may be a
        // parent of the task's working sub-directory.
        gitRoot: workspace.root,
        trustedScriptDir: p.join(config.outDir, 'trusted'),
        mode: attempt.executionMode,
        controlled: config.controlled,
        cancellation: config.cancellation,
      );
      List<String> changed;
      String diff;
      try {
        changed = await workspace.changedFiles();
        diff = await workspace.diff();
      } on Object {
        if (!config.controlled) rethrow;
        changed = const [];
        diff = '';
        attempt = attempt.copyWith(
          completed: false,
          error: 'candidate artifacts failed safety checks',
        );
      }
      final patchRef = await artifacts.writePatch(attemptId, diff);
      attempt = attempt.copyWith(
        verification: verification,
        expectedAuthoritativeChecks: _declaredAuthoritativeChecks(
          task,
          plan,
          effective,
        ),
        filesTouched: changed,
        transcriptRef: config.controlled && patchRef != null
            ? p.relative(patchRef, from: artifacts.runDir)
            : patchRef,
        // End-to-end latency is closed AFTER independent verification, so it
        // means one thing rather than being copied from the backend's stopwatch.
        latency: EvaluationLatency(
          transportTtfbMs: attempt.latency.transportTtfbMs,
          firstModelEventMs: attempt.latency.firstModelEventMs,
          firstUsefulTextMs: attempt.latency.firstUsefulTextMs,
          providerTotalMs: attempt.latency.providerTotalMs,
          totalMs:
              DateTime.now().millisecondsSinceEpoch - attempt.startedAtEpochMs,
        ),
      );
      attempt = attempt.copyWith(
        identityMismatches: [
          ...assetMismatches,
          ..._identityMismatches(attempt, observedSurfaces: observedSurfaces),
        ],
      );

      // The task's declarative graders reuse the existing grader layer, but their
      // verdicts are recorded as NON-authoritative: a `max_turns` or `cost_budget`
      // check describes the run, it does not verify the deliverable.
      final advisory = _gradeAdvisory(task, attempt);
      if (advisory.isNotEmpty) {
        attempt = attempt.copyWith(
          verification: [...verification, ...advisory],
        );
      }

      await artifacts.writeRecording(
        attemptId: attemptId,
        attempt: attempt,
        diff: diff,
      );
      await artifacts.appendAttempt(attempt);

      if (attempt.servedModel != null &&
          attempt.servedModel != config.manifest.modelId) {
        extraUnknowns.add(
          '${task.id}/${arm.id}: the adapter reported serving '
          '${attempt.servedModel} but the manifest pinned '
          '${config.manifest.modelId}',
        );
      }

      return attempt;
    } finally {
      workspace.dispose();
    }
  }

  Future<EvaluationAttempt> _execute(EvaluationAttemptRequest request) async {
    final backend = config.backend;
    try {
      if (backend is ReplayEvaluationBackend) {
        final recording =
            await backend.recordingFor(request.attemptId) ??
            await backend.recordingFor(_logicalId(request));
        if (recording == null) {
          return backend.missingRecording(request);
        }
        final failure = await backend.restoreWorkspace(
          recording: recording,
          workspaceRoot: request.workspaceRoot,
        );
        final replayed = backend.asReplay(recording, request);
        return failure == null
            ? replayed
            : replayed.copyWith(completed: false, error: failure);
      }
      return await backend.execute(request);
    } on Object catch (exception) {
      return _errorAttempt(request, '$exception');
    }
  }

  EvaluationAttempt _errorAttempt(
    EvaluationAttemptRequest request,
    String message,
  ) => EvaluationAttempt(
    attemptId: request.attemptId,
    taskId: request.task.id,
    taskKind: request.task.kind,
    armId: request.arm.id,
    effective: request.effective,
    stratum: request.stratum,
    repetition: request.repetition,
    seed: request.seed,
    ordinal: request.ordinal,
    startedAtEpochMs:
        (config.now?.call() ?? DateTime.now()).millisecondsSinceEpoch,
    executionMode: request.executionMode,
    completed: false,
    error: message,
    verification: const [],
    notes: 'backend fault (${config.backend.id})',
  );

  /// Runs the task's deterministic graders over the attempt's projected
  /// outcome, returning them as advisory (non-authoritative) evidence.
  List<EvaluationVerificationResult> _gradeAdvisory(
    EvaluationTask task,
    EvaluationAttempt attempt,
  ) {
    if (task.graders.isEmpty) {
      return const [];
    }
    final outcome = attempt.toEvalOutcome();
    final results = <EvaluationVerificationResult>[];
    for (final spec in task.graders) {
      final grader = spec.build();
      if (grader == null) {
        continue;
      }
      final grade = grader.grade(outcome);
      results.add(
        EvaluationVerificationResult(
          verifierId: grade.graderId,
          passed: grade.passed,
          authoritative: false,
          provenance: VerificationProvenance.behavioral,
          detail: grade.detail,
        ),
      );
    }
    return results;
  }

  /// The per-task verification set: the task's own checks plus, when the arm
  /// runs the memory experiment, that experiment's fidelity checks — because a
  /// compressed context that loses the task's facts must fail the task.
  ///
  /// Fidelity checks are scoped by an optional `taskId` param: a check about
  /// one task's facts must not be imposed on every other task in the corpus.
  List<EvaluationVerifier> _verifiersFor(
    EvaluationTask task,
    EvaluationPlan plan,
    EvaluationEffectiveConfig effective,
  ) {
    // The task's own checks PLUS one digest check per protected fixture file:
    // a candidate that rewrites the evidence a check reads must fail the trial.
    final declared = task.effectiveVerifiers();
    final experiment = plan.memoryExperiment;
    if (experiment == null ||
        !experiment.enabled ||
        experiment.mode != effective.memoryPolicy) {
      return declared;
    }
    return [
      ...declared,
      for (final verifier in experiment.fidelityVerifiers)
        if (verifier.params['taskId'] == null ||
            verifier.params['taskId'] == task.id)
          verifier,
    ];
  }

  ({EvaluationEffectiveConfig effective, String note}) _routeFor(
    EvaluationTask task,
    EvaluationArm arm,
    EvaluationPlan plan,
  ) {
    final base = EvaluationEffectiveConfig.forArm(config.manifest, arm);
    final policy = plan.routePolicy;
    if (policy == null ||
        !policy.enabled ||
        arm.taskRoutePolicyId != policy.id) {
      return (effective: base, note: '');
    }
    final decision = policy.decisionFor(task);
    if (decision == null) {
      return (
        effective: base,
        note:
            'route policy ${policy.id} v${policy.version}: task class '
            '${task.kind.wire} has no route, so the pinned quality default ran',
      );
    }
    return (
      effective: EvaluationEffectiveConfig(
        adapter: base.adapter,
        providerId: base.providerId,
        modelId: decision.modelId ?? base.modelId,
        effortLevel: decision.effortLevel ?? base.effortLevel,
        memoryPolicy: base.memoryPolicy,
        sessionContinuity: base.sessionContinuity,
        mcpDiscoveryCache: base.mcpDiscoveryCache,
        toolOverlap: base.toolOverlap,
        skillExposure: base.skillExposure,
        cacheEnabled: base.cacheEnabled,
        toolDeferralEnabled: base.toolDeferralEnabled,
      ),
      note:
          'route policy ${policy.id} v${policy.version} → '
          '${decision.modelId ?? config.manifest.modelId}/'
          '${decision.effortLevel ?? config.manifest.effortLevel ?? 'default'}'
          '${decision.note.isEmpty ? '' : ' (${decision.note})'}',
    );
  }

  String? _fixtureFor(EvaluationTask task) {
    final ref = task.fixtureRef;
    if (ref == null || ref.isEmpty) {
      return null;
    }
    if (File(ref).isAbsolute) {
      return ref;
    }
    final base = config.fixtureDirectory;
    if (base == null) {
      throw StateError(
        'task "${task.id}" needs fixture "$ref" but no fixture directory was '
        'configured',
      );
    }
    return '$base/$ref';
  }

  static StratumSpec? _stratumSpec(EvaluationPlan plan, CacheStratum stratum) {
    for (final spec in plan.strata) {
      if (spec.stratum == stratum) {
        return spec;
      }
    }
    return null;
  }

  static EvaluationArm? _armById(EvaluationPlan plan, String armId) {
    for (final arm in plan.arms) {
      if (arm.id == armId) {
        return arm;
      }
    }
    return null;
  }

  static String _attemptId(
    EvaluationPlan plan,
    EvaluationTrial trial,
    EvaluationTask task,
    EvaluationArm arm,
  ) =>
      '${plan.id}-${trial.ordinal}-${task.id}-${arm.id}-'
      '${trial.stratum.wire}-r${trial.repetition}';

  /// A schedule-independent attempt id, so a replay can find a recording even
  /// when it runs a different seed/order.
  static String _logicalId(EvaluationAttemptRequest request) =>
      '${request.task.id}-${request.arm.id}-${request.stratum.wire}-'
      'r${request.repetition}';

  void _progress(String message) => config.onProgress?.call(message);
}
