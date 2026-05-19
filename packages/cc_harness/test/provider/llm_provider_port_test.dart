import 'dart:async';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Coverage for the streaming-event model and config value objects that sit
/// behind the [LlmProviderPort]. The port itself is an abstract interface —
/// exercised via a tiny in-memory implementation that replays a canned event
/// list, so the contract (terminates with exactly one LlmDone/LlmError) is
/// also asserted.
class _ReplayProvider implements LlmProviderPort {
  _ReplayProvider(
    this.events, {
    this.displayName = 'Replay',
    this.defaultModel = 'replay-1',
  });

  final List<LlmEvent> events;

  @override
  final String displayName;

  @override
  final String defaultModel;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig? config,
  }) async* {
    for (final e in events) {
      yield e;
    }
  }

  @override
  Future<List<ProviderModel>> listModels() async => const [
    ProviderModel(id: 'm1', displayName: 'One'),
  ];
}

void main() {
  group('LlmTextDelta / LlmThinkingDelta / LlmToolUseDelta', () {
    test('LlmTextDelta carries the text', () {
      const delta = LlmTextDelta('hi');
      expect(delta.text, 'hi');
    });

    test('LlmThinkingDelta carries thinking + optional signature', () {
      const withSig = LlmThinkingDelta('hmm', signature: 'sig');
      expect(withSig.thinking, 'hmm');
      expect(withSig.signature, 'sig');
      const withoutSig = LlmThinkingDelta('hmm');
      expect(withoutSig.signature, isNull);
    });

    test('LlmToolUseDelta carries id + name + argumentsJson', () {
      const delta = LlmToolUseDelta(
        id: 'tu1',
        name: 'search',
        argumentsJson: '{"q":"x"}',
      );
      expect(delta.id, 'tu1');
      expect(delta.name, 'search');
      expect(delta.argumentsJson, '{"q":"x"}');
    });
  });

  group('LlmUsage', () {
    test('defaults to zero tokens', () {
      const usage = LlmUsage();
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.cacheReadTokens, 0);
      expect(usage.cacheWriteTokens, 0);
      expect(usage.thoughtTokens, 0);
    });

    test('operator + sums every count', () {
      const a = LlmUsage(
        inputTokens: 1,
        outputTokens: 2,
        cacheReadTokens: 3,
        cacheWriteTokens: 4,
        thoughtTokens: 5,
      );
      const b = LlmUsage(
        inputTokens: 10,
        outputTokens: 20,
        cacheReadTokens: 30,
        cacheWriteTokens: 40,
        thoughtTokens: 50,
      );
      final sum = a + b;
      expect(sum.inputTokens, 11);
      expect(sum.outputTokens, 22);
      expect(sum.cacheReadTokens, 33);
      expect(sum.cacheWriteTokens, 44);
      expect(sum.thoughtTokens, 55);
    });

    test('+ with zero left operand returns the right operand counts', () {
      final sum =
          const LlmUsage() + const LlmUsage(inputTokens: 7, outputTokens: 8);
      expect(sum.inputTokens, 7);
      expect(sum.outputTokens, 8);
    });
  });

  group('LlmStopReason', () {
    test('fromWire maps Anthropic + OpenAI spellings', () {
      expect(LlmStopReason.fromWire('end_turn'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('stop'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('tool_use'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('tool_calls'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('max_tokens'), LlmStopReason.maxTokens);
      expect(LlmStopReason.fromWire('length'), LlmStopReason.maxTokens);
      expect(
        LlmStopReason.fromWire('stop_sequence'),
        LlmStopReason.stopSequence,
      );
    });

    test('fromWire defaults null/unrecognized to unknown', () {
      expect(LlmStopReason.fromWire(null), LlmStopReason.unknown);
      expect(LlmStopReason.fromWire('weird'), LlmStopReason.unknown);
    });
  });

  group('LlmDone / LlmError', () {
    test('LlmDone defaults to unknown stop reason + null usage', () {
      const done = LlmDone();
      expect(done.stopReason, LlmStopReason.unknown);
      expect(done.usage, isNull);
    });

    test('LlmError carries message + classification + retry hints', () {
      const err = LlmError(
        'rate limited',
        code: 'rate_limit_error',
        retryable: true,
        retryAfterMs: 1234,
      );
      expect(err.message, 'rate limited');
      expect(err.code, 'rate_limit_error');
      expect(err.retryable, isTrue);
      expect(err.retryAfterMs, 1234);
    });

    test('LlmError defaults', () {
      const err = LlmError('boom');
      expect(err.code, isNull);
      expect(err.retryable, isFalse);
      expect(err.retryAfterMs, isNull);
    });
  });

  group('LlmToolSchema', () {
    test('is a plain immutable carrier', () {
      const schema = LlmToolSchema(
        name: 'search',
        description: 'Search the web',
        inputSchema: {'type': 'object'},
      );
      expect(schema.name, 'search');
      expect(schema.description, 'Search the web');
      expect(schema.inputSchema, {'type': 'object'});
    });
  });

  group('LlmCompleteConfig', () {
    test('applies the documented defaults', () {
      const config = LlmCompleteConfig();
      expect(config.model, isNull);
      expect(config.systemPrompt, isNull);
      expect(config.maxTokens, 8192);
      expect(config.temperature, isNull);
      expect(config.stopSequences, isEmpty);
      expect(config.effort, isNull);
      expect(config.cacheEnabled, isTrue);
      expect(config.cacheKey, isNull);
    });

    test('holds every configured field', () {
      const config = LlmCompleteConfig(
        model: 'claude-x',
        systemPrompt: 'be brief',
        maxTokens: 4096,
        temperature: 0.5,
        stopSequences: ['END'],
        effort: ReasoningEffort.high,
        cacheEnabled: false,
        cacheKey: 'run-1',
      );
      expect(config.model, 'claude-x');
      expect(config.systemPrompt, 'be brief');
      expect(config.maxTokens, 4096);
      expect(config.temperature, 0.5);
      expect(config.stopSequences, ['END']);
      expect(config.effort, ReasoningEffort.high);
      expect(config.cacheEnabled, isFalse);
      expect(config.cacheKey, 'run-1');
    });

    test('copyWith overrides only model + systemPrompt (per source)', () {
      const base = LlmCompleteConfig(
        model: 'a',
        systemPrompt: 'p1',
        maxTokens: 111,
        temperature: 0.1,
        stopSequences: ['s'],
        effort: ReasoningEffort.low,
        cacheEnabled: false,
        cacheKey: 'k',
      );
      final next = base.copyWith(model: 'b', systemPrompt: 'p2');
      expect(next.model, 'b');
      expect(next.systemPrompt, 'p2');
      // Everything else is carried through unchanged.
      expect(next.maxTokens, 111);
      expect(next.temperature, 0.1);
      expect(next.stopSequences, ['s']);
      expect(next.effort, ReasoningEffort.low);
      expect(next.cacheEnabled, isFalse);
      expect(next.cacheKey, 'k');
    });
  });

  group('ProviderModel', () {
    test('is a plain immutable carrier', () {
      const model = ProviderModel(
        id: 'claude-3',
        displayName: 'Claude 3',
        inputCostPerMTokens: 3.0,
        outputCostPerMTokens: 15.0,
        contextWindow: 200000,
      );
      expect(model.id, 'claude-3');
      expect(model.displayName, 'Claude 3');
      expect(model.inputCostPerMTokens, 3.0);
      expect(model.outputCostPerMTokens, 15.0);
      expect(model.contextWindow, 200000);
    });
  });

  group('LlmProviderPort (via a replay implementation)', () {
    test('complete streams the canned events in order', () async {
      final provider = _ReplayProvider([
        const LlmTextDelta('hel'),
        const LlmTextDelta('lo'),
        const LlmDone(
          stopReason: LlmStopReason.endTurn,
          usage: LlmUsage(inputTokens: 1, outputTokens: 2),
        ),
      ]);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events, hasLength(3));
      expect((events[0] as LlmTextDelta).text, 'hel');
      expect((events[1] as LlmTextDelta).text, 'lo');
      final done = events.last as LlmDone;
      expect(done.stopReason, LlmStopReason.endTurn);
      expect(done.usage?.outputTokens, 2);
    });

    test('listModels returns the advertised list', () async {
      final provider = _ReplayProvider(const []);
      final models = await provider.listModels();
      expect(models.single.id, 'm1');
      expect(models.single.displayName, 'One');
    });

    test('port surface exposes displayName + defaultModel', () {
      final provider = _ReplayProvider(
        const [],
        displayName: 'X',
        defaultModel: 'd',
      );
      expect(provider.displayName, 'X');
      expect(provider.defaultModel, 'd');
    });
  });
}
