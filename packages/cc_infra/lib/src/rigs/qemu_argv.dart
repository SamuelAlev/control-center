import 'dart:convert';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// Everything the argv builder needs, so building the command line is a pure
/// function of data rather than of a live machine.
///
/// This separation is the only reason the command line is testable: a rig
/// cannot be booted in CI, but the flags that decide whether the guest is
/// network-isolated absolutely must be.
class QemuLaunchPlan {
  /// Creates a [QemuLaunchPlan].
  const QemuLaunchPlan({
    required this.rigId,
    required this.backend,
    required this.overlayPath,
    required this.memoryMb,
    required this.cpuCount,
    required this.display,
    required this.qmpSocketPath,
    required this.sshHostPort,
    required this.agentHostPort,
    required this.surface,
    this.httpProxyHostPort,
    this.socksProxyHostPort,
    this.credentialHostPort,
    this.seedImagePath,
    this.machineType,
    this.firmwarePath,
  });

  /// The rig this machine serves.
  ///
  /// Emitted as `-name ccrig-<rigId>` so the process can be identified by an
  /// EXACT argv token. Without it the only way to recognise a rig's hypervisor
  /// from the outside was a substring search over the whole command line, and
  /// `qemu-img info .../<uuid>/overlay.qcow2` — the command an operator runs to
  /// inspect an orphaned overlay after a crash — matches "qemu" and the id
  /// both.
  final String rigId;

  /// Which accelerator to ask for.
  final EnclosureBackend backend;

  /// The per-session qcow2 overlay. NEVER the base image: the base is opened
  /// read-only as a backing file, so a rig cannot modify what the next rig
  /// boots from.
  final String overlayPath;

  /// Guest RAM.
  final int memoryMb;

  /// Guest vCPUs.
  final int cpuCount;

  /// Boot display mode.
  final RigDisplaySize display;

  /// Where QEMU should listen for QMP.
  final String qmpSocketPath;

  /// Host loopback port forwarded to the guest's SSH port.
  final int sshHostPort;

  /// Host loopback port forwarded to the guest agent.
  final int agentHostPort;

  /// Which machine this is (decides whether a GPU/tablet are needed).
  final RigSurface surface;

  /// Host port of the shared egress HTTP proxy, exposed to the guest.
  final int? httpProxyHostPort;

  /// Host port of the shared egress SOCKS proxy.
  final int? socksProxyHostPort;

  /// Host port of the credential-broker endpoint.
  final int? credentialHostPort;

  /// A cloud-init/seed image carrying the per-VM keys and tokens.
  final String? seedImagePath;

  /// An explicit `-machine` type, or null for the architecture default.
  final String? machineType;

  /// UEFI firmware to boot with (`-bios`), or null for the binary's built-in
  /// default.
  ///
  /// Load-bearing on aarch64: the `virt` machine has NO default firmware, so
  /// without this the vCPU starts on empty memory and the guest never executes
  /// a single instruction — the boot does not fail, it silently does nothing
  /// until the readiness probe gives up minutes later. x86_64 machines carry
  /// SeaBIOS internally and leave this null.
  final String? firmwarePath;
}

/// The longest a unix socket path may be, in bytes.
///
/// `sockaddr_un.sun_path` is 104 bytes on macOS/BSD and 108 on Linux. The
/// smaller bound is the portable one, and the path must still fit its
/// terminating NUL.
const int kMaxUnixSocketPathBytes = 104;

