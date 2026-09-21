import 'dart:typed_data';

import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
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
  test(
    'getRawFileBytes uses the raw-file route and ResponseType.bytes',
    () async {
      final adapter = _CaptureAdapter();
      final client = GitLabApiClient(Dio()..httpClientAdapter = adapter);
      final bytes = await client.getRawFileBytes(
        'acme%2Fweb',
        'docs/shot.png',
        'abc123',
      );
      expect(bytes, [0x89, 0x50, 0x4e, 0x47]);
      final req = adapter.last!;
      expect(
        req.path,
        '/projects/acme%2Fweb/repository/files/docs%2Fshot.png/raw',
      );
      expect(req.queryParameters['ref'], 'abc123');
      expect(req.responseType, ResponseType.bytes);
    },
  );
}
