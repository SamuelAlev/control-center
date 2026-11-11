import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_ticket_draft_row.dart';
import 'package:control_center/features/chat_bridges/providers/chat_ticket_draft_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Profile, under the chat link: the tickets the reader
/// drafted from chat in this workspace, waiting to become backlog tickets.
///
/// A chat command only drafts: its text came through the chat app (and, on
/// the shared app, a relay) and cannot be re-read, so nothing is created —
/// and no ticket trigger fires — until its reporter creates it here. Shown
/// only while there are drafts ([watchChatTicketDraftsApplies]).
class ChatTicketDraftsSection extends ConsumerWidget {
  /// Creates a [ChatTicketDraftsSection].
  const ChatTicketDraftsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(chatTicketDraftsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceName = ref.watch(activeWorkspaceProvider)?.name;
    final style = CcTypography.caption.copyWith(
      color: t.textSecondary,
      height: 1.45,
    );
    return SectionCard(
      label: l10n.chatTicketDraftsTitle,
      count: drafts.length,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.chatTicketDraftsDescription, style: style),
          if (workspaceName != null)
            Text(l10n.accountReachWorkspace(workspaceName), style: style),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, draft) in drafts.indexed) ...[
            if (i > 0) const CcDivider(),
            ChatTicketDraftRow(key: ValueKey(draft.id), draft: draft),
          ],
        ],
      ),
    );
  }
}

/// Whether [ChatTicketDraftsSection] has anything to show: the reader has
/// drafts waiting. An empty card would be standing chrome for a list that is
/// usually empty.
bool watchChatTicketDraftsApplies(WidgetRef ref) =>
    ref.watch(chatTicketDraftsProvider).value?.isNotEmpty ?? false;
