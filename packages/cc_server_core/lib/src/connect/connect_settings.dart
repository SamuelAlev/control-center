import 'dart:convert';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_persistence/cc_persistence.dart' show ServerSettingDao;
import 'package:cc_server_core/src/file_secrets_store.dart';

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
      'cc_server: refusing to start — CC_CONNECT_URL is not usable: $reason '
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

  /// The environment override, parsed once: null when `CC_CONNECT_URL` is
  /// unset, Connect off (locked) when it is unusable.
  late final ConnectChoice? _pinned = _parseEnvironment(_environment).$1;

  /// The last `mode|url|seed` observed, so a change made by another process
  /// (`cc_server connect`) is noticed. Null until first observed.
  String? _observed;

  /// Serializes the seed's read-then-write.
  Future<void> _seedLock = Future<void>.value();

  /// Runs [listener] after anything that changes which Connect or install
  /// identity lanes use: [setChoice], [rotateInstallSeed], or such a change
  /// made outside this process and noticed by [noticeExternalChanges].
  /// Callers drop what they cached.
  void addListener(void Function() listener) => _listeners.add(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

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
  /// since this process last looked: `cc_server connect enable | disable |
  /// rotate-key` writes the same data directory from another process, and
  /// nothing else would tell a running server's caches. Cheap (two setting
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
  static const _klipyKeySecretPrefix = 'connect_klipy_key:';

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

  /// Replaces the master seed. Every Connect grant this server holds stops
  /// working (its seals are bound to the old install id). Listeners run, so
  /// nothing keeps signing with the old identity.
  Future<void> rotateInstallSeed() async {
    await _withSeedLock(
      () => _secrets.writePsk(
        installKeySecret,
        b64url(ConnectInstallIdentity.newMasterSeed()),
      ),
    );
    await _settled();
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

  /// The last verified config for [baseUrl], for outages. It never holds a
  /// key-mode Klipy app key ([cacheConfig]), so a cached key-mode lane does
  /// not parse and GIF search waits for Connect.
  Future<Map<String, Object?>?> cachedConfig(String baseUrl) async {
    final raw = await _read('$_configKeyPrefix$baseUrl');
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

  /// Caches a verified config for [baseUrl]. A key-mode Klipy app key is a
  /// rotatable Connect secret no client needs: it is never written anywhere
  /// (server settings are backed up and exported; the secrets file outlives
  /// a rotation). `ConnectClient` keeps it in memory only. A copy an older
  /// build left in the secrets store is deleted here.
  Future<void> cacheConfig(String baseUrl, Map<String, Object?> json) async {
    final cached = {...json};
    final klipy = cached['klipy'];
    if (klipy is Map) {
      cached['klipy'] = {...klipy}..remove('app_key');
    }
    final legacy = '$_klipyKeySecretPrefix$baseUrl';
    if (await _secrets.readPsk(legacy) != null) {
      await _secrets.deletePsk(legacy);
    }
    await _write('$_configKeyPrefix$baseUrl', jsonEncode(cached));
  }

  /// The identifiers pinned on first use of a self-hosted Connect.
  Future<Map<String, String>?> pins(String baseUrl) =>
      _readMap('$_pinsKeyPrefix$baseUrl');

  /// Pins [identifiers] for [baseUrl] and clears any pending change.
  Future<void> setPins(String baseUrl, Map<String, String> identifiers) async {
    await _write('$_pinsKeyPrefix$baseUrl', jsonEncode(identifiers));
    await _delete('$_pendingPinsKeyPrefix$baseUrl');
  }

  /// A changed identifier set awaiting the owner's confirmation.
  Future<Map<String, String>?> pendingPins(String baseUrl) =>
      _readMap('$_pendingPinsKeyPrefix$baseUrl');

  /// Records a changed identifier set for the owner to confirm.
  Future<void> setPendingPins(String baseUrl, Map<String, String> ids) =>
      _write('$_pendingPinsKeyPrefix$baseUrl', jsonEncode(ids));

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
