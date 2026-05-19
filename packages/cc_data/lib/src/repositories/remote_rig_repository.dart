import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A rig as the client sees it.
///
/// A flat view model rather than the domain entity: the client renders status
/// and identity and never reasons about a spec, so reconstructing the whole
/// aggregate on this side would be work with no reader.
class RigView {
  /// Creates a [RigView].
  const RigView({
    required this.id,
    required this.surface,
    required this.backendLabel,
    required this.phase,
    required this.accelerated,
    this.isExec = false,
    this.detail,
    this.closeReason,
    this.displayWidth,
    this.displayHeight,
    this.conversationId,
    this.agentId,
    this.controller,
    this.createdAt,
    this.expiresAt,
    this.memoryMb = 0,
    this.currentUrl,
  });

  /// Builds a view from the `rig.*` wire map.
  ///
  /// Absent fields come back ABSENT — `phase` no longer defaults to
  /// `provisioning` and `accelerated` no longer defaults to true. A truncated
  /// or older payload reading as a known state is worse than reading as
  /// unknown: the first shows a spinner for a machine nobody is booting, and
  /// the second hid the "Emulated" warning on exactly the hosts that need it.
  factory RigView.fromWire(Map<String, dynamic> wire) => RigView(
    id: wire['id'] as String? ?? '',
    surface: wire['surface'] as String? ?? '',
    isExec: wire['is_exec'] as bool? ?? false,
    backendLabel: wire['backend_label'] as String? ?? '',
    phase: wire['phase'] as String? ?? '',
    accelerated: wire['accelerated'] as bool?,
    detail: wire['detail'] as String?,
    closeReason: wire['close_reason'] as String?,
    displayWidth: wire['display_width'] as int?,
    displayHeight: wire['display_height'] as int?,
    conversationId: wire['conversation_id'] as String?,
    agentId: wire['agent_id'] as String?,
    controller: wire['controller'] as String?,
    createdAt: DateTime.tryParse(wire['created_at'] as String? ?? ''),
    expiresAt: DateTime.tryParse(wire['expires_at'] as String? ?? ''),
    memoryMb: wire['memory_mb'] as int? ?? 0,
    currentUrl: wire['current_url'] as String?,
  );

  /// Session id.
  final String id;

  /// `computer` / `browser` / `mobile`, as the wire spelled it.
  ///
  /// Prefer [surfaceKind] for anything that branches: five UI files were
  /// hand-comparing these strings, which is the domain's own state machine
  /// re-typed by hand once per file.
  final String surface;

  /// [surface] parsed, or null when the server named one this client does not
  /// know.
  RigSurface? get surfaceKind => RigSurface.fromWire(surface);

  /// Whether this is an exec (terminal) rig rather than a drivable surface.
  /// An exec rig and a `computer_use` rig share the `computer` surface, so
  /// this is the only thing that tells the ports panel which rig is the shell.
  final bool isExec;

  /// Human-readable backend name.
  final String backendLabel;

  /// Lifecycle phase, as the wire spelled it.
  final String phase;

  /// [phase] parsed, or null when the server named one this client does not
  /// know (an older or newer server, a truncated payload).
  ///
  /// Null is a REAL state the UI has to render honestly. It used to be
  /// impossible — an absent phase defaulted to `provisioning` — so an unknown
  /// value showed a "Failed" label beside a neutral status dot, which is two
  /// different claims about the same machine.
  RigPhase? get phaseKind => RigPhase.fromWire(phase);

  /// Whether the backend is hardware-accelerated, or null when the server did
  /// not say.
  ///
  /// Deliberately nullable: defaulting an absent value to `true` hid the
  /// "Emulated" badge, and a rig that is silently ten times slower with no
  /// explanation is the worst version of this.
  final bool? accelerated;

  /// Whether this rig is known to be running WITHOUT hardware acceleration.
  /// False when accelerated or unknown — the badge claims slowness only when
  /// the server actually reported it.
  bool get isEmulated => accelerated == false;

  /// Boot step or failure message.
  final String? detail;

  /// Why it closed.
  final String? closeReason;

