import 'dart:convert';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Replays one scripted turn per call and captures everything the loop built:
/// the messages, the tool catalog and the per-request config.
class _CapturingProvider implements LlmProviderPort, LlmDeferredToolSupport {
  _CapturingProvider(this.script, {this.supportsDeferral = true});

  final List<List<LlmEvent>> script;
  final bool supportsDeferral;
  final List<List<HarnessMessage>> requests = [];
  final List<List<LlmToolSchema>> toolSets = [];
  final List<LlmCompleteConfig> configs = [];
  int calls = 0;

  /// When set, reported as the wire-served model (a router or a dated snapshot
  /// can serve a different id than the run asked for).
  String servedModel = '';

  @override
  String get displayName => 'Capturing';

  @override
  String get defaultModel => 'mock';

  @override
  bool supportsDeferredTools({String? model}) => supportsDeferral;

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final index = calls < script.length ? calls : script.length - 1;
    requests.add(List.of(messages));
    toolSets.add(List.of(tools));
    configs.add(config);
    calls++;
    if (servedModel.isNotEmpty) {
      config.trace?.servedModel(servedModel);
    }
    yield* Stream.fromIterable(script[index]);
  }
}

class _Tool extends HarnessTool {
  _Tool(this.name);

  @override
  final String name;

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  String get description => '$name tool';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

LlmToolUseDelta _call(String name, [Map<String, dynamic> args = const {}]) =>
    LlmToolUseDelta(
      id: 'tc_$name',
      name: name,
      argumentsJson: jsonEncode(args),
    );

/// Folds every tool-role message into one summary that KEEPS the activation
/// metadata, the way a text/snapshot fold does — the reference blocks that
/// carried the activations do not survive.
class _FoldingCompactor implements HarnessCompactor {
  bool folded = false;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (folded) {
      return const HarnessCompactionResult.unchanged(0);
    }
    // Fold the model's tool-call turn together with its results, the way a
    // text fold collapses a contiguous span — never orphaning a tool_use.
    final foldedCount = history
        .where((m) => m.role == HarnessRole.tool || m.hasToolUse)
        .length;
    if (foldedCount == 0) {
      return const HarnessCompactionResult.unchanged(0);
    }
    final union = <String>{
      for (final message in history) ...message.activatedToolNames,
    };
    final firstFolded = history.indexWhere(
      (m) => m.role == HarnessRole.tool || m.hasToolUse,
    );
    history.removeRange(firstFolded, history.length);
    history.add(
      HarnessMessage(
        role: HarnessRole.system,
        content: const [HarnessTextBlock('[folded earlier turns]')],
        activatedToolNames: union.toList(growable: false),
      ),
    );
    folded = true;
    return HarnessCompactionResult(
      changed: true,
      summarized: true,
      messagesFolded: foldedCount,
      tokensBefore: 500,
      tokensAfter: 50,
    );
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

void main() {
  const runner = AgentLoopRunner();

  group('deferred activation survives a fold', () {
    test('a metadata-only activation becomes a real definition', () async {
      // The search result that referenced `deploy` was folded away, leaving
      // only the carried metadata. The provider can no longer expand a
      // reference into a schema, so the tool must be admitted as a REAL
      // definition or the model cannot call it at all.
      final provider = _CapturingProvider([
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      await runner
          .run(
            history: [
              const HarnessMessage(
                role: HarnessRole.user,
                content: [HarnessTextBlock('summarised earlier turns')],
                activatedToolNames: ['deploy'],
              ),
            ],
            userMessage: 'go',
            tools: [_Tool('read_file')],
            deferredTools: [_Tool('write_file'), _Tool('deploy')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      final schemas = provider.toolSets.single;
      expect(schemas.map((s) => s.name), [
        'read_file',
        'write_file',
        'deploy',
      ], reason: 'the fixed catalog order is preserved');
      expect(schemas[0].deferLoading, isFalse);
      expect(schemas[1].deferLoading, isTrue);
      expect(
        schemas[2].deferLoading,
        isFalse,
        reason: 'a name whose reference was folded away must be callable',
      );
      expect(
        schemas[2].inputSchema,
        isNotEmpty,
        reason: 'it is a real schema, not a dangling reference',
      );
    });

    test('a surviving reference keeps the tool deferred', () async {
      final provider = _CapturingProvider([
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      await runner
          .run(
            history: [
              HarnessMessage.toolResults(const [
                HarnessToolResultBlock(
                  toolUseId: 't1',
                  content: 'matched write_file',
                  toolReferences: ['write_file'],
                ),
              ]),
            ],
            userMessage: 'go',
            tools: [_Tool('read_file')],
            deferredTools: [_Tool('write_file')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      final schemas = provider.toolSets.single;
      expect(
        schemas[1].deferLoading,
        isTrue,
        reason:
            'the reference is still on the wire, so nothing needs to '
            'change about how the tool loads',
      );
    });

    test('a mid-run fold re-admits the tool as a real definition', () async {
      // The fold happens AFTER the run started, so a decision frozen at run
      // start would keep sending a deferred definition whose reference block
      // no longer exists.
      final provider = _CapturingProvider([
        [_call('deploy'), const LlmDone(stopReason: LlmStopReason.toolUse)],
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      final compactor = _FoldingCompactor();
      await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [_Tool('read_file')],
            deferredTools: [_Tool('write_file'), _Tool('deploy')],
            provider: provider,
            config: AgentLoopConfig(
              model: 'm',
              compactor: compactor,
              contextWindow: 200000,
            ),
          )
          .toList();

      expect(compactor.folded, isTrue);
      final beforeFold = provider.toolSets.first;
      expect(beforeFold[2].deferLoading, isTrue);
      final afterFold = provider.toolSets.last;
      expect(afterFold.map((s) => s.name), [
        'read_file',
        'write_file',
        'deploy',
      ], reason: 'the fixed catalog order survives the fold');
      expect(
        afterFold[2].deferLoading,
        isFalse,
        reason:
            'its reference block was folded away, so the definition must be '
            'resident again',
      );
      expect(afterFold[1].deferLoading, isTrue);
    });

    test('a provider without native deferral is unaffected', () async {
      final provider = _CapturingProvider([
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ], supportsDeferral: false);
      await runner
          .run(
            history: [
              const HarnessMessage(
                role: HarnessRole.user,
                content: [HarnessTextBlock('summary')],
                activatedToolNames: ['deploy'],
              ),
            ],
            userMessage: 'go',
            tools: [_Tool('read_file')],
            deferredTools: [_Tool('write_file'), _Tool('deploy')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      final schemas = provider.toolSets.single;
      expect(
        schemas.map((s) => s.name),
        ['read_file', 'deploy'],
        reason:
            'only the restored activation is appended for a portable '
            'catalog — not every deferred tool',
      );
      expect(schemas.every((s) => !s.deferLoading), isTrue);
    });
  });

  group('activation metadata is recorded on the turn', () {
    test('a direct call to a deferred tool tags the result message', () async {
      final provider = _CapturingProvider([
        [_call('deploy'), const LlmDone(stopReason: LlmStopReason.toolUse)],
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [_Tool('read_file')],
            deferredTools: [_Tool('deploy')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      expect(provider.calls, 2);
      final toolMessage = provider.requests[1].lastWhere(
        (m) => m.role == HarnessRole.tool,
      );
      expect(
        toolMessage.activatedToolNames,
        contains('deploy'),
        reason: 'a later fold needs a machine-readable source for this',
      );
      // It must be metadata only — no fabricated assistant call or result.
      expect(
        provider.requests[1]
            .expand((m) => m.content)
            .whereType<HarnessToolUseBlock>()
            .where((b) => b.name == 'deploy')
            .length,
        1,
        reason: 'exactly the model\'s own call, never a synthesized one',
      );
    });
  });

  group('rewind invalidates the cache anchor', () {
    test('the request after a rewind carries no stale anchor', () async {
      final provider = _CapturingProvider([
        [
          const LlmTextDelta('rewinding'),
          _call('rewind'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [_Tool('rewind')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      expect(provider.calls, 2);
      expect(
        provider.configs[0].cacheAnchorIndex,
        -1,
        reason: 'the first request has nothing to anchor to yet',
      );
      expect(
        provider.configs[1].cacheAnchorIndex,
        -1,
        reason:
            'the rewind truncated the history the previous anchor '
            'pointed into, so it must not be reused',
      );
    });

    test('the rewind carries dropped activations forward', () async {
      final provider = _CapturingProvider([
        [_call('deploy'), const LlmDone(stopReason: LlmStopReason.toolUse)],
        [_call('rewind'), const LlmDone(stopReason: LlmStopReason.toolUse)],
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [_Tool('rewind')],
            deferredTools: [_Tool('deploy')],
            provider: provider,
            config: const AgentLoopConfig(model: 'm'),
          )
          .toList();

      final rewound = provider.requests[2].firstWhere(
        (m) => m.textContent.contains('Rewound'),
      );
      expect(
        rewound.activatedToolNames,
        contains('deploy'),
        reason: 'the dropped span activated it and it is still callable',
      );
    });
  });

  group('calibration identity', () {
    test(
      'observes the REQUESTED model while serving a different one',
      () async {
        final ledger = ProviderCallLedger(runId: 'run-1');
        final calibration = TokenCalibration(minSamples: 1);
        final inner = _CapturingProvider([
          [
            const LlmTextDelta('hi'),
            const LlmUsage(inputTokens: 1000, outputTokens: 5),
            const LlmDone(stopReason: LlmStopReason.endTurn),
          ],
        ])..servedModel = 'claude-sonnet-4-5-20250929';
        final provider = ObservedLlmProvider(
          inner,
          observer: ledger,
          identity: ledger.identity,
          providerId: 'anthropic',
        );

        await runner
            .run(
              history: <HarnessMessage>[],
              userMessage: 'go',
              tools: const [],
              provider: provider,
              config: AgentLoopConfig(
                model: 'claude-sonnet-4-5',
                callLedger: ledger,
                tokenCalibration: calibration,
              ),
            )
            .toList();

        final record = ledger.records.single;
        expect(
          record.model,
          'claude-sonnet-4-5-20250929',
          reason: 'the serving identity is kept for pricing/observability',
        );
        expect(record.requestedModelOrServed, 'claude-sonnet-4-5');
        expect(
          calibration.factorFor(
            providerId: 'anthropic',
            modelId: 'claude-sonnet-4-5',
          ),
          greaterThan(1.0),
          reason: 'the sample is keyed by the model the run configured',
        );
        expect(
          calibration.factorFor(
            providerId: 'anthropic',
            modelId: 'claude-sonnet-4-5-20250929',
          ),
          1.0,
          reason:
              'nothing is recorded under the served id, so the compactor\'s '
              'lookup must not be left to find it there',
        );
      },
    );
  });
}
