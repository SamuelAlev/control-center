import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:media_kit/media_kit.dart';

/// Plays notification sounds from bundled assets.
///
/// Uses a single libmpv-backed [Player] (media_kit) to avoid overlapping
/// sounds. If a sound is already playing, it is stopped first. The player is
/// created lazily on the first sound actually played: the service is
/// constructed at app startup on every machine, including ones with sounds
/// disabled (and test doubles that subclass this), and none of them should
/// pay for — or require — a native audio backend they never use.
class NotificationSoundService {
  /// Creates a [NotificationSoundService].
  NotificationSoundService();

  Player? _player;

  Player get _ensurePlayer => _player ??= Player();

  /// Plays the given notification [sound] at [volume] (0.0–1.0, default 1.0).
  ///
  /// Does nothing if [sound] is [NotificationSound.none].
  /// Silently catches playback errors — notification sounds are non-critical.
  Future<void> play(NotificationSound sound, {double volume = 1.0}) async {
    if (sound == NotificationSound.none || sound.assetPath == null) {
      return;
    }

    try {
      final player = _ensurePlayer;
      await player.stop();
      await player.setVolume(volume);
      // Asset keys are `assets/<path>`; the triple-slash form is media_kit's
      // documented asset URI (works on native via the asset dir and on web via
      // the asset loader).
      await player.open(Media('asset:///assets/${sound.assetPath!}'));
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to play sound: $e');
    }
  }

  /// Stops any currently playing sound.
  Future<void> stop() async {
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await player.stop();
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to stop sound: $e');
    }
  }

  /// Releases the underlying audio player resources, if any were created.
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    if (player == null) {
      return;
    }
    try {
      await player.dispose();
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to dispose player: $e');
    }
  }
}
