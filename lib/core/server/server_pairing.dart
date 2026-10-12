import 'dart:async';

import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/client_resource_proxy.dart';
import 'package:control_center/core/server/identity_probe_client.dart'
    if (dart.library.js_interop) 'package:control_center/core/server/identity_probe_client_web.dart';
import 'package:control_center/core/server/invite_redeemer.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/snapshot_cache_binding.dart';
import 'package:control_center/core/storage/client_snapshot_store.dart';
import 'package:control_center/core/theme/font_loader_install.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';

/// A live, resilient connection to one paired server — the web-safe core
/// shared by the desktop boot, the web gate and the settings "add server" /
/// switch flows.
class RemoteServerConnection {
  /// Creates a handle.
  RemoteServerConnection({
    required this.client,
    required this.supervisor,
    required this.entry,
    required this.resourceProxy,
    this.mediaProxy,
  });

  /// The resilient RPC client (survives path failovers).
  final ResilientRpcClient client;

  /// The connection supervisor (status for the pill).
  final ServerConnectionSupervisor supervisor;

  /// The paired-server entry backing this connection.
  final ServerEntry entry;

  /// Capability-scoped local resource listener, retained across reconnects.
  final LocalResourceProxy resourceProxy;

  /// Signed media on the local encrypted-resource listener.
  final MediaProxyConfig? mediaProxy;

  /// Retire local URLs before the authenticated RPC client is closed.
  Future<void> dispose() async {
    await resourceProxy.close();
    await client.close();
  }
}

/// Connects to a paired server entry: resolver-ranked best path, PSK
/// handshake, Ed25519 identity verification against the entry's pin.
/// Persists descriptor refreshes and a first-connect TOFU pin back to
/// [store].
Future<RemoteServerConnection> connectToEntry({
  required ServerConnectionStore store,
  required ServerEntry entry,
  required String psk,
  bool persistSnapshots = true,
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
  try {
    await supervisor.start();
  } on AuthRejectedException {
    if (persistSnapshots) {
      await forgetSnapshotServer(entry.serverId);
    }
    rethrow;
  }
  final client = ResilientRpcClient(supervisor);
  LocalResourceProxy? resourceProxy;
  try {
    await attachVerifiedSnapshotCache(
      client: client,
      serverId: entry.serverId,
      fingerprint: supervisor.pinnedFingerprint,
      persist: persistSnapshots,
      supervisor: supervisor,
    );
    resourceProxy = await createClientResourceProxy(() => client.resources);
    AppLog.i(
      'cc_server',
      'connected to ${entry.name} via ${supervisor.current.path} '
          '(${supervisor.current.relayed ? 'relayed' : 'direct'})',
    );
    final mediaProxy = MediaProxyConfig(
      httpBase: resourceProxy.baseUri,
      deviceId: entry.deviceId,
      psk: psk,
    );
    installHostFontLoader(mediaProxy);
    return RemoteServerConnection(
      client: client,
      supervisor: supervisor,
      entry: entry,
      resourceProxy: resourceProxy,
      mediaProxy: mediaProxy,
    );
  } catch (_) {
    await resourceProxy?.close();
    await client.close();
    rethrow;
  }
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
  final previousEntries = store.readEntries();
  if (inviteCode.trim().isNotEmpty) {
    final normalized = normalizeServerUrl(rawUrl);
    if (normalized == null) {
      throw StateError('Enter the server address the invite belongs to.');
    }
    final wsUri = Uri.parse(normalized);
    final existingPin = previousEntries
        .where(
          (saved) => saved.descriptor.paths.any((path) {
            final uri = path.rpcUri;
            return uri != null &&
                uri.scheme == wsUri.scheme &&
                uri.authority == wsUri.authority;
          }),
        )
        .map((entry) => entry.pinnedFingerprint)
        .toSet();
    if (existingPin.length > 1) {
      throw const InviteRejectedException('Server identity changed');
    }
    final httpBase = wsUri.replace(
      scheme: wsUri.scheme == 'wss' ? 'https' : 'http',
      path: '',
    );
    final code = inviteCode.trim();
    bool strongCode;
    try {
      InvitePairingProof.codeHash(code);
      strongCode = true;
    } on FormatException {
      strongCode = false;
    }
    String? demoFingerprint;
    final RedeemedInvite redeemed;
    if (strongCode) {
      redeemed = await redeemInviteAt(
        httpBase: httpBase,
        code: code,
        platform: platform,
        pinnedFingerprint: existingPin.isEmpty ? null : existingPin.single,
      );
    } else {
      // Only the advertised public demo accepts a short code. A failed
      // high-entropy Noise handshake NEVER falls back to this HTTP route.
      final probe = await probeServerIdentity(
        httpBase,
        httpClientFactory: identityProbeClientFactory(httpBase),
      );
      if (probe?.demo != true) {
        throw const InviteRejectedException('Invite is invalid or expired');
      }
      demoFingerprint = probe!.fingerprint;
      redeemed = await redeemPublicDemoAt(
        httpBase: httpBase,
        code: code,
        platform: platform,
        httpClientFactory: identityProbeClientFactory(httpBase),
      );
    }
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
    final expectedFingerprint = demoFingerprint ?? redeemed.verifiedFingerprint;
    if (entry.descriptor.fingerprint != expectedFingerprint ||
        previousEntries.any(
          (saved) =>
              saved.serverId == entry.serverId &&
              saved.pinnedFingerprint != expectedFingerprint,
        )) {
      throw const InviteRejectedException('Server identity changed');
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
  final candidateUri = Uri.tryParse(normalizeServerUrl(rawUrl) ?? '');
  if (previousEntries.any(
    (saved) =>
        (saved.serverId == entry.serverId ||
            saved.descriptor.paths.any((path) {
              final uri = path.rpcUri;
              return uri != null &&
                  candidateUri != null &&
                  uri.scheme == candidateUri.scheme &&
                  uri.authority == candidateUri.authority;
            })) &&
        saved.pinnedFingerprint != entry.descriptor.fingerprint,
  )) {
    throw const InviteRejectedException('Server identity changed');
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
