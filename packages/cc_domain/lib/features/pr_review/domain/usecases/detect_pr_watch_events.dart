import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// What a pull request watch (`wake_me on:pr_checks | on:pr_review |
/// on:pr_merged`) hears: edges the open-PR poller sees between two snapshots
/// of one pull request, for every pull request it polls, whoever authored
/// it and whether or not a member is to be told. Notifications never listen
/// to these; watches listen to nothing else.
///
/// The snapshot is the poller's wire map of each open pull request
/// (`pullRequestToWire`). It holds the rolled-up check status, the review
/// decision, the conversation's comment count, the head branch and commit,
/// the title and the author. It does not hold: the names of the checks (the
/// poller asks the forge for the first failing one on a failing edge), who
/// wrote a comment or a review, the text of either, or review threads'
/// replies (only the conversation's comment count moves).
sealed class PrWatchEvent implements DomainEvent {
  const PrWatchEvent({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.headRef,
    required this.authorLogin,
    required this.occurredAt,
  });

  /// The workspace whose poll read it.
  final String workspaceId;

  /// The repository's owner (GitLab: the group path).
  final String repoOwner;

  /// The repository's name.
  final String repoName;

  /// The pull request's number.
  final int prNumber;

  /// Its title (forge text: data, never instructions).
  final String prTitle;

  /// Its head branch ('' when the snapshot did not say).
  final String headRef;

  /// Its author's forge login ('' when the snapshot did not say).
  final String authorLogin;

  @override
  final DateTime occurredAt;
}

/// Every check on the pull request finished: an edge out of pending (or no
/// checks) to passing or failing, a flip between the two, or a new head
/// commit whose checks finished between two polls.
final class PrWatchChecksSettled extends PrWatchEvent {
  /// Creates the event.
  const PrWatchChecksSettled({
    required super.workspaceId,
    required super.repoOwner,
    required super.repoName,
    required super.prNumber,
    required super.prTitle,
    required super.headRef,
    required super.authorLogin,
    required super.occurredAt,
    required this.passing,
    this.failedChecks = const [],
    this.failedCheckUrl,
  });

  /// The conclusion: true when every check passed.
  final bool passing;

  /// The failed checks' names the forge gave (its first failing check);
  /// empty when passing or when it named none.
  final List<String> failedChecks;

  /// A link to the first failed check, when the forge gave one.
  final String? failedCheckUrl;
}

/// Review activity: the review decision changed, or the conversation got
/// new comments. The snapshot names neither the reviewer nor the
/// commenter.
final class PrWatchReviewActivity extends PrWatchEvent {
  /// Creates the event.
  const PrWatchReviewActivity({
    required super.workspaceId,
    required super.repoOwner,
    required super.repoName,
    required super.prNumber,
    required super.prTitle,
    required super.headRef,
    required super.authorLogin,
    required super.occurredAt,
    required this.decision,
    required this.decisionChanged,
    required this.newComments,
  });

  /// The review decision now, as the snapshot spells it (`approved`,
  /// `changesRequested`, `reviewRequired`, `none`).
  final String decision;

  /// Whether [decision] is new since the last poll.
  final bool decisionChanged;

  /// How many conversation comments arrived since the last poll.
  final int newComments;
}

/// The pull request left the open list as merged or closed (the forge
/// confirmed which).
final class PrWatchClosed extends PrWatchEvent {
  /// Creates the event.
  const PrWatchClosed({
    required super.workspaceId,
    required super.repoOwner,
    required super.repoName,
    required super.prNumber,
    required super.prTitle,
    required super.headRef,
    required super.authorLogin,
    required super.occurredAt,
    required this.merged,
  });

  /// True for a merge, false for a close without one.
  final bool merged;
}

