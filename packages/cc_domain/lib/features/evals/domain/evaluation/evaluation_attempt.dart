import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';

/// Micro-USD per US cent.
///
/// The canonical unit for all evaluation money is micro-USD (10⁻⁶ USD), the
/// unit `ProviderCallRecord.costMicros` and `RunCost.costMicros` use. One cent
/// is 10,000 µ$; a cheap auxiliary call is real spend that a cents-only figure
/// would round to zero.
const int microsPerCent = 10000;

/// Tokens split by the axes the cost question actually needs
/// (HARNESS_RESEARCH §6: "Track tokens as separate axes: uncached input, cache
/// writes, cache reads, output, and reasoning where separately reported. Do not
/// double-count reasoning already included in output.").
///
/// [reasoningSeparatelyReported] is the honesty flag that makes the last
/// clause enforceable: some adapters fold thinking into `output`, and those
/// must report `false` here rather than double-count. [totalTokens] therefore
/// adds [reasoning] only when it was reported separately.
class EvaluationTokenBreakdown {
  /// Creates an [EvaluationTokenBreakdown].
  const EvaluationTokenBreakdown({
    this.uncachedInput = 0,
    this.cacheWrite = 0,
    this.cacheRead = 0,
    this.output = 0,
    this.reasoning = 0,
    this.reasoningSeparatelyReported = false,
  });

  /// Parses from JSON.
  factory EvaluationTokenBreakdown.fromJson(Map<String, dynamic> json) =>
      EvaluationTokenBreakdown(
        uncachedInput: (json['uncachedInput'] as num?)?.toInt() ?? 0,
        cacheWrite: (json['cacheWrite'] as num?)?.toInt() ?? 0,
        cacheRead: (json['cacheRead'] as num?)?.toInt() ?? 0,
        output: (json['output'] as num?)?.toInt() ?? 0,
        reasoning: (json['reasoning'] as num?)?.toInt() ?? 0,
        reasoningSeparatelyReported:
            json['reasoningSeparatelyReported'] as bool? ?? false,
      );

  /// Input tokens that were neither written to nor read from the cache.
  final int uncachedInput;

  /// Input tokens written into the provider prompt cache.
  final int cacheWrite;

  /// Input tokens served from the provider prompt cache.
  final int cacheRead;

  /// Output (completion) tokens, including thinking when the adapter folds it
  /// in.
  final int output;

  /// Reasoning tokens, when the adapter reports them separately.
  final int reasoning;

  /// Whether [reasoning] is a distinct axis rather than a view of [output].
  final bool reasoningSeparatelyReported;

  /// Everything the model read: uncached input plus both cache directions.
  int get inputTokens => uncachedInput + cacheWrite + cacheRead;

  /// Every token the adapter counted, without double-counting reasoning.
  int get totalTokens =>
      inputTokens + output + (reasoningSeparatelyReported ? reasoning : 0);

  /// The fraction of input served from cache, or 0 when nothing was read.
  double get cacheReadFraction {
    final input = inputTokens;
    return input > 0 ? cacheRead / input : 0;
  }

  /// Sums two breakdowns. The reasoning flag is preserved only when both sides
  /// agree, so a mixed pair reports reasoning as already inside output.
  EvaluationTokenBreakdown operator +(EvaluationTokenBreakdown other) =>
      EvaluationTokenBreakdown(
        uncachedInput: uncachedInput + other.uncachedInput,
        cacheWrite: cacheWrite + other.cacheWrite,
        cacheRead: cacheRead + other.cacheRead,
        output: output + other.output,
        reasoning: reasoning + other.reasoning,
        reasoningSeparatelyReported:
            reasoningSeparatelyReported && other.reasoningSeparatelyReported,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'uncachedInput': uncachedInput,
    'cacheWrite': cacheWrite,
    'cacheRead': cacheRead,
    'output': output,
    if (reasoning > 0) 'reasoning': reasoning,
    'reasoningSeparatelyReported': reasoningSeparatelyReported,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationTokenBreakdown &&
          uncachedInput == other.uncachedInput &&
          cacheWrite == other.cacheWrite &&
          cacheRead == other.cacheRead &&
          output == other.output &&
          reasoning == other.reasoning &&
          reasoningSeparatelyReported == other.reasoningSeparatelyReported;

  @override
  int get hashCode => Object.hash(
    uncachedInput,
    cacheWrite,
    cacheRead,
    output,
    reasoning,
    reasoningSeparatelyReported,
  );
}

/// Money kept in *roles*, in micro-USD, because a subscription $1.50 and a
/// billed $1.50 are different facts (report 4C).
///
/// Every field is nullable and null means NOT OBSERVED — it is never a zero, and
/// it never becomes one: an unpriced call is unknown spend, not free work.
/// [isComplete] answers "was the primary spend observed at all", which is what
/// the report's savings arithmetic requires from BOTH arms before it will
/// recommend anything.
class EvaluationCostRoles {
  /// Creates an [EvaluationCostRoles].
  const EvaluationCostRoles({
    this.subscriptionMicros,
    this.estimatedApiMicros,
    this.billedMicros,
    this.auxMicros,
    this.advisorMicros,
  });

  /// Parses from JSON.
  factory EvaluationCostRoles.fromJson(Map<String, dynamic> json) =>
      EvaluationCostRoles(
        subscriptionMicros: (json['subscriptionMicros'] as num?)?.toInt(),
        estimatedApiMicros: (json['estimatedApiMicros'] as num?)?.toInt(),
        billedMicros: (json['billedMicros'] as num?)?.toInt(),
        auxMicros: (json['auxMicros'] as num?)?.toInt(),
        advisorMicros: (json['advisorMicros'] as num?)?.toInt(),
      );

  /// What the run consumed from a subscription quota, when metered.
  final int? subscriptionMicros;

  /// What the run would cost at list price (API-equivalent).
  final int? estimatedApiMicros;

  /// What was actually billed (pay-as-you-go accounts only).
  final int? billedMicros;

  /// Auxiliary model calls the adapter made on its own (titling, discovery).
  final int? auxMicros;

