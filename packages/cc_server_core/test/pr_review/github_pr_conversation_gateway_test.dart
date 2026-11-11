import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:test/test.dart';

/// Whether the bridge may claim and reply is asked at the scope that claim
/// and reply need: `comment` on the timeline (an issue-comment or pull
/// request reaction, a timeline comment), `bot` inside a review thread (the
/// review-comment reaction and the thread reply).
void main() {
  late List<GitHubTokenScope> asked;
  late GitHubTokenScope granted;

  WorkspaceGitHubPrConversationGateway gateway() =>
      WorkspaceGitHubPrConversationGateway(
        presence: () async => null,
        lane: () async => GitHubLane.connect,
        clientForOwner: (owner, {actingUserId}) =>
            throw StateError('nothing is posted by a probe'),
        clientForRepo: (owner, repo) =>
            throw StateError('nothing is read by a probe'),
        linkedRepos: () async => const [],
        mint: (owner, repo, {required scope, required actingUserId}) async {
          asked.add(scope);
          return GitHubScopedGrant(
            token: 'ghs_probe',
            scope: granted,
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            lane: GitHubLane.connect,
            workspaceId: 'ws',
            owner: owner,
            repo: repo,
          );
        },
      );

  setUp(() => asked = []);

  test('a timeline claim and reply are asked at comment, never bot', () async {
    granted = GitHubTokenScope.comment;
    expect(
      await gateway().canPostAs(
        'acme',
        'api',
        actingUserId: 'u1',
        inReviewThread: false,
      ),
      isTrue,
    );
    expect(asked, [GitHubTokenScope.comment]);
  });

  test('a review-thread claim and reply are asked at bot', () async {
    granted = GitHubTokenScope.bot;
    expect(
      await gateway().canPostAs(
        'acme',
        'api',
        actingUserId: 'u1',
        inReviewThread: true,
      ),
      isTrue,
    );
    expect(asked, [GitHubTokenScope.bot]);
  });

  test('a token clamped below the scope asked is a refusal', () async {
    granted = GitHubTokenScope.read;
    expect(
      await gateway().canPostAs(
        'acme',
        'api',
        actingUserId: 'u1',
        inReviewThread: false,
      ),
      isFalse,
    );
  });
}
