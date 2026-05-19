import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Formats [dt] as a human-readable relative time string using the
/// ICU-aware localizations from `gen_l10n`.
///
/// Returns an empty string when [dt] is `null`.
String formatRelativeTime(BuildContext context, DateTime? dt) {
  if (dt == null) {
    return '';
  }

  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 5) {
    return l10n.justNow;
  }
  if (diff.inSeconds < 60) {
    return l10n.secondsAgo(diff.inSeconds);
  }
  if (diff.inMinutes < 60) {
    return l10n.minutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.hoursAgo(diff.inHours);
  }
  if (diff.inDays == 1) {
    return l10n.yesterday;
  }
  if (diff.inDays < 30) {
    return l10n.daysAgo(diff.inDays);
  }
  if (diff.inDays < 365) {
    return l10n.monthsAgo(diff.inDays ~/ 30);
  }
  return l10n.yearsAgo(diff.inDays ~/ 365);
}
