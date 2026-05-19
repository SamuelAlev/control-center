import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart'
    show kBaselineDeniedDomains;
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart'
    show NetworkConfig;
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/qemu_argv.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:cc_infra/src/rigs/rig_image_store.dart';
import 'package:cc_infra/src/rigs/rig_machine.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:cc_infra/src/sandboxing/socks_proxy.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// How many QEMU stderr lines are retained for the startup-crash message.
/// A QEMU that rejects its command line says so in a handful of lines.
const int _qemuStderrTailLines = 200;

/// A rig could not be booted.
class RigLaunchException implements Exception {
  /// Creates a [RigLaunchException].
  const RigLaunchException(this.message);

  /// What went wrong, phrased for the operator.
  final String message;

  @override
  String toString() => message;
}

/// A host tool the rig runtime shells out to failed.
///
/// A [RigLaunchException] so nothing that already catches a launch failure
/// stops working, but typed and carrying the tool's own stderr: the documented
/// crash-loop was a `chmod` whose exit code nobody read, and "the image may be
/// wrong for this surface" two minutes later is not the same information as
/// "chmod: /path: Operation not permitted".
class RigToolException extends RigLaunchException {
  /// Creates a [RigToolException].
  RigToolException({
    required this.tool,
    required this.stderr,
    this.exitCode,
    this.arguments = const [],
    this.hint,
  }) : super(_format(tool, exitCode, stderr, hint));

  /// The tool that failed, as an operator would name it.
  final String tool;

  /// Its exit code, or null when it could not be started at all (or when
  /// several candidate tools were tried and every one failed).
  final int? exitCode;

  /// The arguments it was given.
  final List<String> arguments;

  /// Whatever it wrote to stderr, trimmed.
  final String stderr;

  /// What the operator can do about it.
  final String? hint;

  static String _format(
    String tool,
    int? exitCode,
    String stderr,
    String? hint,
  ) {
    final buffer = StringBuffer(
      exitCode == null
          ? '$tool could not be run'
          : '$tool failed (exit $exitCode)',
    );
    final detail = stderr.trim();
    if (detail.isNotEmpty) {
      buffer.write(': $detail');
    }
    if (hint != null && hint.isNotEmpty) {
      buffer.write('\n$hint');
    }
    return buffer.toString();
  }
}

/// Looks at and signals host processes.
///
/// Seamed so the lifecycle paths — which decide whether a directory holding a
/// live VM's overlay may be deleted — are testable without booting a
/// hypervisor or killing a real pid.
///
/// A probe that cannot answer must THROW rather than report "gone": every
/// caller treats an unanswerable probe as "unknown", and unknown is never a
/// licence to delete.
abstract class RigProcessProbe {
  /// The full command line of [pid], or null when there is no such process.
  Future<String?> commandLine(int pid);

  /// Whether [pid] names a live process.
  Future<bool> isAlive(int pid);

  /// Sends [signal] to [pid]. False when there was no such process.
  Future<bool> signal(int pid, ProcessSignal signal);
}

/// The real [RigProcessProbe]: `/proc` on Linux, `ps` elsewhere.
class SystemRigProcessProbe implements RigProcessProbe {
  /// Creates a [SystemRigProcessProbe].
  const SystemRigProcessProbe();

  static bool get _hasProc =>
      Platform.isLinux && Directory('/proc').existsSync();

  @override
  Future<bool> isAlive(int pid) async {
    if (pid <= 0) {
      return false;
    }
    if (_hasProc) {
      return Directory('/proc/$pid').existsSync();
    }
    if (Platform.isWindows) {
      return false;
    }
    // A ProcessException (no `ps` on this host) deliberately propagates: the
    // caller must not read "the probe is broken" as "the process is gone".
    final result = await Process.run('ps', ['-p', '$pid', '-o', 'pid=']);
    return result.exitCode == 0 && '${result.stdout}'.trim().isNotEmpty;
  }

  @override
  Future<String?> commandLine(int pid) async {
    if (pid <= 0) {
      return null;
    }
    if (_hasProc) {
      final file = File('/proc/$pid/cmdline');
      if (!file.existsSync()) {
        return null;
      }
      try {
        final raw = await file.readAsString();
        final line = raw.replaceAll('\u0000', ' ').trim();
        return line.isEmpty ? null : line;
      } on Object {
        // The process exited between the stat and the read.
        return null;
      }
    }
    if (Platform.isWindows) {
      return null;
    }
    final result = await Process.run('ps', ['-p', '$pid', '-o', 'command=']);
    if (result.exitCode != 0) {
      return null;
    }
    final line = '${result.stdout}'.trim();
    return line.isEmpty ? null : line;
  }

  @override
  Future<bool> signal(int pid, ProcessSignal signal) async {
    if (pid <= 0) {
      return false;
    }
    try {
      return Process.killPid(pid, signal);
    } on Object {
      return false;
    }
  }
}

/// How long each teardown escalation waits before the next one.
///
/// A value object rather than constants so a test can run the full ladder in
/// milliseconds; the defaults are the production ones.
class RigTeardownLadder {
  /// Creates a [RigTeardownLadder].
  const RigTeardownLadder({
    this.powerdown = const Duration(seconds: 5),
    this.quit = const Duration(seconds: 3),
    this.kill = const Duration(seconds: 3),
    this.poll = const Duration(milliseconds: 200),
  });

  /// How long an ACPI powerdown gets before QMP `quit`.
  final Duration powerdown;

  /// How long `quit` gets before SIGKILL.
  final Duration quit;

  /// How long a signalled process gets to actually leave.
  final Duration kill;

  /// How often liveness is re-checked while waiting.
  final Duration poll;
}

/// Who a rig runtime directory belongs to.
///
/// Written beside the overlay at launch and read by the orphan sweep. Without
/// it the sweep is a `rm -rf` of every directory it can see: two servers
/// sharing a data dir (or a `TMPDIR`) delete each other's live overlays and
/// control sockets, and a QEMU whose state has been removed keeps running.
class RigRuntimeOwner {
  /// Creates a [RigRuntimeOwner].
  const RigRuntimeOwner({
    required this.rigId,
    required this.serverPid,
    required this.serverInstance,
    this.qemuPid,
    this.serverCommand,
    this.createdAt,
  });

  /// The marker THIS server process writes when it claims a directory.
  factory RigRuntimeOwner.forThisServer({
    required String rigId,
    int? qemuPid,
  }) => RigRuntimeOwner(
    rigId: rigId,
    serverPid: pid,
    serverInstance: currentServerInstance,
    serverCommand: currentServerCommand,
    qemuPid: qemuPid,
    createdAt: DateTime.now(),
  );

  /// Reads the wire form.
  factory RigRuntimeOwner.fromJson(Map<String, dynamic> json) =>
      RigRuntimeOwner(
        rigId: '${json['rig_id'] ?? ''}',
        qemuPid: (json['qemu_pid'] as num?)?.toInt(),
        serverPid: (json['server_pid'] as num?)?.toInt(),
        serverInstance: json['server_instance'] as String?,
        serverCommand: json['server_command'] as String?,
        createdAt: DateTime.tryParse('${json['created_at']}'),
      );

  /// The marker's filename inside a runtime or socket directory.
  static const String fileName = 'owner.json';

  /// Identifies THIS server run.
  ///
  /// A pid alone cannot: a server that crashed and a live sibling can hold the
  /// same number on a host that recycled it, and the two answers ("sweep it"
  /// versus "that VM is running") are opposite.
  static final String currentServerInstance = _mintInstanceId();

