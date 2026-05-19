/// Available sandbox backends.
///
/// Three today: a real VM boundary ([microvm]), OS-native primitives
/// ([native]) and the user-selected opt-out ([none]). The previous `docker`
/// and `auto` modes were removed when the in-project native sandbox (Seatbelt
/// + bubblewrap) landed; preferences still containing `"docker"` are migrated
/// to [native] on read by `SandboxPreferences`.
enum SandboxBackend {
  /// A rig: a disposable VM/microVM with a kernel boundary and a
  /// deny-by-default NIC. The strongest option, and the only one where the
  /// shell genuinely does not run on the host.
  ///
  /// Probe-gated — it needs a hypervisor and a base image, so it is offered
  /// only where `RigPort.probe()` says it can boot. Selecting it where it
  /// cannot boot is an error, never a silent downgrade to [native]: "I asked
  /// for a VM and got a Seatbelt profile" is exactly the sort of quiet
  /// weakening this enum exists to make visible.
  microvm,

  /// OS-native primitives wrapped by the in-project sandbox runtime:
  /// `sandbox-exec` (Seatbelt) on macOS, `bubblewrap` on Linux / WSL2.
  /// Namespace-level isolation only — no kernel boundary.
  native,

  /// User opted out. Falls back to bare `Process.start` on the host.
  none;

  /// Human-readable label used in settings and the chat badge.
  String get label {
    switch (this) {
      case SandboxBackend.microvm:
        return 'Enclosed VM';
      case SandboxBackend.native:
        return 'Native sandbox';
      case SandboxBackend.none:
        return 'No isolation';
    }
  }

  /// Whether the workload runs behind a kernel boundary rather than beside
  /// the host's own processes.
  bool get isEnclosed => this == SandboxBackend.microvm;

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
