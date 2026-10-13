import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
import 'package:cc_infra/src/network/gitlab/gitlab_pr_mapper.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_merge_request.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:test/test.dart';

void main() {
  group('GitLabMergeRequest labels', () {
    test('reads names-only list entries', () {
      final mr = GitLabMergeRequest.fromJson({
        'id': 9,
        'iid': 3,
        'title': 't',
        'state': 'opened',
        'labels': ['bug', '', 'frontend'],
      });
      expect(mr.labels.map((l) => l.name), ['bug', 'frontend']);
      expect(mr.labels.every((l) => l.color.isEmpty), isTrue);
    });

    test('reads with_labels_details objects and strips the hash', () {
      final mr = GitLabMergeRequest.fromJson({
        'id': 9,
        'iid': 3,
        'title': 't',
        'state': 'opened',
        'labels': [
          {
            'name': 'bug',
            'color': '#d73a4a',
            'description': 'Something is wrong',
          },
          {'title': 'docs', 'color': '0075ca'},
          {'name': ''},
        ],
      });
      expect(mr.labels, hasLength(2));
      expect(mr.labels.first.name, 'bug');
      expect(mr.labels.first.color, '#d73a4a');
      expect(mr.labels.first.description, 'Something is wrong');
      expect(mr.labels.last.name, 'docs');

      final pr = pullRequestFromGitLab(mr, repoFullName: 'o/r');
      expect(pr.labels.map((l) => l.name), ['bug', 'docs']);
      expect(pr.labels.first.color, 'd73a4a');
      expect(pr.labels.last.color, '0075ca');
      expect(pr.labels.first.description, 'Something is wrong');
    });
  });

  test(
    'branch history requests all merge-request states by source branch',
    () async {
      final http = TestHttpClient(
        handler: (request) async => httpTextResponse(request, [
          {
            'id': 101,
            'iid': 1,
            'title': 'merged',
            'state': 'merged',
            'source_branch': 'stack/a',
          },
          {
            'id': 102,
            'iid': 2,
            'title': 'closed',
            'state': 'closed',
            'source_branch': 'stack/a',
          },
        ]),
      );
      final api = GitLabApiClient(http);
      final page = await api.listMergeRequests(
        GitLabApiClient.encodeProjectPath('group/repo'),
        state: 'all',
        sourceBranch: 'stack/a',
      );
      expect(page.items.map((mr) => mr.state), ['merged', 'closed']);
      final request = http.requests.single;
      expect(request.query!['state'], 'all');
      expect(request.query!['source_branch'], 'stack/a');
      expect(request.url, '/projects/group%2Frepo/merge_requests');
    },
  );
}
