import 'dart:convert';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart' show ServerSettingDao;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/media_proxy_guard.dart'
    show isBlockedProxyTarget, resolvesToBlockedAddress;
import 'package:cc_server_core/src/server_boot_refusal.dart' show printableText;

/// Which Connect this server uses, if any.
enum ConnectMode {
  /// Onboarding has not picked yet. Behaves as [off].
  unset,

  /// Control Center's hosted Connect ([hostedConnectOrigin]).
  hosted,

  /// A self-hosted Connect at an operator-chosen URL.
  custom,

  /// No Connect: every lane uses this server's own credentials or is off.
  off;

  /// Parses a stored value; [unset] for anything unknown.
  static ConnectMode fromWire(String? wire) {
    for (final mode in values) {
      if (mode.name == wire) {
        return mode;
      }
    }
    return unset;
  }

  /// Whether a Connect is in use.
  bool get usesConnect => this == hosted || this == custom;
}

/// The effective Connect choice after the environment override.
final class ConnectChoice {
  /// Creates a choice.
  const ConnectChoice({
    required this.mode,
    required this.baseUrl,
    required this.lockedByEnvironment,
  });

  /// The mode in force.
  final ConnectMode mode;

  /// The canonical base URL when [mode] uses a Connect, else empty.
  final String baseUrl;

  /// True when `CC_CONNECT_URL` decides, so Settings shows the control
  /// read-only.
  final bool lockedByEnvironment;

  /// Whether lanes may route through a Connect.
  bool get enabled => mode.usesConnect && baseUrl.isNotEmpty;
}

/// One Connect a call goes to, and whose trust state it uses.
///
/// The server's own choice is one target; a workspace that picked Control
/// Center's Connect or one of its own is another. Config, identity and
/// last-good caches are keyed by [cacheKey], so two targets never share a
/// verdict unless they are the same Connect under the same trust store.
final class ConnectTarget {
  /// Creates a target.
  const ConnectTarget({
    required this.mode,
    required this.baseUrl,
    this.pinScope = '',
    this.guarded = false,
    this.lockedByEnvironment = false,
  });

  /// The server's own choice as a target.
  factory ConnectTarget.server(ConnectChoice choice) => ConnectTarget(
    mode: choice.mode,
    baseUrl: choice.baseUrl,
    lockedByEnvironment: choice.lockedByEnvironment,
  );

  /// No Connect.
  static const ConnectTarget none = ConnectTarget(
    mode: ConnectMode.off,
    baseUrl: '',
  );

  /// Hosted or custom; [ConnectMode.off] for none.
  final ConnectMode mode;

  /// The canonical base URL, or empty.
  final String baseUrl;

  /// Whose TOFU pins and cached config apply: empty for the server's, else
  /// the id of the workspace that chose this custom Connect. A workspace
  /// admin confirming a pin change never moves the server's trust, nor
  /// another workspace's, in the same URL.
  final String pinScope;

  /// Whether every connection is checked against the media-proxy SSRF rules
  /// and pinned to the address it resolved to: true for a URL a workspace
  /// admin chose, false for the server owner's choice.
  final bool guarded;

  /// True when `CC_CONNECT_URL` decides the server's choice.
  final bool lockedByEnvironment;

  /// Whether calls may go to this Connect at all.
  bool get enabled => mode.usesConnect && baseUrl.isNotEmpty;

  /// The canonical origin seals made here carry, or empty.
  String get origin => baseUrl.isEmpty ? '' : canonicalConnectBaseUrl(baseUrl);

  /// The target as a [ConnectChoice], for status surfaces.
  ConnectChoice get choice => ConnectChoice(
    mode: mode,
    baseUrl: baseUrl,
    lockedByEnvironment: lockedByEnvironment,
  );

  /// The key every per-target cache uses.
  String get cacheKey => '${guarded ? 'g' : 'u'}\u0000$pinScope\u0000$baseUrl';

  @override
  bool operator ==(Object other) =>
      other is ConnectTarget &&
      other.mode == mode &&
      other.baseUrl == baseUrl &&
      other.pinScope == pinScope &&
      other.guarded == guarded;

