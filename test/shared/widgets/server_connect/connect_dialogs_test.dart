import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/pairing_link.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/server_connect/connect_dialog_host.dart';
import 'package:control_center/shared/widgets/server_connect/pairing_link_dialog.dart';
import 'package:control_center/shared/widgets/server_connect/server_connect_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoServerDiscovery extends ServerDiscovery {
  const _NoServerDiscovery();

  @override
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) => const Stream.empty();
}

final String _link = buildPairingLink(
  origin: 'https://cc.example.com',
  server: 'wss://cc.example.com:9030/rpc',
  deviceId: 'device-1',
  psk: 'secret',
);

/// Hosts a surface the way the web gate does: no app-level Navigator.
Widget _app(WidgetBuilder builder) {
  final theme = CcThemeData.light();
  return CcTheme(
    data: theme,
    child: WidgetsApp(
      color: theme.tokens.bgPrimary,
      supportedLocales: kSupportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, _) => ConnectDialogHost(builder: builder),
    ),
  );
}

Future<void> _open(WidgetTester tester, WidgetBuilder dialog) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(
      (context) => CcButton(
        onPressed: () =>
            unawaited(showCcDialog<void>(context: context, builder: dialog)),
        child: const Text('Open'),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(CcTextField)),
  matching: find.byType(EditableText),
);

void main() {
  group('PairingLinkDialog', () {
    testWidgets('shows where a link leads and connects only on Connect', (
      tester,
    ) async {
      final connected = <ServerConnectCredentials>[];
      await _open(
        tester,
        (_) => PairingLinkDialog(onConnect: (c) async => connected.add(c)),
      );

      await tester.enterText(find.byType(EditableText), _link);
      await tester.pumpAndSettle();
      expect(find.text('wss://cc.example.com:9030/rpc'), findsOneWidget);
      expect(connected, isEmpty, reason: 'A paste must never connect');

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(connected.single, (
        rawUrl: 'wss://cc.example.com:9030/rpc',
        inviteCode: '',
        deviceId: 'device-1',
        psk: 'secret',
      ));
      expect(find.byType(PairingLinkDialog), findsNothing);
    });

    testWidgets('does not show the credential it was pasted', (tester) async {
      await _open(tester, (_) => PairingLinkDialog(onConnect: (_) async {}));
      await tester.enterText(find.byType(EditableText), _link);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });

    testWidgets('an unusable link explains itself and cannot connect', (
      tester,
    ) async {
      var attempts = 0;
      await _open(
        tester,
        (_) => PairingLinkDialog(onConnect: (_) async => attempts++),
      );

      await tester.enterText(find.byType(EditableText), 'https://example.com');
      await tester.pumpAndSettle();
      expect(find.textContaining("That isn't a Control"), findsOneWidget);

      await tester.tap(find.text('Connect'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(attempts, 0);
    });

    testWidgets('a failed connection stays beside the link for a retry', (
      tester,
    ) async {
      await _open(
        tester,
        (_) => PairingLinkDialog(
          onConnect: (_) async =>
              throw const UserFacingMessage('Server unavailable'),
        ),
      );
      await tester.enterText(find.byType(EditableText), _link);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.byType(PairingLinkDialog), findsOneWidget);
    });
  });

  group('ServerConnectDialog', () {
    ServerConnectDialog dialog({
      Future<void> Function(ServerConnectCredentials)? onConnect,
      String prefillUrl = 'wss://host:9030/rpc',
      String prefillPsk = '',
    }) => ServerConnectDialog(
      title: 'Connect to a server',
      prefillUrl: prefillUrl,
      prefillPsk: prefillPsk,
      discovery: const _NoServerDiscovery(),
      onConnect: onConnect,
    );

    testWidgets('rejects an invalid address without connecting', (
      tester,
    ) async {
      var attempts = 0;
      await _open(
        tester,
        (_) =>
            dialog(prefillUrl: 'ftp://h', onConnect: (_) async => attempts++),
      );

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(attempts, 0);
      expect(find.byType(ConnectionErrorAlert), findsOneWidget);
      expect(find.byType(ServerConnectDialog), findsOneWidget);
    });

    testWidgets('a failure keeps the dialog and every typed value', (
      tester,
    ) async {
      await _open(
        tester,
        (_) => dialog(
          onConnect: (_) async => throw const UserFacingMessage('Refused'),
        ),
      );

      await tester.enterText(_field('Invite code'), 'one-time-code');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Refused'), findsOneWidget);
      expect(find.byType(ServerConnectDialog), findsOneWidget);
      expect(find.text('one-time-code'), findsOneWidget);
    });

    testWidgets('closes itself once the connection succeeds', (tester) async {
      ServerConnectCredentials? sent;
      await _open(tester, (_) => dialog(onConnect: (c) async => sent = c));

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(sent?.rawUrl, 'wss://host:9030/rpc');
      expect(find.byType(ServerConnectDialog), findsNothing);
    });

    testWidgets('pops the credentials when the caller connects them itself', (
      tester,
    ) async {
      ServerConnectCredentials? popped;
      await tester.pumpWidget(
        _app(
          (context) => CcButton(
            onPressed: () async {
              popped = await showCcDialog<ServerConnectCredentials>(
                context: context,
                builder: (_) => dialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(popped?.rawUrl, 'wss://host:9030/rpc');
    });

    testWidgets('the pairing key is folded until asked for', (tester) async {
      await _open(tester, (_) => dialog());
      expect(find.text('Pairing key').hitTestable(), findsNothing);

      await tester.tap(find.text('Use a pairing key'));
      await tester.pumpAndSettle();
      expect(find.text('Pairing key').hitTestable(), findsOneWidget);
    });

    testWidgets('an invite replaces the pairing key entirely', (tester) async {
      await _open(tester, (_) => dialog());
      await tester.enterText(_field('Invite code'), 'code');
      await tester.pumpAndSettle();
      expect(find.text('Use a pairing key'), findsNothing);
    });

    testWidgets('a prefilled key opens unfolded for review', (tester) async {
      await _open(tester, (_) => dialog(prefillPsk: 'secret'));
      expect(find.text('Pairing key').hitTestable(), findsOneWidget);
    });
  });

  testWidgets('the dialog host rebuilds its surface with its parent', (
    tester,
  ) async {
    late StateSetter update;
    var label = 'before';
    final theme = CcThemeData.light();
    await tester.pumpWidget(
      CcTheme(
        data: theme,
        child: WidgetsApp(
          color: theme.tokens.bgPrimary,
          builder: (context, _) => StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return ConnectDialogHost(builder: (_) => Text(label));
            },
          ),
        ),
      ),
    );
    expect(find.text('before'), findsOneWidget);

    update(() => label = 'after');
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
  });
}
