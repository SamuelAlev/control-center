import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/context/snapcompact_compactor.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
import 'package:cc_infra/src/evaluation/local_evaluation_command_runner.dart';
import 'package:cc_infra/src/evaluation/provider_call_budget_guard.dart';
import 'package:cc_infra/src/harness/file_tool_output_store.dart';
import 'package:path/path.dart' as p;

/// Builds the context compactor for a memory policy under test.
typedef EvaluationCompactorFactory =
    HarnessCompactor? Function({
      required MemoryPolicyMode policy,
      required LlmProviderPort provider,
      required String providerId,
      required String modelId,
      required bool readerHasVision,
      required TokenCalibration calibration,
      required void Function(HarnessCompactionResult result) onResult,
    });

/// Runs an attempt through Control Center's OWN agent loop, in-process.
///
/// Everything a policy arm claims is executed for real:
///  * the provider is wrapped in [ObservedLlmProvider], so cost, tokens, call
///    counts and retries come from COMPLETED PHYSICAL RECORDS — not from
///    streaming usage deltas (a request can emit input and output separately,
///    and individually sub-cent charges would vanish);
///  * the context window is set, so compaction actually runs;
///  * the compactor is the shipped one for the arm's policy, wrapped so the
///    fold/mask/snapshot it performed is recorded as evidence;
///  * tool observations are ingested into a real per-workspace
///    [FileToolOutputStore] and `read_output` is on the surface, so masking has
///    recoverable references.
///
/// A policy this backend cannot implement is REFUSED up front via
/// [unsupportedReason] — it never silently runs the default.
class BuiltinEvaluationBackend implements EvaluationBackendPort {
  /// Creates a [BuiltinEvaluationBackend].
  BuiltinEvaluationBackend({
    this.factory = const HarnessProviderFactory(),
    this.credential,
    this.commandRunner,
    this.commandRunnerFactory,
    this.cancel,
    this.controlledFileToolsFactory,
    this.costLimitMicros,
    this.maxCallMicros,
    this.stopAfterCall = false,
    this.skillEventsForTool,
    this.approvalCallbackFactory,
    this.priceLookup,
    this.systemPrompt = defaultSystemPrompt,
    this.includeWebFetch = true,
    this.maxToolCalls = 240,
    this.compactorFactory,
    this.visionLookup,
    this.effortCapabilityLookup,
    this.toolOutputDir,
    this.tokenCalibration,
    this.contextWindowTokens,
    this.maxParallelToolCalls = 4,
    this.onNotice,
  });

  /// The default system prompt for evaluated runs.
  static const String defaultSystemPrompt =
      "You are Control Center's coding agent, working alone in an isolated "
      'workspace. Use the available tools to read, search, edit and run code '
      'to accomplish the task. Be concise and stop when the task is done.';

  /// Builds providers from a provider id + credential.
  final HarnessProviderFactory factory;

  /// The credential to authenticate with. Null means UNAUTHENTICATED, which is
  /// valid only for local endpoints — a hosted provider then fails honestly
  /// rather than sending an empty key.
  final ProviderCredential? credential;

  /// The command runner backing the `bash` tool. When null the backend builds
  /// a [LocalEvaluationCommandRunner] over the attempt's workspace.
  final HarnessCommandRunner? commandRunner;

  /// Controlled runs inject one strict runner per fresh attempt.
  final HarnessCommandRunner Function(EvaluationAttemptRequest)?
  commandRunnerFactory;

  /// Replaces every host filesystem tool for controlled skill attempts only.
  /// A missing factory retains the ordinary evaluator's existing behavior.
  final List<HarnessTool> Function(ControlledEvaluationProcess)?
  controlledFileToolsFactory;

  /// Interrupts model streams and contained tools when the campaign is cancelled.
  final CancellationToken? cancel;

  /// Remaining campaign allowance at the start of this attempt. Strict for
  /// reserved calls; a post-call stopping threshold for subscription calls.
  final int? costLimitMicros;

  /// Worst-case reservation per physical call, null in stop-after-call mode.
  final int? maxCallMicros;

  /// Subscription usage threshold: allow one call while below budget, then
  /// stop using observed API-equivalent cost. Not a hard spending ceiling.
  final bool stopAfterCall;

  /// A direct tool-result observer (never inference from model prose).
  final EvaluationSkillEvent? Function(
    EvaluationAttemptRequest,
    String,
    String,
    Map<String, dynamic>,
    HarnessToolResult,
  )?
  skillEventsForTool;

