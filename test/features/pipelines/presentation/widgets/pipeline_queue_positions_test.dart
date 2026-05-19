import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineRun _run(
  String id, {
  required PipelineRunStatus status,
  String templateId = 'index_code',
  String workspaceId = 'ws-1',
}) => PipelineRun(
  id: id,
  templateId: templateId,
  workspaceId: workspaceId,
  status: status,
  // Every run of a burst shares one second — `started_at` is stored at second
  // resolution, so this is what the real rows look like and why position is
  // read off the list's ORDER rather than off this stamp.
  startedAt: DateTime(2026, 1, 1, 12, 30, 45),
);

/// A capped template drains its queue oldest-first, but the runs table lists
/// runs newest-first — so the run about to start is the one at the BOTTOM of a
/// queued block, which reads as last when it is next.
void main() {
  group('pipelineQueuePositions', () {
    test('numbers a queue from the end of the list, 1 being next', () {
      // Newest first, as the server orders them: `c` was added last.
      final runs = [
        _run('c', status: PipelineRunStatus.queued),
        _run('b', status: PipelineRunStatus.queued),
        _run('a', status: PipelineRunStatus.queued),
      ];

      expect(pipelineQueuePositions(runs), {'a': 1, 'b': 2, 'c': 3});
    });

    test('ignores runs that are not queued', () {
      final runs = [
        _run('running', status: PipelineRunStatus.running),
        _run('queued', status: PipelineRunStatus.queued),
        _run('done', status: PipelineRunStatus.completed),
      ];

      expect(pipelineQueuePositions(runs), {'queued': 1});
    });

    test('counts each template separately', () {
      // The cap is per template, so two templates' queues are two queues —
      // each has its own "next".
      final runs = [
        _run('index-2', status: PipelineRunStatus.queued),
        _run('review-2', status: PipelineRunStatus.queued, templateId: 'pr'),
        _run('index-1', status: PipelineRunStatus.queued),
        _run('review-1', status: PipelineRunStatus.queued, templateId: 'pr'),
      ];

      expect(pipelineQueuePositions(runs), {
        'index-1': 1,
        'index-2': 2,
        'review-1': 1,
        'review-2': 2,
      });
    });

    test('does not merge queues across workspaces', () {
      final runs = [
        _run('other', status: PipelineRunStatus.queued, workspaceId: 'ws-2'),
        _run('mine', status: PipelineRunStatus.queued),
      ];

      expect(pipelineQueuePositions(runs), {'mine': 1, 'other': 1});
    });

    test('is empty when nothing waits', () {
      expect(
        pipelineQueuePositions([_run('r', status: PipelineRunStatus.running)]),
        isEmpty,
      );
    });
  });
}
