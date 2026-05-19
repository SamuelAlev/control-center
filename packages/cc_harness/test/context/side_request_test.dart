import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Records what the side request actually sent, so the cache-preserving shape
/// can be asserted rather than assumed.
class _RecordingProvider implements LlmProviderPort {
  _RecordingProvider(this.script);
  final List<LlmEvent> script;
  List<HarnessMessage>? sentMessages;
  List<LlmToolSchema>? sentTools;
  LlmCompleteConfig? sentConfig;
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
    calls++;
    sentMessages = messages;
    sentTools = tools;
    sentConfig = config;
    yield* Stream.fromIterable(script);
  }
}

void main() {
  const done = LlmDone(stopReason: LlmStopReason.endTurn);

  group('SideRequest', () {
    test('appends exactly one trailing turn to a snapshot', () async {
      final provider = _RecordingProvider([
        const LlmTextDelta('the answer'),
        done,
      ]);
      final history = [
        HarnessMessage.user('do the thing'),
        HarnessMessage.assistant('done'),
      ];

      final answer = await SideRequest(provider).ask(
        history: history,
        question: 'what did you change?',
        systemPrompt: 'you are an agent',
        cacheKey: 'run-1',
      );

      expect(answer, 'the answer');
      expect(provider.sentMessages, hasLength(history.length + 1));
      // Everything before the trailing turn must be IDENTICAL — that is what
      // makes the provider's cached prefix a hit rather than a miss.
      for (var i = 0; i < history.length; i++) {
        expect(identical(provider.sentMessages![i], history[i]), isTrue);
      }
      expect(provider.sentMessages!.last.role, HarnessRole.user);
    });

    test('does not mutate the live history', () async {
      final provider = _RecordingProvider([const LlmTextDelta('x'), done]);
      final history = [HarnessMessage.user('a')];
      await SideRequest(provider).ask(
        history: history,
        question: 'q',
      );
      expect(
        history,
        hasLength(1),
        reason: 'the conversation must never learn this happened',
      );
    });

    test('carries the run cache key and system prompt through', () async {
      final provider = _RecordingProvider([const LlmTextDelta('x'), done]);
      await SideRequest(provider).ask(
        history: const [],
        question: 'q',
        systemPrompt: 'sys',
        cacheKey: 'run-7',
        model: 'a-model',
      );
      expect(provider.sentConfig!.cacheKey, 'run-7');
      expect(provider.sentConfig!.systemPrompt, 'sys');
      expect(provider.sentConfig!.model, 'a-model');
    });

    test('sends no tools at all', () async {
      final provider = _RecordingProvider([const LlmTextDelta('x'), done]);
      await SideRequest(provider).ask(
        history: const [],
        question: 'q',
      );
      expect(
        provider.sentTools,
        isEmpty,
        reason: 'a side request that edits a file is a bug with no upside',
      );
    });

    test('a provider error degrades to null, never a throw', () async {
      final provider = _RecordingProvider([
        const LlmError('upstream exploded'),
      ]);
      expect(
        await SideRequest(provider).ask(
          history: const [],
          question: 'q',
        ),
        isNull,
      );
    });

    test('an empty answer is null, not an empty string', () async {
      final provider = _RecordingProvider([const LlmTextDelta('   '), done]);
      expect(
        await SideRequest(provider).ask(
          history: const [],
          question: 'q',
        ),
        isNull,
      );
    });
  });

  group('prompts', () {
    test('the handoff prompt names its three sections', () {
      expect(handoffPrompt, contains('## Task'));
      expect(handoffPrompt, contains('## State'));
      expect(handoffPrompt, contains('## Next'));
      expect(
        handoffPrompt,
        contains('tried'),
        reason: 'what was rejected, and why, is what stops a repeat',
      );
    });

    test('a side question tells the model not to start work', () {
      final prompt = sideQuestionPrompt('which file holds the router?');
      expect(prompt, contains('which file holds the router?'));
      expect(prompt, contains('not start any work'));
    });
  });
}
