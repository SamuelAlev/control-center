import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _NetworkImageTestBinding();

  late Directory root;
  late HttpServer server;
  late Uint8List png;
  late int requests;
  late bool failNetwork;

  setUpAll(() async {
    final image = await createTestImage(width: 2, height: 2);
    png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cc-image-provider-test');
    requests = 0;
    failNetwork = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      if (requests == 1 || failNetwork) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
      } else {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(png);
      }
      await request.response.close();
    });
    installMediaDiskCache(MediaDiskCache(root: root));
  });

  tearDown(() async {
    await server.close(force: true);
    await root.delete(recursive: true);
  });

  String imageUrl() => 'http://${server.address.host}:${server.port}/image.png';

  testWidgets('network fallback survives resize, eviction and reload', (
    tester,
  ) async {
    final provider = ResizeImage(
      DiskCachedNetworkImage(imageUrl(), scale: 2),
      width: 1,
      height: 1,
    );

    final first = await tester.runAsync(() => _resolve(provider));
    expect(first!.image.width, 1);
    expect(first.image.height, 1);
    expect(first.scale, 2);
    first.dispose();
    expect(requests, 2, reason: 'the failed cache fetch falls back to network');

    await provider.evict();
    await tester.pump();

    final reloaded = await tester.runAsync(() => _resolve(provider));
    expect(reloaded!.image.width, 1);
    expect(reloaded.image.height, 1);
    reloaded.dispose();
    expect(requests, 3, reason: 'eviction must allow a fresh, usable codec');

    await provider.evict();
    await tester.pump();
  });

  testWidgets('a failed fallback reports the HTTP error and can recover', (
    tester,
  ) async {
    failNetwork = true;
    final provider = DiskCachedNetworkImage(imageUrl());

    await tester.runAsync(() async {
      await expectLater(
        _resolve(provider),
        throwsA(
          isA<NetworkImageLoadException>()
              .having(
                (error) => error.statusCode,
                'statusCode',
                HttpStatus.serviceUnavailable,
              )
              .having((error) => error.uri, 'uri', Uri.parse(provider.url)),
        ),
      );
    });
    expect(requests, 2);
    await tester.pump();

    failNetwork = false;
    final recovered = await tester.runAsync(() => _resolve(provider));
    expect(recovered!.image.width, 2);
    expect(recovered.image.height, 2);
    recovered.dispose();
    expect(requests, 3);

    await provider.evict();
    await tester.pump();
  });
}

Future<ImageInfo> _resolve(ImageProvider provider) {
  final ready = Completer<ImageInfo>();
  final stream = provider.resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener(
    (image, synchronousCall) => ready.complete(image),
    onError: ready.completeError,
  );
  stream.addListener(listener);
  return ready.future.whenComplete(() => stream.removeListener(listener));
}

class _NetworkImageTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}
