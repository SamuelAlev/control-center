import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/providers/chat_ticket_draft_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One ticket drafted from chat: its title and description, open for
/// correction, with Create ticket and Discard.
///
/// The fields start from what the command said and stay the reader's while
/// the list around them changes, so the row must be keyed by draft id.
class ChatTicketDraftRow extends ConsumerStatefulWidget {
  /// Creates a [ChatTicketDraftRow].
  const ChatTicketDraftRow({super.key, required this.draft});

  /// The draft this row edits.
  final ChatTicketDraftView draft;

  @override
  ConsumerState<ChatTicketDraftRow> createState() => _ChatTicketDraftRowState();
}

class _ChatTicketDraftRowState extends ConsumerState<ChatTicketDraftRow> {
  late final TextEditingController _title = TextEditingController(
    text: widget.draft.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.draft.description ?? '',
  );

  @override
  void initState() {
    super.initState();
    // Create stays off for an empty title: the server would refuse it.
    _title.addListener(_onTitle);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitle);
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onTitle() => setState(() {});

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final toasts = CcToastScope.maybeOf(context);
    final ticket = await ref
        .read(chatTicketDraftControllerProvider.notifier)
        .confirm(
          widget.draft.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
        );
    if (ticket != null) {
      toasts?.show(
        l10n.chatTicketDraftCreated(
          ticket.key.isEmpty ? ticket.title : ticket.key,
        ),
        variant: CcToastVariant.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final draft = widget.draft;
    final action = ref.watch(
      chatTicketDraftControllerProvider.select((s) => s[draft.id]),
    );
    final busy = action?.isLoading ?? false;
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final createdAt = draft.createdAt;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.chatTicketDraftFrom(draft.provider.displayName),
                style: caption,
              ),
              if (createdAt != null)
                AppTimestamp.relative(createdAt, style: caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CcTextField(
            controller: _title,
            label: l10n.titleLabel,
            enabled: !busy,
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextArea(
            controller: _description,
            label: l10n.ticketDescription,
            enabled: !busy,
            minLines: 2,
            maxLines: 6,
          ),
          if (action?.hasError ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.failedWithError('${action!.error}'),
              style: CcTypography.caption.copyWith(color: t.bgErrorSolid),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CcButton(
                variant: CcButtonVariant.ghost,
                icon: AppIcons.trash2,
                onPressed: busy
                    ? null
                    : () => unawaited(
                        ref
                            .read(chatTicketDraftControllerProvider.notifier)
                            .discard(draft.id),
                      ),
                child: Text(l10n.discard),
              ),
              CcButton(
                icon: AppIcons.ticket,
                loading: busy,
                onPressed: busy || _title.text.trim().isEmpty
                    ? null
                    : () => unawaited(_create()),
                child: Text(l10n.chatTicketDraftCreate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
