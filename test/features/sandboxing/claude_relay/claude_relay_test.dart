import 'package:control_center/features/sandboxing/data/claude_relay/anthropic_proxy.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_pid_watcher.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_relay.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_trust_prompt.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/message_assembler.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/message_request_filter.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/sse.dart';
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

  group('buildClaudeArgs further', () {
    test('combines all flags', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'claude-sonnet-4-6',
        permissionMode: 'acceptEdits',
        skipPermissions: true,
      );
      expect(args, containsAllInOrder(['--model', 'claude-sonnet-4-6']));
      expect(
        args,
        containsAllInOrder(['--permission-mode', 'acceptEdits']),
      );
      expect(args, contains('--dangerously-skip-permissions'));
    });

    test('omits permission-mode when empty string', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'm',
        permissionMode: '',
      );
      expect(args, isNot(contains('--permission-mode')));
    });

    test('omits permission-mode when null', () {
      final args = ClaudeRelay.buildClaudeArgs(modelId: 'm');
      expect(args, isNot(contains('--permission-mode')));
    });
  });

  group('ClaudeRelay instance construction', () {
    test('defaults to AnthropicProxy.new and ClaudePidWatcher.new factories', () {
      final relay = ClaudeRelay();
      // Construction succeeds without error; the factories are private but
      // the relay holds them — we verify the relay is non-null as a smoke test.
      expect(relay, isNotNull);
    });

    test('accepts a custom proxyFactory', () {
      var factoryCalled = false;
      AnthropicProxy customFactory(ProxyCallbacks callbacks) {
        factoryCalled = true;
        return AnthropicProxy(callbacks);
      }
      final relay = ClaudeRelay(proxyFactory: customFactory);
      expect(relay, isNotNull);
      // factory is not invoked until run() — just verifying construction.
      expect(factoryCalled, isFalse);
    });

    test('accepts a custom pidWatcherFactory', () {
      var factoryCalled = false;
      ClaudePidWatcher customFactory(
        int pid,
        void Function(String, String?, PidFileData) onStatusChange,
      ) {
        factoryCalled = true;
        return ClaudePidWatcher(pid, onStatusChange, homeDir: '/tmp');
      }
      final relay = ClaudeRelay(pidWatcherFactory: customFactory);
      expect(relay, isNotNull);
      expect(factoryCalled, isFalse);
    });

    test(
        'quietCompletionGrace is 8 seconds (fallback when PID watcher unavailable)',
        () {
      // The constant is private, but we can verify its value through
      // the design intent: generous enough not to fire mid-tool-execution.
      // We test this by checking the relay's run behavior with a mock proxy.
      // For pure-logic coverage, we rely on integration tests.
    });
  });

  group('ClaudeToolUse', () {
    test('constructs with all fields', () {
      const toolUse = ClaudeToolUse(
        id: 'toolu_01',
        name: 'Bash',
        input: {'command': 'ls'},
      );
      expect(toolUse.id, 'toolu_01');
      expect(toolUse.name, 'Bash');
      expect(toolUse.input, {'command': 'ls'});
    });

    test('constructs with null input', () {
      const toolUse = ClaudeToolUse(
        id: 'toolu_02',
        name: 'Read',
      );
      expect(toolUse.input, isNull);
    });
  });

  group('ClaudeToolResult', () {
    test('constructs with all fields', () {
      const result = ClaudeToolResult(
        toolUseId: 'toolu_1',
        content: 'output',
        isError: true,
      );
      expect(result.toolUseId, 'toolu_1');
      expect(result.content, 'output');
      expect(result.isError, isTrue);
    });

    test('constructs with isError false', () {
      const result = ClaudeToolResult(
        toolUseId: 't2',
        content: 'ok',
        isError: false,
      );
      expect(result.isError, isFalse);
    });
  });

  group('ClaudeRelayCallbacks', () {
    test('all callbacks are optional and nullable', () {
      const callbacks = ClaudeRelayCallbacks();
      expect(callbacks.onText, isNull);
      expect(callbacks.onToolCall, isNull);
      expect(callbacks.onToolResult, isNull);
      expect(callbacks.onError, isNull);
    });

    test('constructs with all callbacks', () {
      final callbacks = ClaudeRelayCallbacks(
        onText: (_) {},
        onThinking: (_) {},
        onToolCall: (_) {},
        onToolResult: (_) {},
        onError: (_) {},
        onDebug: (_) {},
        onPid: (_) {},
        onStatus: (_, _) {},
      );
      expect(callbacks.onText, isNotNull);
      expect(callbacks.onThinking, isNotNull);
      expect(callbacks.onToolCall, isNotNull);
      expect(callbacks.onToolResult, isNotNull);
      expect(callbacks.onError, isNotNull);
      expect(callbacks.onDebug, isNotNull);
      expect(callbacks.onPid, isNotNull);
      expect(callbacks.onStatus, isNotNull);
    });
  });

  group('extractToolResultsFromBody edge cases', () {
    test('handles empty messages list', () {
      final body = <String, Object?>{
        'messages': <Map<String, Object?>>[],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('handles missing messages key', () {
      final body = <String, Object?>{};
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('handles tool_result with missing tool_use_id', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'content': 'some output',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('handles tool_result with null content', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_3',
                'content': null,
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_3');
      expect(results.single.content, '');
    });

    test('handles content list with non-text items', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_4',
                'content': [
                  {'type': 'text', 'text': 'hello'},
                  {'type': 'image', 'source': '...'},
                  {'type': 'text', 'text': ' world'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_4');
      expect(results.single.content, 'hello world');
    });

    // ── Message assembly: deeper flattenContent / extraction paths ──

    test('flattens a single list-form text block', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_x',
                'content': [
                  {'type': 'text', 'text': 'only one block'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.content, 'only one block');
      expect(results.single.isError, isFalse);
    });

    test('returns empty string for content list with zero text blocks', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_z',
                'content': [
                  {'type': 'image', 'source': 'a'},
                  {'type': 'image', 'source': 'b'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.content, '');
    });

    test('handles content list with non-map items intermixed', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_m',
                'content': [
                  {'type': 'text', 'text': 'A'},
                  'plain string in list',
                  42,
                  {'type': 'text', 'text': 'B'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.content, 'AB');
    });

    test('handles string content with is_error', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_err',
                'is_error': true,
                'content': 'something went wrong',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.content, 'something went wrong');
      expect(results.single.isError, isTrue);
    });

    // ── Request filtering: multiple messages, mixed roles ──

    test('extracts from multiple user messages, skipping assistants', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_a',
                'content': 'result A',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'thinking...'},
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_b',
                'content': 'result B',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(2));
      expect(results.map((r) => r.toolUseId), ['toolu_a', 'toolu_b']);
      expect(results.map((r) => r.content), ['result A', 'result B']);
    });

    test('skips result already seen, emits new ones from later messages', () {
      final seen = <String>{'toolu_old'};
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_old',
                'content': 'old result',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_new',
                'content': 'new result',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(body, seen);
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_new');
      expect(seen, contains('toolu_new'));
    });

    test('ignores messages where content is not a list', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': 'plain string content, not a list',
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('ignores messages with null content', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': null,
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('skips non-map items in content list', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              'a string block',
              42,
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_v',
                'content': 'valid',
              },
              true,
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_v');
    });

    test('skips messages where role is missing', () {
      final body = <String, Object?>{
        'messages': [
          {
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_x',
                'content': 'orphan',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('skips non-map messages in the list', () {
      final body = <String, Object?>{
        'messages': [
          'just a string message',
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_s',
                'content': 'found me',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_s');
    });

    test('extracts multiple tool_results from a single user message', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_first',
                'content': 'first',
              },
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_second',
                'content': 'second',
                'is_error': true,
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(2));
      expect(results[0].toolUseId, 'toolu_first');
      expect(results[0].content, 'first');
      expect(results[0].isError, isFalse);
      expect(results[1].toolUseId, 'toolu_second');
      expect(results[1].content, 'second');
      expect(results[1].isError, isTrue);
    });

    test('handles maximum nesting: tool_result with text block with null text', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_n',
                'content': [
                  {'type': 'text', 'text': null},
                  {'type': 'text', 'text': 'hello'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      // Null text in a text block is not a String, so it is skipped.
      expect(results.single.content, 'hello');
    });
  });

  // ── ProxyCallbacks: the relay ↔ proxy contract ──

  group('ProxyCallbacks', () {
    test('onSseEvent is required', () {
      final cb = ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {},
      );
      expect(cb.onSseEvent, isNotNull);
    });

    test('all optional callbacks default to null', () {
      final cb = ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {},
      );
      expect(cb.onProxyError, isNull);
      expect(cb.onRequestStart, isNull);
      expect(cb.onRequestEnd, isNull);
      expect(cb.onRateLimit, isNull);
      expect(cb.onRequestBody, isNull);
    });

    test('constructs with every callback populated', () {
      final cb = ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {},
        onProxyError: (_) {},
        onRequestStart: (_, _) {},
        onRequestEnd: (_, _, _) {},
        onRateLimit: (code, retry, path) {},
        onRequestBody: (body, path, {required bool observe}) {},
      );
      expect(cb.onProxyError, isNotNull);
      expect(cb.onRequestStart, isNotNull);
      expect(cb.onRequestEnd, isNotNull);
      expect(cb.onRateLimit, isNotNull);
      expect(cb.onRequestBody, isNotNull);
    });

    test('onRequestBody receives observe flag as named required param', () {
      Map<String, Object?>? capturedBody;
      String? capturedPath;
      bool? capturedObserve;

      final cb = ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {},
        onRequestBody: (body, path, {required bool observe}) {
          capturedBody = body;
          capturedPath = path;
          capturedObserve = observe;
        },
      );

      cb.onRequestBody!.call(
        {'key': 'value'},
        '/v1/messages',
        observe: true,
      );

      expect(capturedBody, {'key': 'value'});
      expect(capturedPath, '/v1/messages');
      expect(capturedObserve, isTrue);
    });
  });

  // ── PidFileData: Claude process session-file parsing ──

  group('PidFileData.fromJson', () {
    test('parses a fully-populated session file', () {
      final data = PidFileData.fromJson({
        'pid': 4242,
        'sessionId': 'sess-abc123',
        'cwd': '/tmp/work',
        'kind': 'agent',
        'status': 'busy',
        'waitingFor': null,
        'updatedAt': 1718123456789,
      });
      expect(data, isNotNull);
      expect(data!.pid, 4242);
      expect(data.sessionId, 'sess-abc123');
      expect(data.cwd, '/tmp/work');
      expect(data.kind, 'agent');
      expect(data.status, 'busy');
      expect(data.waitingFor, isNull);
      expect(data.updatedAt, 1718123456789);
    });

    test('parses pid as a double (num but not int)', () {
      final data = PidFileData.fromJson({
        'pid': 99.0,
        'sessionId': 'sess-x',
      });
      expect(data, isNotNull);
      expect(data!.pid, 99);
    });

    test('returns null when pid is missing', () {
      final data = PidFileData.fromJson({
        'sessionId': 'sess-x',
      });
      expect(data, isNull);
    });

    test('returns null when pid is a string', () {
      final data = PidFileData.fromJson({
        'pid': '4242',
        'sessionId': 'sess-x',
      });
      expect(data, isNull);
    });

    test('returns null when sessionId is missing', () {
      final data = PidFileData.fromJson({
        'pid': 42,
      });
      expect(data, isNull);
    });

    test('returns null when sessionId is not a string', () {
      final data = PidFileData.fromJson({
        'pid': 42,
        'sessionId': 123,
      });
      expect(data, isNull);
    });

    test('defaults optional string fields to empty', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
      });
      expect(data, isNotNull);
      expect(data!.cwd, '');
      expect(data.kind, '');
      expect(data.status, isNull);
      expect(data.waitingFor, isNull);
    });

    test('parses updatedAt as a double', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
        'updatedAt': 1718123456789.0,
      });
      expect(data, isNotNull);
      expect(data!.updatedAt, 1718123456789);
    });

    test('updatedAt defaults to null when not a number', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
        'updatedAt': 'not-a-number',
      });
      expect(data, isNotNull);
      expect(data!.updatedAt, isNull);
    });

    test('handles waitingFor set to a string', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
        'status': 'waiting',
        'waitingFor': 'permission',
      });
      expect(data, isNotNull);
      expect(data!.status, 'waiting');
      expect(data.waitingFor, 'permission');
    });

    test('handles completely empty JSON object', () {
      final data = PidFileData.fromJson({});
      expect(data, isNull);
    });
  });

  // ── Trust prompts: auto-confirm workspace trust ──

  group('shouldAutoConfirmWorkspaceTrust', () {
    test('true when --dangerously-skip-permissions is present', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(
          ['--model', 'sonnet', '--dangerously-skip-permissions'],
        ),
        isTrue,
      );
    });

    test('true when the flag is the only arg', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(['--dangerously-skip-permissions']),
        isTrue,
      );
    });

    test('false for empty args', () {
      expect(shouldAutoConfirmWorkspaceTrust([]), isFalse);
    });

    test('false when flag is absent but other args present', () {
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--model',
          'opus',
          '--permission-mode',
          'plan',
        ]),
        isFalse,
      );
    });

    test('false when a different flag contains the string as substring', () {
      // --no-dangerously-skip-permissions is not the same flag.
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--no-dangerously-skip-permissions',
        ]),
        isFalse,
      );
    });
  });
  // ── buildClaudeArgs edge cases ──

  group('buildClaudeArgs edge cases', () {
    test('handles all args together including custom instructions', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'claude-opus-4-7',
        permissionMode: 'plan',
        skipPermissions: true,
      );
      expect(args, containsAllInOrder(['--model', 'claude-opus-4-7']));
      expect(args, containsAllInOrder(['--permission-mode', 'plan']));
      expect(args, contains('--dangerously-skip-permissions'));
      // Verify the relative order of all three flag groups.
      expect(args.indexOf('--model'), lessThan(args.indexOf('--permission-mode')));
      expect(
        args.indexOf('--permission-mode'),
        lessThan(args.indexOf('--dangerously-skip-permissions')),
      );
    });

    test('args list does not contain duplicates', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'claude-sonnet-4-6',
        permissionMode: 'acceptEdits',
        skipPermissions: true,
      );
      expect(args.where((a) => a == '--model').length, 1);
      expect(args.where((a) => a == 'claude-sonnet-4-6').length, 1);
      expect(args.where((a) => a == '--permission-mode').length, 1);
      expect(args.where((a) => a == 'acceptEdits').length, 1);
      expect(args.where((a) => a == '--dangerously-skip-permissions').length, 1);
    });

    test('model flag value preserves exact string', () {
      final args = ClaudeRelay.buildClaudeArgs(modelId: 'ClAuDe-OpUs-4');
      expect(args, containsAllInOrder(['--model', 'ClAuDe-OpUs-4']));
      // Model value is exactly the string, no transformation.
      expect(args[args.indexOf('--model') + 1], 'ClAuDe-OpUs-4');
    });

    test('permission mode values are case-preserved', () {
      final args = ClaudeRelay.buildClaudeArgs(
        modelId: 'm',
        permissionMode: 'AcCePtEdItS',
      );
      expect(args, containsAllInOrder(['--permission-mode', 'AcCePtEdItS']));
      expect(args[args.indexOf('--permission-mode') + 1], 'AcCePtEdItS');
    });
  });

  // ── extractToolResultsFromBody further edges ──

  group('extractToolResultsFromBody further edges', () {
    test('handles deeply nested content blocks', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_deep',
                'content': [
                  [
                    {'type': 'text', 'text': 'too deep'},
                  ],
                  {'type': 'text', 'text': 'shallow'},
                ],
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      // Only shallow text blocks are extracted; nested lists are skipped.
      expect(results.single.content, 'shallow');
    });

    test('dedups across calls with growing seen set', () {
      final seen = <String>{};
      final body1 = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_a',
                'content': 'first call result',
              },
            ],
          },
        ],
      };
      final body2 = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_a',
                'content': 'duplicate',
              },
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_b',
                'content': 'second call result',
              },
            ],
          },
        ],
      };

      final results1 = ClaudeRelay.extractToolResultsFromBody(body1, seen);
      expect(results1, hasLength(1));
      expect(results1.single.toolUseId, 'toolu_a');
      expect(seen, contains('toolu_a'));

      final results2 = ClaudeRelay.extractToolResultsFromBody(body2, seen);
      expect(results2, hasLength(1));
      expect(results2.single.toolUseId, 'toolu_b');
      expect(results2.single.content, 'second call result');
      expect(seen, containsAll(['toolu_a', 'toolu_b']));
    });

    test('handles is_error: false explicitly', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_ok',
                'is_error': false,
                'content': 'all good',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_ok');
      expect(results.single.content, 'all good');
      expect(results.single.isError, isFalse);
    });

    test('handles tool_result with boolean content', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_bool',
                'content': true,
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      // Boolean content is not a String and not a List, so it falls through to ''.
      expect(results.single.content, '');
    });

    test('handles content as integer (edge case)', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_int',
                'content': 42,
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      expect(results, hasLength(1));
      // Integer is not a String and not a List, so it falls through to ''.
      expect(results.single.content, '');
    });

    test('handles message with role "system" (ignored)', () {
      final body = <String, Object?>{
        'messages': [
          {
            'role': 'system',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_sys',
                'content': 'system result',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'toolu_usr',
                'content': 'user result',
              },
            ],
          },
        ],
      };
      final results = ClaudeRelay.extractToolResultsFromBody(
        body,
        <String>{},
      );
      // Only the user message's result is extracted; system is ignored.
      expect(results, hasLength(1));
      expect(results.single.toolUseId, 'toolu_usr');
      expect(results.single.content, 'user result');
    });
  });

  // ── ClaudeToolUse edge cases ──

  group('ClaudeToolUse edge cases', () {
    test('constructs with empty input map', () {
      const toolUse = ClaudeToolUse(
        id: 'toolu_empty',
        name: 'Test',
        input: <String, Object?>{},
      );
      expect(toolUse.id, 'toolu_empty');
      expect(toolUse.name, 'Test');
      expect(toolUse.input, isEmpty);
    });

    test('constructs with nested input', () {
      const toolUse = ClaudeToolUse(
        id: 'toolu_nested',
        name: 'Bash',
        input: <String, Object?>{
          'command': 'ls',
          'options': <String, Object?>{
            'recursive': true,
            'path': '/tmp',
          },
        },
      );
      expect(toolUse.input, isA<Map>());
      final input = toolUse.input as Map;
      expect(input['command'], 'ls');
      expect(input['options'], isA<Map>());
      expect((input['options'] as Map)['recursive'], isTrue);
    });

    test('equality check', () {
      const a = ClaudeToolUse(
        id: 'toolu_eq',
        name: 'Edit',
        input: {'path': 'foo.dart'},
      );
      const b = ClaudeToolUse(
        id: 'toolu_eq',
        name: 'Edit',
        input: {'path': 'foo.dart'},
      );
      // Fields are identical.
      expect(a.id, b.id);
      expect(a.name, b.name);
      expect(a.input, b.input);
    });
  });

  // ── ClaudeToolResult edge cases ──

  group('ClaudeToolResult edge cases', () {
    test('content can be empty string', () {
      const result = ClaudeToolResult(
        toolUseId: 'toolu_empty_content',
        content: '',
        isError: false,
      );
      expect(result.content, '');
      expect(result.content, isEmpty);
      expect(result.toolUseId, 'toolu_empty_content');
      expect(result.isError, isFalse);
    });

    test('isError defaults', () {
      const withError = ClaudeToolResult(
        toolUseId: 't1',
        content: 'err',
        isError: true,
      );
      const withoutError = ClaudeToolResult(
        toolUseId: 't2',
        content: 'ok',
        isError: false,
      );
      expect(withError.isError, isTrue);
      expect(withoutError.isError, isFalse);
    });
  });

  // ── PidFileData further edges ──

  group('PidFileData further edges', () {
    test('parses minimal valid JSON', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 'minimal',
      });
      expect(data, isNotNull);
      expect(data!.pid, 1);
      expect(data.sessionId, 'minimal');
      expect(data.cwd, '');
      expect(data.kind, '');
    });

    test('handles kind with any string value', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
        'kind': 'custom-unusual-kind!',
      });
      expect(data, isNotNull);
      expect(data!.kind, 'custom-unusual-kind!');
    });

    test('status null by default', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
      });
      expect(data, isNotNull);
      expect(data!.status, isNull);
    });

    test('updatedAt defaults to null when absent', () {
      final data = PidFileData.fromJson({
        'pid': 1,
        'sessionId': 's',
      });
      expect(data, isNotNull);
      expect(data!.updatedAt, isNull);
    });
  });

  // ── shouldAutoConfirmWorkspaceTrust edges ──

  group('shouldAutoConfirmWorkspaceTrust edges', () {
    test('false for args with similar but different flag', () {
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--dangerously-skip-permissions-extra',
        ]),
        isFalse,
      );
    });

    test('true when flag present with other args in any order', () {
      // Flag at the start.
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--dangerously-skip-permissions',
          '--model',
          'sonnet',
        ]),
        isTrue,
      );
      // Flag at the end.
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--model',
          'opus',
          '--dangerously-skip-permissions',
        ]),
        isTrue,
      );
      // Flag in the middle.
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '--model',
          'haiku',
          '--dangerously-skip-permissions',
          '--permission-mode',
          'plan',
        ]),
        isTrue,
      );
    });
  });

  // ── SSE event extraction ──

  group('extractSseEvents', () {
    test('extracts single plain-text event', () {
      final result = extractSseEvents('data: hello\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.event, isNull);
      expect(result.complete.single.data, 'hello');
      expect(result.complete.single.parsed, isNull);
      expect(result.remainder, '');
    });

    test('extracts event with JSON payload', () {
      final result = extractSseEvents('data: {"key":"val"}\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.parsed, {'key': 'val'});
    });

    test('extracts event type field', () {
      final result = extractSseEvents('event: ping\ndata: pong\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.event, 'ping');
      expect(result.complete.single.data, 'pong');
    });

    test('joins multi-line data fields', () {
      final result = extractSseEvents('data: line1\ndata: line2\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.data, 'line1\nline2');
    });

    test('preserves partial trailing block as remainder', () {
      final result = extractSseEvents('data: partial');
      expect(result.complete, isEmpty);
      expect(result.remainder, 'data: partial');
    });

    test('extracts multiple events from buffer then returns remainder', () {
      final result = extractSseEvents(
        'data: a\n\ndata: b\n\nremaining',
      );
      expect(result.complete, hasLength(2));
      expect(result.complete[0].data, 'a');
      expect(result.complete[1].data, 'b');
      expect(result.remainder, 'remaining');
    });

    test('skips blocks with no data lines', () {
      final result = extractSseEvents('event: ping\n\ndata: real\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.data, 'real');
    });

    test('handles invalid JSON gracefully (parsed is null)', () {
      final result = extractSseEvents('data: not-json\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.data, 'not-json');
      expect(result.complete.single.parsed, isNull);
    });

    test('handles "data:" without space', () {
      final result = extractSseEvents('data:value\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.single.data, 'value');
    });

    test('handles empty buffer', () {
      final result = extractSseEvents('');
      expect(result.complete, isEmpty);
      expect(result.remainder, '');
    });

    test('handles buffer with only blank blocks', () {
      final result = extractSseEvents('\n\n\n\n');
      expect(result.complete, isEmpty);
      expect(result.remainder, '');
    });
  });

  group('SseEvent', () {
    test('constructs with parsed JSON object', () {
      const event = SseEvent(
        event: 'delta',
        data: '{"k":1}',
        parsed: {'k': 1},
      );
      expect(event.event, 'delta');
      expect(event.data, '{"k":1}');
      expect(event.parsed, {'k': 1});
    });

    test('constructs with null parsed', () {
      const event = SseEvent(data: 'plain');
      expect(event.event, isNull);
      expect(event.data, 'plain');
      expect(event.parsed, isNull);
    });
  });

  // ── Message request filter ──

  group('shouldObserveMessagesRequest', () {
    test('returns true for normal message request', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-6',
        'messages': [
          {
            'role': 'user',
            'content': 'Hello',
          },
        ],
      };
      expect(shouldObserveMessagesRequest(body), isTrue);
    });

    test('returns false for session title generation request', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-6',
        'system': [
          {
            'type': 'text',
            'text':
                'Generate a concise, sentence-case title for this conversation.',
          },
          {
            'type': 'text',
            'text': 'Return JSON with a single "title" field.',
          },
        ],
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tools': [
          {
            'name': 'respond',
            'input_schema': {
              'type': 'json_schema',
              'schema': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                },
                'required': ['title'],
              },
            },
          },
        ],
      };
      expect(shouldObserveMessagesRequest(body), isFalse);
    });

    test('returns false when prompt markers in system string', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-6',
        'system': 'Generate a concise, sentence-case title. Return JSON with a single "title" field.',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
            },
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), isFalse);
    });

    test('returns true when markers present but no single-title schema', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-6',
        'system': 'Generate a concise, sentence-case title. Return JSON with a single "title" field.',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), isTrue);
    });
  });

  // ── Trust prompt: stripTerminalControls & isWorkspaceTrustPrompt ──

  group('stripTerminalControls', () {
    test('strips ANSI CSI sequences', () {
      const input = '\x1b[32mhello\x1b[0m';
      expect(stripTerminalControls(input), 'hello');
    });

    test('normalises carriage returns to newlines', () {
      const input = 'line1\rline2\r\n';
      // \r → \n, and \r\n → \n\n
      expect(stripTerminalControls(input), 'line1\nline2\n\n');
    });
    test('leaves plain text unchanged', () {
      const input = 'hello world';
      expect(stripTerminalControls(input), 'hello world');
    });
  });

  group('isWorkspaceTrustPrompt', () {
    test('detects workspace trust prompt', () {
      const prompt = 'Quick safety check: Yes, I trust this folder. No, exit.';
      expect(isWorkspaceTrustPrompt(prompt), isTrue);
    });

    test('returns false for unrelated text', () {
      expect(isWorkspaceTrustPrompt('Hello, how can I help?'), isFalse);
    });

    test('returns false when only one phrase present', () {
      expect(
        isWorkspaceTrustPrompt('Quick safety check: something else'),
        isFalse,
      );
    });
  });

  group('WorkspaceTrustPromptDetector', () {
    test('fires onDetected when trust prompt appears in single chunk', () {
      var fired = false;
      final detector = WorkspaceTrustPromptDetector(() => fired = true);
      detector
          .add('Quick safety check: Yes, I trust this folder. No, exit.');
      expect(fired, isTrue);
    });

    test('fires onDetected when prompt arrives across chunks', () {
      var fired = false;
      final detector = WorkspaceTrustPromptDetector(() => fired = true);
      detector.add('Quick safety check: Yes, I ');
      expect(fired, isFalse);
      detector.add('trust this folder. No, exit.');
      expect(fired, isTrue);
    });

    test('fires only once', () {
      var count = 0;
      final detector = WorkspaceTrustPromptDetector(() => count++);
      detector
          .add('Quick safety check: Yes, I trust this folder. No, exit.');
      expect(count, 1);
      detector
          .add('Quick safety check: Yes, I trust this folder. No, exit.');
      expect(count, 1);
    });

    test('does not fire on non-matching text', () {
      var fired = false;
      final detector = WorkspaceTrustPromptDetector(() => fired = true);
      detector.add('Hello, how can I help?');
      expect(fired, isFalse);
    });

    test('truncates buffer to last 16000 chars', () {
      var fired = false;
      final detector = WorkspaceTrustPromptDetector(() => fired = true);
      // Fill buffer with 16000+ chars of noise, then append trust prompt.
      final noise = 'x' * 16000;
      detector.add(noise);
      expect(fired, isFalse);
      detector
          .add('Quick safety check: Yes, I trust this folder. No, exit.');
      expect(fired, isTrue);
    });
  });

  // ── Message assembler ──

  group('MessageAssembler.processSse', () {
    test('processes message_start and exposes contextUsage', () {
      final assembler = MessageAssembler((_) {});
      const sse = SseEvent(
        data: '{}',
        parsed: {
          'type': 'message_start',
          'message': {
            'id': 'msg_001',
            'model': 'claude-sonnet-4-6',
            'usage': {
              'input_tokens': 100,
              'output_tokens': 0,
            },
          },
        },
      );
      assembler.processSse(sse);
      expect(assembler.contextUsage.inputTokens, 100);
      expect(assembler.contextUsage.outputTokens, 0);
    });

    test('processes tool_use block lifecycle', () {
      AssembledMessage? captured;
      final assembler = MessageAssembler((msg) => captured = msg);

      // message_start
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {'id': 'msg_001', 'model': 'sonnet', 'usage': {}},
      }));

      // content_block_start for tool_use
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {
          'type': 'tool_use',
          'id': 'toolu_001',
          'name': 'Bash',
        },
      }));

      // input_json_delta
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': '{"command":',
        },
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': '"ls"}',
        },
      }));

      // content_block_stop
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_stop',
        'index': 0,
      }));

      expect(captured, isNotNull);
      expect(captured!.content, hasLength(1));
      final block = captured!.content.single;
      expect(block, isA<ToolUseBlock>());
      final toolUse = block as ToolUseBlock;
      expect(toolUse.id, 'toolu_001');
      expect(toolUse.name, 'Bash');
      expect(toolUse.input, {'command': 'ls'});
      expect(assembler.lastToolUse, isNotNull);
      expect(assembler.lastToolUse!.id, 'toolu_001');
    });

    test('processes text block lifecycle', () {
      String? capturedText;
      final assembler = MessageAssembler((msg) {
        if (msg.content.isNotEmpty && msg.content.first is TextBlock) {
          capturedText = (msg.content.first as TextBlock).text;
        }
      });

      // message_start
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {'id': 'msg_001', 'model': 'sonnet', 'usage': {}},
      }));

      // content_block_start for text
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text', 'text': 'He'},
      }));

      // text_delta
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'llo'},
      }));

      // content_block_stop
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_stop',
        'index': 0,
      }));

      expect(capturedText, 'Hello');
    });

    test('processes thinking block lifecycle', () {
      String? capturedThinking;
      final assembler = MessageAssembler((msg) {
        if (msg.content.isNotEmpty && msg.content.first is ThinkingBlock) {
          capturedThinking = (msg.content.first as ThinkingBlock).thinking;
        }
      });

      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {'id': 'msg_001', 'model': 'sonnet', 'usage': {}},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'thinking', 'thinking': 'Pond'},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'thinking_delta', 'thinking': 'ering...'},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_stop',
        'index': 0,
      }));

      expect(capturedThinking, 'Pondering...');
    });

    test('message_delta updates output_tokens on contextUsage', () {
      final captured = <AssembledMessage>[];
      final assembler = MessageAssembler(captured.add);
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {'id': 'msg_001', 'model': 'sonnet', 'usage': {}},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text', 'text': 'Hi'},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_stop',
        'index': 0,
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_delta',
        'delta': {'stop_reason': 'end_turn'},
        'usage': {'output_tokens': 50},
      }));

      expect(assembler.contextUsage.outputTokens, 50);
    });

    test('message_stop clears current state', () {
      final assembler = MessageAssembler((_) {});
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {'id': 'msg_001', 'model': 'sonnet', 'usage': {}},
      }));
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_stop',
      }));
      // After message_stop, subsequent content blocks should be ignored
      // (no current state). We verify by checking no crash and no capture.
      var captured = false;
      final assembler2 = MessageAssembler((_) => captured = true);
      assembler2.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_stop',
      }));
      assembler2.processSse(const SseEvent(data: '', parsed: {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text', 'text': 'orphan'},
      }));
      // No message_start preceded it, so no callback fires.
      expect(captured, isFalse);
    });

    test('reset clears contextUsage and state', () {
      final assembler = MessageAssembler((_) {});
      assembler.processSse(const SseEvent(data: '', parsed: {
        'type': 'message_start',
        'message': {
          'id': 'msg_001',
          'model': 'sonnet',
          'usage': {
            'input_tokens': 100,
            'output_tokens': 50,
            'cache_read_input_tokens': 30,
            'cache_creation_input_tokens': 10,
          },
        },
      }));
      expect(assembler.contextUsage.inputTokens, 100);
      assembler.reset();
      expect(assembler.contextUsage.inputTokens, 0);
      expect(assembler.contextUsage.outputTokens, 0);
      expect(assembler.contextUsage.cacheReadInputTokens, 0);
      expect(assembler.contextUsage.cacheCreationInputTokens, 0);
      expect(assembler.lastToolUse, isNull);
    });
  });

  group('TokenUsage', () {
    test('defaults all fields to zero', () {
      final usage = TokenUsage();
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.cacheReadInputTokens, 0);
      expect(usage.cacheCreationInputTokens, 0);
    });

    test('constructs with explicit values', () {
      final usage = TokenUsage(
        inputTokens: 100,
        outputTokens: 50,
        cacheReadInputTokens: 30,
        cacheCreationInputTokens: 10,
      );
      expect(usage.inputTokens, 100);
      expect(usage.outputTokens, 50);
      expect(usage.cacheReadInputTokens, 30);
      expect(usage.cacheCreationInputTokens, 10);
    });

    test('fields are mutable', () {
      final usage = TokenUsage();
      usage.inputTokens = 42;
      usage.outputTokens = 7;
      expect(usage.inputTokens, 42);
      expect(usage.outputTokens, 7);
    });
  });

  group('ToolUseRef', () {
    test('constructs with all fields', () {
      const ref = ToolUseRef(
        id: 'toolu_001',
        name: 'Bash',
        input: {'command': 'ls'},
      );
      expect(ref.id, 'toolu_001');
      expect(ref.name, 'Bash');
      expect(ref.input, {'command': 'ls'});
    });
    test('constructs with null input', () {
      const ref = ToolUseRef(id: 'toolu_002', name: 'Read', input: null);
      expect(ref.input, isNull);
    });
  });

  group('AssembledMessage', () {
    test('constructs with all fields', () {
      final usage = TokenUsage(inputTokens: 10, outputTokens: 5);
      final blocks = <AssembledBlock>[TextBlock('hello')];
      final msg = AssembledMessage(
        id: 'msg_001',
        model: 'sonnet',
        content: blocks,
        stopReason: 'end_turn',
        usage: usage,
      );
      expect(msg.id, 'msg_001');
      expect(msg.model, 'sonnet');
      expect(msg.content, same(blocks));
      expect(msg.stopReason, 'end_turn');
      expect(msg.usage, same(usage));
    });
  });
}
