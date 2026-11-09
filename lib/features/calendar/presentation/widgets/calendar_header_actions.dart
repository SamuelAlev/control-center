import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the event composer for the next free-looking hour: the coming
/// quarter hour today, 9:00 on any other focused day. The keyboard's way in;
/// dragging across the grid is the pointer's. Hidden when the person has no
/// calendar to write to, or on a demo server.
class CalendarNewEventButton extends ConsumerWidget {
  /// Creates a [CalendarNewEventButton].
  const CalendarNewEventButton({super.key});

  /// The slot a new event starts in when nothing was drawn.
  static ({DateTime start, DateTime end}) defaultSpan(
    DateTime focused,
    DateTime now,
  ) {
    final DateTime start;
    if (dayKey(focused) == dayKey(now)) {
      final next = now.add(const Duration(minutes: 15));
      start = DateTime(
        next.year,
        next.month,
        next.day,
        next.hour,
      ).add(Duration(minutes: next.minute ~/ 15 * 15));
    } else {
      start = dayKey(focused).add(const Duration(hours: 9));
    }
    return (start: start, end: start.add(const Duration(hours: 1)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isDemoServerProvider) ||
        ref.watch(writableCalendarsProvider).isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return CcIconButton(
      icon: AppIcons.plus,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      tooltip: l10n.calendarNewEvent,
      semanticLabel: l10n.calendarNewEvent,
      onPressed: () {
        final box = context.findRenderObject() as RenderBox?;
        final span = defaultSpan(
          ref.read(selectedDateProvider),
          DateTime.now(),
        );
        ref
            .read(calendarComposerProvider.notifier)
            .open(
              CalendarSlot(
                start: span.start,
                end: span.end,
                allDay: false,
                anchor: box == null
                    ? Offset.zero
                    : box.localToGlobal(box.size.bottomLeft(Offset.zero)),
              ),
            );
      },
    );
  }
}

/// Asks the host to sync this workspace's calendars now; a spinner while it
/// runs.
class CalendarSyncButton extends ConsumerStatefulWidget {
  /// Creates a [CalendarSyncButton].
  const CalendarSyncButton({super.key});

  @override
  ConsumerState<CalendarSyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<CalendarSyncButton> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) {
      return;
    }
    setState(() => _syncing = true);
    try {
      await ref.read(calendarSyncServiceProvider).refreshNow();
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (_syncing) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: CcSpinner(size: 16, color: t.accent),
      );
    }
    return CcIconButton(
      icon: AppIcons.refreshCw,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      tooltip: l10n.calendarSyncNow,
      semanticLabel: l10n.calendarSyncNow,
      onPressed: _sync,
    );
  }
}
