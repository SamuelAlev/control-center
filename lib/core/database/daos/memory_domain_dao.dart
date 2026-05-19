import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_domains.dart';
import 'package:drift/drift.dart';

part 'memory_domain_dao.g.dart';

@DriftAccessor(tables: [MemoryDomainsTable])
/// Data access for memory domains.
class MemoryDomainDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryDomainDaoMixin {
  /// Creates a [MemoryDomainDao].
  MemoryDomainDao(super.attachedDatabase);

  /// Watches domains in a workspace, sorted by name.
  Stream<List<MemoryDomainsTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryDomainsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Reads domains in a workspace, sorted by name.
  Future<List<MemoryDomainsTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryDomainsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Looks up a domain by name within a workspace.
  Future<MemoryDomainsTableData?> findByName(
    String workspaceId,
    String name,
  ) =>
      (select(memoryDomainsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.name.equals(name),
            ))
          .getSingleOrNull();

  /// Upserts a domain keyed on its natural identity `(workspaceId, name)`.
  ///
  /// We deliberately target the `(workspaceId, name)` unique index rather than
  /// the `id` primary key. Domains are looked up and referenced by their slug
  /// (`name`), and each `ResolveOrCreateDomainUseCase.execute` mints a fresh
  /// `id` for a domain it believes is new. When two `propose_fact` calls race
  /// for the same new slug, both pass the `findByName` check and attempt to
  /// insert with different UUIDs — `insertOnConflictUpdate` (which conflicts on
  /// `id`) would then trip the `(workspaceId, name)` unique constraint and
  /// throw. Targeting the natural key makes the second write an idempotent
  /// update, preserving the original row's `id` and `createdAt`.
  Future<void> upsert(MemoryDomainsTableCompanion entry) =>
      into(memoryDomainsTable).insert(
        entry,
        onConflict: DoUpdate(
          (_) => MemoryDomainsTableCompanion(
            label: entry.label,
            description: entry.description,
            createdByRole: entry.createdByRole,
          ),
          target: [memoryDomainsTable.workspaceId, memoryDomainsTable.name],
        ),
      );
}
