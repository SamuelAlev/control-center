import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lanServer = DiscoveredServer(
    name: 'Basement Mac',
    host: '192.168.1.20',
    port: 9030,
    serverId: 's-lan',
    fingerprintPrefix: 'abc',
    tls: true,
  );
  const tailnetServer = DiscoveredServer(
    name: 'devbox',
    host: 'devbox.tail1234.ts.net',
    port: 9030,
    serverId: 's-ts',
    fingerprintPrefix: 'def',
    tls: true,
    source: DiscoverySource.tailscale,
  );

  Future<void> pumpButton(
    WidgetTester tester, {
    required ServerDiscovery discovery,
    required ValueChanged<DiscoveredServer> onSelected,
    Set<String> excludeServerIds = const {},
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: CcTextField(
                  suffix: ServerDiscoveryButton(
                    discovery: discovery,
                    excludeServerIds: excludeServerIds,
                    onSelected: onSelected,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('button inside the field suffix, badge reflects the scan', (
    tester,
  ) async {
    await pumpButton(
      tester,
      discovery: _FakeServerDiscovery(const [lanServer, tailnetServer]),
      onSelected: (_) {},
    );
    await tester.pumpAndSettle();

    // The suffix button renders inside the CcTextField without overflow and
    // the scan result badges it with the found count.
    expect(find.byType(CcIconButton), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the dialog, lists both sources, pick reports the server', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    DiscoveredServer? selected;
    await pumpButton(
      tester,
      discovery: _FakeServerDiscovery(const [lanServer, tailnetServer]),
      onSelected: (server) => selected = server,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();

    // Dialog lists both servers with their source badges.
    expect(find.text(l10n.serverDiscoveryTitle), findsOneWidget);
    expect(find.text('Basement Mac'), findsOneWidget);
    expect(find.text('devbox'), findsOneWidget);
    expect(find.text('192.168.1.20:9030'), findsOneWidget);
    expect(find.text(l10n.connectionPathLan), findsOneWidget);
    expect(find.text(l10n.connectionPathTailnet), findsOneWidget);

    await tester.tap(find.text('devbox'));
    await tester.pumpAndSettle();

    expect(selected, tailnetServer);
    expect(find.text(l10n.serverDiscoveryTitle), findsNothing);
  });

  testWidgets('excludeServerIds hides already-paired servers', (tester) async {
    await pumpButton(
      tester,
      discovery: _FakeServerDiscovery(const [lanServer, tailnetServer]),
      excludeServerIds: const {'s-lan'},
      onSelected: (_) {},
    );
    await tester.pumpAndSettle();
    // Only the tailnet server counts toward the badge.
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();
    expect(find.text('Basement Mac'), findsNothing);
    expect(find.text('devbox'), findsOneWidget);
  });

  testWidgets('empty result shows the empty state after the scan completes', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await pumpButton(
      tester,
      discovery: _FakeServerDiscovery(const []),
      onSelected: (_) {},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.serverDiscoveryEmpty), findsOneWidget);
    expect(find.text(l10n.serverDiscoveryRefresh), findsOneWidget);
  });
}

/// Emits one fixed snapshot, then completes.
class _FakeServerDiscovery extends ServerDiscovery {
  _FakeServerDiscovery(this.results);

  final List<DiscoveredServer> results;

  @override
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) => Stream.value(results);
}