  /// Supplies the attempt's tool-approval policy.
  final ToolApprovalCallback Function(EvaluationAttemptRequest)?
  approvalCallbackFactory;

  /// Prices a completed provider call. A null return means UNPRICED, and
  /// unpriced spend is recorded as unknown — never as zero.
  final ProviderCallCost? Function(ProviderCallRecord record)? priceLookup;

  /// The system prompt sent to the model.
  final String systemPrompt;

  /// Whether the `web_fetch` tool is on the surface.
  final bool includeWebFetch;

  /// Hard ceiling on tool calls in one attempt.
  final int maxToolCalls;

  /// Compactor factory override; null uses the shipped compactors.
  final EvaluationCompactorFactory? compactorFactory;

  /// Whether a served model can read images (snapshot folding needs it).
  final bool Function(String qualifiedModel)? visionLookup;

  /// Whether a served model can actually apply a reasoning effort.
  ///
  /// The wire request silently omits the effort for providers that do not
  /// support it, which would make an effort arm identical to its baseline while
  /// being reported as different — so an effort arm is refused unless this says
  /// the model honours it.
  final bool Function(String qualifiedModel)? effortCapabilityLookup;

  /// Root directory for the durable tool-output store.
  final String? toolOutputDir;

  /// Provider-usage calibration threaded to the compactor.
  final TokenCalibration? tokenCalibration;

  /// The context window in force. Required for an arm that rewrites history.
  final int? contextWindowTokens;

  /// Parallel tool-call width.
  final int maxParallelToolCalls;

  /// Optional progress sink.
  final void Function(String message)? onNotice;

  @override
  String get id => 'builtin';

  @override
  bool get callsModel => true;

  /// The pinned tool catalog this backend exposes, in schema order.
  List<String> get toolNames => [
    'read',
    'write',
    'edit',
    'search',
    'find',
    'bash',
    'read_output',
    if (includeWebFetch) 'web_fetch',
  ];

