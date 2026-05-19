import 'package:cc_data/cc_data.dart' show RigBackendView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_states.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The boot screen's whole job is answering "what starts when I press this".
/// For a browser surface that answer is the engine's mark — the same logo the
/// tab strip and the guest's own new-tab page carry. These pin that the
/// affordance is the logo, not the generic surface glyph.
void main() {
  RigBackendView backendFor(String surface) => RigBackendView(
    backend: 'smolvm',
    label: 'smolvm',
    available: true,
    surfaces: [surface],
  );

  Future<void> pumpStart(
    WidgetTester tester, {
    required String surface,
    RigBrowserEngine? engine,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rigCapabilitiesProvider.overrideWith(
            (ref) async => [backendFor(surface)],
          ),
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
                surface: surface,
                engine: engine,
                starting: false,
                error: null,
                onStart: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a browser start screen shows its engine\'s mark', (
    tester,
  ) async {
    await pumpStart(
      tester,
      surface: RigTabSurfaces.browser,
      engine: RigBrowserEngine.firefox,
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is BrowserEngineLogo && w.engine == RigBrowserEngine.firefox,
      ),
      findsOneWidget,
    );
    expect(
      find.byIcon(RigTabSurfaces.iconFor(RigTabSurfaces.browser)),
      findsNothing,
      reason: 'The globe is the fallback, never the browser answer.',
    );
  });

  testWidgets('a non-browser surface keeps the generic glyph', (tester) async {
    await pumpStart(tester, surface: RigTabSurfaces.computer);

    expect(find.byType(BrowserEngineLogo), findsNothing);
    expect(
      find.byIcon(RigTabSurfaces.iconFor(RigTabSurfaces.computer)),
      findsOneWidget,
    );
  });
}
