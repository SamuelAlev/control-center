import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/value_objects/notification_kind.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:flutter/widgets.dart';

/// What a long-running-work notification asks of the person
/// (`notification_kind`): `question` and `review` wait for them and open the
/// record they are about; `notify` says something happened. It never decides
/// whether a frame is quiet: that is [isQuietNotification].
enum WorkNotificationKind { notify, question, review }

/// Whether the server marked the frame quiet (`quiet: true`): it shows in
/// the activity list without asking for attention. Only that field decides;
/// a frame without it, or with any other value, is not quiet.
bool isQuietNotification(NotificationFeedItem item) =>
    item.params[notificationQuietKey] == true;

const _goalSettled = 'notifications/goal_settled';
const _ruleEnded = 'notifications/wake_rule_ended';
const _digest = 'notifications/waiting_digest';
const _improvement = 'notifications/improvement_proposed';
const _pipelineHeld = 'notifications/pipeline_run_held';

/// The frames long-running work sends.
const workNotificationMethods = {
  _goalSettled,
  _ruleEnded,
  _digest,
  _improvement,
  _pipelineHeld,
};

String? _string(Map<String, dynamic> p, String key) {
  final value = p[key];
  return value is String && value.isNotEmpty ? value : null;
}

int _int(Map<String, dynamic> p, String key) {
  final value = p[key];
  return value is num ? value.toInt() : 0;
}

/// The frame's `notification_kind`. Null for a frame that is not
/// long-running work, or that carries no kind this version knows.
WorkNotificationKind? workNotificationKind(NotificationFeedItem item) {
  if (!workNotificationMethods.contains(item.method)) return null;
  return switch (NotificationKindWire.tryParse(
    item.params[notificationKindKey],
  )) {
    NotificationKind.notify => WorkNotificationKind.notify,
    NotificationKind.question => WorkNotificationKind.question,
    NotificationKind.review => WorkNotificationKind.review,
    null => null,
  };
}

/// The title of a long-running-work frame, or null for any other frame.
String? workActivityTitle(NotificationFeedItem item, AppLocalizations l) {
  final p = item.params;
  switch (item.method) {
    case _goalSettled:
      final hold = _string(p, 'hold');
      if (hold == 'needs_review') return l.notifGoalNeedsReview;
      if (hold == 'person') return l.notifGoalNeedsPerson;
      return switch (_string(p, 'status')) {
        'completed' => l.notifGoalCompleted,
        'failed' => l.notifGoalFailed,
        'cancelled' => l.notifGoalCancelled,
        'budget_exhausted' => l.notifGoalBudgetExhausted,
        _ => l.notifGoalOnHold,
      };
    case _ruleEnded:
      return l.notifWakeRuleEnded;
    case _digest:
      return l.notifWaitingDigest(_int(p, 'count'));
    case _improvement:
      return l.notifImprovementProposed(
        _int(p, 'count') < 1 ? 1 : _int(p, 'count'),
      );
    case _pipelineHeld:
      return l.notifPipelineRunHeld;
  }
  return null;
}

/// The body of a long-running-work frame: the goal's summary (agent text,
/// made inert), why a schedule ended, a held pipeline run's spend. Null for
/// any other frame or when there is nothing to add.
String? workActivityBody(BuildContext context, NotificationFeedItem item) {
  final l = AppLocalizations.of(context);
  final p = item.params;
  switch (item.method) {
    case _goalSettled:
      final summary = _string(p, 'summary');
      return summary == null ? '' : inertText(summary);
    case _ruleEnded:
      return wakeRuleEndSentence(l, _string(p, 'reason')) ?? '';
    case _pipelineHeld:
      final spent = p['spent_micros'];
      final cap = p['cap_micros'];
      if (spent is! num || cap is! num) return '';
      return l.notifPipelineRunHeldBody(
        planMoney(context, spent.toInt()),
        planMoney(context, cap.toInt()),
      );
    case _digest:
    case _improvement:
      return '';
  }
  return null;
}

String? _conversation(String workspaceId, Map<String, dynamic> p) {
  final space = _string(p, 'space_id');
  if (space == null) return null;
  return remoteSpaceLocation(
    workspaceId: workspaceId,
    spaceId: space,
    conversationId: _string(p, 'conversation_id'),
  );
}

/// Where a long-running-work frame opens: a goal's own route, a schedule's
/// own route, or the conversation. Null when the frame names nothing to
/// open (a digest opens each item instead); [handled] is false for a frame
/// that is not long-running work.
({bool handled, String? location}) workActivityDestination(
  NotificationFeedItem item,
) {
  final p = item.params;
  final ws = item.workspaceId;
  switch (item.method) {
    case _goalSettled:
      final goal = _string(p, 'goal_id');
      return (
        handled: true,
        location: goal == null
            ? _conversation(ws, p)
            : remoteWorkspaceLocation(
                '/goals/${Uri.encodeComponent(goal)}',
                ws,
              ),
      );
    case _ruleEnded:
      final rule = _string(p, 'rule_id');
      return (
        handled: true,
        location: rule == null
            ? _conversation(ws, p)
            : remoteWorkspaceLocation(
                '/schedules/${Uri.encodeComponent(rule)}',
                ws,
              ),
      );
    case _digest:
      return (handled: true, location: null);
    case _improvement:
    case _pipelineHeld:
      return (handled: true, location: _conversation(ws, p));
  }
  return (handled: false, location: null);
}

/// One item of a waiting digest: its label, its summary (data) and where it
/// opens, or null when it names nothing the phone can open.
typedef DigestItem = ({String label, String summary, String? location});

/// The items of a `waiting_digest` frame, in the order sent.
List<DigestItem> digestItems(NotificationFeedItem item, AppLocalizations l) {
  if (item.method != _digest) return const [];
  final raw = item.params['items'];
  if (raw is! List) return const [];
  final ws = item.workspaceId;
  return [
    for (final entry in raw)
      if (entry is Map) _digestItem(ws, Map<String, dynamic>.from(entry), l),
  ].nonNulls.toList();
}

DigestItem? _digestItem(String ws, Map<String, dynamic> p, AppLocalizations l) {
  final type = _string(p, 'type');
  final id = _string(p, 'id');
  final summary = inertText(_string(p, 'summary') ?? '', singleLine: true);
  String? goal() => id == null
      ? null
      : remoteWorkspaceLocation('/goals/${Uri.encodeComponent(id)}', ws);
  switch (type) {
    case 'goal_review':
      return (
        label: l.notifDigestGoalReview,
        summary: summary,
        location: goal(),
      );
    case 'goal_person':
      return (
        label: l.notifDigestGoalPerson,
        summary: summary,
        location: goal(),
      );
    case 'held_wake':
      final space = _string(p, 'space_id');
      final conversation = _string(p, 'conversation_id');
      return (
        label: l.notifDigestHeldWake,
        summary: summary,
        location: space == null || conversation == null
            ? null
            : remoteWorkspaceLocation(
                Uri(
                  pathSegments: ['', 'spaces', space, 'progress'],
                  queryParameters: {'conversation_id': conversation},
                ).toString(),
                ws,
              ),
      );
    case 'improvement':
      return (
        label: l.notifDigestImprovement,
        summary: summary,
        location: _conversation(ws, p),
      );
    case 'request':
      // A question or approval a server-started run waits on: it is
      // answered in its conversation.
      return (
        label: l.notifDigestRequest,
        summary: summary,
        location: _conversation(ws, p),
      );
  }
  return null;
}
