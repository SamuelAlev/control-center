import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:drift/drift.dart';

part 'paired_device_dao.g.dart';

/// Status values stored in [PairedDevicesTable.status].
///
/// String-based (not an enum) so the DB layer stays decoupled from the
/// remote-control feature's domain types — matches the codebase convention for
/// status columns (see `notification_event_mapper._humanizeStatus`).
abstract final class PairedDeviceStatus {
  /// Awaiting first user confirmation on the desktop.
  static const pendingConfirm = 'pendingConfirm';

  /// Confirmed and usable.
  static const active = 'active';

  /// Revoked by the user — PSK deleted, must not reconnect.
  static const revoked = 'revoked';
}

/// Data access object for [PairedDevicesTable].
///
/// Devices are global — a paired phone spans every workspace — so the list
/// queries here are intentionally **unscoped** by workspace. This is the
/// documented "CROSS-WORKSPACE BY DESIGN" exception: pairing metadata is not
/// workspace-scoped data and must never mix with the workspace-scoped tables.
@DriftAccessor(tables: [PairedDevicesTable])
class PairedDeviceDao extends DatabaseAccessor<GlobalDatabase>
    with _$PairedDeviceDaoMixin {
  /// Creates a [PairedDeviceDao] for the given database.
  PairedDeviceDao(super.attachedDatabase);

  /// Watches every paired device, most-recently-seen first.
  ///
  /// CROSS-WORKSPACE BY DESIGN — device pairing is a server-global concern: the
  /// remote-control auth layer must see every paired device to authenticate an
  /// incoming connection, independent of any workspace. The `workspaceId`
  /// column records the device's landing workspace, not an isolation boundary.
  Stream<List<PairedDevicesTableData>> watchAll() => (select(
    pairedDevicesTable,
  )..orderBy([(t) => OrderingTerm.desc(t.pairedAt)])).watch();

  /// Returns every paired device.
  ///
  /// CROSS-WORKSPACE BY DESIGN — see [watchAll]; device auth is server-global.
  Future<List<PairedDevicesTableData>> getAll() =>
      select(pairedDevicesTable).get();

  /// Returns a device by [id], or null.
  Future<PairedDevicesTableData?> getById(String id) => (select(
    pairedDevicesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Devices belonging to [userId], most-recently-seen first (the per-user
  /// device registry: list / rename / revoke your own devices).
  Future<List<PairedDevicesTableData>> getForUser(String userId) =>
      (select(pairedDevicesTable)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.pairedAt)]))
          .get();

  /// Watches devices belonging to [userId], most-recently-seen first.
  Stream<List<PairedDevicesTableData>> watchForUser(String userId) =>
      (select(pairedDevicesTable)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.pairedAt)]))
          .watch();

  /// Binds a device to its owning user (bootstrap backfill / invite
  /// redemption).
  Future<int> setUserId(String id, String userId) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(userId: Value(userId)),
      );

  /// Watches only active (confirmed) devices.
  Stream<List<PairedDevicesTableData>> watchActive() => (select(
    pairedDevicesTable,
  )..where((t) => t.status.equals(PairedDeviceStatus.active))).watch();

  /// Watches devices the server should join the broker room for: active
  /// (confirmed) **and** pending-confirmation. A pending device must be able to
  /// connect and authenticate so the desktop can surface it as "wants to
  /// connect" — the RPC session is held until the user confirms it.
  Stream<List<PairedDevicesTableData>> watchConnectable() =>
      (select(pairedDevicesTable)..where(
            (t) => t.status.isIn(const [
              PairedDeviceStatus.active,
              PairedDeviceStatus.pendingConfirm,
            ]),
          ))
          .watch();

  /// Inserts or updates a device row.
  Future<void> upsert(PairedDevicesTableCompanion entry) =>
      into(pairedDevicesTable).insertOnConflictUpdate(entry);

  /// Updates a device's status (e.g. confirm → active, or revoke).
  Future<int> setStatus(String id, String status) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(status: Value(status)),
      );

  /// Confirms a device: marks it `active` and resets its credential expiry to
  /// an absolute lifetime ([expiresAt]). Used on first approval and on
  /// re-approval after an idle period.
  Future<int> confirm(String id, {required DateTime expiresAt}) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(
          status: const Value(PairedDeviceStatus.active),
          expiresAt: Value(expiresAt),
        ),
      );

  /// Drops an approved device back to `pendingConfirm` (re-approval required)
  /// and sets a fresh short offer window [expiresAt], so a long-dormant trust
  /// is not silently resumed.
  Future<int> requireReapproval(String id, {required DateTime expiresAt}) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(
          status: const Value(PairedDeviceStatus.pendingConfirm),
          expiresAt: Value(expiresAt),
        ),
      );

  /// Pins the remote DTLS fingerprint after first connect (TOFU).
  Future<int> setRemoteFingerprint(String id, String fingerprint) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(remoteFingerprint: Value(fingerprint)),
      );

  /// Records a connect timestamp.
  Future<int> markSeen(String id, DateTime at) =>
      (update(pairedDevicesTable)..where((t) => t.id.equals(id))).write(
        PairedDevicesTableCompanion(lastSeenAt: Value(at)),
      );

  /// Deletes a device row (used on revoke after the PSK is purged).
  Future<int> remove(String id) =>
      (delete(pairedDevicesTable)..where((t) => t.id.equals(id))).go();
}
