import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart' show ToolSurfaceSpec;
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/harness/file_transcript_store.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// The two dispatch options on the built-in harness: a fresh run sees no
/// earlier turn and leaves the conversation's transcript alone; a read-only
/// run has no tool that changes the worktree, and runs only in the sandbox.
void main() {
  late Directory root;
  late HttpServer server;
  late List<Map<String, dynamic>> requests;
  late int runNumber;

  FileHarnessTranscriptStore store() =>
      FileHarnessTranscriptStore(workspaceDir: (_) => root.path);
  final key = FileHarnessTranscriptStore.keyFor(
    workspaceId: 'ws',
    conversationId: 'conversation',
    agentId: 'agent',
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cc-run-options-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = [];
    runNumber = 0;
    server.listen((request) async {
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': 'Answer $runNumber.'},
              'finish_reason': null,
            },
          ],
        })}\n\n',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
          'usage': {'prompt_tokens': 20, 'completion_tokens': 5},
        })}\n\ndata: [DONE]\n\n',
      );
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await deleteDirBestEffort(root);
  });

  Future<List<AgentProcessEvent>> run(
    String prompt, {
    bool freshHistory = false,
    bool readOnly = false,
    bool person = true,
    Mode mode = Mode.chat,
    HostExecutionPosture posture = HostExecutionPosture.offByOwner,
    SandboxManager? sandboxManager,
  }) async {
    runNumber++;
    final session = DispatchSession(
      deps: SandboxDispatchDeps(
        hostExecution: HostExecutionGate(posture: posture),
        sandbox: _Sandbox(),
        sandboxManager: sandboxManager,
        agentRepo: _Agents(),
        runLogRepo: null,
        eventBus: null,
        resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
            AgentCommitIdentity.person((
              name: 'Test User',
              email: 'test@example.test',
            )),
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _Credentials(
          'http://127.0.0.1:${server.port}/v1',
        ),
        transcriptStore: store(),
      ),
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async => SandboxHandle(
            sessionId: sessionId,
            backend: SandboxBackend.none,
            state: SandboxState.warm,
          ),
      onScheduleCooldown: (_) {},
      dispatchId: 'dispatch-$runNumber',
      cliName: 'cc-harness',
      prompt: prompt,
      // Only a signed-in person's own message is passed as `userText`.
      userText: person ? prompt : null,
      freshHistory: freshHistory,
      readOnly: readOnly,
      agentDirHostPath: root.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent',
      workspaceId: 'ws',
      conversationId: 'conversation',
      runLogId: 'run-$runNumber',
      mode: mode,
    );
    final events = <AgentProcessEvent>[];
    final subscription = session.controller.stream.listen(events.add);
    await session.run().timeout(const Duration(seconds: 15));
    await subscription.cancel();
    return events;
  }

  String sentText() => jsonEncode(requests.last['messages']);

  Set<String> sentTools() => {
    for (final tool in (requests.last['tools'] as List? ?? const []))
      ((tool as Map)['function'] as Map)['name'] as String,
  };

  test('a fresh run has no earlier turn and leaves the conversation '
      'transcript for the next ordinary run', () async {
    await run('first-question');
    expect(sentText(), contains('first-question'));
    final saved = await store().load(key);
    expect(saved, isNotNull);

    final freshEvents = await run('fresh-question', freshHistory: true);
    expect(freshEvents.whereType<ErrorEvent>(), isEmpty);
    expect(sentText(), contains('fresh-question'));
    expect(sentText(), isNot(contains('first-question')));
    expect(sentText(), isNot(contains('Answer 1.')));
    // Not saved over the conversation's transcript.
    final afterFresh = await store().load(key);
    expect(
      jsonEncode([for (final m in afterFresh!.messages) m.toJson()]),
      jsonEncode([for (final m in saved!.messages) m.toJson()]),
    );

    await run('next-question');
    expect(sentText(), contains('first-question'));
    expect(sentText(), contains('next-question'));
    expect(sentText(), isNot(contains('fresh-question')));
  });

  test('a read-only run is offered no tool that changes the worktree, '
      'whatever mode it was started with', () async {
    await run('ordinary');
    expect(sentTools(), contains('write'));

    final events = await run(
      'just look',
      readOnly: true,
      posture: HostExecutionPosture.sandboxed,
      sandboxManager: _FakeManager(),
    );
    expect(events.whereType<ErrorEvent>(), isEmpty);
    expect(sentTools().intersection(ToolSurfaceSpec.worktreeMutators), isEmpty);
    expect(sentTools(), contains('read'));
  });

  test('a read-only run is offered nothing that changes state: no shell, '
      'subagent or write; only what the read-only profile admits', () async {
    await run('ordinary');
    const changers = {'task', 'bash', 'write', 'edit'};
    expect(sentTools(), containsAll(changers));
    await run(
      'just look',
      readOnly: true,
      posture: HostExecutionPosture.sandboxed,
      sandboxManager: _FakeManager(),
    );
    expect(sentTools().intersection(changers), isEmpty);
    expect(
      sentTools().where((t) => !ReadOnlyRunProfile.admits(t, const {})),
      isEmpty,
      reason: 'every offered tool is a read the profile admits',
    );
    expect(sentTools(), containsAll(['read', 'search', 'find']));
  });

  group('text that is not a person\'s own message is never a command', () {
    // The notices a command or a keyword leaves.
    const commandNotices = {
      '[harness] plan mode',
      '[harness] vibe mode',
      '[harness] skill: lint',
      '[harness] ultrathink',
      '[harness] ultrathink, orchestrate',
    };
    List<String> notices(List<AgentProcessEvent> events) => [
      for (final e in events.whereType<DebugEvent>())
        if (commandNotices.contains(e.content) ||
            e.content.startsWith('[harness] command:'))
          e.content,
    ];

    for (final text in [
      '/plan move the parser',
      '/vibe build it',
      '/skill:lint check it',
      'please ultrathink and orchestrate this',
    ]) {
      test('"$text" from a wake, a peer or a pipeline', () async {
        final events = await run(text, person: false);
        expect(events.whereType<ErrorEvent>(), isEmpty);
        expect(notices(events), isEmpty);
        // The text reaches the model as it was written, not as a command.
        expect(sentText(), contains(text));
        expect(sentText(), isNot(contains('Think carefully and at length')));
        expect(sentTools(), contains('write'), reason: 'still chat mode');
      });
    }

    test('the same text from a person acts', () async {
      expect(notices(await run('/plan move the parser')), [
        '[harness] plan mode',
      ]);
      expect(sentTools(), isNot(contains('write')));
      expect(notices(await run('/vibe build it')), ['[harness] vibe mode']);
      expect(notices(await run('please ultrathink about it')), [
        '[harness] ultrathink',
      ]);
      expect(sentText(), contains('Think carefully and at length'));
    });
  });

  test(
    'a read-only run without the sandbox is refused, never run bare',
    () async {
      for (final (posture, manager) in [
        (HostExecutionPosture.offByOwner, null),
        (HostExecutionPosture.unavailable, null),
        (HostExecutionPosture.sandboxed, null),
        (HostExecutionPosture.offByOwner, _FakeManager()),
      ]) {
        requests.clear();
        final events = await run(
          'just look',
          readOnly: true,
          posture: posture,
          sandboxManager: manager,
        );
        final error = events.whereType<ErrorEvent>().single;
        expect(error.content, ReadOnlyRunUnavailableException.refusal);
        expect(requests, isEmpty, reason: 'nothing reached the model');
      }
      expect(
        const ReadOnlyRunUnavailableException().code,
        'sandbox_unavailable',
      );
    },
  );
}

class _Sandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;
  @override
  Stream<SandboxEvent> events(SandboxHandle handle) => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeManager extends SandboxManager {
  _FakeManager() : super.test();

  @override
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async => SandboxWrapResult(
    executable: argv.first,
    argv: argv.sublist(1),
    environment: const {},
  );

  @override
  Future<void> disposeSession(String sessionId) async {}
}

class _Credentials implements ProviderCredentialStore {
  _Credentials(this.url);
  final String url;
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: url,
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
