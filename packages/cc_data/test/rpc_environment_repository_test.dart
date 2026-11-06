import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:test/test.dart';

void main() {
  group('environmentDefinitionRecordFromWire', () {
    test('reads the wire form the server writes', () {
      final record = environmentDefinitionRecordFromWire({
        'id': 'd1',
        'workspace_id': 'ws',
        'name': 'Shop',
        'definition': {'name': 'Shop'},
        'source_repo_id': 'r1',
        'source_path': '.cc/environment.json',
        'approved_blob_hash': 'abc',
        'overrides': {
          'policy': {'maxRunning': 2},
        },
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      });
      expect(record.hasSource, isTrue);
      expect(record.definitionJson, '{"name":"Shop"}');
      expect(record.overridesJson, '{"policy":{"maxRunning":2}}');
      expect(record.toJson()['definition'], {'name': 'Shop'});
    });
  });

  group('environmentRunFromWire', () {
    test('round-trips the entity wire form', () {
      final run = EnvironmentRun(
        id: 'r1',
        workspaceId: 'ws',
        spaceId: 's1',
        kind: EnvironmentRunKind.task,
        label: 'migrate',
        status: EnvironmentRunStatus.timedOut,
        startedAt: DateTime.utc(2026),
        completedAt: DateTime.utc(2026, 1, 2),
        exitCode: 124,
        output: 'tail',
      );
      expect(environmentRunFromWire(run.toJson()), run);
    });
  });

  group('environmentIssuesFromMessage', () {
    test('splits path: message lines and keeps the rest', () {
      final issues = environmentIssuesFromMessage(
        'components[0].id: Must match x\nrepos: At least one\nNo path here',
      );
      expect(issues.map((issue) => issue.path), [
        'components[0].id',
        'repos',
        '',
      ]);
      expect(issues.first.message, 'Must match x');
      expect(issues.last.message, 'No path here');
    });
  });

  group('environmentSourceUpdateFromWire', () {
    test('reads the shape environment_service_definitions sends', () {
      final update = environmentSourceUpdateFromWire({
        'blob_hash': 'b2',
        'approved_blob_hash': 'b1',
        'update_available': true,
        'text': '{"name":"Shop"}',
        'approved_text': '{"name":"Old"}',
      })!;
      expect(update.currentHash, 'b2');
      expect(update.approvedHash, 'b1');
      expect(update.hasUpdate, isTrue);
      expect(update.content, '{"name":"Shop"}');
      expect(update.approvedContent, '{"name":"Old"}');
    });

    test('trusts update_available over comparing hashes', () {
      final update = environmentSourceUpdateFromWire({
        'blob_hash': 'b1',
        'approved_blob_hash': 'b1',
        'update_available': false,
        'text': '{}',
        'approved_text': '{}',
      })!;
      expect(update.hasUpdate, isFalse);
    });

    test('an empty object is a definition without a source', () {
      expect(environmentSourceUpdateFromWire(const {}), isNull);
    });
  });
}
