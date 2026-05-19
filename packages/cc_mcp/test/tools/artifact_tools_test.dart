import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/artifact_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/artifact_tools.dart';
import 'package:test/test.dart';

/// In-memory [WorkProductRepository]. Every read filters by workspace exactly
/// like the DAO does, so the isolation assertions below test the real boundary
/// rather than a permissive fake.
class _InMemoryWorkProducts implements WorkProductRepository {
  final List<WorkProduct> products = [];
  final List<WorkProductRevision> revisions = [];

  @override
  Future<void> upsert(WorkProduct workProduct) async {
    products.removeWhere((p) => p.id == workProduct.id);
    products.add(workProduct);
  }

  @override
  Future<void> addRevision(WorkProductRevision revision) async =>
      revisions.add(revision);

  @override
  Future<WorkProduct?> getById(String workspaceId, String id) async => products
      .where((p) => p.id == id && p.workspaceId == workspaceId)
      .firstOrNull;

  @override
  Stream<List<WorkProduct>> watchByWorkspace(String workspaceId) =>
      Stream.value(
        products
            .where((p) => p.workspaceId == workspaceId)
            .toList()
            .reversed
            .toList(),
      );

  @override
  Future<List<WorkProduct>> forTicket(
    String workspaceId,
    String ticketId,
  ) async => products
      .where((p) => p.workspaceId == workspaceId && p.ticketId == ticketId)
      .toList();

  @override
  Future<void> delete(String workspaceId, String id) async =>
      products.removeWhere((p) => p.id == id && p.workspaceId == workspaceId);

  @override
  Future<List<WorkProductRevision>> getRevisions(
    String workspaceId,
    String workProductId,
  ) async =>
      (revisions
              .where(
                (r) =>
                    r.workspaceId == workspaceId &&
                    r.workProductId == workProductId,
              )
              .toList()
            ..sort((a, b) => b.revisionNumber.compareTo(a.revisionNumber)))
          .toList();

  @override
  Stream<List<WorkProductRevision>> watchRevisions(
    String workspaceId,
    String workProductId,
  ) => Stream.fromFuture(getRevisions(workspaceId, workProductId));

  @override
  Future<WorkProductRevision?> getRevisionById(
    String workspaceId,
    String id,
  ) async => revisions
      .where((r) => r.id == id && r.workspaceId == workspaceId)
      .firstOrNull;
}

/// Returns a fixed active run (or none) for any agent.
class _FakeRunLogs implements AgentRunLogRepository {
  _FakeRunLogs(this._run);
  final AgentRunLog? _run;

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => _run;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every message the tools post.
class _RecordingMessaging implements MessagingRepository {
  final List<
    ({
      String workspaceId,
      String channelId,
      String? conversationId,
      String content,
      String messageType,
      Map<String, dynamic>? metadata,
    })
  >
  sent = [];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    sent.add((
      workspaceId: workspaceId,
      channelId: channelId,
      conversationId: conversationId,
      content: content,
      messageType: messageType,
      metadata: metadata,
    ));
    return id ?? 'msg-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentRunLog _run({
  String workspaceId = 'ws1',
  String? conversationId = 'conv-1',
  String? channelId = 'chan-1',
}) => AgentRunLog(
  id: 'run-1',
  agentId: 'a1',
  workspaceId: workspaceId,
  conversationId: conversationId,
  channelId: channelId,
  startedAt: DateTime.utc(2026, 7, 25),
  status: RunStatus.running,
);

const _markdown = {'type': 'markdown', 'text': 'The comparison:'};
const _table = {
  'type': 'table',
  'columns': [
    {'key': 'opt', 'label': 'Option'},
    {'key': 'cost', 'label': 'Cost', 'align': 'right'},
  ],
  'rows': [
    ['A', '\$3'],
    ['B', '\$5'],
  ],
};
const _emptyChart = {'type': 'chart', 'chartKind': 'bar', 'series': <Object>[]};

