import 'dart:typed_data';

import 'package:cc_infra/src/network/bitbucket/bitbucket_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromBytes(
      Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
      200,
      headers: const {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('getFileBytes uses the src route and ResponseType.bytes', () async {
    final adapter = _CaptureAdapter();
    final client = BitbucketApiClient(Dio()..httpClientAdapter = adapter);
    final bytes = await client.getFileBytes(
      'acme',
      'cc',
      'docs/shot.png',
      'abc123',
    );
    expect(bytes, [0x89, 0x50, 0x4e, 0x47]);
    final req = adapter.last!;
    expect(req.path, '/repositories/acme/cc/src/abc123/docs/shot.png');
    expect(req.responseType, ResponseType.bytes);
  });
}
