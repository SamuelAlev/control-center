import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/features/auth/presentation/screens/signed_out_screen.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The re-authentication screen an operator lands on when their forge
/// credential lapses after a completed setup.
///
/// What these pin is that it stays the SMALL screen: the whole reason it exists
/// is that first-run onboarding asks for things this operator already has, so a
/// step indicator or a workspace form appearing here would be the regression.
void main() {
  Widget wrap({
    List<ForgeConnection> connections = const [],
    Map<String, SignInProvider> signIn = const {},
  }) => ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
      forgeConnectionsProvider.overrideWith((ref) async => connections),
      signInProvidersProvider.overrideWith((ref) async => signIn),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(data: CcThemeData.light(), child: const SignedOutScreen()),
    ),
  );

  testWidgets('says the connection lapsed, not that setup is unfinished', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    // The shader background tickers every frame, so the tree never
    // settles — pump the async provider reads through explicitly.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.signedOutTitle), findsOneWidget);
    expect(find.text(l10n.signedOutSubtitle), findsOneWidget);
  });

  testWidgets('offers a sign-in for every supported forge', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    for (final forge in ForgeHost.supported) {
      expect(
        find.text(forge.displayName),
        findsOneWidget,
        reason: 'missing row for ${forge.name}',
      );
    }
  });

  testWidgets('shows NO step indicator — there is one thing to do', (
    tester,
  ) async {
    // A progress bar over a single action promises steps that never come, and
    // it is the visual cue that says "you are being set up again".
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(OnboardingStepIndicator), findsNothing);
  });

  testWidgets('shows no continue button — the router leaves on its own', (
    tester,
  ) async {
    // Signing back in flips the onboarding gate, and `onboardingGuard` routes
    // away from this screen. A button here would either duplicate that or sit
    // disabled, implying the sign-in did not take.
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.widgetWithText(CcButton, l10n.continueLabel), findsNothing);
  });

  testWidgets('keeps the paste-a-token path when the server has no app', (
    tester,
  ) async {
    // A server with no OAuth app configured cannot run a browser sign-in, and
    // this screen is a hard gate — with no token path such an operator would
    // have no way out of it at all.
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.widgetWithText(CcButton, l10n.addToken), findsWidgets);
  });

  testWidgets('the background moves the window — nothing else here can', (
    tester,
  ) async {
    // This screen and onboarding are drawn OUTSIDE the shell, so the app's own
    // title bar — the only thing that moves a window that is deliberately not
    // system-movable (`styleWindowOnShow` sets `isMovable = false`) — is not on
    // screen. Without the frame's own drag area the operator is stuck with a
    // window they cannot move, at the one moment they have reached nothing else.
    var dragStarts = 0;
    WindowDragArea.debugOnStartDrag = () => dragStarts++;
    // The manual-move path reads the OS cursor and repositions the window on
    // every update; neither exists under `flutter_tester`.
    WindowDragArea.debugCursorPosition = () => Offset.zero;
    WindowDragArea.debugOnMoveTo = (_) {};
    addTearDown(() {
      WindowDragArea.debugOnStartDrag = null;
      WindowDragArea.debugCursorPosition = null;
      WindowDragArea.debugOnMoveTo = null;
    });

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Top-left corner: clear of the centred card and of the theme toggle
    // opposite it. Jitter by ~10px — past the 1px pan slop a mouse gets, so the
    // recognizer commits.
    final gesture = await tester.startGesture(
      const Offset(24, 24),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(8, 6));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    // Not `pumpAndSettle`: the shader background tickers every frame, so the
    // tree never settles.
    await tester.pump();

    expect(dragStarts, 1);
  });
}
