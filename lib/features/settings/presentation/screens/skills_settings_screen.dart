import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart';
import 'package:flutter/widgets.dart';

/// Settings screen for managing skills.
class SkillsSettingsScreen extends StatelessWidget {
  /// Creates a [SkillsSettingsScreen].
  const SkillsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsShortcuts(child: SkillsSettings());
}
