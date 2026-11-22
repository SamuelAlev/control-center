import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/still_in_flight_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/limit_park_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/still_in_flight_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_learning_rows.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_row_frame.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `metadata.kind` values a [WorkSystemRow] renders.
const Set<String> workSystemRowKinds = {
  'wake',
  'wake_skipped',
  'wake_rule_created',
  'wake_rule_ended',
  'wake_rule_paused',
  'wake_rule_note',
  'limit_park',
  'command_refused',
  'orchestration_cap_raised',
  'improvement_apply_incomplete',
};

/// Whether [message] is a long-running-work system row this client renders
/// as its own row rather than as plain system text.
bool isWorkSystemRow(Message message) {
  final meta = message.metadata;
  if (!message.isSystem || meta == null) {
    return false;
  }
  return meta[stillInFlightRowKey] is String ||
      workSystemRowKinds.contains(meta['kind']);
}

/// A long-running-work system row, by `metadata.kind`: a delivered or skipped
/// wake, a schedule created, paused, ended or firing its note, a pause at a usage
/// limit, the state handed on after compaction, a refused command, a raised
/// pipeline cap or an improvement that could not be applied. Every sentence
/// is the client's; the server's text is used only for the note, and for a
/// refusal without a kind, both shown as plain quoted text.
class WorkSystemRow extends ConsumerWidget {
  /// Creates the row; [message] must satisfy [isWorkSystemRow].
  const WorkSystemRow({super.key, required this.message});

  /// The system row.
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = message.metadata ?? const <String, dynamic>{};
    final workspaceId = ref.watch(activeWorkspaceIdProvider) ?? '';
    final l10n = AppLocalizations.of(context);
    String agent(Object? id) {
      final name = id is String
          ? ref.watch(
              workAgentNameProvider((workspaceId: workspaceId, agentId: id)),
            )
          : null;
      return name ?? l10n.workAgentUnknown;
    }

    String person(Object? id) {
      final users = ref.watch(usersByIdProvider).value;
      final user = id is String && users != null ? users[id] : null;
      final name = user?.displayName.trim();
      return name == null || name.isEmpty
          ? l10n.workFeedPersonUnknown
          : inertText(name, singleLine: true);
    }

