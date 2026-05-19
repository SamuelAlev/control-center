import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_mcp/src/tools/add_review_node_tool.dart';
import 'package:test/test.dart';

class _FakeMessagingRepository implements MessagingRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      null;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => const [];

  final List<Map<String, dynamic>> sentMessages = [];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    sentMessages.add({
      'spaceId': spaceId,
      'conversationId': conversationId,
      'content': content,
      'senderId': senderId,
      'senderType': senderType,
      'messageType': messageType,
      'metadata': metadata,
      'id': id,
    });
    return '';
  }

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([]);

  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {}

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
  }) async {}

  @override
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => [];

  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) async => null;

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => const {};

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {}

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => Stream.value([]);

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}

  Future<void> updateSpaceType(String spaceId, String type) async {}

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => [];

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => Stream.value([]);

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];

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

void main() {
  group('AddReviewNodeTool', () {
    late _FakeMessagingRepository repository;
    late AddReviewNodeTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = AddReviewNodeTool(repository: repository);
    });

    // A finding belongs in the stream the reviewer that filed it is working
    // in. It used to go to the space's standing conversation — the lead's
    // report and the artifact the PR review tab renders — which buried that
    // report under every reviewer's findings and left each reviewer's own tab
    // showing narration about findings it never displayed.
    group('destination conversation', () {
      Future<Object?> fileFinding(AddReviewNodeTool t) => t.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'Null pointer on line 42',
        'priority': 'p0',
        'confidence': 0.9,
      });

      test("files into the reviewer's active-run conversation", () async {
        final withRun = AddReviewNodeTool(
          repository: repository,
          runLogs: _FakeRunLogs(
            _run(workspaceId: 'ws-1', conversationId: 'conv-architect'),
          ),
        );
        await fileFinding(withRun);
        expect(
          repository.sentMessages.single['conversationId'],
          'conv-architect',
        );
      });

      test(
        'falls back to the standing conversation with no active run',
        () async {
          final noRun = AddReviewNodeTool(
            repository: repository,
            runLogs: _FakeRunLogs(null),
          );
          await fileFinding(noRun);
          // Null lets the repository resolve the space's standing conversation —
          // exactly where these went before, so nothing is lost.
          expect(repository.sentMessages.single['conversationId'], isNull);
        },
      );

      test('ignores a run belonging to another workspace', () async {
        final foreign = AddReviewNodeTool(
          repository: repository,
          runLogs: _FakeRunLogs(
            _run(workspaceId: 'ws-2', conversationId: 'conv-elsewhere'),
          ),
        );
        await fileFinding(foreign);
        expect(repository.sentMessages.single['conversationId'], isNull);
      });

      test('survives a run-log lookup that throws', () async {
        final broken = AddReviewNodeTool(
          repository: repository,
          runLogs: _ThrowingRunLogs(),
        );
        final result = await fileFinding(broken);
        // The finding is the expensive part of a review pass; a bookkeeping
        // failure must not lose one.
        expect((result! as CallResult).isError, isFalse);
        expect(repository.sentMessages.single['conversationId'], isNull);
      });
    });

    test('has correct name', () {
      expect(tool.name, 'add_review_node');
    });

    test('has valid inputSchema with priority and confidence required', () {
      final schema = tool.inputSchema;
      expect(
        schema['required'],
        containsAll([
          'space_id',
          'sender_id',
          'node_type',
          'content',
          'priority',
          'confidence',
        ]),
      );
      final nodeType =
          (schema['properties'] as Map<String, dynamic>)['node_type']
              as Map<String, dynamic>;
      expect(nodeType['enum'], [
        'bug',
        'suggestion',
        'recommendation',
        'question',
        'ticket',
      ]);
      final priority =
          (schema['properties'] as Map<String, dynamic>)['priority']
              as Map<String, dynamic>;
      expect(priority['enum'], ['p0', 'p1', 'p2', 'p3']);
    });

    test('adds review node with required fields', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'Null pointer on line 42',
        'priority': 'p0',
        'confidence': 0.92,
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['node_type'], 'bug');
      expect(data['priority'], 'p0');
      expect(data['confidence'], 0.92);
      expect(data['status'], 'open');
    });

    test('includes priority and confidence in sent metadata', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'recommendation',
        'content': 'Use const',
        'priority': 'p3',
        'confidence': 0.7,
        'file_path': 'lib/main.dart',
        'line_number': 10,
      });

      expect(repository.sentMessages.length, 1);
      final msg = repository.sentMessages.first;
      expect(msg['messageType'], 'review_node');
      final meta = msg['metadata'] as Map<String, dynamic>;
      expect(meta['filePath'], 'lib/main.dart');
      expect(meta['lineNumber'], 10);
      expect(meta['priority'], 'p3');
      expect(meta['confidence'], 0.7);
      expect(meta.containsKey('severity'), isFalse);
    });

    test('rejects when priority is missing', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('priority'));
    });

    test('rejects when priority is invalid', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p4',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
    });

    test('rejects when confidence is missing', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p0',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('confidence'));
    });

    test('rejects when confidence is out of range', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p0',
        'confidence': 1.5,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('range'));
    });

    // Length is checked mechanically because asking for brevity in the prompt
    // does not hold: a reviewer told to be brief still writes at whatever
    // length it finds satisfying, and the result is inline comments several
    // paragraphs long that nobody reads in the margin of a diff.
    group('body length', () {
      Future<CallResult> file(String content) => tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': content,
        'priority': 'p1',
        'confidence': 0.9,
      });

      test('accepts a title plus three sentences', () async {
        final result = await file(
          '**Await the future before closing the transaction.**\n\n'
          'The handler closes the connection in a `finally` that runs before '
          'the write completes. Rows written after the close are lost without '
          'an error. Await the future before closing.',
        );
        expect(result.isError, isFalse);
      });

      test('rejects a body that has become a report', () async {
        final result = await file('**Fix it.**\n\n${'word ' * 400}');
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('too long'));
        // Actionable, not just a refusal.
        expect(result.content.first.text, contains('fix_diff'));
        expect(repository.sentMessages, isEmpty);
      });

      test('does not count a fenced block against the limit', () async {
        // A short finding that carries its own patch must not be punished for
        // carrying it.
        final patch = '```diff\n${'- old line\n+ new line\n' * 120}```';
        final result = await file(
          '**Await the future before closing the transaction.**\n\n'
          'Rows written after the close are lost.\n\n$patch',
        );
        expect(result.isError, isFalse);
      });

      test('still rejects long prose that surrounds a fenced block', () async {
        final result = await file(
          '**Fix it.**\n\n${'word ' * 200}\n```dart\nfinal x = 1;\n```\n'
          '${'word ' * 200}',
        );
        expect(result.isError, isTrue);
      });
    });

    group('triage axes', () {
      Future<Map<String, dynamic>> fileWith(Map<String, dynamic> extra) async {
        await tool.call({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'sender_id': 'a-1',
          'node_type': 'bug',
          'content': '**Await the future.**\n\nIt leaks otherwise.',
          'priority': 'p2',
          'confidence': 0.9,
          ...extra,
        });
        return repository.sentMessages.last['metadata'] as Map<String, dynamic>;
      }

      test('stores category, severity and effort', () async {
        final meta = await fileWith({
          'category': 'data_integrity',
          'severity': 'major',
          'effort': 'quick_win',
        });
        expect(meta['category'], 'data_integrity');
        expect(meta['severity'], 'major');
        expect(meta['effort'], 'quick_win');
      });

      test('severity derives the priority, overriding the argument', () async {
        // Otherwise a finding could render as critical while the verdict
        // counted it as a p2.
        final meta = await fileWith({'severity': 'critical'});
        expect(meta['priority'], 'p0');
      });

      test('keeps the explicit priority when no severity is given', () async {
        final meta = await fileWith(const {});
        expect(meta['priority'], 'p2');
        expect(meta.containsKey('severity'), isFalse);
      });

      test('drops an unrecognized axis instead of failing the call', () async {
        // A mislabelled finding is still a finding; bouncing the turn would
        // lose the expensive part of a review pass.
        final meta = await fileWith({
          'category': 'vibes',
          'severity': 'apocalyptic',
          'effort': 'herculean',
        });
        expect(meta.containsKey('category'), isFalse);
        expect(meta.containsKey('severity'), isFalse);
        expect(meta.containsKey('effort'), isFalse);
        expect(meta['priority'], 'p2');
      });

      test('stores a proposed fix and an agent prompt', () async {
        final meta = await fileWith({
          'fix_diff': '- await x;\n+ await x.close();',
          'ai_prompt': 'Close the client before returning.',
        });
        expect(meta['fixDiff'], '- await x;\n+ await x.close();');
        expect(meta['aiPrompt'], 'Close the client before returning.');
      });

      test('treats a blank fix or prompt as absent', () async {
        final meta = await fileWith({'fix_diff': '  ', 'ai_prompt': ''});
        expect(meta.containsKey('fixDiff'), isFalse);
        expect(meta.containsKey('aiPrompt'), isFalse);
      });

      test('echoes the classification in the result payload', () async {
        final result = await tool.call({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'sender_id': 'a-1',
          'node_type': 'bug',
          'content': 'x',
          'priority': 'p2',
          'confidence': 0.9,
          'severity': 'minor',
          'category': 'performance',
          'effort': 'moderate',
        });
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['severity'], 'minor');
        expect(data['category'], 'performance');
        expect(data['effort'], 'moderate');
        expect(data['priority'], 'p2');
      });

      test('the schema advertises each axis without requiring it', () {
        final props = tool.inputSchema['properties'] as Map<String, dynamic>;
        expect((props['severity'] as Map)['enum'], [
          'critical',
          'major',
          'minor',
          'trivial',
          'info',
        ]);
        expect((props['effort'] as Map)['enum'], [
          'quick_win',
          'moderate',
          'heavy_lift',
        ]);
        expect((props['category'] as Map)['enum'], contains('data_integrity'));
        final required = tool.inputSchema['required'] as List;
        for (final key in ['category', 'severity', 'effort', 'fix_diff']) {
          expect(required, isNot(contains(key)), reason: key);
        }
      });
    });
  });
}

/// A run log positioned as the reviewer's active run.
AgentRunLog _run({required String workspaceId, String? conversationId}) =>
    AgentRunLog(
      id: 'run-1',
      agentId: 'a-1',
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: 'ch-1',
      startedAt: DateTime.utc(2026),
      status: RunStatus.running,
    );

class _FakeRunLogs implements AgentRunLogRepository {
  _FakeRunLogs(this._active);

  final AgentRunLog? _active;

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => _active;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingRunLogs implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => throw StateError('database unavailable');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
