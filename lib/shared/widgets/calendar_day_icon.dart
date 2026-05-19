import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The next LOCAL midnight after [now]. Computed from civil date fields, not
/// `Duration(days: 1)`, so a DST transition lands on the real midnight rather
/// than on a 24h offset from now.
DateTime nextLocalMidnight(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1);

/// A calendar icon that shows the USER'S current day of month instead of the
/// "12" hardcoded into the Phosphor `calendar` glyph: the blank outline
/// ([AppIcons.calendarBlank] — the same contours minus the digits) with the
/// day written into its body.
///
/// The day is the device's LOCAL day (`DateTime.now()`), so it is correct in
/// whatever timezone the user is in — no server clock or UTC conversion is
/// involved. A timer rescheduled at each local midnight flips the digit even
/// when the surrounding chrome never rebuilds.
class CalendarDayIcon extends StatefulWidget {
  /// Creates a [CalendarDayIcon].
  const CalendarDayIcon({super.key, required this.color, this.size = 18});

  /// The glyph + digit color (the host's state-dependent icon color).
  final Color color;

  /// The icon edge in logical pixels (the glyph fills the square).
  final double size;

  @override
  State<CalendarDayIcon> createState() => _CalendarDayIconState();
}

class _CalendarDayIconState extends State<CalendarDayIcon> {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnightFlip();
  }

  /// Rebuilds once at the next LOCAL midnight, then reschedules.
  void _scheduleMidnightFlip() {
    final now = DateTime.now();
    _midnightTimer = Timer(nextLocalMidnight(now).difference(now), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleMidnightFlip();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        children: [
          Icon(AppIcons.calendarBlank, size: widget.size, color: widget.color),
          Positioned.fill(
            // The glyph's body (below the divider stroke) spans 96..208 of the
            // 256-unit box; its centre (152) sits at 59.4% of the icon.
            child: Align(
              alignment: const Alignment(0, 0.19),
              // Icon chrome, not content: pinned against the OS text scale so
              // the digit never outgrows the glyph body (the destination label
              // beside it does scale).
              child: Text(
                '${DateTime.now().day}',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: widget.size * 0.36,
                  height: 1,
                  fontWeight: CcTypography.semiboldWeight,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
