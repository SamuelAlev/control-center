import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/activity/work_notifications.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The items of a waiting digest, each opening its own record: a goal that
/// waits for review or a person, a held wake in its conversation's progress,
/// a proposed improvement in its conversation.
class DigestItems extends StatelessWidget {
  const DigestItems({super.key, required this.item});

  final NotificationFeedItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final items = digestItems(item, AppLocalizations.of(context));
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in items)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: CcCard(
              interactive: entry.location != null,
              semanticLabel: entry.label,
              onPressed: entry.location == null
                  ? null
                  : () => context.push(entry.location!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    entry.label,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.summary.isNotEmpty)
                    Text(
                      entry.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
