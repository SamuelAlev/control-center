import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/server_connection_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Connection & status.
///
/// Which server this client talks to. Lifted out of the old "Advanced" junk
/// drawer, where it sat between the branch template and the log level.
///
/// Note the scope split on this page: the server LIST and the active choice are
/// per-device by definition (this machine's endpoint, this machine's keychain
/// entry for the PSK), while what it reports about the server is server-wide.
/// The section carries a device badge for exactly that reason.
class ServerConnectionSettingsScreen extends StatelessWidget {
  /// Creates a [ServerConnectionSettingsScreen].
  const ServerConnectionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsServerConnection,
      subtitle: l10n.settingsServerConnectionDescription,
      sections: const [ServerConnectionSection()],
    );
  }
}
