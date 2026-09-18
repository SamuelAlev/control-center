import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The card above the agenda: the meeting happening now, or the next one.
class UpNextCard extends StatelessWidget {
  const UpNextCard({super.key, required this.event});

  final CalendarEventDto event;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final start = DateTime.tryParse(event.startTime);
    final end = DateTime.tryParse(event.endTime);
    final now = DateTime.now();
    final live =
        start != null && end != null && !start.isAfter(now) && end.isAfter(now);
    final away = start == null ? Duration.zero : start.difference(now);
    final lead = start == null
        ? ''
        : live
        ? l10n.happeningNow
        : away.inHours >= 12
        ? dayHeading(context, start)
        : l10n.inDuration(shortDuration(context, away));

    return CcCard(
      interactive: true,
      semanticLabel: l10n.upNextSemantic(lead, event.title),
      onPressed: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                live ? AppIcons.circleDot : AppIcons.clock,
                size: 14,
                color: live ? t.textSuccessPrimary : t.accent,
              ),
              const SizedBox(width: 6),
              Text(
                lead,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: live ? t.textSuccessPrimary : t.accent,
                ),
              ),
              const Spacer(),
              if (start != null)
                Text(
                  event.isAllDay ? l10n.allDay : clockTime(context, start),
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          if ((event.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(AppIcons.mapPin, size: 12, color: t.fgTertiary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                ),
              ],
            ),
          ],
          if ((event.meetingUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            CcButton(
              fullWidth: true,
              size: CcButtonSize.sm,
              icon: AppIcons.video,
              onPressed: () => openExternal(event.meetingUrl),
              child: Text(l10n.join),
            ),
          ],
        ],
      ),
    );
  }
}
