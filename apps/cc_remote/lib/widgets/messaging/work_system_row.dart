import 'package:cc_domain/cc_domain.dart' show AgentDto, MessageDto, UserDto;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/limit_park_card.dart';
import 'package:cc_remote/widgets/messaging/work_row_frame.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `metadata.kind` values of the system rows [WorkSystemRow] renders.
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

/// Whether [message] is a long-running-work system row this app words
/// itself instead of showing the server's English text.
bool isWorkSystemRow(MessageDto message) {
  final meta = message.metadata;
  return message.messageType == 'system' &&
      meta is Map &&
      workSystemRowKinds.contains(meta['kind']);
}

String? _text(Map<dynamic, dynamic> meta, String key) {
  final value = meta[key];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// A long-running-work system row, by `metadata.kind`: a delivered or
/// skipped wake (its headline from `wakeHeadline`), a schedule created,
/// paused by someone, ended or firing its note, a pause at a usage limit, a refused command, a
/// raised pipeline cap or a skill change that could not be applied. Every
/// sentence is the app's; record text (a headline, a note, a refusal with
/// no kind) is quoted as inert plain text.
class WorkSystemRow extends ConsumerWidget {
  const WorkSystemRow({
    super.key,
    required this.message,
    required this.workspaceId,
    required this.users,
  });

  final MessageDto message;
  final String workspaceId;
  final Map<String, UserDto> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final meta = message.metadata is Map
        ? message.metadata as Map<dynamic, dynamic>
        : const <dynamic, dynamic>{};
    final agents = ref.watch(agentsProvider).value ?? const <AgentDto>[];
    String agent(Object? id) {
      final name = id is String
          ? agents.where((a) => a.id == id).firstOrNull?.name
          : null;
      return name == null || name.trim().isEmpty
          ? l.agent
          : inertText(name, singleLine: true);
    }

    String person(Object? id) {
      final user = id is String ? users[id] : null;
      if (user == null) return l.teammate;
      return inertText(
        user.displayName.isNotEmpty ? user.displayName : '@${user.handle}',
        singleLine: true,
      );
    }

    final headline = _text(meta, 'wakeHeadline');
    final quotedHeadline = headline == null
        ? null
        : WorkQuote(headline, maxLines: 2);
    switch (meta['kind']) {
      case 'wake':
        final ids = meta['wakeIds'];
        final count = ids is List && ids.isNotEmpty ? ids.length : 1;
        return WorkRowFrame(
          icon: AppIcons.clock,
          sentence: l.workRowWoke(count, agent(meta['wakeAgentId'])),
          origin: _origin(l, meta, agent),
          detail: [?quotedHeadline],
        );
      case 'wake_skipped':
        final kind = _text(meta, 'wakeSkipKind') ?? '';
        final who = agent(meta['wakeAgentId']);
        final missed = kind == 'wake_missed';
        return WorkRowFrame(
          icon: missed ? AppIcons.calendar : AppIcons.circleSlash,
          sentence: missed
              ? l.workRowWakeMissed(who)
              : l.workRowWakeSkipped(who),
          origin: _origin(l, meta, agent),
          detail: [
            if (!missed && kind.isNotEmpty)
              WorkKindLine(sentence: wakeKindSentence(l, kind), kind: kind),
            ?quotedHeadline,
          ],
        );
      case 'wake_rule_created':
        return WorkRowFrame(
          icon: AppIcons.repeat,
          sentence: l.workRowScheduleCreated(agent(meta['agentId'])),
          action: _openSchedule(context, l, meta),
        );
      case 'wake_rule_ended':
        final reason = _text(meta, 'endReason') ?? '';
        return WorkRowFrame(
          icon: AppIcons.circleX,
          sentence: l.workRowScheduleEnded(agent(meta['agentId'])),
          detail: [
            if (reason.isNotEmpty)
              WorkKindLine(
                sentence: wakeRuleEndSentence(l, reason),
                kind: reason,
              ),
          ],
          action: _openSchedule(context, l, meta),
        );
      case 'wake_rule_paused':
        return WorkRowFrame(
          icon: AppIcons.circleSlash,
          sentence: l.workRowSchedulePaused(
            person(meta['pausedByUserId']),
            agent(meta['agentId']),
          ),
          action: _openSchedule(context, l, meta),
        );
      case 'wake_rule_note':
        return WorkRowFrame(
          icon: AppIcons.messageSquare,
          sentence: meta['noteAuthor'] == 'agent'
              ? l.workRowNoteFromAgent(agent(meta['agentId']))
              : l.workRowNoteFromPerson,
          detail: [
            if (message.content.trim().isNotEmpty)
              WorkQuote(message.content.trim(), maxLines: 6),
          ],
          action: _openSchedule(context, l, meta),
        );
      case 'limit_park':
        final row = limitParkRowOf(message);
        if (row == null) return const SizedBox.shrink();
        if (row.outcome != null) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: 10,
              start: 4,
              end: 4,
            ),
            child: LimitParkSettled(row: row),
          );
        }
        final at = row.resumesAt;
        return WorkRowFrame(
          icon: AppIcons.clock,
          sentence: at == null
              ? l.limitParkGone(row.provider ?? l.limitParkProviderUnknown)
              : row.provider == null
              ? l.limitParkTitleUnnamed(workTime(context, at))
              : l.limitParkTitle(row.provider!, workTime(context, at)),
        );
      case 'command_refused':
        final command = _text(meta, 'command');
        final kind = _text(meta, 'refusalKind');
        final named = const {
          'goal',
          'loop',
          'schedule',
          'refine',
        }.contains(command);
        return WorkRowFrame(
          icon: AppIcons.circleSlash,
          sentence: named
              ? l.workRowCommandRefusedNamed('/$command')
              : l.workRowCommandRefused,
          detail: [
            if (kind != null)
              WorkKindLine(
                sentence: workRefusalSentence(l, kind),
                kind: kind,
                lead: l.workRefusalUnknown,
              )
            else if (message.content.trim().isNotEmpty)
              WorkQuote(message.content.trim(), maxLines: 4),
          ],
        );
      case 'orchestration_cap_raised':
        final from = meta['old_micros'];
        final to = meta['new_micros'];
        return WorkRowFrame(
          icon: AppIcons.circleCheck,
          sentence: from is num && to is num
              ? l.workRowCapRaised(
                  person(meta['user_id']),
                  planMoney(context, from.toInt()),
                  planMoney(context, to.toInt()),
                )
              : l.workRowCapRaisedNoAmounts(person(meta['user_id'])),
        );
      case 'improvement_apply_incomplete':
        final skill = _text(meta, 'skill_slug');
        return WorkRowFrame(
          icon: AppIcons.triangleAlert,
          sentence: l.workRowApplyIncomplete,
          detail: [?(skill == null ? null : WorkCode(skill, maxLines: 1))],
        );
    }
    return const SizedBox.shrink();
  }

  String? _origin(
    AppLocalizations l,
    Map<dynamic, dynamic> meta,
    String Function(Object?) agent,
  ) {
    final reason = WakeReasonWire.tryParse(meta['wakeReason']);
    if (reason == null) return null;
    final source = meta['wakeSourceAgentId'];
    return wakeOriginLabel(
      l,
      reason,
      agentName: source is String ? agent(source) : null,
    );
  }

  Widget? _openSchedule(
    BuildContext context,
    AppLocalizations l,
    Map<dynamic, dynamic> meta,
  ) {
    final ruleId = _text(meta, 'ruleId');
    if (ruleId == null || workspaceId.isEmpty) return null;
    return CcButton(
      size: CcButtonSize.lg,
      variant: CcButtonVariant.ghost,
      onPressed: () => context.push(
        remoteWorkspaceLocation(
          '/schedules/${Uri.encodeComponent(ruleId)}',
          workspaceId,
        ),
      ),
      child: Text(l.workRowOpenSchedule),
    );
  }
}
