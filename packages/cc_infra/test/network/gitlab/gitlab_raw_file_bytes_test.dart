import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

void main() {
  test('getRawFileBytes uses the raw-file route and asks for bytes', () async {
    final client = TestHttpClient(
      handler: (request) async => httpBytesResponse(
        request,
        const [0x89, 0x50, 0x4e, 0x47],
        headers: const {'content-type': 'application/octet-stream'},
      ),
    );
    final api = GitLabApiClient(client);

    final bytes = await api.getRawFileBytes(
      'acme%2Fweb',
      'docs/shot.png',
      'abc123',
    );

    expect(bytes, [0x89, 0x50, 0x4e, 0x47]);
    final request = client.requests.single;
    expect(
      request.url,
      '/projects/acme%2Fweb/repository/files/docs%2Fshot.png/raw',
    );
    expect(request.query, {'ref': 'abc123'});
    expect(request.expectBody, HttpExpectBody.bytes);
  });
}