  /// Guest display width, once it has one.
  final int? displayWidth;

  /// Guest display height.
  final int? displayHeight;

  /// The conversation it belongs to.
  final String? conversationId;

  /// The agent driving it.
  final String? agentId;

  /// Wire-encoded principal holding input control, or null.
  final String? controller;

  /// When it was created.
  final DateTime? createdAt;

  /// When its hard TTL expires.
  final DateTime? expiresAt;

  /// Guest RAM.
  final int memoryMb;

  /// The URL a browser rig's page is on, pushed as it navigates. Null on the
  /// other surfaces and before the first navigation.
  final String? currentUrl;

  /// Whether it can still be driven.
  bool get isLive => phaseKind?.isLive ?? false;

  /// Whether it is still coming up.
  bool get isStarting => phaseKind == RigPhase.provisioning;

  /// Whether it failed.
  bool get isFailed => phaseKind == RigPhase.failed;

  /// Whether the machine is gone (closed or failed).
  bool get isTerminal => phaseKind?.isTerminal ?? false;

  /// Who holds input control, or null when nobody does (or when the server
  /// sent something unparseable).
  Principal? get controllerPrincipal => Principal.tryParse(controller);

  /// Whether a human holds control.
  bool get isHumanControlled => controllerPrincipal?.isUser ?? false;
}

/// One backend's capabilities as the client sees them.
class RigBackendView {
  /// Creates a [RigBackendView].
  const RigBackendView({
    required this.backend,
    required this.label,
    required this.available,
    required this.surfaces,
    this.terminals = false,
    this.enforcedEgress = true,
    this.requiresInstall = false,
    this.installHint,
    this.note,
    this.missingImages = const [],
    this.version,
  });

  /// Builds a view from the `rig.detect` wire map.
  factory RigBackendView.fromWire(Map<String, dynamic> wire) => RigBackendView(
    backend: wire['backend'] as String? ?? '',
    label: wire['label'] as String? ?? '',
    available: wire['available'] as bool? ?? false,
    surfaces: [
      for (final s in (wire['surfaces'] as List? ?? const []))
        if (s is String) s,
    ],
    terminals: wire['terminals'] as bool? ?? false,
    enforcedEgress: wire['enforcedEgress'] as bool? ?? true,
    requiresInstall: wire['requiresInstall'] as bool? ?? false,
    installHint: wire['installHint'] as String?,
    note: wire['note'] as String?,
    missingImages: [
      for (final i in (wire['missingImages'] as List? ?? const []))
        if (i is String) i,
    ],
    version: wire['version'] as String?,
  );

  /// Backend wire id.
  final String backend;

  /// Human-readable label.
  final String label;

  /// Whether it can boot right now.
  final bool available;

  /// Surfaces it can host.
  final List<String> surfaces;

  /// Whether it can host an enclosed TERMINAL (the exec image is on disk).
  /// Separate from [surfaces]: the exec image is a shell with no display, so
  /// a host can offer VM terminals while offering no `computer_use`.
  final bool terminals;

  /// Whether this backend's guest gets the deny-by-default NIC. False for the
  /// Android emulator, which manages its own networking.
  final bool enforcedEgress;

  /// Whether installing something would make it available.
  final bool requiresInstall;

  /// The install command, shown verbatim.
  final String? installHint;

  /// Operator-facing note.
  final String? note;

  /// Base images still to download.
  final List<String> missingImages;

  /// Detected version.
  final String? version;
}

/// One base image as the client sees it.
class RigImageView {
  /// Creates a [RigImageView].
  const RigImageView({
    required this.id,
    required this.surface,
    required this.role,
    required this.description,
    required this.sizeBytes,
    required this.present,
    required this.published,
    this.downloadedBytes,
  });

  /// Builds a view from the `rig.images` wire map.
  factory RigImageView.fromWire(Map<String, dynamic> wire) => RigImageView(
    id: wire['id'] as String? ?? '',
    surface: wire['surface'] as String? ?? '',
    role: wire['role'] as String? ?? 'interactive',
    description: wire['description'] as String? ?? '',
    sizeBytes: wire['size_bytes'] as int? ?? 0,
    present: wire['present'] as bool? ?? false,
    published: wire['published'] as bool? ?? false,
    downloadedBytes: wire['downloaded_bytes'] as int?,
  );

