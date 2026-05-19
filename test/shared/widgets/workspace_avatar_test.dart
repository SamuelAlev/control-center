import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal valid 1x1 transparent PNG, so [Image.memory] takes its image
/// branch against real, decodable bytes.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8A'
  'AAMBAQAY3Y2wAAAAAElFTkSuQmCC',
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// A [MediaProxyScope] with a fixed config so the avatar can resolve a
/// `/workspace/logo` URL in tests without a live server connection.
Widget _withProxy(Widget child) => MediaProxyScope(
  config: MediaProxyConfig(
    httpBase: Uri.parse('https://cc.example.com:9030'),
    deviceId: 'test-device',
    psk: 'test-psk',
  ),
  child: _host(child),
);

void main() {
  group('WorkspaceAvatar', () {
    testWidgets('renders the logo image when in-memory bytes are provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(WorkspaceAvatar(logoBytes: _pngBytes, size: 48, name: 'Acme')),
      );

      final image = find.byType(Image);
      expect(image, findsOneWidget);
      expect(tester.widget<Image>(image).image, isA<MemoryImage>());
      // The initial fallback must NOT be shown when a logo renders.
      expect(find.text('A'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'builds a network image from the proxy URL when a logo is configured',
      (tester) async {
        await tester.pumpWidget(
          _withProxy(
            const WorkspaceAvatar(
              workspaceId: 'ws-1',
              hasLogo: true,
              size: 48,
              name: 'Acme',
            ),
          ),
        );

        // The avatar synchronously resolves the proxy URL and builds an
        // [Image.network]. The fetch itself will fail asynchronously (no
        // server) — we only assert the widget shape, then drain the error.
        final image = find.byType(Image);
        expect(image, findsOneWidget);
        final networkImage = tester.widget<Image>(image).image;
        expect(networkImage, isA<NetworkImage>());
        expect((networkImage as NetworkImage).url, contains('/workspace/logo'));
        expect(networkImage.url, contains('w=ws-1'));
        // The initial fallback must NOT be shown.
        expect(find.text('A'), findsNothing);
        // Drain the inevitable async fetch failure.
        await tester.pump();
        await tester.pump();
        tester.takeException();
      },
    );

    testWidgets('falls back to the initial when there is no proxy scope yet', (
      tester,
    ) async {
      // hasLogo is true but no MediaProxyScope is installed (cold start,
      // before the server connection resolves) — the URL is null, so it
      // degrades to the fallback instead of fetching.
      await tester.pumpWidget(
        _host(
          const WorkspaceAvatar(
            workspaceId: 'ws-1',
            hasLogo: true,
            size: 48,
            name: 'Acme',
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the initial when no logo is set', (tester) async {
      await tester.pumpWidget(
        _host(const WorkspaceAvatar(size: 48, name: 'Beta')),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
