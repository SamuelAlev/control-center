import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/connection_descriptor.dart';
import 'package:cc_rpc/src/channel/relay_client_channel.dart';
import 'package:cc_rpc/src/channel/ws_client_channel.dart';
import 'package:cc_rpc/src/client/remote_channel_auth.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';
import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:http/http.dart' as http;

/// Whether this build has `dart:io` (false on web). A web client can dial TLS
/// socket paths, the broker relay and loopback (potentially trustworthy in
/// every browser); it cannot dial plaintext LAN addresses, which are mixed
/// content unless the page itself was served over plaintext.
const bool _hasIo = bool.fromEnvironment('dart.library.io');

/// The outcome of probing one [ConnectionPath].
class PathProbeResult {
  /// Creates a [PathProbeResult].
  const PathProbeResult({
    required this.path,
    required this.reachable,
    this.latency,
    this.serverId,
    this.detail,
  });

  /// The probed path.
  final ConnectionPath path;

  /// Whether the path answered as this server within the probe timeout.
  final bool reachable;

  /// Round-trip latency of the successful probe.
  final Duration? latency;

  /// The server id the endpoint reported (null for relay probes, which
  /// verify by admission instead).
  final String? serverId;

  /// Failure detail for diagnostics (never secrets).
  final String? detail;
}

/// A live, authenticated connection produced by [ReachabilityResolver.connect].
class ResolvedConnection {
  /// Creates a [ResolvedConnection].
  const ResolvedConnection({
    required this.client,
    required this.path,
    required this.latency,
    required this.serverFingerprint,
  });

  /// The started, initialized RPC client.
  final RemoteRpcClient client;

  /// The path that won.
  final ConnectionPath path;

  /// Probe latency of the winning path.
  final Duration latency;

  /// The server's verified identity fingerprint (TOFU pin source).
  final String serverFingerprint;

  /// Whether the winning path relays through a broker rather than reaching
  /// the server directly (drives the "relayed" indicator).
  bool get relayed => !path.isDirect;
}

/// Probes every path in a [ConnectionDescriptor] in parallel and connects the
/// best *reachable + secure* one (PRD 15 §1).
///
/// Ranking is fixed: loopback > LAN > tailnet > wss(TLS) > relay. Probing is
/// concurrent with a per-path timeout (~2s); the resolver holds no state —
/// hysteresis and failover live in `ServerConnectionSupervisor`, which calls
/// [connect] once per (re)connect so path *upgrades* only happen on a natural
/// reconnect, never mid-session.
class ReachabilityResolver {
  /// Creates a resolver. [probeTimeout] bounds each path probe; the HTTP
  /// client factory is injectable for tests. [isWebPlatform] and
  /// [pageOriginFactory] are injectable so the web path filter can be
  /// exercised from a native test runner; they default to the compile-time
  /// platform and [Uri.base].
  ReachabilityResolver({
    this.probeTimeout = const Duration(seconds: 2),
    http.Client Function()? httpClientFactory,
    bool? isWebPlatform,
    Uri Function()? pageOriginFactory,
  }) : _httpClientFactory = httpClientFactory ?? http.Client.new,
       _isWeb = isWebPlatform ?? !_hasIo,
       _pageOrigin = pageOriginFactory ?? (() => Uri.base);

  /// Per-path probe timeout.
  final Duration probeTimeout;

  final http.Client Function() _httpClientFactory;

  /// Whether this resolver behaves as a web client — web filters off-loopback
  /// plaintext paths, with a local-dev carve-out (see [usablePaths]).
  final bool _isWeb;

  /// The page's own origin, consulted only on web to admit off-loopback
  /// plaintext when the page is itself plaintext loopback (local dev).
  final Uri Function() _pageOrigin;

