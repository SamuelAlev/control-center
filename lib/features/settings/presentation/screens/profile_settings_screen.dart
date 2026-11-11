import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/profile_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Profile & identity.
///
/// Who you are in this workspace: display name, email and the git identity
/// stamped on commits made on your behalf. Switching workspace switches this
/// overlay; handle, sign-in and devices stay on the account (You → Your
/// devices).
///
/// Your provider connections (code hosting, Linear, Google Calendar, your
/// Slack link and ticket drafts from chat) are not here: they are stored
/// against you, so they live on You → Profile.
class ProfileSettingsScreen extends StatelessWidget {
  /// Creates a [ProfileSettingsScreen].
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsProfile,
      subtitle: l10n.settingsProfileDescription,
      sections: const [ProfileSection()],
    );
  }
}
