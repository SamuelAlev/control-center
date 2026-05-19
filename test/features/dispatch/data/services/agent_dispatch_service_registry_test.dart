import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeDispatchUseCase implements DispatchAgentUseCase {
  _FakeDispatchUseCase(this.result);
  final PreparedDispatch result;

  @override
  Future<PreparedDispatch> execute({
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    String? workingDirectory,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async =>
      result;
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  _FakeAgentDispatchPort(this.events);
  final Stream<AgentProcessEvent> events;

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
    String? effortLevel,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
  }) =>
      DispatchHandle(dispatchId: 'dispatch-1', events: events);

  @override
  Future<void> stopDispatch(String dispatchId) async {}
  @override
  Future<void> stopAllForAgent(String agentId) async {}
  @override
  Future<void> stop() async {}
}

class _FakeRunLogRepository implements AgentRunLogRepository {
  final Map<String, AgentRunLog> logs = {};

  @override
  Future<AgentRunLog?> getById(String id) async => logs[id];
  @override
  Future<void> upsert(AgentRunLog log) async => logs[log.id] = log;
  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async => null;
  @override
  Future<List<AgentRunLog>> forPipelineRun(String w, String r) async => const [];
  @override
  Future<List<AgentRunLog>> forPipelineStep(String w, String r, String s) async =>
      const [];
  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value([]);
  @override
  Stream<List<AgentRunLog>> watchByAgent(String w, String a) =>
      Stream.value([]);
  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(String w, String c) =>
      Stream.value([]);
}

Agent _agent({String id = 'a1', String name = 'Reviewer Bot'}) => Agent(
      id: id,
      name: name,
      title: 'Tester',
      agentMdPath: '/tmp/$id.md',
      workspaceId: 'ws-1',
      skills: AgentSkills(const []),
      createdAt: DateTime(2025),
    );

PreparedDispatch _prepared({Agent? agent}) => PreparedDispatch(
      effectivePrompt: 'do work',
      effectiveConversationId: 'conv-1',
      agent: agent,
      mode: ConversationMode.chat,
      resolvedAdapterId: null,
      cliName: 'pi',
    );

void main() {
  late StreamController<AgentProcessEvent> events;
  late AgentRegistryImpl registry;
  late _FakeRunLogRepository runLogRepo;

  AgentDispatchService service({Agent? agent}) => AgentDispatchService(
        agentDispatch: _FakeAgentDispatchPort(events.stream),
        dispatchUseCase: _FakeDispatchUseCase(_prepared(agent: agent)),
        runLogRepo: runLogRepo,
        registry: registry,
      );

  setUp(() {
    events = StreamController<AgentProcessEvent>.broadcast();
    registry = AgentRegistryImpl();
    runLogRepo = _FakeRunLogRepository();
  });

  tearDown(() => events.close());

  test('dispatch registers the agent as running with display name + dispatch',
      () async {
    await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
    );

    final ref = registry.get('a1');
    expect(ref, isNotNull);
    expect(ref!.status, AgentStatus.running);
    expect(ref.workspaceId, 'ws-1');
    expect(ref.displayName, 'Reviewer Bot');
    expect(ref.dispatchId, 'dispatch-1');
    expect(ref.conversationId, 'conv-1');
  });

  test('a workspace-less dispatch is not tracked in the registry', () async {
    await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      // no workspaceId
    );
    expect(registry.get('a1'), isNull);
  });

  test('tool-call events become the agent activity as the stream is consumed',
      () async {
    final result = await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
    );

    final seen = <AgentProcessEvent>[];
    final sub = result.stream.listen(seen.add);
    events.add(ToolCallEvent(toolName: 'run_tests', toolCallId: 't1'));
    await pumpEventQueue();

    expect(registry.get('a1')!.activity, 'run_tests');
    // The tap is transparent: the consumer still receives the event.
    expect(seen.single, isA<ToolCallEvent>());
    await sub.cancel();
  });

  test('a DoneEvent flips the agent to idle (clearing activity + dispatch)',
      () async {
    final result = await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
    );

    final sub = result.stream.listen((_) {});
    events.add(ToolCallEvent(toolName: 'edit', toolCallId: 't1'));
    events.add(DoneEvent());
    await pumpEventQueue();

    final ref = registry.get('a1')!;
    expect(ref.status, AgentStatus.idle);
    expect(ref.activity, isNull);
    expect(ref.dispatchId, isNull);
    await sub.cancel();
  });

  test('completeRun marks the agent idle in the registry', () async {
    final result = await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
    );
    expect(registry.get('a1')!.status, AgentStatus.running);

    await service(agent: _agent()).completeRun(result.runLog, 'done');
    expect(registry.get('a1')!.status, AgentStatus.idle);
  });

  test('failRun marks the agent idle in the registry', () async {
    final result = await service(agent: _agent()).dispatch(
      agentId: 'a1',
      prompt: 'do work',
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
    );

    await service(agent: _agent()).failRun(result.runLog, 'boom');
    expect(registry.get('a1')!.status, AgentStatus.idle);
  });
}
