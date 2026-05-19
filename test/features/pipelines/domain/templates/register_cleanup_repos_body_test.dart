import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/domain/templates/register_cleanup_repos_body.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async =>
      _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _RecordingProvisioner implements RepoWorkspaceProvisionerPort {
  _RecordingProvisioner({this.ticketReleaseCount = 1, this.sweepCount = 0});
  final int ticketReleaseCount;
  final int sweepCount;
  final List<String> releasedTickets = [];
  final List<String> sweptWorkspaces = [];

  @override
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  }) async {
    releasedTickets.add('$workspaceId/$ticketId');
    return ticketReleaseCount;
  }

  @override
  Future<int> sweepStale({required String workspaceId}) async {
    sweptWorkspaces.add(workspaceId);
    return sweepCount;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _RecordingPrWorktrees implements PrWorktreePort {
  final List<String> released = [];

  @override
  Future<void> release({
    required String repoFullName,
    required int prNumber,
  }) async {
    released.add('$repoFullName#$prNumber');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PipelineDefinition _def({String? outputKey}) => PipelineDefinition(
      templateId: 'pr_merged_cleanup',
      workspaceId: 'ws-1',
      name: 'Stale repository cleanup',
      steps: [
        PipelineStepDefinition(
          id: 'cleanup',
          kind: StepKind.listen,
          bodyKey: BuiltInBodyKeys.cleanupRepos,
          config: PipelineNodeConfig(
            label: 'Remove stale worktrees',
            outputKey: outputKey,
          ),
        ),
      ],
    );

typedef _Harness = ({
  Future<StepResult> Function(PipelineContext) handler,
  _RecordingProvisioner provisioner,
  _RecordingPrWorktrees prWorktrees,
});

_Harness _harness({
  String? outputKey = 'cleanupResult',
  int ticketReleaseCount = 1,
  int sweepCount = 0,
}) {
  final registry = PipelineBodyRegistry();
  final provisioner = _RecordingProvisioner(
    ticketReleaseCount: ticketReleaseCount,
    sweepCount: sweepCount,
  );
  final prWorktrees = _RecordingPrWorktrees();
  registerCleanupReposBody(
    registry,
    templateRepository: _FakeTemplateRepo(_def(outputKey: outputKey)),
    provisioner: provisioner,
    prWorktrees: prWorktrees,
  );
  return (
    handler: registry.body(BuiltInBodyKeys.cleanupRepos),
    provisioner: provisioner,
    prWorktrees: prWorktrees,
  );
}

PipelineContext _ctx({Map<String, dynamic>? trigger, bool dryRun = false}) =>
    PipelineContext(
      pipelineRunId: 'run-1',
      templateId: 'pr_merged_cleanup',
      stepId: 'cleanup',
      stepRunId: 'steprun-1',
      workspaceId: 'ws-1',
      state: {},
      triggerPayload: trigger,
      dryRun: dryRun,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('registerCleanupReposBody — ticket mode', () {
    test('releases the ticket worktrees scoped to the run workspace', () async {
      final h = _harness(ticketReleaseCount: 2);
      final result = await h.handler(_ctx(trigger: {'ticketId': 't-1'}));

      expect(result.isFailed, isFalse);
      expect(h.provisioner.releasedTickets, ['ws-1/t-1']);
      expect(h.provisioner.sweptWorkspaces, isEmpty);
      expect(h.prWorktrees.released, isEmpty);
      expect(result.mutatedState!['cleanupResult'],
          'Released 2 worktree(s) for ticket t-1');
    });

    test('reports when the ticket owns no worktrees', () async {
      final h = _harness(ticketReleaseCount: 0);
      final result = await h.handler(_ctx(trigger: {'ticketId': 't-1'}));

      expect(result.mutatedState!['cleanupResult'],
          'No worktrees to release for ticket t-1');
    });

    test('ticket takes priority over a PR payload', () async {
      final h = _harness();
      final result = await h.handler(_ctx(trigger: {
        'ticketId': 't-1',
        'repoFullName': 'acme/app',
        'prNumber': 42,
      }));

      expect(result.isFailed, isFalse);
      expect(h.provisioner.releasedTickets, ['ws-1/t-1']);
      expect(h.prWorktrees.released, isEmpty);
    });
  });

  group('registerCleanupReposBody — PR mode', () {
    test('releases the PR editor worktree', () async {
      final h = _harness();
      final result = await h.handler(_ctx(trigger: {
        'status': 'merged',
        'repoFullName': 'acme/app',
        'prNumber': 42,
      }));

      expect(result.isFailed, isFalse);
      expect(h.prWorktrees.released, ['acme/app#42']);
      expect(h.provisioner.releasedTickets, isEmpty);
      expect(h.provisioner.sweptWorkspaces, isEmpty);
      expect(result.mutatedState!['cleanupResult'],
          'Released PR worktree acme/app#42');
    });

    test('falls back to a sweep when prNumber is missing', () async {
      final h = _harness(sweepCount: 1);
      final result = await h.handler(_ctx(trigger: {
        'status': 'closed',
        'repoFullName': 'acme/app',
      }));

      expect(h.prWorktrees.released, isEmpty);
      expect(h.provisioner.sweptWorkspaces, ['ws-1']);
      expect(result.mutatedState!['cleanupResult'], 'Swept 1 stale worktree(s)');
    });
  });

  group('registerCleanupReposBody — sweep mode', () {
    test('sweeps the workspace when no unit is in the payload', () async {
      final h = _harness(sweepCount: 3);
      final result = await h.handler(_ctx());

      expect(result.isFailed, isFalse);
      expect(h.provisioner.sweptWorkspaces, ['ws-1']);
      expect(h.provisioner.releasedTickets, isEmpty);
      expect(h.prWorktrees.released, isEmpty);
      expect(result.mutatedState!['cleanupResult'], 'Swept 3 stale worktree(s)');
    });

    test('reports a clean sweep', () async {
      final h = _harness(sweepCount: 0);
      final result = await h.handler(_ctx(trigger: {}));

      expect(result.mutatedState!['cleanupResult'], 'No stale worktrees to sweep');
    });
  });

  group('registerCleanupReposBody — dry run & output key', () {
    test('dry run performs no teardown and echoes the target', () async {
      final h = _harness();
      final result =
          await h.handler(_ctx(trigger: {'ticketId': 't-1'}, dryRun: true));

      expect(h.provisioner.releasedTickets, isEmpty);
      expect(h.provisioner.sweptWorkspaces, isEmpty);
      expect(h.prWorktrees.released, isEmpty);
      expect(result.mutatedState!['cleanupResult'],
          {'dryRun': true, 'target': 'ticket t-1'});
    });

    test('succeeds with no output key declared', () async {
      final h = _harness(outputKey: null);
      final result = await h.handler(_ctx(trigger: {'ticketId': 't-1'}));

      expect(result.isFailed, isFalse);
      expect(h.provisioner.releasedTickets, ['ws-1/t-1']);
      expect(result.mutatedState, isEmpty);
    });
  });
}
