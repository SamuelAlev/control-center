import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_ticket_draft_row.dart';
import 'package:control_center/features/chat_bridges/providers/chat_ticket_draft_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/scope_badge.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Profile: the tickets the reader drafted from chat, waiting to
/// become backlog tickets.
///
/// A chat command only drafts: its text came through the chat app (and, on
/// the shared app, a relay) and cannot be re-read, so nothing is created —
/// and no ticket trigger fires — until its reporter creates it here. Renders
/// nothing while there are no drafts; an empty card would be standing chrome
/// for a list that is usually empty.
class ChatTicketDraftsSection extends ConsumerWidget {
  /// Creates a [ChatTicketDraftsSection].
  const ChatTicketDraftsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(chatTicketDraftsProvider).value ?? const [];
    if (drafts.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.chatTicketDraftsTitle,
      count: drafts.length,
      subtitle: Text(
        l10n.chatTicketDraftsDescription,
        style: CcTypography.caption.copyWith(
          color: t.textSecondary,
          height: 1.45,
        ),
      ),
      trailing: const ScopeBadge(SettingScope.user),
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
