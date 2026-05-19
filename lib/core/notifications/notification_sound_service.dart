import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
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
  ///
  /// [outputDeviceName] resolves the app-wide output device at PLAY time — a
  /// long-lived service outlives any one selection, so a value captured at
  /// construction would pin whichever device was chosen at app start.
  // The field stays PRIVATE so it is not part of the implicit interface
  // outside this library: the notification test doubles `implements` this
  // class, and a public member would force every one of them to grow a
  // resolver they have no use for. `this._x` is not expressible for a named
  // parameter, so the initializing formal the lint wants cannot be written.
  NotificationSoundService({String? Function()? outputDeviceName})
    // ignore: prefer_initializing_formals
    : _outputDeviceName = outputDeviceName;

  /// Resolves the app-wide output device name (null = system default), or is
  /// itself null where routing does not apply (web, tests).
  final String? Function()? _outputDeviceName;

  Player? _player;

  /// The device last handed to [_player], so a chime does not re-route (which
  /// makes mpv reinitialize its audio output) on every notification.
  /// `_deviceApplied` distinguishes "never applied" from "applied null", which
  /// is a real value meaning the system default.
  String? _appliedDevice;
  bool _deviceApplied = false;

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
      await _applyOutputDevice(player);
      // media_kit's volume is 0–100; the stored preference is 0..1. Passing it
      // through unscaled played every chime at 1% — audible as nothing at all.
      await player.setVolume(mediaKitVolume(volume));
      // Asset keys are `assets/<path>`; the triple-slash form is media_kit's
      // documented asset URI (works on native via the asset dir and on web via
      // the asset loader).
      await player.open(Media('asset:///assets/${sound.assetPath!}'));
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Failed to play sound: $e');
    }
  }

  /// Routes the player through the app-wide output device, if one resolves.
  ///
  /// A routing failure (device unplugged since it was picked) must not swallow
  /// the chime: mpv falls back to the default output, so the sound still plays
  /// and only the routing is logged.
  Future<void> _applyOutputDevice(Player player) async {
    final resolve = _outputDeviceName;
    if (resolve == null) {
      return;
    }
    final name = resolve();
    if (_deviceApplied && name == _appliedDevice) {
      return;
    }
    try {
      await applyAppAudioOutput(player, name);
      _appliedDevice = name;
      _deviceApplied = true;
    } on Object catch (e) {
      AppLog.w('notification_sound', 'Could not apply output device: $e');
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
    // The next play() builds a fresh player, which inherits no routing.
    _appliedDevice = null;
    _deviceApplied = false;
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