  /// The subset of [descriptor] paths this client can use at all, in rank
  /// order.
  ///
  /// On a native client every path is usable. On web the filter is about what
  /// the *browser* will dial at all and the two plaintext cases differ:
  ///
  /// - **Loopback is always kept**, whatever the page origin. Browsers treat
  ///   loopback as a potentially-trustworthy origin, so `ws://127.0.0.1` is
  ///   not mixed content even from a deployed `https://` page. Whether the
  ///   browser's loopback is *this server's* loopback is not guessed from the
  ///   page origin — it is decided by probing, because [probePath] compares
  ///   the `serverId` `/healthz` reports against [ConnectionDescriptor.serverId]
  ///   and refuses a stranger. Filtering on the page origin instead cost the
  ///   legitimate "deployed page, server on this same machine" case its only
  ///   path and did so silently (an empty probe set yields a
  ///   [NoReachablePathException] that names no reason).
  /// - **Off-loopback plaintext stays filtered** unless the page is itself
  ///   loopback: `ws://192.168.1.42` from an `https://` page is mixed content
  ///   with no exemption, so probing it can only ever burn the timeout.
  List<ConnectionPath> usablePaths(ConnectionDescriptor descriptor) {
    final pageIsLoopback =
        _isWeb && TransportSecurityPolicy.isLoopbackHost(_pageOrigin().host);
    final paths = descriptor.paths.where((p) {
      if (!_isWeb) {
        return true;
      }
      return switch (p) {
        WssPath() => true,
        RelayPath() => true,
        LanPath(:final tls) => tls || pageIsLoopback,
        TailnetPath(:final tls) => tls || pageIsLoopback,
        LoopbackPath() => true,
      };
    }).toList();
    paths.sort((a, b) => a.rank.compareTo(b.rank));
    return paths;
  }

  /// Probes every usable path concurrently. Results arrive in rank order.
  Future<List<PathProbeResult>> probeAll(
    ConnectionDescriptor descriptor, {
    required String psk,
  }) async {
    final paths = usablePaths(descriptor);
    return Future.wait(paths.map((p) => probePath(descriptor, p, psk: psk)));
  }

  /// Probes one path: `GET /healthz` for socket paths (validating the
  /// reported server id when the endpoint provides one), a broker
  /// join-with-admission for relay paths.
  Future<PathProbeResult> probePath(
    ConnectionDescriptor descriptor,
    ConnectionPath path, {
    required String psk,
  }) async {
    if (path is RelayPath) {
      final latency = await RelayClientChannel.probe(
        signalingUrl: path.signalingUrl,
        room: path.room,
        psk: psk,
        timeout: probeTimeout,
      );
      return PathProbeResult(
        path: path,
        reachable: latency != null,
        latency: latency,
        detail: latency == null ? 'relay probe failed' : null,
      );
    }
    final probeUri = path.probeUri;
    if (probeUri == null) {
      return PathProbeResult(path: path, reachable: false, detail: 'no probe');
    }
    if (!TransportSecurityPolicy.allows(
      probeUri,
      insecureAllowed: descriptor.insecureAllowed,
    )) {
      return PathProbeResult(
        path: path,
        reachable: false,
        detail: 'refused: plaintext off-loopback',
      );
    }
    final client = _httpClientFactory();
    final started = DateTime.now();
    try {
      final response = await client
          .get(probeUri.replace(path: '/healthz'))
          .timeout(probeTimeout);
      if (response.statusCode != 200) {
        return PathProbeResult(
          path: path,
          reachable: false,
          detail: 'healthz ${response.statusCode}',
        );
      }
      String? serverId;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          serverId = body['serverId'] as String?;
        }
      } catch (_) {
        // A non-JSON 200 still proves TCP+TLS reachability.
      }
      if (serverId != null &&
          serverId.isNotEmpty &&
          serverId != descriptor.serverId) {
        // The address answered, but as a DIFFERENT server — a moved LAN IP
        // or rebound name. Refuse at probe time; the identity handshake
        // would refuse at connect time anyway.
        return PathProbeResult(
          path: path,
          reachable: false,
          serverId: serverId,
          detail: 'different server at this address',
        );
      }
      return PathProbeResult(
        path: path,
        reachable: true,
        latency: DateTime.now().difference(started),
        serverId: serverId,
      );
    } catch (e) {
      return PathProbeResult(
        path: path,
        reachable: false,
        detail: e.toString(),
      );
    } finally {
      client.close();
    }
  }

  /// Probes all paths and connects the highest-ranked reachable one, running
  /// the PSK handshake + identity verification. Falls through to the next
  /// reachable path when the winner fails to connect (reachable ≠ healthy).
  ///
  /// Throws [ServerIdentityMismatchException] immediately (no fallback) when
  /// any path presents a wrong identity — a rebind is a hard stop, not a
  /// path-selection problem. Throws [NoReachablePathException] when nothing
  /// connects.
  Future<ResolvedConnection> connect(
    ConnectionDescriptor descriptor, {
    required String deviceId,
    required String psk,
    String? pinnedFingerprint,
  }) async {
    final probes = await probeAll(descriptor, psk: psk);
    final reachable = probes.where((p) => p.reachable).toList();
    final failures = <String>[
      for (final p in probes.where((p) => !p.reachable))
        '${p.path.toJson()['t']}: ${p.detail ?? 'unreachable'}',
    ];
    for (final probe in reachable) {
      final path = probe.path;
      try {
        final channel = switch (path) {
          RelayPath() => await RelayClientChannel.connect(
            signalingUrl: path.signalingUrl,
            room: path.room,
            deviceId: deviceId,
            psk: psk,
          ),
          _ => await WsClientChannel.connect(
            path.rpcUri!,
            insecureAllowed: descriptor.insecureAllowed,
          ),
        };
        final authed = await authenticateRemoteClient(
          channel: channel,
          deviceId: deviceId,
          psk: psk,
          pinnedFingerprint: pinnedFingerprint,
        );
        return ResolvedConnection(
          client: authed.client,
          path: path,
          latency: probe.latency ?? Duration.zero,
          serverFingerprint: authed.serverFingerprint,
        );
      } on ServerIdentityMismatchException {
        rethrow;
      } catch (e) {
        failures.add('${path.toJson()['t']}: connect failed: $e');
      }
    }
    throw NoReachablePathException(descriptor.serverId, failures);
  }
}

