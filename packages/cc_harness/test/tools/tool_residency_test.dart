import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Records the tool schemas and cache hints of every request it serves, so a
/// test can assert what the model actually saw turn by turn.
class _RecordingProvider implements LlmProviderPort {
  _RecordingProvider(this.script);

  final List<List<LlmEvent>> script;
  final List<List<String>> toolNamesPerCall = [];
  final List<int?> breakpointPerCall = [];
  final List<int?> anchorPerCall = [];
  int calls = 0;

  @override
  String get displayName => 'Recording';
  @override
  String get defaultModel => 'mock';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    toolNamesPerCall.add([for (final t in tools) t.name]);
    breakpointPerCall.add(config.toolCacheBreakpointIndex);
    anchorPerCall.add(config.cacheAnchorIndex);
    final index = calls < script.length ? calls : script.length - 1;
    calls++;
    yield* Stream.fromIterable(script[index]);
  }
}

class _EchoTool extends HarnessTool {
  _EchoTool(this.name, {this.activates = const {}});

  @override
  final String name;

  /// Deferred tools this tool asks the loop to load, standing in for a search.
  final Set<String> activates;

  int calls = 0;

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'echoes for $name';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls++;
    return HarnessToolResult.success('ran $name', activateTools: activates);
  }
}

List<LlmEvent> _callsTool(String name, {String id = 'c1'}) => [
  LlmToolUseDelta(id: id, name: name, argumentsJson: '{}'),
  const LlmDone(stopReason: LlmStopReason.toolUse),
];

const _stop = [
  LlmTextDelta('done'),
  LlmDone(stopReason: LlmStopReason.endTurn),
];

