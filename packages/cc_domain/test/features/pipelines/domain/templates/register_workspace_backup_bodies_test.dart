import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_workspace_backup_bodies.dart';
import 'package:test/test.dart';

class _Backups implements DatabaseBackupPort {
  bool failSnapshot = false;
  final List<String> snapshotWorkspaces = [];
  final List<({Duration age, String? workspaceId})> deletions = [];

  @override
  Future<String> backupWorkspace(String workspaceId) async {
    snapshotWorkspaces.add(workspaceId);
    if (failSnapshot) {
      throw StateError('disk full');
    }
    return '/backups/workspace-backups/$workspaceId/new/workspace.db';
  }

  @override
  Future<int> deleteBackupsOlderThan({
    required Duration age,
    String? workspaceId,
  }) async {
    deletions.add((age: age, workspaceId: workspaceId));
    return 2;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _Templates implements PipelineTemplateRepository {
  _Templates(this.definition);
  final PipelineDefinition definition;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    if (workspaceId != definition.workspaceId ||
        templateId != definition.templateId) {
      return null;
    }
    return definition;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

PipelineContext _context(String stepId, {bool dryRun = false}) =>
    PipelineContext(
      pipelineRunId: 'run-1',
      templateId: 'workspace_backup',
      stepId: stepId,
      stepRunId: 'step-run-1',
      workspaceId: 'workspace-A',
      state: const {},
      dryRun: dryRun,
    );

void main() {
  final definition = workspaceBackupTemplate('workspace-A');

  test(
    'successful snapshot then retention stays within running workspace',
    () async {
      final backups = _Backups();
      final bodies = PipelineBodyRegistry();
      registerWorkspaceBackupBodies(
        bodies,
        backups: backups,
        templateRepository: _Templates(definition),
      );

      final snapshot = await bodies.body(BuiltInBodyKeys.backupWorkspace)(
        _context('backup'),
      );
      expect(snapshot.isFailed, isFalse);
      expect(backups.snapshotWorkspaces, ['workspace-A']);
      expect(
        snapshot.mutatedState?['backup_path'],
        '/backups/workspace-backups/workspace-A/new/workspace.db',
      );

      final prune = await bodies.body(BuiltInBodyKeys.deleteOldBackups)(
        _context('delete_old_backups'),
      );
      expect(prune.isFailed, isFalse);
      expect(backups.deletions, [
        (age: const Duration(days: 30), workspaceId: 'workspace-A'),
      ]);
      expect(prune.mutatedState?['deleted_backups'], 2);
    },
  );

  test('invalid retention cannot delete anything', () async {
    final backups = _Backups();
    final steps = definition.steps.map((step) {
      if (step.id != 'delete_old_backups') {
        return step;
      }
      return PipelineStepDefinition.fromJson({
        ...step.toJson(),
        'config': step.config.copyWith(extras: {'retentionDays': -1}).toJson(),
      });
    }).toList();
    final bodies = PipelineBodyRegistry();
    registerWorkspaceBackupBodies(
      bodies,
      backups: backups,
      templateRepository: _Templates(definition.copyWith(steps: steps)),
    );
    final result = await bodies.body(BuiltInBodyKeys.deleteOldBackups)(
      _context('delete_old_backups'),
    );
    expect(result.isFailed, isTrue);
    expect(backups.deletions, isEmpty);
  });

  test(
    'snapshot failure returns a failed step for engine propagation',
    () async {
      final backups = _Backups()..failSnapshot = true;
      final bodies = PipelineBodyRegistry();
      registerWorkspaceBackupBodies(
        bodies,
        backups: backups,
        templateRepository: _Templates(definition),
      );
      final result = await bodies.body(BuiltInBodyKeys.backupWorkspace)(
        _context('backup'),
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('disk full'));
    },
  );
}
