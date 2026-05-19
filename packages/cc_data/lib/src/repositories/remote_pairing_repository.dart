import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/remote_control/domain/entities/paired_device.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The credential a freshly-minted pairing yields — what a first-party client
/// encodes into a pairing QR/link for a phone. The [psk] is returned exactly
/// once (by `pairing.mint`); it is never read back afterwards.
class PairingMint {
  /// Creates a [PairingMint].
  const PairingMint({
    required this.deviceId,
    required this.psk,
    required this.serverUrl,
    required this.platform,
    this.signalingUrl = '',
    this.room = '',
    this.workspaceId,
    this.workspaceName,
  });

  /// The new device's id (sent in the client's auth handshake).
  final String deviceId;

  /// The pre-shared key the new client proves possession of.
  final String psk;

  /// The reachable RPC WebSocket URL the new client should dial. Empty when
  /// the host is not directly reachable (the caller then falls back to WebRTC).
  final String serverUrl;

  /// The minted device's platform — `web`/`desktop` (a first-party fullClient)
  /// or `ios`/`android` (a restricted phone).
  final String platform;

  /// The signaling broker a phone uses to rendezvous with cc_server when the
  /// server isn't directly reachable (the relay pairing path). Empty disables
  /// relay pairing.
  final String signalingUrl;

  /// The broker room a phone joins to reach cc_server — the device id.
  final String room;

  /// The workspace the device's first session binds to.
  final String? workspaceId;

  /// Human-readable name of [workspaceId].
  final String? workspaceName;

  /// Whether the host advertised a phone-reachable URL (so a direct-WS pairing
  /// link can be built; otherwise the client falls back to WebRTC).
  bool get isDirectlyReachable => serverUrl.trim().isNotEmpty;

  /// Whether a broker was advertised, so a phone can pair via the relay even
  /// when the server is not directly reachable.
  bool get canRelay => signalingUrl.trim().isNotEmpty && room.trim().isNotEmpty;
}

/// Drives the server's `pairing.*` ops over the RPC client: mint a pairing for
/// a phone, list paired devices, rename, and revoke.
///
/// The phone then dials the server DIRECTLY with the minted credential (the
/// same WSS + PSK handshake this client used). These ops are `fullClient`-only
/// server-side — a companion phone session is denied — so a first-party
/// web/desktop client is the only legitimate caller.
class RemotePairingRepository {
  /// Creates a [RemotePairingRepository] over [_client].
  RemotePairingRepository(this._client);

  final RemoteRpcClient _client;

  /// Mints a new pairing labelled [label] for a [platform] client, returning
  /// the credential to encode into a pairing QR/link. `web`/`desktop` mint a
  /// first-party fullClient (which may itself manage pairings); `ios`/`android`
  /// mint a restricted phone. Seeds the device's initial workspace from the
  /// caller's session binding (server-side).
  Future<PairingMint> mint({
    required String label,
    String platform = 'web',
  }) async {
    final data = await _client.call('pairing.mint', {
      'label': label,
      'platform': platform,
    });
    return PairingMint(
      deviceId: data['device_id'] as String,
      psk: data['psk'] as String,
      serverUrl: (data['server_url'] as String?) ?? '',
      platform: (data['platform'] as String?) ?? platform,
      signalingUrl: (data['signaling_url'] as String?) ?? '',
      room: (data['room'] as String?) ?? '',
      workspaceId: data['workspace_id'] as String?,
      workspaceName: data['workspace_name'] as String?,
    );
  }

  /// Lists paired devices (optionally filtered by [status]). Returns an empty
  /// list when the host exposes no pairing surface (default-deny → opUnknown).
  Future<List<PairedDevice>> list({String? status}) async {
    try {
      final data = await _client.call('pairing.list', {'status': ?status});
      return ((data['devices'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => _device(e.cast<String, dynamic>()))
          .toList();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// Renames device [deviceId] to [label], returning the updated device.
  Future<PairedDevice> rename(String deviceId, String label) async {
    final data = await _client.call('pairing.rename', {
      'device_id': deviceId,
      'label': label,
    });
    return _device((data['device'] as Map).cast<String, dynamic>());
  }

  /// Revokes device [deviceId]: deletes its PSK (the phone can no longer
  /// authenticate) and removes its metadata row.
  Future<void> revoke(String deviceId) async {
    await _client.call('pairing.revoke', {'device_id': deviceId});
  }

  PairedDevice _device(Map<String, dynamic> d) => PairedDevice(
    id: d['device_id'] as String,
    label: d['label'] as String? ?? '',
    platform: d['platform'] as String? ?? '',
    // `pskRef` is a server-only secure-store key; clients never see or need it.
    pskRef: '',
    status: d['status'] as String? ?? '',
    workspaceId: d['workspace_id'] as String?,
    remoteFingerprint: d['remote_fingerprint'] as String?,
    pairedAt:
        DateTime.tryParse(d['paired_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    lastSeenAt: _date(d['last_seen_at']),
    expiresAt: _date(d['expires_at']),
  );

  DateTime? _date(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}
