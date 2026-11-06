import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/environment_slot_leases.dart';
import 'package:drift/drift.dart';

part 'environment_lease_dao.g.dart';

/// Data access object for the [EnvironmentSlotLeasesTable] in `global.db`.
///
/// **CROSS-WORKSPACE BY DESIGN**: ports are host-wide, so [all] and [tryInsert]
/// deliberately see every workspace. Everything naming a holder is scoped by
/// its workspace, because a space id is only unique inside one.
@DriftAccessor(tables: [EnvironmentSlotLeasesTable])
class EnvironmentLeaseDao extends DatabaseAccessor<GlobalDatabase>
    with _$EnvironmentLeaseDaoMixin {
  /// Creates an [EnvironmentLeaseDao] for the global database.
  EnvironmentLeaseDao(super.attachedDatabase);

  /// Every lease, by block.
  Future<List<EnvironmentSlotLeasesTableData>> all() => (select(
    environmentSlotLeasesTable,
  )..orderBy([(t) => OrderingTerm.asc(t.block)])).get();

  /// The lease [spaceId] holds for [definitionId], or null.
  Future<EnvironmentSlotLeasesTableData?> forSpace(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) =>
      (select(environmentSlotLeasesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.definitionId.equals(definitionId),
          ))
          .getSingleOrNull();

  /// Inserts [entry]; false when any unique key refuses it.
  ///
  /// That covers a taken block, a taken pool slot, and a holder that already
  /// has a lease: a concurrent start for the same space lost the race, so a
  /// caller seeing false should read [forSpace] before trying the next block.
  ///
  /// The RETURNING row is the only reliable signal. `block` aliases the rowid,
  /// and an ignored insert reports the previous insert's rowid, not a failure.
  Future<bool> tryInsert(EnvironmentSlotLeasesTableCompanion entry) async {
    final inserted = await into(
      environmentSlotLeasesTable,
    ).insertReturningOrNull(entry, mode: InsertMode.insertOrIgnore);
    return inserted != null;
  }

  /// Releases the lease [spaceId] holds for [definitionId].
  Future<void> release(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) =>
      (delete(environmentSlotLeasesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.definitionId.equals(definitionId),
          ))
          .go();

  /// Releases every lease of [spaceId].
  Future<void> releaseSpace(String workspaceId, String spaceId) =>
      (delete(environmentSlotLeasesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
          ))
          .go();
}