  /// Image id, also its directory name.
  final String id;

  /// Which surface it serves.
  final String surface;

  /// `exec` (a shell, no display) or `interactive`.
  final String role;

  /// One line for the settings row.
  final String description;

  /// Approximate download size.
  final int sizeBytes;

  /// Whether it is on disk and usable.
  final bool present;

  /// Whether an artifact has actually been published for it.
  ///
  /// False means there is nothing to download and the store will refuse — the
  /// working path is importing a locally built image. The UI says which,
  /// rather than offering a button that always fails.
  final bool published;

  /// Bytes on disk so far, for a partial download.
  final int? downloadedBytes;
}

/// Drives server-hosted enclosures (rigs) over the RPC client.
///
/// Mirrors the `rig.*` ops and the `rig.watchSessions` subscription. The
/// machines live on the SERVER; this is the thin-client handle. Frames do NOT
/// come through here — they ride the separate `/rig/stream/<id>` chunked HTTP
/// body, because video in the same lane as every other RPC message would stall
/// the lane.
class RemoteRigRepository {
  /// Creates a [RemoteRigRepository] over [_client].
  RemoteRigRepository(this._client);

  final RemoteRpcClient _client;

  /// What the connected server can host.
  ///
  /// A server with no enclosure support answers `opUnknown`; that reads as
  /// "nothing available" rather than an error, so the settings page renders a
  /// clean empty state instead of a red banner.
  Future<List<RigBackendView>> detect() async {
    try {
      final data = await _client.call('rig.detect', const {});
      return [
        for (final b in (data['backends'] as List? ?? const []))
          if (b is Map) RigBackendView.fromWire(b.cast<String, dynamic>()),
      ];
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// The base images this host knows about and their state.
  Future<List<RigImageView>> images() async {
    try {
      final data = await _client.call('rig.images', const {});
      return [
        for (final i in (data['images'] as List? ?? const []))
          if (i is Map) RigImageView.fromWire(i.cast<String, dynamic>()),
      ];
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// Starts downloading [imageId].
  ///
  /// Returns as soon as the server ACCEPTS the download, not when it finishes:
  /// a base image is hundreds of megabytes and holding an RPC call open for
  /// minutes times the client out on a transfer that is working. Progress is
  /// the growing `downloadedBytes` in [images].
  Future<void> downloadImage(String imageId) =>
      _client.call('rig.downloadImage', {'image_id': imageId});

  /// Adopts the disk image at [path] on the SERVER's filesystem as [imageId].
  Future<void> importImage(String imageId, String path) =>
      _client.call('rig.importImage', {'image_id': imageId, 'path': path});

  /// Every rig in the bound workspace.
  Future<List<RigView>> list(String workspaceId) async {
    final data = await _client.call('rig.list', {'workspace_id': workspaceId});
    return _rigs(data);
  }

  /// Live rigs, pushed on every change.
  Stream<List<RigView>> watch(String workspaceId) => _client
      .subscribe('rig.watchSessions', {'workspace_id': workspaceId})
      .map(_rigs);

  /// Opens a rig.
  Future<RigView> open({
    required String workspaceId,
    required String surface,
    String? conversationId,
  }) async {
    final data = await _client.call('rig.open', {
      'workspace_id': workspaceId,
      'surface': surface,
      'conversation_id': ?conversationId,
    });
    return RigView.fromWire(data);
  }

  /// Sends one action as the calling human.
  ///
  /// Only meaningful while this user holds control — the server refuses a
  /// mutating action otherwise, which is the take-over lock doing its job
  /// rather than an error to work around.
  Future<({String text, bool isError})> act({
    required String workspaceId,
    required String rigId,
    required Map<String, dynamic> action,
  }) async {
    // The action map is spread FIRST and the scoped ids pinned after it. The
    // other order let an action carrying `workspace_id` / `rig_id` keys
    // override the ones this call was scoped to — client-originated today,
    // which is exactly the kind of "not currently attacker-controlled" that
    // stops being true without warning.
    final data = await _client.call('rig.act', {
      ...action,
      'workspace_id': workspaceId,
      'rig_id': rigId,
    });
    return (
      text: data['text'] as String? ?? '',
      isError: data['is_error'] as bool? ?? false,
    );
  }

  /// Takes exclusive input control.
  Future<RigView> takeControl(String workspaceId, String rigId) async {
    final data = await _client.call('rig.takeControl', {
      'workspace_id': workspaceId,
      'rig_id': rigId,
    });
    return RigView.fromWire(data);
  }

  /// The live navigation state of a browser rig: current URL plus whether
  /// back/forward have anywhere to go.
  ///
  /// Read on demand — back/forward reachability lives in the page's session
  /// history and is never pushed. The URL half also rides the rig row
  /// ([RigView.currentUrl]) for push updates on navigation.
  Future<RigBrowserStateView> browserState(
    String workspaceId,
    String rigId,
  ) async {
    final data = await _client.call('rig.browserState', {
      'workspace_id': workspaceId,
      'rig_id': rigId,
    });
    return RigBrowserStateView.fromWire(data);
  }

  /// Hands control back to the owning agent.
  Future<RigView> releaseControl(String workspaceId, String rigId) async {
    final data = await _client.call('rig.releaseControl', {
      'workspace_id': workspaceId,
      'rig_id': rigId,
    });
    return RigView.fromWire(data);
  }

  /// Destroys a rig.
  Future<void> destroy(String workspaceId, String rigId, {String? reason}) =>
      _client.call('rig.destroy', {
        'workspace_id': workspaceId,
        'rig_id': rigId,
        'reason': ?reason,
      });

  // ── Ports ──────────────────────────────────────────────────────────────

  /// Live forwarded-port snapshots for a Terminal (VM), pushed on every change.
  ///
  /// The discovery poll runs on the SERVER; the client never touches the
  /// guest. A server with no enclosure ports support answers `opUnknown`,
  /// which surfaces as an empty stream rather than an error banner.
  Stream<RigPortsView> watchPorts(String workspaceId, String rigId) => _client
      .subscribe('rig.watchPorts', {
        'workspace_id': workspaceId,
        'rig_id': rigId,
      })
      .map(RigPortsView.fromWire);

  /// Turns auto-forwarding of newly discovered guest ports on or off.
  Future<void> setPortsAutoForward(
    String workspaceId,
    String rigId, {
    required bool enabled,
  }) => _client.call('rig.setPortsAutoForward', {
    'workspace_id': workspaceId,
    'rig_id': rigId,
    'enabled': enabled,
  });

  /// Forwards [guestPort] by hand.
  Future<void> addPort(String workspaceId, String rigId, int guestPort) =>
      _client.call('rig.addPort', {
        'workspace_id': workspaceId,
        'rig_id': rigId,
        'guest_port': guestPort,
      });

  /// Removes [guestPort]'s forward.
  Future<void> removePort(String workspaceId, String rigId, int guestPort) =>
      _client.call('rig.removePort', {
        'workspace_id': workspaceId,
        'rig_id': rigId,
        'guest_port': guestPort,
      });

  /// Exposes (or unexposes) [guestPort] on the LAN.
  Future<void> setPortLan(
    String workspaceId,
    String rigId,
    int guestPort, {
    required bool exposed,
  }) => _client.call('rig.setPortLan', {
    'workspace_id': workspaceId,
    'rig_id': rigId,
    'guest_port': guestPort,
    'exposed': exposed,
  });

  /// Assigns (or clears, with null) a dev domain for [guestPort].
  Future<void> setPortDomain(
    String workspaceId,
    String rigId,
    int guestPort,
    String? domain,
  ) => _client.call('rig.setPortDomain', {
    'workspace_id': workspaceId,
    'rig_id': rigId,
    'guest_port': guestPort,
    'domain': ?domain,
  });

  List<RigView> _rigs(Map<String, dynamic> data) => [
    for (final r in (data['rigs'] as List? ?? const []))
      if (r is Map) RigView.fromWire(r.cast<String, dynamic>()),
  ];
}

/// A browser rig's navigation state as the client sees it.
class RigBrowserStateView {
  /// Creates a [RigBrowserStateView].
  const RigBrowserStateView({
    required this.url,
    required this.canGoBack,
    required this.canGoForward,
    this.loading = false,
  });

  /// Builds a view from the `rig.browserState` wire map.
  factory RigBrowserStateView.fromWire(Map<String, dynamic> wire) =>
      RigBrowserStateView(
        url: wire['url'] as String? ?? '',
        canGoBack: wire['can_go_back'] as bool? ?? false,
        canGoForward: wire['can_go_forward'] as bool? ?? false,
        loading: wire['loading'] as bool? ?? false,
      );

  /// The current page URL ('' when unknown or not loaded yet).
  final String url;

  /// Whether the session history has a previous entry.
  final bool canGoBack;

  /// Whether the session history has a next entry.
  final bool canGoForward;

  /// Whether the main frame is mid-load — while true the toolbar's reload
  /// button is a stop button.
  final bool loading;
}

/// One forwarded port as the client sees it.
class RigPortView {
  /// Creates a [RigPortView].
  const RigPortView({
    required this.guestPort,
    required this.hostPort,
    required this.origin,
    required this.active,
    this.lanPort,
    this.domain,
    this.process,
  });

  /// Builds a view from the `rig.ports` wire map.
  factory RigPortView.fromWire(Map<String, dynamic> wire) => RigPortView(
    guestPort: wire['guest_port'] as int? ?? 0,
    hostPort: wire['host_port'] as int? ?? 0,
    origin: wire['origin'] as String? ?? 'auto',
    active: wire['active'] as bool? ?? true,
    lanPort: wire['lan_port'] as int?,
    domain: wire['domain'] as String?,
    process: wire['process'] as String?,
  );

  /// The port inside the guest — the number the dev server printed.
  final int guestPort;

  /// The host loopback port. Equal to [guestPort] when that was free, so
  /// `localhost:<guestPort>` works on the host too.
  final int hostPort;

  /// `auto` (discovered) or `manual` (added by hand).
  final String origin;

  /// Whether something in the guest is listening right now. A manual forward
  /// outlives its process and shows inactive rather than vanishing.
  final bool active;

  /// The LAN-visible port, when exposed. Null means loopback only.
  final int? lanPort;

  /// A dev domain (`myapp.test`) routed to this port in the Browser (VM).
  final String? domain;

  /// The guest process listening on it, when known.
  final String? process;

  /// Whether this forward is loopback-only (not published on the LAN).
  bool get loopbackOnly => lanPort == null;
}

/// The forwarded-ports snapshot for one rig.
class RigPortsView {
  /// Creates a [RigPortsView].
  const RigPortsView({
    required this.rigId,
    required this.autoForward,
    required this.ports,
    this.tlsEnabled = false,
  });

  /// Builds a view from the `rig.ports` / `rig.watchPorts` wire map.
  factory RigPortsView.fromWire(Map<String, dynamic> wire) => RigPortsView(
    rigId: wire['rig_id'] as String? ?? '',
    autoForward: wire['auto_forward'] as bool? ?? true,
    tlsEnabled: wire['tls_enabled'] as bool? ?? false,
    ports: [
      for (final p in (wire['ports'] as List? ?? const []))
        if (p is Map) RigPortView.fromWire(p.cast<String, dynamic>()),
    ],
  );

  /// The rig.
  final String rigId;

  /// Whether new guest ports are forwarded automatically.
  final bool autoForward;

  /// Whether dev domains are served over HTTPS in the Browser (VM). Drives
  /// which scheme the panel shows in front of a domain — a scheme the server
  /// cannot answer must not be promised.
  final bool tlsEnabled;

  /// Current forwards, ascending by guest port.
  final List<RigPortView> ports;
}
