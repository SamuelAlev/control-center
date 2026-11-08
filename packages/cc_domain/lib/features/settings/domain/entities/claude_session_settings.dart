/// How Control Center manages the length of Claude Code sessions on this
/// server. One value per server, like the Claude Code logins it applies to.
class ClaudeSessionSettings {
  /// Creates [ClaudeSessionSettings]. Throws when [autoCompactWindow] is
  /// outside what Claude Code accepts.
  ClaudeSessionSettings({
    this.autoCompactWindow,
    this.compactIdleBeforeCacheExpires = false,
  }) {
    final window = autoCompactWindow;
    if (window != null &&
        (window < minAutoCompactWindow || window > maxAutoCompactWindow)) {
      throw ArgumentError.value(
        window,
        'autoCompactWindow',
        'must be $minAutoCompactWindow to $maxAutoCompactWindow',
      );
    }
  }

  /// Reads settings from their stored shape. A value that is no longer valid
  /// falls back to the default rather than failing every run.
  factory ClaudeSessionSettings.fromJson(Map<String, dynamic> json) {
    final window = json['autoCompactWindow'];
    final valid =
        window is int &&
        window >= minAutoCompactWindow &&
        window <= maxAutoCompactWindow;
    return ClaudeSessionSettings(
      autoCompactWindow: valid ? window : null,
      compactIdleBeforeCacheExpires:
          json['compactIdleBeforeCacheExpires'] == true,
    );
  }

  /// The smallest window Claude Code accepts.
  static const int minAutoCompactWindow = 100000;

  /// The largest window Claude Code accepts.
  static const int maxAutoCompactWindow = 1000000;

  /// The context size below which an idle conversation is left alone: a cold
  /// re-read is cheap there, so compacting mostly loses context for little
  /// saving.
  static const int minIdleCompactTokens = 200000;

  /// Tokens of context at which Claude Code compacts by itself. Null leaves
  /// Claude Code's own default in charge.
  final int? autoCompactWindow;

  /// Whether an idle conversation is compacted while its prompt cache is still
  /// warm, so coming back to it does not pay to re-read it all.
  final bool compactIdleBeforeCacheExpires;

  /// The stored shape.
  Map<String, Object?> toJson() => {
    'autoCompactWindow': autoCompactWindow,
    'compactIdleBeforeCacheExpires': compactIdleBeforeCacheExpires,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaudeSessionSettings &&
          autoCompactWindow == other.autoCompactWindow &&
          compactIdleBeforeCacheExpires == other.compactIdleBeforeCacheExpires;

  @override
  int get hashCode =>
      Object.hash(autoCompactWindow, compactIdleBeforeCacheExpires);
}