  /// This server's executable name, so a recycled pid running something else
  /// is not mistaken for the sibling that wrote a marker.
  static final String currentServerCommand = p.basename(
    Platform.resolvedExecutable,
  );

  static String _mintInstanceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// The rig this directory serves.
  final String rigId;

  /// The hypervisor's pid, once it is known. Null between the directory being
  /// created and QEMU being started.
  final int? qemuPid;

  /// The pid of the server that created it.
  final int? serverPid;

  /// Which RUN of that server — a pid alone cannot tell a live sibling from a
  /// dead predecessor whose pid the host handed out again.
  final String? serverInstance;

  /// The owning server's executable name, so a reused pid running something
  /// else is not mistaken for the sibling that wrote this.
  final String? serverCommand;

  /// When the directory was claimed.
  final DateTime? createdAt;

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'rig_id': rigId,
    if (qemuPid != null) 'qemu_pid': qemuPid,
    if (serverPid != null) 'server_pid': serverPid,
    if (serverInstance != null) 'server_instance': serverInstance,
    if (serverCommand != null) 'server_command': serverCommand,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  /// Writes the marker into [directory].
  ///
  /// Through a temp file and a rename: a half-written marker reads as
  /// "unowned", which is the one direction that loses a live sibling's VM.
  Future<void> writeTo(String directory) async {
    final target = File(p.join(directory, fileName));
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
      flush: true,
    );
    await temp.rename(target.path);
  }

  /// Reads the marker in [directory], or null when there is none.
  ///
  /// An absent or unparseable marker reads as unowned — the same state every
  /// directory written before this file existed is in.
  static RigRuntimeOwner? readSync(String directory) {
    final file = File(p.join(directory, fileName));
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return RigRuntimeOwner.fromJson(decoded);
    } on Object {
      return null;
    }
  }
}

/// What became of a process the lifecycle paths tried to reap.
enum _ReapOutcome {
  /// No live process matching this rig held that pid.
  absent,

  /// It was alive, it matched, and it is gone now.
  killed,

  /// It was alive, it matched, and it ignored SIGKILL.
  survived,
}

/// A booted QEMU machine and everything needed to drive it.
class QemuMachine implements RigMachine {
  /// Creates a [QemuMachine].
  QemuMachine({
    required this.rigId,
    required this.process,
    required this.qmp,
    required this.agent,
    required this.backend,
    required this.sshPort,
    required this.agentPort,
    required this.overlayPath,
    required this.runtimeDir,
    required this.socketDir,
    required this.guestSecret,
    required this.display,
    this.httpProxy,
    this.socksProxy,
  });

  /// The rig this machine serves.
  @override
  final String rigId;

  /// The QEMU process.
  @override
  final Process process;

  /// Its QMP control space.
  final QmpClient qmp;

  /// The in-guest agent.
  final GuestAgentClient agent;

  /// Which accelerator it booted with.
  final EnclosureBackend backend;

  /// Host loopback port forwarded to the guest's SSH port.
  final int sshPort;

  /// Host loopback port forwarded to the guest agent.
  final int agentPort;

  /// The per-session overlay, deleted on teardown.
  final String overlayPath;

  /// Per-rig scratch directory (seed image, key, overlay).
  final String runtimeDir;

  /// Per-rig control-socket directory, held OUTSIDE [runtimeDir] because a
  /// unix socket path is length-capped. Removed with the machine.
  final String socketDir;

  /// The per-VM secret the guest presents to the credential broker.
  @override
  final String guestSecret;

  /// This rig's OWN egress HTTP proxy, closed with the machine.
  ///
  /// Per-rig rather than shared: the shared sandbox proxies filter with ONE
  /// mutable config that every `wrap()` overwrites, so a long-lived VM behind
  /// them would inherit whatever policy the most recent terminal spawn set —
  /// and its own `egressAllowlist` would be decoration. A dedicated listener
  /// per machine is what makes the spec's allowlist the policy that is
  /// actually enforced.
  final SandboxHttpProxy? httpProxy;

  /// This rig's own egress SOCKS proxy. Same reasoning as [httpProxy].
  final SandboxSocksProxy? socksProxy;

  /// The guest's current display mode.
  @override
  RigDisplaySize display;

  /// Whether the guest is parked (vCPUs stopped).
  @override
  bool parked = false;

  /// The private key path for SSH into this guest.
  String get privateKeyPath => p.join(runtimeDir, 'id_ed25519');
}

/// Boots and tears down QEMU-backed rigs.
///
/// Owns the process, the overlay and the control spaces. It deliberately
/// does NOT own policy: what a rig may reach, who may drive it and how long it
/// lives are decided above and handed down, so this class stays a mechanism.
class QemuEnclosureBackend {
  /// Creates a [QemuEnclosureBackend].
  ///
  /// [processProbe], [socketRoots] and [ladder] are seams: production uses the
  /// defaults, tests substitute fakes so the paths that decide whether to kill
  /// a pid or delete a directory can be exercised without a hypervisor.
  QemuEnclosureBackend({
    required String dataDir,
    required RigImageStore images,
    this.credentialPort,
    RigProcessProbe? processProbe,
    List<String>? socketRoots,
    RigTeardownLadder ladder = const RigTeardownLadder(),
  }) : _runtimeRoot = p.join(dataDir, 'rigs', 'run'),
       _images = images,
       _processes = processProbe ?? const SystemRigProcessProbe(),
       _socketRoots =
           socketRoots ?? defaultRigSocketRoots(Platform.environment),
       _ladder = ladder;

  final String _runtimeRoot;
  final RigImageStore _images;
  final RigProcessProbe _processes;
  final List<String> _socketRoots;
  final RigTeardownLadder _ladder;
  final Random _random = Random.secure();

  /// Host port of the credential-broker endpoint.
  ///
  /// The broker stays SHARED across rigs (unlike the egress proxies): every
  /// request carries the per-rig secret, so the endpoint itself does not need
  /// to know which machine is calling to enforce per-rig policy.
  int? credentialPort;

  RigBackendCapabilities? _cachedProbe;
  String? _firmwarePath;

  /// What QEMU can do on this host.
  ///
  /// Cheap by contract — a PATH lookup, a `-version` run and a few `stat`s —
  /// because settings calls it on open and boot calls it before every launch.
  /// Cached after the first success: a hypervisor does not get installed
  /// halfway through a session, and re-running it per launch would put a
  /// process spawn on the path of every rig.
  Future<RigBackendCapabilities> probe({bool refresh = false}) async {
    final cached = _cachedProbe;
    if (cached != null && !refresh) {
      return cached;
    }
    final result = await _probeUncached();
    if (result.available || refresh) {
      _cachedProbe = result;
    }
    return result;
  }

