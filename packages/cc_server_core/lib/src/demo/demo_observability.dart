import 'dart:math';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';

/// Models the demo observability surfaces attribute usage to.
///
/// Display strings, not catalogue ids: the usage donut, the trend legend and
/// the insights "by model" rows print [AgentRunLog.modelId] as-is.
const String kDemoModelOpus = 'Claude 5.5 Opus';

/// Claude 5.1 Fable, the mid-tier model in the demo mix.
const String kDemoModelFable = 'Claude 5.1 Fable';

/// Grok 4.7, used mostly by the triage agent.
const String kDemoModelGrok = 'Grok 4.7';

/// GLM 5.3, the cheapest model in the demo mix.
const String kDemoModelGlm = 'GLM 5.3';

/// The four models a demo workspace reports, in legend order.
const List<String> kDemoObservabilityModels = [
  kDemoModelOpus,
  kDemoModelFable,
  kDemoModelGrok,
  kDemoModelGlm,
];

/// One finished or in-flight agent run for the observability seed.
class DemoObservabilityRun {
  /// Creates a run spec.
  const DemoObservabilityRun({
    required this.id,
    required this.agentIndex,
    required this.startedAt,
    required this.status,
    required this.modelId,
    required this.summary,
    required this.cost,
    this.completedAt,
    this.liveness,
    this.errorFamily,
    this.errorCode,
    this.role = AgentRunRole.main,
  });

  /// Stable id within one workspace database.
  final String id;

  /// Index into the demo agent list (Ravi, Juno, Wren).
  final int agentIndex;

  /// When the run started.
  final DateTime startedAt;

  /// When it finished. Null while it is still in flight.
  final DateTime? completedAt;

  /// Terminal or live status.
  final RunStatus status;

  /// Model name shown on the usage and insights surfaces.
  final String modelId;

  /// One-line outcome shown in the run log and the benchmark trial list.
  final String summary;

  /// Token and cost figures the charts aggregate.
  final RunCost cost;

  /// Liveness, when the run has been classified.
  final RunLiveness? liveness;

  /// Error family for a failed run.
  final RunErrorFamily? errorFamily;

  /// Adapter error code for a failed run.
  final String? errorCode;

  /// Main or subagent, for the role cost split.
  final AgentRunRole role;

  /// Returns a copy with [id] replaced.
  DemoObservabilityRun copyWith({String? id}) => DemoObservabilityRun(
    id: id ?? this.id,
    agentIndex: agentIndex,
    startedAt: startedAt,
    completedAt: completedAt,
    status: status,
    modelId: modelId,
    summary: summary,
    cost: cost,
    liveness: liveness,
    errorFamily: errorFamily,
    errorCode: errorCode,
    role: role,
  );
}

/// A year of Helix run history ending at [now].
///
/// Deterministic for a given [now]: the same clock yields the same runs, so
/// a test can pin the mix without seeding a database. The last eleven local
/// days each carry tokens (the usage streak), today includes runs inside the
/// trailing few hours (the live quota windows), and all four models appear
/// inside the trailing month (the usage donut).
List<DemoObservabilityRun> buildDemoObservabilityRuns(DateTime now) {
  final random = Random(0x48454C58);
  final today = DateTime(now.year, now.month, now.day);
  final runs = <DemoObservabilityRun>[];
  var serial = 0;

  for (var ago = 363; ago >= 0; ago--) {
    final day = DateTime(today.year, today.month, today.day - ago);
    final keep = ago < 11 || _dayIsActive(random, day.weekday);
    if (!keep) {
      continue;
    }
    final count = ago == 0
        ? 3
        : ago < 11
        ? 2 + random.nextInt(2)
        : 1 +
              (day.weekday < DateTime.saturday && random.nextInt(100) < 28
                  ? 1
                  : 0);
    for (var n = 0; n < count; n++) {
      final startedAt = _startedAt(
        day: day,
        now: now,
        ago: ago,
        slot: n,
        slots: count,
        random: random,
      );
      runs.add(
        _completedRun(
          random: random,
          id: 'demo-obs-$serial',
          startedAt: startedAt,
          ago: ago,
        ),
      );
      serial++;
    }
  }

  // Juno is mid-triage when the visitor arrives, so the live roster is not
  // a wall of idle rows.
  final liveStart = now.subtract(const Duration(minutes: 8));
  runs.add(
    DemoObservabilityRun(
      id: 'demo-obs-live-juno',
      agentIndex: 1,
      startedAt: liveStart.isBefore(today) ? today : liveStart,
      status: RunStatus.running,
      liveness: RunLiveness.alive,
      modelId: kDemoModelGrok,
      summary: 'Checking the cancellation path on the shared run-group ledger',
      cost: const RunCost(
        inputTokens: 9400,
        outputTokens: 210,
        cachedReadTokens: 4200,
        cachedWriteTokens: 640,
        thoughtTokens: 180,
        estimatedCostCents: 18,
      ),
    ),
  );

  return _pinRecentCompleted(runs);
}