  @override
  int get hashCode => Object.hash(mode, baseUrl, pinScope, guarded);
}

/// Where one workspace's provider lanes run: the effective form of its
/// [WorkspaceConnectMode] over the server's choice.
final class ConnectRoute {
  /// Creates a route.
  const ConnectRoute({
    required this.mode,
    required this.target,
    required this.serverOwnApps,
    this.blockedByEnvironment = false,
    this.connectUrlInvalid = false,
    this.workspaceSlot = false,
  });

  /// The workspace's stored choice; [WorkspaceConnectMode.inherit] for a
  /// call with no workspace.
  final WorkspaceConnectMode mode;

  /// The Connect lanes may route through ([ConnectTarget.none] when none).
  final ConnectTarget target;

  /// Whether the server's own apps (`ProviderAppSettings`, `KLIPY_APP_KEY`,
  /// `LINEAR_API_KEY`) apply: only while the workspace inherits a server on
  /// its own apps.
  final bool serverOwnApps;

  /// True when the workspace chose its own Connect but `CC_CONNECT_URL`
  /// pins where sign-ins go: nothing runs until an admin picks again.
  final bool blockedByEnvironment;

  /// True when the workspace chose a custom Connect whose stored URL is
  /// missing or unusable: nothing runs until an admin enters a valid one.
  final bool connectUrlInvalid;

  /// Whether person grants (GitHub, Linear) live in the workspace's slot
  /// instead of the person's server-wide one: exactly when the workspace's
  /// sign-in target differs from the server's — its own apps, a Connect
  /// whose [ConnectTarget.cacheKey] is not the server route's, or no usable
  /// target at all. A `hosted` workspace on a `hosted` server shares the
  /// person's global grant.
  final bool workspaceSlot;

  /// Whether only the workspace's own apps apply.
  bool get workspaceOwnApps => mode == WorkspaceConnectMode.own;

  /// What the workspace actually runs on, for `workspaceConnect.status`:
  /// `hosted`, `custom`, `server_own`, `own` or `off`.
  String get effectiveMode {
    if (mode == WorkspaceConnectMode.own) {
      return 'own';
    }
    if (target.enabled) {
      return target.mode.name;
    }
    return serverOwnApps ? 'server_own' : 'off';
  }
}

/// A `CC_CONNECT_URL` this server cannot use. The boot refuses to start on
/// it ([ConnectSettings.checkEnvironment]) rather than failing every lane
/// call later; a [ConnectSettings] built over it reads as Connect off.
final class ConnectEnvironmentInvalid implements Exception {
  /// Creates the refusal; [reason] is the URL check's message.
  const ConnectEnvironmentInvalid(this.reason);

  /// Why the value is unusable.
  final String reason;

  /// What the operator reads.
  String get message =>
      'cc_server: refusing to start \u2014 CC_CONNECT_URL is not usable: '
      '${printableText(reason, max: 300)} '
      'Set it to hosted, off or a Connect URL (https://, or http:// on this '
      'machine only), or unset it.';

  @override
  String toString() => message;
}

/// Where the Connect choice and its trust state live.
///
/// Non-secrets (`connect_mode`, `connect_url`, the hosted epoch high-water
/// mark, the last verified config, the self-hosted TOFU pins) are server
/// settings; the master install seed is a secret in [FileSecretsStore],
/// separate from the device-pairing identity.
class ConnectSettings {
  /// Creates the settings over [_secrets] and, when the host has a database,
  /// [_settings]. [_environment] supplies `CC_CONNECT_URL`.
  ConnectSettings({
    required this._secrets,
    this._settings,
    this._environment = const {},
  });

  final FileSecretsStore _secrets;
  final ServerSettingDao? _settings;
  final Map<String, String> _environment;
  final Map<String, String> _memory = {};
  final List<void Function()> _listeners = [];
  final List<void Function(String workspaceId)> _workspaceListeners = [];