void main() {
  late _InMemoryWorkProducts repository;
  late WorkProductService service;
  late _RecordingMessaging messaging;
  late DomainEventBus eventBus;
  late List<ArtifactEvent> events;

  setUp(() {
    repository = _InMemoryWorkProducts();
    service = WorkProductService(repository: repository);
    messaging = _RecordingMessaging();
    eventBus = DomainEventBus();
    events = [];
    eventBus.on<ArtifactEvent>().listen(events.add);
  });

  tearDown(() => eventBus.dispose());

  PublishArtifactTool publishTool({AgentRunLog? run}) => PublishArtifactTool(
    runLogRepository: _FakeRunLogs(run ?? _run()),
    workProducts: service,
    messaging: messaging,
    eventBus: eventBus,
  );

  ReviseArtifactTool reviseTool({AgentRunLog? run}) => ReviseArtifactTool(
    runLogRepository: _FakeRunLogs(run ?? _run()),
    workProducts: service,
    repository: repository,
    eventBus: eventBus,
  );

  Map<String, dynamic> payload(CallResult result) =>
      jsonDecode(result.content.first.text) as Map<String, dynamic>;

  group('publish_artifact', () {
    test(
      'stores a revision, posts an artifact message and fires the event',
      () async {
        final result = await publishTool().run({
          'workspace_id': 'ws1',
          'agent_id': 'a1',
          'title': 'Backend options',
          'artifact_type': 'report',
          'blocks': [_markdown, _table],
        });
        expect(result.isError, isFalse);
        final json = payload(result);
        expect(json['block_count'], 2);
        expect(json['block_ids'], ['b1', 'b2']);
        expect(json['block_errors'], isEmpty);

        // The work product + its first revision hold the block envelope.
        expect(repository.products, hasLength(1));
        final product = repository.products.single;
        expect(product.workspaceId, 'ws1');
        expect(product.title, 'Backend options');
        expect(product.artifactType.name, 'report');
        expect(product.agentId, 'a1');
        expect(repository.revisions, hasLength(1));
        final revision = repository.revisions.single;
        expect(revision.revisionNumber, 1);
        expect(product.currentRevisionId, revision.id);
        final document = ArtifactDocument.tryParseContent(revision.content);
        expect(document, isNotNull);
        expect(document!.blocks.map((b) => b.type), ['markdown', 'table']);

        // The conversation carries a typed card whose metadata is ids ONLY — the
        // bubble watches the row so revisions re-render in place.
        expect(messaging.sent, hasLength(1));
        final message = messaging.sent.single;
        expect(message.messageType, 'artifact');
        // The message is written to the run's own workspace database, never to
        // whatever workspace happened to be active.
        expect(message.workspaceId, 'ws1');
        expect(message.channelId, 'chan-1');
        expect(message.conversationId, 'conv-1');
        expect(message.metadata, {
          'workProductId': product.id,
          'revisionId': revision.id,
        });
        expect(message.content, contains('Backend options'));

        await pumpEventQueue();
        expect(events.single, isA<ArtifactPublished>());
        final event = events.single as ArtifactPublished;
        expect(event.workProductId, product.id);
        expect(event.revisionId, revision.id);
        expect(event.workspaceId, 'ws1');
        expect(event.conversationId, 'conv-1');
        expect(event.blockCount, 2);
        expect(event.title, 'Backend options');
      },
    );

    test(
      'drops one invalid block, publishes the rest and reports the path',
      () async {
        final result = await publishTool().run({
          'workspace_id': 'ws1',
          'agent_id': 'a1',
          'title': 'Partly broken',
          'blocks': [_markdown, _emptyChart, _table],
        });
        expect(result.isError, isFalse);
        final json = payload(result);
        expect(json['block_count'], 2);
        expect(json['block_errors'], ['blocks[1].chart: series is empty']);
        expect(json['message'], contains('DROPPED'));
        expect(repository.revisions, hasLength(1));
      },
    );

    test('a degraded block warns without failing', () async {
      final result = await publishTool().run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'title': 'Gantt',
        'blocks': [
          {'type': 'mermaid', 'source': 'gantt\n  title Release'},
        ],
      });
      final json = payload(result);
      expect(json['block_count'], 1);
      expect(json['block_errors'], isEmpty);
      expect(json['warnings'], hasLength(1));
    });

    test('publishes nothing when no block is valid', () async {
      final result = await publishTool().run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'title': 'All broken',
        'blocks': [_emptyChart],
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('series is empty'));
      expect(repository.products, isEmpty);
      expect(messaging.sent, isEmpty);
    });

    test('rejects a run belonging to another workspace', () async {
      final result = await publishTool(run: _run(workspaceId: 'other')).run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'title': 'Leak',
        'blocks': [_markdown],
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
      expect(repository.products, isEmpty);
    });

    test('rejects when the agent has no active run', () async {
      final tool = PublishArtifactTool(
        runLogRepository: _FakeRunLogs(null),
        workProducts: service,
        messaging: messaging,
      );
      final result = await tool.run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'title': 'Orphan',
        'blocks': [_markdown],
      });
      expect(result.isError, isTrue);
      expect(repository.products, isEmpty);
    });

    test('rejects a run with no conversation', () async {
      final result =
          await publishTool(
            run: _run(conversationId: null, channelId: null),
          ).run({
            'workspace_id': 'ws1',
            'agent_id': 'a1',
            'title': 'Nowhere',
            'blocks': [_markdown],
          });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('conversation'));
    });

    test('reports each missing argument by name', () async {
      final tool = publishTool();
      for (final args in [
        {
          'agent_id': 'a1',
          'title': 't',
          'blocks': [_markdown],
        },
        {
          'workspace_id': 'ws1',
          'title': 't',
          'blocks': [_markdown],
        },
        {
          'workspace_id': 'ws1',
          'agent_id': 'a1',
          'blocks': [_markdown],
        },
      ]) {
        final result = await tool.run(args);
        expect(result.isError, isTrue);
        expect(result.content.first.text, startsWith('Missing or invalid'));
      }
    });
  });

  group('revise_artifact', () {
    Future<String> publish() async {
      final result = await publishTool().run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'title': 'Living doc',
        'blocks': [_markdown, _table],
      });
      return payload(result)['work_product_id'] as String;
    }

    test(
      'appends a revision, posts NO second message, fires ArtifactRevised',
      () async {
        final id = await publish();
        messaging.sent.clear();

        final result = await reviseTool().run({
          'workspace_id': 'ws1',
          'agent_id': 'a1',
          'work_product_id': id,
          'blocks': [_markdown],
          'summary': 'Dropped the table',
        });
        expect(result.isError, isFalse);
        final json = payload(result);
        expect(json['revision_number'], 2);
        expect(json['block_count'], 1);

        expect(repository.revisions, hasLength(2));
        expect(
          repository.products.single.currentRevisionId,
          json['revision_id'],
        );
        // The card in the conversation re-renders from the row; a second bubble
        // per revision would churn the feed for one evolving document.
        expect(messaging.sent, isEmpty);

        await pumpEventQueue();
        expect(events.last, isA<ArtifactRevised>());
        final event = events.last as ArtifactRevised;
        expect(event.revisionNumber, 2);
        expect(event.summary, 'Dropped the table');
      },
    );

    test('never reuses a block id spent by an earlier revision', () async {
      final id = await publish(); // spends b1, b2
      final result = await reviseTool().run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'work_product_id': id,
        'blocks': [_markdown, _table, _markdown],
      });
      expect(payload(result)['block_ids'], ['b3', 'b4', 'b5']);
    });

    test('cannot reach an artifact in another workspace', () async {
      final id = await publish();
      final result =
          await ReviseArtifactTool(
            runLogRepository: _FakeRunLogs(_run(workspaceId: 'ws2')),
            workProducts: service,
            repository: repository,
          ).run({
            'workspace_id': 'ws2',
            'agent_id': 'a1',
            'work_product_id': id,
            'blocks': [_markdown],
          });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
      expect(repository.revisions, hasLength(1));
    });

    test('leaves the artifact untouched when no block is valid', () async {
      final id = await publish();
      final result = await reviseTool().run({
        'workspace_id': 'ws1',
        'agent_id': 'a1',
        'work_product_id': id,
        'blocks': [_emptyChart],
      });
      expect(result.isError, isTrue);
      expect(repository.revisions, hasLength(1));
    });
  });

  group('list_artifacts / get_artifact', () {
    Future<String> publishInto(String workspaceId) async {
      final tool = PublishArtifactTool(
        runLogRepository: _FakeRunLogs(_run(workspaceId: workspaceId)),
        workProducts: service,
        messaging: messaging,
      );
      final result = await tool.run({
        'workspace_id': workspaceId,
        'agent_id': 'a1',
        'title': 'Doc for $workspaceId',
        'blocks': [_markdown],
      });
      return payload(result)['work_product_id'] as String;
    }

    test('list_artifacts returns only the caller workspace rows', () async {
      await publishInto('ws1');
      await publishInto('ws2');

      final result = await ListArtifactsTool(
        repository: repository,
      ).run({'workspace_id': 'ws1'});
      final json = payload(result);
      expect(json['count'], 1);
      final rows = (json['artifacts'] as List).cast<Map<String, dynamic>>();
      expect(rows.single['title'], 'Doc for ws1');
    });

    test('list_artifacts filters by kind', () async {
      await publishInto('ws1');
      final result = await ListArtifactsTool(
        repository: repository,
      ).run({'workspace_id': 'ws1', 'artifact_type': 'plan'});
      expect(payload(result)['count'], 0);
    });

    test('get_artifact returns the decoded blocks and the history', () async {
      final id = await publishInto('ws1');
      final result = await GetArtifactTool(
        repository: repository,
      ).run({'workspace_id': 'ws1', 'work_product_id': id});
      final json = payload(result);
      expect(json['format'], ArtifactDocument.formatVersion);
      final blocks = (json['blocks'] as List).cast<Map<String, dynamic>>();
      expect(blocks.single['type'], 'markdown');
      expect(json['revisions'], hasLength(1));
      expect(json['content'], isNull);
    });

    test('get_artifact refuses an id from another workspace', () async {
      final id = await publishInto('ws1');
      final result = await GetArtifactTool(
        repository: repository,
      ).run({'workspace_id': 'ws2', 'work_product_id': id});
      expect(result.isError, isTrue);
    });

    test('get_artifact reports a plain-text revision as text', () async {
      // Work products predate artifacts: `save_work_product_revision` writes
      // markdown and calling that an empty block document would be a lie.
      final product = await service.create(
        workspaceId: 'ws1',
        title: 'Legacy note',
      );
      await service.addRevision(
        workspaceId: 'ws1',
        workProductId: product.id,
        content: '# just markdown',
      );
      final result = await GetArtifactTool(
        repository: repository,
      ).run({'workspace_id': 'ws1', 'work_product_id': product.id});
      final json = payload(result);
      expect(json['format'], 'text');
      expect(json['blocks'], isNull);
      expect(json['content'], '# just markdown');
    });
  });

  group('schema contract', () {
    test('the block type enum is exactly the canonical kind list', () {
      // The third projection of `artifactBlockKinds` (schema ↔ codec ↔
      // validator). A kind the model is told about but the decoder drops is the
      // "invisible kind" failure this guards.
      for (final schema in [
        publishTool().inputSchema,
        reviseTool().inputSchema,
      ]) {
        final blocks = schema['properties'] as Map<String, dynamic>;
        final items =
            (blocks['blocks'] as Map<String, dynamic>)['items']
                as Map<String, dynamic>;
        final properties = items['properties'] as Map<String, dynamic>;
        final type = properties['type'] as Map<String, dynamic>;
        expect(type['enum'], artifactBlockKinds);
      }
    });

    test('every tool requires workspace_id', () {
      final tools = [
        publishTool(),
        reviseTool(),
        ListArtifactsTool(repository: repository),
        GetArtifactTool(repository: repository),
      ];
      for (final tool in tools) {
        expect(
          tool.inputSchema['required'],
          contains('workspace_id'),
          reason: '${tool.name} must declare workspace_id required',
        );
      }
    });

    test('no artifact tool declares an ActionClass or needs approval', () {
      // One local row + one message: no filesystem, no process, no external
      // system — which is what makes them safe to allow in every mode.
      for (final tool in [
        publishTool(),
        reviseTool(),
        ListArtifactsTool(repository: repository),
        GetArtifactTool(repository: repository),
      ]) {
        expect(tool.actionClasses, isEmpty);
        expect(tool.requiresApproval, isFalse);
      }
    });
  });
}
