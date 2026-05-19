import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/max_parallel_runs_field.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_settings_dialog.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';
const _templateId = 'tpl-1';

/// Mutable capture of what the dialog returned, and whether it returned at all.
class _DialogOutcome {
  bool closed = false;
  PipelineRunSettingsResult? result;
}

/// Mounts a button that opens the run-settings dialog, taps it, and returns the
/// holder the dialog's result lands in once it closes.
Future<_DialogOutcome> _openRunSettings(
  WidgetTester tester, {
  required int? maxParallelRuns,
}) async {
  final outcome = _DialogOutcome();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pipelineTriggersForWorkspaceProvider(
          _workspaceId,
        ).overrideWith((ref) => const Stream.empty()),
      ],
      child: testWrap(
        Consumer(
          builder: (context, ref, _) => CcButton(
            onPressed: () async {
              outcome.result = await showPipelineRunSettingsDialog(
                context: context,
                ref: ref,
                workspaceId: _workspaceId,
                templateId: _templateId,
                inputs: const <PipelineInput>[],
                maxParallelRuns: maxParallelRuns,
              );
              outcome.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return outcome;
}

void main() {
  group('parseMaxParallelRuns', () {
    test('a blank field means unlimited, not an error', () {
      expect(parseMaxParallelRuns(''), (value: null, isInvalid: false));
      expect(parseMaxParallelRuns('   '), (value: null, isInvalid: false));
    });

    test('parses a positive whole number', () {
      expect(parseMaxParallelRuns('1'), (value: 1, isInvalid: false));
      expect(parseMaxParallelRuns(' 12 '), (value: 12, isInvalid: false));
    });

    test('rejects zero and negatives rather than coercing them', () {
      // Coercing 0 to "unlimited" would mean the opposite of what was typed.
      expect(parseMaxParallelRuns('0').isInvalid, isTrue);
      expect(parseMaxParallelRuns('-3').isInvalid, isTrue);
    });

    test('rejects text that is not a whole number', () {
      expect(parseMaxParallelRuns('two').isInvalid, isTrue);
      expect(parseMaxParallelRuns('1.5').isInvalid, isTrue);
    });
  });

  group('run settings dialog', () {
    testWidgets('shows the current cap and returns an edited one', (
      tester,
    ) async {
      final outcome = await _openRunSettings(tester, maxParallelRuns: 1);
      expect(find.text('Max parallel runs'), findsOneWidget);

      await tester.enterText(find.byType(CcTextField).first, '3');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      expect(outcome.result!.maxParallelRuns, 3);
    });

    testWidgets('an empty field saves as unlimited', (tester) async {
      final outcome = await _openRunSettings(tester, maxParallelRuns: 2);

      await tester.enterText(find.byType(CcTextField).first, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      expect(
        outcome.result!.maxParallelRuns,
        isNull,
        reason: 'clearing the field is the only way back to unlimited',
      );
    });

    testWidgets('a rejected value keeps the dialog open with an error', (
      tester,
    ) async {
      final outcome = await _openRunSettings(tester, maxParallelRuns: null);

      // The field filters to digits, so 0 is the reachable invalid value.
      await tester.enterText(find.byType(CcTextField).first, '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        outcome.closed,
        isFalse,
        reason: 'the dialog must not close on an invalid cap',
      );
      expect(
        find.text(
          'Enter a whole number of 1 or more, or leave it empty for unlimited.',
        ),
        findsOneWidget,
      );
    });
  });
}
