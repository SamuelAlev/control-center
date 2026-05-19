/// The composer commands handled entirely on the CLIENT, plus the two that ask
/// the server one question about the conversation.
///
/// **Why they live outside the composer widget.** None of them touches the
/// composer's state — they need a workspace, a space, a conversation and
/// somewhere to put a toast, and that is all. Keeping them inline made a file
/// whose job is "render an input bar" also the place four unrelated features
/// are implemented, and every one of them had to be read past to find the send
/// path.
///
/// The distinction worth keeping in view: a LOCAL command never travels as a
/// message, so it neither lands in the transcript nor reaches an agent.
/// `/handoff` and `/btw` spend a server-side model call but still change
/// nothing — the agent's next real turn sees exactly what it would have seen
/// anyway, which is the whole value of asking.
library;

import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_export.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversation_tree_sheet.dart';
import 'package:control_center/features/messaging/presentation/widgets/guided_goal_dialog.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/export/conversation_export_writer.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drops heavy content from the conversation without summarizing it
/// (`/shake [images|all]`) and narrates what it freed.
Future<void> handleShakeCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String args,
  required String spaceId,
  required String conversationId,
}) async {
  final l10n = AppLocalizations.of(context);
  final toast = CcToastScope.maybeOf(context);
  final port = ref.read(messagingServiceProvider);
  final target = switch (args.trim().toLowerCase()) {
    'images' => 'images',
    'all' => 'all',
    _ => 'tool_output',
  };
  final ConversationShakeResult result;
  try {
    result = await port.shakeConversation(
      workspaceId: ref.requireWorkspaceId(),
      spaceId: spaceId,
      conversationId: conversationId,
      target: target,
    );
  } on Object {
    toast?.show(l10n.shakeUnavailable, variant: CcToastVariant.warning);
    return;
  }
  if (result.unavailable) {
    toast?.show(l10n.shakeUnavailable, variant: CcToastVariant.warning);
    return;
  }
  if (result.isEmpty) {
    toast?.show(l10n.shakeNothing);
    return;
  }
  toast?.show(
    l10n.shakeDone(result.tokensReclaimed),
    variant: CcToastVariant.success,
  );
}

/// Handles `/tree`, `/export` and `/dump`.
Future<void> handleConversationToolCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String command,
  required String spaceId,
  required String conversationId,
}) async {
  if (command == 'tree') {
    await showCcDialog<void>(
      context: context,
      builder: (context) => ConversationTreeSheet(
        spaceId: spaceId,
        conversationId: conversationId,
      ),
    );
    return;
  }

  final l10n = AppLocalizations.of(context);
  final toast = CcToastScope.maybeOf(context);
  final repo = ref.read(messagingRepositoryProvider);
  final messages = await repo.getMessages(
    ref.requireWorkspaceId(),
    spaceId,
    conversationId: conversationId,
  );
  if (!context.mounted) {
    return;
  }
  final title = 'Conversation $conversationId';

  if (command == 'dump') {
    await Clipboard.setData(
      ClipboardData(
        text: renderConversationMarkdown(title: title, messages: messages),
      ),
    );
    toast?.show(l10n.dumpCopied, variant: CcToastVariant.success);
    return;
  }

  // `/export`: a self-contained HTML page. Written next to the app's own
  // documents rather than offered as a save dialog, because the point is to
  // get a file quickly and a picker is three more decisions.
  try {
    final html = renderConversationHtml(
      title: title,
      messages: messages,
      exportedAt: DateTime.now(),
    );
    final path = await writeConversationExport(
      conversationId: conversationId,
      html: html,
    );
    if (context.mounted) {
      toast?.show(l10n.exportSaved(path), variant: CcToastVariant.success);
    }
  } on Object {
    if (context.mounted) {
      toast?.show(l10n.exportFailed, variant: CcToastVariant.warning);
    }
  }
}

