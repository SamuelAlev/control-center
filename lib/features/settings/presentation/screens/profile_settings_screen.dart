import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/accounts_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/profile_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Profile & identity.
///
/// Who you are and what you are connected as: your display name and email, the
/// git identity stamped on commits made on your behalf, your GitHub/ticketing
/// credentials, your calendar accounts, and the link between your chat account
/// and your user.
///
/// This used to be spread across the "Accounts" page under "Integrations",
/// which stacked four scopes in five consecutive cards — your profile, your
/// per-device credentials, the workspace's sync health, and the workspace's
/// chat-bridge setup — with nothing to tell them apart. The two workspace cards
/// moved to Workspace → General; everything personal is here.
///
/// The chat section renders only its [ChatBridgeSurface.myAccountLink] half:
/// connecting the Slack app and customizing the bot is workspace administration
/// and stays on the workspace page. Linking *your* account to *your* user is
/// identity, and belongs beside the rest of it.
class ProfileSettingsScreen extends StatelessWidget {
  /// Creates a [ProfileSettingsScreen].
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsProfile,
      subtitle: l10n.settingsProfileDescription,
      sections: const [
        ProfileSection(),
        AccountsSection(),
        CalendarSection(),
        ChatBridgesSection(surface: ChatBridgeSurface.myAccountLink),
      ],
    );
  }
}