  /// Loads a workspace, so [routeFor] can read its choice. Assigned once the
  /// workspace registry exists; unset (tests, the `cc_server connect` CLI),
  /// every workspace follows the server.
  Future<Workspace?> Function(String workspaceId)? workspaceLookup;

  /// Lists every workspace, so [connectTargets] covers each one's own
  /// Connect. Assigned with [workspaceLookup]; unset, only the server's
  /// Connect is covered.
  Future<List<Workspace>> Function()? workspaceList;

  /// The environment override, parsed once: null when `CC_CONNECT_URL` is
  /// unset, Connect off (locked) when it is unusable.
  late final ConnectChoice? _pinned = _parseEnvironment(_environment).$1;

  /// The last `mode|url|seed` observed, so a change made by another process
  /// (`cc_server connect`) is noticed. Null until first observed.
  String? _observed;

  /// Serializes the seed's read-then-write.
  Future<void> _seedLock = Future<void>.value();

  /// Runs [listener] after anything that changes which Connect or install
  /// identity lanes use: [setChoice], [replaceInstallSeed], or such a change
  /// made outside this process and noticed by [noticeExternalChanges].
  /// Callers drop what they cached.
  void addListener(void Function() listener) => _listeners.add(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Runs [listener] after one workspace's Connect choice changed
  /// ([workspaceChoiceChanged]): what that workspace cached for its lanes
  /// (GitHub grants, Connect config, its chat connection, Google and Linear
  /// grants) belongs to another identity now.
  void addWorkspaceListener(void Function(String workspaceId) listener) =>
      _workspaceListeners.add(listener);

  /// Announces that [workspaceId]'s stored choice changed.
  void workspaceChoiceChanged(String workspaceId) {
    for (final listener in List.of(_workspaceListeners)) {
      listener(workspaceId);
    }
  }

  /// Whether `CC_CONNECT_URL` pins the server's Connect. It also forbids a
  /// workspace from choosing its own Connect: the operator decided where
  /// sign-ins go.
  bool get lockedByEnvironment =>
      (_environment[environmentKey]?.trim() ?? '').isNotEmpty;

  /// Where [workspaceId]'s lanes run now; the server's own route for null.
  ///
  /// Never throws. A workspace that is not registered gets no lane at all
  /// (it cannot borrow the server's), and a workspace that chose its own
  /// Connect while `CC_CONNECT_URL` is set runs nothing until an admin picks
  /// again: it never falls back to the server's apps or Connect.
  Future<ConnectRoute> routeFor(String? workspaceId) async {
    final server = await choice();
    final serverRoute = ConnectRoute(
      mode: WorkspaceConnectMode.inherit,
      target: ConnectTarget.server(server),
      serverOwnApps: !server.mode.usesConnect,
    );
    final lookup = workspaceLookup;
    if (workspaceId == null || workspaceId.isEmpty || lookup == null) {
      return serverRoute;
    }
    final workspace = await lookup(workspaceId);
    if (workspace == null) {
      return const ConnectRoute(
        mode: WorkspaceConnectMode.own,
        target: ConnectTarget.none,
        serverOwnApps: false,
        workspaceSlot: true,
      );
    }
    return routeOf(workspace, serverRoute);
  }

  /// The route [workspace]'s stored choice gives over [serverRoute].
  ConnectRoute routeOf(Workspace workspace, ConnectRoute serverRoute) {
    final mode = workspace.connectMode;
    switch (mode) {
      case WorkspaceConnectMode.inherit:
        return serverRoute;
      case WorkspaceConnectMode.own:
        return ConnectRoute(
          mode: mode,
          target: ConnectTarget.none,
          serverOwnApps: false,
          workspaceSlot: true,
        );
      case WorkspaceConnectMode.hosted || WorkspaceConnectMode.custom:
        final url = workspace.connectUrl.trim();
        if (lockedByEnvironment ||
            (mode == WorkspaceConnectMode.custom && url.isEmpty)) {
          return ConnectRoute(
            mode: mode,
            target: ConnectTarget.none,
            serverOwnApps: false,
            blockedByEnvironment: lockedByEnvironment,
            connectUrlInvalid: !lockedByEnvironment,
            workspaceSlot: true,
          );
        }
        if (mode == WorkspaceConnectMode.hosted) {
          const target = ConnectTarget(
            mode: ConnectMode.hosted,
            baseUrl: hostedConnectOrigin,
          );
          return ConnectRoute(
            mode: mode,
            target: target,
            serverOwnApps: false,
            workspaceSlot: !_sameTarget(target, serverRoute.target),
          );
        }
        final String base;
        try {
          base = canonicalConnectBaseUrl(url);
        } on FormatException {
          return ConnectRoute(
            mode: mode,
            target: ConnectTarget.none,
            serverOwnApps: false,
            connectUrlInvalid: true,
            workspaceSlot: true,
          );
        }
        final target = ConnectTarget(
          mode: ConnectMode.custom,
          baseUrl: base,
          pinScope: workspace.id,
          guarded: true,
        );
        return ConnectRoute(
          mode: mode,
          target: target,
          serverOwnApps: false,
          workspaceSlot: !_sameTarget(target, serverRoute.target),
        );
    }
  }

  /// Whether a workspace's Connect [target] is the very Connect, under the
  /// same trust store, the server's route uses: then its sign-ins are the
  /// server's and share the person's global slot.
  static bool _sameTarget(ConnectTarget target, ConnectTarget server) =>
      target.enabled && server.enabled && target.cacheKey == server.cacheKey;

  /// Checks a Connect URL a workspace admin entered and returns it
  /// canonical. HTTPS only (plain HTTP on this machine is the server owner's
  /// privilege, not a workspace's), and refused when it names or resolves to
  /// an address `/proxy/media` refuses: loopback, link-local, cloud
  /// metadata, private IPv4 or IPv6 unique-local. Every connection re-checks
  /// and pins the address (`ConnectClient`), so a later DNS answer cannot
  /// move it inside.
  static Future<String> checkWorkspaceConnectUrl(String url) async {
    final String base;
    try {
      base = canonicalConnectBaseUrl(url.trim());
    } on FormatException {
      throw const ValidationException('Enter the Connect server URL.');
    }
    if (!base.startsWith('https://')) {
      throw const ValidationException(
        'A workspace\'s Connect server must use HTTPS.',
      );
    }
    final uri = Uri.parse(base);
    if (isBlockedProxyTarget(uri) || await resolvesToBlockedAddress(uri)) {
      throw const ValidationException(
        'That Connect server is on a private or local network address, '
        'which a workspace cannot use. Use a public HTTPS address.',
      );
    }
    return base;
  }

  /// Whether [url] names Control Center's hosted Connect.
  static bool isHostedUrl(String url) => _isHosted(url);

  /// Refuses an unusable `CC_CONNECT_URL` in [environment] with
  /// [ConnectEnvironmentInvalid]. The boot and `cc_server connect` call it
  /// once, so the operator sees the reason instead of every Connect lane
  /// failing at its call site.
  static void checkEnvironment(Map<String, String> environment) {
    final error = _parseEnvironment(environment).$2;
    if (error != null) {
      throw ConnectEnvironmentInvalid(error);
    }
  }

  /// The override in [environment] and, when it is unusable, why.
  static (ConnectChoice?, String?) _parseEnvironment(
    Map<String, String> environment,
  ) {
    final override = environment[environmentKey]?.trim() ?? '';
    if (override.isEmpty) {
      return (null, null);
    }
    switch (override.toLowerCase()) {
      case 'off':
        return (_lockedOff, null);
      case 'hosted':
        return (
          const ConnectChoice(
            mode: ConnectMode.hosted,
            baseUrl: hostedConnectOrigin,
            lockedByEnvironment: true,
          ),
          null,
        );
    }
    try {
      return (
        ConnectChoice(
          mode: _isHosted(override) ? ConnectMode.hosted : ConnectMode.custom,
          baseUrl: _checkedUrl(override),
          lockedByEnvironment: true,
        ),
        null,
      );
    } on ValidationException catch (e) {
      return (_lockedOff, e.message);
    }
  }

  static const _lockedOff = ConnectChoice(
    mode: ConnectMode.off,
    baseUrl: '',
    lockedByEnvironment: true,
  );

  /// Fires the listeners when the stored choice or install seed changed
  /// since this process last looked: `cc_server connect enable | disable`
  /// writes the same data directory from another process, and nothing else
  /// would tell a running server's caches. Cheap (two setting
  /// reads and the secrets file's mtime check); `ConnectClient` runs it
  /// before answering from its config cache.
  Future<void> noticeExternalChanges() async {
    final now = await _fingerprint();
    final before = _observed;
    _observed = now;
    if (before != null && before != now) {
      _notify();
    }
  }

  Future<String> _fingerprint() async {
    final choice = await this.choice();
    final seed = await _secrets.readPsk(installKeySecret) ?? '';
    return '${choice.mode.name}|${choice.baseUrl}|$seed';
  }

  Future<void> _settled() async {
    _observed = await _fingerprint();
    _notify();
  }

  Future<T> _withSeedLock<T>(Future<T> Function() body) {
    final run = _seedLock.then((_) => body());
    _seedLock = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// Whether this server's own apps (`ProviderAppSettings`, `KLIPY_APP_KEY`)
  /// are in force: only when the operator chose no Connect (`off`, or
  /// `unset`, which behaves as off). With a hosted or custom Connect they are
  /// kept but inactive, so a leftover own app never overrides the Connect the
  /// operator picked. A workspace's own app is unaffected.
  Future<bool> serverOwnAppsActive() async =>
      !(await choice()).mode.usesConnect;

  static const _modeKey = 'connect_mode';
  static const _urlKey = 'connect_url';
  static const _epochKey = 'connect_hosted_epoch';
  static const _configKeyPrefix = 'connect_config_cache:';
  static const _pinsKeyPrefix = 'connect_pins:';
  static const _pendingPinsKeyPrefix = 'connect_pins_pending:';

  /// The secrets-file key of the 32-byte master install seed.
  static const String installKeySecret = 'connect_install_key';

  /// The environment override: `hosted`, `off`, or an `https://` URL.
  static const String environmentKey = 'CC_CONNECT_URL';

  /// The effective choice. Never throws: an unusable `CC_CONNECT_URL` reads
  /// as Connect off (see [checkEnvironment]).
  Future<ConnectChoice> choice() async {
    final pinned = _pinned;
    if (pinned != null) {
      return pinned;
    }
    final mode = ConnectMode.fromWire(await _read(_modeKey));
    switch (mode) {
      case ConnectMode.hosted:
        return const ConnectChoice(
          mode: ConnectMode.hosted,
          baseUrl: hostedConnectOrigin,
          lockedByEnvironment: false,
        );
      case ConnectMode.custom:
        final url = await _read(_urlKey) ?? '';
        return ConnectChoice(
          mode: url.isEmpty ? ConnectMode.off : ConnectMode.custom,
          baseUrl: url.isEmpty ? '' : canonicalConnectBaseUrl(url),
          lockedByEnvironment: false,
        );
      case ConnectMode.off || ConnectMode.unset:
        return ConnectChoice(
          mode: mode,
          baseUrl: '',
          lockedByEnvironment: false,
        );
    }
  }

  /// Stores the owner's choice. Throws [ValidationException] when the
  /// environment locks it or a custom URL is not acceptable.
  Future<ConnectChoice> setChoice(ConnectMode mode, {String url = ''}) async {
    if ((_environment[environmentKey]?.trim() ?? '').isNotEmpty) {
      throw const ValidationException(
        'CC_CONNECT_URL is set on this server, so Connect is configured by '
        'its environment.',
      );
    }
    switch (mode) {
      case ConnectMode.custom:
        final checked = _checkedUrl(url);
        if (_isHosted(checked)) {
          await _write(_modeKey, ConnectMode.hosted.name);
          await _delete(_urlKey);
        } else {
          await _write(_modeKey, mode.name);
          await _write(_urlKey, checked);
        }
      case ConnectMode.hosted || ConnectMode.off || ConnectMode.unset:
        await _write(_modeKey, mode.name);
        await _delete(_urlKey);
    }
    await _settled();
    return choice();
  }

  /// The 32-byte master seed, minted on first use. The read and the mint
  /// run under one lock, so two first calls agree on one seed instead of the
  /// later write silently replacing the identity the earlier one derived.
  Future<List<int>> installSeed() => _withSeedLock(_readOrMintSeed);

  Future<List<int>> _readOrMintSeed() async {
    final stored = await _secrets.readPsk(installKeySecret);
    if (stored != null && stored.isNotEmpty) {
      try {
        final bytes = unb64url(stored);
        if (bytes.length == 32) {
          return bytes;
        }
      } on FormatException {
        // Corrupt: mint a new one below. Every seal becomes needs_sign_in,
        // which is the honest outcome for a server whose identity is gone.
      }
    }
    final seed = ConnectInstallIdentity.newMasterSeed();
    await _secrets.writePsk(installKeySecret, b64url(seed));
    // This process minted it: not a change from elsewhere, and nothing
    // derived from a seed that did not exist needs dropping.
    if (_observed != null) {
      _observed = await _fingerprint();
    }
    return seed;
  }

  /// Replaces the master seed [old] with a new one. This server stops
  /// presenting every seal made for the old install id (each reads as
  /// "sign in again" here), and listeners run, so nothing keeps signing with
  /// the old identity. That alone does not stop the old key or its seals at
  /// a Connect: only a retire there does.
  ///
  /// Only `InstallKeyRotation.rotate` calls it, once each Connect the old
  /// seed holds seals at has retired that identity. Throws
  /// [StateError] when the stored seed is no longer [old] (rotated
  /// meanwhile, here or by `cc_server connect`), so a retirement never
  /// stands for a seed it did not cover.
  Future<void> replaceInstallSeed(List<int> old) async {
    await _withSeedLock(() async {
      final stored = await _secrets.readPsk(installKeySecret);
      if (stored != b64url(old)) {
        throw StateError('The install key changed while it was rotated.');
      }
      await _secrets.writePsk(
        installKeySecret,
        b64url(ConnectInstallIdentity.newMasterSeed()),
      );
    });
    await _settled();
  }

  /// Every Connect this server holds an identity towards: the server's own
  /// choice and each workspace's hosted or custom Connect ([workspaceList]),
  /// one per base URL (the identity is derived per base URL).
  Future<List<ConnectTarget>> connectTargets() async {
    final serverRoute = await routeFor(null);
    final byBase = <String, ConnectTarget>{};
    void add(ConnectTarget target) {
      if (target.enabled) {
        byBase.putIfAbsent(target.baseUrl, () => target);
      }
    }

    add(serverRoute.target);
    for (final workspace in await workspaceList?.call() ?? const []) {
      add(routeOf(workspace, serverRoute).target);
    }
    return [...byBase.values];
  }

  /// The highest hosted config epoch this server has accepted.
  Future<int> hostedEpoch() async =>
      int.tryParse(await _read(_epochKey) ?? '') ?? 0;

  /// Raises the hosted epoch high-water mark (never lowers it).
  Future<void> recordHostedEpoch(int epoch) async {
    if (epoch > await hostedEpoch()) {
      await _write(_epochKey, '$epoch');
    }
  }

  /// Where [target]'s keys live: the server's under the base URL, a
  /// workspace's under its id and the base URL. Base URLs start with a
  /// scheme, so the two never collide.
  static String _scoped(ConnectTarget target) => target.pinScope.isEmpty
      ? target.baseUrl
      : '$_workspaceScope${target.pinScope}:${target.baseUrl}';

  static const _workspaceScope = 'ws:';

  /// The last verified config for [target], for outages. It never holds a
  /// key-mode Klipy app key ([cacheConfig]), so a cached key-mode lane does
  /// not parse and GIF search waits for Connect.
  Future<Map<String, Object?>?> cachedConfig(ConnectTarget target) async {
    final raw = await _read('$_configKeyPrefix${_scoped(target)}');
    if (raw == null) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return decoded;
  }

  /// Caches a verified config for [target]. A key-mode Klipy app key is a
  /// rotatable Connect secret no client needs: it is never written anywhere
  /// (server settings are backed up and exported; the secrets file outlives
  /// a rotation). `ConnectClient` keeps it in memory only.
  Future<void> cacheConfig(
    ConnectTarget target,
    Map<String, Object?> json,
  ) async {
    final cached = {...json};
    final klipy = cached['klipy'];
    if (klipy is Map) {
      cached['klipy'] = {...klipy}..remove('app_key');
    }
    await _write('$_configKeyPrefix${_scoped(target)}', jsonEncode(cached));
  }

  /// The identifiers pinned on first use of a self-hosted Connect, in
  /// [target]'s trust store.
  Future<Map<String, String>?> pins(ConnectTarget target) =>
      _readMap('$_pinsKeyPrefix${_scoped(target)}');

  /// Pins [identifiers] for [target] and clears any pending change.
  Future<void> setPins(
    ConnectTarget target,
    Map<String, String> identifiers,
  ) async {
    await _write('$_pinsKeyPrefix${_scoped(target)}', jsonEncode(identifiers));
    await _delete('$_pendingPinsKeyPrefix${_scoped(target)}');
  }

  /// A changed identifier set awaiting confirmation (the server owner's for
  /// the server's trust store, a workspace admin's for a workspace's).
  Future<Map<String, String>?> pendingPins(ConnectTarget target) =>
      _readMap('$_pendingPinsKeyPrefix${_scoped(target)}');

  /// Records a changed identifier set for [target] to confirm.
  Future<void> setPendingPins(ConnectTarget target, Map<String, String> ids) =>
      _write('$_pendingPinsKeyPrefix${_scoped(target)}', jsonEncode(ids));

  /// Deletes every pin, pending pin and cached config [workspaceId]'s own
  /// Connect left (the workspace was deleted). The server's and other
  /// workspaces' trust stores are untouched.
  Future<int> deleteWorkspaceTrust(String workspaceId) async {
    final scope = '$_workspaceScope$workspaceId:';
    bool mine(String key) => [
      _configKeyPrefix,
      _pinsKeyPrefix,
      _pendingPinsKeyPrefix,
    ].any((prefix) => key.startsWith('$prefix$scope'));
    final dao = _settings;
    final keys = dao == null
        ? [..._memory.keys.where(mine)]
        : [
            for (final row in await dao.getAll())
              if (mine(row.key)) row.key,
          ];
    for (final key in keys) {
      await _delete(key);
    }
    return keys.length;
  }

  Future<Map<String, String>?> _readMap(String key) async {
    final raw = await _read(key);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } on FormatException {
      return null;
    }
  }

  static bool _isHosted(String url) {
    try {
      return canonicalConnectBaseUrl(url) == hostedConnectOrigin;
    } on FormatException {
      return false;
    }
  }

  /// A self-hosted Connect must be HTTPS, except on loopback.
  static String _checkedUrl(String url) {
    final String base;
    try {
      base = canonicalConnectBaseUrl(url);
    } on FormatException {
      throw const ValidationException('Enter the Connect server URL.');
    }
    if (base.startsWith('http://') && !isLoopbackOrigin(base)) {
      throw const ValidationException(
        'A Connect server must use HTTPS (plain HTTP is accepted only on '
        'this machine).',
      );
    }
    return base;
  }

  Future<String?> _read(String key) async {
    final dao = _settings;
    final value = dao == null ? _memory[key] : await dao.getValue(key);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _write(String key, String value) async {
    final dao = _settings;
    if (dao == null) {
      _memory[key] = value;
      return;
    }
    await dao.setValue(key, value);
  }

  Future<void> _delete(String key) async {
    final dao = _settings;
    if (dao == null) {
      _memory.remove(key);
      return;
    }
    await dao.deleteValue(key);
  }
}
