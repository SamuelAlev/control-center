import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_row.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_runs_table.dart';
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PipelineRun _run(int i) => PipelineRun(
  id: 'run-$i',
  templateId: 'hello',
  workspaceId: 'ws-1',
  status: PipelineRunStatus.completed,
  startedAt: DateTime(2026, 1, 1),
);

/// The runs table's sliver contract, mirrored from `PipelinesScreen._RunsPane`
/// and the PR queue's `PrRepoSectionCard`: the column header is a pinned
/// [SliverPersistentHeader] of the PR queue's exact 40px extent with its labels
/// in the shared [CcTypography.caption] style, and the rows scroll beneath it.
/// These tests pin the pinning and the parity — a plain-box or restyled
/// regression here is exactly what let the header drift from the PR list.
void main() {
  Widget host(List<PipelineRun> runs) => testWrap(
    CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(right: 16),
          sliver: PipelineRunsTable(
            runs: runs,
            now: DateTime(2026, 1, 1),
            titleFor: (run) => 'Pipeline ${run.id}',
            onOpen: (_) {},
          ),
        ),
      ],
    ),
  );

  testWidgets('the column header pins while the rows scroll beneath it', (
    tester,
  ) async {
    await tester.pumpWidget(host([for (var i = 0; i < 30; i++) _run(i)]));

    final headerLabel = find.text('Duration');
    final firstRow = find.byType(PipelineRunRow).first;
    final headerAtRest = tester.getRect(headerLabel);
    final rowAtRest = tester.getRect(firstRow);

    // The header's box is the PR queue header's exact extent: 40px.
    expect(
      tester.getRect(find.byType(PinnedHeaderBleedGuard)).height,
      40,
      reason: 'the pinned header must match the PR queue header box',
    );

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;

    // Sweep in deliberately fractional steps: at every scroll offset the
    // labels hold the top of the viewport while the rows slide beneath.
    for (
      var target = 0.0;
      target <= position.maxScrollExtent;
      target += 13.7
    ) {
      position.jumpTo(target);
      await tester.pump();
      expect(
        tester.getRect(headerLabel),
        headerAtRest,
        reason: 'offset $target: the pinned header must not move',
      );
      expect(
        tester.getRect(find.byType(PinnedHeaderBleedGuard)).top,
        0,
        reason: 'offset $target: the pinned header must sit at the viewport top',
      );
    }

    expect(
      tester.getTopLeft(firstRow).dy,
      lessThan(0),
      reason: 'at max extent the first row must have scrolled under the header',
    );
    expect(rowAtRest.top, greaterThan(0));
  });

  testWidgets('the column labels match the PR queue header type style', (
    tester,
  ) async {
    await tester.pumpWidget(host([_run(0)]));

    for (final label in ['Pipeline', 'Duration', 'Started']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style, isNotNull, reason: '$label must carry a style');
      expect(
        text.style!.fontSize,
        CcTypography.caption.fontSize,
        reason: '$label must use the caption size the PR/inbox headers use',
      );
      expect(
        text.style!.letterSpacing,
        CcTypography.caption.letterSpacing,
        reason: '$label must use the caption tracking the PR/inbox headers use',
      );
      expect(
        text.style!.fontWeight,
        FontWeight.w500,
        reason: '$label must carry the headers\' w500 base weight',
      );
    }
  });
}
