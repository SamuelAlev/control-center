import 'package:control_center/app/focus_primary_window.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the floating soundscape mini-player window from the main isolate.
///
/// Like the focus pill and the meeting toolbar, the mini-player is a sibling
/// window in the same isolate (see `SoundscapeMiniPlayerWindow` / `AppWindows`),
/// so it reads [soundscapeProvider] directly with no cross-engine IPC. This
/// controller is the single bool — whether the mini-player is floating.
///
/// Pausing does NOT retire the mini-player: it stays floating with a play
/// button so playback can be resumed from it (like any media mini-player).
/// It is dismissed only by its own close button or when the app exits.
class SoundscapeMiniPlayerController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  /// Pops the mini-player out into its own always-on-top window. No-op unless
  /// audio is currently playing.
  void open() {
    if (state || !ref.read(soundscapeProvider).playing) {
      return;
    }
    state = true;
  }

  /// Closes the mini-player and brings the main window back to the front.
  void close() {
    if (!state) {
      return;
    }
    state = false;
    focusPrimaryWindow();
  }

  /// Toggles the mini-player.
  void toggle() => state ? close() : open();
}

/// Whether the floating soundscape mini-player window is open, and the
/// controller that manages it.
final soundscapeMiniPlayerControllerProvider =
    NotifierProvider<SoundscapeMiniPlayerController, bool>(
      SoundscapeMiniPlayerController.new,
    );
