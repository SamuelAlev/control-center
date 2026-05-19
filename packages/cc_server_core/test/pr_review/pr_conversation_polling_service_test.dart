import 'dart:convert';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/cc_infra.dart'
    show GitHubIssueComment, GitHubReviewComment, GitHubViewerPr;
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:cc_server_core/src/pr_review/pr_conversation_polling_service.dart';
import 'package:test/test.dart';

const _botLogin = 'cc-test[bot]';

GitHubViewerPr _pr(String repoFullName, int number, [String title = 'T']) =>
    GitHubViewerPr(
      repoFullName: repoFullName,
      number: number,
      title: title,
      updatedAt: DateTime(2026, 8, 26),
    );

GitHubIssueComment _issue(
  int id,
  String body, {
  String login = 'octocat',
}) => GitHubIssueComment(
  id: id,
  body: body,
  user: GitHubUser(login: login, avatarUrl: ''),
  createdAt: DateTime(2026, 8, 26),
);

GitHubReviewComment _review(
  int id,
  String body, {
  String login = 'octocat',
  int? inReplyTo,
}) => GitHubReviewComment(
  id: id,
  body: body,
  path: 'lib/a.dart',
  diffHunk: '@@ -1,1 +1,1 @@',
  inReplyToId: inReplyTo,
  user: GitHubUser(login: login, avatarUrl: ''),
  createdAt: DateTime(2026, 8, 26),
);

/// Scripts search results and per-PR comment lists; records nothing (the
/// sink records what reached it).
class _FakeGateway implements GitHubPrConversationGateway {
  String botLoginValue = _botLogin;
  List<GitHubViewerPr> mentioned = [];
  List<GitHubViewerPr> shortMentioned = [];
  List<GitHubViewerPr> labeled = [];
  final issueComments =
      <String, List<GitHubIssueComment>>{}; // 'owner/repo#n' → list
  final reviewComments = <String, List<GitHubReviewComment>>{};

  static String _key(String owner, String repo, int pr) =>
      '$owner/$repo#$pr';

  void setIssue(
    String owner,
    String repo,
    int pr,
    List<GitHubIssueComment> comments,
  ) => issueComments[_key(owner, repo, pr)] = comments;

  void setReview(
    String owner,
    String repo,
    int pr,
    List<GitHubReviewComment> comments,
  ) => reviewComments[_key(owner, repo, pr)] = comments;

  @override
  Future<String> botLogin() async => botLoginValue;