  /// The canonical `[name, schemaHash]` fingerprint of the tool surface this
  /// backend actually exposes, for the manifest's tool pin.
  List<List<String>> toolCatalogFingerprints() {
    final HarnessCommandRunner runner = controlledFileToolsFactory == null
        ? LocalEvaluationCommandRunner(workspaceRoot: '.')
        : ControlledEvaluationProcess(root: '.', home: '.');
    final tools = _buildTools(
      runner,
      controlledFiles: runner is ControlledEvaluationProcess
          ? controlledFileToolsFactory!(runner)
          : null,
    );
    final fingerprints = <List<String>>[];
    for (final tool in tools) {
      final schema = tool.toSchema();
      fingerprints.add([
        schema.name,
        canonicalHash({
          'name': schema.name,
          'description': schema.description,
          'inputSchema': schema.inputSchema,
          'deferLoading': schema.deferLoading,
        }),
      ]);
    }
    fingerprints.sort((a, b) => a.first.compareTo(b.first));
    return fingerprints;
  }

  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) {
    final qualified = _qualified(effective);
    if (effective.skillExposure != null && controlledFileToolsFactory == null) {
      return 'skill exposure requires a controlled attempt with isolated '
          'file tools and an admitted skill snapshot';
    }
    if (effective.memoryPolicy != MemoryPolicyMode.textCurrent) {
      if (contextWindowTokens == null || contextWindowTokens! <= 0) {
        return 'memory policy ${effective.memoryPolicy.wire} needs a positive '
            'context window, or the loop would never compact';
      }
      if (effective.memoryPolicy == MemoryPolicyMode.snapshotImages &&
          !(visionLookup?.call(qualified) ?? false)) {
        return 'snapshot compaction needs a vision-capable reader, and nothing '
            'reported $qualified as image-capable';
      }
    }
    if (effective.effortLevel != null &&
        effective.effortLevel!.trim().isNotEmpty &&
        !(effortCapabilityLookup?.call(qualified) ?? false)) {
      return 'the provider/model pair $qualified does not apply a reasoning '
          'effort, so the arm would run the same wire request as its baseline';
    }
    if (effective.mcpDiscoveryCache == McpDiscoveryCacheMode.enabled) {
      return 'the MCP discovery cache belongs to the Claude CLI; the builtin '
          'harness has no MCP discovery step to cache';
    }
    if (effective.sessionContinuity == SessionContinuityMode.nativeResume) {
      return 'native session resume is a Claude CLI capability; the builtin '
          'harness continues a conversation through its transcript store';
    }
    if (effective.toolOverlap == ToolOverlapMode.overlapReadOnly &&
        !_hasOverlapSafeTool) {
      return 'no tool on this surface declares speculativeReadSafe, so the '
          'overlap mode would be a no-op';
    }
    return null;
  }

  bool get _hasOverlapSafeTool => _buildTools(
    LocalEvaluationCommandRunner(workspaceRoot: '.'),
  ).any((tool) => tool.speculativeReadSafe);

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    final started = Stopwatch()..start();
    final startedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    final qualified = _qualified(request.effective);
    final parsed = factory.parseModel(qualified);

    // ONE ledger for this attempt: the provider wrapper records into it and the
    // LOOP is given the same ledger (it reads the physical records for budget
    // accounting and never wraps the provider itself), so every call is counted
    // exactly once under this attempt's run id.
    final ledger = ProviderCallLedger(runId: request.attemptId);
    final resolver = priceLookup;
    final snapshotCounter = _Counter();

    final toolEvents = <EvaluationToolEvent>[];
    final pendingTargets = <String, EvaluationToolEvent>{};
    final skillEvents = <EvaluationSkillEvent>[];
    final pendingArguments = <String, Map<String, dynamic>>{};
    var openCalls = 0;
    var parallelWaves = 0;
    var sweptAFullWave = false;
    var foldSummaries = 0;
    var maskedObservations = 0;
    var snapshotFrames = 0;
    var compactions = 0;
    String? error;
    var completed = false;
    int? firstModelEventMs;
    int? firstUsefulTextMs;
    var toolCeilingHit = false;
    String? servedDefaultModel;
    final turns = [request.task.prompt, ...request.task.followUps];

    bool budgetExceeded() {
      if (costLimitMicros == null) {
        return false;
      }
      final recorded = ledger.records;
      if (recorded.any((r) => r.costMicros == null)) {
        return true;
      }
      final spent = recorded.fold<int>(0, (sum, r) => sum + r.costMicros!);
      if (stopAfterCall) {
        return spent >= costLimitMicros!;
      }
      final reservation = maxCallMicros;
      return reservation == null || spent + reservation > costLimitMicros!;
    }

    try {
      final base = factory.create(
        providerId: parsed.providerId,
        model: parsed.model,
        credential: credential,
      );
      servedDefaultModel = base.defaultModel;
      final observed = ObservedLlmProvider(
        base,
        observer: ledger,
        identity: ledger.identity,
        runId: request.attemptId,
        costResolver: resolver == null
            ? null
            : (record) {
                if (!record.usageReported) {
                  return null;
                }
                return resolver(record);
              },
      );
      final LlmProviderPort provider = costLimitMicros == null
          ? observed
          : ProviderCallBudgetGuard(
              observed,
              canBegin: () => !budgetExceeded(),
            );
      final runner =
          commandRunnerFactory?.call(request) ??
          commandRunner ??
          LocalEvaluationCommandRunner(workspaceRoot: request.workspaceRoot);
      final store = _toolOutputStore(request);
      final ingest = ToolObservationIngest(store: store);
      final calibration = tokenCalibration ?? TokenCalibration();
      final tools = _buildTools(
        runner,
        store: store,
        controlledFiles: controlledFileToolsFactory?.call(
          runner is ControlledEvaluationProcess
              ? runner
              : throw StateError(
                  'controlled file tools need an isolated process',
                ),
        ),
      );
      final hasOverlapSafe = tools.any((tool) => tool.speculativeReadSafe);

      final transcript = InMemoryHarnessTranscriptStore();
      final transcriptKey = 'cc-eval/${request.attemptId}';
      final context = HarnessToolContext(
        workingDirectory: request.workspaceRoot,
        workspaceId: 'cc-eval',
        conversationId: request.attemptId,
        agentId: 'cc-eval',
      );

      for (final turn in turns) {
        final history = <HarnessMessage>[
          ...?((await transcript.load(transcriptKey))?.messages),
        ];
        final compactor = _compactor(
          policy: request.effective.memoryPolicy,
          provider: provider,
          providerId: parsed.providerId,
          modelId: parsed.model ?? provider.defaultModel,
          readerHasVision: visionLookup?.call(qualified) ?? false,
          calibration: calibration,
          onResult: (result) {
            if (result.summarized) {
              foldSummaries++;
            }
            maskedObservations += result.maskedObservations;
            if (result.changed) {
              compactions++;
            }
          },
          onPruneChanged: (changed) {
            // Under a masking policy the prune pass is where stale observations
            // are replaced by recoverable references; the returned count is the
            // blocks it rewrote (elisions, image sheds and masks).
            maskedObservations += changed;
          },
          snapshotCounter: snapshotCounter,
        );
        final config = AgentLoopConfig(
          systemPrompt: systemPrompt,
          model: parsed.model,
          maxTurns: request.task.maxTurns,
          effort: ReasoningEffort.fromId(request.effective.effortLevel),
          cacheKey: 'cc-eval:${request.task.id}',
          cacheEnabled: request.effective.cacheEnabled,
          autoApprove: true,
          approvalCallback: approvalCallbackFactory?.call(request),
          budget: costLimitMicros == null
              ? const HarnessBudget()
              : const HarnessBudget(timeBudget: Duration(minutes: 15)),
          externalBudgetExceeded: budgetExceeded,
          maxProviderRetries: costLimitMicros == null ? 3 : 0,
          contextWindow: contextWindowTokens,
          maxParallelToolCalls: maxParallelToolCalls,
          overlapReadOnlyTools:
              hasOverlapSafe &&
              request.effective.toolOverlap == ToolOverlapMode.overlapReadOnly,
          compactor: compactor,
          tokenCalibration: calibration,
          observationIngest: ingest,
          callLedger: ledger,
          purpose: LlmCallPurpose.main,
          transcriptStore: transcript,
          transcriptKey: transcriptKey,
        );

        await for (final event in const AgentLoopRunner().run(
          history: history,
          userMessage: turn,
          tools: tools,
          provider: provider,
          context: context,
          config: config,
          cancel: cancel,
        )) {
          switch (event) {
            case LoopTextDelta(:final text):
              firstModelEventMs ??= started.elapsedMilliseconds;
              if (firstUsefulTextMs == null && text.trim().isNotEmpty) {
                firstUsefulTextMs = started.elapsedMilliseconds;
              }
            case LoopThinkingDelta():
              firstModelEventMs ??= started.elapsedMilliseconds;
            case LoopToolCallStart(
              :final toolName,
              :final toolUseId,
              :final args,
            ):
              firstModelEventMs ??= started.elapsedMilliseconds;
              firstUsefulTextMs ??= started.elapsedMilliseconds;
              openCalls++;
              if (openCalls >= 2 && !sweptAFullWave) {
                parallelWaves++;
                sweptAFullWave = true;
              }
              pendingTargets[toolUseId] = EvaluationToolEvent(
                name: toolName,
                target: _targetOf(toolName, args),
              );
              pendingArguments[toolUseId] = args;
            case LoopToolCallResult(
              :final toolName,
              :final toolUseId,
              :final result,
            ):
              openCalls = openCalls > 0 ? openCalls - 1 : 0;
              if (openCalls == 0) {
                sweptAFullWave = false;
              }
              final opened = pendingTargets.remove(toolUseId);
              toolEvents.add(
                EvaluationToolEvent(
                  name: opened?.name ?? toolName,
                  isError: result.isError,
                  invalidArgs:
                      result.isError &&
                      result.content.startsWith('Missing or invalid argument'),
                  target: opened?.target,
                ),
              );
              final arguments = pendingArguments.remove(toolUseId);
              if (arguments != null) {
                final observation = skillEventsForTool?.call(
                  request,
                  toolName,
                  toolUseId,
                  arguments,
                  result,
                );
                if (observation != null) {
                  skillEvents.add(observation);
                }
              }
            case LoopUsage():
              // The physical-call ledger records usage and cost exactly once.
              break;
            case LoopCompaction(:final summarized, :final messagesFolded):
              // The compactor decorator already recorded the pass; this only
              // surfaces it to the operator.
              onNotice?.call(
                'context ${summarized ? 'compacted' : 'pruned'}: '
                '$messagesFolded message(s) folded',
              );
            case LoopToolsActivated(:final names, :final trigger):
              onNotice?.call('activated ${names.join(', ')} via $trigger');
            case LoopNotice(:final message):
              onNotice?.call(message);
            case LoopAdvisorNote(:final note):
              onNotice?.call('advisor: $note');
            case LoopError(:final message, :final code):
              error = code == null ? message : '$code: $message';
            case LoopTurnComplete():
              // A completed assistant turn is not a terminal state; nothing to
              // do here (the terminal reasons arrive on LoopDone).
              break;
            case LoopDone(:final reason, :final unmetContractId):
              completed = reason == LoopDoneReason.completed;
              if (!completed && error == null) {
                error =
                    'loop ended: ${reason.name}'
                    '${unmetContractId == null ? '' : ' ($unmetContractId)'}';
              }
          }
          if (toolEvents.length > maxToolCalls) {
            toolCeilingHit = true;
            error = 'tool-call ceiling exceeded ($maxToolCalls)';
            completed = false;
            break;
          }
        }
        if (error != null) {
          break;
        }
      }
      // Snapshot pages the compactor rendered are counted by the decorator.
      snapshotFrames = snapshotCounter.value;
    } on Object catch (exception) {
      error = '$exception';
      completed = false;
    }
    started.stop();

    final records = ledger.records;
    final mainCalls = [
      for (final record in records)
        if (record.purpose == LlmCallPurpose.main) record,
    ];
    var tokens = const EvaluationTokenBreakdown();
    var pricedMicros = 0;
    var pricingComplete = records.isNotEmpty;
    var providerTotalMs = 0;
    ProviderCallRecord? firstMainCall;
    for (final record in mainCalls) {
      providerTotalMs += record.durationMs;
      if (firstMainCall == null ||
          record.startedAtMs < firstMainCall.startedAtMs) {
        firstMainCall = record;
      }
    }
    final requestSent = firstMainCall?.requestSentMs;
    final firstByte = firstMainCall?.transportFirstByteMs;
    final transportTtfb =
        requestSent != null && firstByte != null && firstByte >= requestSent
        ? firstByte - requestSent
        : null;
    for (final record in records) {
      tokens = tokens + _breakdown(record.usage);
      final costMicros = record.costMicros;
      if (costMicros == null) {
        pricingComplete = false;
      } else {
        pricedMicros += costMicros;
      }
    }
    if (!stopAfterCall &&
        maxCallMicros != null &&
        records.any(
          (record) =>
              record.costMicros != null && record.costMicros! > maxCallMicros!,
        )) {
      completed = false;
      error = 'provider exceeded the reserved per-call price ceiling';
    }
    final uniformBasis =
        records.isNotEmpty &&
        records.every((r) => r.costBasis == records.first.costBasis);

    final metrics = EvaluationAttemptMetrics.fromToolEvents(
      toolEvents,
      modelRoundTrips: mainCalls.length,
      providerCalls: records.length,
      failedProviderCalls: records.where((r) => !r.succeeded).length,
      providerRetries: records.where((r) => r.attempt > 1).length,
      userTurns: turns.length,
      compactions: compactions,
      compactionRecoveries: compactions > 0
          ? _reReadsAfterCompaction(toolEvents, compactions)
          : 0,
      foldedSummaries: foldSummaries,
      maskedObservations: maskedObservations,
      snapshotFrames: snapshotFrames,
      contextWindowTokens: contextWindowTokens,
      parallelWaves: parallelWaves,
    );

    return EvaluationAttempt(
      attemptId: request.attemptId,
      taskId: request.task.id,
      taskKind: request.task.kind,
      armId: request.arm.id,
      effective: request.effective,
      stratum: request.stratum,
      repetition: request.repetition,
      seed: request.seed,
      ordinal: request.ordinal,
      startedAtEpochMs: startedAtEpochMs,
      executionMode: request.executionMode,
      completed: completed,
      error: error,
      tokens: tokens,
      cost: pricingComplete && uniformBasis
          ? switch (records.first.costBasis) {
              ProviderCallCostBasis.estimated => EvaluationCostRoles(
                estimatedApiMicros: pricedMicros,
              ),
              ProviderCallCostBasis.providerReported => EvaluationCostRoles(
                billedMicros: pricedMicros,
              ),
              ProviderCallCostBasis.subscription => EvaluationCostRoles(
                subscriptionMicros: pricedMicros,
              ),
              ProviderCallCostBasis.mixed => const EvaluationCostRoles(),
            }
          : const EvaluationCostRoles(),
      latency: EvaluationLatency(
        transportTtfbMs: transportTtfb,
        firstModelEventMs: firstModelEventMs,
        firstUsefulTextMs: firstUsefulTextMs,
        providerTotalMs: mainCalls.isEmpty ? null : providerTotalMs,
        totalMs: started.elapsedMilliseconds,
      ),
      metrics: metrics,
      toolEvents: toolEvents,
      verification: const [],
      skillEvents: skillEvents,
      filesTouched: const [],
      servedModel: parsed.model ?? servedDefaultModel,
      servedEffort: request.effective.effortLevel,
      notes: [
        'builtin harness; system prompt ${systemPrompt.length} chars',
        'memory policy ${request.effective.memoryPolicy.wire}',
        'provider calls ${records.length}',
        if (toolCeilingHit) 'tool-call ceiling hit',
        if (!pricingComplete) 'at least one provider call was unpriced',
        if (!uniformBasis) 'provider cost basis mixed or unobserved',
        if (request.effective.toolOverlap == ToolOverlapMode.overlapReadOnly)
          'tool overlap: read-only tools only, barriers preserved',
      ].join('; '),
    );
  }

  /// The real compactor factory (shipped anchored compaction plus the policy and
  /// snapshot selections), wrapped so the pass it performed is recorded.
  HarnessCompactor? _compactor({
    required MemoryPolicyMode policy,
    required LlmProviderPort provider,
    required String providerId,
    required String modelId,
    required bool readerHasVision,
    required TokenCalibration calibration,
    required void Function(HarnessCompactionResult result) onResult,
    required void Function(int changedBlocks) onPruneChanged,
    required _Counter snapshotCounter,
  }) {
    final factory = compactorFactory ?? _shippedCompactors;
    final inner = factory(
      policy: policy,
      provider: provider,
      providerId: providerId,
      modelId: modelId,
      readerHasVision: readerHasVision,
      calibration: calibration,
      onResult: onResult,
    );
    if (inner == null) {
      return null;
    }
    return _RecordingCompactor(
      inner,
      onResult: onResult,
      onPruneChanged: onPruneChanged,
      snapshotCounter: snapshotCounter,
    );
  }

  EvaluationCompactorFactory get _shippedCompactors =>
      ({
        required policy,
        required provider,
        required providerId,
        required modelId,
        required readerHasVision,
        required calibration,
        required onResult,
      }) {
        final text = DefaultHarnessCompactor(
          summarizer: LlmHarnessSummarizer(provider),
          config: CompactionConfig(policy: _policy(policy)),
          calibration: calibration,
          providerId: providerId,
          modelId: modelId,
          onRewriteDecision: (decision) => onNotice?.call('rewrite: $decision'),
        );
        if (policy != MemoryPolicyMode.snapshotImages) {
          return text;
        }
        return SnapcompactCompactor(
          fallback: text,
          modelId: '$providerId/$modelId',
          readerHasVision: readerHasVision,
          // Explicit opt-in: snapshot folding is the STRATEGY for this arm, not
          // a recovery path (report 3G).
          preferSnapshots: true,
          config: const CompactionConfig(policy: CompactionPolicy.hybrid),
          providerId: providerId,
        );
      };

  FileToolOutputStore _toolOutputStore(EvaluationAttemptRequest request) =>
      FileToolOutputStore(
        workspaceDir: (workspaceId) =>
            p.join(_toolOutputRoot(request), workspaceId),
      );

  String _toolOutputRoot(EvaluationAttemptRequest request) {
    final configured = toolOutputDir;
    if (configured != null && configured.isNotEmpty) {
      return p.join(configured, request.attemptId);
    }
    return p.join(
      Directory.systemTemp.path,
      'cc-eval-tool-output',
      request.attemptId,
    );
  }

  List<HarnessTool> _buildTools(
    HarnessCommandRunner runner, {
    ToolOutputStore? store,
    List<HarnessTool>? controlledFiles,
  }) => [
    ...?controlledFiles,
    if (controlledFiles == null) ...[
      ReadTool(),
      WriteTool(),
      EditTool(),
      SearchTool(),
      FindTool(),
    ],
    if (controlledFiles == null)
      BashTool(runner)
    else
      ControlledEvaluationBashTool(runner as ControlledEvaluationProcess),
    ToolOutputReadTool(store),
    if (includeWebFetch) WebFetchTool(),
  ];

  static CompactionPolicy _policy(MemoryPolicyMode mode) => switch (mode) {
    MemoryPolicyMode.textCurrent => CompactionPolicy.current,
    MemoryPolicyMode.masking => CompactionPolicy.masking,
    MemoryPolicyMode.hybridMaskingSummary => CompactionPolicy.hybrid,
    MemoryPolicyMode.snapshotImages => CompactionPolicy.hybrid,
  };

  static String _qualified(EvaluationEffectiveConfig effective) =>
      '${effective.providerId}/${effective.modelId}';

  static EvaluationTokenBreakdown _breakdown(LlmUsage usage) =>
      EvaluationTokenBreakdown(
        uncachedInput: usage.inputTokens,
        cacheWrite: usage.cacheWriteTokens,
        cacheRead: usage.cacheReadTokens,
        output: usage.outputTokens,
        reasoning: usage.thoughtTokens,
        // OpenAI/Codex report reasoning as a SUBSET of completion tokens.
        reasoningSeparatelyReported: false,
      );

  static String? _targetOf(String toolName, Map<String, dynamic> args) {
    final kind = EvaluationToolKind.of(toolName);
    switch (kind) {
      case EvaluationToolKind.read:
      case EvaluationToolKind.edit:
      case EvaluationToolKind.patch:
      case EvaluationToolKind.find:
        final path = args['path'] ?? args['file_path'];
        return path is String ? path : null;
      case EvaluationToolKind.search:
        final pattern = args['pattern'] ?? args['query'];
        return pattern is String ? pattern : null;
      case EvaluationToolKind.exec:
        final command = args['command'];
        if (command is! String) {
          return null;
        }
        return command.trim().split(RegExp(r'\s+')).first;
      case EvaluationToolKind.other:
        return null;
    }
  }

  /// Reads that happened after the first compaction: an honest, bounded proxy
  /// for "the run had to rebuild context it had lost".
  static int _reReadsAfterCompaction(
    List<EvaluationToolEvent> events,
    int compactions,
  ) {
    final readsByTarget = <String, int>{};
    for (final event in events) {
      if (event.kind == EvaluationToolKind.read && !event.isError) {
        final target = event.target ?? '';
        readsByTarget[target] = (readsByTarget[target] ?? 0) + 1;
      }
    }
    final duplicates = readsByTarget.values
        .where((count) => count > 1)
        .map((count) => count - 1)
        .fold<int>(0, (sum, value) => sum + value);
    return duplicates < compactions ? duplicates : compactions;
  }
}

