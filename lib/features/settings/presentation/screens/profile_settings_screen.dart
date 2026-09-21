import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/profile_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Profile & identity.
///
/// Who you are in this workspace: display name, email, the git identity
/// stamped on commits made on your behalf, your GitHub credentials, your
/// calendar accounts and the link between your chat account and your user.
/// Switching workspace switches this overlay; handle, sign-in and devices
/// stay on the account (You → Your devices).
///
/// The calendar and chat-account cards are not listed here: `calendar` and
/// `chat_bridges` contribute them to [SettingsSlot.workspaceProfile]
/// themselves. The chat one renders only its "link my account" half —
/// connecting the Slack app and customizing the bot is workspace
/// administration and stays on Workspace → General.
class ProfileSettingsScreen extends StatelessWidget {
  /// Creates a [ProfileSettingsScreen].
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsProfile,
      subtitle: l10n.settingsProfileDescription,
      slot: SettingsSlot.workspaceProfile,
      // The forge card is CONTRIBUTED by `forge` (`forge.connections`) rather
      // than named here — settings owns the page, not the integrations on it.
      // Ticketing's vendor lives on Workspace → General: where tickets live is
      // a property of the workspace, not of the signed-in user.
      sections: const [ProfileSection()],
    );
  }
}
