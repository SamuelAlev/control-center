/// The hypervisor stack behind a rig.
///
/// Every value here is producible by a backend that exists — there are no
/// aspirational entries. A backend that has not been built does not get an
/// enum value, because a value nothing can return reads as a capability when
/// it is only an intention.
enum EnclosureBackend {
  /// QEMU accelerated by Apple's Hypervisor.framework (macOS, arm64/x86_64).
  /// The Tier 1 default on a Mac.
  qemuHvf('qemu-hvf', 'QEMU (HVF)'),

  /// QEMU accelerated by KVM (Linux host with `/dev/kvm`).
  qemuKvm('qemu-kvm', 'QEMU (KVM)'),

  /// QEMU with no hardware acceleration — pure emulation. Correct but slow
  /// (roughly an order of magnitude), so it is never chosen automatically:
  /// it is what you get when you ask for a guest architecture the host cannot
  /// accelerate, and the UI says so rather than pretending the rig is fine.
  qemuTcg('qemu-tcg', 'QEMU (emulated)'),

  /// The Android emulator on the host's own hypervisor.
  ///
  /// It IS a QEMU VM, but it is not one we launched, configured or network-
  /// isolated: the emulator owns its own machine definition and networking.
  /// Labelling it `qemuHvf` alongside the rigs we do control would claim a
  /// containment we do not have, so it gets its own value and its own honest
  /// note.
  androidEmulator('android-emulator', 'Android emulator'),

  /// A smolvm microVM: libkrun over Hypervisor.framework (macOS), KVM (Linux)
  /// or WHP (Windows), booting a digest-pinned OCI image. Hosts the exec
  /// (terminal) and browser surfaces — neither needs a display device, and
  /// sub-second warm boots are what makes "every terminal is enclosed"
  /// affordable. The desktop surface keeps QEMU: it needs one.
  smolvm('smolvm', 'smolvm microVM');

  const EnclosureBackend(this.wire, this.label);

  /// Stable wire/storage string.
  final String wire;

  /// Human-readable label (sentence case at the call site).
  final String label;

  /// Whether this backend runs QEMU (all three accelerators share one adapter,
  /// one QMP control socket and one guest-agent protocol).
  bool get isQemu =>
      this == EnclosureBackend.qemuHvf ||
      this == EnclosureBackend.qemuKvm ||
      this == EnclosureBackend.qemuTcg;

  /// Whether this backend is hardware-accelerated. False means usable but
  /// slow, and the UI must say so.
  bool get isAccelerated => this != EnclosureBackend.qemuTcg;

  /// Whether this backend's guest gets egress confined to an allowlist.
  ///
  /// False for the Android emulator: it manages its own networking, so its
  /// egress is not enforced the way the other surfaces' is (per-rig proxies
  /// on QEMU, the VMM's own DNS/IP gate on smolvm). The UI and the tool
  /// description say so rather than implying parity.
  bool get hasEnforcedEgress => this != EnclosureBackend.androidEmulator;

  /// Parses [value] back into a backend, or null when unknown.
  static EnclosureBackend? fromWire(String? value) {
    for (final b in EnclosureBackend.values) {
      if (b.wire == value) {
        return b;
      }
    }
    return null;
  }
}
