import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/widgets/google_calendar_connect_dialog.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A banner shown above the calendar when one or more connected accounts have a
/// dead OAuth token and need the user to reconnect. Hidden (zero-height) while
/// every account is healthy. The synced events stay visible underneath — we
/// only block on a full disconnect, not on a stale token.
class CalendarReauthBanner extends ConsumerWidget {
  /// Creates the banner for [workspaceId]'s accounts.
  const CalendarReauthBanner({super.key, required this.workspaceId});

  /// The workspace whose Google accounts reconnect.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(accountsNeedingReauthProvider);
    if (stale.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Name the account when exactly one is stale; otherwise stay generic.
    final subtitle = stale.length == 1 && stale.first.accountEmail.isNotEmpty
        ? l10n.notificationCalendarAuthExpiredBody(stale.first.accountEmail)
        : l10n.notificationCalendarAuthExpiredBodyNoEmail;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgWarningPrimary,
        border: Border(bottom: BorderSide(color: t.bgWarningSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.calendarX, size: 18, color: t.textWarningPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationCalendarAuthExpiredTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            size: CcButtonSize.sm,
            onPressed: () => showGoogleCalendarConnectDialog(
              context,
              ref,
              workspaceId: workspaceId,
            ),
            icon: AppIcons.refreshCw,
            child: Text(l10n.calendarReconnect),
          ),
        ],
      ),
    );
  }
}

/// The calendar's empty state: no Google account is connected yet.
class CalendarConnectState extends ConsumerWidget {
  /// Creates the empty state for [workspaceId].
  const CalendarConnectState({super.key, required this.workspaceId});

  /// The workspace a new Google account connects to.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return ColoredBox(
      color: t.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.calendar, size: 40, color: t.textTertiary),
              const SizedBox(height: 16),
              Text(
                l10n.calendarSettingsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.calendarConnectDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              CcButton(
                size: CcButtonSize.sm,
                onPressed: () => showGoogleCalendarConnectDialog(
                  context,
                  ref,
                  workspaceId: workspaceId,
                ),
                icon: AppIcons.calendarPlus,
                child: Text(l10n.calendarConnectGoogle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
