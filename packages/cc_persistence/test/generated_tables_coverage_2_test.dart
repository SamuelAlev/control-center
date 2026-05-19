import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Second batch of generated-table coverage: drives the companion/data/mapper
/// code for the remaining large tables (tickets, meetings, pipeline runs,
/// orchestrations, code graph, space surfaces, memory policies, plan/playbook
/// documents) into coverage. Mirrors `generated_tables_coverage_test.dart` —
/// each table's generated code runs when a row is inserted and read back.
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async => db.close());

  group('Ticketing generated tables', () {
    test('tickets round-trip', () async {
      await db
          .into(db.ticketsTable)
          .insert(
            TicketsTableCompanion.insert(
              id: 't-1',
              workspaceId: 'ws',
              title: 'Fix bug',
            ),
          );
      final row = await (db.select(
        db.ticketsTable,
      )..where((t) => t.id.equals('t-1'))).getSingle();
      expect(row.title, 'Fix bug');
    });
  });

  group('Meeting generated tables', () {
    test('meetings round-trip', () async {
      await db
          .into(db.meetingsTable)
          .insert(
            MeetingsTableCompanion.insert(
              id: 'mtg-1',
              workspaceId: 'ws',
              title: 'standup',
            ),
          );
      final row = await (db.select(
        db.meetingsTable,
      )..where((t) => t.id.equals('mtg-1'))).getSingle();
      expect(row.title, 'standup');
    });
  });

  group('Pipeline generated tables', () {
    test('pipeline runs round-trip', () async {
      await db
          .into(db.pipelineTemplatesTable)
          .insert(
            PipelineTemplatesTableCompanion.insert(
              id: 'tpl-1',
              workspaceId: 'ws',
              name: 'template',
            ),
          );
      await db
          .into(db.pipelineRunsTable)
          .insert(
            PipelineRunsTableCompanion.insert(
              id: 'pr-1',
              templateId: 'tpl-1',
              workspaceId: 'ws',
            ),
          );
      final row = await (db.select(
        db.pipelineRunsTable,
      )..where((t) => t.id.equals('pr-1'))).getSingle();
      expect(row.templateId, 'tpl-1');
    });
  });

  group('Orchestration generated tables', () {
    test('orchestrations + revisions round-trip', () async {
      await db
          .into(db.orchestrationsTable)
          .insert(
            OrchestrationsTableCompanion.insert(
              id: 'orc-1',
              workspaceId: 'ws',
              proposalJson: '{}',
            ),
          );
      final orc = await (db.select(
        db.orchestrationsTable,
      )..where((t) => t.id.equals('orc-1'))).getSingle();
      expect(orc.proposalJson, '{}');

      await db
          .into(db.orchestrationRevisionsTable)
          .insert(
            OrchestrationRevisionsTableCompanion.insert(
              id: 'rev-1',
              workspaceId: 'ws',
              orchestrationId: 'orc-1',
              revision: 1,
              proposalJson: '{}',
              authoredBy: 'a-1',
            ),
          );
      final rev = await (db.select(
        db.orchestrationRevisionsTable,
      )..where((t) => t.id.equals('rev-1'))).getSingle();
      expect(rev.orchestrationId, 'orc-1');
      expect(rev.revision, 1);
    });
  });

  group('Code-graph generated tables', () {
    test('code symbols + edges + files round-trip', () async {
      await db
          .into(db.reposTable)
          .insert(
            ReposTableCompanion.insert(
              id: 'repo-1',
              name: 'repo-1',
              path: '/repo-1',
            ),
          );
      await db
          .into(db.codeSymbolsTable)
          .insert(
            CodeSymbolsTableCompanion.insert(
              id: 'sym-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              kind: 'function',
              name: 'bar',
              qualifiedName: 'lib.foo.bar',
              filePath: 'lib/foo.dart',
              language: 'dart',
              startLine: 1,
              endLine: 2,
            ),
          );
      await db
          .into(db.codeEdgesTable)
          .insert(
            CodeEdgesTableCompanion.insert(
              id: 'edge-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              sourceSymbolId: 'sym-1',
              kind: 'calls',
            ),
          );
      await db
          .into(db.codeFilesTable)
          .insert(
            CodeFilesTableCompanion.insert(
              id: 'cf-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              path: 'lib/foo.dart',
              contentHash: 'abc123',
            ),
          );
      final edge = await (db.select(
        db.codeEdgesTable,
      )..where((t) => t.id.equals('edge-1'))).getSingle();
      expect(edge.kind, 'calls');
      final file = await (db.select(
        db.codeFilesTable,
      )..where((t) => t.id.equals('cf-1'))).getSingle();
      expect(file.path, 'lib/foo.dart');
    });
  });

  group('Space-surface generated tables', () {
    test('space messages + reactions + notes round-trip', () async {
      await db
          .into(db.spacesTable)
          .insert(SpacesTableCompanion.insert(id: 'c-1', name: 'c-1'));
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion.insert(id: 'c-1', spaceId: 'c-1'),
          );
      await db
          .into(db.conversationMessagesTable)
          .insert(
            ConversationMessagesTableCompanion.insert(
              id: 'msg-1',
              spaceId: 'c-1',
              conversationId: 'c-1',
              senderId: 'a-1',
              senderType: 'agent',
              content: 'hello',
            ),
          );
      await db
          .into(db.messageReactionsTable)
          .insert(
            MessageReactionsTableCompanion.insert(
              id: 'rxn-1',
              workspaceId: 'ws',
              spaceId: 'c-1',
              messageId: 'msg-1',
              principalId: 'u-1',
              principalType: 'user',
              emoji: '+1',
            ),
          );
      await db
          .into(db.spaceNotesTable)
          .insert(
            SpaceNotesTableCompanion.insert(
              id: 'note-1',
              workspaceId: 'ws',
              spaceId: 'c-1',
              updatedByPrincipal: 'u-1',
            ),
          );
      final msg = await (db.select(
        db.conversationMessagesTable,
      )..where((t) => t.id.equals('msg-1'))).getSingle();
      expect(msg.content, 'hello');
      final rxn = await (db.select(
        db.messageReactionsTable,
      )..where((t) => t.id.equals('rxn-1'))).getSingle();
      expect(rxn.emoji, '+1');
      final note = await (db.select(
        db.spaceNotesTable,
      )..where((t) => t.id.equals('note-1'))).getSingle();
      expect(note.spaceId, 'c-1');
    });

    test('space autonomy round-trip', () async {
      await db
          .into(db.spacesTable)
          .insert(SpacesTableCompanion.insert(id: 'c-2', name: 'c-2'));
      await db
          .into(db.spaceAutonomyTable)
          .insert(
            SpaceAutonomyTableCompanion.insert(
              id: 'ca-1',
              workspaceId: 'ws',
              spaceId: 'c-2',
              agentId: 'a-1',
              autonomyLevel: 'full',
            ),
          );
      final row = await (db.select(
        db.spaceAutonomyTable,
      )..where((t) => t.id.equals('ca-1'))).getSingle();
      expect(row.autonomyLevel, 'full');
    });
  });

  group('Memory generated tables', () {
    test('memory policies round-trip', () async {
      await db
          .into(db.memoryPoliciesTable)
          .insert(
            MemoryPoliciesTableCompanion.insert(
              id: 'mp-1',
              workspaceId: 'ws',
              domain: 'general',
              rule: 'allow',
            ),
          );
      final row = await (db.select(
        db.memoryPoliciesTable,
      )..where((t) => t.id.equals('mp-1'))).getSingle();
      expect(row.rule, 'allow');
    });
  });

  group('Plan / playbook generated tables', () {
    test('plan documents + playbooks round-trip', () async {
      await db
          .into(db.planDocumentsTable)
          .insert(
            PlanDocumentsTableCompanion.insert(
              id: 'pd-1',
              workspaceId: 'ws',
              conversationId: 'c-1',
              agentId: 'a-1',
              planJson: '{}',
            ),
          );
      await db
          .into(db.playbooksTable)
          .insert(
            PlaybooksTableCompanion.insert(
              id: 'pb-1',
              workspaceId: 'ws',
              name: 'deploy',
              sourceProposalJson: '{}',
            ),
          );
      final plan = await (db.select(
        db.planDocumentsTable,
      )..where((t) => t.id.equals('pd-1'))).getSingle();
      expect(plan.agentId, 'a-1');
      final playbook = await (db.select(
        db.playbooksTable,
      )..where((t) => t.id.equals('pb-1'))).getSingle();
      expect(playbook.name, 'deploy');
    });
  });

}
