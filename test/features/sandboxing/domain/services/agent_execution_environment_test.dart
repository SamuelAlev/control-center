import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/sandboxing/domain/services/agent_execution_environment.dart';
import 'package:test/test.dart';

import '../../../../fakes/fake_filesystem_port.dart';

// ── Tracking fake that records writeString / ensureDir calls ────────────

class TrackingFilesystemPort extends FakeFilesystemPort {
  final Map<String, String> written = {};
  final List<String> ensured = [];

  @override
  Future<void> ensureDir(String path) async {
    ensured.add(path);
  }

  @override
  Future<void> writeString(String path, String content) async {
    unawaited(super.writeString(path, content));
    written[path] = content;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

// The code constructs runDir as: '${agent.agentMdPath}/../runs/$ticketId'
// So with agentMdPath='/fake/agent.md' and ticketId='ticket-1':
//   runDir = '/fake/agent.md/../runs/ticket-1'
String _runDir({
  String agentMdPath = '/fake/agent.md',
  String ticketId = 'ticket-1',
}) =>
    '$agentMdPath/../runs/$ticketId';

Agent _agent({
  String id = 'agent-1',
  String name = 'test',
  String agentMdPath = '/fake/agent.md',
  String persona = 'helpful',
  String systemPrompt = 'be good',
}) =>
    Agent(
      id: id,
      name: name,
      title: 'Test Agent',
      agentMdPath: agentMdPath,
      workspaceId: 'ws-1',
      skills: AgentSkills(const ['dart', 'flutter']),
      persona: persona,
      systemPrompt: systemPrompt,
      createdAt: DateTime(2026),
    );

Agent _agentNoSkills() => Agent(
      id: 'agent-1',
      name: 'test',
      title: 'Test Agent',
      agentMdPath: '/fake/agent.md',
      workspaceId: 'ws-1',
      skills: AgentSkills(const []),
      persona: 'helpful',
      systemPrompt: 'be good',
      createdAt: DateTime(2026),
    );

AgentExecutionEnvironment _env(TrackingFilesystemPort fs) =>
    AgentExecutionEnvironment(filesystem: fs);

void main() {
  group('AgentExecutionEnvironment.prepare', () {
    late TrackingFilesystemPort fs;

    setUp(() {
      fs = TrackingFilesystemPort();
    });

    test('prepare creates run directory with AGENTS.md', () async {
      final agent = _agent();
      final rd = _runDir();

      final runDir = await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
      );

      expect(fs.ensured, contains(rd));
      expect(fs.written.containsKey('$rd/AGENTS.md'), isTrue);
      expect(runDir, equals(rd));
    });

    test('prepare writes SKILLS.md when agent has skills', () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
      );

      expect(fs.written.containsKey('$rd/SKILLS.md'), isTrue);
      expect(fs.written['$rd/SKILLS.md'], contains('dart'));
    });

    test('prepare does NOT write SKILLS.md when agent has no skills',
        () async {
      final agent = _agentNoSkills();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
      );

      expect(fs.written.containsKey('$rd/SKILLS.md'), isFalse);
    });

    test('prepare always writes TOOLS.md', () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
      );

      expect(fs.written.containsKey('$rd/TOOLS.md'), isTrue);
    });

    test(
        'prepare writes MEMORY.md when memoryContext is provided and non-empty',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        memoryContext: 'Remember the key: 42',
      );

      expect(fs.written.containsKey('$rd/MEMORY.md'), isTrue);
      expect(
        fs.written['$rd/MEMORY.md'],
        equals('Remember the key: 42'),
      );
    });

    test('prepare does NOT write MEMORY.md when memoryContext is null',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        memoryContext: null,
      );

      expect(fs.written.containsKey('$rd/MEMORY.md'), isFalse);
    });

    test('prepare does NOT write MEMORY.md when memoryContext is empty',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        memoryContext: '',
      );

      expect(fs.written.containsKey('$rd/MEMORY.md'), isFalse);
    });

    test(
        'prepare writes CONTINUATION.md when continuationSummary is provided',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        continuationSummary: 'We left off at step 3.',
      );

      expect(fs.written.containsKey('$rd/CONTINUATION.md'), isTrue);
      expect(
        fs.written['$rd/CONTINUATION.md'],
        contains('We left off at step 3.'),
      );
    });

    test(
        'prepare does NOT write CONTINUATION.md when continuationSummary is null',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        continuationSummary: null,
      );

      expect(fs.written.containsKey('$rd/CONTINUATION.md'), isFalse);
    });

    test(
        'prepare does NOT write CONTINUATION.md when continuationSummary is empty',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
        continuationSummary: '',
      );

      expect(fs.written.containsKey('$rd/CONTINUATION.md'), isFalse);
    });

    test('prepare returns correct run directory path', () async {
      const agentMdPath = '/workspace/agents/my-agent/AGENTS.md';
      final agent = _agent(agentMdPath: agentMdPath);

      final runDir = await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-abc-123',
        mode: ConversationMode.chat,
      );

      // Path is literal: '{agentMdPath}/../runs/{ticketId}'
      expect(runDir,
          equals('/workspace/agents/my-agent/AGENTS.md/../runs/ticket-abc-123'));
    });

    test('prepare with chat mode writes prompt including memory instructions',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.chat,
      );

      final agentsMd = fs.written['$rd/AGENTS.md']!;
      // Chat mode: the execution contract should mention saving facts proactively.
      expect(agentsMd, contains('do not wait to be asked'));
    });

    test(
        'prepare with review mode writes prompt including review-specific mode block',
        () async {
      final agent = _agent();
      final rd = _runDir();

      await _env(fs).prepare(
        agent: agent,
        workspaceId: 'ws-1',
        ticketId: 'ticket-1',
        mode: ConversationMode.review,
      );

      final agentsMd = fs.written['$rd/AGENTS.md']!;
      // Review mode: should contain review-specific text.
      expect(agentsMd, contains('PR reviewer'));
      // resourceProtocols() is called without mode param, defaults to chat,
      // so memory management IS included.
      expect(agentsMd, contains('do not wait to be asked'));
    });
  });
}
