import 'package:cc_infra/src/network/gitlab/gitlab_pr_mapper.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_merge_request.dart';
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
}
