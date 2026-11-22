import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/nested_call_rows.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

class _Sandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async => SandboxHandle(
    sessionId: spec.sessionId,
    backend: SandboxBackend.none,
    state: SandboxState.warm,
  );

  @override
  Future<bool> isAlive(SandboxHandle handle) async => true;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused implements CredentialBrokerPort, AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KeylessStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: 'http://127.0.0.1:1',
      );

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// A run whose one model call is a script that makes [calls] calls, each
/// with arguments and a result of [size] characters.
class _ScriptLoop implements AgentLoop {
  _ScriptLoop(this.calls, this.size);

  final int calls;
  final int size;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    yield const LoopToolCallStart(
      toolName: 'repl',
      toolUseId: 'toolu_1',
      args: {'code': 'for (...) await tools.noop(big)'},
    );
    for (var i = 1; i <= calls; i++) {
      yield LoopToolCallStart(
        toolName: 'noop',
        toolUseId: 'toolu_1/$i',
        args: {'path': 'f$i', 'content': 'line of a file\n' * (size ~/ 15)},
        parentToolUseId: 'toolu_1',
      );
      yield LoopToolCallResult(
        toolName: 'noop',
        toolUseId: 'toolu_1/$i',
        result: HarnessToolResult.success('found one\n' * (size ~/ 10)),
        parentToolUseId: 'toolu_1',
      );
    }
    yield LoopToolCallResult(
      toolName: 'repl',
      toolUseId: 'toolu_1',
      result: HarnessToolResult.success('done'),
    );
    yield const LoopDone(LoopDoneReason.completed);
  }
}