    final stillFor = meta[stillInFlightRowKey];
    if (stillFor is String) {
      return StillInFlightRow(message: message, agentName: agent(stillFor));
    }
    switch (meta['kind']) {
      case 'limit_park':
        return LimitParkCard(message: message, workspaceId: workspaceId);
      case 'wake':
        return _wakeRow(context, l10n, meta, agent);
      case 'wake_skipped':
        return _skippedRow(context, l10n, meta, agent);
      case 'wake_rule_created':
        return WorkRowFrame(
          icon: AppIcons.calendarClock,
          sentence: l10n.workFeedScheduleCreated(agent(meta['agentId'])),
          trailing: _openSchedule(context, l10n, workspaceId, meta),
        );
      case 'wake_rule_ended':
        final reason = meta['endReason'] as String? ?? '';
        return WorkRowFrame(
          icon: AppIcons.calendarX,
          sentence: l10n.workFeedScheduleEnded(agent(meta['agentId'])),
          detail: KindSentence(
            sentence: wakeRuleEndReasonSentence(l10n, reason),
            lead: l10n.wakeKindUnknown,
            kind: reason,
          ),
          trailing: _openSchedule(context, l10n, workspaceId, meta),
        );
      case 'wake_rule_paused':
        // Someone other than its person paused the schedule.
        return WorkRowFrame(
          icon: AppIcons.pauseCircle,
          sentence: l10n.workFeedSchedulePaused(
            person(meta['pausedByUserId']),
            agent(meta['agentId']),
          ),
          trailing: _openSchedule(context, l10n, workspaceId, meta),
        );
      case 'wake_rule_note':
        final byAgent = meta['noteAuthor'] == 'agent';
        return WorkRowFrame(
          icon: AppIcons.quote,
          sentence: byAgent
              ? l10n.workFeedNoteFromAgent(agent(meta['agentId']))
              : l10n.workFeedNoteFromPerson,
          detail: WorkQuote(text: quotedLines(message.content)),
          trailing: _openSchedule(context, l10n, workspaceId, meta),
        );
      case 'command_refused':
        return _refusedRow(context, l10n, meta);
      case 'orchestration_cap_raised':
        return CapRaisedRow(message: message);
      case 'improvement_apply_incomplete':
        return ApplyIncompleteRow(message: message, workspaceId: workspaceId);
    }
    return const SizedBox.shrink();
  }

  Widget _wakeRow(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> meta,
    String Function(Object?) agent,
  ) {
    final ids = meta['wakeIds'];
    final count = ids is List && ids.isNotEmpty ? ids.length : 1;
    final reason = WakeReasonWire.tryParse(meta['wakeReason']);
    return WorkRowFrame(
      icon: reason == null ? AppIcons.zap : wakeOriginIcon(reason),
      sentence: l10n.workFeedWoke(count, agent(meta['wakeAgentId'])),
      chip: reason == null
          ? null
          : _originChip(l10n, reason, meta['wakeSourceAgentId'], agent),
      detail: _headline(context, meta),
    );
  }

  /// A refused slash command: which command, and the refusal's sentence by
  /// `refusalKind`. The row's text (the server's English message) shows only
  /// when the refusal has no kind.
  Widget _refusedRow(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> meta,
  ) {
    final command = meta['command'];
    final kind = meta['refusalKind'];
    final named = const {
      'goal',
      'loop',
      'schedule',
      'refine',
    }.contains(command);
    return WorkRowFrame(
      icon: AppIcons.ban,
      sentence: named
          ? l10n.workFeedCommandRefusedNamed(command as String)
          : l10n.workFeedCommandRefused,
      detail: kind is String && kind.isNotEmpty
          ? KindSentence(
              sentence: workRefusalSentence(l10n, kind),
              lead: l10n.workRefusalUnknown,
              kind: kind,
            )
          : (message.content.trim().isEmpty
                ? null
                : WorkQuote(text: inertText(message.content.trim()))),
    );
  }

  Widget _skippedRow(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> meta,
    String Function(Object?) agent,
  ) {
    final kind = meta['wakeSkipKind'] as String? ?? '';
    final reason = WakeReasonWire.tryParse(meta['wakeReason']);
    final who = agent(meta['wakeAgentId'] ?? meta['agentId']);
    if (kind == 'wake_missed') {
      return WorkRowFrame(
        icon: AppIcons.calendarX,
        sentence: l10n.workFeedWakeMissed(who),
        chip: reason == null
            ? null
            : _originChip(l10n, reason, meta['wakeSourceAgentId'], agent),
        detail: _headline(context, meta),
      );
    }
    return WorkRowFrame(
      icon: AppIcons.ban,
      sentence: l10n.workFeedWakeSkipped(who),
      chip: reason == null
          ? null
          : _originChip(l10n, reason, meta['wakeSourceAgentId'], agent),
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          KindSentence(
            sentence: wakeKindSentence(l10n, kind),
            lead: l10n.wakeKindUnknown,
            kind: kind,
          ),
          ?_headline(context, meta),
        ],
      ),
    );
  }

  Widget _originChip(
    AppLocalizations l10n,
    WakeReason reason,
    Object? sourceAgentId,
    String Function(Object?) agent,
  ) => CcBadge(
    label: wakeOriginLabel(
      l10n,
      reason,
      agentName: sourceAgentId is String ? agent(sourceAgentId) : null,
    ),
    icon: wakeOriginIcon(reason),
  );

  /// The wake's headline (`metadata.wakeHeadline`, already neutralised and
  /// cut by the server), as plain text; nothing when the row has none.
  Widget? _headline(BuildContext context, Map<String, dynamic> meta) {
    final raw = meta['wakeHeadline'];
    final headline = raw is String ? raw.trim() : '';
    if (headline.isEmpty) {
      return null;
    }
    return Text(
      inertText(headline, singleLine: true),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CcTypography.caption.copyWith(color: context.ds.textTertiary),
    );
  }

  Widget? _openSchedule(
    BuildContext context,
    AppLocalizations l10n,
    String workspaceId,
    Map<String, dynamic> meta,
  ) {
    final ruleId = meta['ruleId'];
    if (ruleId is! String || workspaceId.isEmpty) {
      return null;
    }
    return CcIconButton(
      icon: AppIcons.externalLink,
      size: CcButtonSize.sm,
      tooltip: l10n.workFeedOpenSchedule,
      onPressed: () => context.go(scheduleRoute(workspaceId, ruleId)),
    );
  }
}

/// The note lines of a schedule's note row: the server quotes each line
/// with `> `. Falls back to the whole text when nothing is quoted.
String quotedLines(String content) {
  final lines = [
    for (final line in content.split('\n'))
      if (line.startsWith('> ') || line == '>')
        line.length > 2 ? line.substring(2) : '',
  ];
  return lines.isEmpty ? content.trim() : lines.join('\n');
}
