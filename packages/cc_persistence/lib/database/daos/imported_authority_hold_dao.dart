import 'package:cc_persistence/database/tables/imported_authority_holds_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'imported_authority_hold_dao.g.dart';

/// Data access for the grants an import held for the server owner.
///
/// Constructed over one workspace's database (`ImportedAuthorityHoldDao(db)`)
/// by the backup service, the only code that writes or resolves holds.
@DriftAccessor(tables: [ImportedAuthorityHoldsTable])
class ImportedAuthorityHoldDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ImportedAuthorityHoldDaoMixin {
  /// Creates an [ImportedAuthorityHoldDao].
  ImportedAuthorityHoldDao(super.db);

  /// Records a hold.
  Future<void> insert(ImportedAuthorityHoldsTableCompanion entry) =>
      into(importedAuthorityHoldsTable).insert(entry);

  /// Every hold, oldest first; `id` breaks ties so the order is stable.
  Future<List<ImportedAuthorityHoldsTableData>> all() =>
      (select(importedAuthorityHoldsTable)..orderBy([
            (t) => OrderingTerm.asc(t.importedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .get();

  /// The hold [id], or null.
  Future<ImportedAuthorityHoldsTableData?> byId(String id) => (select(
    importedAuthorityHoldsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Removes hold [id]. Returns whether it existed.
  Future<bool> remove(String id) async =>
      await (delete(
        importedAuthorityHoldsTable,
      )..where((t) => t.id.equals(id))).go() >
      0;
}
