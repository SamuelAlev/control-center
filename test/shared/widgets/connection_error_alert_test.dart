import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/invite_redeemer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('ConnectionErrorAlert', () {
    testWidgets(
      'shows friendly copy for an unreachable server and hides the raw '
      'exception until technical details are expanded',
      (tester) async {
        // The exact failure from the connect gate: a NoReachablePathException
        // whose toString() dumps per-path probe internals.
        const error =
            NoReachablePathException('28365cf1-d44b-4fb8-9e62-4107aa118354', [
              'lo: TimeoutException after 0:00:02.000000: Future not completed',
              'rly: relay probe failed',
            ]);
        await tester.pumpWidget(
          _wrap(const ConnectionErrorAlert(error: error)),
        );

        expect(find.text('Could not connect'), findsOneWidget);
        expect(
          find.textContaining("couldn't reach the server"),
          findsOneWidget,
        );
        // No cryptic dump by default.
        expect(find.textContaining('NoReachablePathException'), findsNothing);
        expect(find.textContaining('relay probe failed'), findsNothing);

        // Expanding the details keeps the diagnostics reachable.
        await tester.tap(find.text('Technical details'));
        await tester.pumpAndSettle();
        expect(find.textContaining('NoReachablePathException'), findsOneWidget);
        expect(find.textContaining('relay probe failed'), findsOneWidget);
      },
    );

    testWidgets('maps an auth rejection to credential copy', (tester) async {
      const error = AuthRejectedException('Server auth proof mismatch');
      await tester.pumpWidget(_wrap(const ConnectionErrorAlert(error: error)));

      expect(
        find.textContaining('The server rejected this device'),
        findsOneWidget,
      );
      expect(find.textContaining('auth proof mismatch'), findsNothing);
    });

    testWidgets('an identity mismatch explains the re-pair path', (
      tester,
    ) async {
      const error = ServerIdentityMismatchException(
        expectedFingerprint: 'aaaa',
        actualFingerprint: 'bbbb',
      );
      await tester.pumpWidget(_wrap(const ConnectionErrorAlert(error: error)));

      expect(find.textContaining("identity doesn't match"), findsOneWidget);
    });

    testWidgets(
      'unknown errors fall back to generic copy with the raw text behind '
      'the details toggle',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ConnectionErrorAlert(error: StateError('weird io failure'))),
        );

        expect(
          find.textContaining('Something went wrong while connecting'),
          findsOneWidget,
        );
        expect(find.textContaining('weird io failure'), findsNothing);

        await tester.tap(find.text('Technical details'));
        await tester.pumpAndSettle();
        expect(find.textContaining('weird io failure'), findsOneWidget);
      },
    );

    testWidgets('a UserFacingMessage renders verbatim with no details toggle', (
      tester,
    ) async {
      const message = 'Enter a valid ws:// or wss:// server URL.';
      await tester.pumpWidget(
        _wrap(const ConnectionErrorAlert(error: UserFacingMessage(message))),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.text('Technical details'), findsNothing);
    });

    testWidgets('an invalid or expired invite gets actionable copy', (
      tester,
    ) async {
      const error = InviteRejectedException('Invite is invalid or expired');
      await tester.pumpWidget(_wrap(const ConnectionErrorAlert(error: error)));

      expect(
        find.textContaining('invite code is invalid or has expired'),
        findsOneWidget,
      );
      expect(find.textContaining('Ask for a fresh one'), findsOneWidget);
    });

    testWidgets('honours a title override', (tester) async {
      const error = AuthRejectedException('Server auth proof mismatch');
      await tester.pumpWidget(
        _wrap(const ConnectionErrorAlert(error: error, title: 'Switch failed')),
      );

      expect(find.text('Switch failed'), findsOneWidget);
      expect(find.text('Could not connect'), findsNothing);
    });
  });
}