  /// Advisor / sub-agent spend, kept out of the main-attempt total so a quality
  /// gain cannot hide its true cost.
  final int? advisorMicros;

  /// Whether no role was observable at all.
  bool get isEmpty =>
      subscriptionMicros == null &&
      estimatedApiMicros == null &&
      billedMicros == null &&
      auxMicros == null &&
      advisorMicros == null;

  /// Whether the attempt's primary spend was observed.
  ///
  /// A run whose model calls could not be priced is INCOMPLETE, and incomplete
  /// cost can never support a savings claim.
  bool get isComplete => budgetMicros != null;

  /// The best-known primary spend in micro-USD, or null when unpriced.
  ///
  /// Prefers what was actually billed, then the list-price estimate, then quota
  /// consumption — one axis, in the order of how close each is to an invoice.
  int? get budgetMicros =>
      billedMicros ?? estimatedApiMicros ?? subscriptionMicros;

  /// [budgetMicros] in whole cents (display only; arithmetic stays in micros).
  int get budgetCents {
    final micros = budgetMicros;
    return micros == null ? 0 : (micros / microsPerCent).round();
  }

  /// The total cost of *this attempt* including auxiliary and advisor calls, in
  /// micro-USD, or null when the primary spend was not observable.
  ///
  /// Absent auxiliary/advisor legs contribute nothing rather than blocking the
  /// total: they are extra spend, not the spend being compared.
  int? get allAttemptMicros {
    final base = budgetMicros;
    if (base == null) {
      return null;
    }
    return base + (auxMicros ?? 0) + (advisorMicros ?? 0);
  }

  /// [allAttemptMicros] in whole cents (display only).
  int get allAttemptCents {
    final micros = allAttemptMicros;
    return micros == null ? 0 : (micros / microsPerCent).round();
  }

  /// Sums two role sets, treating null as "not observed" (so `null + 5 = 5`
  /// and `null + null = null`).
  EvaluationCostRoles operator +(EvaluationCostRoles other) =>
      EvaluationCostRoles(
        subscriptionMicros: _add(subscriptionMicros, other.subscriptionMicros),
        estimatedApiMicros: _add(estimatedApiMicros, other.estimatedApiMicros),
        billedMicros: _add(billedMicros, other.billedMicros),
        auxMicros: _add(auxMicros, other.auxMicros),
        advisorMicros: _add(advisorMicros, other.advisorMicros),
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (subscriptionMicros != null) 'subscriptionMicros': subscriptionMicros,
    if (estimatedApiMicros != null) 'estimatedApiMicros': estimatedApiMicros,
    if (billedMicros != null) 'billedMicros': billedMicros,
    if (auxMicros != null) 'auxMicros': auxMicros,
    if (advisorMicros != null) 'advisorMicros': advisorMicros,
  };

  static int? _add(int? a, int? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationCostRoles &&
          subscriptionMicros == other.subscriptionMicros &&
          estimatedApiMicros == other.estimatedApiMicros &&
          billedMicros == other.billedMicros &&
          auxMicros == other.auxMicros &&
          advisorMicros == other.advisorMicros;

  @override
  int get hashCode => Object.hash(
    subscriptionMicros,
    estimatedApiMicros,
    billedMicros,
    auxMicros,
    advisorMicros,
  );
}

/// Latencies kept as distinct stages (report 5: "Measure the right latency").
///
/// A CLI-wrapped adapter cannot observe transport TTFB, so that field stays null
/// there rather than borrowing the CLI's own timing and calling it TTFB. Provider
/// time is the sum of the physical main provider calls, never auxiliary calls
/// or the loop's wall clock (which includes local tool execution).
class EvaluationLatency {
  /// Creates an [EvaluationLatency].
  const EvaluationLatency({
    this.transportTtfbMs,
    this.firstModelEventMs,
    this.firstUsefulTextMs,
    this.providerTotalMs,
    this.totalMs = 0,
  });

  /// Parses from JSON.
  factory EvaluationLatency.fromJson(Map<String, dynamic> json) =>
      EvaluationLatency(
        transportTtfbMs: (json['transportTtfbMs'] as num?)?.toInt(),
        firstModelEventMs: (json['firstModelEventMs'] as num?)?.toInt(),
        firstUsefulTextMs: (json['firstUsefulTextMs'] as num?)?.toInt(),
        providerTotalMs: (json['providerTotalMs'] as num?)?.toInt(),
        totalMs: (json['totalMs'] as num?)?.toInt() ?? 0,
      );

  /// Time from the first main request's observed dispatch to its first response
  /// body byte. Null if either boundary is unavailable (including CLI adapters).
  final int? transportTtfbMs;

  /// Attempt-relative time to the first model-authored event (text, thinking or
  /// tool call). This is distinct from the first useful work.
  final int? firstModelEventMs;

  /// Attempt-relative time to the first nonblank text delta or started tool
  /// action. This is a work boundary, not a judgment of the answer's quality.
  final int? firstUsefulTextMs;

  /// Summed duration of the physical main provider calls, when observed
  /// through a provider observer. Excludes auxiliary calls and local tools.
  final int? providerTotalMs;

  /// Total wall-clock time for the attempt, closed by the engine AFTER
  /// independent verification so it means one thing: end-to-end attempt time.
  final int totalMs;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (transportTtfbMs != null) 'transportTtfbMs': transportTtfbMs,
    if (firstModelEventMs != null) 'firstModelEventMs': firstModelEventMs,
    if (firstUsefulTextMs != null) 'firstUsefulTextMs': firstUsefulTextMs,
    if (providerTotalMs != null) 'providerTotalMs': providerTotalMs,
    'totalMs': totalMs,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationLatency &&
          transportTtfbMs == other.transportTtfbMs &&
          firstModelEventMs == other.firstModelEventMs &&
          firstUsefulTextMs == other.firstUsefulTextMs &&
          providerTotalMs == other.providerTotalMs &&
          totalMs == other.totalMs;

  @override
  int get hashCode => Object.hash(
    transportTtfbMs,
    firstModelEventMs,
    firstUsefulTextMs,
    providerTotalMs,
    totalMs,
  );
}

/// The coarse class of a tool call, used to count the recovery metrics the
/// report asks for without depending on any one tool's naming.
enum EvaluationToolKind {
  /// Reads a file.
  read('read'),