/// Opens the objective interview and returns the sharpened text.
///
/// Returns the ORIGINAL text when the interview cannot run (no one-shot
/// model configured, a failed call) and null only when the person dismissed
/// the dialog outright — a goal must never be lost to an interviewer.
Future<String?> sharpenGoalObjective({
  required WidgetRef ref,
  required BuildContext context,
  required String rough,
}) {
  final port = ref.read(messagingServiceProvider);
  final workspaceId = ref.requireWorkspaceId();
  return showCcDialog<String>(
    context: context,
    builder: (context) => GuidedGoalDialog(
      rough: rough,
      step: (transcript) => port.guidedGoalStep(
        workspaceId: workspaceId,
        rough: rough,
        transcript: transcript,
      ),
    ),
  );
}

/// Runs a side-channel command (`/handoff`, `/btw`).
///
/// The command never travels as a space message — persisting it would push
/// the compaction cut a turn earlier for a question nobody wanted kept.
Future<void> handleAsideCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String command,
  required String args,
  required String spaceId,
  required String conversationId,
}) async {
  final l10n = AppLocalizations.of(context);
  final toast = CcToastScope.maybeOf(context);
  final port = ref.read(messagingServiceProvider);
  final kind = command == 'handoff' ? 'handoff' : 'aside';
  if (kind == 'aside' && args.trim().isEmpty) {
    toast?.show(l10n.asideFailed, variant: CcToastVariant.warning);
    return;
  }

  final ConversationSideChannelResult result;
  try {
    result = await port.askAside(
      workspaceId: ref.requireWorkspaceId(),
      spaceId: spaceId,
      conversationId: conversationId,
      kind: kind,
      input: args.trim(),
    );
  } on Object {
    toast?.show(l10n.asideFailed, variant: CcToastVariant.warning);
    return;
  }
  if (!context.mounted) {
    return;
  }
  if (result.unavailable) {
    toast?.show(l10n.asideUnavailable, variant: CcToastVariant.warning);
    return;
  }
  if (result.empty) {
    toast?.show(l10n.asideEmpty);
    return;
  }

  final text = result.text;
  if (text == null || text.isEmpty) {
    toast?.show(l10n.asideFailed, variant: CcToastVariant.warning);
    return;
  }
  await showCcDialog<void>(
    context: context,
    builder: (context) => CcDialog(
      title: kind == 'handoff' ? l10n.handoffTitle : l10n.asideTitle,
      content: SingleChildScrollView(child: StyledMarkdownBody(data: text)),
    ),
  );
}

/// Runs the server-side compaction pass for this conversation (`/compact`)
/// and narrates the outcome. The summary message itself arrives through the
/// normal message watch stream; only the no-op / busy / unavailable paths
/// need a toast.
Future<void> handleCompactCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String spaceId,
  required String conversationId,
}) async {
  final l10n = AppLocalizations.of(context);
  final port = ref.read(messagingServiceProvider);
  final ConversationCompactionResult result;
  try {
    result = await port.compactConversation(
      workspaceId: ref.requireWorkspaceId(),
      spaceId: spaceId,
      conversationId: conversationId,
    );
  } on Object {
    // The op is absent on a host without the dispatch engine (or the call
    // failed) — say so instead of failing silently.
    if (context.mounted) {
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.compactUnavailable, variant: CcToastVariant.warning);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final toast = CcToastScope.maybeOf(context);
  switch (result.status) {
    case ConversationCompactionStatus.compacted:
      toast?.show(l10n.compactDone, variant: CcToastVariant.success);
    case ConversationCompactionStatus.nothingToCompact:
      toast?.show(l10n.compactNothing);
    case ConversationCompactionStatus.agentBusy:
      toast?.show(l10n.compactBusy, variant: CcToastVariant.warning);
    case ConversationCompactionStatus.unavailable:
      toast?.show(l10n.compactUnavailable, variant: CcToastVariant.warning);
  }
}
