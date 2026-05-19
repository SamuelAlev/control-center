import 'package:control_center/features/sandboxing/data/claude_relay/claude_relay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClaudeRelay.buildClaudeArgs', () {
    test('never includes -p / --print (subscription relay only)', () {
      final args = ClaudeRelay.buildClaudeArgs(modelId: 'claude-sonnet-4-6');
      expect(args, isNot(contains('-p')));
      expect(args, isNot(contains('--print')));
    });

    test('includes model and skip-permissions by default', () {
      final args = ClaudeRelay.buildClaudeArgs(modelId: 'claude-opus-4-7');
      expect(args, containsAllInOrder(['--model', 'claude-opus-4-7']));
      expect(args, contains('--dangerously-skip-permissions'));
    });

    test('adds permission mode when provided', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'm',
        permissionMode: 'plan',
      );
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
    });

    test('omits model flag when model is empty or null', () {
      expect(ClaudeRelay.buildClaudeArgs(), isNot(contains('--model')));
      expect(
        ClaudeRelay.buildClaudeArgs(modelId: ''),
        isNot(contains('--model')),
      );
    });

    test('can disable skip-permissions', () {
      final args = ClaudeRelay.buildClaudeArgs(skipPermissions: false);
      expect(args, isNot(contains('--dangerously-skip-permissions')));
    });
  });

  group('ClaudeRelay.extractToolResultsFromBody', () {
    test('extracts a string tool_result once and dedups by id', () {
      final seen = <String>{};
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_1',
                'content': 'file listing output',
              },
            ],
          },
        ],
      };

      final first = ClaudeRelay.extractToolResultsFromBody(body, seen);
      expect(first, hasLength(1));
      expect(first.single.toolUseId, 'toolu_1');
      expect(first.single.content, 'file listing output');
      expect(first.single.isError, isFalse);

      // Same body again (Claude resends full history) — already seen.
      final second = ClaudeRelay.extractToolResultsFromBody(body, seen);
      expect(second, isEmpty);
    });

    test('flattens list-form content and reads is_error', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_2',
                'is_error': true,
                'content': [
                  {'type': 'text', 'text': 'boom'},
                  {'type': 'text', 'text': '!'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(body, <String>{});
      expect(results, hasLength(1));
      expect(results.single.content, 'boom!');
      expect(results.single.isError, isTrue);
    });

    test('ignores assistant messages and non-tool_result blocks', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'assistant',
            'content': [
              {'type': 'tool_use', 'id': 'x', 'name': 'Bash', 'input': {}},
            ],
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'hello'},
            ],
          },
        ],
      };
      expect(
        ClaudeRelay.extractToolResultsFromBody(body, <String>{}),
        isEmpty,
      );
    });
  });
}
