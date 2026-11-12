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

  /// Writes one managed rule, by id or by its subject (one rule per action
  /// class or command prefix), in one statement. Moving a rule onto a subject
  /// another rule holds is refused.
  Future<void> upsert(ManagedActionPoliciesTableCompanion row) {
    final t = managedActionPoliciesTable;
    final update = row.copyWith(id: const Value.absent());
    return into(t).insert(
      row,
      onConflict: UpsertMultiple([
        DoUpdate((_) => update),
        DoUpdate(
          (_) => update,
          target: [t.actionClass],
          targetCondition: (t) => t.actionClass.isNotNull(),
        ),
        DoUpdate(
          (_) => update,
          target: [t.commandPrefix],
          targetCondition: (t) => t.commandPrefix.isNotNull(),
        ),
      ]),
    );
  }

  /// Deletes a managed rule by id.
  Future<void> deleteById(String id) =>
      (delete(managedActionPoliciesTable)..where((t) => t.id.equals(id))).go();
}
