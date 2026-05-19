import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

PipelineRun _run({
  String id = 'run-1',
  PipelineRunStatus status = PipelineRunStatus.completed,
  String? triggerEventType,
}) {
  return PipelineRun(
    id: id,
    templateId: 'tmpl-1',
    workspaceId: 'ws-1',
    status: status,
    triggerEventType: triggerEventType,
    startedAt: DateTime(2026, 1, 1, 12),
    finishedAt: DateTime(2026, 1, 1, 12, 0, 3),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FTheme(
      data: FThemes.zinc.light.desktop,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PipelineRunCard', () {
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
      expect(find.byType(FTappable), findsWidgets);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(PipelineRunCard)),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });

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

    testWidgets('a manual run reads as Manual', (tester) async {
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
    });
  });
}
