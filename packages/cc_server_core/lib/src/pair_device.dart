import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';

/// Outcome of provisioning a device against a server data dir.
class PairResult {
  /// Creates a [PairResult].
  const PairResult({
    required this.deviceId,
    required this.psk,
    required this.dataDir,
  });

  /// The device id a client must send in its auth handshake.
  final String deviceId;

  /// The freshly minted pre-shared key (base64url, no padding) — the "pairing
  /// key" a thin client pastes to connect. Print once; it is never logged.
  final String psk;

  /// The data dir provisioned.
  final String dataDir;
}

/// Provisions a paired device so a thin client (the web build) can authenticate
/// against a headless `runCcServer` data dir.
///
/// The standalone binary ships an **empty, unprovisioned** data dir: no
/// `paired_devices` row, no PSK — so the server has nothing to authenticate
/// against and the web client's "pairing key" prompt can never be satisfied.
/// This generates a PSK, upserts an `active` paired-device row and writes the
/// PSK to the [FileSecretsStore] beside the database. It deliberately does NOT
/// create a workspace: the connecting client's onboarding names and creates
/// the first one, so a fresh data dir must stay workspace-less until then (an
/// auto-created "Local" workspace would silently skip that step). When the
/// data dir already has workspaces, the device is bound to the first as its
/// session seed.
///
/// Idempotent: re-running rotates the PSK for [deviceId]. Must run while no
/// server holds the SQLite file (it opens the DB directly), so pair **before**
/// starting the server.
Future<PairResult> pairDevice({
  required CcServerConfig config,
  String deviceId = 'web-client',
  String? label,
}) async {
  // Infer the platform from the device id so `--device desktop` mints a desktop
  // row (platform + privilege + icon), `--device ios`/`--device android` a
  // phone and anything else a web client. Otherwise the row was always
  // `platform: 'web'` + label `Web client`, masking the actual device tier.
  final platform = _platformForDeviceId(deviceId);
  Directory(config.dataDir).createSync(recursive: true);
  final db = GlobalDatabase(openGlobalDatabase(dataDir: config.dataDir));
  final workspaceDbs = WorkspaceDatabaseManager(
    dataDir: config.dataDir,
    global: db,
  );
  await workspaceDbs.loadInstallId();
  try {
    // Bind the device's session seed to an existing workspace when the data
    // dir already has one. With none, leave it unbound — the connecting
    // client's onboarding creates and names the first workspace.
    final workspaces = await db.workspaceRegistryDao.getAll();
    final workspace = workspaces.isEmpty ? null : workspaces.first;

    // First-user-is-admin: a CLI-paired device belongs to the server owner
    // (invited collaborators pair through invite redemption instead). Runs the
    // idempotent bootstrap so a fresh data dir mints the owner right here.
    final ownerId = await IdentityBootstrap(
      global: db,
      workspaces: workspaceDbs,
      environment: Platform.environment,
    ).run();

    // Mint the PSK in the same format the handshake expects (32 bytes,
    // base64url, no padding) and persist the device as already-confirmed —
    // there is no separate desktop confirm step for a headless server.
    final psk = RemoteControlCrypto.generatePsk();
    await db.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: Value(deviceId),
        userId: Value(ownerId),
        workspaceId: Value(workspace?.id),
        label: Value(label ?? _defaultLabelForPlatform(platform)),
        platform: Value(platform),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
      ),
    );
    await FileSecretsStore(dataDir: config.dataDir).writePsk(deviceId, psk);

    return PairResult(deviceId: deviceId, psk: psk, dataDir: config.dataDir);
  } finally {
    await workspaceDbs.closeAll();
    await db.close();
  }
}

/// Maps a device id to the platform string the server stores (and that sets the
/// device's capability when it connects). Mirrors the tiers the `pairing.mint`
/// op and the devices UI understand: `web` / `desktop` / `ios` / `android`.
String _platformForDeviceId(String deviceId) {
  final lower = deviceId.toLowerCase();
  if (lower == 'desktop' || lower.startsWith('desktop-')) {
    return 'desktop';
  }
  if (lower == 'ios' ||
      lower.startsWith('ios-') ||
      lower.startsWith('iphone')) {
    return 'ios';
  }
  if (lower == 'android' || lower.startsWith('android-')) {
    return 'android';
  }
  return 'web';
}

/// Human-readable default label matching [platform] (overridable via `--label`).
///
/// Appends the machine hostname (`Platform.localHostname`) when available so
/// paired devices are distinguishable in the device list by more than just
/// their platform tier. Falls back to the bare platform string when the
/// hostname is empty (e.g. sandboxed runtimes that leave it blank).
String _defaultLabelForPlatform(String platform) {
  final base = switch (platform) {
    'desktop' => 'Desktop client',
    'ios' => 'iOS client',
    'android' => 'Android client',
    _ => 'Web client',
  };
  final hostname = Platform.localHostname.trim();
  return hostname.isEmpty ? base : '$base ($hostname)';
}
