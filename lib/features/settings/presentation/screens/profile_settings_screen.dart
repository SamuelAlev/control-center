import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/accounts_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/forge_connections_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/profile_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Profile & identity.
///
/// Who you are and what you are connected as: your display name and email, the
/// git identity stamped on commits made on your behalf, your GitHub/ticketing
/// credentials, your calendar accounts and the link between your chat account
/// and your user.
///
/// This used to be spread across the "Accounts" page under "Integrations",
/// which stacked four scopes in five consecutive cards — your profile, your
/// per-device credentials, the workspace's sync health and the workspace's
/// chat-bridge setup — with nothing to tell them apart. The two workspace cards
/// moved to Workspace → General; everything personal is here.
///
/// The calendar and chat-account cards are not listed here: `calendar` and
/// `chat_bridges` contribute them to [SettingsSlot.userProfile] themselves. The
/// chat one renders only its "link my account" half — connecting the Slack app
/// and customizing the bot is workspace administration and stays on the
/// workspace page, and that split is the contributing feature's call to make.
class ProfileSettingsScreen extends StatelessWidget {
  /// Creates a [ProfileSettingsScreen].
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsProfile,
      subtitle: l10n.settingsProfileDescription,
      slot: SettingsSlot.userProfile,
      sections: const [
        ProfileSection(),
        ForgeConnectionsSection(),
        AccountsSection(),
      ],
    );
  }
}
