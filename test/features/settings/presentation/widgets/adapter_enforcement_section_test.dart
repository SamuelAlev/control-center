import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/adapter_enforcement_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  AdapterTransport transport, {
  bool expanded = true,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    _wrap(
      AdapterEnforcementSection(
        transport: transport,
        initiallyExpanded: expanded,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AdapterEnforcementSection', () {
    testWidgets('renders the five enforcement rows for every transport', (
      tester,
    ) async {
      for (final transport in AdapterTransport.values) {
        await _pump(tester, transport);

        expect(find.text('What this adapter enforces'), findsOneWidget);
        expect(
          find.text('Control Center picks the tools'),
          findsOneWidget,
          reason: '$transport',
        );
        expect(
          find.text('Every call is gated before it runs'),
          findsOneWidget,
          reason: '$transport',
        );
        expect(
          find.text("The runner's own tools are visible"),
          findsOneWidget,
          reason: '$transport',
        );
        expect(
          find.text('The run is held to its deliverable'),
          findsOneWidget,
          reason: '$transport',
        );
        expect(
          find.text('In-process tools are sandboxed'),
          findsOneWidget,
          reason: '$transport',
        );
      }
    });

    testWidgets('states each answer as a word, not only a colour', (
      tester,
    ) async {
      // The a11y bar: status is never colour-alone. The harness declares four
      // yeses and one no, so both words must be on screen and the counts must
      // match the declaration exactly.
      await _pump(tester, AdapterTransport.harness);

      expect(find.text('Yes'), findsNWidgets(4));
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('acp shows four nos and one yes', (tester) async {
      await _pump(tester, AdapterTransport.acp);

      expect(find.text('No'), findsNWidgets(4));
      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('renders the mode mapping note verbatim', (tester) async {
      await _pump(tester, AdapterTransport.acp);

      expect(
        find.text(
          enforcementForTransport(AdapterTransport.acp).modeMappingNote,
        ),
        findsOneWidget,
      );
    });

    testWidgets('surfaces the harness in-process sandbox caveat', (
      tester,
    ) async {
      await _pump(tester, AdapterTransport.harness);

      expect(find.text('Caveats'), findsOneWidget);
      expect(
        find.textContaining('In-process file tools run outside the sandbox'),
        findsOneWidget,
      );
      // The harness intercepts everything, so it must NOT claim the CLI caveat.
      expect(find.textContaining('never reach Control Center'), findsNothing);
    });

    testWidgets('surfaces every acp caveat', (tester) async {
      await _pump(tester, AdapterTransport.acp);

      expect(
        find.textContaining('Read-only modes are not structural'),
        findsOneWidget,
      );
      expect(find.textContaining('No pre-execution gate'), findsOneWidget);
      expect(find.textContaining('never reach Control Center'), findsOneWidget);
      expect(find.textContaining('cannot nudge or fail a run'), findsOneWidget);
      // ACP has no in-process tools of ours, so that caveat must not appear.
      expect(
        find.textContaining('In-process file tools run outside the sandbox'),
        findsNothing,
      );
    });

    testWidgets('collapses to one summary line by default', (tester) async {
      // Settings lists every runner in the catalogue, so the matrix must not be
      // twelve lines per row by default — but the verdict and the caveat count
      // stay on screen, because that is the disclosure.
      await _pump(tester, AdapterTransport.acp, expanded: false);

      expect(find.text('What this adapter enforces'), findsOneWidget);
      expect(find.text('Modes not enforced'), findsOneWidget);
      expect(find.text('4 caveats'), findsOneWidget);

      expect(find.text('Control Center picks the tools'), findsNothing);
      expect(find.text('In-process tools are sandboxed'), findsNothing);
      expect(find.text('Caveats'), findsNothing);
      expect(
        find.text(
          enforcementForTransport(AdapterTransport.acp).modeMappingNote,
        ),
        findsNothing,
      );
    });

    testWidgets('states the verdict in the header for every transport', (
      tester,
    ) async {
      // Never status-by-colour-alone: the shield glyph is a reinforcement, the
      // word is the signal, and it must match the domain's own verdict.
      for (final transport in AdapterTransport.values) {
        await _pump(tester, transport, expanded: false);
        final enforcement = enforcementForTransport(transport);

        expect(
          find.text(
            enforcement.enforcesModeGuarantees
                ? 'Modes enforced'
                : 'Modes not enforced',
          ),
          findsOneWidget,
          reason: '$transport',
        );
        expect(
          find.text(
            enforcement.caveats.length == 1
                ? '1 caveat'
                : '${enforcement.caveats.length} caveats',
          ),
          findsOneWidget,
          reason: '$transport',
        );
      }
    });

    testWidgets('tapping the header opens and closes the matrix', (
      tester,
    ) async {
      await _pump(tester, AdapterTransport.harness, expanded: false);

      await tester.tap(find.text('What this adapter enforces'));
      await tester.pumpAndSettle();

      expect(find.text('Control Center picks the tools'), findsOneWidget);
      expect(find.text('Caveats'), findsOneWidget);

      await tester.tap(find.text('What this adapter enforces'));
      await tester.pumpAndSettle();

      expect(find.text('Control Center picks the tools'), findsNothing);
      expect(find.text('Caveats'), findsNothing);
      // The verdict survives the close.
      expect(find.text('Modes enforced'), findsOneWidget);
    });

    testWidgets('renders one caveat line per declared caveat', (tester) async {
      for (final transport in AdapterTransport.values) {
        await _pump(tester, transport);
        final expected = enforcementForTransport(transport).caveats;
        for (final caveat in expected) {
          expect(
            find.text(
              caveatMessage(
                AppLocalizations.of(tester.element(find.text('Caveats'))),
                caveat,
              ),
            ),
            findsOneWidget,
            reason: '$transport / $caveat',
          );
        }
      }
    });
  });
}
