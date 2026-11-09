import 'package:cc_rpc/cc_rpc.dart';

/// How this server reaches Control Center Connect.
enum ConnectModeSetting {
  /// Never chosen. Lanes without an own app sign nobody in.
  unset,

  /// Control Center's hosted Connect.
  hosted,

  /// A Connect at an operator-supplied HTTPS URL.
  custom,

  /// Connect is off; only own apps sign people in.
  off;

  /// Parses a wire value; [unset] for anything unknown.
  static ConnectModeSetting fromWire(Object? wire) {
    for (final mode in values) {
      if (mode.name == wire) {
        return mode;
      }
    }
    return unset;
  }

  /// The wire spelling.
  String get wire => name;
}

/// Why Connect is not usable right now. [none] when it is fine.
enum ConnectHealthError {
  /// Healthy.
  none(''),

  /// The hosted service has no apps for this build yet.
  hostedUnprovisioned('hosted_unprovisioned'),

  /// The signed configuration did not verify.
  signature('signature'),

  /// The configuration is older than one already seen.
  rollback('rollback'),

  /// Connect did not answer.
  unreachable('unreachable'),

  /// Connect refuses this server.
  installBlocked('install_blocked'),

  /// Connect's signing keys changed and wait for the owner's confirmation.
  pinsChanged('pins_changed'),

  /// Connect speaks a protocol this server does not.
  protocol('protocol'),

  /// A code this client does not know.
  unknown('?');

  const ConnectHealthError(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; [none] for an empty one, [unknown] for others.
  static ConnectHealthError fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) {
      return none;
    }
    for (final error in values) {
      if (error.wire == wire) {
        return error;
      }
    }
    return unknown;
  }
}

/// Where one provider lane's credentials come from.
enum ConnectLaneSource {
  /// The server's own app or key.
  own,

  /// Control Center Connect.
  connect,

  /// Nothing; the lane is off.
  off;

  /// Parses a wire value; [off] for anything unknown.
  static ConnectLaneSource fromWire(Object? wire) => switch (wire) {
    'own' => own,
    'connect' => connect,
    _ => off,
  };
}

/// One lane in `connect.status`.
class ConnectLaneStatus {
  /// Creates a [ConnectLaneStatus].
  const ConnectLaneStatus({
    required this.lane,
    required this.source,
    this.error = '',
  });

  /// Decodes one entry.
  factory ConnectLaneStatus.fromJson(Map<String, dynamic> json) =>
      ConnectLaneStatus(
        lane: json['lane'] as String? ?? '',
        source: ConnectLaneSource.fromWire(json['source']),
        error: json['error'] as String? ?? '',
      );

  /// The lane's wire id (`github`, `google`, `linear`, `slack`, `klipy`).
  final String lane;

  /// Where its credentials come from.
  final ConnectLaneSource source;

  /// Why it does not work, already phrased for a person.
  final String error;
}

/// `connect.status`: this server's Connect configuration and health.
class ConnectStatus {
  /// Creates a [ConnectStatus].
  const ConnectStatus({
    required this.mode,
    this.url = '',
    this.locked = false,
    this.installId = '',
    this.usable = false,
    this.error = ConnectHealthError.none,
    this.stale = false,
    this.pendingPins,
    this.epoch,
    this.lanes = const [],
  });

  /// Decodes a status payload.
  factory ConnectStatus.fromJson(Map<String, dynamic> json) {
    final pins = json['pending_pins'];
    return ConnectStatus(
      mode: ConnectModeSetting.fromWire(json['mode']),
      url: json['url'] as String? ?? '',
      locked: json['locked'] as bool? ?? false,
      installId: json['install_id'] as String? ?? '',
      usable: json['usable'] as bool? ?? false,
      error: ConnectHealthError.fromWire(json['error']),
      stale: json['stale'] as bool? ?? false,
      pendingPins: pins is Map
          ? {for (final e in pins.entries) '${e.key}': '${e.value}'}
          : null,
      epoch: (json['epoch'] as num?)?.toInt(),
      lanes: [
        for (final entry
            in (json['lanes'] as List? ?? const []).whereType<Map>())
          ConnectLaneStatus.fromJson(entry.cast<String, dynamic>()),
      ],
    );
  }

  /// The configured mode.
  final ConnectModeSetting mode;

  /// The Connect base URL in use (empty when off or unset).
  final String url;

  /// Whether `CC_CONNECT_URL` pins the configuration, so it cannot be
  /// changed here.
  final bool locked;

  /// This server's install id on that Connect.
  final String installId;

  /// Whether Connect is answering with a verified configuration.
  final bool usable;

  /// Why it is not usable.
  final ConnectHealthError error;

  /// Whether the configuration in use is a cached copy past its refresh.
  final bool stale;

  /// New signing pins waiting for the owner's confirmation, or null.
  final Map<String, String>? pendingPins;

  /// The configuration epoch in use, or null before the first fetch.
  final int? epoch;

  /// Every lane's source.
  final List<ConnectLaneStatus> lanes;
}

/// The owner-only `connect.*` ops.
class RemoteConnectSettings {
  /// Creates a [RemoteConnectSettings] over [_client].
  RemoteConnectSettings(this._client);

  final RemoteRpcClient _client;

  /// The current configuration and health.
  Future<ConnectStatus> status() async =>
      ConnectStatus.fromJson(await _client.call('connect.status', const {}));

  /// Switches to [mode]; [url] is required for [ConnectModeSetting.custom].
  Future<ConnectStatus> configure(
    ConnectModeSetting mode, {
    String? url,
  }) async => ConnectStatus.fromJson(
    await _client.call('connect.configure', {'mode': mode.wire, 'url': ?url}),
  );

  /// Forces a configuration refresh and reports the result.
  Future<ConnectStatus> test() async =>
      ConnectStatus.fromJson(await _client.call('connect.test', const {}));

  /// Accepts the pending signing pins.
  Future<ConnectStatus> confirmPins() async => ConnectStatus.fromJson(
    await _client.call('connect.confirmPins', const {}),
  );

  /// Mints a new install key. Every Connect sign-in must be redone.
  Future<ConnectStatus> rotateKey() async =>
      ConnectStatus.fromJson(await _client.call('connect.rotateKey', const {}));
}
