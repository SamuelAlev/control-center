/// The client-side slash commands a space composer intercepts before anything
/// travels to an agent.
///
/// Split out of `space_input_bar.dart`, which had become a long `if` chain
/// wrapped in a widget. The chain is its own concern — "which submissions never
/// become a turn" — and it is what pushed that file past the presentation size
/// budget.
library;

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_harness/cc_harness.dart' show ParsedSlashCommand;
import 'package:control_center/features/messaging/presentation/widgets/composer/context_command.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/local_slash_commands.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/todos/providers/todo_command_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs whichever local command [parsed] names, if any.
///
/// Returns the content the send path should carry on with, or **null** when the
/// submission was fully handled here and must not be sent. A submission that is
/// not a command comes back as [rawContent], unchanged.
///
/// Two commands rewrite rather than consume: `/plan` arms the conversation's
/// mode and continues with the rest of the line, and `/goal` substitutes the
/// sharpened objective in place so the rest of the send path — mentions,
/// steering, persistence — sees an ordinary `/goal …` message.
Future<String?> dispatchLocalSlashCommand({
  required WidgetRef ref,
  required BuildContext context,
  required ParsedSlashCommand parsed,
  required String rawContent,
  required String spaceId,
  required String conversationId,
  required String workspaceId,
}) async {
  if (!parsed.isCommand) {
    return rawContent;
  }
  var content = rawContent;

  // `/plan` sets the conversation's mode rather than travelling as text. The
  // server also recognizes it (from the raw user text), but flipping the mode
  // here is what makes the tool surface, guard preset, sandbox and prompt
  // agree for THIS turn and every turn after it.
  if (parsed.command == 'plan') {
    await ref.read(activeSpaceModeProvider.notifier).setMode(Mode.plan);
    final rest = parsed.args.trim();
    if (rest.isEmpty) {
      // A bare `/plan` just arms the mode; there is nothing to say yet.
      return null;
    }
    content = rest;
    if (!context.mounted) {
      return null;
    }
  }

  // `/todo …` is handled entirely on the client (view/edit the persisted list)
  // — it never reaches the agent.
  if (parsed.command == 'todo') {
    await handleTodoSlashCommand(
      ref: ref,
      context: context,
      spaceId: spaceId,
      workspaceId: workspaceId,
      args: parsed.args,
    );
    return null;
  }

  // `/compact` folds older history into an anchored summary server-side and
  // — like `/todo` — never travels as a space message: persisting it would
  // push the planner's cut one turn back and pollute the transcript. The
  // conversation then continues on the compacted context.
  if (parsed.command == 'compact') {
    if (context.mounted) {
      await handleCompactCommand(
        ref: ref,
        context: context,
        spaceId: spaceId,
        conversationId: conversationId,
      );
    }
    return null;
  }

  // `/shake` drops heavy content WITHOUT summarizing — no model call, every
  // word kept, only the bulk nobody was going to re-read is blanked. Like
  // `/compact` it is a local command and never lands in the transcript.
  if (parsed.command == 'shake') {
    if (context.mounted) {
      await handleShakeCommand(
        ref: ref,
        context: context,
        args: parsed.args,
        spaceId: spaceId,
        conversationId: conversationId,
      );
    }
    return null;
  }

  // `/tree`, `/export` and `/dump` are pure inspection: they never travel as a
  // message and never reach an agent.
  if (const {'tree', 'export', 'dump'}.contains(parsed.command) &&
      context.mounted) {
    await handleConversationToolCommand(
      ref: ref,
      context: context,
      command: parsed.command!,
      spaceId: spaceId,
      conversationId: conversationId,
    );
    return null;
  }

  // `/context` opens the context explorer for this conversation's agent as a
  // tab of its own. Pure inspection — it never travels as a message.
  if (parsed.command == 'context') {
    if (context.mounted) {
      await handleContextCommand(
        ref: ref,
        context: context,
        args: parsed.args,
        spaceId: spaceId,
        workspaceId: workspaceId,
      );
    }
    return null;
  }

  // `/goal` opens the objective interview first. An autonomous goal is the one
  // place a vague brief is genuinely expensive — the run works for hours on an
  // objective whose "done" nobody defined, then reports success on its own
  // terms. The interview is a default, never a gate: every step offers "run as
  // written".
  if (parsed.command == 'goal' &&
      parsed.args.trim().isNotEmpty &&
      context.mounted) {
    final sharpened = await sharpenGoalObjective(
      ref: ref,
      context: context,
      rough: parsed.args,
    );
    if (sharpened == null) {
      return null;
    }
    if (sharpened != parsed.args) {
      content = content.replaceFirst(parsed.args, sharpened);
    }
  }

  // `/handoff` and `/btw` ask ONE question about the conversation and never add
  // to it: the agent's next real turn sees exactly what it would have seen
  // anyway, which is the whole value of asking.
  if (const {'handoff', 'btw'}.contains(parsed.command)) {
    if (context.mounted) {
      await handleAsideCommand(
        ref: ref,
        context: context,
        command: parsed.command!,
        args: parsed.args,
        spaceId: spaceId,
        conversationId: conversationId,
      );
    }
    return null;
  }

  return content;
}
