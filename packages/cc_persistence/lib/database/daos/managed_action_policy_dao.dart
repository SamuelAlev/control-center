import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/managed_action_policies_table.dart';
import 'package:drift/drift.dart';

part 'managed_action_policy_dao.g.dart';

/// Data access object for the [ManagedActionPoliciesTable] — the install-wide
/// managed policy tier (CROSS-WORKSPACE BY DESIGN; see the table doc).
@DriftAccessor(tables: [ManagedActionPoliciesTable])
class ManagedActionPolicyDao extends DatabaseAccessor<GlobalDatabase>
    with _$ManagedActionPolicyDaoMixin {
  /// Creates a [ManagedActionPolicyDao] bound to the given database.
  ManagedActionPolicyDao(super.attachedDatabase);

  /// Every managed rule on the install.
  Future<List<ManagedActionPoliciesTableData>> all() =>
      select(managedActionPoliciesTable).get();

  /// Streams [all].
  Stream<List<ManagedActionPoliciesTableData>> watchAll() =>
      select(managedActionPoliciesTable).watch();

  /// Inserts or replaces one managed rule.
  Future<void> upsert(ManagedActionPoliciesTableCompanion row) =>
      into(managedActionPoliciesTable)
          .insert(row, mode: InsertMode.insertOrReplace);

  /// Deletes a managed rule by id.
  Future<void> deleteById(String id) =>
      (delete(managedActionPoliciesTable)..where((t) => t.id.equals(id))).go();
}
