import 'dart:async';

import 'package:cc_domain/features/remote_control/domain/entities/paired_device.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/remote_control/data/repositories/paired_device_secrets_repository.dart';
import 'package:control_center/features/remote_control/providers/remote_control_config_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [PairedDeviceSecretsRepository] over the shared secure store.
final pairedDeviceSecretsProvider = Provider<PairedDeviceSecretsRepository>((
  ref,
) {
  return PairedDeviceSecretsRepository(ref.watch(secureStoreProvider));
});

/// Watches all paired devices, most-recently-paired first.
final pairedDevicesProvider = StreamProvider<List<PairedDevice>>((ref) {
  return ref.watch(pairedDeviceRepositoryProvider).watchAll();
});

/// Generates a pairing QR payload and records the pending device.
///
/// The pairing room code **is** the device id (capacity-2 broker room), so
/// reconnects are deterministic: the phone rejoins `room = deviceId`. The PSK
/// is generated here, stored in the secure store, and embedded in the QR's URL
/// fragment (never sent to the PWA host). The device row starts
/// `pendingConfirm` and is promoted to `active` once the user confirms the
/// first connection.
Future<PairingPayload> generatePairingPayload(WidgetRef ref) async {
  final config = ref.read(remoteControlConfigProvider);
  final devices = ref.read(pairedDeviceRepositoryProvider);
  final secrets = ref.read(pairedDeviceSecretsProvider);
  final activeWorkspace = ref.read(activeWorkspaceIdProvider);

  // deviceId == room code (the capacity-2 broker room this phone reuses).
  final deviceId = RemoteControlCrypto.generateRoomCode();
  final psk = RemoteControlCrypto.generatePsk();

  // Persist the PSK, then immediately read it back. A silent keychain failure
  // (e.g. an ad-hoc/unsigned build that can't satisfy the keychain-access
  // entitlement) makes `writePsk` no-op and the desktop later deny the phone
  // with "row=present, psk=missing" — surfacing it here pins the blame at the
  // source instead of a confusing connect-time denial.
  final wrote = await secrets.writePsk(deviceId, psk);
  final readBack = await secrets.readPsk(deviceId);
  if (!wrote || readBack != psk) {
    AppLog.e(
      'RemoteControl',
      'Secure-store round-trip FAILED for pairing PSK (device=$deviceId): '
          'write=$wrote, readBack='
          '${readBack == null ? 'null' : (readBack == psk ? 'ok' : 'mismatch')}. '
          'The phone will be denied at connect time — this build likely cannot '
          'write to the platform keychain (signing/entitlement).',
    );
  }
  // Time-box the offer: an un-confirmed device past this window is purged at the
  // desktop connect gate, so a leaked QR can't be redeemed indefinitely.
  final offerExpiry = RemotePairingLifecycle.offerExpiry(DateTime.now());
  await devices.upsertPending(
    id: deviceId,
    workspaceId: activeWorkspace,
    label: 'New device',
    pskRef: PairedDeviceSecretsRepository.keyFor(deviceId),
    expiresAt: offerExpiry,
  );

  return PairingPayload(
    version: PairingPayload.currentVersion,
    signalingUrl: config.signalingUrl,
    room: deviceId,
    psk: psk,
    // The desktop's broker signaling id is no longer derived from a QR value
    // (it is a fresh per-room random), so the QR carries no peer id an attacker
    // could use to evict the desktop or occupy its room slot. The field is kept
    // for wire shape; the phone does not use it.
    appInstanceId: '',
    stunUrls: config.stunUrls,
    expiresAt: offerExpiry,
  );
}

/// Promotes a pending device to active after the user confirms it, stamping a
/// fresh absolute credential expiry so the approval is time-boxed.
Future<void> confirmPairedDevice(WidgetRef ref, String deviceId) async {
  final devices = ref.read(pairedDeviceRepositoryProvider);
  await devices.confirm(
    deviceId,
    expiresAt: RemotePairingLifecycle.credentialExpiry(DateTime.now()),
  );
}

/// Discards a pairing offer that was never used: deletes its PSK and metadata
/// row so a dead `pendingConfirm` entry doesn't linger in the device list.
///
/// Only removes a device that is still `pendingConfirm` — a no-op once it has
/// been confirmed (active). Call this when the pairing dialog closes without a
/// phone having connected; the caller is responsible for checking that no phone
/// is mid-connection (connected/awaiting approval) before discarding.
Future<void> discardPairingOffer(WidgetRef ref, String deviceId) async {
  final devices = ref.read(pairedDeviceRepositoryProvider);
  final device = await devices.getById(deviceId);
  if (device == null || device.status != 'pendingConfirm') {
    return;
  }
  final secrets = ref.read(pairedDeviceSecretsProvider);
  await secrets.deletePsk(deviceId);
  await devices.remove(deviceId);
}

/// Renames a paired device.
Future<void> renamePairedDevice(
  WidgetRef ref,
  String deviceId,
  String label,
) async {
  final devices = ref.read(pairedDeviceRepositoryProvider);
  await devices.rename(deviceId, label);
}

/// Revokes a paired device: deletes its PSK (fails closed) and the metadata
/// row. The live channel is torn down by the server, which watches device
/// status and drops revoked sessions.
Future<void> revokePairedDevice(WidgetRef ref, String deviceId) async {
  final devices = ref.read(pairedDeviceRepositoryProvider);
  final secrets = ref.read(pairedDeviceSecretsProvider);
  await secrets.deletePsk(deviceId);
  await devices.revoke(deviceId);
}
