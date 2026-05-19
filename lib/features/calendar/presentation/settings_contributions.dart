import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `calendar` puts into settings: the connected-accounts card on the
/// profile page. Calendar accounts are the signed-in user's, not the
/// workspace's, so the card belongs under the `You` scope.
const List<SettingsSectionContribution> calendarSettingsSections = [
  SettingsSectionContribution(
    id: 'calendar.accounts',
    slot: SettingsSlot.userProfile,
    order: 30,
    builder: _buildCalendar,
  ),
];

Widget _buildCalendar(BuildContext context) => const CalendarSection();
