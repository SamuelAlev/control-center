import 'package:cc_data/cc_data.dart' show RigBackendView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_boot_failure.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_states.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _dump =
    'IosSimulatorException: WebDriverAgent did not become ready '
    'after 3 attempt(s): WdaException: invalid screen geometry.\n'
    'stdout:\n'
    'com.facebook.WebDriverAgentRunner.xctestrunner: 57720\n'
    'stderr:\n'
    't = nans Interface orientation changed to Portrait';

void main() {
  group('splitRigFailure', () {
    test('strips nested exception prefixes from the first line', () {
      final parts = splitRigFailure(_dump);
      expect(
        parts.summary,
        'WebDriverAgent did not become ready '
        'after 3 attempt(s): WdaException: invalid screen geometry.',
      );
      expect(parts.details, contains('stdout:'));
      expect(parts.details, contains('stderr:'));
    });

    test('a one-line failure has no details to hide', () {
      final parts = splitRigFailure('The virtual machine exited unexpectedly.');
      expect(parts.summary, 'The virtual machine exited unexpectedly.');
      expect(parts.details, isNull);
    });
  });

  group('RigStart boot failure', () {
    RigBackendView backend() => const RigBackendView(
      backend: 'ios-simulator',
      label: 'iOS Simulator',
      available: true,
      surfaces: [RigTabSurfaces.ios],
      enforcedEgress: false,
    );

    Future<void> pumpStart(WidgetTester tester, {required String error}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rigCapabilitiesProvider.overrideWith((ref) async => [backend()]),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CcTheme(
              data: CcThemeData(
                tokens: DesignSystemTokens.light(),
                brightness: CcBrightness.light,
              ),
              child: Scaffold(
                body: RigStart(
                  surface: RigTabSurfaces.ios,
                  starting: false,
                  error: error,
                  onStart: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a summary and hides the dump until expanded', (
      tester,
    ) async {
      await pumpStart(tester, error: _dump);

      expect(
        find.text(
          'WebDriverAgent did not become ready '
          'after 3 attempt(s): WdaException: invalid screen geometry.',
        ),
        findsOneWidget,
      );
      expect(find.text('Technical details'), findsOneWidget);
      expect(find.textContaining('xctestrunner'), findsNothing);
      expect(find.byKey(const Key('rigBootFailureDetails')), findsNothing);

      await tester.tap(find.text('Technical details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('xctestrunner'), findsOneWidget);
      final dump = tester.widget<ConstrainedBox>(
        find.byKey(const Key('rigBootFailureDetails')),
      );
      expect(dump.constraints.maxHeight, 180);
    });

    testWidgets('a one-line failure does not grow a disclosure', (
      tester,
    ) async {
      await pumpStart(
        tester,
        error: 'The virtual machine exited unexpectedly.',
      );
      expect(
        find.text('The virtual machine exited unexpectedly.'),
        findsOneWidget,
      );
      expect(find.text('Technical details'), findsNothing);
    });
  });
}