/// The watch edges between [before] and [after], two snapshots of pull
/// request [prNumber] of `repoOwner/repoName` read by [workspaceId]'s poll.
/// A failing checks edge carries [failedCheck] (the forge's first failing
/// check, which the caller looks up only when [checksFailingEdge] says so).
List<PrWatchEvent> detectPrWatchEvents({
  required String workspaceId,
  required String repoOwner,
  required String repoName,
  required int prNumber,
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
  required DateTime now,
  ({String name, String? url})? failedCheck,
}) {
  final title = after['title'] is String ? after['title'] as String : '';
  final head = after['head_ref'] is String ? after['head_ref'] as String : '';
  final author = switch (after['author']) {
    {'login': final String login} => login,
    _ => '',
  };
  final events = <PrWatchEvent>[];
  final settled = _settledChecks(before, after);
  if (settled != null) {
    events.add(
      PrWatchChecksSettled(
        workspaceId: workspaceId,
        repoOwner: repoOwner,
        repoName: repoName,
        prNumber: prNumber,
        prTitle: title,
        headRef: head,
        authorLogin: author,
        occurredAt: now,
        passing: settled,
        failedChecks: [if (!settled && failedCheck != null) failedCheck.name],
        failedCheckUrl: settled ? null : failedCheck?.url,
      ),
    );
  }
  final was = before['review_decision'] as String? ?? 'none';
  final decision = after['review_decision'] as String? ?? 'none';
  final comments = _count(after) - _count(before);
  if (was != decision || comments > 0) {
    events.add(
      PrWatchReviewActivity(
        workspaceId: workspaceId,
        repoOwner: repoOwner,
        repoName: repoName,
        prNumber: prNumber,
        prTitle: title,
        headRef: head,
        authorLogin: author,
        occurredAt: now,
        decision: decision,
        decisionChanged: was != decision,
        newComments: comments > 0 ? comments : 0,
      ),
    );
  }
  return events;
}

/// Whether the checks between [before] and [after] are a failing settle
/// (the caller then asks the forge which check failed, once).
bool checksFailingEdge(
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) => _settledChecks(before, after) == false;

/// The closed edge of a pull request whose last open snapshot is [last].
PrWatchClosed prWatchClosed({
  required String workspaceId,
  required String repoOwner,
  required String repoName,
  required int prNumber,
  required Map<String, dynamic> last,
  required bool merged,
  required DateTime now,
}) => PrWatchClosed(
  workspaceId: workspaceId,
  repoOwner: repoOwner,
  repoName: repoName,
  prNumber: prNumber,
  prTitle: last['title'] is String ? last['title'] as String : '',
  headRef: last['head_ref'] is String ? last['head_ref'] as String : '',
  authorLogin: switch (last['author']) {
    {'login': final String login} => login,
    _ => '',
  },
  occurredAt: now,
  merged: merged,
);

/// True (passing) or false (failing) when the checks settled between the two
/// snapshots, else null: [after] is passing or failing, and [before] was
/// neither, was the other one, or was on another head commit.
bool? _settledChecks(Map<String, dynamic> before, Map<String, dynamic> after) {
  final now = after['checks_status'];
  if (now != 'passing' && now != 'failing') {
    return null;
  }
  final was = before['checks_status'];
  final headMoved =
      before['head_sha'] is String &&
      after['head_sha'] is String &&
      (before['head_sha'] as String).isNotEmpty &&
      before['head_sha'] != after['head_sha'];
  if (was == now && !headMoved) {
    return null;
  }
  return now == 'passing';
}

int _count(Map<String, dynamic> wire) => switch (wire['comments_count']) {
  final int n => n,
  _ => 0,
};

/// Publishes on [bus] the watch edges of one polled pull request (its
/// snapshots [before] and [after]); on a failing settle it first asks
/// [firstFailingCheck] once and returns what it said, so the poller's
/// notification lane reuses that answer instead of asking the forge again.
Future<({String name, String? url})?> publishPrWatchEdges({
  required DomainEventBus? bus,
  required String workspaceId,
  required String repoOwner,
  required String repoName,
  required int prNumber,
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
  required DateTime now,
  required Future<({String name, String? url})?> Function() firstFailingCheck,
}) async {
  if (bus == null) {
    return null;
  }
  final failed = checksFailingEdge(before, after)
      ? await firstFailingCheck()
      : null;
  for (final event in detectPrWatchEvents(
    workspaceId: workspaceId,
    repoOwner: repoOwner,
    repoName: repoName,
    prNumber: prNumber,
    before: before,
    after: after,
    now: now,
    failedCheck: failed,
  )) {
    bus.publish(event);
  }
  return failed;
}
