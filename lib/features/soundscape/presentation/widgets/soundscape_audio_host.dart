import 'dart:async';

import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

const _tag = 'Soundscape';

/// An always-mounted, zero-visual host that owns the single soundscape
/// [Player] and keeps it in sync with [soundscapeProvider].
///
/// The server generates the ambient audio and serves it as an infinite MP3
/// stream (`/soundscape/stream`); this widget just points the player at the
/// current mood's URL, sets the volume and resumes/stops as `playing`
/// toggles — there is no seek or duration (a live radio stream). It renders
/// nothing ([SizedBox.shrink]); the orchestrator mounts it once in the shell.
///
/// The player is media_kit (libmpv) specifically because it can route to a
/// chosen OUTPUT device: the app-wide selection in You → Audio is applied
/// here, the same way every other sound-making surface applies it. Web has no
/// output routing (the browser decides), so the device application is
/// native-only.
class SoundscapeAudioHost extends ConsumerStatefulWidget {
  /// Creates a [SoundscapeAudioHost].
  const SoundscapeAudioHost({super.key});

  @override
  ConsumerState<SoundscapeAudioHost> createState() =>
      _SoundscapeAudioHostState();
}

class _SoundscapeAudioHostState extends ConsumerState<SoundscapeAudioHost> {
  /// Created on the first note actually played, not on mount.
  ///
  /// `Player()` resolves the libmpv native library eagerly, so constructing it
  /// in a field initializer meant MOUNTING THE APP SHELL required a working
  /// audio backend: every widget test that renders `ControlCenterLayout` threw
  /// "MediaKit.ensureInitialized must be called…" before it could find
  /// anything, and a headless/CI machine with no libmpv could not open the
  /// shell at all. The soundscape is off by default, so the common case pays
  /// for a backend it never uses.
  ///
  /// Same shape `NotificationSoundService` already uses, for the same reason.
  Player? _player;

  Player get _ensurePlayer => _player ??= Player();

  /// The source URL currently loaded into the player, so an unrelated rebuild
  /// (or a volume-only change) does not re-point and restart the stream.
  String? _currentUrl;

  /// Set in [dispose] so an in-flight [_applyState] cannot re-arm a player that
  /// is already being torn down.
  bool _disposed = false;

  /// Routes the player through the selected output device (native only —
  /// mpv's `auto` is the system default, which is all the web player can do).
  Future<void> _applyOutputDevice(String? name) async {
    if (_disposed || kIsWeb) {
      return;
    }
    try {
      // Only routes a player that EXISTS: creating one here would defeat the
      // laziness, and there is nothing to route until something plays. The
      // listener re-applies the device the next time a stream starts.
      final player = _player;
      if (player == null) {
        return;
      }
      await applyAppAudioOutput(player, name);
    } on Object catch (e) {
      AppLog.w(_tag, 'Could not apply output device: $e');
    }
  }

  /// Drives the player to match [s]. URL resolution (which needs [context]) is
  /// done synchronously up front, before any `await`, so it never touches an
  /// unmounted element.
  Future<void> _applyState(SoundscapeState s) async {
    if (_disposed) {
      return;
    }
    if (!s.playing) {
      _currentUrl = null;
      await _stopQuietly();
      return;
    }
    final ws = ref.read(activeWorkspaceIdProvider);
    final url = ws == null
        ? null
        : MediaProxyScope.soundscapeStreamUrlOf(
            context,
            workspaceId: ws,
            mood: s.mood.name,
          );
    if (url == null) {
      // Not connected / no active workspace — nothing to stream.
      _currentUrl = null;
      await _stopQuietly();
      return;
    }
    try {
      // The first note is what creates the player — and, with it, applies the
      // persisted output device that `_applyOutputDevice` had nothing to route.
      final fresh = _player == null;
      final player = _ensurePlayer;
      if (fresh && !kIsWeb) {
        await _applyOutputDevice(ref.read(audioOutputDeviceProvider));
        if (_disposed) {
          return;
        }
      }
      await player.setVolume(mediaKitVolume(s.volume));
      if (_disposed) {
        return;
      }
      if (url != _currentUrl) {
        _currentUrl = url;
        // It is a live stream: no looping, and stop (not pause) at end.
        await player.setPlaylistMode(PlaylistMode.none);
        await player.open(Media(url), play: true);
        if (_disposed) {
          return;
        }
      }
    } on Object catch (e) {
      // Bad URL, disconnected, or no audio backend: leave it stopped rather
      // than crashing the app shell.
      _currentUrl = null;
      AppLog.w(_tag, 'Could not start soundscape stream: $e');
    }
  }

  Future<void> _stopQuietly() async {
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await player.stop();
    } on Object {
      // Already stopped / disposed — nothing to do.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    // `State.dispose()` cannot be async; drive stop → dispose to completion in a
    // detached closure that keeps the player reachable until the chain settles.
    final player = _player;
    _player = null;
    if (player == null) {
      super.dispose();
      return;
    }
    unawaited(() async {
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
  Widget build(BuildContext context) {
    // React to playback/mood/volume changes and re-point the player. Playback
    // is never persisted (always stopped on mount), so there is no initial
    // state to apply — the first apply happens when `playing` flips to true.
    ref.listen<SoundscapeState>(
      soundscapeProvider,
      (_, next) => unawaited(_applyState(next)),
    );

    // React to the output-device selection: applied to the live player
    // immediately, so changing the device mid-ambience does not restart the
    // stream.
    ref.listen<String?>(
      audioOutputDeviceProvider,
      (_, next) => unawaited(_applyOutputDevice(next)),
    );

    // Focus-mode auto-start: entering focus starts the soundscape (when opted
    // in and not already playing); leaving focus stops it if it is playing.
    ref.listen<bool>(focusModeProvider.select((s) => s.active), (_, active) {
      final s = ref.read(soundscapeProvider);
      final controller = ref.read(soundscapeProvider.notifier);
      if (active && s.autoStartWithFocus && !s.playing) {
        controller.play();
      } else if (!active && s.playing) {
        controller.stop();
      }
    });

    return const SizedBox.shrink();
  }
}
