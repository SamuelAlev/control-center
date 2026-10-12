import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:test/test.dart';

Agent _agent({String id = 'agent-1', String workspaceId = 'ws-1'}) => Agent(
  id: id,
  name: 'Ada',
  title: 'Engineer',
  agentMdPath: '/tmp/ada.md',
  workspaceId: workspaceId,
  skills: AgentSkills(const []),
  createdAt: DateTime(2026),
);

class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo({this.agents = const {}, this.onWatch}) : rosters = const {};

  /// Agents by `workspaceId/agentId`.
  final Map<String, Agent?> agents;

  /// Rosters by workspace id.
  final Map<String, List<Agent>> rosters;

  /// Overrides the roster stream (used to gate or fail the lookup).
  final Stream<List<Agent>> Function(String workspaceId)? onWatch;

  final List<String> getByIdCalls = [];
  final List<String> watchCalls = [];

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    getByIdCalls.add('$workspaceId/$id');
    return agents['$workspaceId/$id'];
  }

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) {
    watchCalls.add(workspaceId);
    return onWatch?.call(workspaceId) ??
        Stream.value(rosters[workspaceId] ?? const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _StubMemory implements BuildMemoryContextUseCase {
  _StubMemory(this.onExecute);

  final Future<String> Function(
    String workspaceId,
    String agentId,
    String? task,
  )
  onExecute;

  final List<({String workspaceId, String agentId, String? task})> calls = [];

  @override
  Future<String> execute({
    required String workspaceId,
    required String agentId,
    String? taskDescription,
    String? repoSlug,
  }) {
    calls.add((
      workspaceId: workspaceId,
      agentId: agentId,
      task: taskDescription,
    ));
    return onExecute(workspaceId, agentId, taskDescription);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _StubConversation implements BuildConversationContextUseCase {
  _StubConversation({required this.onExecute});

  final Future<String> Function(
    String workspaceId,
    String spaceId,
    String selfAgentId,
    int characterBudget,
  )
  onExecute;

  final List<({String workspaceId, String spaceId, String selfAgentId})> calls =
      [];

  @override
  Future<String> execute({
    required String workspaceId,
    required String spaceId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
    String? conversationId,
  }) {
    calls.add((
      workspaceId: workspaceId,
      spaceId: spaceId,
      selfAgentId: selfAgentId,
    ));
    return onExecute(workspaceId, spaceId, selfAgentId, characterBudget);
  }

  @override
  Future<ConversationContextParts> executeStructured({
    required String workspaceId,
    required String spaceId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
    String? conversationId,
  }) async => ConversationContextParts(
    text: await execute(
      workspaceId: workspaceId,
      spaceId: spaceId,
      selfAgentId: selfAgentId,
      selfAgentName: selfAgentName,
      taskDescription: taskDescription,
      characterBudget: characterBudget,
      conversationId: conversationId,
    ),
    entries: const [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _StubModeResolver implements ModeResolver {
  _StubModeResolver(this.onResolve);

  final Future<Mode> Function(String workspaceId, String? conversationId)
  onResolve;

  final List<({String workspaceId, String? spaceId})> calls = [];

  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) {
    calls.add((workspaceId: workspaceId, spaceId: conversationId));
    return onResolve(workspaceId, conversationId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

void main() {
  group('DispatchAgentUseCase — independent reads run concurrently', () {
    test(
      'memory, conversation, mode and roster are all in flight together',
      () async {
        final entered = <String>[];
        final gate = Completer<void>();
        Future<String> gated(String name, String value) async {
          entered.add(name);
          await gate.future;
          return value;
        }

        final memory = _StubMemory(
          (w, a, t) => gated('memory', 'MEMORY-LAYER'),
        );
        final conversation = _StubConversation(
          onExecute: (w, s, a, b) =>
              gated('conversation', 'CONVERSATION-LAYER'),
        );
        final modeResolver = _StubModeResolver((w, s) async {
          entered.add('mode');
          await gate.future;
          return Mode.chat;
        });
        final repo = _FakeAgentRepo(
          agents: {'ws-1/agent-1': _agent()},
          onWatch: (workspaceId) async* {
            entered.add('teammates');
            await gate.future;
            yield <Agent>[];
          },
        );

        final useCase = DispatchAgentUseCase(
          agentRepo: repo,
          memoryContextUseCase: memory,
          conversationContextUseCase: conversation,
          modeResolver: modeResolver,
        );

        final future = useCase.execute(
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          prompt: 'Fix the bug',
          spaceId: 'space-1',
        );

        // Every independent read is entered BEFORE any of them is released. A
        // sequential implementation would leave the later ones unentered (the
        // first read holds the gate), so this assertion is the concurrency proof.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          entered,
          containsAll(['memory', 'conversation', 'mode', 'teammates']),
          reason: 'authorized, independent reads must overlap',
        );

        gate.complete();
        final prepared = await future;

        expect(prepared.agent?.id, 'agent-1');
        expect(prepared.promptParts.fullPrompt, prepared.effectivePrompt);
        expect(prepared.effectivePrompt, contains('MEMORY-LAYER'));
        expect(prepared.effectivePrompt, contains('CONVERSATION-LAYER'));
      },
    );

    test(
      'one failing read never loses the others or aborts the dispatch',
      () async {
        final memory = _StubMemory(
          (w, a, t) => Future<String>.error(StateError('memory store down')),
        );
        final conversation = _StubConversation(
          onExecute: (w, s, a, b) async => 'CONVERSATION-LAYER',
        );
        final repo = _FakeAgentRepo(
          agents: {'ws-1/agent-1': _agent()},
          onWatch: (workspaceId) =>
              Stream<List<Agent>>.error(StateError('roster lookup down')),
        );

        final prepared =
            await DispatchAgentUseCase(
              agentRepo: repo,
              memoryContextUseCase: memory,
              conversationContextUseCase: conversation,
            ).execute(
              workspaceId: 'ws-1',
              agentId: 'agent-1',
              prompt: 'Fix the bug',
              spaceId: 'space-1',
            );

        // The failed layer is absent; everything else is intact.
        expect(prepared.effectivePrompt, contains('CONVERSATION-LAYER'));
        expect(prepared.effectivePrompt, contains('## Identity'));
        expect(prepared.effectivePrompt, isNot(contains('MEMORY-LAYER')));
        expect(prepared.promptParts.standing, contains('## Identity'));
      },
    );
  });

  group('DispatchAgentUseCase — workspace scoping', () {
    test(
      'memory uses the agent workspace, history the dispatch workspace',
      () async {
        final memory = _StubMemory((w, a, t) async => 'MEMORY-LAYER');
        final conversation = _StubConversation(
          onExecute: (w, s, a, b) async => 'CONVERSATION-LAYER',
        );
        final repo = _FakeAgentRepo(
          agents: {'ws-dispatch/agent-1': _agent(workspaceId: 'ws-agent')},
          onWatch: (workspaceId) => Stream.value(const []),
        );

        await DispatchAgentUseCase(
          agentRepo: repo,
          memoryContextUseCase: memory,
          conversationContextUseCase: conversation,
        ).execute(
          workspaceId: 'ws-dispatch',
          agentId: 'agent-1',
          prompt: 'Fix the bug',
          spaceId: 'space-1',
        );

        // Memory is authoritative on the AGENT's own workspace (never null),
        // history and the roster stay on the dispatching workspace.
        expect(repo.getByIdCalls, ['ws-dispatch/agent-1']);
        expect(memory.calls.single.workspaceId, 'ws-agent');
        expect(conversation.calls.single.workspaceId, 'ws-dispatch');
        expect(conversation.calls.single.spaceId, 'space-1');
        expect(repo.watchCalls, ['ws-agent']);
      },
    );

    test('an agent from another workspace resolves to nothing', () async {
      final memory = _StubMemory((w, a, t) async => 'MEMORY-LAYER');
      final conversation = _StubConversation(
        onExecute: (w, s, a, b) async => 'CONVERSATION-LAYER',
      );
      final repo = _FakeAgentRepo(
        agents: {'ws-1/agent-1': _agent()},
        onWatch: (workspaceId) => Stream.value(const []),
      );

      final prepared =
          await DispatchAgentUseCase(
            agentRepo: repo,
            memoryContextUseCase: memory,
            conversationContextUseCase: conversation,
          ).execute(
            workspaceId: 'ws-other',
            agentId: 'agent-1',
            prompt: 'Fix the bug',
            spaceId: 'space-1',
          );

      expect(prepared.agent, isNull);
      expect(prepared.effectivePrompt, 'Fix the bug');
      expect(prepared.promptParts.hasContext, isFalse);
      // No cross-workspace read is ever issued.
      expect(memory.calls, isEmpty);
      expect(conversation.calls, isEmpty);
      expect(repo.watchCalls, isEmpty);
    });
  });

  group('DispatchAgentUseCase — structured parts', () {
    test(
      'publishes the focused native-resume delta alongside the full prompt',
      () async {
        final memory = _StubMemory(
          (w, a, t) async => '## Agent Memory\n\n- a fact',
        );
        final conversation = _StubConversation(
          onExecute: (w, s, a, b) async => '## Recent conversation\n\nhello',
        );
        final repo = _FakeAgentRepo(
          agents: {'ws-1/agent-1': _agent()},
          onWatch: (workspaceId) => Stream.value(const []),
        );

        final prepared =
            await DispatchAgentUseCase(
              agentRepo: repo,
              memoryContextUseCase: memory,
              conversationContextUseCase: conversation,
            ).execute(
              workspaceId: 'ws-1',
              agentId: 'agent-1',
              prompt: 'Fix the bug',
              spaceId: 'space-1',
            );

        expect(prepared.rawUserText, 'Fix the bug');
        expect(prepared.promptParts.fullPrompt, prepared.effectivePrompt);
        expect(prepared.promptParts.standing, contains('## Identity'));
        expect(prepared.promptParts.conversationContext, contains('hello'));
        // The delta keeps the required per-turn instructions and drops both the
        // standing brief and the whole-conversation replay.
        expect(prepared.promptParts.resumePrompt, contains('a fact'));
        expect(prepared.promptParts.resumePrompt, endsWith('Fix the bug'));
        expect(
          prepared.promptParts.resumePrompt,
          isNot(contains('## Identity')),
        );
        expect(
          prepared.promptParts.resumePrompt,
          isNot(contains('Recent conversation')),
        );
      },
    );

    test('resolves the deterministic mode for the space', () async {
      final modeResolver = _StubModeResolver((w, s) async => Mode.plan);
      final repo = _FakeAgentRepo(
        agents: {'ws-1/agent-1': _agent()},
        onWatch: (workspaceId) => Stream.value(const []),
      );

      final prepared =
          await DispatchAgentUseCase(
            agentRepo: repo,
            modeResolver: modeResolver,
          ).execute(
            workspaceId: 'ws-1',
            agentId: 'agent-1',
            prompt: 'Ship the plan',
            spaceId: 'space-1',
          );

      expect(prepared.mode, Mode.plan);
      expect(modeResolver.calls.single.workspaceId, 'ws-1');
      expect(modeResolver.calls.single.spaceId, 'space-1');
      // Plan mode's contract rides the standing brief; the goal is the prompt.
      expect(prepared.promptParts.standing, contains('## Mode'));
    });
  });
}
