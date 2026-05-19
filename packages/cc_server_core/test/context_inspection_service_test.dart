import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/context/context_inspection_service.dart';
import 'package:cc_server_core/src/context/context_rpc_ops.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late _FakeAgents agents;
  late _FakeSpaces spaces;
  late _FakeFilesystem filesystem;
  late McpToolRegistry mcpRegistry;

  const workspaceId = 'ws-1';
  const spaceId = 'space-1';
  const agentId = 'agent-1';

  Agent buildAgent({int? contextSize = 100000}) => Agent(
    id: agentId,
    name: 'Ada',
    title: 'Engineer',
    agentMdPath: '/tmp/ada.md',
    workspaceId: workspaceId,
    skills: AgentSkills(const ['review']),
    systemPrompt: 'Be thorough.',
    persona: 'Calm and precise.',
    contextSize: contextSize,
    createdAt: DateTime(2026),
  );

  ContextInspectionService buildService() => ContextInspectionService(
    agentRepository: agents,
    messagingRepository: spaces,
    modeResolver: _FakeModeResolver(),
    filesystem: filesystem,
    mcpRegistry: mcpRegistry,
    fileSearch: _FakeFileSearch(),
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('context_inspection_test');
    agents = _FakeAgents()..seed(buildAgent());
    spaces = _FakeSpaces()..seed(workspaceId, spaceId);
    filesystem = _FakeFilesystem(tmp.path);
    mcpRegistry = McpToolRegistry([_FakeMcpTool('recall_facts')]);

    // The agent's global dir: an AGENTS.md plus one skill, exactly where a
    // real dispatch reads them.
    final agentDir = Directory(p.join(tmp.path, 'agents', 'ada'));
    await agentDir.create(recursive: true);
    await File(
      p.join(agentDir.path, 'AGENTS.md'),
    ).writeAsString('# House rules\n\nAlways test.');
    final skillDir = Directory(
      p.join(agentDir.path, '.agents', 'skills', 'review'),
    );
    await skillDir.create(recursive: true);
    await File(p.join(skillDir.path, 'SKILL.md')).writeAsString(
      '---\nname: review\ndescription: Reviews code\n---\n\nDo a careful review.\n',
    );
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('segments arrive in declaration order with per-part attribution', () async {
    final inspection = await buildService().inspect(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      includeContent: true,
    );

    expect(inspection.workspaceId, workspaceId);
    expect(inspection.agentName, 'Ada');
    expect(inspection.mode, 'chat');
    expect(inspection.hasContent, isTrue);
    expect(inspection.windowTokens, greaterThan(0));
    expect(inspection.workingDirectory, contains(p.join('agents', 'ada')));

    // Order is the load-bearing contract the stacked bar renders.
    final kinds = [for (final s in inspection.segments) s.kind];
    final order = [
      for (final k in ContextSegmentKind.values) if (kinds.contains(k)) k,
    ];
    expect(kinds, order);

    // No conversation segment: the client composes it from live messages.
    expect(kinds, isNot(contains(ContextSegmentKind.conversation)));

    // Segment totals are the sums of their parts.
    for (final segment in inspection.segments) {
      expect(
        segment.tokens,
        segment.parts.fold<int>(0, (sum, part) => sum + part.tokens),
        reason: segment.kind.name,
      );
    }

    // Rules carry the AGENTS.md content verbatim, one part per file.
    final rules = inspection.segmentFor(ContextSegmentKind.rules)!;
    final agentsMd = rules.parts.where((p) => p.title == 'AGENTS.md');
    expect(agentsMd, hasLength(1));
    expect(agentsMd.single.content, contains('Always test.'));
    // …plus the agent's own instructions and persona sections.
    expect(
      rules.parts.map((p) => p.title),
      containsAll(['Agent instructions', 'Persona']),
    );

    // Skills: the scanned skill is its own part; with content, the SKILL.md
    // body is drill-in-able while the count stays the index line's.
    final skills = inspection.segmentFor(ContextSegmentKind.skills)!;
    final review = skills.parts.where((p) => p.title == 'review');
    expect(review, hasLength(1));
    expect(review.single.content, contains('Do a careful review.'));

    // Tool definitions: the resident built-ins land in toolDefinitions, and
    // the top-level `task` tool is present.
    final builtins = inspection.segmentFor(
      ContextSegmentKind.toolDefinitions,
    )!;
    final builtinNames = [for (final p in builtins.parts) p.title];
    expect(builtinNames, containsAll(['read', 'write', 'bash', 'task']));

    // A bridged MCP tool outside the resident set is reported as DEFERRED, not
    // as absent — it is callable, it just carries no schema until first use.
    // Reporting it under `mcpTools` would claim a per-request cost no request
    // pays, which is the exact lie this service exists to prevent.
    final deferred = inspection.segmentFor(ContextSegmentKind.deferredTools)!;
    final deferredPart = deferred.parts.singleWhere(
      (p) => p.title == 'recall_facts',
    );
    expect(deferredPart.subtitle, contains('withheld'));
    expect(
      inspection.segmentFor(ContextSegmentKind.mcpTools),
      isNull,
      reason: 'nothing bridged is resident in this fixture',
    );

    // Subagent profiles: one part per type.
    final subs = inspection.segmentFor(ContextSegmentKind.subagents)!;
    expect(subs.parts.map((p) => p.title), containsAll(['general', 'explore', 'plan']));
  });

  test('summary mode carries sizes but no content', () async {
    final inspection = await buildService().inspect(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
    );
    expect(inspection.hasContent, isFalse);
    expect(inspection.segments, isNotEmpty);
    for (final segment in inspection.segments) {
      expect(segment.tokens, greaterThan(0), reason: segment.kind.name);
      for (final part in segment.parts) {
        expect(part.content, isNull, reason: part.id);
        expect(part.chars, greaterThan(0), reason: part.id);
      }
    }
  });

  test('a foreign-workspace agent resolves to nothing', () async {
    await expectLater(
      buildService().inspect(
        workspaceId: 'ws-OTHER',
        spaceId: spaceId,
        agentId: agentId,
      ),
      throwsArgumentError,
    );
  });

  test('an unknown space in the workspace is refused', () async {
    await expectLater(
      buildService().inspect(
        workspaceId: workspaceId,
        spaceId: 'no-such-space',
        agentId: agentId,
      ),
      throwsArgumentError,
    );
  });

  test('a provisioned overlay wins over the agent dir fallback', () async {
    final overlay = Directory(
      p.join(tmp.path, 'conversations', spaceId, 'agents', 'ada'),
    );
    await overlay.create(recursive: true);
    await File(
      p.join(overlay.path, 'AGENTS.md'),
    ).writeAsString('# Overlay rules\n\nOverlay wins.');

    final inspection = await buildService().inspect(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      includeContent: true,
    );
    expect(inspection.workingDirectory, overlay.path);
    final rules = inspection.segmentFor(ContextSegmentKind.rules)!;
    expect(
      rules.parts.where((p) => p.title == 'AGENTS.md').single.content,
      contains('Overlay wins.'),
    );
  });

  test('context.inspect op returns the inspection over the wire shape', () async {
    final ops = buildContextOps(inspection: buildService());
    expect(ops, hasLength(1));
    final op = ops.single;
    expect(op.name, 'context.inspect');
    expect(op.kind, RepoOpKind.read);
    expect(op.requiredArgs, containsAll(['space_id', 'agent_id']));

    final data = await op.handler(
      const RepoOpContext(
        args: {'space_id': spaceId, 'agent_id': agentId},
        workspaceId: workspaceId,
        deviceId: 'device-1',
        userId: 'user-1',
      ),
    );
    final inspection = ContextInspection.fromJson(
      (data['inspection'] as Map).cast<String, dynamic>(),
    );
    expect(inspection.agentName, 'Ada');
    expect(inspection.hasContent, isFalse);
    expect(
      inspection.segments.map((s) => s.kind),
      isNot(contains(ContextSegmentKind.conversation)),
    );

    final withContent = await op.handler(
      const RepoOpContext(
        args: {
          'space_id': spaceId,
          'agent_id': agentId,
          'include_content': true,
        },
        workspaceId: workspaceId,
        deviceId: 'device-1',
        userId: 'user-1',
      ),
    );
    final full = ContextInspection.fromJson(
      (withContent['inspection'] as Map).cast<String, dynamic>(),
    );
    expect(full.hasContent, isTrue);
    expect(
      full.segments.expand((s) => s.parts).any((p) => p.content != null),
      isTrue,
    );
  });

  test('wire round-trip preserves the payload the client renders', () async {
    final inspection = await buildService().inspect(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      includeContent: true,
    );
    final restored = ContextInspection.fromJson(inspection.toJson());
    expect(restored.toJson(), inspection.toJson());
  });
}

