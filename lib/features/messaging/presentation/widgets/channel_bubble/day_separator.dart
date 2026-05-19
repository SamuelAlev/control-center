import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A quiet centered date divider between message groups from different days.
class DaySeparator extends StatelessWidget {
  /// Creates a [DaySeparator] for [day] (local date, midnight).
  const DaySeparator({super.key, required this.day});

  /// The local day this separator marks.
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: CcDivider(color: tokens.borderSecondary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppTimestamp(
              dateTime: day,
              child: Text(
                _label(day),
                style: CcTypography.caption.copyWith(
                  color: tokens.textQuaternary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(child: CcDivider(color: tokens.borderSecondary)),
        ],
      ),
    );
  }

  String _label(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return 'Today';
    }
    if (diff == 1) {
      return 'Yesterday';
    }
    if (diff < 7) {
      return DateFormat.EEEE().format(day);
    }
    return DateFormat.yMMMMd().format(day);
  }
}
