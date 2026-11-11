import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `calendar` puts into settings: the Google Calendar card among the
/// connected accounts on You → Profile. Google accounts are the signed-in
/// person's, kept for the current workspace only, not a workspace-wide
/// calendar.
const List<SettingsSectionContribution> calendarSettingsSections = [
  SettingsSectionContribution(
    id: 'calendar.accounts',
    slot: SettingsSlot.userAccounts,
    order: 40,
    builder: _buildCalendar,
  ),
];

Widget _buildCalendar(BuildContext context) => const CalendarSection();