/// A server's public identity as reported by its `/healthz` endpoint —
/// what a manual "add server by URL" flow reads before pairing and what the
/// desktop reads from its spawned local server to detect a stale prebuilt
/// binary.
class ServerIdentityProbe {
  /// Creates a [ServerIdentityProbe].
  const ServerIdentityProbe({
    required this.serverId,
    required this.serverName,
    required this.fingerprint,
    required this.insecure,
    this.version,
    this.gitSha,
    this.catalogVersion,
  });

  /// The server's stable id.
  final String serverId;

  /// The server's display name.
  final String serverName;

  /// The identity fingerprint the client will pin on first connect.
  final String fingerprint;

  /// Whether the server runs with the `--insecure` escape hatch.
  final bool insecure;

  /// The server's build version, or null when it did not report one (a
  /// server older than the /healthz build-identity fields).
  final String? version;

  /// The server's build git sha, or null when absent.
  final String? gitSha;

  /// The repo-RPC op catalog version the server speaks, or null when absent.
  final int? catalogVersion;
}

/// Fetches a server's public identity from `GET <httpBase>/healthz`.
/// Returns null when the endpoint is unreachable or reports no identity.
Future<ServerIdentityProbe?> probeServerIdentity(
  Uri httpBase, {
  Duration timeout = const Duration(seconds: 4),
  http.Client Function()? httpClientFactory,
}) async {
  final client = (httpClientFactory ?? http.Client.new)();
  try {
    final response = await client
        .get(httpBase.replace(path: '/healthz'))
        .timeout(timeout);
    if (response.statusCode != 200) {
      return null;
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final serverId = body['serverId'] as String? ?? '';
    final fingerprint = body['fingerprint'] as String? ?? '';
    if (serverId.isEmpty || fingerprint.isEmpty) {
      return null;
    }
    return ServerIdentityProbe(
      serverId: serverId,
      serverName: body['serverName'] as String? ?? serverId,
      fingerprint: fingerprint,
      insecure: body['insecure'] as bool? ?? false,
      version: body['version'] as String?,
      gitSha: body['gitSha'] as String?,
      catalogVersion: body['catalogVersion'] as int?,
    );
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

/// Thrown when no descriptor path could be probed and connected.
class NoReachablePathException implements Exception {
  /// Creates a [NoReachablePathException].
  const NoReachablePathException(this.serverId, this.failures);

  /// The unreachable server's id.
  final String serverId;

  /// Per-path failure summaries (diagnostics; no secrets).
  final List<String> failures;

  @override
  String toString() =>
      'NoReachablePathException: no path to server $serverId — '
      '${failures.join('; ')}';
}
