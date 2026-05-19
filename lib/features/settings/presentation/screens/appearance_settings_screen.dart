import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/editor_behavior_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/editor_theme_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/typography_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Appearance: theme, language and typography. The settings
/// landing page (first item in the "General" group).
class AppearanceSettingsScreen extends StatelessWidget {
  /// Creates an [AppearanceSettingsScreen].
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.appearance,
      subtitle: l10n.appearanceSettingsDescription,
      sections: const [
        AppearanceSection(),
        TypographySection(),
        EditorThemeSection(),
        EditorBehaviorSection(),
      ],
    );
  }
}
