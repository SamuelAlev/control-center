import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:test/test.dart';

Agent _testAgent({
  String id = 'agent-1',
  String name = 'TestBot',
  String? adapterId,
  int? contextSize,
  String workspaceId = 'ws-1',
}) {
  return Agent(
    id: id,
    name: name,
    title: 'Test Agent',
    agentMdPath: '/tmp/agents/$id.md',
    workspaceId: workspaceId,
    skills: AgentSkills(['coding', 'review']),
    adapterId: adapterId,
    contextSize: contextSize,
    persona: 'You are a test agent.',
    createdAt: DateTime(2025, 1, 1),
  );
}

// ---------------------------------------------------------------------------
// Hand-rolled test doubles (build_runner excludes test/** from sources so we
// cannot use @GenerateNiceMocks here).
// ---------------------------------------------------------------------------

class _FakeAgentRepository implements AgentRepository {
  final Map<String, Agent> _agents = {};
  Exception? throwOnGetById;

  void addAgent(Agent agent) => _agents[agent.id] = agent;

  @override
  Future<Agent?> getById(String id) async {
    if (throwOnGetById != null) {
      throw throwOnGetById!;
    }
    return _agents[id];
  }

  @override
  Stream<List<Agent>> watchAll() => throw UnimplementedError();

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> upsert(Agent agent) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();
}


class _FakeMemoryContextUseCase implements BuildMemoryContextUseCase {
  late Future<String> Function({required String workspaceId, required String agentId, String? taskDescription}) onExecute;
  Exception? throwOnExecute;

  @override
  Future<String> execute({
    required String workspaceId,
    required String agentId,
    String? taskDescription,
  }) async {
    if (throwOnExecute != null) {
      throw throwOnExecute!;
    }
    return onExecute(
      workspaceId: workspaceId,
      agentId: agentId,
      taskDescription: taskDescription,
    );
  }
}


class _FakeConversationContextUseCase
    implements BuildConversationContextUseCase {
  late Future<String> Function({required String channelId, required String selfAgentId, required String selfAgentName, required String taskDescription, required int characterBudget}) onExecute;
  Exception? throwOnExecute;

  @override
  Future<String> execute({
    required String channelId,
    required String selfAgentId,
    required String selfAgentName,
    required String taskDescription,
    required int characterBudget,
  }) async {
    if (throwOnExecute != null) {
      throw throwOnExecute!;
    }
    return onExecute(
      channelId: channelId,
      selfAgentId: selfAgentId,
      selfAgentName: selfAgentName,
      taskDescription: taskDescription,
      characterBudget: characterBudget,
    );
  }
}

class _FakeModeResolver implements ConversationModeResolver {
  Future<ConversationMode> Function(String? conversationId)? onResolve;

  @override
  Future<ConversationMode> resolveForConversation(
    String? conversationId,
  ) async {
    if (onResolve != null) {
      return onResolve!(conversationId);
    }
    return ConversationMode.chat;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeAgentRepository agentRepo;
  late _FakeMemoryContextUseCase memoryUseCase;
  late _FakeConversationContextUseCase conversationUseCase;
  late _FakeModeResolver modeResolver;

  setUp(() {
    agentRepo = _FakeAgentRepository();
    memoryUseCase = _FakeMemoryContextUseCase();
    conversationUseCase = _FakeConversationContextUseCase();
    modeResolver = _FakeModeResolver();
  });

  DispatchAgentUseCase createUseCase({
    _FakeMemoryContextUseCase? memory,
    _FakeConversationContextUseCase? conversation,
    _FakeModeResolver? resolver,
  }) {
    return DispatchAgentUseCase(
      agentRepo: agentRepo,
      memoryContextUseCase: memory,
      conversationContextUseCase: conversation,
      modeResolver: resolver,
    );
  }

  // ---- Successful dispatch -----------------------------------------------

  group('successful dispatch', () {
    test('resolves agent, builds prompt, returns PreparedDispatch', () async {
      final agent = _testAgent();
      agentRepo.addAgent(agent);

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: agent.id,
        prompt: 'Do something',
      );

      expect(result.agent, equals(agent));
      expect(result.effectivePrompt, isNotEmpty);
      expect(result.effectivePrompt.contains('Do something'), isTrue);
      expect(result.effectiveConversationId, isNull);
      expect(result.mode, ConversationMode.chat);
      // Default cliName from predefinedAdapters: 'pi'
      expect(result.cliName, 'pi');
    });

    test('uses conversationId directly when provided', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        conversationId: 'conv-42',
        channelId: 'ch-99',
      );

      expect(result.effectiveConversationId, 'conv-42');
    });

