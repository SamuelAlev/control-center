import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/approval_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoApprovalRepository] and [ApprovalMapper] end-to-end against an
/// in-memory database. Covers every repository method plus the mapper's
/// JSON-decode branches for `linkedTicketIds` (empty / valid list / malformed).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late ApprovalMapper mapper;
  late DaoApprovalRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    mapper = const ApprovalMapper();
    repo = DaoApprovalRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Approval approval({
    String id = 'ap-1',
    String workspaceId = 'w-1',
    String title = 'merge main',
    String? description,
    ApprovalKind kind = ApprovalKind.merge,
    ApprovalStatus status = ApprovalStatus.pending,
    String requestedByActorType = 'agent',
    String? requestedById = 'a-1',
    List<String> linkedTicketIds = const [],
    String? linkedEntityType,
    String? linkedEntityId,
    String? decidedByActorType,
    String? decidedById,
    String? decisionReason,
    DateTime? decidedAt,
  }) => Approval(
    id: id,
    workspaceId: workspaceId,
    title: title,
    description: description,
    kind: kind,
    status: status,
    requestedByActorType: requestedByActorType,
    requestedById: requestedById,
    linkedTicketIds: linkedTicketIds,
    linkedEntityType: linkedEntityType,
    linkedEntityId: linkedEntityId,
    decidedByActorType: decidedByActorType,
    decidedById: decidedById,
    decisionReason: decisionReason,
    createdAt: DateTime(2026, 1, 1),
    decidedAt: decidedAt,
    updatedAt: DateTime(2026, 1, 1),
  );

  group('ApprovalMapper linkedTicketIds decode branches', () {
    test('empty string decodes to an empty list', () {
      final row = ApprovalsTableData(
        id: 'ap-1',
        workspaceId: 'w-1',
        title: 't',
        description: null,
        kind: 'merge',
        status: 'pending',
        requestedByActorType: 'agent',
        requestedById: null,
        linkedTicketIds: '',
        linkedEntityType: null,
        linkedEntityId: null,
        decidedByActorType: null,
        decidedById: null,
        decisionReason: null,
        createdAt: DateTime(2026, 1, 1),
        decidedAt: null,
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(mapper.toDomain(row).linkedTicketIds, isEmpty);
    });

    test('malformed JSON decodes to an empty list', () {
      final row = ApprovalsTableData(
        id: 'ap-1',
        workspaceId: 'w-1',
        title: 't',
        description: null,
        kind: 'merge',
        status: 'pending',
        requestedByActorType: 'agent',
        requestedById: null,
        linkedTicketIds: '{not a list',
        linkedEntityType: null,
        linkedEntityId: null,
        decidedByActorType: null,
        decidedById: null,
        decisionReason: null,
        createdAt: DateTime(2026, 1, 1),
        decidedAt: null,
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(mapper.toDomain(row).linkedTicketIds, isEmpty);
    });

    test('a non-list JSON value decodes to an empty list', () {
      final row = ApprovalsTableData(
        id: 'ap-1',
        workspaceId: 'w-1',
        title: 't',
        description: null,
        kind: 'merge',
        status: 'pending',
        requestedByActorType: 'agent',
        requestedById: null,
        linkedTicketIds: '{"foo":"bar"}',
        linkedEntityType: null,
        linkedEntityId: null,
        decidedByActorType: null,
        decidedById: null,
        decisionReason: null,
        createdAt: DateTime(2026, 1, 1),
        decidedAt: null,
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(mapper.toDomain(row).linkedTicketIds, isEmpty);
    });
  });

  group('DaoApprovalRepository upsert + read round-trip', () {
    test('getById returns null when absent', () async {
      expect(await repo.getById('w-1', 'missing'), isNull);
    });

    test('upsert then getById round-trips all fields', () async {
      await repo.upsert(
        approval(
          id: 'ap-1',
          title: 'merge it',
          description: 'ships the feature',
          kind: ApprovalKind.release,
          status: ApprovalStatus.approved,
          requestedById: 'a-9',
          linkedTicketIds: ['t-1', 't-2'],
          linkedEntityType: 'pull_request',
          linkedEntityId: 'pr-1',
          decidedByActorType: 'user',
          decidedById: 'u-1',
          decisionReason: 'LGTM',
          decidedAt: DateTime(2026, 1, 2),
        ),
      );
      final loaded = await repo.getById('w-1', 'ap-1');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'merge it');
      expect(loaded.kind, ApprovalKind.release);
      expect(loaded.status, ApprovalStatus.approved);
      expect(loaded.linkedTicketIds, ['t-1', 't-2']);
      expect(loaded.decisionReason, 'LGTM');
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await repo.upsert(approval(id: 'ap-1', title: 'first'));
      await repo.upsert(approval(id: 'ap-1', title: 'second'));
      expect((await repo.getById('w-1', 'ap-1'))?.title, 'second');
    });
  });

  group('DaoApprovalRepository workspace isolation', () {
    test('watchByWorkspace emits only the workspace rows', () async {
      await repo.upsert(approval(id: 'ap-1', workspaceId: 'w-1'));
      await repo.upsert(approval(id: 'ap-2', workspaceId: 'w-2'));
      final rows = await repo.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'ap-1');
    });

    test('watchByStatus filters by status within the workspace', () async {
      await repo.upsert(approval(id: 'ap-1', status: ApprovalStatus.pending));
      await repo.upsert(approval(id: 'ap-2', status: ApprovalStatus.approved));
      await repo.upsert(
        approval(
          id: 'ap-3',
          workspaceId: 'w-2',
          status: ApprovalStatus.pending,
        ),
      );
      final rows = await repo.watchByStatus('w-1', 'pending').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'ap-1');
    });

    test('getById is workspace-scoped', () async {
      await repo.upsert(approval(id: 'ap-1', workspaceId: 'w-1'));
      expect(await repo.getById('w-2', 'ap-1'), isNull);
    });

    test('delete is workspace-scoped', () async {
      await repo.upsert(approval(id: 'ap-1', workspaceId: 'w-1'));
      await repo.delete('w-2', 'ap-1');
      expect(await repo.getById('w-1', 'ap-1'), isNotNull);
      await repo.delete('w-1', 'ap-1');
      expect(await repo.getById('w-1', 'ap-1'), isNull);
    });
  });

  group('DaoApprovalRepository comments', () {
    test(
      'addComment + getComments round-trips and is workspace-scoped',
      () async {
        await repo.upsert(approval(id: 'ap-1'));
        await repo.addComment(
          ApprovalComment(
            id: 'cm-1',
            approvalId: 'ap-1',
            workspaceId: 'w-1',
            authorType: 'user',
            authorId: 'u-1',
            body: 'LGTM',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        final comments = await repo.getComments('w-1', 'ap-1');
        expect(comments, hasLength(1));
        expect(comments.first.body, 'LGTM');
        // Foreign workspace cannot see the thread.
        expect(await repo.getComments('w-2', 'ap-1'), isEmpty);
      },
    );

    test('watchComments emits only the workspace thread', () async {
      await repo.upsert(approval(id: 'ap-1'));
      await repo.addComment(
        ApprovalComment(
          id: 'cm-1',
          approvalId: 'ap-1',
          workspaceId: 'w-1',
          body: 'hi',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final comments = await repo.watchComments('w-1', 'ap-1').first;
      expect(comments, hasLength(1));
    });
  });
}