/// Builds the QMP control-socket path for [rigId] under the first of
/// [candidateRoots] that fits.
///
/// Deliberately NOT inside the rig's runtime directory. That directory lives
/// under an operator-chosen data directory whose length we do not control, and
/// a unix socket path is hard-capped — a checkout one level deeper than the
/// developer's is enough to push a full UUID past the limit, at which point
/// QEMU refuses to start with "path too long" and no rig boots at all. The
/// durable artifacts (overlay, seed image, private key) stay in the runtime
/// directory, where length does not matter.
///
/// The rig id is never truncated. Two rigs sharing a shortened prefix would
/// share a socket directory and the second would clobber the first's control
/// channel — a far worse failure than a long path.
String buildRigSocketPath({
  required List<String> candidateRoots,
  required String rigId,
  String fileName = 'qmp.sock',
}) {
  String candidate(String root) {
    final trimmed = root.length > 1 && root.endsWith('/')
        ? root.substring(0, root.length - 1)
        : root;
    return '$trimmed/ccrig/$rigId/$fileName';
  }

  for (final root in candidateRoots) {
    if (root.isEmpty) {
      continue;
    }
    final path = candidate(root);
    // BYTES, not UTF-16 code units. `sun_path` is a byte array, so a non-ASCII
    // `TMPDIR` (an accented username, a CJK directory) counts short by up to
    // 3× and hands QEMU a path the kernel truncates — which is the exact
    // failure this whole function exists to prevent, arriving silently.
    if (utf8.encode(path).length < kMaxUnixSocketPathBytes) {
      return path;
    }
  }
  // Every candidate was too long. `/tmp` is the shortest root present on every
  // POSIX host, so fall back to it rather than returning a path that is
  // guaranteed to fail at bind time.
  final fallback = candidate('/tmp');
  if (utf8.encode(fallback).length < kMaxUnixSocketPathBytes) {
    return fallback;
  }
  throw StateError(
    'No socket directory short enough for rig $rigId '
    '(limit $kMaxUnixSocketPathBytes bytes).',
  );
}

/// The roots to try for a rig control socket, most-private first.
///
/// `XDG_RUNTIME_DIR` is per-user and short on Linux; `TMPDIR` is per-user on
/// macOS. `/tmp` is the shared fallback, which is why the directory itself is
/// created 0700 — this socket is a full control channel for the VM.
List<String> defaultRigSocketRoots(Map<String, String> environment) => [
  ...[environment['XDG_RUNTIME_DIR'], environment['TMPDIR']].nonNulls,
  '/tmp',
];

/// The fixed guest-side addresses the guest's own config expects.
///
/// QEMU's user-mode network hands the guest a fixed 10.0.2.0/24 and these are
/// the addresses the base image's proxy environment and git helper are baked
/// against, so they are protocol, not preference.
abstract final class QemuGuestAddresses {
  /// Guest-visible address of the egress HTTP proxy.
  static const String httpProxy = '10.0.2.100';

  /// Guest-visible port of the egress HTTP proxy.
  static const int httpProxyPort = 3128;

  /// Guest-visible address of the egress SOCKS proxy.
  static const String socksProxy = '10.0.2.101';

  /// Guest-visible port of the egress SOCKS proxy.
  static const int socksProxyPort = 1080;

  /// Guest-visible address of the host credential broker.
  static const String credentialBroker = '10.0.2.102';

  /// Guest-visible port of the host credential broker.
  static const int credentialBrokerPort = 8420;
}

/// The `-name` value a rig's hypervisor carries.
///
/// The prefix matters as much as the id: it is what lets the reaper match an
/// EXACT argv token instead of searching the whole command line for a uuid
/// that also appears in every path built from it.
String qemuProcessName(String rigId) => 'ccrig-$rigId';

