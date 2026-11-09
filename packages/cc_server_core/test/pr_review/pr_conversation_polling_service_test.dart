import 'dart:convert';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/cc_infra.dart'
    show GitHubIssueComment, GitHubReviewComment, GitHubViewerPr;
import 'package:cc_server_core/src/forge/github_clients.dart' show GitHubLane;
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
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
  int userId = 101,
}) => GitHubIssueComment(
  id: id,
  body: body,
  user: GitHubUser(login: login, avatarUrl: '', id: userId),
  createdAt: DateTime(2026, 8, 26),
);

GitHubReviewComment _review(
  int id,
  String body, {
  String login = 'octocat',
  int userId = 101,
  int? inReplyTo,
}) => GitHubReviewComment(
  id: id,
  body: body,
  path: 'lib/a.dart',
  diffHunk: '@@ -1,1 +1,1 @@',
  inReplyToId: inReplyTo,
  user: GitHubUser(login: login, avatarUrl: '', id: userId),
  createdAt: DateTime(2026, 8, 26),
);

/// Scripts search results and per-PR comment lists; records nothing (the
/// sink records what reached it).
class _FakeGateway implements GitHubPrConversationGateway {
  String botLoginValue = _botLogin;
  List<GitHubViewerPr> mentioned = [];
  List<GitHubViewerPr> botMentioned = [];
  List<GitHubViewerPr> shortMentioned = [];
  List<GitHubViewerPr> labeled = [];
  bool allSuspended = false;
  Set<String> suspendedOwnerLogins = {};
  int searchCalls = 0;
  int issueCommentCalls = 0;
  final issueComments =
      <String, List<GitHubIssueComment>>{}; // 'owner/repo#n' → list
  final reviewComments = <String, List<GitHubReviewComment>>{};

  static String _key(String owner, String repo, int pr) => '$owner/$repo#$pr';

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
  Future<GitHubConversationIdentity?> identity() async => botLoginValue.isEmpty
      ? null
      : GitHubConversationIdentity(
          botLogin: botLoginValue,
          slug: 'cc-test',
          lane: GitHubLane.ownApp,
        );

  @override
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> botMentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchCandidates({DateTime? since}) async {
    searchCalls++;
    return (
      mentioned: mentioned,
      botMentioned: botMentioned,
      shortMentioned: shortMentioned,
      labeled: labeled,
    );
  }

  @override
  Future<bool> allInstallationsSuspended() async => allSuspended;

  @override
  Future<Set<String>> suspendedOwners() async => suspendedOwnerLogins;

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int prNumber,
  ) async {
    issueCommentCalls++;
    return issueComments[_key(owner, repo, prNumber)] ?? const [];
  }

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
      <({String workspaceId, String owner, String repo, int prNumber})>[];

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
  'v': 2,
  'watermarks': <String, String>{},
  'seen': <String>[],
});

/// One identity per workspace (`ws-a` plus every linked or associated one),
/// each served by [gateway] on [lane].
Future<List<PrConversationAppIdentity>> Function() _identitiesOf(
  _FakeGateway Function() gateway,
  Map<String, List<String>> repoLinks,
  List<AssociatedPullRequest> Function() associated, {
  GitHubLane lane = GitHubLane.ownApp,
}) => () async {
  final g = gateway();
  final workspaceIds = <String>{
    'ws-a',
    for (final ids in repoLinks.values) ...ids,
    for (final a in associated()) a.workspaceId,
  };
  return [
    for (final id in workspaceIds.toList()..sort())
      PrConversationAppIdentity(
        workspaceId: id,
        botLogin: g.botLoginValue,
        lane: lane,
        gateway: g,
      ),
  ];
};

