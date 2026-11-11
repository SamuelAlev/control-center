import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/network/bitbucket/bitbucket_pr_mapper.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pull_request.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/gitlab/gitlab_pr_mapper.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_merge_request.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:test/test.dart';

/// The approval guard matches a pull request's author to the approver by the
/// forge's durable account id, so every mapper must carry it.
void main() {
  test('Bitbucket authors carry account_id beside the nickname login', () {
    final user = prUserFromBitbucket(
      BitbucketUser.fromJson({
        'uuid': '{u-1}',
        'account_id': '557058:abc',
        'nickname': 'jdoe',
        'display_name': 'Jane Doe',
      }),
    );
    expect(user.login, 'jdoe');
    expect(user.accountId, '557058:abc');
    expect(prUserFromBitbucket(null).accountId, isEmpty);
  });

  test('GitLab authors carry the numeric id beside the username', () {
    final user = prUserFromGitLab(
      GitLabUser.fromJson({'id': 42, 'username': 'gl-jdoe', 'name': 'J'}),
    );
    expect(user.login, 'gl-jdoe');
    expect(user.accountId, '42');
    expect(
      prUserFromGitLab(GitLabUser.fromJson({'username': 'x'})).accountId,
      isEmpty,
    );
  });

  test('GitHub authors carry the numeric id when the source has one', () {
    GitHubPullRequest pr(GitHubUser author) => GitHubPullRequest(
      number: 1,
      title: 't',
      body: '',
      state: 'open',
      isDraft: false,
      userLogin: author.login,
      htmlUrl: 'https://gh/p/1',
      externalId: 'NODE_1',
      author: author,
      headRef: 'feature/x',
    );
    expect(
      pullRequestFromGitHub(
        pr(const GitHubUser(login: 'octo', avatarUrl: '', id: 7)),
        repoFullName: 'o/r',
      ).author?.accountId,
      '7',
    );
    expect(
      pullRequestFromGitHub(
        pr(const GitHubUser(login: 'octo', avatarUrl: '')),
        repoFullName: 'o/r',
      ).author?.accountId,
      isEmpty,
    );
  });

  group('pull requests carry the durable base and head repository ids', () {
    test('GitHub REST, and its JSON round trip', () {
      final gh = GitHubPullRequest.fromJson({
        'number': 3,
        'title': 't',
        'head': {
          'ref': 'feature/x',
          'repo': {'id': 222, 'full_name': 'fork/widgets'},
        },
        'base': {
          'ref': 'main',
          'repo': {'id': 111, 'full_name': 'acme/widgets'},
        },
      });
      final pr = pullRequestFromGitHub(gh, repoFullName: 'acme/widgets');
      expect(pr.baseRepoId, '111');
      expect(pr.headRepoId, '222');
      expect(pr.isFromBaseRepository, isFalse);
      final again = GitHubPullRequest.fromJson(gh.toJson());
      expect((again.baseRepoId, again.headRepoId), ('111', '222'));
    });

    test('GitHub GraphQL', () {
      final pr = pullRequestFromGraphQlNode({
        'number': 3,
        'title': 't',
        'baseRepository': {'databaseId': 111},
        'headRepository': {'databaseId': 111},
      }, repoFullName: 'acme/widgets');
      expect(pr.baseRepoId, '111');
      expect(pr.isFromBaseRepository, isTrue);
      final deletedFork = pullRequestFromGraphQlNode({
        'number': 4,
        'title': 't',
        'baseRepository': {'databaseId': 111},
        'headRepository': null,
      }, repoFullName: 'acme/widgets');
      expect(deletedFork.headRepoId, isEmpty);
      expect(deletedFork.isFromBaseRepository, isFalse);
    });

    test('GitLab target and source projects', () {
      final pr = pullRequestFromGitLab(
        GitLabMergeRequest.fromJson({
          'iid': 5,
          'title': 't',
          'source_project_id': 9,
          'target_project_id': 8,
        }),
        repoFullName: 'acme/widgets',
      );
      expect((pr.baseRepoId, pr.headRepoId), ('8', '9'));
      expect(
        pullRequestFromGitLab(
          GitLabMergeRequest.fromJson({'iid': 5, 'title': 't'}),
          repoFullName: 'acme/widgets',
        ).baseRepoId,
        isEmpty,
      );
    });

    test('Bitbucket destination and source repositories', () {
      final pr = pullRequestFromBitbucket(
        BitbucketPullRequest.fromJson({
          'id': 6,
          'title': 't',
          'source': {
            'repository': {'uuid': '{src}'},
          },
          'destination': {
            'repository': {'uuid': '{dst}'},
          },
        }),
        owner: 'acme',
        repo: 'widgets',
      );
      expect((pr.baseRepoId, pr.headRepoId), ('{dst}', '{src}'));
    });
  });
}
