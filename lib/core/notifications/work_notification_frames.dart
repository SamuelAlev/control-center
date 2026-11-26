// The long-running-work notification frames: a goal settled or needs a
// person, a schedule ended, improvements were proposed, a pipeline run is
// held at its budget, and the daily digest of what waits. Split out of
// `notification_frame_mapper.dart`, which hands every method it does not
// know to [mapWorkNotificationFrame].
//
// Whether a frame toasts and sounds is the server's `quiet` field, never its
// `notification_kind`: every frame carries a kind (a new message is
// `notify`), and only a terminal `goal_settled` and `wake_rule_ended` are
// quiet. The kind picks the category only: `notify` (something finished) or
// `question` / `review` (a person is needed). Titles are the client's sentences; a frame's `summary` is agent text and
// goes in the body as plain text. Taps open the record: the goal's page, the
// schedule's page, the improvement, the conversation, or the inbox.
library;

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/features/notifications/domain/value_objects/notification_kind.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// The methods [mapWorkNotificationFrame] maps.
const Set<String> workNotificationMethods = {
  'notifications/goal_settled',
  'notifications/wake_rule_ended',
  'notifications/waiting_digest',
  'notifications/improvement_proposed',
  'notifications/pipeline_run_held',
};

/// Whether the server marked a frame quiet (`quiet: true`): recorded in the
/// bell, never a sound or a toast. A frame without the field is not quiet.
bool isQuietFrame(Map<String, dynamic> params) =>
    params[notificationQuietKey] == true;

/// Maps one long-running-work frame, or null for any other method or a frame
/// without its workspace.
AppNotification? mapWorkNotificationFrame(
  String method,
  Map<String, dynamic> p, {
  required AppLocalizations l10n,
}) {
  final workspaceId = p['workspace_id'];
  if (workspaceId is! String || workspaceId.isEmpty) {
    return null;
  }
  final category = p[notificationKindKey] == NotificationKind.notify.wire
      ? NotificationCategory.agentRunCompleted
      : NotificationCategory.agentAwaitingInput;
  final presentation = isQuietFrame(p)
      ? NotificationPresentation.centerOnly
      : NotificationPresentation.notification;
  final spaceId = p['space_id'] as String?;
  AppNotification note(String title, String body, String route) =>
      AppNotification(
        category: category,
        title: title,
        body: body,
        route: route,
        workspaceId: workspaceId,
        spaceId: spaceId,
        presentation: presentation,
      );
  switch (method) {
    case 'notifications/goal_settled':
      final goalId = p['goal_id'] as String?;
      final title = switch ((p['status'] as String?, p['hold'] as String?)) {
        ('completed', _) => l10n.notifGoalCompleted,
        ('failed', _) => l10n.notifGoalFailed,
        ('cancelled', _) => l10n.notifGoalCancelled,
        ('budget_exhausted', _) => l10n.notifGoalBudgetExhausted,
        (_, 'needs_review') => l10n.notifGoalNeedsReview,
        (_, 'person') => l10n.notifGoalNeedsPerson,
        _ => l10n.notifGoalOnHold,
      };
      return note(
        title,
        _plain(p['summary']),
        goalId != null &&
                goalId.isNotEmpty &&
                spaceId != null &&
                spaceId.isNotEmpty
            ? spaceRoute(workspaceId, spaceId, tab: goalTabKey(goalId))
            : _conversation(workspaceId, p),
      );
    case 'notifications/wake_rule_ended':
      final ruleId = p['rule_id'] as String?;
      return note(
        l10n.notifWakeRuleEnded,
        '',
        ruleId == null
            ? _conversation(workspaceId, p)
            : scheduleRoute(workspaceId, ruleId),
      );
    case 'notifications/waiting_digest':
      final items = p['items'] is List ? p['items'] as List : const [];
      final count = (p['count'] as num?)?.toInt() ?? items.length;
      return note(
        l10n.notifWaitingDigest(count),
        [
          for (final item in items.take(3))
            if (item is Map) _plain(item['summary']),
        ].where((s) => s.isNotEmpty).join('\n'),
        inboxRoute(workspaceId),
      );
    case 'notifications/improvement_proposed':
      final ids = p['proposal_ids'] is List
          ? p['proposal_ids'] as List
          : const [];
      final count = (p['count'] as num?)?.toInt() ?? ids.length;
      return note(
        l10n.notifImprovementProposed(count),
        '',
        ids.length == 1 && ids.single is String
            ? memoryImprovementRoute(workspaceId, ids.single as String)
            : memoryImprovementsRoute(workspaceId),
      );
    case 'notifications/pipeline_run_held':
      final spent = (p['spent_micros'] as num?)?.toInt() ?? 0;
      final cap = (p['cap_micros'] as num?)?.toInt() ?? 0;
      return note(
        l10n.notifPipelineRunHeld,
        l10n.notifPipelineRunHeldBody(
          fmtMicros(spent, decimals: 2),
          fmtMicros(cap, decimals: 2),
        ),
        _conversation(workspaceId, p),
      );
  }
  return null;
}

/// The route a digest item opens: the goal's page for a goal waiting on a
/// person, the improvement for a proposal, the conversation for a held wake
/// and for a `request` (an approval or question of a run the server started,
/// answered where it was asked); any other type also opens its conversation.
String waitingDigestItemRoute(String workspaceId, Map<String, dynamic> item) {
  final id = item['id'] as String? ?? '';
  return switch (item['type']) {
    'goal_review' ||
    'goal_person' when id.isNotEmpty => _goalInSpace(workspaceId, item, id),
    'improvement' when id.isNotEmpty => memoryImprovementRoute(workspaceId, id),
    'held_wake' || 'request' => _conversation(workspaceId, item),
    _ => _conversation(workspaceId, item),
  };
}

String _goalInSpace(
  String workspaceId,
  Map<String, dynamic> item,
  String goalId,
) {
  final spaceId = item['space_id'] as String?;
  if (spaceId == null || spaceId.isEmpty) {
    return _conversation(workspaceId, item);
  }
  return spaceRoute(workspaceId, spaceId, tab: goalTabKey(goalId));
}

String _conversation(String workspaceId, Map<String, dynamic> p) {
  final spaceId = p['space_id'] as String?;
  if (spaceId == null || spaceId.isEmpty) {
    return inboxRoute(workspaceId);
  }
  final conversationId = p['conversation_id'] as String?;
  return spaceRoute(
    workspaceId,
    spaceId,
    tab: conversationId == null ? null : conversationTabKey(conversationId),
  );
}

/// Agent text for a notification body: one plain line, no control characters.
String _plain(Object? raw) {
  if (raw is! String) {
    return '';
  }
  return raw
      .replaceAll(
        RegExp(r'[\x00-\x1F\x7F-\x9F\u202A-\u202E\u2066-\u2069]'),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
