import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_history.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_provider.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_transport.dart';
import 'package:cc_harness_runtime/src/providers/cursor/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeCursorWireModel', () {
    test('strips OpenAI-family effort siblings into a reasoning parameter', () {
      final wire = normalizeCursorWireModel('gpt-5.6-sol-xhigh');
      expect(wire.modelId, 'gpt-5.6-sol');
      expect(wire.parameters, [('reasoning', 'xhigh')]);
      expect(wire.maxMode, isFalse);
    });

    test('keeps composer-2.5 and tags it not-fast', () {
      final wire = normalizeCursorWireModel('composer-2.5');
      expect(wire.modelId, 'composer-2.5');
      expect(wire.parameters, [('fast', 'false')]);
    });

    test('maps config effort onto an OpenAI-family base id', () {
      final wire = normalizeCursorWireModel(
        'gpt-5.4',
        effort: ReasoningEffort.high,
      );
      expect(wire.modelId, 'gpt-5.4');
      expect(wire.parameters, [('reasoning', 'high')]);
    });

    test('strips a trailing -max onto the max-mode flag', () {
      final wire = normalizeCursorWireModel('claude-4.6-sonnet-max');
      expect(wire.modelId, 'claude-4.6-sonnet');
      expect(wire.maxMode, isTrue);
    });
  });

  group('packCursorHistory', () {
    test('puts the system prompt in its own blob and holds back the live user', () {
      final packed = packCursorHistory(
        [
          HarnessMessage.user('hello'),
        ],
        systemPrompt: 'Be brief.',
      );
      expect(packed.liveUserText, 'hello');
      expect(packed.blobIds, hasLength(1));
      final json = jsonDecode(
        utf8.decode(packed.store[blobIdHex(packed.blobIds.first)]!),
      ) as Map<String, dynamic>;
      expect(json['role'], 'system');
      expect(json['content'], 'Be brief.');
    });

    test('a tool-result follow-up is a resume: history keeps the user turn', () {
      final packed = packCursorHistory([
        HarnessMessage.user('run it'),
        HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 'call/1',
              name: 'bash',
              input: {'command': 'ls'},
            ),
          ],
        ),
        HarnessMessage.toolResults([
          const HarnessToolResultBlock(
            toolUseId: 'call/1',
            content: 'a.txt',
          ),
        ]),
      ]);
      expect(packed.liveUserText, isNull);
      expect(packed.blobIds.length, greaterThan(2));
      final blobs = [
        for (final id in packed.blobIds)
          jsonDecode(utf8.decode(packed.store[blobIdHex(id)]!)),
      ];
      expect(
        blobs.any(
          (b) => b is Map && b['role'] == 'user',
        ),
        isTrue,
      );
      final assistant = blobs.whereType<Map>().firstWhere(
        (b) => b['role'] == 'assistant',
      );
      final call = (assistant['content'] as List).first as Map;
      expect(call['toolCallId'], 'call_1');
    });

    test('sanitizes tool-call ids outside Cursor\'s charset', () {
      expect(normalizeCursorToolCallId('abc|def'), 'abc_def');
    });
  });

  group('CursorProvider', () {
    test('streams text and ends the turn', () async {
      final transport = _ScriptedTransport([
        _interaction(1, 'Hello'),
        _interaction(14),
      ]);
      final provider = CursorProvider(
        accessToken: 'tok',
        transport: transport,
      );
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmTextDelta>().single.text, 'Hello');
      expect(events.whereType<LlmDone>().single.stopReason, LlmStopReason.endTurn);
      expect(transport.sent, isNotEmpty);
    });

    test('MCP calls become tool-use events; native execs are thrown', () async {
      final transport = _ScriptedTransport([
        _exec(id: 1, caseNumber: 10),
        _exec(id: 2, caseNumber: 7),
        _mcpCall(id: 3, name: 'bash', toolCallId: 'c1', args: {'command': 'ls'}),
      ]);
      final provider = CursorProvider(
        accessToken: 'tok',
        transport: transport,
      );
      final events = await provider
          .complete(
            messages: [HarnessMessage.user('list files')],
            tools: const [
              LlmToolSchema(
                name: 'bash',
                description: 'Run a command',
                inputSchema: {'type': 'object'},
              ),
            ],
          )
          .toList();
      final tool = events.whereType<LlmToolUseDelta>().single;
      expect(tool.name, 'bash');
      expect(tool.id, 'c1');
      expect(jsonDecode(tool.argumentsJson), {'command': 'ls'});
      expect(events.whereType<LlmDone>().single.stopReason, LlmStopReason.toolUse);

      final sent = transport.sent;
      expect(
        sent.any(_isRequestContextReply),
        isTrue,
        reason: 'requestContext must be answered',
      );
      expect(
        sent.any(_isExecThrow),
        isTrue,
        reason: 'native execs must be declined',
      );
      expect(
        sent.any(_isMcpResult),
        isFalse,
        reason: 'MCP execution stays in the harness loop',
      );
    });

    test('GetUsableModels maps catalog rows', () async {
      final modelsPayload = (ProtoWriter()
            ..message(
              1,
              (ProtoWriter()
                    ..string(1, 'composer-2')
                    ..string(4, 'Composer 2'))
                  .take(),
            ))
          .take();
      final transport = _ScriptedTransport(
        const [],
        usableModels: modelsPayload,
      );
      final provider = CursorProvider(
        accessToken: 'tok',
        transport: transport,
      );
      final models = await provider.listModels();
      expect(models.single.id, 'composer-2');
      expect(models.single.displayName, 'Composer 2');
    });
  });
}