void main() {
  test('a script\'s calls reach the run\'s stream and its run log as bounded '
      'rows: every row is there, their previews together stay within the '
      'per-script bound', () async {
    // Many times the per-script bound.
    const calls = 60;
    const size = 20 * 1000;
    final dir = Directory.systemTemp.createTempSync('cc_nested_rows_');
    addTearDown(() => deleteDirBestEffort(dir));
    final adapter = SandboxedAgentDispatchAdapter(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: _Sandbox(),
      agentRepository: _Unused(),
      harnessCredentialStore: _KeylessStore(),
      agentLoop: _ScriptLoop(calls, size),
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
    );
    addTearDown(adapter.shutdown);

    final handle = adapter.start(
      wakeContext: const WakeContext.userMessage(),
      freshHistory: false,
      readOnly: false,
      cliName: 'cc-harness',
      prompt: 'go',
      workingDirectory: dir.path,
      modelId: 'openai/test-model',
      workspaceId: 'ws-1',
    );
    final events = await handle.events.toList();

    final nestedCalls = [
      for (final e in events.whereType<ToolCallEvent>())
        if (e.parentToolCallId != null) e,
    ];
    final nestedResults = [
      for (final e in events.whereType<ToolResultEvent>())
        if (e.parentToolCallId != null) e,
    ];
    expect(nestedCalls, hasLength(calls), reason: 'every row is kept');
    expect(nestedResults, hasLength(calls));
    final preview =
        nestedCalls.fold<int>(
          0,
          (n, e) => n + utf8.encode(jsonEncode(e.inputs)).length,
        ) +
        nestedResults.fold<int>(0, (n, e) => n + utf8.encode(e.outputs).length);
    // Each emptied row still says `{}`.
    expect(
      preview,
      lessThanOrEqualTo(NestedCallRows.maxPreviewBytesPerScript + 2 * calls),
    );
    expect(nestedCalls.first.inputs!['path'], 'f1');

    // The run log holds the same bounded rows.
    final logs = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.ndjson'))
        .toList();
    final logBytes = logs.fold<int>(0, (n, f) => n + f.lengthSync());
    expect(
      logBytes,
      lessThan(4 * NestedCallRows.maxPreviewBytesPerScript + calls * 1024),
    );
  });

  group('one row', () {
    test('a value that is little JSON but much memory is kept as its text', () {
      final rows = NestedCallRows();
      final event =
          rows.bound(
                ToolCallEvent(
                  toolName: 'noop',
                  toolCallId: 'p/1',
                  parentToolCallId: 'p',
                  inputs: {
                    'pad': [for (var i = 0; i < 2000; i++) <String, dynamic>{}],
                    'path': 'a.txt',
                  },
                ),
              )!
              as ToolCallEvent;
      expect(event.inputs!['pad'], isA<String>());
      expect(
        utf8.encode(jsonEncode(event.inputs)).length,
        lessThanOrEqualTo(NestedCallRows.maxArgumentsBytes + 16),
      );
    });

    test('the values a script\'s rows keep are charged for their memory, '
        'not only their JSON', () {
      final rows = NestedCallRows();
      var kept = 0;
      for (var i = 0; i < 500; i++) {
        final event =
            rows.bound(
                  ToolCallEvent(
                    toolName: 'noop',
                    toolCallId: 'p/$i',
                    parentToolCallId: 'p',
                    inputs: {
                      'pad': [
                        for (var j = 0; j < 100; j++) <String, dynamic>{},
                      ],
                    },
                  ),
                )!
                as ToolCallEvent;
        final pad = event.inputs!['pad'];
        if (pad is List) {
          kept += pad.length;
        }
      }
      expect(
        kept,
        lessThanOrEqualTo(
          NestedCallRows.maxPreviewBytesPerScript ~/
              NestedCallRows.bytesPerKeptValue,
        ),
      );
    });

    test('a row is bounded as it is stored, escapes included', () {
      final rows = NestedCallRows();
      final control = '\u0001' * 20000;
      final call =
          rows.bound(
                ToolCallEvent(
                  toolName: 'noop',
                  toolCallId: 'p/1',
                  parentToolCallId: 'p',
                  inputs: {'content': control},
                ),
              )!
              as ToolCallEvent;
      final result =
          rows.bound(
                ToolResultEvent(
                  toolCallId: 'p/1',
                  outputs: control,
                  parentToolCallId: 'p',
                ),
              )!
              as ToolResultEvent;
      expect(
        utf8.encode(jsonEncode(call.inputs)).length,
        lessThanOrEqualTo(NestedCallRows.maxArgumentsBytes),
      );
      expect(
        utf8.encode(jsonEncode(result.outputs)).length,
        lessThanOrEqualTo(NestedCallRows.maxResultBytes),
      );
      expect(result.outputs, startsWith('\u0001'));
    });

    test('a long tool name is clipped, partial output and images are not '
        'kept, and the call that ran the script passes unchanged', () {
      final rows = NestedCallRows();
      final call =
          rows.bound(
                ToolCallEvent(
                  toolName: 'x' * 5000,
                  toolCallId: 'p/1',
                  parentToolCallId: 'p',
                ),
              )!
              as ToolCallEvent;
      expect(call.toolName.length, NestedCallRows.maxToolNameChars + 1);
      expect(
        rows.bound(
          ToolResultEvent(
            toolCallId: 'p/1',
            outputs: 'partial',
            isPartial: true,
            parentToolCallId: 'p',
          ),
        ),
        isNull,
      );
      final parent = ToolResultEvent(toolCallId: 'p', outputs: 'r' * 100000);
      expect(rows.bound(parent), same(parent));
    });

    test('the per-script bound starts again for the next script', () {
      final rows = NestedCallRows();
      String out(String parent, int i) =>
          (rows.bound(
                    ToolResultEvent(
                      toolCallId: '$parent/$i',
                      outputs: 'r' * 100000,
                      parentToolCallId: parent,
                    ),
                  )!
                  as ToolResultEvent)
              .outputs;
      for (var i = 0; i < 40; i++) {
        out('p', i);
      }
      expect(out('p', 41), isEmpty, reason: 'past the bound');
      rows.bound(ToolResultEvent(toolCallId: 'p', outputs: 'done'));
      expect(out('q', 1), isNotEmpty);
    });
  });

  group('a secret that straddles the cut', () {
    // Where a result's cut falls: the room, less the quotes and the marker.
    const filler = 'x ';

    /// The kept result for [secret] placed at [at] characters into filler
    /// long enough to be cut, and the same text redacted the way the run
    /// log redacts it afterwards.
    String kept(String secret, int at) {
      final text =
          '${filler * (at ~/ 2)}${at.isOdd ? ' ' : ''}$secret'
          ' ${'y ' * 12000}';
      final event =
          NestedCallRows().bound(
                ToolResultEvent(
                  toolCallId: 'p/1',
                  outputs: text,
                  parentToolCallId: 'p',
                ),
              )!
              as ToolResultEvent;
      return event.outputs;
    }

    /// Every offset from wholly before the cut to wholly after it.
    Iterable<int> across(String secret) sync* {
      const cut = NestedCallRows.maxResultBytes;
      for (var at = cut - secret.length - 64; at <= cut + 8; at++) {
        yield at;
      }
    }

    void neverShows(String secret, List<String> fragments) {
      for (final at in across(secret)) {
        final out = kept(secret, at);
        expect(out, contains('bytes, truncated]'), reason: 'cut at $at');
        for (final fragment in fragments) {
          expect(out, isNot(contains(fragment)), reason: 'secret at $at');
          expect(
            redactSecrets(out),
            isNot(contains(fragment)),
            reason: 'run log, secret at $at',
          );
        }
      }
    }

    test('a GitHub token shows no prefix at any offset', () {
      const token = 'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij';
      neverShows(token, ['ghp_', 'ABCD']);
    });

    test('a JWT shows no part at any offset', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      neverShows(jwt, ['eyJ', 'SflK']);
    });

    test('a URL credential shows no part of the password at any offset', () {
      const url = 'https://deploy:s3cretPassw0rdValue@git.example.com/o/r';
      neverShows(url, ['s3cr', 'Passw0rd']);
    });

    test('a private key whose end lies beyond the window is redacted from its '
        'BEGIN line', () {
      final body = List.filled(
        200,
        'MIIEowIBAAKCAQEAq7BFUAYz8sHk0n',
      ).join('\n');
      final pem =
          '-----BEGIN RSA PRIVATE KEY-----\n$body\n'
          '-----END RSA PRIVATE KEY-----';
      expect(pem.length, greaterThan(NestedCallRows.redactionReach));
      for (final at in [
        NestedCallRows.maxResultBytes - 200,
        NestedCallRows.maxResultBytes - 40,
        NestedCallRows.maxResultBytes - 5,
      ]) {
        final out = kept(pem, at);
        expect(out, isNot(contains('MIIE')), reason: 'key at $at');
        expect(out, isNot(contains('BEGIN RSA')), reason: 'key at $at');
      }
    });

    test('an argument value cut at the token shows no prefix either', () {
      const token = 'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij';
      for (final at in across(token)) {
        final value =
            '${filler * (at ~/ 2)}${at.isOdd ? ' ' : ''}$token'
            ' ${'y ' * 12000}';
        final call =
            NestedCallRows().bound(
                  ToolCallEvent(
                    toolName: 'bash',
                    toolCallId: 'p/1',
                    parentToolCallId: 'p',
                    inputs: {'command': value},
                  ),
                )!
                as ToolCallEvent;
        final kept = call.inputs!['command'] as String;
        expect(kept, isNot(contains('ghp_')), reason: 'token at $at');
        expect(kept, isNot(contains('ABCD')), reason: 'token at $at');
      }
    });
  });
}
