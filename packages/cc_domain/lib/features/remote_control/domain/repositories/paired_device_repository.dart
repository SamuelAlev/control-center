import 'package:cc_domain/features/remote_control/domain/entities/paired_device.dart';

/// Repository for paired remote-control devices (the desktop's trusted phones).
///
/// Devices are **global** (not workspace-scoped) — a paired phone spans every
/// workspace — so these queries are intentionally unscoped by workspace. This
/// is the documented cross-workspace exception: pairing metadata is not
/// workspace-scoped data and must never mix with the workspace-scoped tables.
abstract class PairedDeviceRepository {
  /// Watches every paired device, most-recently-paired first.
  Stream<List<PairedDevice>> watchAll();

  /// Returns a device by [id], or null.
  Future<PairedDevice?> getById(String id);

  /// Records a freshly-generated pairing offer as a `pendingConfirm` device.
  ///
  /// The device starts pending and is promoted to `active` via [confirm] once
  /// the user approves the first connection. [expiresAt] is the short
  /// pairing-offer window after which an un-confirmed offer is purged.
  Future<void> upsertPending({
    required String id,
    required String label,
    required String pskRef,
    String? workspaceId,
    DateTime? expiresAt,
  });

  /// Promotes a pending device to `active`, stamping a fresh absolute
  /// credential [expiresAt] so the approval is time-boxed.
  Future<void> confirm(String id, {required DateTime expiresAt});

  /// Renames a device.
  Future<void> rename(String id, String label);

  /// Revokes a device: marks it `revoked` (so the live server tears down its
  /// session) and then deletes the metadata row.
  Future<void> revoke(String id);

  /// Deletes a device's metadata row (used to discard an unused pairing offer).
  Future<void> remove(String id);
}
