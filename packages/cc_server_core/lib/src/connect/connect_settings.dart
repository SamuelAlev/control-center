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

  /// Runs [listener] after every [setChoice]: which lanes the server's own
  /// apps answer for may have changed, so callers drop what they cached.
  void addListener(void Function() listener) => _listeners.add(listener);

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

  /// The effective choice.
  Future<ConnectChoice> choice() async {
    final override = _environment[environmentKey]?.trim() ?? '';
    if (override.isNotEmpty) {
      return switch (override.toLowerCase()) {
        'off' => const ConnectChoice(
          mode: ConnectMode.off,
          baseUrl: '',
          lockedByEnvironment: true,
        ),
        'hosted' => const ConnectChoice(
          mode: ConnectMode.hosted,
          baseUrl: hostedConnectOrigin,
          lockedByEnvironment: true,
        ),
        _ => ConnectChoice(
          mode: _isHosted(override) ? ConnectMode.hosted : ConnectMode.custom,
          baseUrl: _checkedUrl(override),
          lockedByEnvironment: true,
        ),
      };
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
    for (final listener in List.of(_listeners)) {
      listener();
    }
    return choice();
  }

  /// The 32-byte master seed, minted on first use.
  Future<List<int>> installSeed() async {
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
    return seed;
  }

  /// Replaces the master seed. Every Connect grant this server holds stops
  /// working (its seals are bound to the old install id).
  Future<void> rotateInstallSeed() async {
    await _secrets.writePsk(
      installKeySecret,
      b64url(ConnectInstallIdentity.newMasterSeed()),
    );
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

  /// The last verified config for [baseUrl], for outages, with a key-mode
  /// Klipy app key put back from the secrets store.
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
    final klipy = decoded['klipy'];
    final key = await _secrets.readPsk('$_klipyKeySecretPrefix$baseUrl');
    if (klipy is Map && key != null && key.isNotEmpty) {
      decoded['klipy'] = {...klipy, 'app_key': key};
    }
    return decoded;
  }

  /// Caches a verified config for [baseUrl]. A key-mode Klipy app key is a
  /// secret: it goes to the secrets store, never into server settings (which
  /// are backed up and exported).
  Future<void> cacheConfig(String baseUrl, Map<String, Object?> json) async {
    final cached = {...json};
    final klipy = cached['klipy'];
    final secretKey = '$_klipyKeySecretPrefix$baseUrl';
    final key = klipy is Map ? klipy['app_key'] : null;
    final stored = await _secrets.readPsk(secretKey);
    if (key is String && key.isNotEmpty) {
      cached['klipy'] = {...(klipy as Map)}..remove('app_key');
      if (stored != key) {
        await _secrets.writePsk(secretKey, key);
      }
    } else if (stored != null) {
      await _secrets.deletePsk(secretKey);
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
