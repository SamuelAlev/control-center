import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/connect/presentation/settings/connect_section.dart';
import 'package:control_center/features/connect/presentation/settings/connect_server_actions.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';
import '../../../helpers/test_wrap.dart';

const _hosted = ConnectStatus(
  mode: ConnectModeSetting.hosted,
  url: 'https://connect.controlcenter.example',
  installId: 'inst_01HZX',
  usable: true,
  epoch: 7,
  lanes: [
    ConnectLaneStatus(lane: 'github', source: ConnectLaneSource.connect),
    ConnectLaneStatus(
      lane: 'google',
      source: ConnectLaneSource.off,
      error: 'Google is not set up on this Connect.',
    ),
  ],
);

Map<String, dynamic> _statusJson(String mode) => {
  'mode': mode,
  'install_id': 'inst_01HZX',
  'usable': true,
};

void main() {
  late AppLocalizations l10n;
  late FakeRpcHost host;
  late List<(String, Map<String, dynamic>)> calls;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    calls = [];
    host = FakeRpcHost()
      ..onCall = (op, args) {
        calls.add((op, args));
        return switch (op) {
          'connect.configure' => _statusJson(args['mode'] as String),
          'connect.test' ||
          'connect.confirmPins' ||
          'connect.rotateKey' => _statusJson('hosted'),
          _ => throw StateError('unexpected op $op'),
        };
      };
  });

  Widget scope(Widget child, {TextDirection? textDirection}) {
    final rpc = host.client();
    addTearDown(rpc.close);
    return ProviderScope(
      overrides: [rpcClientProvider.overrideWithValue(rpc)],
      child: testWrap(
        SingleChildScrollView(child: child),
        textDirection: textDirection,
      ),
    );
  }

  Iterable<String> ops() => calls.map((c) => c.$1);

  /// Room for the whole card, so taps land without scrolling.
  void tall(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('renders nothing for anyone but the server owner', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectStatusProvider.overrideWith((ref) async => null)],
        child: testWrap(const ConnectSection()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SectionCard), findsNothing);
  });

  testWidgets('summarises mode, health, lanes, install id and the CLI', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(scope(const ConnectStatusCard(status: _hosted)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.connectDescription), findsOneWidget);
    expect(find.text(l10n.connectHealthOk), findsOneWidget);
    expect(find.text('inst_01HZX'), findsOneWidget);
    expect(find.text(kConnectCliHint), findsOneWidget);
    expect(find.text('Google is not set up on this Connect.'), findsOneWidget);
    // The saved mode is what is selected; nothing to apply yet.
    expect(find.widgetWithText(CcButton, l10n.apply), findsNothing);
  });

  testWidgets('switching to own apps applies through connect.configure', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(scope(const ConnectStatusCard(status: _hosted)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CcButton, l10n.apply));
    await tester.pumpAndSettle();

    expect(ops(), ['connect.configure']);
    expect(calls.single.$2, {'mode': 'off'});
  });

  testWidgets('a custom Connect needs an HTTPS address before it is sent', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(scope(const ConnectStatusCard(status: _hosted)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.connectModeCustom));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'http://connect.local');
    await tester.pump();
    await tester.tap(find.widgetWithText(CcButton, l10n.apply));
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectCustomUrlInvalid), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(
      find.byType(EditableText),
      'https://connect.example.com',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(CcButton, l10n.apply));
    await tester.pumpAndSettle();
    expect(ops(), ['connect.configure']);
    expect(calls.single.$2, {
      'mode': 'custom',
      'url': 'https://connect.example.com',
    });
  });

  testWidgets('an environment-pinned mode says so and offers no choice', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      scope(
        const ConnectStatusCard(
          status: ConnectStatus(
            mode: ConnectModeSetting.custom,
            url: 'https://connect.example.com',
            locked: true,
            usable: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.connectLocked), findsOneWidget);
    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CcButton, l10n.apply), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('changed signing pins wait for the owner to confirm', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      scope(
        const ConnectStatusCard(
          status: ConnectStatus(
            mode: ConnectModeSetting.hosted,
            error: ConnectHealthError.pinsChanged,
            pendingPins: {'ed25519': 'AAAA', 'next': 'BBBB'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.connectErrorPinsChanged), findsOneWidget);
    expect(find.text(l10n.connectHealthDown), findsOneWidget);
    await tester.tap(find.widgetWithText(CcButton, l10n.connectConfirmPins));
    await tester.pumpAndSettle();
    expect(ops(), ['connect.confirmPins']);
  });

  testWidgets('rotating the key asks first, and cancel sends nothing', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(scope(const ConnectStatusCard(status: _hosted)));
    await tester.pumpAndSettle();

    Future<void> openRotate() async {
      final rotate = find.widgetWithText(CcButton, l10n.connectRotateKey);
      await tester.ensureVisible(rotate);
      await tester.pumpAndSettle();
      await tester.tap(rotate);
      await tester.pumpAndSettle();
      expect(find.text(l10n.connectRotateKeyTitle), findsOneWidget);
    }

    await openRotate();
    await tester.tap(find.widgetWithText(CcButton, l10n.cancel));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await openRotate();
    final confirm = find.descendant(
      of: find.byType(CcDialog),
      matching: find.widgetWithText(CcButton, l10n.connectRotateKey),
    );
    expect(
      tester.widget<CcButton>(confirm).variant,
      CcButtonVariant.destructive,
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(ops(), ['connect.rotateKey']);
    expect(find.text(l10n.connectRotateKeyDone), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('own apps hides the Connect-only actions', (tester) async {
    tall(tester);
    await tester.pumpWidget(
      scope(
        const ConnectStatusCard(
          status: ConnectStatus(mode: ConnectModeSetting.off),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectHealthOff), findsOneWidget);
    expect(find.widgetWithText(CcButton, l10n.connectRotateKey), findsNothing);
    expect(find.widgetWithText(CcButton, l10n.testLabel), findsNothing);
  });

  group('RTL', () {
    testWidgets('radios lead from the right; the URL stays left to right', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        scope(
          const ConnectStatusCard(
            status: ConnectStatus(
              mode: ConnectModeSetting.custom,
              url: 'https://connect.example.com',
              usable: true,
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final title = find.text(l10n.connectModeHosted);
      final radio = find.byType(CcRadio<ConnectModeSetting>).first;
      expect(
        tester.getCenter(radio).dx,
        greaterThan(tester.getCenter(title).dx),
      );
      expect(
        Directionality.of(tester.element(find.byType(EditableText))),
        TextDirection.ltr,
      );
    });
  });
}