  Future<RigBackendCapabilities> _probeUncached() async {
    final architecture = _hostArchitecture();
    final binary = qemuBinaryFor(architecture);
    final resolved = await _which(binary);
    if (resolved == null) {
      return RigBackendCapabilities.unavailable(
        _preferredBackend(),
        note: 'QEMU is not installed, so enclosed VMs are unavailable.',
        requiresInstall: true,
        installHint: Platform.isMacOS
            ? 'brew install qemu'
            : Platform.isLinux
            ? 'sudo apt-get install qemu-system'
            : 'Install QEMU and make $binary available on PATH',
      );
    }

    String? version;
    try {
      final result = await Process.run(resolved, ['-version']);
      final line = '${result.stdout}'.split('\n').first.trim();
      if (line.isNotEmpty) {
        version = line;
      }
    } on Object {
      // A binary that will not report its version is still worth trying; the
      // launch will produce a better error than the probe could.
    }

    // aarch64 boots nothing without its UEFI firmware — not an error, just a
    // vCPU spinning on empty memory until the readiness probe times out. So a
    // missing firmware file is a probe failure with the fix named, never a
    // two-minute mystery at launch.
    final firmwareFile = qemuFirmwareFileFor(architecture);
    if (firmwareFile != null) {
      _firmwarePath = await _locateFirmware(resolved, firmwareFile);
      if (_firmwarePath == null) {
        return RigBackendCapabilities.unavailable(
          _preferredBackend(),
          note:
              'QEMU is installed but its UEFI firmware ($firmwareFile) was '
              'not found in any of its data directories, and an aarch64 '
              'guest cannot boot without it.',
          requiresInstall: true,
          installHint: Platform.isMacOS
              ? 'brew reinstall qemu'
              : 'Reinstall QEMU (the firmware ships with it)',
        );
      }
    }

    final backend = await _detectAccelerator(resolved);
    // A surface is only offered when its image is actually on disk. Offering
    // one and failing at boot with "image missing" is the same information
    // three minutes later and after a wasted VM start.
    final surfaces = <RigSurface>{
      for (final surface in RigSurface.values)
        if (surface != RigSurface.mobile)
          if (_images.defaultFor(surface) case final spec?)
            if (_images.isPresent(spec)) surface,
    };
    final missing = <String>[
      for (final surface in RigSurface.values)
        if (surface != RigSurface.mobile) ..._images.missingFor(surface),
    ];

    return RigBackendCapabilities(
      backend: backend,
      available: true,
      surfaces: surfaces,
      // Terminals moved to the smolvm backend: a headless shell needs no
      // display device, and the microVM boots it in a fraction of the time.
      supportsTerminals: false,
      note: backend.isAccelerated
          ? 'QEMU with ${backend == EnclosureBackend.qemuHvf ? 'Hypervisor.framework' : 'KVM'} — a real kernel boundary.'
          : 'QEMU without hardware acceleration — correct but roughly 10x '
                'slower. Expect a rig to feel sluggish.',
      missingImages: missing,
      version: version,
    );
  }

