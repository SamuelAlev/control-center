import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
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
    this.browserEngine = RigBrowserEngine.chromium,
    this.egressAllowlist = const [],
    int? memoryMb,
    int? cpuCount,
    RigDisplaySize? display,
    this.ttl = const Duration(hours: 2),
    this.idleTimeout = const Duration(minutes: 15),
    this.worktreePath,
    this.imageId,
    this.conversationId,
    this.slotId,
    this.agentId,
    this.openedByUserId,
    this.capabilities = AgentCapabilities.safeDefault,
    this.repoOwner,
    this.repoName,
    this.homeTheme,
  }) : memoryMb = memoryMb ?? _defaultMemoryMb(surface, browserEngine),
       cpuCount = cpuCount ?? _defaultCpuCount(surface),
       display = display ?? _defaultDisplay(surface) {
    final slotError = slotIdError(slotId, surface);
    if (slotError != null) {
      throw ArgumentError.value(slotId, 'slotId', slotError);
    }
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
    String? openedByUserId,
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
    openedByUserId: openedByUserId,
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

  /// Which browser a [RigSurface.browser] rig runs.
  ///
  /// Ignored on the other surfaces (nothing reads it there), and non-null so
  /// every browser rig states its engine rather than leaving it to whichever
  /// image happened to boot. Two engines in one conversation are two
  /// machines — that IS the feature.
  final RigBrowserEngine browserEngine;

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

  /// WHICH machine of this kind, within [conversationId].
  ///
  /// Null is the conversation's DEFAULT machine: the one an agent's
  /// `browser_use`/`computer_use` reaches, the one every tab addressed before
  /// slots existed, and the one a persisted row with no slot resolves to. That
  /// default is what keeps "the human's tab and the agent's tool calls drive
  /// ONE machine" true — an agent never picks a slot, so it can never end up
  /// on a machine a person opened to compare against.
  ///
  /// A non-null slot is a deliberate SECOND machine of the same surface and
  /// engine, opened from the UI to run two of something side by side. It is
  /// part of the reuse key, so two slots are two VMs; everything else about
  /// them (image, envelope, egress) is identical.
  ///
  /// Never a path or a command-line argument — a matching key only — but
  /// validated to `[A-Za-z0-9_-]{1,64}` at construction anyway, because it
  /// arrives from a client and outlives the call in the persisted spec.
  final String? slotId;

  /// The agent that asked for it, when an agent did.
  final String? agentId;

  /// The member this rig was opened FOR, when a human opened it.
  ///
  /// A rig's credential grant is minted against this person's forge access, so
  /// a shell in an enclosure cannot reach further than the human who asked for
  /// it. Null means the rig was opened by background work and falls back to the
  /// server's own identity.
  final String? openedByUserId;

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

  /// The color scheme a browser rig's home page is written with, when the
  /// opener's app said one. Null means no client named one (an agent-opened
  /// rig) and the server falls back to the last theme a client named.
  ///
  /// Deliberately NOT part of `==`/`hashCode`: it changes nothing about the
  /// machine — only the placeholder page written at boot — so a theme flip
  /// must not defeat rig reuse and boot a second VM over a stylesheet. A rig
  /// reused across a theme change keeps its boot-time page until it is
  /// closed and reopened; the page is baked into the guest, not re-rendered.
  final RigBrowserHomeTheme? homeTheme;

  /// Returns a copy with selected fields overridden.
  RigSpec copyWith({
    RigSurface? surface,
    EnclosureBackend? backend,
    RigBrowserEngine? browserEngine,
    List<String>? egressAllowlist,
    int? memoryMb,
    int? cpuCount,
    RigDisplaySize? display,
    Duration? ttl,
    Duration? idleTimeout,
    String? worktreePath,
    String? imageId,
    String? conversationId,
    String? slotId,
    String? agentId,
    String? openedByUserId,
    AgentCapabilities? capabilities,
    String? repoOwner,
    String? repoName,
    RigBrowserHomeTheme? homeTheme,
  }) => RigSpec(
    surface: surface ?? this.surface,
    backend: backend ?? this.backend,
    browserEngine: browserEngine ?? this.browserEngine,
    egressAllowlist: egressAllowlist ?? this.egressAllowlist,
    memoryMb: memoryMb ?? this.memoryMb,
    cpuCount: cpuCount ?? this.cpuCount,
    display: display ?? this.display,
    ttl: ttl ?? this.ttl,
    idleTimeout: idleTimeout ?? this.idleTimeout,
    worktreePath: worktreePath ?? this.worktreePath,
    imageId: imageId ?? this.imageId,
    conversationId: conversationId ?? this.conversationId,
    slotId: slotId ?? this.slotId,
    agentId: agentId ?? this.agentId,
    openedByUserId: openedByUserId ?? this.openedByUserId,
    capabilities: capabilities ?? this.capabilities,
    repoOwner: repoOwner ?? this.repoOwner,
    repoName: repoName ?? this.repoName,
    homeTheme: homeTheme ?? this.homeTheme,
  );

  /// JSON form (RPC + persistence).
  Map<String, dynamic> toJson() => {
    'surface': surface.wire,
    if (backend != null) 'backend': backend!.wire,
    'browserEngine': browserEngine.wire,
    'egressAllowlist': egressAllowlist,
    'memoryMb': memoryMb,
    'cpuCount': cpuCount,
    'display': display.toJson(),
    'ttlSeconds': ttl.inSeconds,
    'idleTimeoutSeconds': idleTimeout.inSeconds,
    if (worktreePath != null) 'worktreePath': worktreePath,
    if (imageId != null) 'imageId': imageId,
    if (conversationId != null) 'conversationId': conversationId,
    if (slotId != null) 'slotId': slotId,
    if (agentId != null) 'agentId': agentId,
    if (openedByUserId != null) 'openedByUserId': openedByUserId,
    'capabilities': capabilities.toJsonString(),
    if (repoOwner != null) 'repoOwner': repoOwner,
    if (repoName != null) 'repoName': repoName,
    if (homeTheme != null) 'homeTheme': homeTheme!.wire,
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
      // An ABSENT engine is Chromium: every rig row written before engines
      // existed is a Chromium rig, and reading those back as "unknown" would
      // strand them. An engine this build does not know is a different case —
      // it also lands on Chromium here, but only because a persisted row has
      // to resolve to something bootable; the RPC entry point rejects an
      // unknown engine outright rather than quietly opening the wrong
      // browser.
      browserEngine:
          RigBrowserEngine.fromWire(json['browserEngine'] as String?) ??
          RigBrowserEngine.fallback,
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
      slotId: json['slotId'] as String?,
      agentId: json['agentId'] as String?,
      openedByUserId: json['openedByUserId'] as String?,
      capabilities: json['capabilities'] is String
          ? AgentCapabilities.fromJsonString(json['capabilities'] as String)
          : AgentCapabilities.safeDefault,
      repoOwner: json['repoOwner'] as String?,
      repoName: json['repoName'] as String?,
      homeTheme: RigBrowserHomeTheme.fromWire(json['homeTheme'] as String?),
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
  /// Per-surface memory defaults, refined per browser engine.
  ///
  /// Chromium's headless-shell is the lean case. Firefox and WebKit are not:
  /// Firefox runs a full browser (no headless-shell equivalent) and WebKit
  /// runs MiniBrowser on top of an Xvfb server, so both carry a real desktop
  /// stack the 2 GB Chromium budget does not cover. The number is what the
  /// host COMMITS and what the resident-megabyte LRU counts, so it is sized
  /// per engine rather than rounded up for everyone.
  static int _defaultMemoryMb(RigSurface surface, RigBrowserEngine engine) =>
      switch (surface) {
        RigSurface.computer => 4096,
        RigSurface.browser => switch (engine) {
          RigBrowserEngine.chromium => 2048,
          RigBrowserEngine.firefox => 2560,
          RigBrowserEngine.webkit => 2560,
        },
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
        browserEngine == other.browserEngine &&
        _sameList(egressAllowlist, other.egressAllowlist) &&
        memoryMb == other.memoryMb &&
        cpuCount == other.cpuCount &&
        display == other.display &&
        ttl == other.ttl &&
        idleTimeout == other.idleTimeout &&
        worktreePath == other.worktreePath &&
        imageId == other.imageId &&
        conversationId == other.conversationId &&
        slotId == other.slotId &&
        agentId == other.agentId &&
        capabilities == other.capabilities &&
        repoOwner == other.repoOwner &&
        repoName == other.repoName;
  }

  @override
  int get hashCode => Object.hash(
    surface,
    backend,
    browserEngine,
    Object.hashAll(egressAllowlist),
    memoryMb,
    cpuCount,
    display,
    ttl,
    idleTimeout,
    worktreePath,
    imageId,
    conversationId,
    slotId,
    agentId,
    capabilities,
    repoOwner,
    repoName,
  );

  /// Why [slotId] is not usable on [surface], or null when it is fine.
  ///
  /// Exposed rather than left to the constructor's [ArgumentError] so the RPC
  /// entry point can answer a bad slot with a named validation failure the
  /// caller can act on — an `ArgumentError` escaping a handler surfaces as the
  /// generic internal error, which tells the client nothing.
  static String? slotIdError(String? slotId, RigSurface surface) {
    if (slotId == null) {
      return null;
    }
    if (!_slotIdPattern.hasMatch(slotId)) {
      return 'A slot id is 1-64 characters of [A-Za-z0-9_-].';
    }
    // The Android emulator is a HOST device, not a machine this server boots:
    // two mobile rigs would drive the same phone while claiming to be two.
    // Refused rather than silently collapsed, because "I opened a second
    // device" and "both tabs drive one device" look identical right up until
    // an action lands somewhere nobody was looking.
    if (surface == RigSurface.mobile) {
      return 'The mobile surface drives the host\'s attached device, so a '
          'conversation has exactly one phone rig.';
    }
    return null;
  }

  /// What a client may name a slot. Deliberately narrow: it is opaque to the
  /// server, so nothing is lost by refusing the shapes that would surprise
  /// someone reading a spec back out of the database.
  static final RegExp _slotIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  @override
  String toString() =>
      'RigSpec(${surface.wire}${backend == null ? '' : '/${backend!.wire}'}'
      '${surface == RigSurface.browser ? '/${browserEngine.wire}' : ''}'
      // Two slots are two VMs with otherwise identical specs, so a log line
      // that omits the slot describes both of them.
      '${slotId == null ? '' : '#$slotId'}, '
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
