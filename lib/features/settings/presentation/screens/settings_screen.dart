import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/agents_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/repos_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/branch_template_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/diarization_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/embedding_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/logging_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/mcp_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/notifications_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/privacy_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/typography_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/voice_section.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Shared scaffold for a settings sub-page: keyboard shortcuts + a titled,
/// scrollable column of section cards with consistent 16px spacing.
class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return SettingsShortcuts(
      child: PageWrapper(
        title: title,
        subtitle: subtitle,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, index) => sections[index],
        ),
      ),
    );
  }
}

/// Settings → Appearance: theme, language, and typography. The settings
/// landing page (first item in the "General" group).
class AppearanceSettingsScreen extends StatelessWidget {
  /// Creates an [AppearanceSettingsScreen].
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsPage(
      title: l10n.appearance,
      subtitle: l10n.appearanceSettingsDescription,
      sections: const [AppearanceSection(), TypographySection()],
    );
  }
}

/// Settings → Notifications: per-event notification toggles.
class NotificationsSettingsScreen extends StatelessWidget {
  /// Creates a [NotificationsSettingsScreen].
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsPage(
      title: l10n.notifications,
      subtitle: l10n.notificationsSettingsDescription,
      sections: const [NotificationsSection()],
    );
  }
}

/// Settings → Integrations: GitHub, ticketing, and the MCP server.
class IntegrationsSettingsScreen extends StatelessWidget {
  /// Creates an [IntegrationsSettingsScreen].
  const IntegrationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsPage(
      title: l10n.integrations,
      subtitle: l10n.integrationsSettingsDescription,
      sections: const [
        IntegrationsSection(),
        CalendarSection(),
        McpSection(),
      ],
    );
  }
}

/// Settings → Advanced: branch template, voice, semantic search, privacy,
/// and logging. The rarely-touched system configuration.
class AdvancedSettingsScreen extends StatelessWidget {
  /// Creates an [AdvancedSettingsScreen].
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsPage(
      title: l10n.advanced,
      subtitle: l10n.advancedSettingsDescription,
      sections: const [
        BranchTemplateSection(),
        VoiceSection(),
        EmbeddingSection(),
        DiarizationSection(),
        PrivacySection(),
        LoggingSection(),
      ],
    );
  }
}

/// Settings screen for configuring adapters.
class AdaptersSettingsScreen extends StatelessWidget {
  /// Creates an [AdaptersSettingsScreen].
  const AdaptersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptersSettings(
      colors: context.theme.colors,
      textTheme: Theme.of(context).textTheme,
    );
  }
}

/// Settings screen for managing agents.
class AgentsSettingsScreen extends StatelessWidget {
  /// Creates an [AgentsSettingsScreen].
  const AgentsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AgentsSettings();
}

/// Settings screen for managing repositories.
class ReposSettingsScreen extends StatelessWidget {
  /// Creates a [ReposSettingsScreen].
  const ReposSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ReposSettings();
}

/// Settings screen for managing skills.
class SkillsSettingsScreen extends StatelessWidget {
  /// Creates a [SkillsSettingsScreen].
  const SkillsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsShortcuts(child: SkillsSettings());
}