  /// Searches for text or symbols.
  search('search'),

  /// Lists / finds files.
  find('find'),

  /// Mutates a file in place.
  edit('edit'),

  /// Applies a patch.
  patch('patch'),

  /// Runs a process.
  exec('exec'),

  /// Anything else.
  other('other');

  const EvaluationToolKind(this.wire);

  /// Stable wire string.
  final String wire;

  /// Classifies a tool name into a kind. Tolerant of adapter naming
  /// (`Bash`/`bash`, `Read`/`read`, `apply_patch`, …).
  static EvaluationToolKind of(String name) {
    final n = name.toLowerCase();
    if (n.contains('patch')) {
      return EvaluationToolKind.patch;
    }
    if (n == 'read' || n.contains('read_file') || n == 'read_output') {
      return EvaluationToolKind.read;
    }
    if (n.contains('search') || n == 'grep' || n.contains('glob')) {
      return EvaluationToolKind.search;
    }
    if (n == 'find' || n.contains('list')) {
      return EvaluationToolKind.find;
    }
    if (n == 'edit' || n == 'write' || n.contains('str_replace')) {
      return EvaluationToolKind.edit;
    }
    if (n == 'bash' ||
        n == 'shell' ||
        n.contains('exec') ||
        n.contains('run')) {
      return EvaluationToolKind.exec;
    }
    return EvaluationToolKind.other;
  }
}

/// One observed tool call, kept minimal on purpose: enough to count re-reads,
/// repeated failures and invalid calls without storing full arguments (which
/// may contain secrets) in the audit artifact.
class EvaluationToolEvent {
  /// Creates an [EvaluationToolEvent].
  const EvaluationToolEvent({
    required this.name,
    this.isError = false,
    this.invalidArgs = false,
    this.target,
  });

  /// Parses from JSON.
  factory EvaluationToolEvent.fromJson(Map<String, dynamic> json) =>
      EvaluationToolEvent(
        name: json['name'] as String? ?? '',
        isError: json['isError'] as bool? ?? false,
        invalidArgs: json['invalidArgs'] as bool? ?? false,
        target: json['target'] as String?,
      );

  /// Tool name as the adapter reported it.
  final String name;

  /// Whether the result was an error.
  final bool isError;

  /// Whether the tool rejected the arguments before doing any work.
  final bool invalidArgs;

  /// A stable, non-secret identity for the call's target (path or the first
  /// token of a command), when one is available. Drives re-read detection.
  final String? target;

  /// The coarse class of this call.
  EvaluationToolKind get kind => EvaluationToolKind.of(name);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (isError) 'isError': true,
    if (invalidArgs) 'invalidArgs': true,
    if (target != null) 'target': target,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationToolEvent &&
          name == other.name &&
          isError == other.isError &&
          invalidArgs == other.invalidArgs &&
          target == other.target;

  @override
  int get hashCode => Object.hash(name, isError, invalidArgs, target);
}

/// Directly observed availability, file load, or script invocation. Availability
/// never implies that the model loaded or followed the skill.
class EvaluationSkillEvent {
  const EvaluationSkillEvent({
    required this.kind,
    required this.skillHash,
    required this.atEpochMs,
    required this.origin,
    this.path,
    this.toolUseId,
    this.observed = true,
  });

  factory EvaluationSkillEvent.fromJson(Map<String, dynamic> json) =>
      EvaluationSkillEvent(
        kind: json['kind'] as String,
        skillHash: json['skillHash'] as String,
        atEpochMs: (json['atEpochMs'] as num).toInt(),
        origin: json['origin'] as String,
        path: json['path'] as String?,
        toolUseId: json['toolUseId'] as String?,
        observed: json['observed'] as bool? ?? true,
      );

  final String kind;
  final String skillHash;
  final int atEpochMs;
  final String origin;
  final String? path;
  final String? toolUseId;
  final bool observed;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'skillHash': skillHash,
    'atEpochMs': atEpochMs,
    'origin': origin,
    if (path != null) 'path': path,
    if (toolUseId != null) 'toolUseId': toolUseId,
    'observed': observed,
  };

  @override
  bool operator ==(Object other) =>
      other is EvaluationSkillEvent &&
      kind == other.kind &&
      skillHash == other.skillHash &&
      atEpochMs == other.atEpochMs &&
      origin == other.origin &&
      path == other.path &&
      toolUseId == other.toolUseId &&
      observed == other.observed;

  @override
  int get hashCode => Object.hash(
    kind,
    skillHash,
    atEpochMs,
    origin,
    path,
    toolUseId,
    observed,
  );
}

/// The recovery / thrash metrics HARNESS_RESEARCH §6 requires, plus the
/// context-management evidence a memory experiment needs to prove it ran.
class EvaluationAttemptMetrics {
  /// Creates an [EvaluationAttemptMetrics].
  const EvaluationAttemptMetrics({
    this.toolCalls = 0,
    this.failedToolCalls = 0,
    this.invalidToolCalls = 0,
    this.repeatedFailedCalls = 0,
    this.reReads = 0,
    this.patchFailures = 0,
    this.modelRoundTrips = 0,
    this.providerCalls = 0,
    this.failedProviderCalls = 0,
    this.providerRetries = 0,
    this.userTurns = 0,
    this.compactions = 0,
    this.compactionRecoveries = 0,
    this.foldedSummaries = 0,
    this.maskedObservations = 0,
    this.snapshotFrames = 0,
    this.contextWindowTokens,
    this.policyDenials = 0,
    this.parallelWaves = 0,
    this.initMetadataMs,
  });

