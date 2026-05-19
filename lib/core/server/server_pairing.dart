import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/invite_redeemer.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/theme/font_loader_install.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';

/// A live, resilient connection to one paired server — the web-safe core
/// shared by the desktop boot, the web gate, and the settings "add server" /
/// switch flows.
class RemoteServerConnection {
  /// Creates a handle.
  RemoteServerConnection({
    required this.client,
    required this.supervisor,
    required this.entry,
    this.mediaProxy,
  });

  /// The resilient RPC client (survives path failovers).
  final ResilientRpcClient client;

  /// The connection supervisor (status for the pill).
  final ServerConnectionSupervisor supervisor;

  /// The paired-server entry backing this connection.
  final ServerEntry entry;

  /// Media proxy base for this connection, when an HTTP path exists.
  final MediaProxyConfig? mediaProxy;

  /// Closes the connection.
  Future<void> dispose() => client.close();
}

/// Connects to a paired server entry: resolver-ranked best path, PSK
/// handshake, Ed25519 identity verification against the entry's pin.
/// Persists descriptor refreshes and a first-connect TOFU pin back to
/// [store].
Future<RemoteServerConnection> connectToEntry({
  required ServerConnectionStore store,
  required ServerEntry entry,
  required String psk,
}) async {
  final supervisor = ServerConnectionSupervisor(
    descriptor: entry.descriptor,
    deviceId: entry.deviceId,
    psk: psk,
    pinnedFingerprint: entry.pinnedFingerprint,
    onDescriptorUpdated: (descriptor) =>
        unawaited(store.updateDescriptor(entry.serverId, descriptor)),
    onFingerprintPinned: (fingerprint) =>
        unawaited(store.updatePin(entry.serverId, fingerprint)),
  );
  await supervisor.start();
  final client = ResilientRpcClient(supervisor);
  AppLog.i(
    'cc_server',
    'connected to ${entry.name} via ${supervisor.current.path} '
        '(${supervisor.current.relayed ? 'relayed' : 'direct'})',
  );
  final mediaProxy = mediaProxyFor(supervisor, entry.deviceId, psk);
  // A user-selected font's bytes come from the host too (see
  // `installHostFontLoader`), so it is armed with the same connection.
  installHostFontLoader(mediaProxy);
  return RemoteServerConnection(
    client: client,
    supervisor: supervisor,
    entry: entry,
    mediaProxy: mediaProxy,
  );
}

/// Bulk/media base for a connection: the descriptor's advertised HTTPS bulk
/// base when present, else the live path's HTTP origin. Relay-only
/// connections without any HTTP path get none (media loads direct).
MediaProxyConfig? mediaProxyFor(
  ServerConnectionSupervisor supervisor,
  String deviceId,
  String psk,
) {
  final bulk = supervisor.descriptor.bulkHttpBase;
  if (bulk != null && bulk.isNotEmpty) {
    final base = Uri.tryParse(bulk);
    if (base != null && base.host.isNotEmpty) {
      return MediaProxyConfig(httpBase: base, deviceId: deviceId, psk: psk);
    }
  }
  final rpcUri = supervisor.current.path?.rpcUri;
  if (rpcUri == null) {
    return null;
  }
  return MediaProxyConfig.fromConnection(
    serverUri: rpcUri,
    deviceId: deviceId,
    psk: psk,
  );
}

/// Pairs this client with a server and persists the entry. Two shapes:
///  * [inviteCode] non-empty → redeem it at the server named by [rawUrl]
///    (JIT user + device credential + descriptor).
///  * otherwise → manual credentials: probe the URL's identity, then connect
///    with [deviceId] + [psk].
/// Returns the connected handle; the entry is stored only after a
/// successful, identity-verified connect.
Future<RemoteServerConnection> pairWithServer({
  required ServerConnectionStore store,
  required String rawUrl,
  required String platform,
  String inviteCode = '',
  String deviceId = '',
  String psk = '',
}) async {
  ServerEntry entry;
  String effectivePsk;
  if (inviteCode.trim().isNotEmpty) {
    final normalized = normalizeServerUrl(rawUrl);
    if (normalized == null) {
      throw StateError('Enter the server address the invite belongs to.');
    }
    final wsUri = Uri.parse(normalized);
    final redeemed = await redeemInviteAt(
      httpBase: wsUri.replace(
        scheme: wsUri.scheme == 'wss' ? 'https' : 'http',
        path: '',
      ),
      code: inviteCode.trim(),
      platform: platform,
    );
    effectivePsk = redeemed.psk;
    if (redeemed.descriptor != null) {
      entry = ServerEntryFactory.fromDescriptorMap(
        redeemed.descriptor!,
        deviceId: redeemed.deviceId,
      );
    } else {
      final manual = await ServerEntryFactory.fromManualUrl(
        rawUrl: redeemed.serverUrl ?? normalized,
        deviceId: redeemed.deviceId,
      );
      if (manual == null) {
        throw StateError('The server did not publish its identity.');
      }
      entry = manual;
    }
  } else {
    final manual = await ServerEntryFactory.fromManualUrl(
      rawUrl: rawUrl,
      deviceId: deviceId,
    );
    if (manual == null) {
      throw StateError(
        'Could not reach the server at that address (its /healthz did not '
        'answer with an identity).',
      );
    }
    entry = manual;
    effectivePsk = psk;
  }

  // Connect FIRST (this verifies the Ed25519 identity against the pin), then
  // persist — a failed or impostor connect never writes an entry.
  final connection = await connectToEntry(
    store: store,
    entry: entry,
    psk: effectivePsk,
  );
  await store.upsertEntry(
    connection.supervisor.pinnedFingerprint.isNotEmpty
        ? entry.withPin(connection.supervisor.pinnedFingerprint)
        : entry,
    psk: effectivePsk,
  );
  await store.setMode(ServerConnectionMode.remote);
  await store.setActiveServer(entry.serverId);
  return connection;
}