  /// Boots a rig for [spec] and returns the machine once its guest agent
  /// answers.
  ///
  /// [onProgress] reports each boot step verbatim to the UI, because a
  /// two-minute silent wait and a hang are indistinguishable to the person
  /// looking at the panel.
  Future<QemuMachine> launch({
    required String rigId,
    required RigSpec spec,
    void Function(String step)? onProgress,
  }) async {
    final probeResult = await probe();
    if (!probeResult.available) {
      throw RigLaunchException(
        probeResult.note ?? 'No enclosure backend is available on this host.',
      );
    }
    final image = spec.imageId != null
        ? _images.byId(spec.imageId!)
        : _images.defaultFor(spec.surface);
    if (image == null) {
      throw RigLaunchException(
        spec.imageId != null
            ? 'No base image "${spec.imageId}" is catalogued.'
            : 'No base image is catalogued for the ${spec.surface.label} '
                  'surface.',
      );
    }
    if (!_images.isPresent(image)) {
      throw RigLaunchException(
        'The base image "${image.id}" has not been downloaded yet. '
        'Download it in Settings → Rigs before opening this surface.',
      );
    }

    onProgress?.call('Creating the disk overlay');
    final runtimeDir = Directory(p.join(_runtimeRoot, rigId));
    await runtimeDir.create(recursive: true);
    final overlayPath = p.join(runtimeDir.path, 'overlay.qcow2');
    final String guestSecret;
    final String agentToken;
    final String? seedPath;
    try {
      // The directory is about to hold the per-VM private key and the seed
      // image (broker secret, agent token). The files themselves are 0600, but
      // a 0700 directory means a permission slip on any future file in here is
      // not immediately world-readable.
      await _chmod('700', runtimeDir.path);
      // Claimed BEFORE anything expensive lands in it: a sibling server
      // sweeping between the mkdir and the first byte of a multi-gigabyte
      // overlay would otherwise see an unowned directory and delete this
      // launch out from under itself.
      await _claim(runtimeDir.path, rigId: rigId, required: true);
      await _createOverlay(
        basePath: _images.diskPathFor(image),
        overlayPath: overlayPath,
      );

      onProgress?.call('Minting the per-VM key');
      guestSecret = _randomToken();
      agentToken = _randomToken();
      seedPath = await _writeSeed(
        runtimeDir: runtimeDir.path,
        rigId: rigId,
        guestSecret: guestSecret,
        agentToken: agentToken,
        egressAllowlist: spec.egressAllowlist,
      );
    } on Object {
      // A missing `qemu-img`, a corrupt base image, a full disk or a failed
      // `ssh-keygen` all land here. Without this the directory survives — with
      // a possibly multi-gigabyte overlay AND the minted private key in it —
      // until the next server start sweeps it.
      await _cleanupRuntime(runtimeDir.path);
      rethrow;
    }

    final sshPort = await _freePort();
    final agentPort = await _freePort();

    // This rig's OWN egress proxies, filtering with ITS allowlist for its
    // whole lifetime. The shared sandbox proxies hold one mutable config that
    // every terminal spawn overwrites — behind those, a VM's effective egress
    // policy would be whatever the most recent unrelated spawn set, and an
    // empty allowlist here would mean "whatever they allow" instead of the
    // deny-by-default floor the spec promises.
    final egress = NetworkConfig(
      allowAll: false,
      allowedDomains: spec.egressAllowlist,
      // Cloud metadata endpoints and telemetry sinks stay denied even when an
      // allowlist entry would match them — denies win in the matcher.
      deniedDomains: kBaselineDeniedDomains,
    );
    // Configured AT START, not a few statements later. The listeners were
    // previously open for the gap in between — unreachable in practice (there
    // is no guest yet), but "deny by default" should not be a property of
    // statement order.
    final httpProxy = await SandboxHttpProxy.start(network: egress);
    final socksProxy = await SandboxSocksProxy.start(network: egress);
    Future<void> closeProxies() async {
      await httpProxy.close();
      await socksProxy.close();
    }

    // ── One rollback for the whole launch tail ──────────────────────────────
    //
    // Everything from here on can throw, and several steps had no handler at
    // all: `buildRigSocketPath` throws a StateError when no candidate root
    // fits `sun_path`, `_which(...)!` null-asserts, and `Process.start` throws
    // on a binary that vanished between the probe and the launch. Each of
    // those left the 0700 runtime directory behind — with the MINTED PRIVATE
    // KEY and the seed image in it — plus two listening proxies, and because
    // the directory was already `_claim`ed the orphan sweep deliberately skips
    // it. It survived until the next server restart.
    //
    // So the tail is one guarded region with one rollback, rather than a
    // handler per step that the next step forgets to add.
    String? socketDir;
    Process? process;
    QmpClient? qmp;
    GuestAgentClient? agent;
    try {
      final qmpSocketPath = buildRigSocketPath(
        candidateRoots: _socketRoots,
        rigId: rigId,
      );
      socketDir = p.dirname(qmpSocketPath);
      // The namespace directory may land in a shared /tmp, where anyone can
      // create entries. A symlink planted at `ccrig` would silently redirect
      // this VM's control socket somewhere the attacker can reach, so refuse
      // it rather than following it.
      final socketNamespace = Link(p.dirname(socketDir));
      if (socketNamespace.existsSync()) {
        throw RigLaunchException(
          'Refusing to use ${socketNamespace.path}: it is a symlink, not a '
          'directory. Remove it and retry.',
        );
      }
      await Directory(socketDir).create(recursive: true);
      // The QMP socket can stop the VM, inject input and read its state, so
      // the directory must not be traversable by other users on a shared /tmp.
      await _chmod('700', socketDir);
      // The socket namespace is the one place two servers are GUARANTEED to
      // collide (a shared /tmp), so it carries the same ownership marker the
      // runtime directory does.
      await _claim(socketDir, rigId: rigId, required: true);
      final architecture = _hostArchitecture();

      final plan = QemuLaunchPlan(
        rigId: rigId,
        backend: probeResult.backend,
        overlayPath: overlayPath,
        memoryMb: spec.memoryMb,
        cpuCount: spec.cpuCount,
        display: spec.display,
        qmpSocketPath: qmpSocketPath,
        sshHostPort: sshPort,
        agentHostPort: agentPort,
        surface: spec.surface,
        httpProxyHostPort: httpProxy.port,
        socksProxyHostPort: socksProxy.port,
        credentialHostPort: credentialPort,
        seedImagePath: seedPath,
        machineType: qemuMachineFor(architecture),
        firmwarePath: _firmwarePath,
      );

      onProgress?.call('Starting the machine');
      // Re-resolved rather than null-asserted: the probe that found this
      // binary may be minutes old, and a `!` on a PATH lookup turns "QEMU was
      // uninstalled since" into a TypeError with nothing behind it.
      final binary = await _which(qemuBinaryFor(architecture));
      if (binary == null) {
        throw RigLaunchException(
          'QEMU (${qemuBinaryFor(architecture)}) is no longer on PATH. It was '
          'present when this host was probed, so it has been moved or '
          'uninstalled since.',
        );
      }
      final argv = buildQemuArgv(plan);
      CcInfraLog.info('rig/$rigId: $binary ${argv.join(' ')}');
      process = await Process.start(
        binary,
        argv,
        workingDirectory: runtimeDir.path,
      );
      // Record the hypervisor's pid in both markers. This is what lets a later
      // sweep KILL an orphaned QEMU before removing the overlay it is running
      // on, instead of deleting the state under a process that keeps going.
      await _claim(runtimeDir.path, rigId: rigId, qemuPid: process.pid);
      await _claim(socketDir, rigId: rigId, qemuPid: process.pid);
      // The guest's serial console. Kept in the server log so a kernel panic is
      // a readable line rather than a boot that silently never finishes.
      unawaited(
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) => CcInfraLog.debug('rig/$rigId guest: $line')),
      );
      // A BOUNDED tail, not an unbounded buffer. This is only ever read inside
      // the 3s startup window below, but the subscription lives for the whole
      // life of the machine — an hours-long rig that chatters on stderr would
      // otherwise accumulate every line of it for nobody.
      final stderrTail = Queue<String>();
      unawaited(
        process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
              stderrTail.add(line);
              if (stderrTail.length > _qemuStderrTailLines) {
                stderrTail.removeFirst();
              }
              CcInfraLog.warning('rig/$rigId qemu: $line');
            }),
      );

      // A QEMU that rejects its own command line exits in milliseconds.
      // Catching that here turns "the guest agent never answered after 120s"
      // into the actual flag error, which is the difference between a
      // two-minute mystery and a one-line fix.
      //
      // The sentinel is a NULL, not `-1`. POSIX completes `exitCode` with the
      // NEGATED SIGNAL for a signalled process, so `exitCode >= 0` read a
      // SIGSEGV or SIGABRT at startup as "still running": the launch then
      // waited the full 15 s for a QMP socket that would never appear and
      // reported "QMP socket never appeared: null", throwing away the crash
      // stderr it had already collected. `-1` also collides with SIGHUP.
      final exitCode = await process.exitCode
          .then<int?>((code) => code)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (exitCode != null) {
        throw RigLaunchException(
          exitCode < 0
              ? 'QEMU was killed by signal ${-exitCode} before it started:\n'
                    '${stderrTail.join('\n').trim()}'
              : 'QEMU exited immediately (code $exitCode):\n'
                    '${stderrTail.join('\n').trim()}',
        );
      }

      onProgress?.call('Connecting the control channel');
      try {
        qmp = await _connectQmp(qmpSocketPath);
      } on Object catch (e) {
        throw RigLaunchException('Could not reach the QEMU control socket: $e');
      }

      agent = GuestAgentClient(port: agentPort, token: agentToken);
      final display = await agent.awaitReady(onProgress: onProgress);

      onProgress?.call('Ready');
      return QemuMachine(
        rigId: rigId,
        process: process,
        qmp: qmp,
        agent: agent,
        backend: probeResult.backend,
        sshPort: sshPort,
        agentPort: agentPort,
        overlayPath: overlayPath,
        runtimeDir: runtimeDir.path,
        socketDir: socketDir,
        guestSecret: guestSecret,
        display: display,
        httpProxy: httpProxy,
        socksProxy: socksProxy,
      );
    } on Object {
      // Roll back EVERYTHING the tail created, and do not let a failing step
      // skip the ones after it — teardown is the one place where "best effort"
      // means "keep going", because the alternative is a leaked hypervisor,
      // two listening proxies, and a minted private key left on disk inside a
      // directory the orphan sweep deliberately skips (it is `_claim`ed, so it
      // reads as live).
      try {
        await qmp?.close();
      } on Object catch (e) {
        CcInfraLog.debug('rig/$rigId: QMP close during rollback failed ($e)');
      }
      process?.kill(ProcessSignal.sigkill);
      agent?.close();
      try {
        await closeProxies();
      } on Object catch (e) {
        CcInfraLog.warning(
          'rig/$rigId: proxy close during rollback failed ($e)',
        );
      }
      await _cleanupRuntime(runtimeDir.path, socketDir: socketDir);
      rethrow;
    }
  }

  /// Stops [machine] and discards its overlay.
  ///
  /// Asks politely, then kills. A rig is disposable by construction, so a
  /// guest that ignores ACPI does not get to keep the host's memory: the
  /// SIGKILL is the contract, not a failure mode.
  ///
  /// Every escalation is INDEPENDENT. Nesting them meant one throwing step
  /// skipped the ones after it — a QMP client that threw on `quit` for its own
  /// reasons took the SIGKILL with it and left the hypervisor running — so
  /// each rung stands alone and the kill is unconditional while the process
  /// still lives. The same goes for the closes and the deletes below: teardown
  /// is idempotent and must never throw out of here, because the caller's only
  /// alternative to finishing is leaking a VM.
  Future<void> destroy(QemuMachine machine) async {
    final rigId = machine.rigId;
    var dead = false;

    // 1. ACPI powerdown: the guest gets to flush and unmount.
    try {
      await machine.qmp.systemPowerdown();
      await machine.process.exitCode.timeout(_ladder.powerdown);
      dead = true;
    } on Object catch (e) {
      CcInfraLog.debug('rig/$rigId: ACPI powerdown did not finish it ($e)');
    }

    // 2. QMP quit: the hypervisor exits, the guest does not get a say.
    if (!dead) {
      try {
        await machine.qmp.quit();
        await machine.process.exitCode.timeout(_ladder.quit);
        dead = true;
      } on Object catch (e) {
        CcInfraLog.debug('rig/$rigId: QMP quit did not finish it ($e)');
      }
    }

    // 3. SIGKILL. Unconditional while the process is still alive — this rung
    // is the contract.
    if (!dead) {
      try {
        machine.process.kill(ProcessSignal.sigkill);
        await machine.process.exitCode.timeout(_ladder.kill);
        dead = true;
      } on Object catch (e) {
        CcInfraLog.warning(
          'rig/$rigId: SIGKILL did not settle the process ($e)',
        );
      }
    }

    // 4. The pathological case: the tracked handle is unusable (a kill that
    // reported no such process, an exit code that never arrives) but the
    // pidfile still names a live QEMU. An orphaned hypervisor outlives the
    // server, holds gigabytes and answers to nobody, so verify-then-kill by
    // pid — the same primitive the sweep uses.
    if (!dead) {
      try {
        dead = await _reapRecordedQemu(machine);
      } on Object catch (e) {
        CcInfraLog.warning('rig/$rigId: could not reap the recorded pid ($e)');
      }
    }

    await _quietly(machine.qmp.close, 'rig/$rigId: QMP close');
    await _quietly(
      () async => machine.agent.close(),
      'rig/$rigId: agent close',
    );
    // The rig's own egress listeners die with it. Leaving one open would be a
    // loopback port whose allowlist names a machine that no longer exists.
    await _quietly(
      () async => machine.httpProxy?.close(),
      'rig/$rigId: HTTP proxy close',
    );
    await _quietly(
      () async => machine.socksProxy?.close(),
      'rig/$rigId: SOCKS proxy close',
    );

    if (!dead) {
      // Deleting the overlay under a running hypervisor is precisely the
      // hazard the sweep was fixed for. Leave the directory: the next boot's
      // sweep kills first and deletes second.
      CcInfraLog.warning(
        'rig/$rigId: the hypervisor is still alive after the full teardown '
        'ladder — leaving ${machine.runtimeDir} in place rather than removing '
        'the state a running VM is using. The next boot sweep will kill it '
        'first.',
      );
      return;
    }
    await _cleanupRuntime(machine.runtimeDir, socketDir: machine.socketDir);
  }

  /// Runs [action], logging rather than propagating anything it throws.
  ///
  /// Teardown steps are independent by design: a space that will not close
  /// must not stop the next one, and none of them may take the whole teardown
  /// down with them.
  static Future<void> _quietly(
    Future<void> Function() action,
    String what,
  ) async {
    try {
      await action();
    } on Object catch (e) {
      CcInfraLog.warning('$what failed: $e');
    }
  }

  /// Kills whatever live QEMU the markers still name for [machine].
  ///
  /// True when nothing matching is left running (either it was never there or
  /// it is gone now).
  Future<bool> _reapRecordedQemu(QemuMachine machine) async {
    final pids = <int>{};
    final owner = RigRuntimeOwner.readSync(machine.runtimeDir);
    if (owner?.qemuPid case final recorded?) {
      pids.add(recorded);
    }
    try {
      pids.add(machine.process.pid);
    } on Object {
      // A handle that will not even report its pid is exactly why the marker
      // exists.
    }
    var clean = true;
    for (final pid in pids) {
      final outcome = await _terminateVerifiedQemu(pid, rigId: machine.rigId);
      if (outcome == _ReapOutcome.survived) {
        clean = false;
      }
    }
    return clean;
  }

  /// Parks [machine]: vCPUs stopped, memory still resident.
  Future<void> park(QemuMachine machine) async {
    if (machine.parked) {
      return;
    }
    await machine.qmp.stop();
    machine.parked = true;
  }

  /// Wakes a parked [machine].
  Future<void> wake(QemuMachine machine) async {
    if (!machine.parked) {
      return;
    }
    await machine.qmp.cont();
    machine.parked = false;
  }

  Future<QmpClient> _connectQmp(String socketPath) async {
    // QEMU creates the socket a moment after the process starts.
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      if (File(socketPath).existsSync()) {
        try {
          return await QmpClient.connect(socketPath);
        } on Object catch (e) {
          lastError = e;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    throw RigLaunchException('QMP socket never appeared: $lastError');
  }

  Future<void> _createOverlay({
    required String basePath,
    required String overlayPath,
  }) async {
    final qemuImg = await _which('qemu-img');
    if (qemuImg == null) {
      throw const RigLaunchException(
        'qemu-img is not installed; it ships with QEMU and is required to '
        'create a per-session disk overlay.',
      );
    }
    await runHostTool(
      'qemu-img',
      // The base image is the BACKING file, so it is opened read-only and one
      // rig cannot change what the next one boots from. Everything a rig
      // writes lands in the overlay and dies with it. Built by a pure
      // function so `qemu_argv_test.dart` can pin that.
      buildQemuOverlayArgs(basePath: basePath, overlayPath: overlayPath),
      executable: qemuImg,
      hint:
          'The per-session overlay is what keeps a rig from writing to the '
          'base image at $basePath.',
    );
  }

  /// Writes the per-VM seed image the guest reads at boot.
  ///
  /// Carries the SSH public key, the guest-agent token, the credential-broker
  /// secret and the egress allowlist. It is a fresh FAT image per rig and is
  /// deleted with the runtime directory, so nothing here outlives the machine.
  Future<String?> _writeSeed({
    required String runtimeDir,
    required String rigId,
    required String guestSecret,
    required String agentToken,
    required List<String> egressAllowlist,
  }) async {
    final keyPath = p.join(runtimeDir, 'id_ed25519');
    final keygen = await _which('ssh-keygen');
    if (keygen == null) {
      throw const RigLaunchException(
        'ssh-keygen is not available; it is needed to mint the per-VM key '
        'that reaches the guest shell.',
      );
    }
    await runHostTool(
      'ssh-keygen',
      ['-t', 'ed25519', '-N', '', '-C', 'cc-rig-$rigId', '-f', keyPath],
      executable: keygen,
      hint: 'Without the per-VM key nothing can reach the guest shell.',
    );
    // The private key must not be readable by other users on the host: it is
    // a shell on the rig, and the rig can reach the credential broker.
    await _chmod('600', keyPath);
    final publicKey = await File('$keyPath.pub').readAsString();

    final seedDir = Directory(p.join(runtimeDir, 'seed'));
    await seedDir.create(recursive: true);
    final seedJson = File(p.join(seedDir.path, 'cc-rig.json'));
    await seedJson.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'rig_id': rigId,
        'authorized_key': publicKey.trim(),
        'agent_token': agentToken,
        'credential_secret': guestSecret,
        'egress_allowlist': egressAllowlist,
        'http_proxy':
            'http://${QemuGuestAddresses.httpProxy}:'
            '${QemuGuestAddresses.httpProxyPort}',
        'socks_proxy':
            'socks5://${QemuGuestAddresses.socksProxy}:'
            '${QemuGuestAddresses.socksProxyPort}',
        'credential_endpoint':
            'http://${QemuGuestAddresses.credentialBroker}:'
            '${QemuGuestAddresses.credentialBrokerPort}/credential',
      }),
    );
    // Same reasoning as the private key above: this file holds the
    // credential-broker secret and the agent token in plaintext, and that
    // secret is the ONLY thing gating the broker. At the default umask any
    // other local user could read it and mint against the broker.
    await _chmod('600', seedJson.path);

    final seedImage = await _buildSeedImage(
      seedDir: seedDir.path,
      runtimeDir: runtimeDir,
      rigId: rigId,
    );
    // The image now carries the same secrets the JSON does.
    await _chmod('600', seedImage);
    return seedImage;
  }

  /// Writes [sourceDir] as an ISO9660 image at [output], labelled [label].
  ///
  /// The label is load-bearing on both sides: cloud-init's NoCloud datasource
  /// looks for `cidata`, and our own boot script greps blkid for `CCRIG`. An
  /// image with the right contents under the wrong label is silently ignored
  /// by the guest, which then boots looking perfectly healthy and configured
  /// with nothing.
  /// Returns whether the image was built, and why every attempt that ran
  /// failed. The failures are carried out rather than only logged: when no
  /// builder works, "no usable ISO builder on this host" is a much worse
  /// message than the four lines saying what each one actually said.
  Future<({bool built, List<String> failures})> _makeIso(
    String sourceDir,
    String label,
    String output,
  ) async {
    final failures = <String>[];

    Future<bool> attempt(String tool, String binary, List<String> args) async {
      // A previous attempt may have left a truncated file behind, and an
      // `exitCode == 0 && exists` check would then read it as success.
      final stale = File(output);
      if (stale.existsSync()) {
        try {
          await stale.delete();
        } on Object catch (e) {
          failures.add('$tool: could not clear a stale $output: $e');
          return false;
        }
      }
      ProcessResult result;
      try {
        result = await Process.run(binary, args);
      } on Object catch (e) {
        failures.add('$tool: could not be run: $e');
        return false;
      }
      if (result.exitCode == 0 && File(output).existsSync()) {
        return true;
      }
      final detail = result.exitCode == 0
          ? 'exited 0 but wrote no image at $output'
          : 'exit ${result.exitCode}: ${'${result.stderr}'.trim()}';
      failures.add('$tool: $detail');
      CcInfraLog.warning('rig: $tool could not build $label — $detail');
      return false;
    }

    final hdiutil = await _which('hdiutil');
    if (hdiutil != null) {
      final ok = await attempt('hdiutil', hdiutil, [
        'makehybrid',
        '-o',
        output,
        '-iso',
        '-joliet',
        '-default-volume-name',
        label,
        '-iso-volume-name',
        label,
        '-joliet-volume-name',
        label,
        sourceDir,
      ]);
      if (ok) {
        return (built: true, failures: failures);
      }
    }
    for (final tool in const ['genisoimage', 'mkisofs', 'xorriso']) {
      final binary = await _which(tool);
      if (binary == null) {
        failures.add('$tool: not installed');
        continue;
      }
      final base = [
        '-output',
        output,
        '-volid',
        label,
        '-joliet',
        '-rock',
        sourceDir,
      ];
      final ok = await attempt(
        tool,
        binary,
        tool == 'xorriso' ? ['-as', 'mkisofs', ...base] : base,
      );
      if (ok) {
        return (built: true, failures: failures);
      }
    }
    return (built: false, failures: failures);
  }

  /// Builds the small removable image the guest reads its per-VM secrets from.
  ///
  /// The guest finds it by LABEL and mounts it with the filesystem
  /// auto-detected, so ISO9660 and FAT are equally good — which matters
  /// because the FAT path needs `dosfstools` AND `mtools`, and macOS ships
  /// neither. Building only FAT meant every rig on a Mac booted with no key,
  /// no agent token and no broker secret.
  ///
  /// Never returns a seedless or empty image. A rig without its seed has no
  /// shell, no guest agent and no credential broker — it is not a degraded
  /// rig, it is a VM that cannot do the one job it was booted for, and it
  /// looks identical to a healthy one until the first operation fails.
  Future<String> _buildSeedImage({
    required String seedDir,
    required String runtimeDir,
    required String rigId,
  }) async {
    final jsonPath = p.join(seedDir, 'cc-rig.json');

    // ISO9660 first: some builder for it exists on every supported host.
    final isoPath = p.join(runtimeDir, 'seed.iso');
    final iso = await _makeIso(seedDir, 'CCRIG', isoPath);
    if (iso.built) {
      return isoPath;
    }
    final failures = [...iso.failures];

    // FAT fallback. Both halves are required: mkfs alone yields an image the
    // guest mounts successfully and finds nothing in, which is the same
    // keyless VM wearing a healthy-looking seed.
    final mkfs = await _which('mkfs.vfat') ?? await _which('mkfs.fat');
    final mcopy = await _which('mcopy');
    if (mkfs == null || mcopy == null) {
      failures.add(
        'FAT fallback: needs BOTH mkfs.vfat/mkfs.fat and mcopy '
        '(mkfs ${mkfs == null ? 'missing' : 'found'}, '
        'mcopy ${mcopy == null ? 'missing' : 'found'})',
      );
    } else {
      final imagePath = p.join(runtimeDir, 'seed.img');
      try {
        await runHostTool('mkfs.vfat', [
          '-C',
          imagePath,
          '1440',
          '-n',
          'CCRIG',
        ], executable: mkfs);
        await runHostTool(
          'mcopy',
          ['-i', imagePath, jsonPath, '::cc-rig.json'],
          executable: mcopy,
          hint:
              'An image the guest mounts and finds nothing in is the same '
              'keyless VM wearing a healthy-looking seed.',
        );
        return imagePath;
      } on RigToolException catch (e) {
        failures.add(e.message);
        CcInfraLog.warning('rig/$rigId: ${e.message}');
      }
    }

    throw RigToolException(
      tool: 'seed image builder',
      stderr: failures.join('\n'),
      hint:
          'Could not build the rig seed image. Install one of hdiutil (macOS), '
          'genisoimage/mkisofs/xorriso, or dosfstools + mtools. Without a seed '
          'the guest has no key, no agent token and no credential broker '
          'secret.',
    );
  }

  Future<void> _cleanupRuntime(String runtimeDir, {String? socketDir}) async {
    // The socket directory sits outside the runtime directory (a unix socket
    // path is length-capped), so removing the runtime tree does not reach it.
    // Independently, because a socket directory that will not go must not keep
    // a multi-gigabyte overlay on disk.
    for (final path in [runtimeDir, ?socketDir]) {
      await _deleteRigDirectory(path);
    }
  }

  /// Every directory tree this backend is allowed to delete from.
  ///
  /// `/tmp` is always in the list because [buildRigSocketPath] falls back to it
  /// when every configured root would overflow `sun_path`, so a socket
  /// directory can legitimately be there even when no root named it.
  List<String> get _deletableRoots => [
    _runtimeRoot,
    for (final root in {..._socketRoots, '/tmp'})
      if (root.isNotEmpty) p.join(root, 'ccrig'),
  ];

  /// Whether [path] is a directory this backend may recursively delete.
  ///
  /// The guard exists because the only thing between `deleteSync(recursive:
  /// true)` and an operator's data directory is which string got passed. A
  /// delete is permitted strictly INSIDE the rig runtime root or a `ccrig`
  /// socket namespace — never a root itself, and never anything under the
  /// image store, which holds multi-gigabyte artifacts nobody re-downloads by
  /// accident.
  bool isRigDeletablePath(String path) {
    if (path.trim().isEmpty) {
      return false;
    }
    final target = p.canonicalize(path);
    final images = p.canonicalize(_images.root);
    if (target == images || p.isWithin(images, target)) {
      return false;
    }
    for (final root in _deletableRoots) {
      if (p.isWithin(p.canonicalize(root), target)) {
        return true;
      }
    }
    return false;
  }

  /// Recursively deletes [path] once it is proven to be a rig directory.
  ///
  /// True when something was removed. Never throws: both callers (teardown and
  /// the boot sweep) must continue past a directory they cannot delete.
  Future<bool> _deleteRigDirectory(String path) async {
    if (!isRigDeletablePath(path)) {
      CcInfraLog.warning(
        'rig: REFUSING to delete $path — it is not inside the rig runtime root '
        '($_runtimeRoot) or a ccrig socket namespace. This is a bug in whoever '
        'built that path.',
      );
      return false;
    }
    final dir = Directory(path);
    if (!dir.existsSync()) {
      return false;
    }
    try {
      await dir.delete(recursive: true);
      return true;
    } on Object catch (e) {
      CcInfraLog.warning('rig: could not remove $path: $e');
      return false;
    }
  }

  /// Removes runtime directories left behind by a previous process.
  ///
  /// A server that was killed leaves overlays and sockets on disk. Nothing
  /// references them (the sessions are marked failed on the next boot), and an
  /// overlay is easily a gigabyte, so an unswept directory is a slow disk leak.
  ///
  /// It used to delete every directory it could see, which made it unsafe in
  /// the two situations it runs in most: two servers sharing a data dir (or a
  /// `TMPDIR`) wiped each other's LIVE overlays and control sockets, and a
  /// directory was removed without killing the QEMU running on it, leaving a
  /// hypervisor with no state and no owner. So a candidate is now swept only
  /// when its marker says nobody live owns it, and any QEMU it still names is
  /// killed FIRST.
  Future<int> sweepOrphanedRuntimes() async {
    var removed = await _sweepNamespace(_runtimeRoot);
    // Socket directories live outside the runtime root, so the walk above
    // cannot see them. A stale one is tiny, but it is also a stale control
    // socket sitting in a shared /tmp, which is the part worth clearing.
    removed += await _sweepOrphanedSocketDirs();

    if (removed > 0) {
      CcInfraLog.info('rig: swept $removed orphaned runtime director(ies)');
    }
    return removed;
  }

  /// Removes control-socket directories left behind by a previous process.
  Future<int> _sweepOrphanedSocketDirs() async {
    // Derive the same roots the launcher used, so a sweep after a restart
    // looks where the sockets were actually written.
    var removed = 0;
    final seen = <String>{};
    for (final root in _deletableRoots) {
      if (root == _runtimeRoot || !seen.add(root)) {
        continue;
      }
      removed += await _sweepNamespace(root, isSocketNamespace: true);
    }
    return removed;
  }

  /// Sweeps one namespace directory, one candidate at a time.
  ///
  /// A failure on any single candidate is logged and stepped over: one
  /// undeletable directory must not stop the sweep from reclaiming the rest,
  /// and this runs on every boot.
  Future<int> _sweepNamespace(
    String rootPath, {
    bool isSocketNamespace = false,
  }) async {
    if (isSocketNamespace && Link(rootPath).existsSync()) {
      // Same refusal the launcher makes: a symlink planted at the `ccrig`
      // namespace in a shared /tmp would redirect a recursive delete wherever
      // the planter chose.
      CcInfraLog.warning(
        'rig: refusing to sweep $rootPath — it is a symlink, not a directory.',
      );
      return 0;
    }
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      return 0;
    }
    List<FileSystemEntity> entries;
    try {
      // followLinks: false so a symlink is reported as a Link and skipped
      // rather than resolved into a Directory we would then delete through.
      entries = await root.list(followLinks: false).toList();
    } on Object catch (e) {
      CcInfraLog.warning('rig: could not enumerate $rootPath: $e');
      return 0;
    }
    var removed = 0;
    for (final entity in entries) {
      if (entity is Link) {
        CcInfraLog.warning(
          'rig: skipping ${entity.path} — it is a symlink, not a rig '
          'directory, and a recursive delete must never follow one.',
        );
        continue;
      }
      if (entity is! Directory) {
        continue;
      }
      try {
        if (await _sweepOne(entity.path)) {
          removed++;
        }
      } on Object catch (e) {
        // Includes a process probe that could not answer: unknown is not a
        // licence to delete, so the directory simply survives this pass.
        CcInfraLog.warning('rig: could not sweep ${entity.path}: $e');
      }
    }
    return removed;
  }

  /// Decides one candidate directory's fate. True when it was removed.
  Future<bool> _sweepOne(String dirPath) async {
    final owner = RigRuntimeOwner.readSync(dirPath);
    final rigId = owner?.rigId.isNotEmpty ?? false
        ? owner!.rigId
        : p.basename(dirPath);

    if (owner != null && await _isLiveOwner(owner)) {
      CcInfraLog.debug(
        'rig: leaving $dirPath alone — it belongs to a live server '
        '(pid ${owner.serverPid}).',
      );
      return false;
    }

    // An unmarked directory predates the marker (or its writer died before the
    // first flush): there is no pid to verify, so there is nothing to kill and
    // removing it is all that is available. A LIVE rig can no longer land
    // here — `launch` refuses to boot without its marker, precisely so that
    // "unmarked" means "not ours and not anybody's".
    if (owner?.qemuPid case final qemuPid?) {
      final outcome = await _terminateVerifiedQemu(qemuPid, rigId: rigId);
      if (outcome == _ReapOutcome.survived) {
        CcInfraLog.warning(
          'rig: leaving $dirPath in place — QEMU pid $qemuPid ignored SIGKILL '
          'and removing its overlay would leave a hypervisor running on state '
          'that no longer exists.',
        );
        return false;
      }
    }
    return _deleteRigDirectory(dirPath);
  }

  /// Whether [owner] names a server process that is still running.
  ///
  /// The whole point of the marker: a directory owned by a LIVE sibling server
  /// is not an orphan, it is somebody else's running VM.
  Future<bool> _isLiveOwner(RigRuntimeOwner owner) async {
    if (owner.serverInstance == RigRuntimeOwner.currentServerInstance) {
      // Ours, booted by this very process and still tracked above. Sweeping it
      // would kill a rig somebody is looking at.
      return true;
    }
    final serverPid = owner.serverPid;
    if (serverPid == null || serverPid <= 0) {
      return false;
    }
    if (serverPid == pid) {
      // Our pid, a different run: a dead predecessor whose number the host
      // handed back to us. Not a sibling.
      return false;
    }
    final line = await _processes.commandLine(serverPid);
    if (line == null) {
      return false;
    }
    final command = owner.serverCommand;
    if (command != null && command.isNotEmpty && !line.contains(command)) {
      // The pid is live but it is running something else entirely — it was
      // recycled, and the server that wrote this marker is gone.
      return false;
    }
    return true;
  }

  /// Kills [pid] when — and only when — it is verifiably QEMU serving [rigId].
  ///
  /// The command-line check is what makes this safe against pid reuse: a
  /// recorded pid that now belongs to somebody's editor must never be
  /// signalled, so a mismatch reads as "the hypervisor is gone".
  Future<_ReapOutcome> _terminateVerifiedQemu(
    int pid, {
    required String rigId,
  }) async {
    if (pid <= 0) {
      return _ReapOutcome.absent;
    }
    final line = await _processes.commandLine(pid);
    if (line == null) {
      return _ReapOutcome.absent;
    }
    if (!commandLineMatchesRig(line, rigId)) {
      CcInfraLog.info(
        'rig/$rigId: pid $pid is no longer QEMU for this rig (it runs "$line") '
        '— not signalling it.',
      );
      return _ReapOutcome.absent;
    }
    CcInfraLog.warning('rig/$rigId: terminating orphaned QEMU pid $pid');
    await _processes.signal(pid, ProcessSignal.sigterm);
    if (await _awaitExit(pid)) {
      return _ReapOutcome.killed;
    }
    await _processes.signal(pid, ProcessSignal.sigkill);
    if (await _awaitExit(pid)) {
      return _ReapOutcome.killed;
    }
    CcInfraLog.warning(
      'rig/$rigId: QEMU pid $pid is still alive after SIGKILL',
    );
    return _ReapOutcome.survived;
  }

  Future<bool> _awaitExit(int pid) async {
    final deadline = DateTime.now().add(_ladder.kill);
    while (true) {
      if (!await _processes.isAlive(pid)) {
        return true;
      }
      if (!DateTime.now().isBefore(deadline)) {
        return false;
      }
      await Future<void>.delayed(_ladder.poll);
    }
  }

  /// Whether [commandLine] is a QEMU serving [rigId].
  ///
  /// This decides whether a recorded pid gets SIGTERM→SIGKILL, so it has to be
  /// wrong in the safe direction. Two exact checks, not two substring searches:
  ///
  ///  * argv[0]'s BASENAME must start with `qemu-system` (the emulator
  ///    binaries; `qemu-img` is deliberately excluded), and
  ///  * `ccrig-<rigId>` must appear as a WHOLE argv token, which only the
  ///    `-name` flag this backend passes produces.
  ///
  /// A substring pair (`contains('qemu') && contains(rigId)`) matched far more
  /// than QEMU: `qemu-img info <dataDir>/rigs/run/<uuid>/overlay.qcow2`,
  /// `tail -f …/qemu-stderr-<uuid>` and `grep <uuid> …` all contain both, and
  /// an operator inspecting an orphaned overlay after a crash is exactly the
  /// person running the first of those. With pid reuse in the mix that is a
  /// SIGKILL aimed at somebody's shell.
  static bool commandLineMatchesRig(String commandLine, String rigId) {
    if (rigId.isEmpty) {
      return false;
    }
    final tokens = commandLine.split(RegExp(r'\s+'))
      ..removeWhere((t) => t.isEmpty);
    if (tokens.isEmpty) {
      return false;
    }
    final executable = tokens.first.split(RegExp(r'[/\\]')).last.toLowerCase();
    if (!executable.startsWith('qemu-system')) {
      return false;
    }
    return tokens.skip(1).contains(qemuProcessName(rigId));
  }

  /// Writes this server's ownership marker into [directory].
  ///
  /// **[required] on the first write, best-effort on the pid update.** The
  /// marker is the ONLY thing that tells another server's orphan sweep that
  /// this directory belongs to a live machine: an unmarked directory is swept
  /// as debris, with no `qemuPid` to verify first, so a running rig whose
  /// marker write failed once loses its overlay and its control socket
  /// mid-session — to a sibling server that did exactly what it was told.
  ///
  /// So the claim that happens BEFORE the hypervisor starts must succeed or
  /// the launch fails. That trades a rig that will not boot for a rig that
  /// gets deleted underneath someone, on a filesystem where we have just
  /// written a multi-gigabyte overlay and cannot write a 200-byte JSON file
  /// beside it. Re-claiming to record the pid stays best-effort: the marker
  /// already exists by then, so the worst case is a sweep that cannot kill an
  /// orphan rather than one that deletes a live rig.
  Future<void> _claim(
    String directory, {
    required String rigId,
    int? qemuPid,
    bool required = false,
  }) async {
    try {
      await RigRuntimeOwner.forThisServer(
        rigId: rigId,
        qemuPid: qemuPid,
      ).writeTo(directory);
    } on Object catch (e) {
      if (required) {
        throw RigLaunchException(
          'Could not write the ownership marker in $directory ($e). Refusing '
          'to boot: an unmarked runtime directory is swept as debris by any '
          'other server sharing this data directory, which would delete this '
          'machine\'s state while it runs.',
        );
      }
      CcInfraLog.warning('rig/$rigId: could not claim $directory: $e');
    }
  }

  EnclosureBackend _preferredBackend() {
    if (Platform.isMacOS) {
      return EnclosureBackend.qemuHvf;
    }
    if (Platform.isLinux) {
      return EnclosureBackend.qemuKvm;
    }
    return EnclosureBackend.qemuTcg;
  }

  Future<EnclosureBackend> _detectAccelerator(String binary) async {
    if (Platform.isMacOS) {
      // Hypervisor.framework is present on every supported macOS.
      return EnclosureBackend.qemuHvf;
    }
    if (Platform.isLinux) {
      // KVM needs the device node AND permission to open it; being in the
      // `kvm` group is the usual missing half, and a rig that silently falls
      // back to emulation reads as "rigs are slow" rather than "add yourself
      // to the kvm group".
      final kvm = File('/dev/kvm');
      if (kvm.existsSync()) {
        try {
          final handle = await kvm.open();
          await handle.close();
          return EnclosureBackend.qemuKvm;
        } on Object {
          CcInfraLog.warning(
            'rig: /dev/kvm exists but is not readable by this user — falling '
            'back to emulation. Add this user to the "kvm" group for a ~10x '
            'speedup.',
          );
        }
      }
    }
    return EnclosureBackend.qemuTcg;
  }

  static String _hostArchitecture() {
    final version = Platform.version;
    if (version.contains('arm64') || version.contains('aarch64')) {
      return 'arm64';
    }
    return 'x64';
  }

  /// Finds [fileName] in the QEMU binary's own data directories.
  ///
  /// `qemu -L help` prints them — asking the binary beats guessing distro
  /// paths, because a Homebrew or Nix binary on PATH is a symlink into a
  /// versioned store and `dirname`-arithmetic lands beside the symlink, not
  /// beside the firmware. (The same reasoning `build_image.sh` documents.)
  static Future<String?> _locateFirmware(
    String qemuBinary,
    String fileName,
  ) async {
    try {
      final result = await Process.run(qemuBinary, ['-L', 'help']);
      for (final line in '${result.stdout}'.split('\n')) {
        final dir = line.trim();
        if (dir.isEmpty) {
          continue;
        }
        final candidate = File(p.join(dir, fileName));
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }
    } on Object {
      // Fall through: report not-found and let the probe say what is missing.
    }
    return null;
  }

  /// Runs [tool] and throws a [RigToolException] naming it when it fails.
  ///
  /// The rig runtime shells out for everything Dart has no API for — `chmod`,
  /// `ssh-keygen`, `qemu-img`, an ISO builder — and an unchecked exit code
  /// there is not a small bug: a seed written at the wrong mode boots a guest
  /// whose agent crash-loops on a permission error, and the operator is told
  /// two minutes later that "the image may be wrong for this surface".
  @visibleForTesting
  static Future<ProcessResult> runHostTool(
    String tool,
    List<String> arguments, {
    String? executable,
    String? hint,
  }) async {
    ProcessResult result;
    try {
      result = await Process.run(executable ?? tool, arguments);
    } on Object catch (e) {
      throw RigToolException(
        tool: tool,
        arguments: arguments,
        stderr: '$e',
        hint: hint ?? 'Is $tool installed and on PATH?',
      );
    }
    if (result.exitCode != 0) {
      throw RigToolException(
        tool: tool,
        arguments: arguments,
        exitCode: result.exitCode,
        stderr: '${result.stderr}'.trim(),
        hint: hint,
      );
    }
    return result;
  }

  /// Sets [mode] on [path].
  ///
  /// One helper for what used to be five unchecked `Process.run('chmod', …)`
  /// calls. Keeping chmod as a subprocess is fine — Dart has no native one —
  /// but it must not fail silently: every one of these files (the per-VM key,
  /// the seed, the seed image) holds a secret whose only protection is its
  /// mode, and the directories gate a control space that can stop the VM.
  Future<void> _chmod(String mode, String path) async {
    if (Platform.isWindows) {
      // There is no POSIX mode to set, and no rig boots here anyway: the
      // control space is a unix socket. Silently skipping is honest here in
      // a way it never is on a host that CAN enforce the mode.
      return;
    }
    await runHostTool(
      'chmod',
      [mode, path],
      hint:
          'Without mode $mode on $path the rig would run with a secret at the '
          'default umask.',
    );
  }

  static Future<String?> _which(String binary) async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        binary,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final path = '${result.stdout}'.split('\n').first.trim();
      return path.isEmpty ? null : path;
    } on Object {
      return null;
    }
  }

  static Future<int> _freePort() async {
    // Bind :0, read the port, release it. There is a race between releasing
    // and QEMU binding, but the window is microseconds and the alternative
    // (a fixed range) collides far more often in practice.
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  String _randomToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