  /// Parses from JSON.
  factory EvaluationAttemptMetrics.fromJson(
    Map<String, dynamic> json,
  ) => EvaluationAttemptMetrics(
    toolCalls: (json['toolCalls'] as num?)?.toInt() ?? 0,
    failedToolCalls: (json['failedToolCalls'] as num?)?.toInt() ?? 0,
    invalidToolCalls: (json['invalidToolCalls'] as num?)?.toInt() ?? 0,
    repeatedFailedCalls: (json['repeatedFailedCalls'] as num?)?.toInt() ?? 0,
    reReads: (json['reReads'] as num?)?.toInt() ?? 0,
    patchFailures: (json['patchFailures'] as num?)?.toInt() ?? 0,
    modelRoundTrips: (json['modelRoundTrips'] as num?)?.toInt() ?? 0,
    providerCalls: (json['providerCalls'] as num?)?.toInt() ?? 0,
    failedProviderCalls: (json['failedProviderCalls'] as num?)?.toInt() ?? 0,
    providerRetries: (json['providerRetries'] as num?)?.toInt() ?? 0,
    userTurns: (json['userTurns'] as num?)?.toInt() ?? 0,
    compactions: (json['compactions'] as num?)?.toInt() ?? 0,
    compactionRecoveries: (json['compactionRecoveries'] as num?)?.toInt() ?? 0,
    foldedSummaries: (json['foldedSummaries'] as num?)?.toInt() ?? 0,
    maskedObservations: (json['maskedObservations'] as num?)?.toInt() ?? 0,
    snapshotFrames: (json['snapshotFrames'] as num?)?.toInt() ?? 0,
    contextWindowTokens: (json['contextWindowTokens'] as num?)?.toInt(),
    policyDenials: (json['policyDenials'] as num?)?.toInt() ?? 0,
    parallelWaves: (json['parallelWaves'] as num?)?.toInt() ?? 0,
    initMetadataMs: (json['initMetadataMs'] as num?)?.toInt(),
  );

  /// Derives the tool-derived counters from the observed call sequence.
  ///
  /// * re-reads — a `read` of a target already read this run;
  /// * repeated failed calls — a (name, target) pair that failed, then failed
  ///   again (a retry that changed nothing);
  /// * patch failures — a failed call whose kind is [EvaluationToolKind.patch];
  /// * invalid tool calls — a call the tool rejected for its arguments.
  factory EvaluationAttemptMetrics.fromToolEvents(
    List<EvaluationToolEvent> events, {
    int modelRoundTrips = 0,
    int providerCalls = 0,
    int failedProviderCalls = 0,
    int providerRetries = 0,
    int userTurns = 0,
    int compactions = 0,
    int compactionRecoveries = 0,
    int foldedSummaries = 0,
    int maskedObservations = 0,
    int snapshotFrames = 0,
    int? contextWindowTokens,
    int policyDenials = 0,
    int parallelWaves = 0,
    int? initMetadataMs,
  }) {
    final readTargets = <String>{};
    final failedSignatures = <String>{};
    var reReads = 0;
    var repeatedFailed = 0;
    var patchFailures = 0;
    var invalid = 0;
    var failed = 0;
    for (final event in events) {
      if (event.invalidArgs) {
        invalid++;
      }
      if (event.isError) {
        failed++;
        if (event.kind == EvaluationToolKind.patch) {
          patchFailures++;
        }
        final signature = '${event.name}\u0000${event.target ?? ''}';
        if (!failedSignatures.add(signature)) {
          repeatedFailed++;
        }
      }
      if (event.kind == EvaluationToolKind.read &&
          !event.isError &&
          event.target != null) {
        if (!readTargets.add(event.target!)) {
          reReads++;
        }
      }
    }
    return EvaluationAttemptMetrics(
      toolCalls: events.length,
      failedToolCalls: failed,
      invalidToolCalls: invalid,
      repeatedFailedCalls: repeatedFailed,
      reReads: reReads,
      patchFailures: patchFailures,
      modelRoundTrips: modelRoundTrips,
      providerCalls: providerCalls,
      failedProviderCalls: failedProviderCalls,
      providerRetries: providerRetries,
      userTurns: userTurns,
      compactions: compactions,
      compactionRecoveries: compactionRecoveries,
      foldedSummaries: foldedSummaries,
      maskedObservations: maskedObservations,
      snapshotFrames: snapshotFrames,
      contextWindowTokens: contextWindowTokens,
      policyDenials: policyDenials,
      parallelWaves: parallelWaves,
      initMetadataMs: initMetadataMs,
    );
  }

  /// Total tool calls made.
  final int toolCalls;

  /// Tool calls that returned an error.
  final int failedToolCalls;

  /// Tool calls rejected for malformed arguments.
  final int invalidToolCalls;

  /// Calls that failed, were retried identically, and failed again.
  final int repeatedFailedCalls;

  /// Reads of a target that was already read this run.
  final int reReads;

  /// Failed patch applications.
  final int patchFailures;

  /// Model-facing turns in the loop (its iterations), not physical requests.
  final int modelRoundTrips;

  /// Physical provider requests, counted from completed call records.
  final int providerCalls;

  /// Physical provider requests that did not succeed.
  final int failedProviderCalls;

  /// Provider retries (a second+ attempt at the same logical request).
  final int providerRetries;

  /// External user turns delivered to the agent.
  final int userTurns;

  /// Compaction passes the loop performed.
  final int compactions;

  /// Turns that ran after a compaction to recover lost context.
  final int compactionRecoveries;

  /// Passes that produced an anchored summary.
  final int foldedSummaries;

  /// Observations replaced by a recoverable reference (masking).
  final int maskedObservations;

  /// Snapshot pages rendered for the model (report 3G).
  final int snapshotFrames;

  /// The context window in force for the attempt, when the run had one.
  ///
  /// A memory-policy arm with no window performs no compaction at all, so the
  /// report refuses to treat such an arm as having exercised its policy.
  final int? contextWindowTokens;

  /// Tool calls denied by policy.
  final int policyDenials;

  /// Parallel tool waves observed.
  final int parallelWaves;

  /// Milliseconds from process start to the adapter's startup metadata.
  final int? initMetadataMs;

  /// Whether this attempt actually exercised a context-management rewrite.
  bool get rewritesHistory =>
      compactions > 0 || foldedSummaries > 0 || maskedObservations > 0;

