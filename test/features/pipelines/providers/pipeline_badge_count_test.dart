import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves one caller-driven run stream for the workspace under test.
class _FakeRunRepo implements PipelineRunRepository {
  // Closed in `_harness` tearDown; close_sinks cannot see that lifecycle.
  // ignore: close_sinks
  final controller = StreamController<List<PipelineRun>>();

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) =>
      controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The provider under test, wired to a hand-fed run stream.
///
/// Built INSIDE the test body, never in `setUp`: `testWidgets` bodies run in a
/// fake-async zone, and a `StreamController` created outside it delivers its
/// events on the real microtask queue, where `tester.pump` can never see them.
({_FakeRunRepo repo, List<int> emitted}) _harness(WidgetTester tester) {
  final repo = _FakeRunRepo();
  final container = ProviderContainer(
    overrides: [pipelineRunRepositoryProvider.overrideWithValue(repo)],
  );
  final emitted = <int>[];
  container.listen<AsyncValue<int>>(runningPipelineCountProvider('ws-1'), (
    _,
    next,
  ) {
    final value = next.value;
    if (value != null) {
      emitted.add(value);
    }
  }, fireImmediately: true);
  addTearDown(() {
    container.dispose();
    repo.controller.close();
  });
  return (repo: repo, emitted: emitted);
}

PipelineRun _run(String id, PipelineRunStatus status) => PipelineRun(
  id: id,
  templateId: 'pr_merged_cleanup',
  workspaceId: 'ws-1',
  status: status,
  startedAt: DateTime(2026, 1, 1, 12),
  finishedAt: status == PipelineRunStatus.running
      ? null
      : DateTime(2026, 1, 1, 12, 0, 1),
);

void main() {
  const settle = Duration(milliseconds: 700);
  const beyondSettle = Duration(milliseconds: 900);

  group('runningPipelineCountProvider', () {
    testWidgets('a sub-second run never reaches the badge', (tester) async {
      final h = _harness(tester);

      // What pr_merged_cleanup does on every merged PR the poller sees: start
      // and finish well inside the settle window.
      h.repo.controller.add([_run('r1', PipelineRunStatus.running)]);
      await tester.pump(const Duration(milliseconds: 200));
      h.repo.controller.add([_run('r1', PipelineRunStatus.completed)]);
      await tester.pump(beyondSettle);

      // The settled feed resolves to zero (that's what lifts the provider out
      // of `loading`), but it never passes through a badge-showing count.
      expect(h.emitted, everyElement(0));
    });

    testWidgets('a run that outlives the settle window shows, then clears', (
      tester,
    ) async {
      final h = _harness(tester);

      h.repo.controller.add([_run('r1', PipelineRunStatus.running)]);
      await tester.pump(beyondSettle);
      expect(h.emitted, [1]);

      h.repo.controller.add([_run('r1', PipelineRunStatus.completed)]);
      await tester.pump(beyondSettle);
      expect(h.emitted, [1, 0]);
    });

    testWidgets('progress re-emits at an unchanged count do not starve the '
        'badge', (tester) async {
      final h = _harness(tester);

      // The run stream re-emits on every pipeline mutation. Those repeats are
      // deduped upstream of the timer, so they must not keep resetting it.
      h.repo.controller.add([_run('r1', PipelineRunStatus.running)]);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        h.repo.controller.add([_run('r1', PipelineRunStatus.running)]);
      }
      await tester.pump(settle);

      expect(h.emitted, [1]);
    });

    testWidgets('a second concurrent run raises the settled count', (
      tester,
    ) async {
      final h = _harness(tester);

      h.repo.controller.add([_run('r1', PipelineRunStatus.running)]);
      await tester.pump(beyondSettle);
      h.repo.controller.add([
        _run('r1', PipelineRunStatus.running),
        _run('r2', PipelineRunStatus.running),
      ]);
      await tester.pump(beyondSettle);

      expect(h.emitted, [1, 2]);
    });
  });
}
