import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, ServerBuild;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:control_center/features/shell/presentation/widgets/server_shutdown_overlay.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [RemoteRpcClient] stand-in: only `notifications` is exercised.
class _FakeRpcClient implements RemoteRpcClient {
  _FakeRpcClient(this.notifications);

  @override
  final Stream<JsonRpcNotification> notifications;

  @override
  ServerBuild? get serverBuild => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRpcClient.${invocation.memberName}');
}

Widget _materialApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders nothing when inactive', (tester) async {
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(
          _FakeRpcClient(const Stream.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _materialApp(const ServerShutdownOverlay()),
      ),
    );
    await tester.pump();

    expect(find.byType(ServerShutdownOverlay), findsOneWidget);
    expect(find.text('Shutting down'), findsNothing);
  });

  testWidgets('shows title and subtitle when active with no server frames', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(
          _FakeRpcClient(const Stream.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(shutdownProgressProvider.notifier).begin();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _materialApp(const ServerShutdownOverlay()),
      ),
    );
    await tester.pump();

    // Title and subtitle are visible.
    expect(find.text('Shutting down'), findsWidgets);
    expect(find.text('Closing the local server'), findsOneWidget);
  });

  testWidgets('shows service list when server streams begin frame', (
    tester,
  ) async {
    final controller = StreamController<JsonRpcNotification>();
    addTearDown(controller.close);

    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(_FakeRpcClient(controller.stream)),
      ],
    );
    addTearDown(container.dispose);

    // Force the provider to build (subscribe to the stream).
    container.read(shutdownProgressProvider);

    // Emit a begin frame with services.
    controller.add(
      JsonRpcNotification(
        method: 'server/shutdown_progress',
        params: {
          'phase': 'begin',
          'services': ['approvals', 'meetings', 'networking'],
        },
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _materialApp(const ServerShutdownOverlay()),
      ),
    );
    await tester.pump();

    // Title + subtitle.
    expect(find.text('Shutting down'), findsOneWidget);
    expect(find.text('Closing the local server'), findsOneWidget);
    // Service labels (localized).
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Meetings'), findsOneWidget);
    expect(find.text('Networking'), findsOneWidget);
  });

  testWidgets('card has a shadow for visual elevation', (tester) async {
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(
          _FakeRpcClient(const Stream.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(shutdownProgressProvider.notifier).begin();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _materialApp(const ServerShutdownOverlay()),
      ),
    );
    await tester.pump();

    // The card Container should have a BoxDecoration with boxShadow.
    final containers = tester.widgetList<Container>(find.byType(Container));
    final cardContainer = containers.firstWhere(
      (c) => c.decoration is BoxDecoration,
    );
    final decoration = cardContainer.decoration as BoxDecoration;
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('scrim color differs from card background for visibility', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(
          _FakeRpcClient(const Stream.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(shutdownProgressProvider.notifier).begin();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _materialApp(const ServerShutdownOverlay()),
      ),
    );
    await tester.pump();

    // Find the scrim ColoredBox (the first one, wrapping everything).
    final scrim = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).first;
    final t = DesignSystemTokens.light();

    // Scrim should NOT be the same as bgPrimary (which is the card color).
    // This ensures the card is visually distinguishable from the scrim.
    expect(scrim.color, isNot(equals(t.bgPrimary)));
  });
}
