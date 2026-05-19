// Turns "somebody pushed" into "your review is out of date", but only when
// that is actually true.
//
// The poller notices a head move on every sweep of every open pull request.
// Raising a notification from that directly would mean a ping for every push
// on every PR, most of which have never been reviewed — which is precisely the
// kind of noise the reviewer itself is tuned to avoid, and the fastest way to
// teach someone to ignore this product's notifications.
//
// So the raw signal is filtered here, against the only thing that makes it
// meaningful: whether a finished review exists and which commit it read.

import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_host/cc_host.dart';

/// Watches for pushes that invalidate a finished review.
class StaleReviewWatcher {
  /// Creates a [StaleReviewWatcher].
  StaleReviewWatcher({
    required DomainEventBus eventBus,
    required ReviewSpaceRepository reviewSpaces,
    required ReviewRunSnapshotRepository runSnapshots,
    DateTime Function()? now,
  }) : _eventBus = eventBus,
       _reviewSpaces = reviewSpaces,
       _runSnapshots = runSnapshots,
       _now = now ?? DateTime.now;

  final DomainEventBus _eventBus;
  final ReviewSpaceRepository _reviewSpaces;
  final ReviewRunSnapshotRepository _runSnapshots;
  final DateTime Function() _now;

  final List<StreamSubscription<Object?>> _subs = [];

  /// Starts watching. Idempotent.
  void start() {
    if (_subs.isNotEmpty) {
      return;
    }
    _subs.add(_eventBus.on<PrHeadChanged>().listen(_onHeadChanged));
  }

  /// Stops watching.
  Future<void> stop() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _onHeadChanged(PrHeadChanged event) async {
    try {
      final prExternalId = '${event.repoOwner}/${event.repoName}'
          '#${event.prNumber}';

      // No review space means nobody has ever reviewed this PR. A push on an
      // unreviewed pull request is just work happening.
      final association = await _reviewSpaces
          .watchByPr(event.workspaceId, prExternalId)
          .first;
      if (association == null) {
        return;
      }

      // No finalized pass, or one that never recorded which commit it read.
      // Claiming staleness without knowing what was reviewed would be a guess,
      // and a wrong staleness warning costs more trust than a missing one.
      final snapshot = await _runSnapshots.latestForPr(
        event.workspaceId,
        association.prExternalId,
      );
      final reviewed = snapshot?.headSha;
      if (reviewed == null || reviewed.isEmpty) {
        return;
      }

      // Already stale before this push: the person has been told. Repeating it
      // on every subsequent commit turns one useful warning into a stream.
      if (reviewed != event.previousHeadSha) {
        return;
      }

      _eventBus.publish(
        ReviewBecameStale(
          workspaceId: event.workspaceId,
          spaceId: association.spaceId,
          repoOwner: event.repoOwner,
          repoName: event.repoName,
          prNumber: event.prNumber,
          prTitle: event.prTitle,
          reviewedHeadSha: reviewed,
          headSha: event.headSha,
          occurredAt: _now(),
        ),
      );
    } on Object catch (e, st) {
      // A notification is never worth taking the poller down for.
      CcHostLog.warning(
        'stale review watcher: could not evaluate '
        '${event.repoOwner}/${event.repoName}#${event.prNumber}: $e\n$st',
      );
    }
  }
}