/// Builds the QEMU command line for [plan].
///
/// The security-critical parts, all pinned by `qemu_argv_test.dart`:
///
///  * `restrict=on` on the user-mode netdev. Without it the guest reaches the
///    host's LAN and the internet directly and every egress control in this
///    system is decoration.
///  * Every host-facing forward binds `127.0.0.1` explicitly. A bare
///    `hostfwd=tcp::2222-:22` listens on 0.0.0.0 and publishes a shell on the
///    rig to the local network.
///  * The base image is a read-only backing file behind a per-session overlay,
///    so a rig cannot alter what the next one boots.
///  * No host filesystem is passed through — no `-virtfs`, no `-fsdev`. The
///    worktree is copied in, not mounted.
List<String> buildQemuArgv(QemuLaunchPlan plan) {
  final argv = <String>[
    // Accelerator. `tcg` is emulation — correct, and roughly an order of
    // magnitude slower, which is why it is never selected automatically.
    '-accel',
    switch (plan.backend) {
      EnclosureBackend.qemuHvf => 'hvf',
      EnclosureBackend.qemuKvm => 'kvm',
      _ => 'tcg',
    },
    // Explicit CPU model. Recent QEMU resolves a usable default under
    // hvf/kvm, but older builds refuse to start the aarch64 `virt` machine's
    // 32-bit default CPU under a 64-bit hypervisor — `host` (accelerated) /
    // `max` (emulated) is correct on every version.
    '-cpu',
    plan.backend == EnclosureBackend.qemuHvf ||
            plan.backend == EnclosureBackend.qemuKvm
        ? 'host'
        : 'max',
    '-m', '${plan.memoryMb}',
    '-smp', '${plan.cpuCount}',
    // No display window on the host: the frames come from inside the guest.
    // A rig that opened a window on the operator's desktop would be both
    // startling and unusable on a headless server.
    '-display', 'none',
    '-nodefaults',
    // Serial to stdio so a kernel panic during boot is visible in the server
    // log rather than being an unexplained timeout.
    '-serial', 'stdio',
    '-qmp', 'unix:${plan.qmpSocketPath},server=on,wait=off',
    // Identity, for the reaper. `debug-threads=on` also names the guest's
    // threads after the machine, which is what makes `top` legible when two
    // rigs are running.
    '-name', qemuProcessName(plan.rigId),
  ];

  if (plan.machineType != null) {
    argv
      ..add('-machine')
      ..add(plan.machineType!);
  }
  if (plan.firmwarePath != null) {
    argv
      ..add('-bios')
      ..add(plan.firmwarePath!);
  }

  // ── Storage ────────────────────────────────────────────────────────────
  argv
    ..add('-drive')
    ..add('file=${plan.overlayPath},if=virtio,format=qcow2,cache=writeback');
  if (plan.seedImagePath != null) {
    argv
      ..add('-drive')
      ..add('file=${plan.seedImagePath},if=virtio,format=raw,readonly=on');
  }

  // ── Network ────────────────────────────────────────────────────────────
  final netdev = StringBuffer('user,id=net0,restrict=on');
  // Host → guest. Bound to loopback so nothing on the LAN can reach the rig.
  netdev.write(',hostfwd=tcp:127.0.0.1:${plan.sshHostPort}-:22');
  netdev.write(',hostfwd=tcp:127.0.0.1:${plan.agentHostPort}-:7811');
  // Guest → host, one hole per service. With `restrict=on` these are the ONLY
  // outbound paths that exist: the guest cannot reach the host, the LAN or the
  // internet by any other route, so the proxies are not merely the recommended
  // path, they are the only one.
  if (plan.httpProxyHostPort != null) {
    netdev.write(
      ',guestfwd=tcp:${QemuGuestAddresses.httpProxy}:'
      '${QemuGuestAddresses.httpProxyPort}-'
      'tcp:127.0.0.1:${plan.httpProxyHostPort}',
    );
  }
  if (plan.socksProxyHostPort != null) {
    netdev.write(
      ',guestfwd=tcp:${QemuGuestAddresses.socksProxy}:'
      '${QemuGuestAddresses.socksProxyPort}-'
      'tcp:127.0.0.1:${plan.socksProxyHostPort}',
    );
  }
  if (plan.credentialHostPort != null) {
    netdev.write(
      ',guestfwd=tcp:${QemuGuestAddresses.credentialBroker}:'
      '${QemuGuestAddresses.credentialBrokerPort}-'
      'tcp:127.0.0.1:${plan.credentialHostPort}',
    );
  }
  argv
    ..add('-netdev')
    ..add(netdev.toString())
    ..add('-device')
    ..add('virtio-net-pci,netdev=net0');

  // ── Graphics + input ───────────────────────────────────────────────────
  //
  // Keyed on whether the surface HAS A DISPLAY, not on "is not browser". The
  // negative form was a statement about today's catalogue: add a
  // browser-on-QEMU entry (or any third display surface) and it boots with no
  // GPU and no input devices — a machine that renders nothing and cannot be
  // clicked, for a reason nothing in the argv explains.
  if (_surfaceNeedsDisplay(plan.surface)) {
    // 2D virtio-gpu. No `virtio-gpu-gl`: upstream QEMU on macOS has no
    // virglrenderer, so asking for GL fails to start rather than degrading.
    // Accelerated graphics is a later tier with a vendored QEMU build.
    argv
      ..add('-device')
      ..add(
        'virtio-gpu-pci,xres=${plan.display.width},yres=${plan.display.height}',
      )
      // Absolute pointer positioning. A PS/2 mouse only reports deltas, so
      // "click at (412, 180)" would be unimplementable and the pointer would
      // drift out of sync with the screenshots the model is looking at.
      ..add('-device')
      ..add('virtio-tablet-pci')
      ..add('-device')
      ..add('virtio-keyboard-pci');
  }

  argv
    ..add('-device')
    ..add('virtio-rng-pci');
  return argv;
}

