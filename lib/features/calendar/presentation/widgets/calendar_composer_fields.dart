import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart'
    show CalendarSlot;
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_mini_month.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The step between offered start and end times.
const Duration kComposerTimeStep = Duration(minutes: 15);

/// One composer line: a leading glyph in the inspector's tertiary ink and the
/// control it labels, aligned on the control's first line.
class ComposerRow extends StatelessWidget {
  /// Creates a [ComposerRow].
  const ComposerRow({
    super.key,
    required this.icon,
    required this.child,
    this.chromeless = false,
  });

  /// Whether [child] is a borderless field, whose first line sits higher.
  final bool chromeless;

  /// The leading glyph.
  final IconData icon;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: chromeless ? 3 : 9),
            child: Icon(icon, size: 16, color: t.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Start times on [day]'s quarter hours, plus [current] when it falls between
/// them (a drawn span snaps to kalender's grid, which may be finer).
List<DateTime> composerStartTimes(DateTime day, DateTime current) {
  final midnight = dayKey(day);
  final times = [
    for (var i = 0; i < 96; i++) midnight.add(kComposerTimeStep * i),
  ];
  if (!times.contains(current) && dayKey(current) == midnight) {
    times
      ..add(current)
      ..sort();
  }
  return times;
}

/// End times after [start], up to a day later, plus [current] when it falls
/// between them.
List<DateTime> composerEndTimes(DateTime start, DateTime current) {
  final times = [for (var i = 1; i < 96; i++) start.add(kComposerTimeStep * i)];
  if (current.isAfter(start) && !times.contains(current)) {
    times
      ..add(current)
      ..sort();
  }
  return times;
}

/// A time picker over [options]. With [from] set, each option also names its
/// distance from it (`3:30 PM · 1h 30m`), the way an end time reads best.
class ComposerTimeSelect extends StatelessWidget {
  /// Creates a [ComposerTimeSelect].
  const ComposerTimeSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.from,
  });

  /// The accessible label.
  final String label;

  /// The selected time.
  final DateTime value;

  /// The times offered.
  final List<DateTime> options;

  /// Called with the chosen time.
  final ValueChanged<DateTime> onChanged;

  /// The start an end time is measured from.
  final DateTime? from;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.jm();
    String labelFor(DateTime time) {
      final start = from;
      final clock = format.format(time);
      return start == null
          ? clock
          : '$clock · ${formatDurationShort(time.difference(start))}';
    }

    return CcSelect<int>(
      semanticLabel: label,
      value: value.millisecondsSinceEpoch,
      options: [
        for (final time in options)
          CcSelectOption(
            value: time.millisecondsSinceEpoch,
            label: labelFor(time),
          ),
      ],
      onChanged: (ms) => onChanged(DateTime.fromMillisecondsSinceEpoch(ms)),
    );
  }
}

/// A date chip that opens a month grid beneath it.
class ComposerDateField extends StatefulWidget {
  /// Creates a [ComposerDateField].
  const ComposerDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
  });

  /// The accessible label.
  final String label;

  /// The selected day.
  final DateTime date;

  /// Called with the chosen day.
  final ValueChanged<DateTime> onChanged;

  @override
  State<ComposerDateField> createState() => _ComposerDateFieldState();
}

class _ComposerDateFieldState extends State<ComposerDateField> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcPopover(
      controller: _controller,
      // The chip below is itself a button; it toggles the panel, so the
      // popover's own target tap is off (a nested button would swallow it).
      toggleOnTargetTap: false,
      semanticLabel: widget.label,
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 252,
          child: CalendarMonthGrid(
            selected: widget.date,
            onSelect: (day) {
              _controller.hide();
              widget.onChanged(day);
            },
          ),
        ),
      ),
      target: CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        onPressed: _controller.toggle,
        child: Text(DateFormat.yMMMEd().format(widget.date)),
      ),
    );
  }
}

/// The time block: start → end with the duration on the end times, the day,
/// and the all-day switch. All-day spans pick a first and last day instead.
class ComposerWhenFields extends StatelessWidget {
  /// Creates a [ComposerWhenFields].
  const ComposerWhenFields({
    super.key,
    required this.slot,
    required this.lastDay,
    required this.onStart,
    required this.onEnd,
    required this.onDay,
    required this.onLastDay,
    required this.onAllDay,
  });

  /// The span being composed.
  final CalendarSlot slot;

  /// The last day of an all-day span.
  final DateTime lastDay;

  /// Called with a new start time.
  final ValueChanged<DateTime> onStart;

  /// Called with a new end time.
  final ValueChanged<DateTime> onEnd;

  /// Called with a new (first) day.
  final ValueChanged<DateTime> onDay;

  /// Called with a new last day of an all-day span.
  final ValueChanged<DateTime> onLastDay;

  /// Called when all-day is toggled.
  final ValueChanged<bool> onAllDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!slot.allDay)
          Row(
            children: [
              Expanded(
                child: ComposerTimeSelect(
                  label: l10n.calendarComposerStarts,
                  value: slot.start,
                  options: composerStartTimes(slot.start, slot.start),
                  onChanged: onStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ComposerTimeSelect(
                  label: l10n.calendarComposerEnds,
                  value: slot.end,
                  from: slot.start,
                  options: composerEndTimes(slot.start, slot.end),
                  onChanged: onEnd,
                ),
              ),
            ],
          ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ComposerDateField(
              label: l10n.calendarComposerDate,
              date: dayKey(slot.start),
              onChanged: onDay,
            ),
            if (slot.allDay && lastDay.isAfter(slot.start)) ...[
              const Icon(AppIcons.arrowRight, size: 13),
              ComposerDateField(
                label: l10n.calendarComposerEndDate,
                date: lastDay,
                onChanged: onLastDay,
              ),
            ],
          ],
        ),
        CcCheckbox(
          value: slot.allDay,
          onChanged: onAllDay,
          label: Text(l10n.calendarAllDay),
        ),
      ],
    );
  }
}