/// A mutable counter shared between the backend and its compactor decorator.
class _Counter {
  int value = 0;
}

/// Wraps the real compactor so every pass it performs is recorded — the loop's
/// compaction EVENT does not carry the policy, mask count or snapshot frames,
/// and an experiment that cannot show its intervention ran is not a result.
class _RecordingCompactor implements HarnessCompactor {
  _RecordingCompactor(
    this._inner, {
    required this.onResult,
    required this.onPruneChanged,
    required this.snapshotCounter,
  });

  final HarnessCompactor _inner;
  final void Function(HarnessCompactionResult result) onResult;
  final void Function(int changedBlocks) onPruneChanged;
  final _Counter snapshotCounter;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    final imagesBefore = _imageBlocks(history);
    final result = await _inner.maybeCompact(
      history,
      contextWindow: contextWindow,
      overheadTokens: overheadTokens,
      reservedOutputTokens: reservedOutputTokens,
      selfAgentName: selfAgentName,
      force: force,
    );
    _countNewImages(history, imagesBefore);
    onResult(result);
    return result;
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) {
    final imagesBefore = _imageBlocks(history);
    final changed = _inner.pruneToolResults(history, force: force);
    _countNewImages(history, imagesBefore);
    if (changed > 0) {
      onPruneChanged(changed);
    }
    return changed;
  }

  void _countNewImages(List<HarnessMessage> history, int imagesBefore) {
    final imagesAfter = _imageBlocks(history);
    if (imagesAfter > imagesBefore) {
      snapshotCounter.value += imagesAfter - imagesBefore;
    }
  }

  static int _imageBlocks(List<HarnessMessage> history) {
    var count = 0;
    for (final message in history) {
      for (final block in message.content) {
        if (block is HarnessImageBlock) {
          count++;
        }
      }
    }
    return count;
  }
}
