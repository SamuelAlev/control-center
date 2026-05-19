import 'package:audioplayers/audioplayers.dart';
import 'package:control_center/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Plays notification sounds from bundled assets.
///
/// Uses a single [AudioPlayer] instance to avoid overlapping sounds.
/// If a sound is already playing, it is stopped first.
class NotificationSoundService {
  /// Creates a [NotificationSoundService].
  NotificationSoundService();

  final AudioPlayer _player = AudioPlayer();

  /// Plays the given notification [sound] at [volume] (0.0–1.0, default 1.0).
  ///
  /// Does nothing if [sound] is [NotificationSound.none].
  /// Silently catches playback errors — notification sounds are non-critical.
  Future<void> play(NotificationSound sound, {double volume = 1.0}) async {
    if (sound == NotificationSound.none || sound.assetPath == null) {
      return;
    }

    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource(sound.assetPath!));
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to play sound: $e');
    }
  }

  /// Stops any currently playing sound.
  Future<void> stop() async {
    try {
      await _player.stop();
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to stop sound: $e');
    }
  }

  /// Releases the underlying audio player resources.
  void dispose() {
    _player.dispose();
  }
}
