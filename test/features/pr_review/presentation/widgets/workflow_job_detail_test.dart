import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_job_detail.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [codeFontFamilyProvider.overrideWithValue('Fira Code')],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  const log =
      'line one\n'
      '##[group]Install deps\n'
      'installing...\n'
      '##[endgroup]\n'
      'line five\n';

  testWidgets('renders GitHub-style numbered rows in the configured code '
      'font', (tester) async {
    await tester.pumpWidget(_wrap(const JobLogBody(text: log)));
    await tester.pump();

    // Gutter numbers for the visible rows (1 line, 2 group header, 3 child,
    // 4 trailing line — the hidden ##[endgroup] marker consumes no number).
    for (final n in ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('line one'), findsOneWidget);
    expect(find.text('Install deps'), findsOneWidget);
    expect(find.text('installing...'), findsOneWidget);

    final lineText = tester.widget<Text>(find.text('line one'));
    // The provider override is the display name 'Fira Code', which is not the
    // bundled asset family (`packages/cc_ui/Fira Code`), so codeStyleDynamic
    // routes through CcFontRegistry and names the cut `{family} {weight}`.
    expect(lineText.style?.fontFamily, startsWith('Fira Code'));
  });

  testWidgets('tapping a group header folds it; gutter numbers keep the '
      'jump', (tester) async {
    await tester.pumpWidget(_wrap(const JobLogBody(text: log)));
    await tester.pump();

    await tester.tap(find.text('Install deps'));
    await tester.pump();

    // Child rows are hidden…
    expect(find.text('installing...'), findsNothing);
    expect(find.text('3'), findsNothing);
    // …but surrounding rows keep their numbers (contiguous, marker-free).
    expect(find.text('line five'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Tapping again unfolds.
    await tester.tap(find.text('Install deps'));
    await tester.pump();
    expect(find.text('installing...'), findsOneWidget);
  });

  testWidgets('select-all + copy includes the log text but not the gutter '
      'numbers', (tester) async {
    var clipboard = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard =
              (call.arguments as Map<dynamic, dynamic>)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_wrap(const JobLogBody(text: log)));
    await tester.pump();

    final region = tester.state<SelectableRegionState>(
      find.descendant(
        of: find.byType(JobLogBody),
        matching: find.byType(SelectableRegion),
      ),
    );
    region.selectAll(SelectionChangedCause.keyboard);
    // SelectableRegionState.copySelection is the test seam for clipboard
    // contents; the deprecation is about the widget's own context menu, not
    // this programmatic copy.
    // ignore: deprecated_member_use
    region.copySelection(SelectionChangedCause.keyboard);
    await tester.pump();

    expect(clipboard, contains('line one'));
    expect(clipboard, contains('line five'));
    // No gutter digits ride along.
    expect(clipboard.contains(RegExp(r'\d')), isFalse);
  });
}
