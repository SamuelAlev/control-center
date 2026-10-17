@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/sent_attachments.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  textStyle: const TextStyle(
    fontSize: 14,
    color: Color(0xFF202020),
    decoration: TextDecoration.none,
  ),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: CcTheme(
    data: CcThemeData.light(),
    child: Center(child: child),
  ),
);

Future<void> _pumpUntil(WidgetTester tester, Finder target) async {
  final elapsed = Stopwatch()..start();
  while (target.evaluate().isEmpty &&
      elapsed.elapsed < const Duration(seconds: 5)) {
    // Image decoding completes on the browser's event loop, not fake time.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(target, findsOneWidget);
}

Finder _decodedImage() => find.byWidgetPredicate(
  (widget) => widget is RawImage && widget.image != null,
);

void main() {
  testWidgets('desktop catalog screenshot resolves in its message workspace', (
    tester,
  ) async {
    final hash = List.filled(64, 'a').join();
    final attachments = MessageAttachment.attachmentsFromMetadata({
      'attachments': [
        {
          'id': 'desktop-draft',
          'fileId': 'catalog-file-1',
          'path': 'blob:sha256:$hash',
          'name': 'screenshot.png',
          'kind': 'image',
          'mediaType': 'image/png',
          'order': 0,
        },
      ],
    });
    final endpoint = RemoteMediaEndpoint(
      httpBase: Uri.parse('https://phone.example/_cc_resource/session/'),
      deviceId: 'phone',
      psk: 'paired-key',
    );
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
      ),
    );
    Uri? requested;
    String? requestedMethod;
    final resourceServer = RemoteResourceServer(
      serverChannel,
      onRequest: (request) async {
        requested = request.uri;
        requestedMethod = request.method;
        return RemoteResourceResponse(
          statusCode: 200,
          headers: const {
            'content-type': ['image/png'],
          },
          body: Stream<Uint8List>.value(png),
        );
      },
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteRpcClient(clientChannel)..start();
    addTearDown(clientChannel.close);
    addTearDown(resourceServer.close);
    addTearDown(client.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaEndpointProvider.overrideWith((ref) async* {
            yield endpoint;
          }),
          rpcClientProvider.overrideWith((ref) async* {
            yield client;
          }),
          activeWorkspaceIdProvider.overrideWith((ref) async* {
            yield 'other-workspace';
          }),
        ],
        child: _host(
          SentAttachments(
            attachments: attachments,
            workspaceId: 'message-workspace',
            alignEnd: false,
          ),
        ),
      ),
    );
    await _pumpUntil(tester, _decodedImage());
    expect(find.byType(CcExpandableImage), findsOneWidget);
    expect(requestedMethod, 'GET');
    expect(requested?.path, '/blob');
    expect(requested?.queryParameters['w'], 'message-workspace');
    expect(requested?.queryParameters['h'], hash);
    expect(
      RemoteControlCrypto.verifyProxyTarget(
        'blob:message-workspace:$hash',
        endpoint.psk,
        requested!.queryParameters['s']!,
      ),
      isTrue,
    );
  });

  testWidgets('failed image offers retry and loads when resource returns', (
    tester,
  ) async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
      ),
    );
    var attempts = 0;
    final resourceServer = RemoteResourceServer(
      serverChannel,
      onRequest: (_) async => RemoteResourceResponse(
        statusCode: ++attempts == 1 ? 503 : 200,
        headers: const {
          'content-type': ['image/png'],
        },
        body: Stream<Uint8List>.value(png),
      ),
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteRpcClient(clientChannel)..start();
    addTearDown(clientChannel.close);
    addTearDown(resourceServer.close);
    addTearDown(client.close);
    final endpoint = RemoteMediaEndpoint(
      httpBase: Uri.parse('https://phone.example/_cc_resource/session/'),
      deviceId: 'phone',
      psk: 'paired-key',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaEndpointProvider.overrideWith((ref) async* {
            yield endpoint;
          }),
          rpcClientProvider.overrideWith((ref) async* {
            yield client;
          }),
        ],
        child: _host(
          SentAttachments(
            workspaceId: 'message-workspace',
            alignEnd: false,
            attachments: [
              MessageAttachment(
                id: 'image-1',
                path: 'blob:sha256:${'a' * 64}',
                name: 'screenshot.png',
                kind: AttachmentKind.image,
              ),
            ],
          ),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('Retry'));
    expect(find.byType(CcExpandableImage), findsNothing);
    await tester.tap(find.text('Retry'));
    await _pumpUntil(tester, _decodedImage());
    expect(attempts, 2);
    expect(find.byType(CcExpandableImage), findsOneWidget);
  });
}
