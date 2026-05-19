import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/remote_control/presentation/settings/own_devices_section.dart';
import 'package:control_center/features/remote_control/presentation/settings/remote_control_settings.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Settings → Remote control & devices: pair phones that remote-control this
/// app and configure the remote-control server. Merges the former separate
/// Devices page into the remote-control surface.
///
/// "Pair a new client" lives in the header (right of the title/subtitle row,
/// like the pipeline-templates "New template" button); the pairing form and
/// minted credential render inline above "Your devices", which is the single
/// device list (the former "Paired clients" list was its duplicate).
class RemoteControlSettingsView extends StatefulWidget {
  /// Creates a [RemoteControlSettingsView].
  const RemoteControlSettingsView({super.key});

  @override
  State<RemoteControlSettingsView> createState() =>
      _RemoteControlSettingsViewState();
}

class _RemoteControlSettingsViewState extends State<RemoteControlSettingsView> {
  bool _pairFormOpen = false;
  PairingMint? _pairMinted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.remoteControlAndDevices,
      subtitle: l10n.remoteControlAndDevicesSettingsDescription,
      actions: [
        CcButton(
          onPressed: () => setState(() {
            _pairFormOpen = !_pairFormOpen;
            // Opening a fresh form dismisses any credential still on screen.
            if (_pairFormOpen) {
              _pairMinted = null;
            }
          }),
          icon: AppIcons.plus,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.primary,
          child: Text(l10n.pairNewClient),
        ),
      ],
      sections: [
        // Mounted only while it has content (form open or credential showing):
        // an idle panel renders nothing yet would still occupy a section slot
        // and its separator gap, pushing "Your devices" down off the page's
        // standard rhythm.
        if (_pairFormOpen || _pairMinted != null)
          PairedDevicesPanel(
            formOpen: _pairFormOpen,
            onRequestClose: () => setState(() => _pairFormOpen = false),
            minted: _pairMinted,
            onMinted: (mint) => setState(() => _pairMinted = mint),
          ),
        const OwnDevicesSection(),
      ],
    );
  }
}