    test('falls back to channelId when conversationId is null', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        channelId: 'ch-99',
      );

      expect(result.effectiveConversationId, 'ch-99');
    });

    test('resolves agent adapterId when no explicit adapterId is given',
        () async {
      final agent = _testAgent(adapterId: 'claude-code');
      agentRepo.addAgent(agent);

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: agent.id,
        prompt: 'test',
      );

      expect(result.resolvedAdapterId, 'claude-code');
      expect(result.cliName, 'claude');
    });

    test('uses explicit adapterId over agent adapterId', () async {
      final agent = _testAgent(adapterId: 'claude-code');
      agentRepo.addAgent(agent);

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: agent.id,
        prompt: 'test',
        adapterId: 'pi-dev',
      );

      expect(result.resolvedAdapterId, 'pi-dev');
      expect(result.cliName, 'pi');
    });

    test('cliName defaults to pi when adapter not found', () async {
      agentRepo.addAgent(_testAgent(adapterId: null));

      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        adapterId: 'nonexistent',
      );

      expect(result.resolvedAdapterId, 'nonexistent');
      expect(result.cliName, 'pi');
    });

    test('resolves plan mode when modeResolver returns plan', () async {
      agentRepo.addAgent(_testAgent());
      modeResolver.onResolve = (_) async => ConversationMode.plan;

      final useCase = createUseCase(resolver: modeResolver);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'Design a system',
        channelId: 'ch-1',
        workingDirectory: '/tmp/ws',
      );

      expect(result.mode, ConversationMode.plan);
      // Plan mode injects ModePromptContext with planGoal and plansDir
      expect(result.effectivePrompt, contains('Design a system'));
    });

    test('passes wakeContext through to prompt builder', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase();
      const wake = WakeContext(
        runId: 'run-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        wakeReason: WakeReason.userMessage,
      );
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        wakeContext: wake,
      );

      // wakeContext text is incorporated by prompt builder
      expect(result.effectivePrompt, isNotEmpty);
    });

    test('passes mentionContext through to prompt builder', () async {
      agentRepo.addAgent(_testAgent(name: 'TestBot'));

      final useCase = createUseCase();
      const mention = MentionContext(
        summonedBy: 'UserX',
        channelRoster: [
          MentionRosterEntry(
            agentId: 'agent-1',
            name: 'TestBot',
            isTopLevel: false,
          ),
        ],
      );
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        mentionContext: mention,
      );

      // Mention context injects summoner info
      expect(result.effectivePrompt, contains('UserX'));
    });
  });

  // ---- Memory context ----------------------------------------------------

  group('memory context', () {
    test('skips when use case is not wired (null)', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase(memory: null);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
      );

      expect(result.effectivePrompt, isNotEmpty);
      // Prompt should still build without memory context
      expect(result.effectivePrompt.contains('Do something'), isFalse);
    });

    test('skips when agent is not found', () async {
      // No agent added to repo
      memoryUseCase.onExecute = ({
        required String workspaceId,
        required String agentId,
        String? taskDescription,
      }) async =>
          'CONTAMINATION';

      final useCase = createUseCase(memory: memoryUseCase);
      final result = await useCase.execute(
        agentId: 'nonexistent',
        prompt: 'test',
      );

      expect(result.agent, isNull);
      // Memory context should not appear since agent is null
      expect(result.effectivePrompt, isNot(contains('CONTAMINATION')));
    });

    test('injects memory context when agent is found', () async {
      final agent = _testAgent();
      agentRepo.addAgent(agent);
      memoryUseCase.onExecute = ({
        required String workspaceId,
        required String agentId,
        String? taskDescription,
      }) async =>
          '## My Notes\nRemember to use camelCase.';

      final useCase = createUseCase(memory: memoryUseCase);
      final result = await useCase.execute(
        agentId: agent.id,
        prompt: 'Write a function',
      );

      expect(result.effectivePrompt, contains('camelCase'));
    });

    test('passes workspaceId and agentId to memory use case', () async {
      final agent = _testAgent(workspaceId: 'ws-5', id: 'agt-5');
      agentRepo.addAgent(agent);

      String? capturedWorkspace;
      String? capturedAgentId;
      String? capturedTask;
      memoryUseCase.onExecute = ({
        required String workspaceId,
        required String agentId,
        String? taskDescription,
      }) async {
        capturedWorkspace = workspaceId;
        capturedAgentId = agentId;
        capturedTask = taskDescription;
        return '';
      };

      final useCase = createUseCase(memory: memoryUseCase);
      await useCase.execute(
        agentId: agent.id,
        prompt: 'Fix the bug',
      );

      expect(capturedWorkspace, 'ws-5');
      expect(capturedAgentId, 'agt-5');
      expect(capturedTask, 'Fix the bug');
    });

    test('handles memory context build failure gracefully', () async {
      agentRepo.addAgent(_testAgent());
      memoryUseCase.throwOnExecute = Exception('DB down');

      final useCase = createUseCase(memory: memoryUseCase);
      // Should not throw
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
      );

      expect(result.effectivePrompt, isNotEmpty);
    });

    test('empty memory context does not block dispatch', () async {
      agentRepo.addAgent(_testAgent());
      memoryUseCase.onExecute = ({
        required String workspaceId,
        required String agentId,
        String? taskDescription,
      }) async =>
          '';

      final useCase = createUseCase(memory: memoryUseCase);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
      );

      expect(result.effectivePrompt, isNotEmpty);
    });
  });

  // ---- Conversation context ----------------------------------------------

  group('conversation context', () {
    test('skips when use case is not wired', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase(conversation: null);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        channelId: 'ch-1',
      );

      expect(result.effectivePrompt, isNotEmpty);
    });

    test('skips when channelId is null', () async {
      agentRepo.addAgent(_testAgent());
      conversationUseCase.onExecute = ({
        required String channelId,
        required String selfAgentId,
        required String selfAgentName,
        required String taskDescription,
        required int characterBudget,
      }) async =>
          'CONV-DATA';

      final useCase = createUseCase(conversation: conversationUseCase);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
      );

      expect(result.effectivePrompt, isNot(contains('CONV-DATA')));
    });

    test('skips when agent is not found (agentId null)', () async {
      conversationUseCase.onExecute = ({
        required String channelId,
        required String selfAgentId,
        required String selfAgentName,
        required String taskDescription,
        required int characterBudget,
      }) async =>
          'CONV-DATA';

      final useCase = createUseCase(conversation: conversationUseCase);
      final result = await useCase.execute(
        agentId: 'nonexistent',
        prompt: 'test',
        channelId: 'ch-1',
      );

      expect(result.effectivePrompt, isNot(contains('CONV-DATA')));
    });

    test('injects conversation context when channel and agent are available',
        () async {
      final agent = _testAgent(name: 'TestBot');
      agentRepo.addAgent(agent);
      conversationUseCase.onExecute = ({
        required String channelId,
        required String selfAgentId,
        required String selfAgentName,
        required String taskDescription,
        required int characterBudget,
      }) async =>
          '## Recent messages\nUser: hello';

      final useCase = createUseCase(conversation: conversationUseCase);
      final result = await useCase.execute(
        agentId: agent.id,
        prompt: 'test',
        channelId: 'ch-1',
      );

      expect(result.effectivePrompt, contains('Recent messages'));
    });

    test('passes character budget derived from agent contextSize', () async {
      final agent = _testAgent(contextSize: 50000);
      agentRepo.addAgent(agent);

      int? capturedBudget;
      conversationUseCase.onExecute = ({
        required String channelId,
        required String selfAgentId,
        required String selfAgentName,
        required String taskDescription,
        required int characterBudget,
      }) async {
        capturedBudget = characterBudget;
        return '';
      };

      final useCase = createUseCase(conversation: conversationUseCase);
      await useCase.execute(
        agentId: agent.id,
        prompt: 'test',
        channelId: 'ch-1',
      );

      // contextSize * 2 = 100000, clamped to maxConversationChars (50000)
      expect(capturedBudget, 50000);
    });

    test('character budget uses default when contextSize is null', () async {
      final agent = _testAgent(contextSize: null);
      agentRepo.addAgent(agent);

      int? capturedBudget;
      conversationUseCase.onExecute = ({
        required String channelId,
        required String selfAgentId,
        required String selfAgentName,
        required String taskDescription,
        required int characterBudget,
      }) async {
        capturedBudget = characterBudget;
        return '';
      };

      final useCase = createUseCase(conversation: conversationUseCase);
      await useCase.execute(
        agentId: agent.id,
        prompt: 'test',
        channelId: 'ch-1',
      );

      // default contextSize = 1000000, * 2 = 2000000, clamped to 50000
      expect(capturedBudget, 50000);
    });

    test('handles conversation context build failure gracefully', () async {
      agentRepo.addAgent(_testAgent());
      conversationUseCase.throwOnExecute = Exception('Channel not found');

      final useCase = createUseCase(conversation: conversationUseCase);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        channelId: 'ch-1',
      );

      expect(result.effectivePrompt, isNotEmpty);
    });
  });

  // ---- Mode resolution ---------------------------------------------------

  group('mode resolution', () {
    test('defaults to chat when modeResolver is null', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = createUseCase(resolver: null);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'test',
        channelId: 'ch-1',
      );

      expect(result.mode, ConversationMode.chat);
    });

    test('resolves review mode via resolver', () async {
      agentRepo.addAgent(_testAgent());
      modeResolver.onResolve = (_) async => ConversationMode.review;

      final useCase = createUseCase(resolver: modeResolver);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'Review PR #42',
        channelId: 'ch-review',
      );

      expect(result.mode, ConversationMode.review);
    });
  });

  // ---- All optional dependencies null -----------------------------------

  group('minimal wiring', () {
    test('works with all optional dependencies null', () async {
      agentRepo.addAgent(_testAgent());

      final useCase = DispatchAgentUseCase(agentRepo: agentRepo);
      final result = await useCase.execute(
        agentId: 'agent-1',
        prompt: 'Hello',
      );

      expect(result.agent, isNotNull);
      expect(result.effectivePrompt, isNotEmpty);
      expect(result.mode, ConversationMode.chat);
      expect(result.cliName, 'pi');
      expect(result.resolvedAdapterId, isNull);
    });
  });

  // ---- Agent not found ---------------------------------------------------

  group('agent not found', () {
    test('returns PreparedDispatch with null agent', () async {
      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: 'nonexistent',
        prompt: 'test',
      );

      expect(result.agent, isNull);
      // Adapter falls back to explicit adapterId, or null
      expect(result.resolvedAdapterId, isNull);
      expect(result.cliName, 'pi');
      // Prompt is raw (no agent to layer onto)
      expect(result.effectivePrompt, equals('test'));
      expect(result.effectiveConversationId, isNull);
      expect(result.mode, ConversationMode.chat);
    });

    test('still resolves explicit adapterId even when agent not found',
        () async {
      final useCase = createUseCase();
      final result = await useCase.execute(
        agentId: 'nonexistent',
        prompt: 'test',
        adapterId: 'claude-code',
      );

      expect(result.agent, isNull);
      expect(result.resolvedAdapterId, 'claude-code');
      expect(result.cliName, 'claude');
    });

    test('memory context skipped when agent not found', () async {
      memoryUseCase.onExecute = ({
        required String workspaceId,
        required String agentId,
        String? taskDescription,
      }) async =>
          'CONTAMINATION';
      final useCase = createUseCase(memory: memoryUseCase);

      final result = await useCase.execute(
        agentId: 'nonexistent',
        prompt: 'test',
      );

      expect(result.effectivePrompt, equals('test'));
    });
  });

  // ---- Agent repo throws ------------------------------------------------

  group('agent repo throws', () {
    test('propagates exception from agent repository', () async {
      agentRepo.throwOnGetById = Exception('Connection refused');
      final useCase = createUseCase();

      await expectLater(
        () => useCase.execute(agentId: 'any', prompt: 'test'),
        throwsA(isA<Exception>().having(
          (e) => '$e',
          'message',
          contains('Connection refused'),
        )),
      );
    });
  });
}
