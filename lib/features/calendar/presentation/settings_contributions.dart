import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `calendar` puts into settings: the connected-accounts card on
/// Workspace → Profile & identity. Google accounts are the signed-in user's
/// in this workspace, not a workspace-wide calendar.
const List<SettingsSectionContribution> calendarSettingsSections = [
  SettingsSectionContribution(
    id: 'calendar.accounts',
    slot: SettingsSlot.workspaceProfile,
    order: 30,
    builder: _buildCalendar,
  ),
];

Widget _buildCalendar(BuildContext context) => const CalendarSection();