  @override
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchCandidates({DateTime? since}) async =>
      (mentioned: mentioned, shortMentioned: shortMentioned, labeled: labeled);

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int prNumber,
  ) async => issueComments[_key(owner, repo, prNumber)] ?? const [];

  @override
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int prNumber,
  ) async => reviewComments[_key(owner, repo, prNumber)] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingSink implements GitHubPrConversationSink {
  final inbound =
      <
        ({
          String workspaceId,
          String owner,
          String repo,
          int prNumber,
          String prTitle,
          InboundGitHubPrComment comment,
          bool isBotThread,
        })
      >[];
  final labeled =
      <
        ({String workspaceId, String owner, String repo, int prNumber})
      >[];

  @override
  Future<void> handleInboundComment({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    bool isBotThread = false,
  }) async {
    inbound.add((
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      prTitle: prTitle,
      comment: comment,
      isBotThread: isBotThread,
    ));
  }

  @override
  Future<void> handleLabeledPullRequest({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    labeled.add((
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
    ));
  }

  @override
  Future<void> stop() async {}
}

/// A valid empty store: a loader that returns this is a RESTART (state
/// exists, nothing seen yet), not a first run ever — the sweep acts.
final String _emptyStore = jsonEncode({
  'v': 1,
  'savedAt': '2026-08-26T11:00:00.000Z',
  'seen': <String>[],
});

void main() {
  late _FakeGateway gateway;
  late _RecordingSink sink;
  late PrConversationPollingService poller;
  final repoLinks = <String, List<String>>{};
  var associated = <AssociatedPullRequest>[];
  String? savedState;

  PrConversationPollingService build({
    String? loadedState,
    bool wireStore = true,
  }) => PrConversationPollingService(
    gateway: gateway,
    bridge: sink,
    workspacesForRepo: (repoFullName) async =>
        repoLinks[repoFullName.toLowerCase()] ?? const [],
    associatedPullRequests: () async => associated,
    // A wired store (even an empty one) means this is not a first run ever,
    // so the sweep acts on what it finds; only the baseline tests opt out.
    loadDedupeState:
        wireStore ? (() async => loadedState ?? _emptyStore) : null,
    saveDedupeState: (state) async => savedState = state,
    now: () => DateTime(2026, 8, 26, 12),
  );

  setUp(() {
    gateway = _FakeGateway();
    sink = _RecordingSink();
    repoLinks.clear();
    associated = const [];
    savedState = null;
    poller = build();
  });

  group('bot thread detection', () {
    test('a reply chain containing the bot marks the whole thread', () {
      final ids = PrConversationPollingService.botThreadCommentIds([
        _review(1, 'finding', login: _botLogin),
        _review(2, 'reply to bot', inReplyTo: 1),
        _review(3, 'unrelated root'),
        _review(4, 'reply to unrelated', inReplyTo: 3),
      ], _botLogin);

      expect(ids, {1, 2});
    });

    test('a broken parent chain is not assumed to be ours', () {
      final ids = PrConversationPollingService.botThreadCommentIds([
        // Replies to a parent the list does not carry.
        _review(9, 'orphan reply', inReplyTo: 1),
      ], _botLogin);

      expect(ids, isEmpty);
    });
  });

  test('no app identity: the sweep does nothing and asks for nothing',
      () async {
    gateway.botLoginValue = '';

    await poller.pollOnce();

    expect(gateway.mentioned, isEmpty);
    expect(sink.inbound, isEmpty);
    expect(sink.labeled, isEmpty);
  });

  test('a short-alias mention (bare slug) is discovered like a full one',
      () async {
    repoLinks['acme/app'] = ['ws-a'];
    // The text-search lane found the PR; the comment says `@cc-test`, not
    // `@cc-test[bot]`.
    gateway.shortMentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@cc-test hello?')]);

    await poller.pollOnce();

    final call = sink.inbound.single;
    expect(call.workspaceId, 'ws-a');
    expect(call.comment.id, 11);
  });

  test('a mentioning comment is routed to the first linking workspace',
      () async {
    repoLinks['acme/app'] = ['ws-b', 'ws-a'];
    gateway.mentioned = [_pr('acme/app', 7, 'Fix')];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);

    await poller.pollOnce();

    final call = sink.inbound.single;
    expect(call.workspaceId, 'ws-a');
    expect(call.comment.id, 11);
    expect(call.comment.isReviewComment, isFalse);
    expect(call.prTitle, 'Fix');
  });

  test('the same comment never fires twice', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);

    await poller.pollOnce();
    await poller.pollOnce();

    expect(sink.inbound, hasLength(1));
  });

  test('bot-authored comments are skipped entirely (loop guard)', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [
      _issue(11, '@$_botLogin thanks', login: _botLogin),
      _issue(12, 'from another bot', login: 'copilot[bot]'),
    ]);

    await poller.pollOnce();

    expect(sink.inbound, isEmpty);
  });

  test('an issue comment without a mention is other people\'s conversation',
      () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, 'looks good to me')]);

    await poller.pollOnce();

    expect(sink.inbound, isEmpty);
  });

  test('a reply in a bot review thread qualifies without a mention',
      () async {
    associated = [
      const AssociatedPullRequest(
        workspaceId: 'ws-a',
        repoFullName: 'acme/app',
        prNumber: 7,
      ),
    ];
    gateway.setReview('acme', 'app', 7, [
      _review(1, 'finding', login: _botLogin),
      _review(2, 'what about X?', inReplyTo: 1),
    ]);

    await poller.pollOnce();

    final call = sink.inbound.single;
    expect(call.workspaceId, 'ws-a');
    expect(call.comment.id, 2);
    expect(call.comment.isReviewComment, isTrue);
    expect(call.isBotThread, isTrue);
  });

  test('an unlinked repo is ignored and not marked seen', () async {
    gateway.labeled = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hi')]);

    await poller.pollOnce();
    expect(sink.inbound, isEmpty);
    expect(sink.labeled, isEmpty);

    // Linking the repo later delivers both the label and the comment.
    repoLinks['acme/app'] = ['ws-a'];
    await poller.pollOnce();

    expect(sink.labeled, hasLength(1));
    expect(sink.inbound, hasLength(1));
  });

  test('the first sweep ever baselines silently', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);
    poller = build(wireStore: false);

    await poller.pollOnce();
    expect(sink.inbound, isEmpty);

    // A NEW comment on the next sweep fires.
    gateway.setIssue('acme', 'app', 7, [
      _issue(11, '@$_botLogin hello?'),
      _issue(12, '@$_botLogin and this?'),
    ]);
    await poller.pollOnce();

    expect(sink.inbound, hasLength(1));
    expect(sink.inbound.single.comment.id, 12);
  });

  test('a persisted store means no baseline: a restart catches up', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);
    final first = build(wireStore: false);
    await first.pollOnce();
    // No store wired → first-run baseline records silently (but persists).
    expect(savedState, isNotNull);
    expect(sink.inbound, isEmpty);

    // A comment that arrived while "down" fires on the first sweep after the
    // restart, because the loaded store already says what was seen.
    gateway.setIssue('acme', 'app', 7, [
      _issue(11, '@$_botLogin hello?'),
      _issue(12, '@$_botLogin new one'),
    ]);
    final restarted = build(loadedState: savedState);
    await restarted.pollOnce();

    expect(sink.inbound, hasLength(1));
    expect(sink.inbound.single.comment.id, 12);
  });

  test('a labeled PR triggers a review exactly once', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.labeled = [_pr('acme/app', 9, 'Add thing')];

    await poller.pollOnce();
    expect(sink.labeled.single,
        (workspaceId: 'ws-a', owner: 'acme', repo: 'app', prNumber: 9));

    await poller.pollOnce();
    expect(sink.labeled, hasLength(1));
  });

  test('the comment sweep is capped per pass', () async {
    repoLinks['acme/one'] = ['ws-a'];
    repoLinks['acme/two'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/one', 1), _pr('acme/two', 2)];
    gateway.setIssue('acme', 'one', 1, [_issue(11, '@$_botLogin a')]);
    gateway.setIssue('acme', 'two', 2, [_issue(12, '@$_botLogin b')]);
    final capped = PrConversationPollingService(
      gateway: gateway,
      bridge: sink,
      workspacesForRepo: (repoFullName) async =>
          repoLinks[repoFullName.toLowerCase()] ?? const [],
      associatedPullRequests: () async => associated,
      maxCommentSweeps: 1,
      loadDedupeState: () async => _emptyStore,
      saveDedupeState: (state) async => savedState = state,
      now: () => DateTime(2026, 8, 26, 12),
    );

    await capped.pollOnce();

    expect(sink.inbound, hasLength(1));
    // The second PR is picked up on the next sweep.
    await capped.pollOnce();
    expect(sink.inbound, hasLength(2));
  });

  test('an association wins over search routing for the same PR', () async {
    // Linked in ws-a and ws-b (ws-a sorts first), but the review space lives
    // in ws-b: the conversation continues where it already is.
    repoLinks['acme/app'] = ['ws-b', 'ws-a'];
    associated = [
      const AssociatedPullRequest(
        workspaceId: 'ws-b',
        repoFullName: 'acme/app',
        prNumber: 7,
      ),
    ];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin again')]);

    await poller.pollOnce();

    expect(sink.inbound.single.workspaceId, 'ws-b');
  });

  test('the saved state is a versioned JSON document', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.labeled = [_pr('acme/app', 9)];

    await poller.pollOnce();

    final decoded = jsonDecode(savedState!) as Map<String, dynamic>;
    expect(decoded['v'], 1);
    expect((decoded['seen'] as List).contains('lb:acme/app#9'), isTrue);
    expect(decoded['savedAt'], isNotNull);
  });
}