/// The `qemu-img create` arguments for a rig's per-session overlay.
///
/// Pure for the same reason [buildQemuArgv] is: this is where "a rig cannot
/// change what the next rig boots from" is actually decided, and it is decided
/// by three flags nobody would notice going missing. An overlay created
/// WITHOUT `-b` is a blank disk (the rig boots to nothing); an overlay created
/// with the base as its target rather than its backing file writes the guest's
/// changes straight into the shared image, and every later rig inherits them.
///
/// `-F qcow2` states the backing file's format explicitly: qemu-img refuses to
/// probe it, so omitting it fails the create on current QEMU rather than
/// guessing.
List<String> buildQemuOverlayArgs({
  required String basePath,
  required String overlayPath,
}) => ['create', '-f', 'qcow2', '-F', 'qcow2', '-b', basePath, overlayPath];

/// Whether [surface] presents a screen a human watches and a pointer drives.
///
/// A browser rig is CDP-driven and headless: its frames come from Chromium's
/// screencast, not from a framebuffer, and its input goes over CDP rather than
/// through the hypervisor. Everything else needs a GPU, an absolute-positioning
/// tablet and a keyboard.
bool _surfaceNeedsDisplay(RigSurface surface) => switch (surface) {
  RigSurface.browser => false,
  RigSurface.computer || RigSurface.mobile => true,
};

/// The QEMU binary name for [architecture] (`arm64`/`x64`).
String qemuBinaryFor(String architecture) =>
    architecture == 'arm64' || architecture == 'aarch64'
    ? 'qemu-system-aarch64'
    : 'qemu-system-x86_64';

/// The `-machine` type for [architecture], or null to take QEMU's default.
///
/// aarch64 has no default machine at all — QEMU exits with "no machine
/// specified" — so this is required there rather than a nicety.
String? qemuMachineFor(String architecture) =>
    architecture == 'arm64' || architecture == 'aarch64'
    ? 'virt,highmem=on'
    : null;

/// The UEFI firmware file [architecture] needs, or null when the QEMU binary
/// carries a built-in default.
///
/// aarch64's `virt` machine ships NO firmware in the binary: without
/// `-bios edk2-aarch64-code.fd` the guest executes nothing, forever, and the
/// boot "fails" only as a readiness timeout minutes later. The file ships in
/// every QEMU install's data directory (`qemu -L help` lists them). x86_64
/// falls back to its built-in SeaBIOS, so it needs nothing here.
String? qemuFirmwareFileFor(String architecture) =>
    architecture == 'arm64' || architecture == 'aarch64'
    ? 'edk2-aarch64-code.fd'
    : null;
