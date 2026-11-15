import 'package:cc_data/cc_data.dart' show ConnectModeSetting, ConnectStatus;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_connect_step.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

const _manifestUrl = 'https://github.com/settings/apps/new?state=m1';

void main() {
  late AppLocalizations l10n;
  late List<(String, Map<String, dynamic>)> calls;
  late List<String> opened;
  late int continued;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  setUp(() {
    calls = [];
    opened = [];
    continued = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    ConnectStatus status = const ConnectStatus(mode: ConnectModeSetting.unset),
    TextDirection? textDirection,
    bool refuse = false,
  }) async {
    final host = FakeRpcHost()
      ..onCall = (op, args) {
        calls.add((op, args));
        if (refuse) {
          throw StateError('Connect is unreachable.');
        }
        return switch (op) {
          'connect.configure' => {'mode': args['mode']},
          'github.manifest.begin' => {'url': _manifestUrl},
          _ => throw StateError('unexpected op $op'),
        };
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          connectStatusProvider.overrideWith((ref) async => status),
          externalUrlOpenerProvider.overrideWithValue((url) {
            opened.add(url);
            return true;
          }),
        ],
        child: testWrap(
          OnboardingConnectStep(onContinue: () => continued++),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  CcButton continueButton(WidgetTester tester) => tester.widget<CcButton>(
    find.widgetWithText(CcButton, l10n.continueLabel),
  );

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(CcButton, l10n.continueLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the three options with none chosen', (tester) async {
    await pump(tester);
    expect(find.text(l10n.connectModeHosted), findsOneWidget);
    expect(find.text(l10n.connectModeOwn), findsOneWidget);
    expect(find.text(l10n.connectModeCustom), findsOneWidget);
    // The disclosure under Control Center's apps is shown before choosing.
    expect(find.text(l10n.connectModeHostedDisclosure), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets("choosing Control Center's apps saves hosted and continues", (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l10n.connectModeHosted));
    await tester.pump();
    await tapContinue(tester);

    expect(calls.map((c) => c.$1), ['connect.configure']);
    expect(calls.single.$2, {'mode': 'hosted'});
    expect(continued, 1);
  });

  testWidgets('own apps offers to create the GitHub App right away', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pump();
    expect(find.text(l10n.onboardingConnectOwnNext), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CcButton, l10n.providerAppCreateGitHub),
    );
    await tester.pumpAndSettle();
    expect(opened, [_manifestUrl]);
    // Creating the app does not pick the mode for the operator.
    expect(continued, 0);

    await tapContinue(tester);
    expect(calls.last.$2, {'mode': 'off'});
    expect(continued, 1);
  });

  testWidgets('a custom Connect must be an HTTPS address', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l10n.connectModeCustom));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'connect.example.com');
    await tapContinue(tester);
    expect(find.text(l10n.connectCustomUrlInvalid), findsOneWidget);
    expect(calls, isEmpty);
    expect(continued, 0);

    await tester.enterText(
      find.byType(EditableText),
      'https://connect.example.com',
    );
    await tapContinue(tester);
    expect(calls.single.$2, {
      'mode': 'custom',
      'url': 'https://connect.example.com',
    });
    expect(continued, 1);
  });

  testWidgets('a refused save stays on the step and says why', (tester) async {
    await pump(tester, refuse: true);
    await tester.tap(find.text(l10n.connectModeHosted));
    await tester.pump();
    await tapContinue(tester);

    expect(find.textContaining('Connect is unreachable.'), findsOneWidget);
    expect(continued, 0);
  });

  testWidgets('an environment-pinned mode is shown locked; Continue moves on', (
    tester,
  ) async {
    await pump(
      tester,
      status: const ConnectStatus(
        mode: ConnectModeSetting.custom,
        url: 'https://connect.example.com',
        locked: true,
      ),
    );
    expect(find.text(l10n.connectLocked), findsOneWidget);
    await tester.tap(find.text(l10n.connectModeHosted));
    await tester.pump();
    await tapContinue(tester);
    expect(calls, isEmpty);
    expect(continued, 1);
  });

  group('RTL', () {
    testWidgets('mirrors the options and the footer', (tester) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);

      final title = find.text(l10n.connectModeOwn);
      final radio = find.byType(CcRadio<ConnectModeSetting>).at(1);
      expect(
        tester.getCenter(radio).dx,
        greaterThan(tester.getCenter(title).dx),
      );
      // Continue sits at the end edge, which is the left in RTL.
      final next = tester.getCenter(
        find.widgetWithText(CcButton, l10n.continueLabel),
      );
      expect(next.dx, lessThan(tester.getCenter(title).dx));
    });

    testWidgets('keeps the custom URL left to right', (tester) async {
      await pump(tester, textDirection: TextDirection.rtl);
      await tester.tap(find.text(l10n.connectModeCustom));
      await tester.pump();
      expect(
        Directionality.of(tester.element(find.byType(EditableText))),
        TextDirection.ltr,
      );
    });
  });
}
