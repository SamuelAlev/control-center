import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/presentation/utils/month_grid_keys.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// The rail's 6-week navigator: a [CalendarMonthGrid] bound to the focused
/// date. In week view the whole focused week is banded, mirroring what the
/// grid shows.
class CalendarMiniMonth extends ConsumerWidget {
  /// Creates the navigator.
  const CalendarMiniMonth({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CalendarMonthGrid(
    selected: ref.watch(selectedDateProvider),
    onSelect: ref.read(selectedDateProvider.notifier).select,
    bandSelectedWeek:
        ref.watch(calendarViewModeProvider) == CalendarViewMode.week,
  );
}

/// A 6-week month grid. Tapping a day calls [onSelect]; the chevrons page the
/// displayed month without moving the selection, and the displayed month
/// follows [selected] when it moves to another month.
class CalendarMonthGrid extends StatefulWidget {
  /// Creates a [CalendarMonthGrid].
  const CalendarMonthGrid({
    super.key,
    required this.selected,
    required this.onSelect,
    this.bandSelectedWeek = false,
  });

  /// The selected day.
  final DateTime selected;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onSelect;

  /// Whether the week holding [selected] is banded.
  final bool bandSelectedWeek;

  @override
  State<CalendarMonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<CalendarMonthGrid> {
  late DateTime _displayMonth = startOfMonth(widget.selected);

  /// One node per cell. The grid is a single Tab stop (the selected day, else
  /// today, else the 1st); the arrow keys move between the days.
  final List<FocusNode> _cells = [
    for (var i = 0; i < 42; i++) FocusNode(debugLabel: 'mini month day $i'),
  ];

  void _page(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta);
    });
  }

  @override
  void didUpdateWidget(CalendarMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final month = startOfMonth(widget.selected);
    if (month != startOfMonth(oldWidget.selected)) {
      _displayMonth = month;
      // The cells now show other days; keep focus on the selected one.
      if (_cells.any((node) => node.hasFocus)) {
        final index = _indexOf(widget.selected);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index != null) {
            _cells[index].requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final node in _cells) {
      node.dispose();
    }
    super.dispose();
  }

  int? _indexOf(DateTime day) {
    final start = dayKey(startOfMonthGrid(_displayMonth));
    // Rounded hours, so a DST shift inside the grid does not drop a day.
    final index = (dayKey(day).difference(start).inHours / 24).round();
    return index >= 0 && index < 42 ? index : null;
  }

  int _tabStop(DateTime today) =>
      _indexOf(widget.selected) ??
      (today.month == _displayMonth.month ? _indexOf(today) : null) ??
      _indexOf(_displayMonth)!;

  KeyEventResult _onGridKey(FocusNode _, KeyEvent event) {
    final current = _cells.indexWhere((node) => node.hasPrimaryFocus);
    final target = current < 0
        ? null
        : monthGridKeyTarget(
            event,
            current,
            rtl: Directionality.of(context) == TextDirection.rtl,
          );
    if (target == null) {
      return KeyEventResult.ignored;
    }
    _cells[target].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final selected = widget.selected;
    final l10n = AppLocalizations.of(context);
    final weekView = widget.bandSelectedWeek;
    final activeWeekStart = dayKey(startOfWeek(selected));

    final today = dayKey(DateTime.now());
    final gridStart = startOfMonthGrid(_displayMonth);
    final days = [
      for (var i = 0; i < 42; i++) gridStart.add(Duration(days: i)),
    ];
    final tabStop = _tabStop(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMM().format(_displayMonth),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            CcIconButton(
              icon: AppIcons.chevronLeft,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              tooltip: l10n.calendarPreviousPeriod,
              semanticLabel: l10n.calendarPreviousPeriod,
              onPressed: () => _page(-1),
            ),
            CcIconButton(
              icon: AppIcons.chevronRight,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              tooltip: l10n.calendarNextPeriod,
              semanticLabel: l10n.calendarNextPeriod,
              onPressed: () => _page(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _weekdayLabels())
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: t.textTertiary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onGridKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var week = 0; week < 6; week++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: weekView && dayKey(days[week * 7]) == activeWeekStart
                        ? t.bgQuaternary
                        : const Color(0x00000000),
                  ),
                  child: Row(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Expanded(
                          child: _MiniDayCell(
                            day: days[week * 7 + d],
                            focusNode: _cells[week * 7 + d]
                              ..skipTraversal = week * 7 + d != tabStop,
                            inMonth:
                                days[week * 7 + d].month == _displayMonth.month,
                            isToday: dayKey(days[week * 7 + d]) == today,
                            isSelected:
                                dayKey(days[week * 7 + d]) == dayKey(selected),
                            onTap: () => widget.onSelect(days[week * 7 + d]),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _weekdayLabels() {
    // Monday-first, short labels from the active locale.
    final monday = startOfWeek(DateTime.now());
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E().format(monday.add(Duration(days: i))),
    ];
  }
}

class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.focusNode,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final FocusNode focusNode;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    final Color textColor;
    if (isSelected) {
      textColor = t.textWhite;
    } else if (!inMonth) {
      textColor = t.textTertiary;
    } else if (isToday) {
      textColor = t.accent;
    } else {
      textColor = t.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: CcTappable(
        onPressed: onTap,
        focusNode: focusNode,
        semanticLabel: DateFormat.yMMMMEEEEd().format(day),
        semanticSelected: isSelected,
        builder: (context, _) => Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? t.accent
                : (isToday ? t.bgBrandPrimary : const Color(0x00000000)),
          ),
          // The full date is the label; the bare number would repeat it.
          child: Text(
            '${day.day}',
            semanticsLabel: '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected || isToday
                  ? FontWeight.w600
                  : CcTypography.regularWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
