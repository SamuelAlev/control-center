import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// What to boot, how big, how long it may live and what it may reach.
///
/// Deliberately shaped like `SandboxSpec`: same egress-allowlist vocabulary,
/// same "everything is bounded" posture. A rig with no ceiling is a VM someone
/// left running on a laptop.
class RigSpec {
  /// Creates a [RigSpec].
  RigSpec({
    required this.surface,
    this.backend,
    this.egressAllowlist = const [],
    int? memoryMb,
    int? cpuCount,
    RigDisplaySize? display,
    this.ttl = const Duration(hours: 2),
    this.idleTimeout = const Duration(minutes: 15),
    this.worktreePath,
    this.imageId,
    this.conversationId,
    this.agentId,
    this.capabilities = AgentCapabilities.safeDefault,
    this.repoOwner,
    this.repoName,
  }) : memoryMb = memoryMb ?? _defaultMemoryMb(surface),
       cpuCount = cpuCount ?? _defaultCpuCount(surface),
       display = display ?? _defaultDisplay(surface) {
    if (this.memoryMb < 128) {
      throw ArgumentError.value(
        this.memoryMb,
        'memoryMb',
        'A guest needs at least 128 MB',
      );
    }
    if (this.cpuCount < 1) {
      throw ArgumentError.value(this.cpuCount, 'cpuCount', 'Must be >= 1');
    }
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'Must be positive');
    }
    if (idleTimeout <= Duration.zero) {
      throw ArgumentError.value(idleTimeout, 'idleTimeout', 'Must be positive');
    }
  }

  /// A terminal/exec rig: lean, no display work, longer idle grace than an
  /// interactive surface because a human staring at a shell is still "using"
  /// it even while typing nothing.
  factory RigSpec.exec({
    required String conversationId,
    String? worktreePath,
    List<String> egressAllowlist = const [],
    EnclosureBackend? backend,
    int memoryMb = 512,
    int cpuCount = 2,
    AgentCapabilities capabilities = AgentCapabilities.safeDefault,
    String? repoOwner,
    String? repoName,
  }) => RigSpec(
    surface: RigSurface.computer,
    backend: backend,
    egressAllowlist: egressAllowlist,
    memoryMb: memoryMb,
    cpuCount: cpuCount,
    ttl: const Duration(hours: 8),
    idleTimeout: const Duration(minutes: 45),
    worktreePath: worktreePath,
    imageId: execImageId,
    conversationId: conversationId,
    capabilities: capabilities,
    repoOwner: repoOwner,
    repoName: repoName,
  );

  /// Whether this spec describes a terminal/exec machine rather than one
  /// someone looks at.
  ///
  /// Load-bearing for reuse: an exec rig and a `computer_use` rig share the
  /// `computer` surface and can share a conversation, but a shell image has no
  /// screen — reusing one for the other would hand an agent a machine it
  /// cannot see.
  bool get isExec => imageId == execImageId;

  /// The image id every exec (terminal) rig boots.
  ///
  /// Named explicitly rather than left to "the default for this surface":
  /// two images serve the computer surface and they are not interchangeable —
  /// this one is a shell with no display server.
  static const String execImageId = 'cc-exec-linux';

  /// Which machine to present.
  final RigSurface surface;

  /// A specific backend to use, or null to let the platform probe and pick.
  /// Naming one that is unavailable is an error, not a silent downgrade.
  final EnclosureBackend? backend;

  /// Hostnames the guest may reach, in the same pattern vocabulary as
  /// `SandboxSpec.egressAllowlist` (exact host, or `*.example.com`).
  ///
  /// Empty means the guest reaches NOTHING outbound — the deny-by-default
  /// floor, not "unrestricted". Everything else is refused by the proxy the
  /// guest is forced through.
  final List<String> egressAllowlist;

  /// Guest RAM.
  final int memoryMb;

  /// Guest vCPUs.
  final int cpuCount;

  /// The display the guest boots with. A viewer renegotiates it live.
  final RigDisplaySize display;

  /// Hard lifetime. A rig is destroyed at [ttl] whatever it is doing; the
  /// guest cannot extend it.
  final Duration ttl;

  /// How long with no action before the rig parks, then closes.
  final Duration idleTimeout;

  /// A host worktree/repo to make available inside the guest, or null for a
  /// bare machine.
  ///
  /// The host copy stays authoritative: this path is synced IN at boot and
  /// changes come back out explicitly. The guest never mounts it.
  final String? worktreePath;

  /// A specific base image to boot, or null for the surface's default.
  final String? imageId;

  /// The conversation this rig belongs to, when opened from one. Exec rigs are
  /// keyed on this so one conversation reuses one machine.
  final String? conversationId;

  /// The agent that asked for it, when an agent did.
  final String? agentId;

  /// What the credential broker may mint for this rig.
  ///
  /// Defaults to [AgentCapabilities.safeDefault], which grants NOTHING — the
  /// broker then has no token to hand over and says so. That is the correct
  /// floor for an agent-opened rig: an enclosure does not get push rights
  /// because it exists. A terminal rig inherits the operator's own
  /// capabilities, which is what makes `git push` work there.
  final AgentCapabilities capabilities;

  /// The repo a scoped credential should be minted for, when known. Without
  /// it the GitHub broker cannot mint a fine-grained token and falls back to
  /// a broader one, so this is the difference between a scoped grant and a
  /// blunt instrument.
  final String? repoOwner;

  /// The repo name half of [repoOwner].
  final String? repoName;

  /// Returns a copy with selected fields overridden.
  RigSpec copyWith({
    RigSurface? surface,
    EnclosureBackend? backend,
    List<String>? egressAllowlist,
    int? memoryMb,
    int? cpuCount,
    RigDisplaySize? display,
    Duration? ttl,
    Duration? idleTimeout,
    String? worktreePath,
    String? imageId,
    String? conversationId,
    String? agentId,
    AgentCapabilities? capabilities,
    String? repoOwner,
    String? repoName,
  }) => RigSpec(
    surface: surface ?? this.surface,
    backend: backend ?? this.backend,
    egressAllowlist: egressAllowlist ?? this.egressAllowlist,
    memoryMb: memoryMb ?? this.memoryMb,
    cpuCount: cpuCount ?? this.cpuCount,
    display: display ?? this.display,
    ttl: ttl ?? this.ttl,
    idleTimeout: idleTimeout ?? this.idleTimeout,
    worktreePath: worktreePath ?? this.worktreePath,
    imageId: imageId ?? this.imageId,
    conversationId: conversationId ?? this.conversationId,
    agentId: agentId ?? this.agentId,
    capabilities: capabilities ?? this.capabilities,
    repoOwner: repoOwner ?? this.repoOwner,
    repoName: repoName ?? this.repoName,
  );

  /// JSON form (RPC + persistence).
  Map<String, dynamic> toJson() => {
    'surface': surface.wire,
    if (backend != null) 'backend': backend!.wire,
    'egressAllowlist': egressAllowlist,
    'memoryMb': memoryMb,
    'cpuCount': cpuCount,
    'display': display.toJson(),
    'ttlSeconds': ttl.inSeconds,
    'idleTimeoutSeconds': idleTimeout.inSeconds,
    if (worktreePath != null) 'worktreePath': worktreePath,
    if (imageId != null) 'imageId': imageId,
    if (conversationId != null) 'conversationId': conversationId,
    if (agentId != null) 'agentId': agentId,
    'capabilities': capabilities.toJsonString(),
    if (repoOwner != null) 'repoOwner': repoOwner,
    if (repoName != null) 'repoName': repoName,
  };

  /// Reads a spec from [json]. Throws [ArgumentError] on an unknown surface —
  /// there is no sensible default for "which machine did you want".
  static RigSpec fromJson(Map<String, dynamic> json) {
    final surface = RigSurface.fromWire(json['surface'] as String?);
    if (surface == null) {
      throw ArgumentError.value(json['surface'], 'surface', 'Unknown surface');
    }
    return RigSpec(
      surface: surface,
      backend: EnclosureBackend.fromWire(json['backend'] as String?),
      egressAllowlist: [
        for (final e in (json['egressAllowlist'] as List? ?? const []))
          if (e is String && e.trim().isNotEmpty) e.trim(),
      ],
      memoryMb: json['memoryMb'] as int?,
      cpuCount: json['cpuCount'] as int?,
      display: json['display'] is Map
          ? RigDisplaySize.fromJson(
              (json['display'] as Map).cast<String, dynamic>(),
              fallback: _defaultDisplay(surface),
            )
          : null,
      ttl: Duration(seconds: json['ttlSeconds'] as int? ?? 7200),
      idleTimeout: Duration(seconds: json['idleTimeoutSeconds'] as int? ?? 900),
      worktreePath: json['worktreePath'] as String?,
      imageId: json['imageId'] as String?,
      conversationId: json['conversationId'] as String?,
      agentId: json['agentId'] as String?,
      capabilities: json['capabilities'] is String
          ? AgentCapabilities.fromJsonString(json['capabilities'] as String)
          : AgentCapabilities.safeDefault,
      repoOwner: json['repoOwner'] as String?,
      repoName: json['repoName'] as String?,
    );
  }

  /// Per-surface memory defaults.
  ///
  /// A desktop or browser guest needs real headroom — the 512 MB that suits a
  /// shell will OOM Chromium on the first heavy page, and an OOM inside a rig
  /// looks to the agent like "the site is broken". The computer surface runs
  /// a full GNOME session on software GL, which is another tier again: at
  /// 2 GB / 2 vCPU the shell fights the encoder for cores and the whole rig
  /// reads as "laggy".
  static int _defaultMemoryMb(RigSurface surface) => switch (surface) {
    RigSurface.computer => 4096,
    RigSurface.browser => 2048,
    RigSurface.mobile => 4096,
  };

  static int _defaultCpuCount(RigSurface surface) => switch (surface) {
    RigSurface.computer => 4,
    RigSurface.browser => 2,
    RigSurface.mobile => 4,
  };

  static RigDisplaySize _defaultDisplay(RigSurface surface) =>
      switch (surface) {
        RigSurface.mobile => RigDisplaySize.defaultMobile,
        _ => RigDisplaySize.defaultDesktop,
      };

  /// Full structural equality, including the egress allowlist.
  ///
  /// This is the feature's central value object: it decides which image boots,
  /// how much memory the host commits, how long the machine lives and — in
  /// [egressAllowlist] — everything the guest may reach. Identity equality
  /// made every `Set`/`Map` use and every "did the spec change?" comparison
  /// silently answer "different", which for the allowlist is the one field
  /// where a missed comparison is a security question.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RigSpec || runtimeType != other.runtimeType) {
      return false;
    }
    return surface == other.surface &&
        backend == other.backend &&
        _sameList(egressAllowlist, other.egressAllowlist) &&
        memoryMb == other.memoryMb &&
        cpuCount == other.cpuCount &&
        display == other.display &&
        ttl == other.ttl &&
        idleTimeout == other.idleTimeout &&
        worktreePath == other.worktreePath &&
        imageId == other.imageId &&
        conversationId == other.conversationId &&
        agentId == other.agentId &&
        capabilities == other.capabilities &&
        repoOwner == other.repoOwner &&
        repoName == other.repoName;
  }

  @override
  int get hashCode => Object.hash(
    surface,
    backend,
    Object.hashAll(egressAllowlist),
    memoryMb,
    cpuCount,
    display,
    ttl,
    idleTimeout,
    worktreePath,
    imageId,
    conversationId,
    agentId,
    capabilities,
    repoOwner,
    repoName,
  );

  @override
  String toString() =>
      'RigSpec(${surface.wire}${backend == null ? '' : '/${backend!.wire}'}, '
      '${memoryMb}MB, ${cpuCount}cpu, $display, '
      '${egressAllowlist.length} allowed host(s))';

  /// Order-sensitive list equality. Order matters here: the allowlist is
  /// interpolated into a command line one entry at a time, so two orders are
  /// two command lines.
  static bool _sameList(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