  /// Whether a screenshot was rendered for the model.
  bool get renderedSnapshots => snapshotFrames > 0;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'toolCalls': toolCalls,
    'failedToolCalls': failedToolCalls,
    'invalidToolCalls': invalidToolCalls,
    'repeatedFailedCalls': repeatedFailedCalls,
    'reReads': reReads,
    'patchFailures': patchFailures,
    'modelRoundTrips': modelRoundTrips,
    'providerCalls': providerCalls,
    'failedProviderCalls': failedProviderCalls,
    'providerRetries': providerRetries,
    'userTurns': userTurns,
    'compactions': compactions,
    'compactionRecoveries': compactionRecoveries,
    'foldedSummaries': foldedSummaries,
    'maskedObservations': maskedObservations,
    'snapshotFrames': snapshotFrames,
    if (contextWindowTokens != null) 'contextWindowTokens': contextWindowTokens,
    'policyDenials': policyDenials,
    'parallelWaves': parallelWaves,
    if (initMetadataMs != null) 'initMetadataMs': initMetadataMs,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationAttemptMetrics &&
          toolCalls == other.toolCalls &&
          failedToolCalls == other.failedToolCalls &&
          invalidToolCalls == other.invalidToolCalls &&
          repeatedFailedCalls == other.repeatedFailedCalls &&
          reReads == other.reReads &&
          patchFailures == other.patchFailures &&
          modelRoundTrips == other.modelRoundTrips &&
          providerCalls == other.providerCalls &&
          failedProviderCalls == other.failedProviderCalls &&
          providerRetries == other.providerRetries &&
          userTurns == other.userTurns &&
          compactions == other.compactions &&
          compactionRecoveries == other.compactionRecoveries &&
          foldedSummaries == other.foldedSummaries &&
          maskedObservations == other.maskedObservations &&
          snapshotFrames == other.snapshotFrames &&
          contextWindowTokens == other.contextWindowTokens &&
          policyDenials == other.policyDenials &&
          parallelWaves == other.parallelWaves &&
          initMetadataMs == other.initMetadataMs;

  @override
  int get hashCode => Object.hashAll([
    toolCalls,
    failedToolCalls,
    invalidToolCalls,
    repeatedFailedCalls,
    reReads,
    patchFailures,
    modelRoundTrips,
    providerCalls,
    failedProviderCalls,
    providerRetries,
    userTurns,
    compactions,
    compactionRecoveries,
    foldedSummaries,
    maskedObservations,
    snapshotFrames,
    contextWindowTokens,
    policyDenials,
    parallelWaves,
    initMetadataMs,
  ]);
}

/// Where a [EvaluationVerificationResult] came from.
enum VerificationProvenance {
  /// A deterministic check of workspace bytes or a process exit status.
  behavioral('behavioral'),

  /// The same deterministic check, re-run during offline replay.
  replayDeterministic('replay_deterministic'),

  /// A model judge. Recorded, never counted as verified success.
  judgeAdvisory('judge_advisory');

  const VerificationProvenance(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [behavioral].
  static VerificationProvenance fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return VerificationProvenance.behavioral;
  }
}

/// The verdict of one acceptance check for one attempt.
class EvaluationVerificationResult {
  /// Creates an [EvaluationVerificationResult].
  const EvaluationVerificationResult({
    required this.verifierId,
    required this.passed,
    this.kind,
    this.authoritative = true,
    this.provenance = VerificationProvenance.behavioral,
    this.detail = '',
    this.skippedReason,
  });

  /// Parses from JSON.
  factory EvaluationVerificationResult.fromJson(Map<String, dynamic> json) =>
      EvaluationVerificationResult(
        verifierId: json['verifierId'] as String? ?? '',
        passed: json['passed'] as bool? ?? false,
        kind: json['kind'] == null
            ? null
            : EvaluationVerifierKind.fromWire(json['kind'] as String?),
        authoritative: json['authoritative'] as bool? ?? true,
        provenance: VerificationProvenance.fromWire(
          json['provenance'] as String?,
        ),
        detail: json['detail'] as String? ?? '',
        skippedReason: json['skippedReason'] as String?,
      );

  /// The verifier that produced this verdict.
  final String verifierId;

  /// Which acceptance check produced this verdict, when known.
  final EvaluationVerifierKind? kind;

  /// Whether the check passed.
  final bool passed;

  /// Whether this check is allowed to prove success.
  final bool authoritative;

  /// Where the verdict came from.
  final VerificationProvenance provenance;

  /// Human-readable explanation.
  final String detail;

  /// Why the check was skipped, when it was (never silently counted as a pass).
  final String? skippedReason;

  /// Whether the check ran at all.
  bool get ran => skippedReason == null;

  /// Whether this verdict *proves* the behaviour.
  bool get proves =>
      authoritative &&
      ran &&
      provenance != VerificationProvenance.judgeAdvisory;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'verifierId': verifierId,
    'passed': passed,
    if (kind != null) 'kind': kind!.wire,
    'authoritative': authoritative,
    'provenance': provenance.wire,
    if (detail.isNotEmpty) 'detail': detail,
    if (skippedReason != null) 'skippedReason': skippedReason,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationVerificationResult &&
          verifierId == other.verifierId &&
          passed == other.passed &&
          kind == other.kind &&
          authoritative == other.authoritative &&
          provenance == other.provenance &&
          detail == other.detail &&
          skippedReason == other.skippedReason;

  @override
  int get hashCode => Object.hash(
    verifierId,
    passed,
    kind,
    authoritative,
    provenance,
    detail,
    skippedReason,
  );
}

/// One attempt of one task under one arm: everything the report needs to judge
/// it, with the audit trail that makes the judgement reproducible.
///
/// An attempt is only ELIGIBLE evidence — for quality or for savings — when it
/// completed, every declared authoritative check RAN and passed, and nothing
/// observed contradicts the campaign's pin (served model, tool surface, CLI
/// version).
class EvaluationAttempt {
  /// Creates an [EvaluationAttempt].
  const EvaluationAttempt({
    required this.attemptId,
    required this.taskId,
    required this.taskKind,
    required this.armId,
    required this.effective,
    required this.stratum,
    required this.repetition,
    required this.seed,
    required this.startedAtEpochMs,
    this.ordinal = 0,
    this.executionMode = EvaluationExecutionMode.live,
    this.resumedSession = false,
    this.sessionId,
    this.servedModel,
    this.servedEffort,
    this.observedCliVersion,
    this.observedToolSurfaceHash,
    this.completed = false,
    this.error,
    this.tokens = const EvaluationTokenBreakdown(),
    this.cost = const EvaluationCostRoles(),
    this.latency = const EvaluationLatency(),
    this.metrics = const EvaluationAttemptMetrics(),
    this.toolEvents = const [],
    this.skillEvents = const [],
    this.verification = const [],
    this.expectedAuthoritativeChecks,
    this.identityMismatches = const [],
    this.filesTouched = const [],
    this.transcriptRef,
    this.notes = '',
  });

