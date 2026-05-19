import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/connection/server_descriptor_service.dart';
import 'package:cc_server_core/src/relay/remote_relay_host.dart';

void _i(String m) => CcHostLog.info('NetworkRuntime: $m');
void _w(String m) => CcHostLog.warning('NetworkRuntime: $m');

/// The server's network-facing runtime state (PRD 15 §5/§7): the mDNS LAN
/// advertisement, the supervised "Share this server" tunnel and relay-usage
/// accounting — plus the `connectivity.*` op surface that controls them.
///
/// The tunnel provider chosen at runtime (the share flow) is persisted to
/// `<dataDir>/network_config.json`, so a restart resumes sharing; the
/// `--tunnel` flag/env seeds the first boot. Public exposure is explicit
/// opt-in — `off` is the default and the only silent state.
class NetworkRuntime {
  /// Creates the runtime. Call [start].
  NetworkRuntime({
    required this.config,
    required this.descriptorService,
    required this.boundPort,
    RemoteRelayHost? relayHost,
  }) : _relayHost = relayHost;

  /// Server config (flags/env defaults).
  final CcServerConfig config;

  /// The descriptor service tunnels publish their paths into.
  final ServerDescriptorService descriptorService;

  /// The RPC server's actually-bound port.
  final int boundPort;

  final RemoteRelayHost? _relayHost;

  CcMdnsResponder? _mdns;
  TunnelManager? _tunnel;
  String _tunnelProvider = 'off';
  Timer? _usageFlushTimer;
  int _persistedRelayChars = 0;
  String _usageMonth = '';

  File get _networkConfigFile => File('${config.dataDir}/network_config.json');

  File get _relayUsageFile => File('${config.dataDir}/relay_usage.json');

