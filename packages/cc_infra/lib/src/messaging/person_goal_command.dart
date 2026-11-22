import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/features/dispatch/domain/services/wake_rule_command.dart'
    show isWakeRuleCommand;
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Starts a durable goal from a signed-in person's `/goal …` message (the
/// goal supervisor's start, injected so the messaging layer never imports
/// it). Returns the first run's id, or null when nothing was dispatched.
/// Refuses with an `AppException` carrying a `data.kind` code
/// (`goal_already_active`).
typedef PersonGoalCommand =
    Future<String?> Function({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      required String requestedByUserId,
      String? conversationId,
    });

/// Whether [prompt] is a `/goal …` command (exact token, case-sensitive, the
/// same rule as `parseSlashCommand`). Only a person's message acts on it.
bool isGoalCommand(String prompt) => prompt.trimLeft().startsWith('/goal ');

/// Whether [prompt] is a `/refine` command (an improvement review of the
/// conversation's work): the exact token, alone or followed by a space.
bool isRefineCommand(String prompt) {
  final trimmed = prompt.trim();
  return trimmed == '/refine' || trimmed.startsWith('/refine ');
}

/// Whether [prompt] is a command only a signed-in person's own message acts
/// on: `/goal`, `/refine`, `/loop` or `/schedule`. Text from anything else
/// (a peer, a pipeline, a webhook, a wake) is ordinary text.
bool isPersonCommand(String prompt) =>
    isGoalCommand(prompt) ||
    isRefineCommand(prompt) ||
    isWakeRuleCommand(prompt);

/// One handler for every person command: `/loop` and `/schedule` go to
/// [wakeRules], `/refine` to [refine], everything else to [goals].
PersonGoalCommand personCommands({
  required PersonGoalCommand goals,
  required PersonGoalCommand wakeRules,
  required PersonGoalCommand refine,
}) =>
    ({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      required String requestedByUserId,
      String? conversationId,
    }) {
      final handler = isWakeRuleCommand(prompt)
          ? wakeRules
          : isRefineCommand(prompt)
          ? refine
          : goals;
      return handler(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: agentId,
        prompt: prompt,
        requestedByUserId: requestedByUserId,
        conversationId: conversationId,
      );
    };

/// The `kind` of the system row saying a person's command was refused.
const String commandRefusedRowKind = 'command_refused';

/// The command word of a person command [prompt], as [personCommands]
/// routes it: `loop`, `schedule`, `refine`, else `goal`.
String personCommandWord(String prompt) {
  if (isWakeRuleCommand(prompt)) {
    return prompt.trimLeft().startsWith('/loop') ? 'loop' : 'schedule';
  }
  return isRefineCommand(prompt) ? 'refine' : 'goal';
}

/// The metadata of the row saying a person's [command] (its word: `goal`,
/// `loop`, `schedule`, `refine`) was refused: `kind` [commandRefusedRowKind],
/// `refusalKind` (the refusal's `data.kind`, when it has one) and `command`.
/// The row's text is the refusal's plain English message.
Map<String, Object?> commandRefusedRowMetadata({
  required String command,
  required String? refusalKind,
}) => {
  'kind': commandRefusedRowKind,
  'refusalKind': ?refusalKind,
  'command': command,
};

/// The [startGoalFromMessage] `say` that posts the refusal as a system row
/// of the conversation through [messages].
Future<void> Function(String message, Map<String, Object?> metadata)
commandRefusalPoster(
  MessagingRepository messages, {
  required String workspaceId,
  required String spaceId,
  required String? conversationId,
}) =>
    (message, metadata) => messages.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: message,
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
      conversationId: conversationId,
      metadata: metadata,
    );

/// Starts the command a person's message asked for, off the send path. A
/// refusal (another goal is active, a command that does not read) is said
/// in the conversation through [say] as one typed row
/// ([commandRefusedRowMetadata]): the message was already stored, so there
/// is no caller to throw to.
Future<void> startGoalFromMessage(
  PersonGoalCommand handler, {
  required String workspaceId,
  required String spaceId,
  required String agentId,
  required String prompt,
  required String requestedByUserId,
  required String? conversationId,
  required Future<void> Function(String message, Map<String, Object?> metadata)
  say,
}) async {
  try {
    await handler(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      prompt: prompt,
      requestedByUserId: requestedByUserId,
      conversationId: conversationId,
    );
  } on AppException catch (e) {
    await say(
      e.message,
      commandRefusedRowMetadata(
        command: personCommandWord(prompt),
        refusalKind: e.code,
      ),
    );
  }
}
