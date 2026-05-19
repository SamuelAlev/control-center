import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a ticket card with title and view button.
class TicketCard extends StatelessWidget {
  /// Creates a [TicketCard].
  const TicketCard({super.key, required this.message});

  /// The ticket message.
  final ChannelMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Icon(LucideIcons.ticket, size: 16, color: tokens.fgTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: ticketUrl.isNotEmpty
                      ? () => launchUrl(Uri.parse(ticketUrl))
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.viewLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
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
