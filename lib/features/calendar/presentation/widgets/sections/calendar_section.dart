import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/widgets/google_calendar_connect_dialog.dart';
import 'package:control_center/features/calendar/providers/connect_account_provider.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Integrations: connect one or more Google Calendar accounts to the
/// active workspace, each disconnectable on its own.
class CalendarSection extends ConsumerWidget {
  /// Creates a [CalendarSection].
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];

    return SectionCard(
      label: l10n.calendarSettingsTitle,
      child: Column(
        children: [
          for (final account in accounts)
            SettingsRow(
              icon: AppIcons.calendar,
              title: account.accountEmail,
              subtitle: l10n.calendarConnectedAs(account.accountEmail),
              trailing: CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: () => ref
                    .read(connectGoogleCalendarProvider.notifier)
                    .disconnect(account.id),
                child: Text(l10n.calendarDisconnect),
              ),
            ),
          SettingsRow(
            icon: accounts.isEmpty ? AppIcons.calendar : AppIcons.plus,
            title: accounts.isEmpty
                ? l10n.calendarSettingsTitle
                : l10n.calendarAddAccount,
            subtitle: accounts.isEmpty
                ? l10n.calendarSettingsDescription
                : l10n.calendarConnectDescription,
            trailing: CcButton(
              variant: accounts.isEmpty
                  ? CcButtonVariant.primary
                  : CcButtonVariant.secondary,
              onPressed: () => showGoogleCalendarConnectDialog(context),
              icon: AppIcons.calendarPlus,
              child: Text(
                accounts.isEmpty
                    ? l10n.calendarConnectGoogle
                    : l10n.calendarAddAccount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
