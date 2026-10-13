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

  test(
    'branch history follows cursors and includes all terminal states',
    () async {
      final client = TestHttpClient(
        handler: (request) async {
          final state = request.query!['state'];
          final second = request.query!['page'] == '2';
          if (state != 'MERGED') {
            return httpTextResponse(request, {'values': <Object>[]});
          }
          return httpTextResponse(request, {
            'values': [
              {
                'id': second ? 2 : 1,
                'title': 'PR',
                'state': state,
                'source': {
                  'branch': {'name': 'stack/a'},
                },
              },
            ],
            if (!second)
              'next':
                  'https://api.bitbucket.org/2.0/pullrequests?'
                  '${Uri(queryParameters: {...?request.query, 'page': '2'}).query}',
          });
        },
      );
      final prs = await BitbucketApiClient(
        client,
      ).listPullRequestsForBranch('acme', 'repo', 'stack/a');
      expect(prs.map((pr) => pr.id), [1, 2]);
      expect(client.requests, hasLength(5));
      expect(client.requests.first.query!['q'], 'source.branch.name="stack/a"');
      expect(client.requests.map((r) => r.query!['state']).toSet(), {
        'OPEN',
        'MERGED',
        'DECLINED',
        'SUPERSEDED',
      });
    },
  );
}