/// Eval suites and their finished batches for the Quality tab.
class DemoEvalSeed {
  /// Creates a suite plus the batches already run against it.
  const DemoEvalSeed({required this.suite, required this.runs});

  /// The suite row.
  final EvalSuite suite;

  /// Finished batches, newest last in this list (the watch orders by time).
  final List<EvalRun> runs;
}

/// Two Helix eval suites with finished batches.
List<DemoEvalSeed> buildDemoEvalSeeds(String workspaceId, DateTime now) {
  EvalSuite suite({
    required String id,
    required String name,
    required String description,
    required int batch,
    required bool starter,
    required int daysAgo,
  }) {
    final created = now.subtract(Duration(days: daysAgo));
    return EvalSuite(
      id: id,
      workspaceId: workspaceId,
      name: name,
      description: description,
      defaultBatchSize: batch,
      isStarter: starter,
      taskJson: '{}',
      gradersJson: '[]',
      createdAt: created,
      updatedAt: now.subtract(const Duration(hours: 6)),
    );
  }

  EvalRun run({
    required String id,
    required String suiteId,
    required int hoursAgo,
    required int batch,
    required double passRate,
    required String status,
    required int costCents,
    required String triggeredBy,
  }) {
    final created = now.subtract(Duration(hours: hoursAgo));
    return EvalRun(
      id: id,
      workspaceId: workspaceId,
      suiteId: suiteId,
      configHash: 'demo-$suiteId',
      batchSize: batch,
      passRate: passRate,
      status: status,
      costCents: costCents,
      triggeredBy: triggeredBy,
      createdAt: created,
      startedAt: created,
      finishedAt: created.add(const Duration(minutes: 4)),
    );
  }

  const budgetId = 'demo-eval-budget';
  const retrieverId = 'demo-eval-retriever';
  return [
    DemoEvalSeed(
      suite: suite(
        id: budgetId,
        name: 'Budget ledger',
        description:
            'Shared run groups keep a remaining-token total that matches '
            'the grader and the run card.',
        batch: 8,
        starter: true,
        daysAgo: 40,
      ),
      runs: [
        run(
          id: 'demo-eval-budget-1',
          suiteId: budgetId,
          hoursAgo: 80,
          batch: 8,
          passRate: 0.75,
          status: 'failed',
          costCents: 186,
          triggeredBy: 'ci',
        ),
        run(
          id: 'demo-eval-budget-2',
          suiteId: budgetId,
          hoursAgo: 30,
          batch: 8,
          passRate: 0.875,
          status: 'completed',
          costCents: 164,
          triggeredBy: 'canary',
        ),
        run(
          id: 'demo-eval-budget-3',
          suiteId: budgetId,
          hoursAgo: 6,
          batch: 8,
          passRate: 1,
          status: 'completed',
          costCents: 142,
          triggeredBy: 'manual',
        ),
      ],
    ),
    DemoEvalSeed(
      suite: suite(
        id: retrieverId,
        name: 'Retriever citations',
        description:
            'Hybrid search answers cite a chunk that is actually in the '
            'retrieved set.',
        batch: 5,
        starter: false,
        daysAgo: 18,
      ),
      runs: [
        run(
          id: 'demo-eval-retriever-1',
          suiteId: retrieverId,
          hoursAgo: 50,
          batch: 5,
          passRate: 0.8,
          status: 'completed',
          costCents: 96,
          triggeredBy: 'ci',
        ),
        run(
          id: 'demo-eval-retriever-2',
          suiteId: retrieverId,
          hoursAgo: 9,
          batch: 5,
          passRate: 0.6,
          status: 'failed',
          costCents: 110,
          triggeredBy: 'manual',
        ),
      ],
    ),
  ];
}

