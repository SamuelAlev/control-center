// The panel's chrome and its non-running states.
//
// Split out of `rig_panel.dart` so the panel itself is the lane wiring (frames
// in, input out, audio, resize negotiation) and these are the pictures around
// it.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// The panel's title row: what this machine is, what state it is in, and the
/// two controls that apply to it.
class RigHeader extends StatelessWidget {
  /// Creates a [RigHeader].
  const RigHeader({
    super.key,
    required this.rig,
    this.onStop,
    this.audioOn = false,
    this.onToggleAudio,
  });

  /// The machine this header describes.
  final RigView rig;

  /// Stops the machine; null when this surface offers no stop control here.
  final VoidCallback? onStop;

  /// Whether guest audio currently plays here.
  final bool audioOn;

  /// Toggles guest audio; null when this surface has no audio lane.
  final VoidCallback? onToggleAudio;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(rigSurfaceIcon(rig.surfaceKind), size: 14, color: t.fgSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            // Named by ENGINE on a browser rig: three of them can be open at
            // once and "Browser" on all three says nothing about which page
            // is on screen.
            rigSurfaceLabel(l10n, rig.surfaceKind, engine: rig.browserEngine),
            style: CcTypography.bodySm.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcStatusTag(
            label: rigPhaseLabel(l10n, rig),
            tone: rigPhaseTone(rig.phaseKind),
          ),
          // Only when the server actually SAID it is emulated. An absent
          // field used to default to accelerated, which hid this badge on
          // exactly the hosts that need it.
          if (rig.isEmulated) ...[
            const SizedBox(width: AppSpacing.xs),
            CcStatusTag(
              label: l10n.rigNotAccelerated,
              tone: CcStatusTone.caution,
            ),
          ],
          const Spacer(),
          if (rig.displayWidth != null && rig.displayHeight != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                '${rig.displayWidth}×${rig.displayHeight}',
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
          if (rig.isLive) ...[
            if (onToggleAudio != null) ...[
              CcIconButton(
                icon: audioOn ? AppIcons.volume2 : AppIcons.volumeOff,
                tooltip: audioOn ? l10n.rigAudioMute : l10n.rigAudioListen,
                onPressed: onToggleAudio,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (onStop != null) ...[
              const SizedBox(width: AppSpacing.xs),
              CcIconButton(
                icon: AppIcons.power,
                tooltip: l10n.rigStopMachine,
                onPressed: onStop,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The booting state: a spinner and the server's own description of the step.
class RigStarting extends StatelessWidget {
  /// Creates a [RigStarting].
  const RigStarting({super.key, this.detail});

  /// The current boot step, when the server reported one.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: AppSpacing.sm),
          // The boot step verbatim. A two-minute silent wait and a hang look
          // identical from here, so the panel says which stage it is in.
          Text(
            detail ?? l10n.rigPhaseStarting,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Plays the rig's audio lane while mounted. Renders nothing — mounting IS
/// the play state, so pausing the tab or toggling the speaker unmounts it
/// and the stream stops (the guest-side encoder dies with the connection).
class RigAudioPlayer extends ConsumerStatefulWidget {
  /// Creates a [RigAudioPlayer].
  const RigAudioPlayer({super.key, required this.url});

  /// The signed audio-lane URL, or null when there is no live connection.
  final String? url;

  @override
  ConsumerState<RigAudioPlayer> createState() => _RigAudioPlayerState();
}

class _RigAudioPlayerState extends ConsumerState<RigAudioPlayer> {
  final Player _player = Player();

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didUpdateWidget(RigAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _play();
    }
  }

  void _play() {
    final url = widget.url;
    if (url == null) {
      return;
    }
    // The app-wide output device applies to a rig's audio lane too — it is a
    // sound this app makes. Routed before opening so the first frames land on
    // the chosen hardware.
    final device = ref.read(audioOutputDeviceProvider);
    unawaited(() async {
      try {
        await applyAppAudioOutput(_player, device);
      } on Object {
        // Device gone since it was picked: mpv falls back to the default
        // output, so the lane still plays. Nothing to report here.
      }
      try {
        await _player.open(Media(url));
      } on Object {
        // A rig that closed mid-listen; the header state is what reports it.
      }
    }());
  }

  @override
  void dispose() {
    unawaited(() async {
      try {
        await _player.stop();
      } on Object {
        // Already stopped — nothing to do.
      }
      try {
        await _player.dispose();
      } on Object {
        // Already disposed — nothing to do.
      }
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The failed state: what went wrong, in the server's own words.
class RigFailed extends StatelessWidget {
  /// Creates a [RigFailed].
  const RigFailed({super.key, this.detail});

  /// The failure reason, when the server reported one.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.triangleAlert, size: 24, color: t.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail ?? l10n.rigPhaseFailed,
              textAlign: TextAlign.center,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
