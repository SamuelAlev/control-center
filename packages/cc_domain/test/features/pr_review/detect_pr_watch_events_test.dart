import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_pr_watch_events.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 19, 12);

Map<String, dynamic> _pr({
  String checks = 'pending',
  String sha = 'a1',
  String decision = 'none',
  int comments = 0,
  String author = 'alice',
}) => {
  'title': 'Add cart',
  'head_ref': 'space/sp-1',
  'head_sha': sha,
  'author': {'login': author},
  'checks_status': checks,
  'review_decision': decision,
  'comments_count': comments,
};

List<PrWatchEvent> _detect(
  Map<String, dynamic> before,
  Map<String, dynamic> after, {
  ({String name, String? url})? failed,
}) => detectPrWatchEvents(
  workspaceId: 'ws-1',
  repoOwner: 'acme',
  repoName: 'shop-ui',
  prNumber: 12,
  before: before,
  after: after,
  now: _now,
  failedCheck: failed,
);

void main() {
  group('checks', () {
    test('pending to passing settles once, passing', () {
      final events = _detect(_pr(), _pr(checks: 'passing'));
      final settled = events.single as PrWatchChecksSettled;
      expect(settled.passing, isTrue);
      expect(settled.failedChecks, isEmpty);
      expect(settled.headRef, 'space/sp-1');
      expect(settled.authorLogin, 'alice');
      expect(settled.prTitle, 'Add cart');
      // The next poll sees nothing new.
      expect(_detect(_pr(checks: 'passing'), _pr(checks: 'passing')), isEmpty);
    });

    test('pending to failing carries the failed check', () {
      expect(checksFailingEdge(_pr(), _pr(checks: 'failing')), isTrue);
      final settled =
          _detect(
                _pr(),
                _pr(checks: 'failing'),
                failed: (name: 'lint', url: 'https://ci.example/1'),
              ).single
              as PrWatchChecksSettled;
      expect(settled.passing, isFalse);
      expect(settled.failedChecks, ['lint']);
      expect(settled.failedCheckUrl, 'https://ci.example/1');
    });

    test('a re-run that finishes again settles again: a flip, or a new '
        'head commit between two polls', () {
      expect(
        (_detect(_pr(checks: 'failing'), _pr(checks: 'passing')).single
                as PrWatchChecksSettled)
            .passing,
        isTrue,
      );
      expect(
        _detect(_pr(checks: 'failing'), _pr(checks: 'failing', sha: 'b2')),
        hasLength(1),
      );
      expect(checksFailingEdge(_pr(), _pr()), isFalse);
      expect(_detect(_pr(), _pr(checks: 'none')), isEmpty);
      expect(_detect(_pr(checks: 'passing'), _pr()), isEmpty);
    });

    test('every author: a bot opened it, or a member', () {
      for (final author in ['builder-bot[bot]', 'bob']) {
        expect(
          _detect(
            _pr(author: author),
            _pr(author: author, checks: 'passing'),
          ).single.authorLogin,
          author,
        );
      }
    });
  });

  group('review', () {
    test('a new decision, or new comments, is review activity', () {
      final decided =
          _detect(_pr(), _pr(decision: 'approved')).single
              as PrWatchReviewActivity;
      expect(decided.decisionChanged, isTrue);
      expect(decided.decision, 'approved');
      expect(decided.newComments, 0);
      final commented =
          _detect(_pr(comments: 2), _pr(comments: 5)).single
              as PrWatchReviewActivity;
      expect(commented.decisionChanged, isFalse);
      expect(commented.newComments, 3);
      expect(_detect(_pr(comments: 5), _pr(comments: 4)), isEmpty);
    });
  });

  test('a close carries whether it merged and the last snapshot', () {
    final closed = prWatchClosed(
      workspaceId: 'ws-1',
      repoOwner: 'acme',
      repoName: 'shop-ui',
      prNumber: 12,
      last: _pr(),
      merged: true,
      now: _now,
    );
    expect(closed.merged, isTrue);
    expect(closed.headRef, 'space/sp-1');
    expect(closed.authorLogin, 'alice');
  });

  test('publishing asks the forge once, only on a failing settle, and hands '
      'its answer back', () async {
    final bus = DomainEventBus();
    final heard = <DomainEvent>[];
    final sub = bus.on<PrWatchEvent>().listen(heard.add);
    var asked = 0;
    Future<({String name, String? url})?> ask() async {
      asked++;
      return (name: 'test', url: null);
    }

    Future<({String name, String? url})?> publish(
      Map<String, dynamic> before,
      Map<String, dynamic> after,
    ) => publishPrWatchEdges(
      bus: bus,
      workspaceId: 'ws-1',
      repoOwner: 'acme',
      repoName: 'shop-ui',
      prNumber: 12,
      before: before,
      after: after,
      now: _now,
      firstFailingCheck: ask,
    );

    expect(await publish(_pr(), _pr(checks: 'passing')), isNull);
    expect(asked, 0);
    expect(await publish(_pr(), _pr(checks: 'failing')), (
      name: 'test',
      url: null,
    ));
    expect(asked, 1);
    await Future<void>.delayed(Duration.zero);
    expect(heard, hasLength(2));
    expect((heard.last as PrWatchChecksSettled).failedChecks, ['test']);
    await sub.cancel();
  });
}
