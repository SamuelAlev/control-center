import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// No calendar account is connected on the server, so there is nothing to
/// sync. Distinguishing that from "a free week" is the whole job of this
/// notice.
class CalendarNoAccountsNotice extends StatelessWidget {
  /// Creates a [CalendarNoAccountsNotice].
  const CalendarNoAccountsNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return _CalendarNotice(
      icon: AppIcons.calendarDays,
      color: t.textWarningPrimary,
      text: AppLocalizations.of(context).calendarNoAccounts,
    );
  }
}

/// An account's credential expired: the rows on screen are the last good sync,
/// not the current state, and only a desktop re-auth fixes it.
class CalendarReauthNotice extends StatelessWidget {
  /// Creates a [CalendarReauthNotice].
  const CalendarReauthNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return _CalendarNotice(
      icon: AppIcons.triangleAlert,
      color: t.textWarningPrimary,
      text: AppLocalizations.of(context).calendarReauthNeeded,
    );
  }
}

class _CalendarNotice extends StatelessWidget {
  const _CalendarNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.warnSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