/// Fictional fleet workers shared by every demo workspace.
///
/// Workers are server-global. These ids are stable so each workspace seed
/// refreshes the same rows instead of accumulating duplicates.
List<Worker> buildDemoFleetWorkers(DateTime now) => [
  Worker(
    id: 'demo-worker-eval-a',
    name: 'helix-eval-a',
    capabilities: const WorkerCapabilities(
      os: 'linux',
      arch: 'x64',
      cores: 16,
      ramMb: 65536,
      hasMl: true,
      alwaysOn: true,
      acceptsParallel: true,
      sandboxBackends: {'native-linux'},
    ),
    status: WorkerStatus.online,
    protocolVersion: 1,
    lastHeartbeatAt: now.subtract(const Duration(seconds: 20)),
    createdAt: now.subtract(const Duration(days: 60)),
  ),
  Worker(
    id: 'demo-worker-eval-b',
    name: 'helix-eval-b',
    capabilities: const WorkerCapabilities(
      os: 'linux',
      arch: 'arm64',
      cores: 8,
      ramMb: 32768,
      hasFlutter: true,
      alwaysOn: true,
      sandboxBackends: {'native-linux'},
    ),
    status: WorkerStatus.online,
    protocolVersion: 1,
    lastHeartbeatAt: now.subtract(const Duration(minutes: 2)),
    createdAt: now.subtract(const Duration(days: 40)),
  ),
  Worker(
    id: 'demo-worker-batch',
    name: 'helix-batch',
    capabilities: const WorkerCapabilities(
      os: 'linux',
      arch: 'x64',
      cores: 32,
      ramMb: 131072,
      hasMl: true,
      acceptsParallel: true,
      sandboxBackends: {'native-linux'},
    ),
    status: WorkerStatus.draining,
    protocolVersion: 1,
    lastHeartbeatAt: now.subtract(const Duration(minutes: 14)),
    drainedAt: now.subtract(const Duration(minutes: 14)),
    lastError: 'Draining for a kernel update; in-flight evals will finish.',
    createdAt: now.subtract(const Duration(days: 20)),
  ),
];

/// One workspace-scoped fleet job plus the placement note that explains it.
class DemoFleetJobSeed {
  /// Creates a job and its placement decision.
  const DemoFleetJobSeed({required this.job, required this.placement});

  /// The job row. Its id is unique per workspace.
  final Job job;

  /// Why the scheduler put it there.
  final PlacementDecision placement;
}

