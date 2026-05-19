import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_server_core/src/pr_review/stale_review_watcher.dart';
import 'package:test/test.dart';

const _ws = 'ws';
const _prExternalId = 'acme/widget#42';

ReviewSpaceAssociation _assoc() => ReviewSpaceAssociation(
  id: 'assoc-1',
  spaceId: 'space-1',
  workspaceId: _ws,
  prExternalId: _prExternalId,
  prNumber: 42,
  repoFullName: 'acme/widget',
  status: ReviewSpaceStatus.awaitingApproval,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _FakeReviewSpaces implements ReviewSpaceRepository {
  _FakeReviewSpaces(this.association);

  ReviewSpaceAssociation? association;

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(association);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSnapshots implements ReviewRunSnapshotRepository {
  _FakeSnapshots(this.latest);

  ReviewRunSnapshot? latest;

  @override
  Future<ReviewRunSnapshot?> latestForPr(
    String workspaceId,
    String prExternalId,
  ) async => latest;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReviewRunSnapshot _snapshot({String? headSha}) => ReviewRunSnapshot(
  id: 'snap-1',
  workspaceId: _ws,
  prExternalId: _prExternalId,
  spaceId: 'space-1',
  finalizedAt: DateTime.utc(2026),
  headSha: headSha,
);

PrHeadChanged _push({String from = 'aaa1111', String to = 'bbb2222'}) =>
    PrHeadChanged(
      workspaceId: _ws,
      repoOwner: 'acme',
      repoName: 'widget',
      prNumber: 42,
      prTitle: 'Add the thing',
      previousHeadSha: from,
      headSha: to,
      occurredAt: DateTime.utc(2026),
    );

void main() {
  group('StaleReviewWatcher', () {
    late DomainEventBus bus;
    late List<ReviewBecameStale> raised;

    Future<void> pump() => Future<void>.delayed(Duration.zero);

    StaleReviewWatcher build({
      ReviewSpaceAssociation? association,
      ReviewRunSnapshot? snapshot,
    }) => StaleReviewWatcher(
      eventBus: bus,
      reviewSpaces: _FakeReviewSpaces(association),
      runSnapshots: _FakeSnapshots(snapshot),
      now: () => DateTime.utc(2026, 2),
    )..start();

    setUp(() {
      bus = DomainEventBus();
      raised = [];
      bus.on<ReviewBecameStale>().listen(raised.add);
    });

    test('raises when a push replaces the reviewed commit', () async {
      build(association: _assoc(), snapshot: _snapshot(headSha: 'aaa1111'));
      bus.publish(_push());
      await pump();

      expect(raised, hasLength(1));
      final e = raised.single;
      expect(e.spaceId, 'space-1');
      expect(e.prNumber, 42);
      expect(e.reviewedHeadSha, 'aaa1111');
      expect(e.headSha, 'bbb2222');
    });

    test('stays quiet when the pull request was never reviewed', () async {
      // A push on an unreviewed PR is just work happening. Notifying on it
      // would mean a ping per commit per open PR.
      build(association: null, snapshot: null);
      bus.publish(_push());
      await pump();
      expect(raised, isEmpty);
    });

    test('stays quiet when no pass ever finalized', () async {
      build(association: _assoc(), snapshot: null);
      bus.publish(_push());
      await pump();
      expect(raised, isEmpty);
    });

    test('stays quiet when the review recorded no commit', () async {
      // Claiming staleness without knowing what was reviewed is a guess, and a
      // wrong staleness warning costs more trust than a missing one.
      build(association: _assoc(), snapshot: _snapshot());
      bus.publish(_push());
      await pump();
      expect(raised, isEmpty);
    });

    test('warns once, not on every subsequent commit', () async {
      // The review is already known-stale: the person has been told, and
      // repeating it per push turns one useful warning into a stream.
      build(association: _assoc(), snapshot: _snapshot(headSha: 'aaa1111'));
      bus.publish(_push(from: 'ccc3333', to: 'ddd4444'));
      await pump();
      expect(raised, isEmpty);
    });

    test('a failing lookup never takes the poller down', () async {
      final watcher = StaleReviewWatcher(
        eventBus: bus,
        reviewSpaces: _ExplodingSpaces(),
        runSnapshots: _FakeSnapshots(null),
      )..start();
      addTearDown(watcher.stop);

      bus.publish(_push());
      await pump();
      expect(raised, isEmpty);
    });

    test('starting twice does not double-subscribe', () async {
      final watcher = build(
        association: _assoc(),
        snapshot: _snapshot(headSha: 'aaa1111'),
      )..start();
      addTearDown(watcher.stop);

      bus.publish(_push());
      await pump();
      expect(raised, hasLength(1));
    });

    test('stops listening once stopped', () async {
      final watcher = build(
        association: _assoc(),
        snapshot: _snapshot(headSha: 'aaa1111'),
      );
      await watcher.stop();
      bus.publish(_push());
      await pump();
      expect(raised, isEmpty);
    });
  });
}

class _ExplodingSpaces implements ReviewSpaceRepository {
  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.error(StateError('database is on fire'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
