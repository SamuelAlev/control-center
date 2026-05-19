import 'dart:convert';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/ticketing/data/mappers/ticket_mapper.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const mapper = TicketMapper();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts a ticket with all fields populated and returns the generated row.
  Future<TicketsTableData> insertTicket({
    String id = 'ticket-1',
    String workspaceId = 'ws-1',
    String provider = 'local',
    String? externalKey,
    String? url,
    String title = 'Test Ticket',
    String? description,
    int priority = 0,
    String labels = '[]',
    String status = 'open',
    String? rawStatus,
    String? parentTicketId,
    String? projectId,
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? channelId,
    String mode = 'chat',
    String? pipelineRunId,
    String? pipelineStepId,
    String? expectedOutputSchema,
    String? outputJson,
    String? errorMessage,
    String linkedPrIds = '[]',
    String metadata = '{}',
    int version = 0,
    String originKind = 'manual',
    String? checkoutRunId,
    DateTime? executionLockedAt,
    String? checkoutAgentId,
    String? executionPolicyJson,
    String? executionStateJson,
    String? recoveryActionsJson,
  }) async {
    // Create pipeline run if specified and doesn't already exist.
    if (pipelineRunId != null) {
      final existingRun = await db.pipelineDao.getRun(pipelineRunId);
      if (existingRun == null) {
        await db.pipelineDao.insertRun(
          PipelineRunsTableCompanion.insert(
            id: pipelineRunId,
            templateId: 'tpl-$pipelineRunId',
            workspaceId: workspaceId,
          ),
        );
      }
    }
    // Create parent ticket if specified and doesn't already exist.
    if (parentTicketId != null) {
      final existing = await db.ticketDao.getById(parentTicketId);
      if (existing == null) {
        await db.ticketDao.insert(
          TicketsTableCompanion.insert(
            id: parentTicketId,
            workspaceId: workspaceId,
            title: 'Parent $parentTicketId',
          ),
        );
      }
    }
    await db.ticketDao.insert(
      TicketsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        title: title,
        provider: Value(provider),
        externalKey: Value.absentIfNull(externalKey),
        url: Value.absentIfNull(url),
        description: Value.absentIfNull(description),
        priority: Value(priority),
        labels: Value(labels),
        status: Value(status),
        rawStatus: Value.absentIfNull(rawStatus),
        parentTicketId: Value.absentIfNull(parentTicketId),
        projectId: Value.absentIfNull(projectId),
        assignedAgentId: Value.absentIfNull(assignedAgentId),
        assignedTeamId: Value.absentIfNull(assignedTeamId),
        delegatedByAgentId: Value.absentIfNull(delegatedByAgentId),
        channelId: Value.absentIfNull(channelId),
        mode: Value(mode),
        pipelineRunId: Value.absentIfNull(pipelineRunId),
        pipelineStepId: Value.absentIfNull(pipelineStepId),
        expectedOutputSchema: Value.absentIfNull(expectedOutputSchema),
        outputJson: Value.absentIfNull(outputJson),
        errorMessage: Value.absentIfNull(errorMessage),
        linkedPrIds: Value(linkedPrIds),
        metadata: Value(metadata),
        version: Value(version),
        originKind: Value(originKind),
        checkoutRunId: Value.absentIfNull(checkoutRunId),
        executionLockedAt: Value.absentIfNull(executionLockedAt),
        checkoutAgentId: Value.absentIfNull(checkoutAgentId),
        executionPolicyJson: Value.absentIfNull(executionPolicyJson),
        executionStateJson: Value.absentIfNull(executionStateJson),
        recoveryActionsJson: Value.absentIfNull(recoveryActionsJson),
      ),
    );
    return (await db.ticketDao.getById(id))!;
  }

  /// Creates a fully-populated Ticket domain entity for testing.
  Ticket createTestTicket({
    String id = 'ticket-test',
    String workspaceId = 'ws-1',
  }) {
    return Ticket(
      id: id,
      workspaceId: workspaceId,
      provider: TicketProvider.linear,
      externalKey: 'LIN-42',
      url: 'https://linear.app/issue/LIN-42',
      title: 'Implement auth',
      description: 'Build the login flow',
      priority: TicketPriority.high,
      labels: const ['backend', 'auth'],
      status: TicketStatus.inProgress,
      rawStatus: 'In Progress',
      parentTicketId: 'parent-1',
      projectId: 'proj-1',
      assignedAgentId: 'agent-abc',
      assignedTeamId: 'team-core',
      delegatedByAgentId: 'agent-delegator',
      channelId: 'channel-1',
      mode: ConversationMode.chat,
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
      expectedOutputSchema: const {'type': 'object', 'properties': {}},
      outputJson: const {'result': 'success', 'code': 200},
      errorMessage: null,
      linkedPrIds: const ['PR-node-1', 'PR-node-2'],
      metadata: const {'source': 'api', 'synced': true},
      version: 3,
      originKind: TicketOriginKind.externalSync,
      checkoutRunId: 'run-42',
      executionLockedAt: DateTime(2025, 6, 1, 12, 0),
      checkoutAgentId: 'agent-checkout',
      executionPolicyJson: '{"stages":[]}',
      executionStateJson: '{"current":"stage1"}',
      recoveryActionsJson: '[{"action":"retry"}]',
      createdAt: DateTime(2025, 1, 1),
      startedAt: DateTime(2025, 1, 2),
      blockedAt: null,
      cancelledAt: null,
      completedAt: null,
      finishedAt: null,
      updatedAt: DateTime(2025, 6, 1),
      collaborators: [
        TicketCollaborator(
          id: 'collab-1',
          ticketId: id,
          agentId: 'agent-abc',
          role: TicketCollaboratorRole.assignee,
          joinedAt: DateTime(2025, 1, 1),
        ),
      ],
    );
  }

  group('TicketMapper', () {
    // --- fromRow ---

    test('fromRow maps all fields correctly with defaults', timeout: const Timeout.factor(2),
        () async {
      final row = await insertTicket();

      final ticket = mapper.fromRow(row);

      expect(ticket.id, 'ticket-1');
      expect(ticket.workspaceId, 'ws-1');
      expect(ticket.provider, TicketProvider.local);
      expect(ticket.externalKey, isNull);
      expect(ticket.url, isNull);
      expect(ticket.title, 'Test Ticket');
      expect(ticket.description, isNull);
      expect(ticket.priority, TicketPriority.none);
      expect(ticket.labels, isEmpty);
      expect(ticket.status, TicketStatus.open);
      expect(ticket.rawStatus, isNull);
      expect(ticket.parentTicketId, isNull);
      expect(ticket.projectId, isNull);
      expect(ticket.assignedAgentId, isNull);
      expect(ticket.assignedTeamId, isNull);
      expect(ticket.delegatedByAgentId, isNull);
      expect(ticket.channelId, isNull);
      expect(ticket.mode, ConversationMode.chat);
      expect(ticket.pipelineRunId, isNull);
      expect(ticket.pipelineStepId, isNull);
      expect(ticket.expectedOutputSchema, isNull);
      expect(ticket.outputJson, isNull);
      expect(ticket.errorMessage, isNull);
      expect(ticket.linkedPrIds, isEmpty);
      expect(ticket.metadata, isEmpty);
      expect(ticket.version, 0);
      expect(ticket.originKind, TicketOriginKind.manual);
      expect(ticket.checkoutRunId, isNull);
      expect(ticket.executionLockedAt, isNull);
      expect(ticket.checkoutAgentId, isNull);
      expect(ticket.executionPolicyJson, isNull);
      expect(ticket.executionStateJson, isNull);
      expect(ticket.recoveryActionsJson, isNull);
      expect(ticket.createdAt, isA<DateTime>());
      expect(ticket.startedAt, isNull);
      expect(ticket.blockedAt, isNull);
      expect(ticket.cancelledAt, isNull);
      expect(ticket.completedAt, isNull);
      expect(ticket.finishedAt, isNull);
      expect(ticket.updatedAt, isA<DateTime>());
      expect(ticket.collaborators, isEmpty);
    });

    test('fromRow maps all nullable fields when populated', timeout: const Timeout.factor(2),
        () async {
      final lockedAt = DateTime(2025, 6, 1, 12, 0);
      final row = await insertTicket(
        provider: 'linear',
        externalKey: 'LIN-42',
        url: 'https://linear.app/issue/LIN-42',
        description: 'Build auth flow',
        priority: 2, // high
        labels: jsonEncode(['backend', 'auth']),
        status: 'inProgress',
        rawStatus: 'In Progress',
        parentTicketId: 'parent-ticket',
        projectId: 'proj-1',
        assignedAgentId: 'agent-abc',
        assignedTeamId: 'team-core',
        delegatedByAgentId: 'agent-delegator',
        channelId: 'channel-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
        expectedOutputSchema: jsonEncode({'type': 'object'}),
        outputJson: jsonEncode({'result': 'ok'}),
        errorMessage: 'Something broke',
        linkedPrIds: jsonEncode(['PR-1', 'PR-2']),
        metadata: jsonEncode({'key': 'value'}),
        version: 5,
        originKind: 'externalSync',
        checkoutRunId: 'checkout-run',
        executionLockedAt: lockedAt,
        checkoutAgentId: 'checkout-agent',
        executionPolicyJson: '{"policy":true}',
        executionStateJson: '{"state":"running"}',
        recoveryActionsJson: '[{"action":"retry"}]',
      );

      final ticket = mapper.fromRow(row);

      expect(ticket.provider, TicketProvider.linear);
      expect(ticket.externalKey, 'LIN-42');
      expect(ticket.url, 'https://linear.app/issue/LIN-42');
      expect(ticket.description, 'Build auth flow');
      expect(ticket.priority, TicketPriority.high);
      expect(ticket.labels, ['backend', 'auth']);
      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.rawStatus, 'In Progress');
      expect(ticket.parentTicketId, 'parent-ticket');
      expect(ticket.projectId, 'proj-1');
      expect(ticket.assignedAgentId, 'agent-abc');
      expect(ticket.assignedTeamId, 'team-core');
      expect(ticket.delegatedByAgentId, 'agent-delegator');
      expect(ticket.channelId, 'channel-1');
      expect(ticket.pipelineRunId, 'run-1');
      expect(ticket.pipelineStepId, 'step-1');
      expect(ticket.expectedOutputSchema, {'type': 'object'});
      expect(ticket.outputJson, {'result': 'ok'});
      expect(ticket.errorMessage, 'Something broke');
      expect(ticket.linkedPrIds, ['PR-1', 'PR-2']);
      expect(ticket.metadata, {'key': 'value'});
      expect(ticket.version, 5);
      expect(ticket.originKind, TicketOriginKind.externalSync);
      expect(ticket.checkoutRunId, 'checkout-run');
      expect(ticket.executionLockedAt, lockedAt);
      expect(ticket.checkoutAgentId, 'checkout-agent');
      expect(ticket.executionPolicyJson, '{"policy":true}');
      expect(ticket.executionStateJson, '{"state":"running"}');
      expect(ticket.recoveryActionsJson, '[{"action":"retry"}]');
    });

    test('fromRow hydrates collaborators', timeout: const Timeout.factor(2),
        () async {
      final row = await insertTicket();

      final collaborators = [
        TicketCollaborator(
          id: 'c1',
          ticketId: 'ticket-1',
          agentId: 'agent-1',
          role: TicketCollaboratorRole.assignee,
          joinedAt: DateTime(2025),
        ),
        TicketCollaborator(
          id: 'c2',
          ticketId: 'ticket-1',
          agentId: 'user',
          role: TicketCollaboratorRole.reviewer,
          joinedAt: DateTime(2025),
        ),
      ];

      final ticket = mapper.fromRow(row, collaborators: collaborators);

      expect(ticket.collaborators, hasLength(2));
      expect(ticket.collaborators[0].id, 'c1');
      expect(ticket.collaborators[1].id, 'c2');
    });

    test('fromRow defaults empty list for empty labels JSON', timeout: const Timeout.factor(2),
        () async {
      await insertTicket(labels: '');

      // The DB will store '' but Drift will return whatever was stored.
      // The mapper's _decodeStringList handles empty strings.
      // However, since we go through DAO insert, the default '[]' was used.
      // Let's test via a custom insert.
      await db.customStatement(
        'INSERT INTO tickets (id, workspace_id, title, labels, linked_pr_ids, metadata, mode, status, provider, priority, version, origin_kind) '
        "VALUES ('ticket-empty-labels', 'ws-1', 'Empty Labels', '', '[]', '{}', 'chat', 'open', 'local', 0, 0, 'manual')",
      );
      final rawRow =
          (await db.ticketDao.getById('ticket-empty-labels'))!;

      final ticket = mapper.fromRow(rawRow);

      expect(ticket.labels, isEmpty);
    });

    // --- toCompanion ---

    test('toCompanion maps all fields', timeout: const Timeout.factor(2), () async {
      final ticket = createTestTicket();

      final companion = mapper.toCompanion(ticket);

      expect(companion.id.value, ticket.id);
      expect(companion.workspaceId.value, ticket.workspaceId);
      expect(companion.provider.value, 'linear');
      expect(companion.externalKey.value, 'LIN-42');
      expect(companion.url.value, 'https://linear.app/issue/LIN-42');
      expect(companion.title.value, 'Implement auth');
      expect(companion.description.value, 'Build the login flow');
      expect(companion.priority.value, TicketPriority.high.toStorageInt());
      expect(companion.labels.value, jsonEncode(['backend', 'auth']));
      expect(companion.status.value, 'inProgress');
      expect(companion.rawStatus.value, 'In Progress');
      expect(companion.parentTicketId.value, 'parent-1');
      expect(companion.projectId.value, 'proj-1');
      expect(companion.assignedAgentId.value, 'agent-abc');
      expect(companion.assignedTeamId.value, 'team-core');
      expect(companion.delegatedByAgentId.value, 'agent-delegator');
      expect(companion.channelId.value, 'channel-1');
      expect(companion.mode.value, 'chat');
      expect(companion.pipelineRunId.value, 'run-1');
      expect(companion.pipelineStepId.value, 'step-1');
      expect(companion.expectedOutputSchema.value,
          jsonEncode({'type': 'object', 'properties': {}}));
      expect(
          companion.outputJson.value, jsonEncode({'result': 'success', 'code': 200}));
      expect(companion.errorMessage.value, isNull);
      expect(companion.linkedPrIds.value, jsonEncode(['PR-node-1', 'PR-node-2']));
      expect(companion.metadata.value,
          jsonEncode({'source': 'api', 'synced': true}));
      expect(companion.version.value, 3);
      expect(companion.originKind.value, 'externalSync');
      expect(companion.checkoutRunId.value, 'run-42');
      expect(companion.executionLockedAt.value, DateTime(2025, 6, 1, 12, 0));
      expect(companion.checkoutAgentId.value, 'agent-checkout');
      expect(companion.executionPolicyJson.value, '{"stages":[]}');
      expect(companion.executionStateJson.value, '{"current":"stage1"}');
      expect(companion.recoveryActionsJson.value, '[{"action":"retry"}]');
      expect(companion.createdAt.value, ticket.createdAt);
      expect(companion.updatedAt.value, ticket.updatedAt);
    });

    // --- toMirrorCompanion ---

    test('toMirrorCompanion writes only mirror columns', timeout: const Timeout.factor(2),
        () async {
      final ticket = createTestTicket();

      final companion = mapper.toMirrorCompanion(ticket);

      // Mirror columns should be set
      expect(companion.provider.value, 'linear');
      expect(companion.externalKey.value, 'LIN-42');
      expect(companion.url.value, 'https://linear.app/issue/LIN-42');
      expect(companion.title.value, 'Implement auth');
      expect(companion.description.value, 'Build the login flow');
      expect(companion.priority.value, TicketPriority.high.toStorageInt());
      expect(companion.labels.value, jsonEncode(['backend', 'auth']));
      expect(companion.status.value, 'inProgress');
      expect(companion.rawStatus.value, 'In Progress');
      expect(companion.updatedAt.value, ticket.updatedAt);

      // Overlay columns should NOT be set (Value.absent)
      expect(companion.id.present, isFalse);
      expect(companion.workspaceId.present, isFalse);
      expect(companion.parentTicketId.present, isFalse);
      expect(companion.projectId.present, isFalse);
      expect(companion.assignedAgentId.present, isFalse);
      expect(companion.assignedTeamId.present, isFalse);
      expect(companion.delegatedByAgentId.present, isFalse);
      expect(companion.channelId.present, isFalse);
      expect(companion.mode.present, isFalse);
      expect(companion.pipelineRunId.present, isFalse);
      expect(companion.pipelineStepId.present, isFalse);
      expect(companion.expectedOutputSchema.present, isFalse);
      expect(companion.outputJson.present, isFalse);
      expect(companion.errorMessage.present, isFalse);
      expect(companion.linkedPrIds.present, isFalse);
      expect(companion.metadata.present, isFalse);
      expect(companion.version.present, isFalse);
      expect(companion.originKind.present, isFalse);
      expect(companion.checkoutRunId.present, isFalse);
      expect(companion.executionLockedAt.present, isFalse);
      expect(companion.checkoutAgentId.present, isFalse);
      expect(companion.executionPolicyJson.present, isFalse);
      expect(companion.executionStateJson.present, isFalse);
      expect(companion.recoveryActionsJson.present, isFalse);
      expect(companion.createdAt.present, isFalse);
      expect(companion.startedAt.present, isFalse);
      expect(companion.blockedAt.present, isFalse);
      expect(companion.cancelledAt.present, isFalse);
      expect(companion.completedAt.present, isFalse);
      expect(companion.finishedAt.present, isFalse);
    });

    // --- toCompanion round-trip through DB ---

    test('toCompanion round-trips through DB and fromRow', timeout: const Timeout.factor(2),
        () async {
      // Create parent ticket for FK
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 'parent-1',
          workspaceId: 'ws-1',
          title: 'Parent Ticket',
        ),
      );
      // Create pipeline run for FK
      await db.pipelineDao.insertRun(
        PipelineRunsTableCompanion.insert(
          id: 'run-1',
          templateId: 'tpl-1',
          workspaceId: 'ws-1',
        ),
      );

      final original = createTestTicket();
      final companion = mapper.toCompanion(original);

      await db.ticketDao.insert(companion);
      final row = (await db.ticketDao.getById(original.id))!;
      final roundTripped = mapper.fromRow(row);

      expect(roundTripped.id, original.id);
      expect(roundTripped.workspaceId, original.workspaceId);
      expect(roundTripped.provider, original.provider);
      expect(roundTripped.externalKey, original.externalKey);
      expect(roundTripped.url, original.url);
      expect(roundTripped.title, original.title);
      expect(roundTripped.description, original.description);
      expect(roundTripped.priority, original.priority);
      expect(roundTripped.labels, original.labels);
      expect(roundTripped.status, original.status);
      expect(roundTripped.rawStatus, original.rawStatus);
      expect(roundTripped.parentTicketId, original.parentTicketId);
      expect(roundTripped.projectId, original.projectId);
      expect(roundTripped.assignedAgentId, original.assignedAgentId);
      expect(roundTripped.assignedTeamId, original.assignedTeamId);
      expect(roundTripped.delegatedByAgentId, original.delegatedByAgentId);
      expect(roundTripped.channelId, original.channelId);
      expect(roundTripped.mode, original.mode);
      expect(roundTripped.pipelineRunId, original.pipelineRunId);
      expect(roundTripped.pipelineStepId, original.pipelineStepId);
      expect(roundTripped.expectedOutputSchema, original.expectedOutputSchema);
      expect(roundTripped.outputJson, original.outputJson);
      expect(roundTripped.errorMessage, original.errorMessage);
      expect(roundTripped.linkedPrIds, original.linkedPrIds);
      expect(roundTripped.metadata, original.metadata);
      expect(roundTripped.version, original.version);
      expect(roundTripped.originKind, original.originKind);
      expect(roundTripped.checkoutRunId, original.checkoutRunId);
      expect(roundTripped.executionLockedAt, original.executionLockedAt);
      expect(roundTripped.checkoutAgentId, original.checkoutAgentId);
      expect(roundTripped.executionPolicyJson, original.executionPolicyJson);
      expect(roundTripped.executionStateJson, original.executionStateJson);
      expect(roundTripped.recoveryActionsJson, original.recoveryActionsJson);
      expect(roundTripped.startedAt, original.startedAt);
    });

    // --- Collaborator mapping ---

    test('collaboratorToCompanion maps all fields', timeout: const Timeout.factor(2),
        () async {
      final joinedAt = DateTime(2025, 3, 15);
      final collab = TicketCollaborator(
        id: 'collab-1',
        ticketId: 'ticket-1',
        agentId: 'agent-abc',
        role: TicketCollaboratorRole.reviewer,
        joinedAt: joinedAt,
      );

      final companion = mapper.collaboratorToCompanion(collab);

      expect(companion.id.value, 'collab-1');
      expect(companion.ticketId.value, 'ticket-1');
      expect(companion.agentId.value, 'agent-abc');
      expect(companion.role.value, 'reviewer');
      expect(companion.joinedAt.value, joinedAt);
    });

    test('collaboratorFromRow maps all fields', timeout: const Timeout.factor(2),
        () async {
      // Insert a ticket + collaborator to get a real Data object.
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 'ticket-collab',
          workspaceId: 'ws-1',
          title: 'Collab Test',
        ),
      );
      await db.ticketDao.addCollaborator(
        TicketCollaboratorsTableCompanion.insert(
          id: 'collab-row',
          ticketId: 'ticket-collab',
          agentId: 'user',
          role: const Value('assignee'),
        ),
      );
      final rows =
          await db.ticketDao.getCollaborators('ticket-collab');
      final row = rows.first;

      final collab = mapper.collaboratorFromRow(row);

      expect(collab.id, 'collab-row');
      expect(collab.ticketId, 'ticket-collab');
      expect(collab.agentId, 'user');
      expect(collab.role, TicketCollaboratorRole.assignee);
      expect(collab.joinedAt, isA<DateTime>());
    });

    test('collaborator round-trip through DB', timeout: const Timeout.factor(2),
        () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 'ticket-crt',
          workspaceId: 'ws-1',
          title: 'Round Trip',
        ),
      );
      final original = TicketCollaborator(
        id: 'collab-rt',
        ticketId: 'ticket-crt',
        agentId: 'agent-xyz',
        role: TicketCollaboratorRole.collaborator,
        joinedAt: DateTime(2025, 5, 20, 10, 30),
      );

      await db.ticketDao.addCollaborator(
        mapper.collaboratorToCompanion(original),
      );
      final rows =
          await db.ticketDao.getCollaborators('ticket-crt');
      final roundTripped = mapper.collaboratorFromRow(rows.first);

      expect(roundTripped.id, original.id);
      expect(roundTripped.ticketId, original.ticketId);
      expect(roundTripped.agentId, original.agentId);
      expect(roundTripped.role, original.role);
    });

    // --- Provider enum mapping ---

    test('fromRow maps all TicketProvider values', timeout: const Timeout.factor(2),
        () async {
      for (final prov in TicketProvider.values) {
        final row = await insertTicket(
          id: 'ticket-prov-${prov.name}',
          provider: prov.toStorageString(),
        );
        final ticket = mapper.fromRow(row);
        expect(ticket.provider, prov,
            reason: 'Failed for provider ${prov.name}');
      }
    });

    // --- Priority mapping ---

    test('fromRow maps all TicketPriority values', timeout: const Timeout.factor(2),
        () async {
      for (final prio in TicketPriority.values) {
        final row = await insertTicket(
          id: 'ticket-prio-${prio.name}',
          priority: prio.toStorageInt(),
        );
        final ticket = mapper.fromRow(row);
        expect(ticket.priority, prio,
            reason: 'Failed for priority ${prio.name}');
      }
    });

    // --- Status mapping ---

    test('fromRow maps all TicketStatus values', timeout: const Timeout.factor(2),
        () async {
      for (final st in TicketStatus.values) {
        final row = await insertTicket(
          id: 'ticket-status-${st.name}',
          status: st.toStorageString(),
        );
        final ticket = mapper.fromRow(row);
        expect(ticket.status, st,
            reason: 'Failed for status ${st.name}');
      }
    });

    // --- ConversationMode mapping ---

    test('fromRow maps all ConversationMode values', timeout: const Timeout.factor(2),
        () async {
      for (final mode in ConversationMode.values) {
        final row = await insertTicket(
          id: 'ticket-mode-${mode.name}',
          mode: mode.toDbValue(),
        );
        final ticket = mapper.fromRow(row);
        expect(ticket.mode, mode,
            reason: 'Failed for mode ${mode.name}');
      }
    });

    // --- OriginKind mapping ---

    test('fromRow maps all TicketOriginKind values', timeout: const Timeout.factor(2),
        () async {
      for (final kind in TicketOriginKind.values) {
        final row = await insertTicket(
          id: 'ticket-origin-${kind.name}',
          originKind: kind.name,
        );
        final ticket = mapper.fromRow(row);
        expect(ticket.originKind, kind,
            reason: 'Failed for originKind ${kind.name}');
      }
    });

    test('fromRow defaults unknown originKind to manual', timeout: const Timeout.factor(2),
        () async {
      final row = await insertTicket(originKind: 'unknown_kind');

      final ticket = mapper.fromRow(row);

      expect(ticket.originKind, TicketOriginKind.manual);
    });

    // --- JSON field edge cases ---

    test('fromRow handles empty labels string', timeout: const Timeout.factor(2),
        () async {
      // Bypass DAO to store empty string directly
      await db.customStatement(
        'INSERT INTO tickets (id, workspace_id, title, labels, linked_pr_ids, metadata, mode, status, provider, priority, version, origin_kind) '
        "VALUES ('ticket-el', 'ws-1', 'Empty', '', '[]', '{}', 'chat', 'open', 'local', 0, 0, 'manual')",
      );
      final row = (await db.ticketDao.getById('ticket-el'))!;

      final ticket = mapper.fromRow(row);

      expect(ticket.labels, isEmpty);
    });

    test('fromRow handles empty metadata string', timeout: const Timeout.factor(2),
        () async {
      await db.customStatement(
        'INSERT INTO tickets (id, workspace_id, title, labels, linked_pr_ids, metadata, mode, status, provider, priority, version, origin_kind) '
        "VALUES ('ticket-em', 'ws-1', 'Empty', '[]', '[]', '', 'chat', 'open', 'local', 0, 0, 'manual')",
      );
      final row = (await db.ticketDao.getById('ticket-em'))!;

      final ticket = mapper.fromRow(row);

      expect(ticket.metadata, isEmpty);
    });

    test('toCompanion handles null JSON fields', timeout: const Timeout.factor(2),
        () async {
      final ticket = Ticket(
        id: 'ticket-nulls',
        workspaceId: 'ws-1',
        title: 'All Nulls',
        expectedOutputSchema: null,
        outputJson: null,
        status: TicketStatus.open,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final companion = mapper.toCompanion(ticket);

      expect(companion.expectedOutputSchema.value, isNull);
      expect(companion.outputJson.value, isNull);
    });

    test('toCompanion JSON-encodes complex maps', timeout: const Timeout.factor(2),
        () async {
      final ticket = Ticket(
        id: 'ticket-json',
        workspaceId: 'ws-1',
        title: 'JSON Test',
        metadata: const {'nested': {'key': [1, 2, 3]}},
        status: TicketStatus.open,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final companion = mapper.toCompanion(ticket);

      final decoded =
          jsonDecode(companion.metadata.value) as Map<String, dynamic>;
      expect(decoded['nested'], isA<Map>());
      expect((decoded['nested'] as Map)['key'], [1, 2, 3]);
    });
  });
}
