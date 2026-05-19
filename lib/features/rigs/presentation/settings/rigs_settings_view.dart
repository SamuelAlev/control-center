import 'package:control_center/features/rigs/presentation/settings/rig_capabilities_section.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_images_section.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_running_section.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_workspace_sections.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Enclosures.
///
/// A server-capability page, not a workspace destination: whether a rig can
/// boot is a property of the machine running `cc_server`, and the LIVE view of
/// a running one belongs beside the work it is doing — a channel tab or a PR
/// tab — rather than in a separate place you have to navigate to.
///
/// The sections live under `widgets/sections/system/` like every other
/// settings page's do; this file is the composition and nothing else.
class RigsSettingsView extends StatelessWidget {
  /// Creates a [RigsSettingsView].
  const RigsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.navRigs,
      subtitle: l10n.rigsSettingsSubtitle,
      sections: const [
        CapabilitiesSection(),
        RigImagesSection(),
        CustomImagesSection(),
        BrowserEgressSection(),
        RunningSection(),
      ],
    );
  }
}
