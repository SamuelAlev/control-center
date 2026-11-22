import 'dart:async';
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
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
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

/// A run that stays open until [release] completes.
class _HeldLoop implements AgentLoop {
  final started = Completer<void>();
  final release = Completer<void>();

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
    started.complete();
    await release.future;
    yield const LoopDone(LoopDoneReason.completed);
  }
}

void main() {
  test('an event emitted to a live run reaches its stream; an unknown id is '
      'ignored', () async {
    final dir = Directory.systemTemp.createTempSync('cc_emit_to_run_');
    addTearDown(() => deleteDirBestEffort(dir));
    final loop = _HeldLoop();
    final adapter = SandboxedAgentDispatchAdapter(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: _Sandbox(),
      agentRepository: _Unused(),
      harnessCredentialStore: _KeylessStore(),
      agentLoop: loop,
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
    final events = handle.events.toList();
    await loop.started.future;

    adapter
      ..emitToRun(
        handle.dispatchId,
        ToolCallEvent(
          toolName: 'lookup_thing',
          toolCallId: 'toolu_1/1',
          parentToolCallId: 'toolu_1',
        ),
      )
      ..emitToRun(
        'no-such-run',
        ToolCallEvent(toolName: 'stray', toolCallId: 'x/1'),
      );
    loop.release.complete();

    final calls = (await events).whereType<ToolCallEvent>().toList();
    expect(calls.map((e) => e.toolName), ['lookup_thing']);
    expect(calls.single.parentToolCallId, 'toolu_1');

    // The run has ended and left the adapter: later events go nowhere.
    adapter.emitToRun(
      handle.dispatchId,
      ToolCallEvent(toolName: 'late', toolCallId: 'y/1'),
    );
  });
}
