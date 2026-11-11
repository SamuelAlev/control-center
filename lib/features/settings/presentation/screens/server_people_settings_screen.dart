import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/server_people_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → People: every account on this server and whether its email is confirmed. Server owner only.
class ServerPeopleSettingsScreen extends StatelessWidget {
  /// Creates a [ServerPeopleSettingsScreen].
  const ServerPeopleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsServerPeople,
      subtitle: l10n.settingsServerPeopleDescription,
      sections: const [ServerPeopleSection()],
    );
  }
}
