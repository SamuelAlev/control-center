import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_persistence/database/tables/environment_definitions.dart';
import 'package:cc_persistence/database/tables/environment_runs.dart';
import 'package:cc_persistence/database/tables/space_environments.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'environment_dao.g.dart';

/// Data access object for the environment tables of ONE workspace.
///
/// Every method is scoped by hanging off a [WorkspaceDatabase]: the isolation
/// boundary is the database file.
@DriftAccessor(
  tables: [
    EnvironmentDefinitionsTable,
    SpaceEnvironmentsTable,
    EnvironmentRunsTable,
  ],
)
class EnvironmentDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$EnvironmentDaoMixin {
  /// Creates an [EnvironmentDao] bound to one workspace's database.
  EnvironmentDao(super.attachedDatabase);

  /// How many finished runs are kept per definition, newest first. Runs with
  /// no definition share one allowance. Pruned on every insert so the table
  /// stays bounded without a sweeper.
  static const int retentionPerDefinition = 100;

  /// The longest output tail stored, in UTF-16 code units.
  static const int maxOutputChars = 64 * 1024;

  // ── Definitions ───────────────────────────────────────────────────────────

  /// Every definition, by name.
  Future<List<EnvironmentDefinitionsTableData>> definitions() =>
      (select(environmentDefinitionsTable)..orderBy([
            (t) => OrderingTerm.asc(t.name),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .get();

  /// One definition, or null.
  Future<EnvironmentDefinitionsTableData?> definition(String id) => (select(
    environmentDefinitionsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts or replaces a definition.
  Future<void> upsertDefinition(EnvironmentDefinitionsTableCompanion entry) =>
      into(environmentDefinitionsTable).insertOnConflictUpdate(entry);

  /// Deletes one definition.
  Future<void> deleteDefinition(String id) =>
      (delete(environmentDefinitionsTable)..where((t) => t.id.equals(id))).go();

  // ── Environments ──────────────────────────────────────────────────────────

  /// Every environment, oldest first.
  Future<List<SpaceEnvironmentsTableData>> environments() =>
      (select(spaceEnvironmentsTable)..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.rowId),
          ]))
          .get();

  /// The environments of [spaceId], oldest first.
  Future<List<SpaceEnvironmentsTableData>> environmentsOfSpace(
    String spaceId,
  ) =>
      (select(spaceEnvironmentsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.rowId),
            ]))
          .get();

  /// One environment, or null.
  Future<SpaceEnvironmentsTableData?> environment(String id) => (select(
    spaceEnvironmentsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts or replaces an environment by id.
  ///
  /// The conflict target is the primary key alone, so a second id for the same
  /// space and definition throws. `INSERT OR REPLACE` would instead delete the
  /// existing row, losing track of a stack that is still running.
  Future<void> upsertEnvironment(SpaceEnvironmentsTableCompanion entry) =>
      into(spaceEnvironmentsTable).insertOnConflictUpdate(entry);

  /// Deletes one environment.
  Future<void> deleteEnvironment(String id) =>
      (delete(spaceEnvironmentsTable)..where((t) => t.id.equals(id))).go();

  // ── Runs ──────────────────────────────────────────────────────────────────

  /// Inserts a run and prunes its definition's history past
  /// [retentionPerDefinition].
  ///
  /// Running rows are never pruned, so an in-flight run can't be deleted out
  /// from under its own finish write.
  Future<void> insertRun(EnvironmentRunsTableCompanion entry) async {
    await transaction(() async {
      final output = entry.outputText;
      await into(environmentRunsTable).insert(
        output.present
            ? entry.copyWith(outputText: Value(capOutput(output.value)))
            : entry,
      );
      final table = environmentRunsTable;
      final definitionId = entry.definitionId.present
          ? entry.definitionId.value
          : null;
      final scope = definitionId == null
          ? table.definitionId.isNull()
          : table.definitionId.equals(definitionId);
      final finished =
          scope & table.status.equals(EnvironmentRunStatus.running.name).not();
      final kept =
          await (selectOnly(table)
                ..addColumns([table.id])
                ..where(finished)
                ..orderBy([
                  OrderingTerm.desc(table.startedAt),
                  OrderingTerm.desc(table.rowId),
                ])
                ..limit(retentionPerDefinition))
              .map((row) => row.read(table.id))
              .get();
      await (delete(
        table,
      )..where((_) => finished & table.id.isNotIn(kept.nonNulls))).go();
    });
  }

  /// Replaces a run's output tail.
  Future<void> updateRunOutput(String id, String output) =>
      (update(environmentRunsTable)..where((t) => t.id.equals(id))).write(
        EnvironmentRunsTableCompanion(outputText: Value(capOutput(output))),
      );

  /// Closes a run. A null [output] keeps the tail already stored.
  Future<void> finishRun(
    String id, {
    required String status,
    required DateTime completedAt,
    int? exitCode,
    String? error,
    String? output,
  }) => (update(environmentRunsTable)..where((t) => t.id.equals(id))).write(
    EnvironmentRunsTableCompanion(
      status: Value(status),
      completedAt: Value(completedAt),
      exitCode: Value(exitCode),
      error: Value(error),
      outputText: output == null
          ? const Value.absent()
          : Value(capOutput(output)),
    ),
  );

  /// Recent runs of [spaceId], newest first.
  Future<List<EnvironmentRunsTableData>> runsOfSpace(
    String spaceId, {
    required int limit,
  }) => _recentRuns((t) => t.spaceId.equals(spaceId), limit);

  /// Recent runs of [definitionId], newest first.
  Future<List<EnvironmentRunsTableData>> runsOfDefinition(
    String definitionId, {
    required int limit,
  }) => _recentRuns((t) => t.definitionId.equals(definitionId), limit);

  // Timestamps are whole seconds, and a task and the start after it often share
  // one. The rowid keeps those in insertion order.
  Future<List<EnvironmentRunsTableData>> _recentRuns(
    Expression<bool> Function($EnvironmentRunsTableTable t) filter,
    int limit,
  ) =>
      (select(environmentRunsTable)
            ..where(filter)
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
              (t) => OrderingTerm.desc(t.rowId),
            ])
            ..limit(limit))
          .get();

  /// One run, or null.
  Future<EnvironmentRunsTableData?> run(String id) => (select(
    environmentRunsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Closes every run still `running`, keeping its output tail.
  Future<void> failRunning(DateTime now, {required String error}) =>
      (update(environmentRunsTable)
            ..where((t) => t.status.equals(EnvironmentRunStatus.running.name)))
          .write(
            EnvironmentRunsTableCompanion(
              status: Value(EnvironmentRunStatus.failed.name),
              completedAt: Value(now),
              error: Value(error),
            ),
          );

  /// The last [maxOutputChars] of [output].
  ///
  /// The cut never lands inside a surrogate pair: a lone surrogate would turn
  /// into a replacement character on the way into SQLite.
  static String capOutput(String output) {
    if (output.length <= maxOutputChars) {
      return output;
    }
    var start = output.length - maxOutputChars;
    final first = output.codeUnitAt(start);
    if (first >= 0xDC00 && first <= 0xDFFF) {
      start++;
    }
    return output.substring(start);
  }
}
