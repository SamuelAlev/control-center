import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Recovery of tool calls that arrive on the content channel instead of the
/// `tool_calls` channel, and the text gate that keeps the raw envelope out of
/// the transcript when recovery succeeds.
void main() {
  const tools = [
    LlmToolSchema(
      name: 'search_memory',
      description: 'search',
      inputSchema: {'type': 'object'},
    ),
    LlmToolSchema(
      name: 'submit_plan',
      description: 'submit',
      inputSchema: {'type': 'object'},
    ),
  ];

  Future<List<LlmEvent>> run(
    List<SseMessage> sse, {
    List<LlmToolSchema> declared = tools,
  }) => OpenAiProvider(
    http: _ScriptedHttp(sse: sse),
  ).complete(messages: [HarnessMessage.user('hi')], tools: declared).toList();

  test(
    'recovers a text-dialect tool call and suppresses the raw envelope',
    () async {
      // The exact shape a production run emitted: the function name in a
      // `parameter` tag, closed by `</function>`, split across SSE frames.
      final events = await run([
        _delta(content: 'I will look this up.\n\n'),
        _delta(content: '<parameter name="search_memory">\n<parameter nam'),
        _delta(content: 'e="query">\nmessaging\n</parameter>\n'),
        _delta(
          content: '<parameter name="workspace_id">\nws-1\n</parameter>\n',
        ),
        _delta(content: '</function>', finishReason: 'stop'),
      ]);

      final call = events.whereType<LlmToolUseDelta>().single;
      expect(call.name, 'search_memory');
      expect(jsonDecode(call.argumentsJson), {
        'query': 'messaging',
        'workspace_id': 'ws-1',
      });

      // The prose before the envelope still streams; the envelope itself does not.
      final text = events.whereType<LlmTextDelta>().map((e) => e.text).join();
      expect(text, 'I will look this up.\n\n');
      expect(text, isNot(contains('<parameter')));
      expect(text, isNot(contains('</function>')));

      expect(
        events.whereType<LlmDone>().single.stopReason,
        LlmStopReason.toolUse,
      );
    },
  );

  test(
    'recovers several calls, including one with a JSON array argument',
    () async {
      final events = await run([
        _delta(
          content:
              '<function=search_memory><parameter=query>a</parameter></function>'
              '<function=submit_plan><parameter=goal>Do it</parameter>'
              '<parameter=nodes>[{"key":"a","title":"A"}]</parameter></function>',
          finishReason: 'stop',
        ),
      ]);

      final calls = events.whereType<LlmToolUseDelta>().toList();
      expect(calls.map((c) => c.name), ['search_memory', 'submit_plan']);
      final plan = jsonDecode(calls.last.argumentsJson) as Map<String, dynamic>;
      expect(plan['goal'], 'Do it');
      expect(plan['nodes'], isA<List<dynamic>>());
    },
  );

  test('releases held text verbatim when nothing is recovered', () async {
    // Tag-like prose that is not a call must reach the transcript unchanged —
    // the gate has to be invisible when it does not fire.
    const prose = 'Use <parameter name="foo"> in the template, then close it.';
    final events = await run([_delta(content: prose, finishReason: 'stop')]);

    expect(events.whereType<LlmToolUseDelta>(), isEmpty);
    expect(events.whereType<LlmTextDelta>().map((e) => e.text).join(), prose);
  });

  test('a structured tool call is never double-counted', () async {
    // When the server DOES parse the call, the same intent must not also be
    // salvaged from any echoed text.
    final events = await run([
      _delta(content: '<function=search_memory>'),
      _toolCallDelta(name: 'search_memory', args: '{"query":"a"}'),
      _delta(finishReason: 'tool_calls'),
    ]);

    expect(events.whereType<LlmToolUseDelta>(), hasLength(1));
    expect(events.whereType<LlmToolUseDelta>().single.name, 'search_memory');
  });

  test('an undeclared tool name is not recovered', () async {
    final events = await run([
      _delta(
        content: '<function=rm_rf><parameter=path>/</parameter></function>',
        finishReason: 'stop',
      ),
    ], declared: const []);

    expect(events.whereType<LlmToolUseDelta>(), isEmpty);
    // With no tools declared there is nothing to salvage, so the text stands.
    expect(
      events.whereType<LlmTextDelta>().map((e) => e.text).join(),
      contains('rm_rf'),
    );
  });

  test('a truncated envelope keeps its stop reason', () async {
    // The loop needs to know the turn was cut off even though a call was
    // recovered from it.
    final events = await run([
      _delta(
        content: '<function=search_memory><parameter=query>partial',
        finishReason: 'length',
      ),
    ]);

    expect(events.whereType<LlmToolUseDelta>().single.name, 'search_memory');
    expect(
      events.whereType<LlmDone>().single.stopReason,
      LlmStopReason.maxTokens,
    );
  });

  test('ordinary prose streams unchanged', () async {
    final events = await run([
      _delta(content: 'The messaging feature lives in '),
      _delta(content: '`lib/features/messaging/`.', finishReason: 'stop'),
    ]);

    expect(events.whereType<LlmToolUseDelta>(), isEmpty);
    expect(
      events.whereType<LlmTextDelta>().map((e) => e.text).join(),
      'The messaging feature lives in `lib/features/messaging/`.',
    );
  });

  test('top_p and top_k are sent only when set', () async {
    final http = _ScriptedHttp(sse: [_delta(finishReason: 'stop')]);
    final provider = OpenAiProvider(http: http);

    await provider.complete(messages: [HarnessMessage.user('hi')]).toList();
    expect(http.lastBody, isNot(contains('top_p')));
    expect(http.lastBody, isNot(contains('top_k')));

    await provider
        .complete(
          messages: [HarnessMessage.user('hi')],
          config: const LlmCompleteConfig(topP: 0.95, topK: 20),
        )
        .toList();
    expect(http.lastBody!['top_p'], 0.95);
    expect(http.lastBody!['top_k'], 20);
  });
}

SseMessage _delta({String? content, String? finishReason}) => SseMessage(
  event: null,
  data: jsonEncode({
    'choices': [
      {
        'delta': <String, dynamic>{'content': ?content},
        'finish_reason': ?finishReason,
      },
    ],
  }),
);

SseMessage _toolCallDelta({required String name, required String args}) =>
    SseMessage(
      event: null,
      data: jsonEncode({
        'choices': [
          {
            'delta': {
              'tool_calls': [
                {
                  'index': 0,
                  'id': 'call_1',
                  'function': {'name': name, 'arguments': args},
                },
              ],
            },
          },
        ],
      }),
    );

class _ScriptedHttp implements ProviderHttp {
  _ScriptedHttp({required this.sse});

  final List<SseMessage> sse;
  Map<String, dynamic>? lastBody;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    lastBody = body;
    for (final m in sse) {
      yield m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
