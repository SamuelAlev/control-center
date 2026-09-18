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
import 'package:media_kit/media_kit.dart';

/// The panel's title row: machine identity, state, and live media controls.
class RigHeader extends StatelessWidget {
  /// Creates a [RigHeader].
  const RigHeader({
    super.key,
    required this.rig,
    this.onStop,
    this.audioOn = false,
    this.onToggleAudio,
    this.microphoneOn = false,
    this.onToggleMicrophone,
    this.onNetworkSecurity,
    this.networkRestarting = false,
  });

  /// The machine this header describes.
  final RigView rig;

  /// Stops the machine; null when this surface offers no stop control here.
  final VoidCallback? onStop;

  /// Whether guest audio currently plays here.
  final bool audioOn;

  /// Toggles guest audio; null when this surface has no audio lane.
  final VoidCallback? onToggleAudio;

  /// Whether the viewer's microphone currently feeds the guest.
  final bool microphoneOn;

  /// Toggles microphone input; null when this surface has no input lane.
  final VoidCallback? onToggleMicrophone;

  /// Opens the per-session network security setting.
  final VoidCallback? onNetworkSecurity;

  /// Whether the unrestricted replacement is being started.
  final bool networkRestarting;

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
          Flexible(
            child: Text(
              // Named by ENGINE on a browser rig: three of them can be open at
              // once and "Browser" on all three says nothing about which page
              // is on screen.
              rigSurfaceLabel(l10n, rig.surfaceKind, engine: rig.browserEngine),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
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
          if (rig.networkIsUnrestricted) ...[
            const SizedBox(width: AppSpacing.xs),
            CcStatusTag(
              label: l10n.rigNetworkUnrestricted,
              tone: CcStatusTone.caution,
            ),
          ],
          const Spacer(),
          if (rig.displayWidth != null && rig.displayHeight != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
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
            if (onToggleMicrophone != null) ...[
              CcIconButton(
                icon: microphoneOn ? AppIcons.mic : AppIcons.micOff,
                tooltip: l10n.meetingRecordMic,
                onPressed: onToggleMicrophone,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (onNetworkSecurity != null) ...[
              CcIconButton(
                icon: networkRestarting
                    ? AppIcons.refreshCw
                    : rig.networkIsUnrestricted
                    ? AppIcons.shieldOff
                    : AppIcons.shield,
                tooltip: rig.networkIsUnrestricted
                    ? l10n.rigNetworkUnrestricted
                    : l10n.rigNetworkAllowAllHosts,
                color: rig.networkIsUnrestricted ? t.fgWarningPrimary : null,
                loading: networkRestarting,
                onPressed: networkRestarting ? null : onNetworkSecurity,
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

/// Plays the rig's audio lane while mounted and renders nothing. The player
/// stays mounted behind inactive tabs so sound continues while the unseen
/// frame lane pauses. Muting or closing the tab unmounts it and closes the
/// guest-side encoder connection.
class RigAudioPlayer extends StatefulWidget {
  /// Creates a [RigAudioPlayer].
  const RigAudioPlayer({
    super.key,
    required this.url,
    this.outputDeviceName,
    this.onPlayingChanged,
  });

  /// The signed audio-lane URL, or null when there is no live connection.
  final String? url;

  /// Per-tab output device name, or null for the system default.
  final String? outputDeviceName;

  /// Reports whether the player is actively rendering the lane.
  final ValueChanged<bool>? onPlayingChanged;
  @override
  State<RigAudioPlayer> createState() => _RigAudioPlayerState();
}

class _RigAudioPlayerState extends State<RigAudioPlayer> {
  Player? _player;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Player _ensurePlayer() {
    final existing = _player;
    if (existing != null) {
      return existing;
    }
    final player = Player();
    _player = player;
    _playingSubscription = player.stream.playing.distinct().listen((playing) {
      if (mounted) {
        widget.onPlayingChanged?.call(playing);
      }
    });
    return player;
  }

  @override
  void didUpdateWidget(RigAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _play();
    } else if (oldWidget.outputDeviceName != widget.outputDeviceName) {
      unawaited(_applyOutputDevice());
    }
  }

  Future<void> _applyOutputDevice() async {
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await applyAppAudioOutput(player, widget.outputDeviceName);
    } on Object {
      // Device gone since it was picked: mpv falls back to the default output,
      // so the lane still plays.
    }
  }

  void _notifyAfterFrame(bool playing) {
    final callback = widget.onPlayingChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback?.call(playing);
    });
  }

  void _play() {
    final url = widget.url;
    if (url == null) {
      _notifyAfterFrame(false);
      return;
    }
    final player = _ensurePlayer();
    unawaited(() async {
      await _applyOutputDevice();
      try {
        await player.open(Media(url));
      } on Object {
        if (mounted) {
          widget.onPlayingChanged?.call(false);
        }
      }
    }());
  }

  @override
  void dispose() {
    // Provider-backed parents cannot be mutated while Flutter is finalizing
    // this subtree. Hidden parents remain mounted and consume this after the
    // frame; closed parents guard it out.
    _notifyAfterFrame(false);
    unawaited(_playingSubscription?.cancel());
    unawaited(() async {
      final player = _player;
      if (player == null) {
        return;
      }
      try {
        await player.stop();
      } on Object {
        // Already stopped — nothing to do.
      }
      try {
        await player.dispose();
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
