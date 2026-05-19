import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/server_sharing_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Sharing & remote access.
///
/// mDNS advertisement, the tunnel-provider opt-in, and the public URL when one
/// is up. Exposing a server publicly is among the most consequential switches
/// in the app, and it used to be the fourth of eight cards on "Advanced". It
/// gets its own page under the scope it actually belongs to.
class ServerSharingSettingsScreen extends StatelessWidget {
  /// Creates a [ServerSharingSettingsScreen].
  const ServerSharingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsServerSharing,
      subtitle: l10n.settingsServerSharingDescription,
      sections: const [ServerSharingSection()],
    );
  }
}
