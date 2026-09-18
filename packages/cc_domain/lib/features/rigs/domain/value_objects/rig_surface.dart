/// What kind of machine a rig presents to the agent driving it.
///
/// The surface decides the execution environment, control protocol and verb
/// vocabulary — it is not cosmetic. One rig is exactly one surface; an agent
/// that needs both a browser and a desktop opens two.
enum RigSurface {
  /// A Linux desktop (X11 + a light window manager). Input is injected from
  /// the host through the hypervisor's own input device, so the guest never
  /// needs a privileged agent to be driven.
  computer,

  /// A headless Chromium driven over the Chrome DevTools Protocol. Text-first:
  /// the DOM and accessibility tree are the primary state, the screenshot is
  /// verification.
  browser,

  /// An Android device (an emulator on Tier 1, a redroid/Cuttlefish instance
  /// on a Linux worker) driven over ADB.
  mobile,

  /// An ephemeral iOS Simulator device on a macOS server, driven through
  /// CoreSimulator and WebDriverAgent.
  ios;

  /// Stable wire/storage string.
  String get wire => name;

  /// Human-readable label (sentence case).
  String get label => switch (this) {
    RigSurface.computer => 'Computer use',
    RigSurface.browser => 'Browser use',
    RigSurface.mobile => 'Android',
    RigSurface.ios => 'iOS Simulator',
  };

  /// Whether a viewer may renegotiate the guest display mode.
  ///
  /// Host-managed device simulators have a fixed logical display. Their
  /// frames fit the panel instead of changing device dimensions.
  bool get hasResizableDisplay => switch (this) {
    RigSurface.computer || RigSurface.browser => true,
    RigSurface.mobile || RigSurface.ios => false,
  };

  /// Parses [value] back into a surface, or null when unknown.
  static RigSurface? fromWire(String? value) {
    for (final s in RigSurface.values) {
      if (s.wire == value) {
        return s;
      }
    }
    return null;
  }
}
