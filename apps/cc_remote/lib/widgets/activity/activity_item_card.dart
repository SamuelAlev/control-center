import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/activity/activity_presentation.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class ActivityItemCard extends StatelessWidget {
  const ActivityItemCard({
    required this.item,
    required this.read,
    required this.working,
    required this.onOpen,
    required this.onToggleRead,
    required this.onDismiss,
    super.key,
  });
  final NotificationFeedItem item;
  final bool read;
  final bool working;
  final VoidCallback? onOpen;
  final VoidCallback onToggleRead;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final body = activityBody(item);
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                read ? AppIcons.circleCheck : AppIcons.triangleAlert,
                size: 16,
                color: read ? t.fgTertiary : t.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activityTitle(item, l),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            shortAgo(context, item.createdAt),
            style: TextStyle(fontSize: 12, color: t.textTertiary),
          ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Text(body, style: TextStyle(color: t.textSecondary)),
            ),
          if (item.isResolved)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Text(
                l.activityResolved,
                style: TextStyle(color: t.textSecondary),
              ),
            ),
          if (onOpen != null)
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.ghost,
              onPressed: working ? null : onOpen,
              child: Text(l.activityOpen),
            ),
          Wrap(
            spacing: 8,
            children: [
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: working ? null : onToggleRead,
                child: Text(read ? l.activityMarkUnread : l.activityMarkRead),
              ),
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.ghost,
                onPressed: working ? null : onDismiss,
                child: Text(l.activityDismiss),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
