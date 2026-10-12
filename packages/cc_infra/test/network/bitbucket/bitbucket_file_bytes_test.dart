import 'package:cc_infra/src/network/bitbucket/bitbucket_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

void main() {
  test('getFileBytes uses the src route and asks for bytes', () async {
    final client = TestHttpClient(
      handler: (request) async => httpBytesResponse(
        request,
        const [0x89, 0x50, 0x4e, 0x47],
        headers: const {'content-type': 'application/octet-stream'},
      ),
    );
    final api = BitbucketApiClient(client);

    final bytes = await api.getFileBytes(
      'acme',
      'cc',
      'docs/shot.png',
      'abc123',
    );

    expect(bytes, [0x89, 0x50, 0x4e, 0x47]);
    final request = client.requests.single;
    expect(request.url, '/repositories/acme/cc/src/abc123/docs/shot.png');
    expect(request.expectBody, HttpExpectBody.bytes);
  });
}
