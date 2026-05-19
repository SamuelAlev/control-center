import 'package:cc_domain/features/remote_control/domain/entities/paired_device.dart';
import 'package:cc_domain/features/remote_control/domain/repositories/paired_device_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:drift/drift.dart';

/// DAO-backed [PairedDeviceRepository]. Maps the Drift [PairedDevicesTableData]
/// rows to the [PairedDevice] domain entity and builds the table companions
/// internally, so drift stays confined to this persistence layer.
class DaoPairedDeviceRepository implements PairedDeviceRepository {
  /// Creates a [DaoPairedDeviceRepository].
  DaoPairedDeviceRepository(this._dao);

  final PairedDeviceDao _dao;

  @override
  Stream<List<PairedDevice>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<PairedDevice?> getById(String id) =>
      _dao.getById(id).then((row) => row == null ? null : _toDomain(row));

  @override
  Future<void> upsertPending({
    required String id,
    required String label,
    required String pskRef,
    String? workspaceId,
    DateTime? expiresAt,
  }) =>
      _dao.upsert(
        PairedDevicesTableCompanion.insert(
          id: id,
          workspaceId:
              workspaceId == null ? const Value.absent() : Value(workspaceId),
          label: label,
          pskRef: pskRef,
          status: const Value(PairedDeviceStatus.pendingConfirm),
          expiresAt:
              expiresAt == null ? const Value.absent() : Value(expiresAt),
        ),
      );

  @override
  Future<void> confirm(String id, {required DateTime expiresAt}) =>
      _dao.confirm(id, expiresAt: expiresAt);

  @override
  Future<void> rename(String id, String label) => _dao.upsert(
        PairedDevicesTableCompanion(id: Value(id), label: Value(label)),
      );

  @override
  Future<void> revoke(String id) async {
    await _dao.setStatus(id, PairedDeviceStatus.revoked);
    await _dao.remove(id);
  }

  @override
  Future<void> remove(String id) => _dao.remove(id);

  PairedDevice _toDomain(PairedDevicesTableData row) => PairedDevice(
        id: row.id,
        workspaceId: row.workspaceId,
        label: row.label,
        platform: row.platform,
        pskRef: row.pskRef,
        remoteFingerprint: row.remoteFingerprint,
        status: row.status,
        pairedAt: row.pairedAt,
        lastSeenAt: row.lastSeenAt,
        expiresAt: row.expiresAt,
      );
}