/// Jobs for one demo workspace: a running eval, a finished review, a queued
/// index, and a failed batch.
List<DemoFleetJobSeed> buildDemoFleetJobs(String workspaceId, DateTime now) {
  String id(String suffix) => '$workspaceId:demo-job-$suffix';
  return [
    DemoFleetJobSeed(
      job: Job(
        id: id('eval'),
        workspaceId: workspaceId,
        kind: JobKind.evalBatch,
        spec: const EvalBatchJobSpec(
          evalRunId: 'demo-eval-budget-3',
          suiteId: 'demo-eval-budget',
          configHash: 'demo-demo-eval-budget',
        ),
        status: JobStatus.running,
        requiredCaps: const {FleetCaps.parallel, FleetCaps.linux},
        workerId: 'demo-worker-eval-a',
        priority: 10,
        attempts: 1,
        maxAttempts: 2,
        costCents: 142,
        agentId: 'demo-agent-reviewer',
        createdAt: now.subtract(const Duration(hours: 6, minutes: 10)),
        leasedAt: now.subtract(const Duration(hours: 6, minutes: 8)),
        startedAt: now.subtract(const Duration(hours: 6, minutes: 7)),
      ),
      placement: const PlacementDecision(
        code: PlacementCode.preferred,
        reason:
            'Pinned to a parallel Linux worker for the budget-ledger batch.',
        workerId: 'demo-worker-eval-a',
      ),
    ),
    DemoFleetJobSeed(
      job: Job(
        id: id('review'),
        workspaceId: workspaceId,
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(
          agentId: 'demo-agent-reviewer',
          prompt: 'Review the shared run-group change on #412.',
        ),
        status: JobStatus.done,
        workerId: 'demo-worker-eval-b',
        attempts: 1,
        costCents: 64,
        agentId: 'demo-agent-reviewer',
        createdAt: now.subtract(const Duration(hours: 5)),
        startedAt: now.subtract(const Duration(hours: 4, minutes: 50)),
        finishedAt: now.subtract(const Duration(hours: 4, minutes: 40)),
      ),
      placement: const PlacementDecision(
        code: PlacementCode.spill,
        reason: 'eval-a was busy with the ledger batch; spilled to eval-b.',
        workerId: 'demo-worker-eval-b',
      ),
    ),
    DemoFleetJobSeed(
      job: Job(
        id: id('index'),
        workspaceId: workspaceId,
        kind: JobKind.codeIndex,
        spec: const CodeIndexJobSpec(repoId: 'demo-repo-evalkit'),
        status: JobStatus.queued,
        pinnedWorkerId: 'demo-worker-batch',
        priority: 1,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      placement: const PlacementDecision(
        code: PlacementCode.pinnedWorkerUnavailable,
        reason: 'helix-batch is draining for a kernel update.',
        workerId: 'demo-worker-batch',
      ),
    ),
    DemoFleetJobSeed(
      job: Job(
        id: id('golden'),
        workspaceId: workspaceId,
        kind: JobKind.benchmark,
        spec: const BenchmarkJobSpec(
          name: 'retriever-citations',
          paramsJson: '{}',
        ),
        status: JobStatus.failed,
        workerId: 'demo-worker-batch',
        attempts: 2,
        maxAttempts: 2,
        costCents: 40,
        error: 'Worker started draining before the benchmark shard finished.',
        createdAt: now.subtract(const Duration(hours: 2)),
        startedAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        finishedAt: now.subtract(const Duration(minutes: 20)),
      ),
      placement: const PlacementDecision(
        code: PlacementCode.pinned,
        reason: 'Benchmark shard was pinned to helix-batch.',
        workerId: 'demo-worker-batch',
      ),
    ),
  ];
}

const List<String> _summaries = [
  'Reviewed #412: 1 blocking comment, 3 nits',
  'Triaged HX-118 to a progress-reporting bug',
  'Broke eval-score exports into four plan nodes',
  'Checked the remaining-token chip against a shared run group',
  'Rewrote the grader note on evalkit/budget.py',
  'Compared BM25 and embedding hits for the citation failure',
  'Split the feature-store lineage query off the hot path',
  'Recorded a LoRA smoke run that stopped at step 40',
  'Left the release-gate note on the shared run-group change',
  'Reproduced the stuck progress bar on HX-118',
  'Approved features #49 after the lineage test went green',
  'Flagged a cache-write spike on the Opus review runs',
];

bool _dayIsActive(Random random, int weekday) {
  final roll = random.nextInt(100);
  if (weekday >= DateTime.saturday) {
    return roll < 32;
  }
  return roll < 74;
}

DateTime _startedAt({
  required DateTime day,
  required DateTime now,
  required int ago,
  required int slot,
  required int slots,
  required Random random,
}) {
  if (ago == 0) {
    // 35 minutes, 2 hours, 5 hours — inside the 5h quota window for the
    // first slot, and still today for the others when the clock allows.
    const offsets = [
      Duration(minutes: 35),
      Duration(hours: 2),
      Duration(hours: 5),
    ];
    final offset = offsets[slot.clamp(0, offsets.length - 1)];
    final candidate = now.subtract(offset);
    if (!candidate.isBefore(day)) {
      return candidate;
    }
    return now.subtract(Duration(minutes: 12 + slot * 4));
  }
  final hour = 9 + random.nextInt(9);
  final minute = (slot * 17 + random.nextInt(20)) % 60;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

DemoObservabilityRun _completedRun({
  required Random random,
  required String id,
  required DateTime startedAt,
  required int ago,
}) {
  final model = _modelFor(random, ago);
  final failed = random.nextInt(16) == 0;
  final sub = !failed && random.nextInt(9) == 0;
  final input = _inputTokens(model, random);
  final output = 180 + random.nextInt(model == kDemoModelOpus ? 1600 : 700);
  final thought = model == kDemoModelOpus || model == kDemoModelFable
      ? 80 + random.nextInt(700)
      : random.nextInt(160);
  final cacheRead = (input * (35 + random.nextInt(40)) / 100).round();
  final cacheWrite = 200 + random.nextInt(1400);
  final seconds = 22 + random.nextInt(failed ? 40 : 160);
  final (inPerM, outPerM) = _rates(model);
  final cents = (input * inPerM + (output + thought) * outPerM) ~/ 1000000;
  return DemoObservabilityRun(
    id: id,
    agentIndex: _agentFor(model, random),
    startedAt: startedAt,
    completedAt: startedAt.add(Duration(seconds: seconds)),
    status: failed ? RunStatus.error : RunStatus.completed,
    liveness: failed ? RunLiveness.failed : RunLiveness.completed,
    errorFamily: failed
        ? (random.nextBool()
              ? RunErrorFamily.transientUpstream
              : RunErrorFamily.budgetExceeded)
        : null,
    errorCode: failed
        ? (random.nextBool() ? 'rate_limit_error' : 'budget_exceeded')
        : null,
    modelId: model,
    summary: failed
        ? 'Stopped early: ${model.toLowerCase()} hit a limit mid-run'
        : _summaries[random.nextInt(_summaries.length)],
    role: sub ? AgentRunRole.sub : AgentRunRole.main,
    cost: RunCost(
      inputTokens: input,
      outputTokens: output,
      thoughtTokens: thought,
      cachedReadTokens: cacheRead,
      cachedWriteTokens: cacheWrite,
      estimatedCostCents: cents < 1 ? 1 : cents,
      durationMs: seconds * 1000,
      timeToFirstTokenMs: 280 + random.nextInt(2200),
    ),
  );
}

String _modelFor(Random random, int ago) {
  // The trailing month always rotates through every model, so a 30-day
  // window cannot drop one of them on an unlucky streak.
  if (ago < 30) {
    return kDemoObservabilityModels[ago % kDemoObservabilityModels.length];
  }
  final n = random.nextInt(100);
  if (n < 40) {
    return kDemoModelOpus;
  }
  if (n < 66) {
    return kDemoModelFable;
  }
  if (n < 86) {
    return kDemoModelGrok;
  }
  return kDemoModelGlm;
}

int _agentFor(String model, Random random) => switch (model) {
  kDemoModelOpus => random.nextInt(6) == 0 ? 2 : 0,
  kDemoModelFable => random.nextInt(6) == 0 ? 0 : 2,
  kDemoModelGrok => 1,
  _ => random.nextInt(3),
};

int _inputTokens(String model, Random random) {
  final base = switch (model) {
    kDemoModelOpus => 48000,
    kDemoModelFable => 28000,
    kDemoModelGrok => 18000,
    _ => 10000,
  };
  return base + random.nextInt(base);
}

(int, int) _rates(String model) => switch (model) {
  kDemoModelOpus => (1500, 7500),
  kDemoModelFable => (300, 1500),
  kDemoModelGrok => (500, 2500),
  _ => (100, 400),
};

List<DemoObservabilityRun> _pinRecentCompleted(
  List<DemoObservabilityRun> runs,
) {
  final completed = [
    for (final run in runs)
      if (run.status == RunStatus.completed) run,
  ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  const pinnedIds = ['demo-run-0', 'demo-run-1', 'demo-run-2'];
  final rename = <DemoObservabilityRun, String>{};
  for (var i = 0; i < pinnedIds.length && i < completed.length; i++) {
    rename[completed[i]] = pinnedIds[i];
  }
  return [
    for (final run in runs)
      if (rename[run] case final id?) run.copyWith(id: id) else run,
  ];
}
