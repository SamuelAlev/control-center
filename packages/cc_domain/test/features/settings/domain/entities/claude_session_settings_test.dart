import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:test/test.dart';

void main() {
  test('defaults leave Claude Code in charge', () {
    final settings = ClaudeSessionSettings();

    expect(settings.autoCompactWindow, isNull);
    expect(settings.compactIdleBeforeCacheExpires, isFalse);
  });

  test('accepts the limits and refuses anything past them', () {
    for (final window in [
      ClaudeSessionSettings.minAutoCompactWindow,
      ClaudeSessionSettings.maxAutoCompactWindow,
    ]) {
      expect(
        ClaudeSessionSettings(autoCompactWindow: window).autoCompactWindow,
        window,
      );
    }
    for (final window in [
      ClaudeSessionSettings.minAutoCompactWindow - 1,
      ClaudeSessionSettings.maxAutoCompactWindow + 1,
    ]) {
      expect(
        () => ClaudeSessionSettings(autoCompactWindow: window),
        throwsArgumentError,
      );
    }
  });

  test('round-trips through its stored shape', () {
    final settings = ClaudeSessionSettings(
      autoCompactWindow: 250000,
      compactIdleBeforeCacheExpires: true,
    );

    expect(ClaudeSessionSettings.fromJson(settings.toJson()), settings);
    expect(
      settings.hashCode,
      ClaudeSessionSettings.fromJson(settings.toJson()).hashCode,
    );
  });

  test('a stored window that is no longer valid falls back', () {
    final settings = ClaudeSessionSettings.fromJson(const {
      'autoCompactWindow': 5,
      'compactIdleBeforeCacheExpires': 'yes',
    });

    expect(settings, ClaudeSessionSettings());
  });
}
