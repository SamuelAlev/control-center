import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/about_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → About: build identity and the desktop updater.
class AboutSettingsScreen extends StatelessWidget {
  /// Creates an [AboutSettingsScreen].
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsAbout,
      subtitle: l10n.settingsAboutDescription,
      sections: const [AboutSection()],
    );
  }
}