void main() {
  late _FakeGateway gateway;
  late _RecordingSink sink;
  late PrConversationPollingService poller;
  final repoLinks = <String, List<String>>{};
  var associated = <AssociatedPullRequest>[];
  String? savedState;
  // Advances on every read so consecutive passes clear any lane's floor;
  // the cadence tests drive their own clock.
  var clock = DateTime(2026, 8, 26, 12);
  DateTime tick() => clock = clock.add(const Duration(minutes: 3));

  PrConversationPollingService build({
    String? loadedState,
    bool wireStore = true,
  }) => PrConversationPollingService(
    listIdentities: _identitiesOf(() => gateway, repoLinks, () => associated),
    bridge: sink,
    workspacesForRepo: (repoFullName) async =>
        repoLinks[repoFullName.toLowerCase()] ?? const [],
    associatedPullRequests: () async => associated,
    // A wired store (even an empty one) means this is not a first run ever,
    // so the sweep acts on what it finds; only the baseline tests opt out.
    loadDedupeState: wireStore
        ? (() async => loadedState ?? _emptyStore)
        : null,
    saveDedupeState: (state) async => savedState = state,
    now: tick,
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

    test('an attributed reply by a person counts as ours', () {
      // Connect posts as the asking person, so the root is theirs.
      final ids = PrConversationPollingService.botThreadCommentIds([
        _review(1, '**Control Center** (for @octocat): the finding'),
        _review(2, 'and the migration?', inReplyTo: 1),
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

  test(
    'no app identity: the sweep does nothing and asks for nothing',
    () async {
      gateway.botLoginValue = '';

      await poller.pollOnce();

      expect(gateway.searchCalls, 0);
      expect(sink.inbound, isEmpty);
      expect(sink.labeled, isEmpty);
    },
  );

  test('suspended installations: the sweep does not hit GitHub', () async {
    gateway.allSuspended = true;
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);

    await poller.pollOnce();

    expect(gateway.searchCalls, 0);
    expect(gateway.issueCommentCalls, 0);
    expect(sink.inbound, isEmpty);
  });

  test('comment sweeps skip a suspended owner', () async {
    // Matching is the owner half of `owner/name`, lowercased, against the
    // suspended-login set — not a substring of the repo name.
    gateway.suspendedOwnerLogins = {'suspended'};
    associated = [
      const AssociatedPullRequest(
        workspaceId: 'ws-a',
        repoFullName: 'suspended/app',
        prNumber: 414,
      ),
    ];
    gateway.setIssue('suspended', 'app', 414, [
      _issue(11, '@$_botLogin hello?'),
    ]);

    await poller.pollOnce();

    expect(gateway.issueCommentCalls, 0);
    expect(sink.inbound, isEmpty);
  });

  test('@usectrl in a timeline comment reaches the bridge', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [
      _issue(11, '@usectrl hello?', login: 'usectrl'),
    ]);

    await poller.pollOnce();

    expect(sink.inbound.single.comment.body, '@usectrl hello?');
    expect(sink.inbound.single.comment.authorIsBot, isFalse);
  });

  test('the author\'s numeric id reaches the bridge', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [
      _issue(11, '@usectrl hello?', login: 'renamed', userId: 583231),
    ]);
    gateway.setReview('acme', 'app', 7, [
      _review(12, '@usectrl why?', userId: 77),
    ]);

    await poller.pollOnce();

    expect(sink.inbound.map((e) => e.comment.authorId), [583231, 77]);
    expect(sink.inbound.first.comment.authorLogin, 'renamed');
  });

  test('@usectrl in a review comment reaches the bridge', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setReview('acme', 'app', 7, [_review(12, '@usectrl why?')]);

    await poller.pollOnce();

    expect(sink.inbound.single.comment.body, '@usectrl why?');
    expect(sink.inbound.single.comment.isReviewComment, isTrue);
  });

  test('the App bot login remains a candidate-search alias', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.botMentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(13, '@$_botLogin hello?')]);

    await poller.pollOnce();

    expect(sink.inbound.single.comment.id, 13);
  });

  test(
    'a short-alias mention (bare slug) is discovered like a full one',
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
    },
  );

  test(
    'a mention is offered to every linking workspace; the claim decides',
    () async {
      repoLinks['acme/app'] = ['ws-b', 'ws-a'];
      gateway.mentioned = [_pr('acme/app', 7, 'Fix')];
      gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);

      await poller.pollOnce();

      expect(sink.inbound.map((e) => (e.workspaceId, e.comment.id)), [
        ('ws-a', 11),
        ('ws-b', 11),
      ]);
      expect(sink.inbound.first.prTitle, 'Fix');
      expect(sink.inbound.first.comment.isReviewComment, isFalse);
    },
  );

  test('two PRs of the same repository are both swept', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7), _pr('acme/app', 8)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin a')]);
    gateway.setIssue('acme', 'app', 8, [_issue(12, '@$_botLogin b')]);

    await poller.pollOnce();

    expect(sink.inbound.map((e) => e.prNumber), [7, 8]);
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
      _issue(11, '@usectrl thanks', login: _botLogin),
      _issue(12, '@usectrl from another bot', login: 'copilot[bot]'),
      // Connect: our reply, authored by the person it answered.
      _issue(13, '**Control Center** (for @octocat): ask @usectrl again'),
    ]);

    await poller.pollOnce();

    expect(sink.inbound, isEmpty);
  });

  test(
    'an issue comment without a mention is other people\'s conversation',
    () async {
      repoLinks['acme/app'] = ['ws-a'];
      gateway.mentioned = [_pr('acme/app', 7)];
      gateway.setIssue('acme', 'app', 7, [_issue(11, 'looks good to me')]);

      await poller.pollOnce();

      expect(sink.inbound, isEmpty);
    },
  );

  test('a reply in a bot review thread qualifies without a mention', () async {
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

  test(
    'the first-run baseline covers every workspace, not just the first',
    () async {
      repoLinks['acme/app'] = ['ws-a', 'ws-b'];
      gateway.mentioned = [_pr('acme/app', 7)];
      gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);
      poller = build(wireStore: false);

      await poller.pollOnce();

      expect(sink.inbound, isEmpty);
    },
  );

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

  test('a store from an older build is a first run (silent)', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hello?')]);
    poller = build(
      loadedState: jsonEncode({
        'v': 1,
        'savedAt': '2026-08-26T11:00:00.000Z',
        'seen': <String>[],
      }),
    );

    await poller.pollOnce();

    expect(sink.inbound, isEmpty);
  });

  test('a labeled PR triggers a review exactly once', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.labeled = [_pr('acme/app', 9, 'Add thing')];

    await poller.pollOnce();
    expect(sink.labeled.single, (
      workspaceId: 'ws-a',
      owner: 'acme',
      repo: 'app',
      prNumber: 9,
    ));

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
      listIdentities: _identitiesOf(() => gateway, repoLinks, () => associated),
      bridge: sink,
      workspacesForRepo: (repoFullName) async =>
          repoLinks[repoFullName.toLowerCase()] ?? const [],
      associatedPullRequests: () async => associated,
      maxCommentSweeps: 1,
      loadDedupeState: () async => _emptyStore,
      saveDedupeState: (state) async => savedState = state,
      now: tick,
    );

    await capped.pollOnce();

    expect(sink.inbound, hasLength(1));
    // The second PR is picked up on the next sweep.
    await capped.pollOnce();
    expect(sink.inbound, hasLength(2));
  });

  test('an association wins over search routing for the same PR', () async {
    // Linked in ws-a and ws-b, but the review space lives in ws-b: the
    // conversation continues where it already is.
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

  test('the saved state is a versioned, per-workspace document', () async {
    repoLinks['acme/app'] = ['ws-a'];
    gateway.labeled = [_pr('acme/app', 9)];

    await poller.pollOnce();

    final decoded = jsonDecode(savedState!) as Map<String, dynamic>;
    expect(decoded['v'], 2);
    expect((decoded['seen'] as List).contains('lb:ws-a:acme/app#9'), isTrue);
    expect((decoded['watermarks'] as Map).containsKey('ws-a'), isTrue);
  });

  test('mentions route only into workspaces that use that App', () async {
    repoLinks['acme/app'] = ['ws-inherit', 'ws-app-b'];
    final appB = _FakeGateway()..botLoginValue = 'other-bot[bot]';
    appB.mentioned = [_pr('acme/app', 7)];
    appB.setIssue('acme', 'app', 7, [
      _issue(11, '@other-bot[bot] hello?', login: 'octocat'),
    ]);
    gateway.mentioned = [_pr('acme/app', 7)];
    gateway.setIssue('acme', 'app', 7, [_issue(12, '@$_botLogin hello?')]);

    final routed = PrConversationPollingService(
      bridge: sink,
      workspacesForRepo: (repoFullName) async =>
          repoLinks[repoFullName.toLowerCase()] ?? const [],
      associatedPullRequests: () async => associated,
      loadDedupeState: () async => _emptyStore,
      saveDedupeState: (state) async => savedState = state,
      now: tick,
      listIdentities: () async => [
        PrConversationAppIdentity(
          workspaceId: 'ws-inherit',
          botLogin: _botLogin,
          lane: GitHubLane.ownApp,
          gateway: gateway,
        ),
        PrConversationAppIdentity(
          workspaceId: 'ws-app-b',
          botLogin: 'other-bot[bot]',
          lane: GitHubLane.workspaceApp,
          gateway: appB,
        ),
      ],
    );

    await routed.pollOnce();
    expect(sink.inbound.map((e) => (e.workspaceId, e.comment.id)).toSet(), {
      ('ws-inherit', 12),
      ('ws-app-b', 11),
    });
  });

  group('Connect lane cadence', () {
    late DateTime now;

    PrConversationPollingService connectPoller({GitHubLane? lane}) =>
        PrConversationPollingService(
          listIdentities: _identitiesOf(
            () => gateway,
            repoLinks,
            () => associated,
            lane: lane ?? GitHubLane.connect,
          ),
          bridge: sink,
          workspacesForRepo: (repoFullName) async =>
              repoLinks[repoFullName.toLowerCase()] ?? const [],
          associatedPullRequests: () async => associated,
          loadDedupeState: () async => _emptyStore,
          saveDedupeState: (state) async => savedState = state,
          now: () => now,
        );

    setUp(() {
      now = DateTime(2026, 8, 26, 12);
      repoLinks['acme/app'] = ['ws-a'];
      gateway.mentioned = [for (var n = 1; n <= 30; n++) _pr('acme/app', n)];
    });

    test('sweeps at most 10 PRs per pass', () async {
      await connectPoller().pollOnce();

      expect(gateway.issueCommentCalls, 10);
    });

    test('an own App lane keeps the larger cap', () async {
      await connectPoller(lane: GitHubLane.ownApp).pollOnce();

      expect(gateway.issueCommentCalls, 25);
    });

    test('does not sweep again inside 120 seconds', () async {
      final connect = connectPoller();
      await connect.pollOnce();
      expect(gateway.searchCalls, 1);

      now = now.add(const Duration(seconds: 61));
      await connect.pollOnce();
      expect(gateway.searchCalls, 1, reason: 'still inside the floor');

      now = now.add(const Duration(seconds: 60));
      await connect.pollOnce();
      expect(gateway.searchCalls, 2);
      // The rotation moved on to the next ten.
      expect(gateway.issueCommentCalls, 20);
    });

    test('an own App lane sweeps again after 60 seconds', () async {
      final own = connectPoller(lane: GitHubLane.ownApp);
      await own.pollOnce();

      now = now.add(const Duration(seconds: 61));
      await own.pollOnce();

      expect(gateway.searchCalls, 2);
    });
  });

  group('rate budget', () {
    late DateTime now;
    late GitHubRateBudget budget;

    PrConversationPollingService budgeted() => PrConversationPollingService(
      listIdentities: _identitiesOf(() => gateway, repoLinks, () => associated),
      bridge: sink,
      workspacesForRepo: (repoFullName) async =>
          repoLinks[repoFullName.toLowerCase()] ?? const [],
      associatedPullRequests: () async => associated,
      rateBudget: budget,
      loadDedupeState: () async => _emptyStore,
      saveDedupeState: (state) async => savedState = state,
      now: () => now,
    );

    setUp(() {
      now = DateTime.utc(2026, 8, 26, 12);
      budget = GitHubRateBudget(now: () => now);
      repoLinks['acme/app'] = ['ws-a', 'ws-b'];
      gateway.mentioned = [_pr('acme/app', 7)];
      gateway.setIssue('acme', 'app', 7, [_issue(11, '@$_botLogin hi')]);
    });

    test('a workspace under 15% of its quota is not swept', () async {
      budget.record(
        'ws-a',
        resource: 'graphql',
        remaining: 700,
        limit: 5000,
        resetAt: now.add(const Duration(minutes: 20)),
      );

      await budgeted().pollOnce();

      // ws-b still sweeps; ws-a asked GitHub for nothing.
      expect(sink.inbound.map((e) => e.workspaceId), ['ws-b']);
      expect(gateway.searchCalls, 1);
    });

    test('the workspace resumes once the window resets', () async {
      budget.record(
        'ws-a',
        resource: 'core',
        remaining: 10,
        limit: 5000,
        resetAt: now.add(const Duration(minutes: 20)),
      );
      final poller = budgeted();
      await poller.pollOnce();
      expect(sink.inbound.map((e) => e.workspaceId), ['ws-b']);

      now = now.add(const Duration(minutes: 21));
      await poller.pollOnce();

      expect(sink.inbound.map((e) => e.workspaceId), ['ws-b', 'ws-a']);
    });

    test('a healthy reading lets the sweep through', () async {
      budget.record('ws-a', resource: 'core', remaining: 800, limit: 5000);

      await budgeted().pollOnce();

      expect(sink.inbound.map((e) => e.workspaceId), ['ws-a', 'ws-b']);
    });
  });
}
