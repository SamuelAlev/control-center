import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// Two edges that had no bound at all.
///
/// `tool_bridge.dart` caps bridged EXTERNAL tools at 256 KB precisely because
/// their output is not ours — but a FIRST-PARTY tool could return a 100 MB
/// string and it went to the model verbatim, through the context window on one
/// side and the phone's WebSocket on the other. And every list tool read
/// `arguments['limit']` verbatim, so a caller could ask for a million rows.
void main() {
  Future<Map<String, dynamic>> callTool(McpTool tool) async {
    final dispatcher = McpToolDispatcher(registry: McpToolRegistry([tool]));
    return dispatcher.handleRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {'name': tool.name, 'arguments': <String, dynamic>{}},
        id: 1,
      ),
    );
  }

  String textOf(Map<String, dynamic> response) {
    final result = (response['result'] as Map).cast<String, dynamic>();
    return (result['content'] as List)
        .cast<Map>()
        .map((c) => c['text'] as String? ?? '')
        .join();
  }

  group('dispatcher result cap', () {
    test(
      'an oversized text result is truncated with a visible marker',
      () async {
        final response = await callTool(
          _FixedResultTool(CallResult.success('x' * (4 * 1024 * 1024))),
        );

        final text = textOf(response);
        expect(text.length, lessThan(2 * 1024 * 1024));
        expect(
          text,
          contains('[truncated:'),
          reason:
              'the model has to be TOLD, or it treats a cut answer as the whole '
              'answer',
        );
        expect(
          text,
          contains('Narrow the request'),
          reason: 'and told what to do about it',
        );
      },
    );

    test('a normal result passes through untouched', () async {
      final response = await callTool(
        _FixedResultTool(CallResult.success('a small answer')),
      );
      expect(textOf(response), 'a small answer');
    });

    test('an oversized image is dropped whole, never half-decoded', () async {
      final response = await callTool(
        _FixedResultTool(
          CallResult(
            content: [
              const CallResultContent(type: 'text', text: 'here it is'),
              CallResultContent.image(
                data: 'A' * (4 * 1024 * 1024),
                mimeType: 'image/png',
              ),
            ],
          ),
        ),
      );

      final result = (response['result'] as Map).cast<String, dynamic>();
      final pieces = (result['content'] as List).cast<Map>();
      expect(
        pieces.where((p) => p['data'] != null),
        isEmpty,
        reason:
            'half a base64 payload is not a smaller image, it is a broken '
            'one',
      );
      expect(textOf(response), contains('here it is'));
      expect(textOf(response), contains('[truncated:'));
    });

    test('an error result stays an error after truncation', () async {
      final response = await callTool(
        _FixedResultTool(CallResult.error('e' * (4 * 1024 * 1024))),
      );
      final result = (response['result'] as Map).cast<String, dynamic>();
      expect(result['isError'], isTrue);
    });
  });

  group('McpTool.clampLimit', () {
    test('clamps an over-large request to the ceiling', () {
      expect(McpTool.clampLimit({'limit': 1000000}, 50), 500);
      expect(McpTool.clampLimit({'limit': 1000000}, 50, max: 20), 20);
    });

    test('passes a reasonable request through', () {
      expect(McpTool.clampLimit({'limit': 25}, 50), 25);
      expect(McpTool.clampLimit({'limit': 25.0}, 50), 25);
    });

    test('falls back when absent or non-numeric', () {
      expect(McpTool.clampLimit(const {}, 50), 50);
      expect(McpTool.clampLimit({'limit': 'lots'}, 50), 50);
      expect(McpTool.clampLimit({'limit': null}, 50), 50);
    });

    test('zero and negatives clamp UP to one', () {
      // "Give me nothing" is never what a caller means, and an empty result
      // reads as "there is nothing there".
      expect(McpTool.clampLimit({'limit': 0}, 50), 1);
      expect(McpTool.clampLimit({'limit': -10}, 50), 1);
    });
  });
}

class _FixedResultTool extends McpTool {
  _FixedResultTool(this._result);

  final CallResult _result;

  @override
  String get name => 'fixed_result';
  @override
  String get description => 'returns a fixed result';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async => _result;
}