void main() {
  group('ToolResidencySpec', () {
    final read = _EchoTool('read');
    final rare = _EchoTool('rare_tool');

    test('partitions by name, preserving order in both halves', () {
      const spec = ToolResidencySpec(residentNames: {'read'});
      final p = spec.partition([read, rare]);
      expect([for (final t in p.resident) t.name], ['read']);
      expect([for (final t in p.deferred) t.name], ['rare_tool']);
      expect(p.hasDeferred, isTrue);
    });

    test('disabled keeps everything resident — the kill switch', () {
      const spec = ToolResidencySpec.allResident();
      final p = spec.partition([read, rare]);
      expect([for (final t in p.resident) t.name], ['read', 'rare_tool']);
      expect(p.deferred, isEmpty);
      expect(p.hasDeferred, isFalse);
    });

    test('a resident name matching no tool is inert', () {
      const spec = ToolResidencySpec(residentNames: {'read', 'not_here'});
      final p = spec.partition([read]);
      expect([for (final t in p.resident) t.name], ['read']);
      expect(p.deferred, isEmpty);
    });
  });

  group('deferred tools in the loop', () {
    test('a deferred tool called by name runs in the SAME step', () async {
      // The model saw the name in the prompt's index, so answering "unknown
      // tool, go search" would spend a round trip telling it what it knew.
      final resident = _EchoTool('read');
      final deferred = _EchoTool('rare_tool');
      final provider = _RecordingProvider([_callsTool('rare_tool'), _stop]);

      final events = await const AgentLoopRunner()
          .run(
            history: [],
            userMessage: 'go',
            tools: [resident],
            deferredTools: [deferred],
            provider: provider,
          )
          .toList();

      expect(deferred.calls, 1, reason: 'executed, not refused');
      final results = events.whereType<LoopToolCallResult>().toList();
      expect(results.single.result.isError, isFalse);
      expect(results.single.result.content, 'ran rare_tool');
    });

    test(
      'activation appends after the resident block and never reorders',
      () async {
        // The resident block is the head of the provider's cache prefix. If
        // activation inserted or reordered, every turn after the first would pay
        // to rebuild tools+system — strictly worse than never deferring.
        final provider = _RecordingProvider([
          _callsTool('rare_tool'),
          _callsTool('read', id: 'c2'),
          _stop,
        ]);
        await const AgentLoopRunner()
            .run(
              history: [],
              userMessage: 'go',
              tools: [_EchoTool('read'), _EchoTool('bash')],
              deferredTools: [_EchoTool('rare_tool'), _EchoTool('other')],
              provider: provider,
            )
            .toList();

        expect(provider.toolNamesPerCall[0], ['read', 'bash']);
        expect(provider.toolNamesPerCall[1], ['read', 'bash', 'rare_tool']);
        // Still appended, still in the same order, on every later turn.
        expect(provider.toolNamesPerCall[2], ['read', 'bash', 'rare_tool']);
        // The breakpoint stays pinned to the resident block.
        expect(provider.breakpointPerCall, everyElement(1));
      },
    );

    test(
      'a tool result can activate deferred tools (the search path)',
      () async {
        final search = _EchoTool('search_tools', activates: {'rare_tool'});
        final provider = _RecordingProvider([
          _callsTool('search_tools'),
          _callsTool('rare_tool', id: 'c2'),
          _stop,
        ]);
        final rare = _EchoTool('rare_tool');

        final events = await const AgentLoopRunner()
            .run(
              history: [],
              userMessage: 'go',
              tools: [search],
              deferredTools: [rare],
              provider: provider,
            )
            .toList();

        // Loaded by the search, so the model could call it on the very next turn
        // without a second discovery round trip.
        expect(provider.toolNamesPerCall[1], ['search_tools', 'rare_tool']);
        expect(rare.calls, 1);
        final activated = events.whereType<LoopToolsActivated>().toList();
        expect(activated.first.names, ['rare_tool']);
      },
    );

    test('a tool cannot activate something outside its own surface', () async {
      // Activation reveals a schema the run was ALWAYS allowed to call; it can
      // never widen what the mode admitted.
      final rogue = _EchoTool('search_tools', activates: {'not_on_surface'});
      final provider = _RecordingProvider([_callsTool('search_tools'), _stop]);

      final events = await const AgentLoopRunner()
          .run(
            history: [],
            userMessage: 'go',
            tools: [rogue],
            deferredTools: const [],
            provider: provider,
          )
          .toList();

      expect(events.whereType<LoopToolsActivated>(), isEmpty);
      expect(provider.toolNamesPerCall[1], ['search_tools']);
    });

    test(
      'a genuinely unknown tool points at search, not a 130-name list',
      () async {
        final provider = _RecordingProvider([_callsTool('nope'), _stop]);
        final events = await const AgentLoopRunner()
            .run(
              history: [],
              userMessage: 'go',
              tools: [_EchoTool('read')],
              deferredTools: [_EchoTool('rare_tool')],
              provider: provider,
            )
            .toList();

        final result = events.whereType<LoopToolCallResult>().single.result;
        expect(result.isError, isTrue);
        expect(result.content, contains('search_tools'));
        // Reprinting the catalogue into a tool result is the context cost
        // deferral exists to remove.
        expect(result.content, isNot(contains('rare_tool')));
      },
    );

    test(
      'with nothing deferred the unknown-tool message still enumerates',
      () async {
        final provider = _RecordingProvider([_callsTool('nope'), _stop]);
        final events = await const AgentLoopRunner()
            .run(
              history: [],
              userMessage: 'go',
              tools: [_EchoTool('read')],
              provider: provider,
            )
            .toList();
        final result = events.whereType<LoopToolCallResult>().single.result;
        expect(result.content, contains('read'));
      },
    );

    test('no deferred tools means byte-identical requests to before', () async {
      // The kill switch has to be a true no-op, or "turn it off" is not a fix.
      final provider = _RecordingProvider([_callsTool('read'), _stop]);
      await const AgentLoopRunner()
          .run(
            history: [],
            userMessage: 'go',
            tools: [_EchoTool('read'), _EchoTool('bash')],
            provider: provider,
          )
          .toList();
      expect(provider.toolNamesPerCall[0], ['read', 'bash']);
      expect(provider.toolNamesPerCall[1], ['read', 'bash']);
      expect(provider.breakpointPerCall, everyElement(1));
    });

    test('the cache anchor tracks the previous request tail', () async {
      final provider = _RecordingProvider([
        _callsTool('read'),
        _callsTool('read', id: 'c2'),
        _stop,
      ]);
      await const AgentLoopRunner()
          .run(
            history: [],
            userMessage: 'go',
            tools: [_EchoTool('read')],
            provider: provider,
          )
          .toList();

      // Turn 1 has nothing to anchor to; every later turn anchors exactly
      // where the previous request wrote.
      expect(provider.anchorPerCall.first, -1);
      expect(provider.anchorPerCall[1], 0);
      expect(provider.anchorPerCall[2], 2);
    });
  });
}
