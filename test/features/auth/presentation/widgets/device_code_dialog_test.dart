import 'dart:async';

import 'package:control_center/features/auth/presentation/widgets/device_code_dialog.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// The device-code dialog has to stay up long enough to read the code.
///
/// Two ways it used to vanish: the scrim ate the click that brought the window
/// back from the browser, and a row that was already signed in matched the
/// first poll ("sign in again") and popped itself.
void main() {
  const prompt = SignInDeviceCode(
    userCode: 'ABCD-1234',
    verificationUri: '',
    expiresIn: Duration(minutes: 15),
  );

  Future<void> open(
    WidgetTester tester, {
    required Future<bool> Function() connected,
  }) async {
    late BuildContext host;
    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showDeviceCodeDialog(
        host,
        providerName: 'GitHub',
        prompt: prompt,
        connected: connected,
      ),
    );
    // Paint the dialog without draining the sign-in poll, which waits in
    // two-second slices for up to ten minutes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> finish(WidgetTester tester) async {
    if (find.text('ABCD-1234').evaluate().isEmpty) {
      return;
    }
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.close));
    // The exit animation has to finish so dispose cancels the poll timer.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a tap outside the panel leaves the code up', (tester) async {
    await open(tester, connected: () async => false);

    expect(find.text('ABCD-1234'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(find.text('ABCD-1234'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('an already-connected forge does not dismiss the code', (
    tester,
  ) async {
    await open(tester, connected: () async => true);
    // The baseline read is async; give it a turn, then the interval the old
    // watch used before it popped.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('ABCD-1234'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the dialog closes once a new connection lands', (tester) async {
    var connected = false;
    await open(tester, connected: () async => connected);

    // Baseline sees "not connected", then the poll waits two seconds.
    await tester.pump();
    connected = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ABCD-1234'), findsNothing);
    await finish(tester);
  });
}
