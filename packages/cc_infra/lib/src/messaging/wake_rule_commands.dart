import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_rule_command.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_infra/src/dispatch/wake_rule_service.dart';
import 'package:cc_infra/src/messaging/person_goal_command.dart';

/// The `kind` of the row a `/loop` or `/schedule` posts.
const String wakeRuleCreatedRowKind = 'wake_rule_created';

/// The handler of a signed-in person's `/loop …` and `/schedule …` (the same
/// path `/goal` takes): reads the command, creates the person's rule, and
/// posts one compact row saying what was created, when it fires next and
/// when it ends. A command that does not read, or a rule the limits refuse,
/// throws a [ValidationException] with its `data.kind`; the composer path
/// says it in the conversation.
///
/// Returns null: the rule's first wake starts the first run.
PersonGoalCommand wakeRuleCommands({
  required WakeRuleService Function() service,
  required Future<String> Function(String workspaceId, String spaceId)
  standingConversation,
  required Future<String?> Function(String workspaceId, String conversationId)
  conversationSpace,
  required Future<void> Function({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required Map<String, Object?> metadata,
  })
  postRow,
}) =>
    ({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      required String requestedByUserId,
      String? conversationId,
    }) async {
      final command = parseWakeRuleCommand(prompt);
      switch (command) {
        case null:
          throw const ValidationException(
            'Not a /loop or /schedule command.',
            code: WakeRuleRefusals.invalidWhen,
          );
        case WakeRuleCommandInvalid(:final message):
          throw ValidationException(
            message,
            code: WakeRuleRefusals.invalidWhen,
          );
        case WakeRuleCommandRequest():
          final conversation =
              conversationId ??
              await standingConversation(workspaceId, spaceId);
          if (await conversationSpace(workspaceId, conversation) != spaceId) {
            throw const ValidationException(
              'That conversation is not in this space.',
            );
          }
          final rule = await service().create(
            WakeRuleRequest(
              workspaceId: workspaceId,
              conversationId: conversation,
              agentId: agentId,
              when: command.when,
              clock: command.clock,
              note: command.prompt,
              origin: WakeRuleOrigin.person,
              maxRuns: command.maxRuns,
              expiresIn: command.days == null
                  ? null
                  : Duration(days: command.days!),
              costCapMicros: command.budgetMicros,
              createdByUserId: requestedByUserId,
              requestedByUserId: requestedByUserId,
              // A loop starts now; a schedule waits for its time.
              fireNow: command.command == 'loop',
            ),
          );
          await postRow(
            workspaceId: workspaceId,
            spaceId: rule.spaceId,
            conversationId: rule.conversationId,
            content: wakeRuleCreatedRowText(rule, command: command.command),
            metadata: {
              'kind': wakeRuleCreatedRowKind,
              'ruleId': rule.id,
              'agentId': rule.agentId,
            },
          );
          return null;
      }
    };

/// The row a `/loop` or `/schedule` posts: what was created, when it fires
/// next, when it ends (times in UTC).
String wakeRuleCreatedRowText(WakeRule rule, {required String command}) {
  final what = switch (rule.trigger) {
    SelfPaced() => 'Loop set at the agent\'s own pace',
    Every() => 'Loop set, ${formatWakeWhen(rule.trigger)}',
    _ when command == 'loop' => 'Loop set, ${formatWakeWhen(rule.trigger)}',
    _ => 'Scheduled, ${formatWakeWhen(rule.trigger)}',
  };
  final zone = formatWakeZone(rule.trigger);
  final next = rule.nextFireAt;
  final parts = [
    zone == null ? what : '$what ($zone)',
    if (next != null) 'next run ${_utc(next)}',
    if (rule.maxRuns != null) 'at most ${rule.maxRuns} runs',
    'ends ${_utc(rule.expiresAt)}',
    'budget ${(rule.costCapMicros / 1000000).toStringAsFixed(2)} USD',
  ];
  return '${parts.join(' · ')}: "${wakeRuleNoteGist(rule.note)}"';
}

String _utc(DateTime at) {
  final u = at.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${two(u.month)}-${two(u.day)} '
      '${two(u.hour)}:${two(u.minute)} UTC';
}