class _FakeAgents implements AgentRepository {
  final Map<String, Agent> _byId = {};

  void seed(Agent agent) => _byId['${agent.workspaceId}/${agent.id}'] = agent;

  @override
  Future<Agent?> getById(String workspaceId, String agentId) async =>
      _byId['$workspaceId/$agentId'];

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([
    for (final a in _byId.values)
      if (a.workspaceId == workspaceId) a,
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSpaces implements MessagingRepository {
  final Set<String> _spaces = {};

  void seed(String workspaceId, String spaceId) =>
      _spaces.add('$workspaceId/$spaceId');

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async {
    if (!_spaces.contains('$workspaceId/$spaceId')) {
      return null;
    }
    return Space(
      id: spaceId,
      name: 'Space',
      workspaceId: workspaceId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeModeResolver implements ModeResolver {
  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) async => Mode.chat;
}

class _FakeFilesystem implements WorkspaceFilesystemPort {
  _FakeFilesystem(this._root);

  final String _root;

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async =>
      p.join(_root, 'agents', agentSlug);

  @override
  Future<String> spaceDir(
    String workspaceId,
    String conversationId,
  ) async => p.join(_root, 'conversations', conversationId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFileSearch implements FileSearchPort {
  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    int limit = 20,
    required String root,
  }) async => const [];
}

class _FakeMcpTool extends McpTool {
  _FakeMcpTool(this._name);

  final String _name;

  @override
  String get name => _name;

  @override
  String get description => 'Fake $_name tool for tests.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.error('not implemented in tests');
}
