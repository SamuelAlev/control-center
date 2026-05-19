import 'package:drift/drift.dart';

/// Migration step.
class MigrationStep {
  /// Creates a migration step from [from] to [to].
  const MigrationStep(this.from, this.to, this.migrate);

  /// Source schema version.
  final int from;

  /// Target schema version.
  final int to;

  /// Migration logic executed by Drift.
  final Future<void> Function(Migrator m) migrate;
}
