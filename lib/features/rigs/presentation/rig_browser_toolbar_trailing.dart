import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/browser_permission.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_browser_permission_flyout.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Size label, audio/mic, and the shield flyout on the browser toolbar.
class RigBrowserToolbarTrailing extends StatelessWidget {
  /// Creates a [RigBrowserToolbarTrailing].
  const RigBrowserToolbarTrailing({
    super.key,
    required this.rig,
    required this.permissions,
    required this.onNetworkSecurity,
    required this.onRespond,
    this.networkRestarting = false,
    this.audioOn = false,
    this.onToggleAudio,
    this.microphoneOn = false,
    this.onToggleMicrophone,
  });

  /// The browser rig being driven.
  final RigView rig;

  /// Site permissions asked this session.
  final List<BrowserPermissionEntry> permissions;

  /// Opens the per-session network security setting.
  final VoidCallback onNetworkSecurity;

  /// Answers a pending site permission.
  final void Function(String requestId, {required bool allow}) onRespond;

  /// Whether the unrestricted replacement is being started.
  final bool networkRestarting;

  /// Whether guest audio currently plays here.
  final bool audioOn;

  /// Toggles guest audio; null when this panel has no output lane.
  final VoidCallback? onToggleAudio;

  /// Whether the viewer's microphone currently feeds the guest.
  final bool microphoneOn;

  /// Toggles microphone input; null when this panel has no input lane.
  final VoidCallback? onToggleMicrophone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rig.displayWidth != null && rig.displayHeight != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${rig.displayWidth}×${rig.displayHeight}',
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        if (rig.networkIsUnrestricted)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: CcStatusTag(
              label: l10n.rigNetworkUnrestricted,
              tone: CcStatusTone.caution,
            ),
          ),
        if (onToggleAudio != null)
          CcIconButton(
            icon: audioOn ? AppIcons.volume2 : AppIcons.volumeOff,
            size: CcButtonSize.sm,
            onPressed: onToggleAudio,
            tooltip: audioOn ? l10n.rigAudioMute : l10n.rigAudioListen,
          ),
        if (onToggleMicrophone != null)
          CcIconButton(
            icon: microphoneOn ? AppIcons.mic : AppIcons.micOff,
            size: CcButtonSize.sm,
            onPressed: onToggleMicrophone,
            tooltip: l10n.meetingRecordMic,
          ),
        RigBrowserPermissionFlyout(
          rig: rig,
          permissions: permissions,
          networkRestarting: networkRestarting,
          onNetworkSecurity: onNetworkSecurity,
          onRespond: onRespond,
        ),
      ],
    );
  }
}
