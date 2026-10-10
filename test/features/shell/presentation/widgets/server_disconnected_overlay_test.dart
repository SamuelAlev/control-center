import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/features/shell/presentation/widgets/server_disconnected_overlay.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A never-started supervisor that only counts manual retries.
class _FakeSupervisor extends ServerConnectionSupervisor {
  _FakeSupervisor()
    : super(
        descriptor: ConnectionDescriptor(
          serverId: 'srv-1',
          serverName: 'dev',
          fingerprint: '0123456789abcdef',
          paths: const [LoopbackPath(port: 9030)],
        ),
        deviceId: 'dev-1',
        psk: 'psk',
      );

  int retries = 0;

  @override
  void reconnectNow() => retries++;
}

const _connected = ServerConnectionStatus(
  phase: ServerConnectionPhase.connected,
);

void main() {
  late StreamController<ServerConnectionStatus> statuses;
  late _FakeSupervisor supervisor;
  late int signIns;

  setUp(() {
    statuses = StreamController<ServerConnectionStatus>.broadcast();
    supervisor = _FakeSupervisor();
    signIns = 0;
  });

  tearDown(() => statuses.close());

  Future<void> pumpOverlay(
    WidgetTester tester, {
    bool withSignIn = true,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverConnectionStatusProvider.overrideWith((ref) => statuses.stream),
          serverConnectionSupervisorProvider.overrideWithValue(supervisor),
          returnToServerSignInProvider.overrideWithValue(
            withSignIn ? () async => signIns++ : null,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(body: ServerDisconnectedOverlay()),
          ),
        ),
      ),
    );
    statuses.add(_connected);
    await tester.pump();
  }

  /// Unmounts the overlay so its countdown ticker is cancelled.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('renders nothing while connected', (tester) async {
    await pumpOverlay(tester);
    expect(find.text('Lost connection to the server'), findsNothing);
  });

  testWidgets('shows after the grace period and offers retry and sign-in', (
    tester,
  ) async {
    await pumpOverlay(tester);
    statuses.add(
      const ServerConnectionStatus(
        phase: ServerConnectionPhase.reconnecting,
        attempt: 1,
      ),
    );
    await tester.pump();
    // A blip that heals within the grace period never shows the dialog.
    expect(find.text('Lost connection to the server'), findsNothing);

    await tester.pump(ServerDisconnectedOverlay.graceDelay);
    expect(find.text('Lost connection to the server'), findsOneWidget);
    // The first attempt is still in flight.
    expect(find.text('Reconnecting…'), findsOneWidget);

    statuses.add(
      ServerConnectionStatus(
        phase: ServerConnectionPhase.reconnecting,
        attempt: 1,
        nextAttemptAt: DateTime.now().add(const Duration(seconds: 10)),
      ),
    );
    await tester.pump();
    expect(find.text('Next attempt in 10s'), findsOneWidget);

    await tester.tap(find.text('Try to reconnect'));
    expect(supervisor.retries, 1);

    await tester.tap(find.text('Go to sign-in'));
    await tester.pump();
    expect(signIns, 1);

    await unmount(tester);
  });

  testWidgets('goes away once the connection is back', (tester) async {
    await pumpOverlay(tester);
    statuses.add(
      const ServerConnectionStatus(phase: ServerConnectionPhase.reconnecting),
    );
    await tester.pump();
    await tester.pump(ServerDisconnectedOverlay.graceDelay);
    expect(find.text('Lost connection to the server'), findsOneWidget);

    statuses.add(_connected);
    await tester.pump();
    expect(find.text('Lost connection to the server'), findsNothing);
  });

  testWidgets('a rejected device can only go to sign-in', (tester) async {
    await pumpOverlay(tester);
    statuses.add(
      const ServerConnectionStatus(
        phase: ServerConnectionPhase.closed,
        authenticationRejected: true,
      ),
    );
    // One frame delivers the status, the next renders it.
    await tester.pump();
    await tester.pump();

    expect(find.text("Can't reconnect to the server"), findsOneWidget);
    expect(find.text('Try to reconnect'), findsNothing);
    expect(find.text('Go to sign-in'), findsOneWidget);
  });

  testWidgets('hides sign-in where the platform has no sign-in screen', (
    tester,
  ) async {
    await pumpOverlay(tester, withSignIn: false);
    statuses.add(
      const ServerConnectionStatus(phase: ServerConnectionPhase.reconnecting),
    );
    await tester.pump();
    await tester.pump(ServerDisconnectedOverlay.graceDelay);

    expect(find.text('Try to reconnect'), findsOneWidget);
    expect(find.text('Go to sign-in'), findsNothing);

    await unmount(tester);
  });

  testWidgets('lays out right-to-left', (tester) async {
    await pumpOverlay(tester, locale: const Locale('ar'));
    statuses.add(
      const ServerConnectionStatus(phase: ServerConnectionPhase.reconnecting),
    );
    await tester.pump();
    await tester.pump(ServerDisconnectedOverlay.graceDelay);

    expect(tester.takeException(), isNull);
    final title = find.text('انقطع الاتصال بالخادم');
    expect(title, findsOneWidget);
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);

    await unmount(tester);
  });
}
