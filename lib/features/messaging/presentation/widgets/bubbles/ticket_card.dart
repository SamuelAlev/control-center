import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/material.dart';

/// Renders a ticket card with title and view button.
class TicketCard extends StatelessWidget {
  /// Creates a [TicketCard].
  const TicketCard({super.key, required this.message});

  /// The ticket message.
  final Message message;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final title = message.metadata?['title'] as String? ?? message.content;
    final ticketUrl = message.metadata?['ticketUrl'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: Row(
              children: [
                Icon(AppIcons.ticket, size: 16, color: tokens.fgTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: CcTypography.body.copyWith(
                      color: tokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                CcButton(
                  onPressed: ticketUrl.isNotEmpty
                      ? () => openExternalUrl(ticketUrl)
                      : null,
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  child: CcLinkText(
                    l10n.viewLabel,
                    style: CcTypography.caption
                        .copyWith(color: tokens.textTertiary)
                        .copyWith(color: tokens.textTertiary)
                        .withLinkUnderline(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
