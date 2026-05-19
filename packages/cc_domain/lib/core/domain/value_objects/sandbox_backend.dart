/// Available sandbox backends.
///
/// Trimmed to the two we ship today: OS-native primitives ([native]) and the
/// user-selected opt-out ([none]). The previous `docker` and `auto` modes
/// were removed when the in-project native sandbox (Seatbelt + bubblewrap)
/// landed; preferences still containing `"docker"` are migrated to [native]
/// on read by `SandboxPreferences`.
enum SandboxBackend {
  /// OS-native primitives wrapped by the in-project sandbox runtime:
  /// `sandbox-exec` (Seatbelt) on macOS, `bubblewrap` on Linux / WSL2.
  /// Namespace-level isolation only — no kernel boundary.
  native,

  /// User opted out. Falls back to bare `Process.start` on the host.
  none;

  /// Human-readable label used in settings and the chat badge.
  String get label {
    switch (this) {
      case SandboxBackend.native:
        return 'Native sandbox';
      case SandboxBackend.none:
        return 'No isolation';
    }
  }

  /// Parses [value] back into a backend. Legacy `"docker"` values rewrite to
  /// [native] so existing users keep their "sandboxed" intent; unknown
  /// values fall through to [none].
  static SandboxBackend fromName(String? value) {
    if (value == null) {
      return SandboxBackend.none;
    }
    if (value == 'docker') {
      return SandboxBackend.native;
    }
    for (final b in SandboxBackend.values) {
      if (b.name == value) {
        return b;
      }
    }
    return SandboxBackend.none;
  }
}
