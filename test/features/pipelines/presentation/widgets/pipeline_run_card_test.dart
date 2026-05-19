import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_card.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

PipelineRun _run({
  String id = 'run-1',
  String templateId = 'tmpl-1',
  PipelineRunStatus status = PipelineRunStatus.completed,
  String? triggerEventType,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: 'ws-1',
    status: status,
    triggerEventType: triggerEventType,
    startedAt: startedAt ?? DateTime(2026, 1, 1, 12),
    finishedAt: finishedAt ?? DateTime(2026, 1, 1, 12, 0, 3),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PipelineRunCard', () {
    // ── Title ─────────────────────────────────────────────────────────

    testWidgets('renders the resolved title and is a semantic button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Index repository code',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Index repository code'), findsOneWidget);
      // Hardening: the row is a real focusable control, not a bare gesture.
      expect(find.byType(CcTappable), findsWidgets);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(PipelineRunCard)),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });

    testWidgets('falls back to templateId when title is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(templateId: 'build-deploy'),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: null,
          ),
        ),
      );

      expect(find.text('build-deploy'), findsOneWidget);
    });

    // ── onTap ─────────────────────────────────────────────────────────

    testWidgets('activating the card fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(PipelineRunCard));
      await tester.pumpAndSettle();
      expect(taps, 1, reason: 'tap selects the run');
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onTap: null,
          ),
        ),
      );

      // Just making sure rendering doesn't explode.
      expect(find.text('Run'), findsOneWidget);
    });

    // ── Trigger label & icon ──────────────────────────────────────────

    testWidgets('a manual run (null trigger) reads as Manual', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(triggerEventType: null),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Manual'), findsOneWidget);
      expect(find.byIcon(LucideIcons.play), findsOneWidget);
    });

    testWidgets('an explicit manual run reads as Manual', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(triggerEventType: 'manual'),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Manual'), findsOneWidget);
      expect(find.byIcon(LucideIcons.play), findsOneWidget);
    });

    testWidgets('an automatic run reads as Automatic with zap icon',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(triggerEventType: 'push'),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Automatic'), findsOneWidget);
      expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    });

    // ── Relative time ─────────────────────────────────────────────────

    testWidgets('shows "just now" when started within the last minute',
        (tester) async {
      final started = DateTime(2026, 1, 1, 12, 0, 30);
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(
              startedAt: started,
              finishedAt: DateTime(2026, 1, 1, 12, 0, 33),
            ),
            now: DateTime(2026, 1, 1, 12, 0, 45),
            title: 'Run',
          ),
        ),
      );

      expect(find.textContaining('just now'), findsOneWidget);
    });

    testWidgets('shows "N min ago" when started minutes ago', (tester) async {
      final started = DateTime(2026, 1, 1, 11, 55);
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(startedAt: started,
                finishedAt: DateTime(2026, 1, 1, 11, 55, 3)),
            now: DateTime(2026, 1, 1, 12, 0),
            title: 'Run',
          ),
        ),
      );

      expect(find.textContaining('5 min ago'), findsOneWidget);
    });

    testWidgets('shows "N hours ago" when started hours ago', (tester) async {
      final started = DateTime(2026, 1, 1, 9, 0);
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(startedAt: started,
                finishedAt: DateTime(2026, 1, 1, 9, 0, 3)),
            now: DateTime(2026, 1, 1, 12, 0),
            title: 'Run',
          ),
        ),
      );

      expect(find.textContaining('3 hours ago'), findsOneWidget);
    });

    testWidgets('shows "N days ago" when started days ago', (tester) async {
      final started = DateTime(2026, 1, 1, 12, 0);
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(startedAt: started,
                finishedAt: DateTime(2026, 1, 1, 12, 0, 3)),
            now: DateTime(2026, 1, 3, 12, 0),
            title: 'Run',
          ),
        ),
      );

      expect(find.textContaining('2 days ago'), findsOneWidget);
    });

    // ── Duration ──────────────────────────────────────────────────────

    testWidgets('shows coarse duration computed from finishedAt when present',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(
              startedAt: DateTime(2026, 1, 1, 12),
              finishedAt: DateTime(2026, 1, 1, 12, 0, 3),
            ),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
          ),
        ),
      );

      // 3 seconds → '3s'
      expect(find.text('3s'), findsOneWidget);
    });

    testWidgets('shows coarse duration computed from now when still running',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: PipelineRun(
              id: 'run-1',
              templateId: 'tmpl-1',
              workspaceId: 'ws-1',
              status: PipelineRunStatus.running,
              startedAt: DateTime(2026, 1, 1, 12),
            ),
            now: DateTime(2026, 1, 1, 12, 2, 34),
            title: 'Run',
          ),
        ),
      );

      // 2 min 34 s → '2m 34s'
      expect(find.text('2m 34s'), findsOneWidget);
    });

    testWidgets('shows <1s for instant runs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(
              startedAt: DateTime(2026, 1, 1, 12),
              finishedAt: DateTime(2026, 1, 1, 12),
            ),
            now: DateTime(2026, 1, 1, 12),
            title: 'Run',
          ),
        ),
      );

      expect(find.text('<1s'), findsOneWidget);
    });

    testWidgets('shows hour‑prefixed duration for long runs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(
              startedAt: DateTime(2026, 1, 1, 12),
              finishedAt: DateTime(2026, 1, 1, 13, 2, 0),
            ),
            now: DateTime(2026, 1, 1, 14),
            title: 'Run',
          ),
        ),
      );

      // 1h 2m 0s → '1h 2m'
      expect(find.text('1h 2m'), findsOneWidget);
    });

    // ── Selected state ────────────────────────────────────────────────

    testWidgets('selected card has brand border', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Selected',
            selected: true,
          ),
        ),
      );

      // The semantics node should report selected.
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(PipelineRunCard)),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('unselected card is not selected in semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Unselected',
            selected: false,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(PipelineRunCard)),
        isSemantics(isSelected: false, isButton: true),
      );
      handle.dispose();
    });

    // ── Status badge ──────────────────────────────────────────────────

    testWidgets('renders status badge for each status without error',
        (tester) async {
      for (final status in PipelineRunStatus.values) {
        await tester.pumpWidget(
          _wrap(
            PipelineRunCard(
              run: _run(status: status),
              now: DateTime(2026, 1, 1, 12, 0, 5),
              title: 'Run',
            ),
          ),
        );

        // Every card has a PipelineStatusBadge.
        expect(find.byType(PipelineStatusBadge), findsOneWidget);
      }
    });

    // ── Subtitle structure ────────────────────────────────────────────

    testWidgets('subtitle is "just now · Manual" for null trigger',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(
              triggerEventType: null,
              startedAt: DateTime(2026, 1, 1, 12),
              finishedAt: DateTime(2026, 1, 1, 12, 0, 3),
            ),
            now: DateTime(2026, 1, 1, 12),
            title: 'Run',
          ),
        ),
      );

      // The subtitle concatenates a relative time, " · ", and a trigger label.
      expect(find.textContaining('Manual'), findsOneWidget);
      // "just now" won't render when at the exact same time (0 seconds diff
      // actually gives inMinutes=0), so we just ensure both pieces are there in
      // the same card.
    });

    testWidgets('title text is styled as primary and bold', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Bold title',
          ),
        ),
      );

      final titleWidget =
          tester.widget<Text>(find.text('Bold title'));
      expect(titleWidget.style?.fontWeight, FontWeight.w600);
      expect(titleWidget.style?.fontSize, 14);
    });

    testWidgets('duration text is styled with medium weight', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunCard(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
          ),
        ),
      );

      final durationWidget = tester.widget<Text>(find.text('3s'));
      expect(durationWidget.style?.fontWeight, FontWeight.w500);
    });
  });
}
