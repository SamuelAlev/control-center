import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/device_code_dialog.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required Future<bool> completion,
  }) async {
    late BuildContext host;
    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) {
            host = context;
            return const Text('Account settings');
          },
        ),
      ),
    );
    unawaited(
      showDeviceCodeDialog(
        host,
        providerName: 'GitHub',
        prompt: SignInDeviceCode(
          userCode: 'ABCD-1234',
          verificationUri: '',
          expiresIn: const Duration(minutes: 15),
          completion: completion,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> close(WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
  }

  testWidgets('a tap outside the panel leaves the code up', (tester) async {
    await open(tester, completion: Completer<bool>().future);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(find.text('ABCD-1234'), findsOneWidget);
    await close(tester);
  });

  testWidgets('sign in again waits for this attempt and then closes', (
    tester,
  ) async {
    final attempt = Completer<bool>();
    await open(tester, completion: attempt.future);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('ABCD-1234'), findsOneWidget);

    attempt.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('ABCD-1234'), findsNothing);
  });

  testWidgets('a first login approved before the first check closes', (
    tester,
  ) async {
    await open(tester, completion: Future.value(true));
    await tester.pumpAndSettle();

    expect(find.text('ABCD-1234'), findsNothing);
  });

  testWidgets('approval after manual dismissal does not pop settings', (
    tester,
  ) async {
    final attempt = Completer<bool>();
    await open(tester, completion: attempt.future);
    await close(tester);

    attempt.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Account settings'), findsOneWidget);
    expect(find.text('ABCD-1234'), findsNothing);
  });

  testWidgets('an unsuccessful attempt stops waiting', (tester) async {
    final attempt = Completer<bool>();
    await open(tester, completion: attempt.future);
    attempt.complete(false);
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.signInNotFinished), findsOneWidget);
    expect(find.byType(CcSpinner), findsNothing);
    await close(tester);
  });
}
