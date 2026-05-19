import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

/// Outcome of provisioning a device against a server data dir.
class PairResult {
  /// Creates a [PairResult].
  const PairResult({
    required this.deviceId,
    required this.psk,
    required this.workspaceId,
    required this.workspaceName,
    required this.createdWorkspace,
    required this.dataDir,
  });

  /// The device id a client must send in its auth handshake.
  final String deviceId;

  /// The freshly minted pre-shared key (base64url, no padding) — the "pairing
  /// key" a thin client pastes to connect. Print once; it is never logged.
  final String psk;

  /// The workspace bound to the device's first session.
  final String workspaceId;

  /// Human-readable name of [workspaceId].
  final String workspaceName;

  /// Whether [workspaceId] was created by this call (data dir had none).
  final bool createdWorkspace;

  /// The data dir provisioned.
  final String dataDir;
}

/// Provisions a paired device so a thin client (the web build) can authenticate
/// against a headless `runCcServer` data dir.
///
/// The standalone binary ships an **empty, unprovisioned** data dir: no
/// workspace, no `paired_devices` row, no PSK — so the server has nothing to
/// authenticate against and the web client's "pairing key" prompt can never be
/// satisfied. This generates a PSK, ensures a workspace exists (so the client
/// has something to bind and show), upserts an `active` paired-device row, and
/// writes the PSK to the [FileSecretsStore] beside the database — exactly the
/// state the desktop's pairing UI and `main_desktop_thin` set up by hand.
///
/// Idempotent: re-running rotates the PSK for [deviceId] and reuses the first
/// existing workspace. Must run while no server holds the SQLite file (it opens
/// the DB directly), so pair **before** starting the server.
Future<PairResult> pairDevice({
  required CcServerConfig config,
  String deviceId = 'web-client',
  String? label,
  String? workspaceName,
}) async {
  Directory(config.dataDir).createSync(recursive: true);
  final db = AppDatabase(openServerDatabase(dataDir: config.dataDir));
  try {
    // Ensure a workspace exists so the session can bind and the shell shows
    // something. Reuse the first one if the data dir already has data.
    var workspaces = await db.workspaceDao.getAll();
    var createdWorkspace = false;
    if (workspaces.isEmpty) {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion(
          id: Value(const Uuid().v4()),
          name: Value(workspaceName ?? 'Local'),
        ),
      );
      createdWorkspace = true;
      workspaces = await db.workspaceDao.getAll();
    }
    final workspace = workspaces.first;

    // Mint the PSK in the same format the handshake expects (32 bytes,
    // base64url, no padding) and persist the device as already-confirmed —
    // there is no separate desktop confirm step for a headless server.
    final psk = RemoteControlCrypto.generatePsk();
    await db.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: Value(deviceId),
        workspaceId: Value(workspace.id),
        label: Value(label ?? 'Web client'),
        platform: const Value('web'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
      ),
    );
    await FileSecretsStore(dataDir: config.dataDir).writePsk(deviceId, psk);

    return PairResult(
      deviceId: deviceId,
      psk: psk,
      workspaceId: workspace.id,
      workspaceName: workspace.name,
      createdWorkspace: createdWorkspace,
      dataDir: config.dataDir,
    );
  } finally {
    await db.close();
  }
}