class _ScriptedTransport implements CursorAgentTransport {
  _ScriptedTransport(this._payloads, {this.usableModels = const []});

  final List<Uint8List> _payloads;
  final List<int> usableModels;
  final List<List<int>> sent = [];

  @override
  Future<CursorRunSession> openRun({
    required String accessToken,
    Uri? baseUrl,
  }) async {
    return CursorRunSession(
      send: sent.add,
      frames: Stream.fromIterable([
        for (final payload in _payloads)
          CursorRunFrame(flags: 0, payload: payload),
      ]),
      close: () async {},
    );
  }

  @override
  Future<List<int>> getUsableModels({
    required String accessToken,
    required List<int> request,
    Uri? baseUrl,
  }) async => usableModels;
}

Uint8List _interaction(int caseNumber, [String text = '']) {
  final inner = text.isEmpty
      ? ProtoWriter().take()
      : (ProtoWriter()..string(1, text)).take();
  final update = (ProtoWriter()..message(caseNumber, inner)).take();
  return (ProtoWriter()..message(1, update)).take();
}

Uint8List _exec({required int id, required int caseNumber, List<int>? args}) {
  final exec = ProtoWriter()
    ..uint32(1, id)
    ..message(caseNumber, args ?? ProtoWriter().take());
  return (ProtoWriter()..message(2, exec.take())).take();
}

Uint8List _mcpCall({
  required int id,
  required String name,
  required String toolCallId,
  required Map<String, dynamic> args,
}) {
  final encoded = ProtoWriter();
  encoded.string(1, name);
  encoded.mapStringBytes(2, {
    for (final entry in args.entries)
      entry.key: utf8.encode(jsonEncode(entry.value)),
  });
  encoded.string(3, toolCallId);
  encoded.string(5, name);
  return _exec(id: id, caseNumber: 11, args: encoded.take());
}

bool _isRequestContextReply(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  if (!fields.containsKey(2)) {
    return false;
  }
  final exec = fields[2]!.first.asMessage.collect();
  return exec.containsKey(10);
}

bool _isExecThrow(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  return fields.containsKey(5);
}

bool _isMcpResult(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  if (!fields.containsKey(2)) {
    return false;
  }
  final exec = fields[2]!.first.asMessage.collect();
  return exec.containsKey(11);
}
