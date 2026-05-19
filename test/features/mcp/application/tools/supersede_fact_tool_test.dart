import 'dart:convert';

import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/mcp/application/tools/supersede_fact_tool.dart';
import 'package:control_center/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('SupersedeFactTool', () {
    late FakeMemoryFactRepository fakeFactRepo;
    late SupersedeFactUseCase useCase;
    late SupersedeFactTool tool;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 6, 1);
      fakeFactRepo = FakeMemoryFactRepository();
      useCase = SupersedeFactUseCase(factRepository: fakeFactRepo);
      tool = SupersedeFactTool(useCase: useCase);
    });

    test('name is supersede_fact', () {
      expect(tool.name, 'supersede_fact');
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({
        'fact_id': 'f-1',
        'superseding_fact_id': 'f-2',
      });

      expect(result.isError, isTrue);
    });

    test('returns error for missing fact_id', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'superseding_fact_id': 'f-2',
      });

      expect(result.isError, isTrue);
    });

    test('returns error for missing superseding_fact_id', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'fact_id': 'f-1',
      });

      expect(result.isError, isTrue);
    });

    test('supersedes a fact and returns updated record', () async {
      fakeFactRepo.seed([
        MemoryFact(
          id: 'f-1',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          topic: 'language',
          content: 'We use Dart',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'fact_id': 'f-1',
        'superseding_fact_id': 'f-2',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"fact_id":"f-1"'));
      expect(result.content.first.text, contains('"superseded_by":"f-2"'));
      expect(result.content.first.text, contains('"status":"superseded"'));

      final updated = await fakeFactRepo.getById('ws-1', 'f-1');
      expect(updated!.supersededBy, 'f-2');
    });

    test('returns error when fact not found', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'fact_id': 'nonexistent',
        'superseding_fact_id': 'f-2',
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Fact not found'));
    });

    test('scopes lookup to workspace_id — does not leak across workspaces', () async {
      fakeFactRepo.seed([
        MemoryFact(
          id: 'f-1',
          workspaceId: 'ws-2',
          domain: 'tech-stack',
          topic: 'lang',
          content: 'Should not be found',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'fact_id': 'f-1',
        'superseding_fact_id': 'f-2',
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Fact not found'));
    });

    // ── New tests ────────────────────────────────────────────────────────

    group('metadata', () {
      test('description is non-empty', () {
        expect(tool.description, isNotEmpty);
      });

      test('inputSchema has type=object and required fields', () {
        final schema = tool.inputSchema;
        expect(schema['type'], 'object');
        expect(schema['required'], containsAll([
          'workspace_id',
          'fact_id',
          'superseding_fact_id',
        ]));

        final properties = schema['properties'] as Map<String, dynamic>;
        expect((properties['workspace_id'] as Map<String, dynamic>)['type'], 'string');
        expect((properties['fact_id'] as Map<String, dynamic>)['type'], 'string');
        expect((properties['superseding_fact_id'] as Map<String, dynamic>)['type'], 'string');
      });
    });

    group('type validation', () {
      test('workspace_id as int returns error', () async {
        final result = await tool.run({
          'workspace_id': 42,
          'fact_id': 'f-1',
          'superseding_fact_id': 'f-2',
        });

        expect(result.isError, isTrue);
      });

      test('fact_id as int returns error', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 99,
          'superseding_fact_id': 'f-2',
        });

        expect(result.isError, isTrue);
      });

      test('superseding_fact_id as int returns error', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-1',
          'superseding_fact_id': 77,
        });

        expect(result.isError, isTrue);
      });

      test('workspace_id as null returns error', () async {
        final result = await tool.run({
          'workspace_id': null,
          'fact_id': 'f-1',
          'superseding_fact_id': 'f-2',
        });

        expect(result.isError, isTrue);
      });

      test('fact_id as null returns error', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': null,
          'superseding_fact_id': 'f-2',
        });

        expect(result.isError, isTrue);
      });

      test('superseding_fact_id as null returns error', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-1',
          'superseding_fact_id': null,
        });

        expect(result.isError, isTrue);
      });
    });

    group('behavior', () {
      test('self-supersede works — fact_id == superseding_fact_id', () async {
        fakeFactRepo.seed([
          MemoryFact(
            id: 'f-self',
            workspaceId: 'ws-1',
            domain: 'tech-stack',
            topic: 'language',
            content: 'Self-referential fact',
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-self',
          'superseding_fact_id': 'f-self',
        });

        expect(result.isError, isFalse);
        final updated = await fakeFactRepo.getById('ws-1', 'f-self');
        expect(updated!.supersededBy, 'f-self');
      });

      test('can supersede an already-superseded fact (chain)', () async {
        fakeFactRepo.seed([
          MemoryFact(
            id: 'f-1',
            workspaceId: 'ws-1',
            domain: 'tech-stack',
            topic: 'language',
            content: 'First version',
            createdAt: now,
            updatedAt: now,
            supersededBy: 'f-2',
          ),
        ]);

        // Supersede f-1 with f-3 (f-1 is already superseded by f-2)
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-1',
          'superseding_fact_id': 'f-3',
        });

        expect(result.isError, isFalse);
        final updated = await fakeFactRepo.getById('ws-1', 'f-1');
        expect(updated!.supersededBy, 'f-3');
      });

      test('superseding fact does not need to exist', () async {
        fakeFactRepo.seed([
          MemoryFact(
            id: 'f-existing',
            workspaceId: 'ws-1',
            domain: 'tech-stack',
            topic: 'language',
            content: 'Existing fact',
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-existing',
          'superseding_fact_id': 'f-nonexistent',
        });

        // Only the fact being superseded is validated; the replacement ID
        // is just a reference — it does not need to resolve to a stored fact.
        expect(result.isError, isFalse);
        final updated = await fakeFactRepo.getById('ws-1', 'f-existing');
        expect(updated!.supersededBy, 'f-nonexistent');
      });
    });

    group('response shape', () {
      test('success response includes fact_id, superseded_by, status', () async {
        fakeFactRepo.seed([
          MemoryFact(
            id: 'f-resp',
            workspaceId: 'ws-1',
            domain: 'tech-stack',
            topic: 'language',
            content: 'Response shape test',
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-resp',
          'superseding_fact_id': 'f-replace',
        });

        expect(result.isError, isFalse);
        final response = jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(response['fact_id'], 'f-resp');
        expect(response['superseded_by'], 'f-replace');
        expect(response['status'], 'superseded');
        expect(response.keys.length, 3);
      });

      test('ArgumentError message is propagated verbatim', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'fact_id': 'f-bogus',
          'superseding_fact_id': 'f-2',
        });

        expect(result.isError, isTrue);
        // The use case produces 'Fact not found: f-bogus'
        expect(result.content.first.text, 'Fact not found: f-bogus');
      });

      test('workspace_id scoping: fact in ws-1 not found via ws-2', () async {
        fakeFactRepo.seed([
          MemoryFact(
            id: 'f-scope',
            workspaceId: 'ws-1',
            domain: 'tech-stack',
            topic: 'lang',
            content: 'Only in ws-1',
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        final result = await tool.run({
          'workspace_id': 'ws-2',
          'fact_id': 'f-scope',
          'superseding_fact_id': 'f-3',
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Fact not found'));
      });
    });
  });
}