  /// Starts mDNS (per config) and resumes the persisted tunnel choice.
  Future<void> start() async {
    if (config.mdnsEnabled) {
      await _startMdns();
    }
    _loadRelayUsage();
    _usageFlushTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _flushRelayUsage(),
    );
    final persisted = _loadPersistedProvider();
    final provider = persisted ?? config.tunnelProvider;
    if (provider != 'off') {
      await _startTunnel(provider);
    }
  }

  Future<void> _startMdns() async {
    try {
      final responder = CcMdnsResponder(
        instanceName: descriptorService.identity.serverName,
        port: boundPort,
        txt: {
          'sid': descriptorService.identity.serverId,
          'fp': descriptorService.identity.fingerprint.substring(0, 16),
          'name': descriptorService.identity.serverName,
          'tls': config.tlsConfigured ? '1' : '0',
        },
        log: _i,
      );
      await responder.start();
      _mdns = responder;
      _i('advertising on mDNS as "${descriptorService.identity.serverName}"');
    } catch (e) {
      // mDNS is best-effort (port 5353 may be taken by an OS daemon that
      // doesn't share) — discovery degrades, direct paths still work.
      _w('mDNS responder failed to start: $e');
    }
  }

  String? _loadPersistedProvider() {
    try {
      if (!_networkConfigFile.existsSync()) {
        return null;
      }
      final decoded = jsonDecode(_networkConfigFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        final p = decoded['tunnel_provider'];
        if (p is String && p.isNotEmpty) {
          return p;
        }
      }
    } catch (_) {}
    return null;
  }

  void _persistProvider(String provider) {
    try {
      _networkConfigFile.writeAsStringSync(
        jsonEncode({'tunnel_provider': provider}),
      );
    } catch (e) {
      _w('could not persist network config: $e');
    }
  }

  Future<void> _startTunnel(String provider) async {
    final parsed = TunnelProvider.values.asNameMap()[provider];
    if (parsed == null) {
      _w('unknown tunnel provider "$provider"');
      return;
    }
    await _stopTunnel();
    final manager = TunnelManager(
      provider: parsed,
      localPort: boundPort,
      binaryPath: config.tunnelBinaryPath,
      expectedSha256: config.tunnelBinarySha256,
      extraArgs: config.tunnelExtraArgs,
      log: _i,
      onAddress: _onTunnelAddress,
    );
    _tunnel = manager;
    _tunnelProvider = provider;
    await manager.start();
  }

  void _onTunnelAddress(TunnelAddress? address) {
    if (address == null) {
      descriptorService.setTunnelPath(null);
      return;
    }
    final url = address.publicUrl;
    if (url.startsWith('tailnet://')) {
      final u = Uri.parse(url.replaceFirst('tailnet://', 'https://'));
      descriptorService.setTunnelPath(
        TailnetPath(
          host: u.host,
          port: u.hasPort ? u.port : boundPort,
          tls: config.tlsConfigured,
        ),
      );
      _i('tailnet path published: ${u.host}');
      return;
    }
    final u = Uri.tryParse(url);
    if (u == null || u.host.isEmpty) {
      return;
    }
    final wss = Uri(
      scheme: 'wss',
      host: u.host,
      port: u.hasPort ? u.port : null,
    ).toString();
    descriptorService.setTunnelPath(WssPath(uri: wss), httpBase: url);
    _i('tunnel path published: $url');
  }

  Future<void> _stopTunnel() async {
    final tunnel = _tunnel;
    _tunnel = null;
    _tunnelProvider = 'off';
    descriptorService.setTunnelPath(null);
    await tunnel?.stop();
  }

  /// Sets (and persists) the share-this-server tunnel provider at runtime —
  /// the explicit public-exposure opt-in. `off` stops sharing.
  Future<Map<String, dynamic>> setTunnelProvider(String provider) async {
    if (provider == 'off') {
      await _stopTunnel();
    } else {
      await _startTunnel(provider);
    }
    _persistProvider(provider);
    return status();
  }

  // --- Relay usage accounting (bytes/month, PRD 15 adversarial note) ---

  String get _currentMonth {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _loadRelayUsage() {
    _usageMonth = _currentMonth;
    try {
      if (!_relayUsageFile.existsSync()) {
        return;
      }
      final decoded = jsonDecode(_relayUsageFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        final v = decoded[_usageMonth];
        if (v is num) {
          _persistedRelayChars = v.toInt();
        }
      }
    } catch (_) {}
  }

  void _flushRelayUsage() {
    final host = _relayHost;
    if (host == null) {
      return;
    }
    final month = _currentMonth;
    if (month != _usageMonth) {
      // Month rolled over: prior months stay in the file; live counters keep
      // accumulating (per-month precision is enough for a bandwidth surprise
      // check, not billing).
      _usageMonth = month;
      _persistedRelayChars = 0;
    }
    try {
      Map<String, dynamic> all = {};
      if (_relayUsageFile.existsSync()) {
        final decoded = jsonDecode(_relayUsageFile.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          all = decoded;
        }
      }
      all[_usageMonth] = _persistedRelayChars + host.relayedChars;
      _relayUsageFile.writeAsStringSync(jsonEncode(all));
    } catch (_) {}
  }

  /// Relayed characters (~bytes) this month, live + persisted.
  int get relayCharsThisMonth =>
      _persistedRelayChars + (_relayHost?.relayedChars ?? 0);

  /// The `connectivity.status` wire shape.
  Map<String, dynamic> status() => {
    'mdns': _mdns != null,
    'tunnel_provider': _tunnelProvider,
    'tunnel': _tunnel?.status.toWire(),
    'relay': {
      'connected': _relayHost?.isConnected ?? false,
      'sessions': _relayHost?.sessionCount ?? 0,
      'chars_this_month': relayCharsThisMonth,
    },
  };

  /// Stops everything (goodbye packets, tunnel child, usage flush).
  Future<void> stop() async {
    _usageFlushTimer?.cancel();
    _usageFlushTimer = null;
    _flushRelayUsage();
    await _stopTunnel();
    await _mdns?.stop();
    _mdns = null;
  }
}