  /// Parses from JSON.
  factory EvaluationAttempt.fromJson(
    Map<String, dynamic> json,
  ) => EvaluationAttempt(
    attemptId: json['attemptId'] as String? ?? '',
    taskId: json['taskId'] as String? ?? '',
    taskKind: EvaluationTaskKind.fromWire(json['taskKind'] as String?),
    armId: json['armId'] as String? ?? '',
    effective: EvaluationEffectiveConfig(
      adapter: (json['effective'] as Map?)?['adapter'] as String? ?? '',
      providerId: (json['effective'] as Map?)?['providerId'] as String? ?? '',
      modelId: (json['effective'] as Map?)?['modelId'] as String? ?? '',
      effortLevel: (json['effective'] as Map?)?['effortLevel'] as String?,
      memoryPolicy: MemoryPolicyMode.fromWire(
        (json['effective'] as Map?)?['memoryPolicy'] as String?,
      ),
      sessionContinuity: SessionContinuityMode.fromWire(
        (json['effective'] as Map?)?['sessionContinuity'] as String?,
      ),
      mcpDiscoveryCache: McpDiscoveryCacheMode.fromWire(
        (json['effective'] as Map?)?['mcpDiscoveryCache'] as String?,
      ),
      toolOverlap: ToolOverlapMode.fromWire(
        (json['effective'] as Map?)?['toolOverlap'] as String?,
      ),
      skillExposure: (json['effective'] as Map?)?['skillExposure'] == null
          ? null
          : SkillExposure.fromWire(
              (json['effective'] as Map)['skillExposure'] as String,
            ),
    ),
    stratum: CacheStratum.fromWire(json['stratum'] as String?),
    repetition: (json['repetition'] as num?)?.toInt() ?? 0,
    seed: (json['seed'] as num?)?.toInt() ?? 0,
    startedAtEpochMs: (json['startedAtEpochMs'] as num?)?.toInt() ?? 0,
    ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
    executionMode: EvaluationExecutionMode.fromWire(
      json['executionMode'] as String?,
    ),
    resumedSession: json['resumedSession'] as bool? ?? false,
    sessionId: json['sessionId'] as String?,
    servedModel: json['servedModel'] as String?,
    servedEffort: json['servedEffort'] as String?,
    observedCliVersion: json['observedCliVersion'] as String?,
    observedToolSurfaceHash: json['observedToolSurfaceHash'] as String?,
    completed: json['completed'] as bool? ?? false,
    error: json['error'] as String?,
    tokens: json['tokens'] == null
        ? const EvaluationTokenBreakdown()
        : EvaluationTokenBreakdown.fromJson(
            (json['tokens'] as Map).cast<String, dynamic>(),
          ),
    cost: json['cost'] == null
        ? const EvaluationCostRoles()
        : EvaluationCostRoles.fromJson(
            (json['cost'] as Map).cast<String, dynamic>(),
          ),
    latency: json['latency'] == null
        ? const EvaluationLatency()
        : EvaluationLatency.fromJson(
            (json['latency'] as Map).cast<String, dynamic>(),
          ),
    metrics: json['metrics'] == null
        ? const EvaluationAttemptMetrics()
        : EvaluationAttemptMetrics.fromJson(
            (json['metrics'] as Map).cast<String, dynamic>(),
          ),
    toolEvents:
        (json['toolEvents'] as List?)
            ?.map(
              (e) => EvaluationToolEvent.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList() ??
        const [],
    skillEvents:
        (json['skillEvents'] as List?)
            ?.map(
              (e) => EvaluationSkillEvent.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList() ??
        const [],
    verification:
        (json['verification'] as List?)
            ?.map(
              (e) => EvaluationVerificationResult.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList() ??
        const [],
    expectedAuthoritativeChecks: (json['expectedAuthoritativeChecks'] as num?)
        ?.toInt(),
    identityMismatches:
        (json['identityMismatches'] as List?)?.map((e) => '$e').toList() ??
        const [],
    filesTouched:
        (json['filesTouched'] as List?)?.map((e) => '$e').toList() ?? const [],
    transcriptRef: json['transcriptRef'] as String?,
    notes: json['notes'] as String? ?? '',
  );

  /// Unique attempt id (stable across replay: the recorded attempt keeps it).
  final String attemptId;

  /// The task that ran.
  final String taskId;

  /// The task's class, denormalized so a report can group without the corpus.
  final EvaluationTaskKind taskKind;

  /// The arm it ran under.
  final String armId;

  /// The effective configuration (manifest + arm deviation).
  final EvaluationEffectiveConfig effective;

  /// The cache stratum.
  final CacheStratum stratum;

  /// Repetition index within (task, arm, stratum).
  final int repetition;

  /// The repeat seed handed to the backend.
  final int seed;

  /// Scheduled position in the randomized order.
  final int ordinal;

  /// Wall-clock start, epoch ms.
  final int startedAtEpochMs;

  /// Live or offline replay.
  final EvaluationExecutionMode executionMode;

  /// Whether the run resumed a native session (report 4B).
  final bool resumedSession;

  /// The adapter's session id, when it exposes one.
  final String? sessionId;

  /// The model the provider actually served, when reported.
  final String? servedModel;

  /// The effort actually applied, when reported.
  final String? servedEffort;

  /// The external CLI version the adapter OBSERVED at startup, when it reports
  /// one. Compared against the manifest pin.
  final String? observedCliVersion;

  /// A hash of the tool surface the adapter observed, when it reports one.
  ///
  /// Two paired attempts with different observed surfaces are not comparable,
  /// which is exactly the kind of silent drift a manifest alone cannot catch.
  final String? observedToolSurfaceHash;

  /// Whether the run reached a clean terminal state.
  final bool completed;

  /// Harness fault detail when the attempt did not complete.
  final String? error;

  /// Tokens by cache role.
  final EvaluationTokenBreakdown tokens;

  /// Cost by role (micro-USD).
  final EvaluationCostRoles cost;

  /// Latency stages.
  final EvaluationLatency latency;

  /// Recovery / thrash / context-management metrics.
  final EvaluationAttemptMetrics metrics;

  /// The observed tool-call sequence.
  final List<EvaluationToolEvent> toolEvents;

  /// Skill exposure/load observations; absence of a load may be unobservable.
  final List<EvaluationSkillEvent> skillEvents;

  /// The acceptance-check verdicts.
  final List<EvaluationVerificationResult> verification;

  /// How many authoritative checks this trial DECLARED.
  ///
  /// Set by the engine from the task (plus any arm-scoped fidelity checks). A
  /// skipped check leaves a hole here, and a hole blocks verified success.
  final int? expectedAuthoritativeChecks;

  /// Observed contradictions of the campaign pin.
  final List<String> identityMismatches;

  /// Workspace-relative paths the run changed.
  final List<String> filesTouched;

  /// A reference to the stored transcript, when one was kept.
  final String? transcriptRef;

  /// Operator notes.
  final String notes;

  /// Whether this was a live run.
  bool get live => executionMode == EvaluationExecutionMode.live;

  /// Verdicts that actually ran and are allowed to prove success.
  List<EvaluationVerificationResult> get proving => [
    for (final v in verification)
      if (v.proves) v,
  ];

  /// Whether every declared authoritative check ran.
  bool get verificationComplete {
    final expected = expectedAuthoritativeChecks;
    return expected != null && proving.length == expected;
  }

  /// Whether an independent behavioral check proved the task's behaviour.
  ///
  /// Requires the run to have completed, at least one declared authoritative
  /// check, EVERY declared check to have run, and all of them to pass. A
  /// skipped check is missing evidence, and missing evidence is never a pass.
  bool get verifiedSuccess =>
      completed &&
      identityMismatches.isEmpty &&
      verificationComplete &&
      proving.isNotEmpty &&
      proving.every((v) => v.passed);

  /// Whether any check that ran failed.
  bool get verificationFailed => proving.any((v) => !v.passed);

  /// Whether this attempt's cost is usable for savings arithmetic.
  bool get costComparable => cost.isComplete;

  /// Whether a memory arm actually exercised its interaction.
  bool get interventionExercised =>
      metrics.contextWindowTokens != null && metrics.rewritesHistory;

  /// The cost used for cost-per-success arithmetic: every attempt, including
  /// failures and auxiliary calls, or null when unpriced.
  int? get attemptCostMicros => cost.allAttemptMicros;

  /// A machine-readable grouping key for paired analysis.
  String get pairKey => '$taskId\u0000${stratum.wire}\u0000$repetition';

  /// Returns a copy with the given fields replaced.
  EvaluationAttempt copyWith({
    List<EvaluationVerificationResult>? verification,
    bool? completed,
    String? error,
    List<String>? filesTouched,
    List<EvaluationToolEvent>? toolEvents,
    List<EvaluationSkillEvent>? skillEvents,
    EvaluationAttemptMetrics? metrics,
    String? transcriptRef,
    String? sessionId,
    bool? resumedSession,
    String? servedModel,
    String? servedEffort,
    String? observedCliVersion,
    String? observedToolSurfaceHash,
    EvaluationExecutionMode? executionMode,
    int? ordinal,
    int? expectedAuthoritativeChecks,
    List<String>? identityMismatches,
    EvaluationLatency? latency,
    String? notes,
  }) => EvaluationAttempt(
    attemptId: attemptId,
    taskId: taskId,
    taskKind: taskKind,
    armId: armId,
    effective: effective,
    stratum: stratum,
    repetition: repetition,
    seed: seed,
    startedAtEpochMs: startedAtEpochMs,
    ordinal: ordinal ?? this.ordinal,
    executionMode: executionMode ?? this.executionMode,
    resumedSession: resumedSession ?? this.resumedSession,
    sessionId: sessionId ?? this.sessionId,
    servedModel: servedModel ?? this.servedModel,
    servedEffort: servedEffort ?? this.servedEffort,
    observedCliVersion: observedCliVersion ?? this.observedCliVersion,
    observedToolSurfaceHash:
        observedToolSurfaceHash ?? this.observedToolSurfaceHash,
    completed: completed ?? this.completed,
    error: error ?? this.error,
    tokens: tokens,
    cost: cost,
    latency: latency ?? this.latency,
    metrics: metrics ?? this.metrics,
    toolEvents: toolEvents ?? this.toolEvents,
    skillEvents: skillEvents ?? this.skillEvents,
    verification: verification ?? this.verification,
    expectedAuthoritativeChecks:
        expectedAuthoritativeChecks ?? this.expectedAuthoritativeChecks,
    identityMismatches: identityMismatches ?? this.identityMismatches,
    filesTouched: filesTouched ?? this.filesTouched,
    transcriptRef: transcriptRef ?? this.transcriptRef,
    notes: notes ?? this.notes,
  );

  /// Projects this attempt into the existing [EvalOutcome] shape so the
  /// existing `GraderSpec` graders can be run over it unchanged.
  ///
  /// The signals are derived from the *verifier* results, never from the
  /// model's prose.
  EvalOutcome toEvalOutcome() {
    final signals = <String, Object>{
      for (final v in verification)
        if (v.ran) v.verifierId: v.passed,
      'verifiedSuccess': verifiedSuccess,
      'testsPassed': _allKindPassed(EvaluationVerifierKind.tests),
      'buildPassed': _allKindPassed(EvaluationVerifierKind.commandExit),
      'noWrites': _allKindPassed(EvaluationVerifierKind.noWrites),
      'diffApplied': _allKindPassed(EvaluationVerifierKind.diffApplies),
      'judgeOnly': proving.isEmpty && verification.isNotEmpty,
    };
    return EvalOutcome(
      completed: completed,
      costCents: cost.allAttemptCents,
      turnCount: metrics.modelRoundTrips,
      toolCalls: [for (final e in toolEvents) e.name],
      sandboxViolations: metrics.policyDenials,
      filesTouched: filesTouched,
      durationMs: latency.totalMs,
      signals: signals,
      error: error,
    );
  }

  bool _allKindPassed(EvaluationVerifierKind kind) {
    final relevant = [
      for (final v in verification)
        if (v.kind == kind) v,
    ];
    return relevant.isNotEmpty && relevant.every((v) => v.passed);
  }

  /// Projects this attempt's acceptance evidence into the observability
  /// domain's [RunVerification], so a caller that persists a run log records
  /// the INDEPENDENT VERDICT rather than inferring success from completion.
  ///
  /// Unchecked (no proving verifier, a skipped check, or the harness faulted
  /// before any check could apply) maps to [VerificationStatus.unverified] —
  /// never to a pass.
  RunVerification toRunVerification({DateTime? at}) {
    final proving = this.proving;
    if (!completed ||
        proving.isEmpty ||
        !verificationComplete ||
        identityMismatches.isNotEmpty) {
      return RunVerification(
        status: VerificationStatus.unverified,
        verifier: proving.isEmpty
            ? null
            : proving.map((v) => v.verifierId).join(', '),
        verifiedAt: at,
        notes:
            error ??
            (identityMismatches.isNotEmpty
                ? identityMismatches.join('; ')
                : verificationComplete
                ? 'no authoritative check'
                : 'a declared authoritative check did not run'),
      );
    }
    final failed = [
      for (final v in proving)
        if (!v.passed) v,
    ];
    return RunVerification(
      status: failed.isEmpty
          ? VerificationStatus.passed
          : VerificationStatus.failed,
      verifier: (failed.isEmpty ? proving : failed)
          .map((v) => v.verifierId)
          .join(', '),
      verifiedAt: at,
      notes: failed.isEmpty
          ? null
          : 'failed: ${failed.map((v) => v.verifierId).join(', ')}',
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'taskId': taskId,
    'taskKind': taskKind.wire,
    'armId': armId,
    'effective': effective.toJson(),
    'stratum': stratum.wire,
    'repetition': repetition,
    'seed': seed,
    'ordinal': ordinal,
    'startedAtEpochMs': startedAtEpochMs,
    'executionMode': executionMode.wire,
    'resumedSession': resumedSession,
    if (sessionId != null) 'sessionId': sessionId,
    if (servedModel != null) 'servedModel': servedModel,
    if (servedEffort != null) 'servedEffort': servedEffort,
    if (observedCliVersion != null) 'observedCliVersion': observedCliVersion,
    if (observedToolSurfaceHash != null)
      'observedToolSurfaceHash': observedToolSurfaceHash,
    'completed': completed,
    if (error != null) 'error': error,
    'tokens': tokens.toJson(),
    'cost': cost.toJson(),
    'latency': latency.toJson(),
    'metrics': metrics.toJson(),
    if (toolEvents.isNotEmpty)
      'toolEvents': [for (final e in toolEvents) e.toJson()],
    if (skillEvents.isNotEmpty)
      'skillEvents': [for (final e in skillEvents) e.toJson()],
    'verification': [for (final v in verification) v.toJson()],
    if (expectedAuthoritativeChecks != null)
      'expectedAuthoritativeChecks': expectedAuthoritativeChecks,
    if (identityMismatches.isNotEmpty) 'identityMismatches': identityMismatches,
    if (filesTouched.isNotEmpty) 'filesTouched': filesTouched,
    if (transcriptRef != null) 'transcriptRef': transcriptRef,
    if (notes.isNotEmpty) 'notes': notes,
    'verifiedSuccess': verifiedSuccess,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationAttempt &&
          attemptId == other.attemptId &&
          taskId == other.taskId &&
          taskKind == other.taskKind &&
          armId == other.armId &&
          effective == other.effective &&
          stratum == other.stratum &&
          repetition == other.repetition &&
          seed == other.seed &&
          ordinal == other.ordinal &&
          startedAtEpochMs == other.startedAtEpochMs &&
          executionMode == other.executionMode &&
          resumedSession == other.resumedSession &&
          sessionId == other.sessionId &&
          servedModel == other.servedModel &&
          servedEffort == other.servedEffort &&
          observedCliVersion == other.observedCliVersion &&
          observedToolSurfaceHash == other.observedToolSurfaceHash &&
          completed == other.completed &&
          error == other.error &&
          tokens == other.tokens &&
          cost == other.cost &&
          latency == other.latency &&
          metrics == other.metrics &&
          expectedAuthoritativeChecks == other.expectedAuthoritativeChecks &&
          notes == other.notes &&
          transcriptRef == other.transcriptRef &&
          _listEq(toolEvents, other.toolEvents) &&
          _listEq(skillEvents, other.skillEvents) &&
          _listEq(verification, other.verification) &&
          _listEq(identityMismatches, other.identityMismatches) &&
          _listEq(filesTouched, other.filesTouched);

  @override
  int get hashCode => Object.hashAll([
    attemptId,
    taskId,
    taskKind,
    armId,
    effective,
    stratum,
    repetition,
    seed,
    ordinal,
    startedAtEpochMs,
    executionMode,
    resumedSession,
    sessionId,
    servedModel,
    servedEffort,
    observedCliVersion,
    observedToolSurfaceHash,
    completed,
    error,
    tokens,
    cost,
    latency,
    metrics,
    expectedAuthoritativeChecks,
    notes,
    transcriptRef,
    Object.hashAll(toolEvents),
    Object.hashAll(skillEvents),
    Object.hashAll(verification),
    Object.hashAll(identityMismatches),
    Object.hashAll(filesTouched),
  ]);
}

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
