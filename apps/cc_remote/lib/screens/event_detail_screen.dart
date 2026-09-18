import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/calendar_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/calendar/event_detail_body.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/event/:eventId` — one event, with everything a phone is asked for while
/// standing up: when, where, the join link, who is coming.
class EventDetailScreen extends ConsumerWidget {
  /// Creates an [EventDetailScreen].
  const EventDetailScreen({super.key, required this.eventId});

  /// The calendar event id from the route.
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Resolved from the live agenda rather than a per-event watch: the row is
    // already in memory and updates in place with the rest of the agenda.
    final event = ref
        .watch(agendaEventsProvider)
        .value
        ?.where((e) => e.id == eventId)
        .firstOrNull;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailHeader(
              title: event?.title ?? AppLocalizations.of(context).event,
            ),
            if (event == null)
              Expanded(
                child: CcEmptyState(
                  icon: AppIcons.calendar,
                  message: AppLocalizations.of(context).eventNotFound,
                  description: AppLocalizations.of(
                    context,
                  ).eventNotFoundDescription,
                ),
              )
            else
              Expanded(child: EventDetailBody(event: event)),
          ],
        ),
      ),
    );
  }
}
