import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: tokens.borderSecondary, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label(day),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textQuaternary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: tokens.borderSecondary, height: 1)),
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
