import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _tag = 'Soundscape';

/// An always-mounted, zero-visual host that owns the single soundscape
/// [AudioPlayer] and keeps it in sync with [soundscapeProvider].
///
/// The server generates the ambient audio and serves it as an infinite MP3
/// stream (`/soundscape/stream`); this widget just points the player at the
/// current mood's URL, sets the volume, and resumes/stops as `playing`
/// toggles — there is no seek or duration (a live radio stream). It renders
/// nothing ([SizedBox.shrink]); the orchestrator mounts it once in the shell.
class SoundscapeAudioHost extends ConsumerStatefulWidget {
  /// Creates a [SoundscapeAudioHost].
  const SoundscapeAudioHost({super.key});

  @override
  ConsumerState<SoundscapeAudioHost> createState() =>
      _SoundscapeAudioHostState();
}

class _SoundscapeAudioHostState extends ConsumerState<SoundscapeAudioHost> {
  final AudioPlayer _player = AudioPlayer();

  /// The source URL currently loaded into the player, so an unrelated rebuild
  /// (or a volume-only change) does not re-point and restart the stream.
  String? _currentUrl;

  /// Set in [dispose] so an in-flight [_applyState] cannot re-arm a player that
  /// is already being torn down.
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // It is a live stream: stop (don't loop) when it ever ends, and never hold
    // the audio session open after a stop.
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
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
      await _player.setVolume(s.volume);
      if (_disposed) {
        return;
      }
      if (url != _currentUrl) {
        _currentUrl = url;
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setSourceUrl(url);
        if (_disposed) {
          return;
        }
        await _player.resume();
      }
    } on Object catch (e) {
      // Bad URL, disconnected, or no audio backend: leave it stopped rather
      // than crashing the app shell.
      _currentUrl = null;
      AppLog.w(_tag, 'Could not start soundscape stream: $e');
    }
  }

  Future<void> _stopQuietly() async {
    try {
      await _player.stop();
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
