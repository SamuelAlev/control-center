import 'dart:convert';

import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/remote_control/data/repositories/paired_device_secrets_repository.dart'
    show PairedDeviceSecretsRepository;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted configuration for the remote-control transport.
///
/// **No secrets here** — the PSK per paired device lives in the platform secure
/// store ([PairedDeviceSecretsRepository]). These are operator settings: the
/// signaling broker URL, STUN servers, the hosted PWA origin (encoded into the
/// pairing QR), and whether the listener auto-starts on launch.
///
/// The signaling URL and PWA host default to the hosted Control Center services
/// ([PairingPayload.defaultSignalingUrl] / [PairingPayload.defaultPwaHost]) so
/// pairing works out of the box; the operator can override either in settings
/// (including self-hosted origins).
class RemoteControlConfig {
  /// Creates a [RemoteControlConfig].
  const RemoteControlConfig({
    this.enabled = false,
    this.signalingUrl = PairingPayload.defaultSignalingUrl,
    this.stunUrls = defaultStunUrls,
    this.pwaHost = PairingPayload.defaultPwaHost,
    this.wsServeEnabled = false,
    this.wsServePort = 9030,
  });

  /// Default public STUN servers (no TURN, by design).
  static const defaultStunUrls = <String>[
    'stun:stun.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
  ];

  /// Whether the listener auto-starts on app launch.
  final bool enabled;

  /// Signaling broker WebSocket URL (`wss://…`).
  final String signalingUrl;

  /// STUN server URLs.
  final List<String> stunUrls;

  /// Hosted PWA origin encoded into the pairing QR (`remote.example.com`).
  final String pwaHost;

  /// Whether the desktop also runs the WSS `LocalRpcServer` ("act as server"),
  /// letting clients on the LAN / same machine connect directly over WebSocket
  /// instead of via the WebRTC broker. Loopback bind; opt-in.
  final bool wsServeEnabled;

  /// TCP port for the WSS `LocalRpcServer` when [wsServeEnabled].
  final int wsServePort;

  /// Whether the bare minimum (a broker URL) is configured.
  bool get isConfigured =>
      signalingUrl.isNotEmpty && stunUrls.isNotEmpty && pwaHost.isNotEmpty;

  RemoteControlConfig copyWith({
    bool? enabled,
    String? signalingUrl,
    List<String>? stunUrls,
    String? pwaHost,
    bool? wsServeEnabled,
    int? wsServePort,
  }) {
    return RemoteControlConfig(
      enabled: enabled ?? this.enabled,
      signalingUrl: signalingUrl ?? this.signalingUrl,
      stunUrls: stunUrls ?? this.stunUrls,
      pwaHost: pwaHost ?? this.pwaHost,
      wsServeEnabled: wsServeEnabled ?? this.wsServeEnabled,
      wsServePort: wsServePort ?? this.wsServePort,
    );
  }
}

/// Provider for [RemoteControlConfig], backed by [AppPreferences].
final remoteControlConfigProvider =
    NotifierProvider<RemoteControlConfigNotifier, RemoteControlConfig>(
      RemoteControlConfigNotifier.new,
    );

/// Manages [RemoteControlConfig] state, persisted to [AppPreferences].
class RemoteControlConfigNotifier extends Notifier<RemoteControlConfig> {
  static const _enabledKey = 'remote_control_enabled';
  static const _signalingUrlKey = 'remote_control_signaling_url';
  static const _stunUrlsKey = 'remote_control_stun_urls';
  static const _pwaHostKey = 'remote_control_pwa_host';
  static const _wsServeEnabledKey = 'remote_control_ws_serve_enabled';
  static const _wsServePortKey = 'remote_control_ws_serve_port';

  late AppPreferences _prefs;

  @override
  RemoteControlConfig build() {
    _prefs = ref.read(appPreferencesProvider);
    return RemoteControlConfig(
      enabled: _prefs.getBool(_enabledKey) ?? false,
      signalingUrl:
          _prefs.getString(_signalingUrlKey) ??
          PairingPayload.defaultSignalingUrl,
      stunUrls: _readStunUrls(),
      pwaHost: _prefs.getString(_pwaHostKey) ?? PairingPayload.defaultPwaHost,
      wsServeEnabled: _prefs.getBool(_wsServeEnabledKey) ?? false,
      wsServePort: _prefs.getInt(_wsServePortKey) ?? 9030,
    );
  }

  List<String> _readStunUrls() {
    final raw = _prefs.getString(_stunUrlsKey);
    if (raw == null || raw.isEmpty) {
      return RemoteControlConfig.defaultStunUrls;
    }
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Fall through to default.
    }
    return RemoteControlConfig.defaultStunUrls;
  }

  Future<void> setEnabled({required bool enabled}) async {
    await _prefs.setBool(_enabledKey, enabled);
    state = state.copyWith(enabled: enabled);
  }

  /// Sets the signaling broker URL.
  Future<void> setSignalingUrl(String url) async {
    await _prefs.setString(_signalingUrlKey, url);
    state = state.copyWith(signalingUrl: url);
  }

  /// Sets the STUN server URLs.
  Future<void> setStunUrls(List<String> urls) async {
    await _prefs.setString(_stunUrlsKey, jsonEncode(urls));
    state = state.copyWith(stunUrls: urls);
  }

  /// Sets the hosted PWA origin (encoded into the pairing QR).
  Future<void> setPwaHost(String host) async {
    await _prefs.setString(_pwaHostKey, host);
    state = state.copyWith(pwaHost: host);
  }

  /// Toggles the WSS "act as server" listener.
  Future<void> setWsServeEnabled({required bool enabled}) async {
    await _prefs.setBool(_wsServeEnabledKey, enabled);
    state = state.copyWith(wsServeEnabled: enabled);
  }

  /// Sets the WSS server port.
  Future<void> setWsServePort(int port) async {
    await _prefs.setInt(_wsServePortKey, port);
    state = state.copyWith(wsServePort: port);
  }
}
