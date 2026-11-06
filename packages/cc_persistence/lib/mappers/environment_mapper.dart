import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Rows ↔ entities for the environment tables.
///
/// Timestamps come back in UTC, the zone every wire form in these entities
/// uses: `DateTime ==` compares zones, so a local value would never equal the
/// entity it was saved from.
class EnvironmentMapper {
  /// Creates an [EnvironmentMapper].
  const EnvironmentMapper();

  /// Row → entity. Rows carry no workspace column, so the caller names the file
  /// they came from.
  EnvironmentDefinitionRecord definitionFromRow(
    EnvironmentDefinitionsTableData row,
    String workspaceId,
  ) => EnvironmentDefinitionRecord(
    id: row.id,
    workspaceId: workspaceId,
    name: row.name,
    definitionJson: row.definitionJson,
    sourceRepoId: row.sourceRepoId,
    sourcePath: row.sourcePath,
    approvedBlobHash: row.approvedBlobHash,
    overridesJson: row.overridesJson,
    createdBy: row.createdBy,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );

  /// Entity → row.
  EnvironmentDefinitionsTableCompanion definitionToCompanion(
    EnvironmentDefinitionRecord record,
  ) => EnvironmentDefinitionsTableCompanion(
    id: Value(record.id),
    name: Value(record.name),
    definitionJson: Value(record.definitionJson),
    sourceRepoId: Value(record.sourceRepoId),
    sourcePath: Value(record.sourcePath),
    approvedBlobHash: Value(record.approvedBlobHash),
    overridesJson: Value(record.overridesJson),
    createdBy: Value(record.createdBy),
    createdAt: Value(record.createdAt),
    updatedAt: Value(record.updatedAt),
  );

  /// Row → entity.
  ///
  /// Tolerant of JSON it can't read, because boot reconciliation walks every
  /// row and one bad field must not stop the rest: a row we half understand
  /// still has to be stoppable.
  SpaceEnvironment environmentFromRow(
    SpaceEnvironmentsTableData row,
    String workspaceId,
  ) => SpaceEnvironment(
    id: row.id,
    workspaceId: workspaceId,
    spaceId: row.spaceId,
    definitionId: row.definitionId,
    name: row.name,
    status: EnvironmentStatus.fromWire(row.status),
    ports: {
      for (final entry in _object(row.portsJson).entries)
        if (entry.value case final num port) entry.key: port.toInt(),
    },
    endpoints: [
      for (final endpoint in _array(row.endpointsJson))
        ?EnvironmentEndpoint.tryFromJson(endpoint),
    ],
    components: [
      for (final component in _array(row.componentsJson))
        ?_component(component),
    ],
    options: _object(row.optionsJson),
    warnings: [for (final warning in _array(row.warningsJson)) '$warning'],
    lastError: EnvironmentError.tryFromJson(
      row.lastErrorJson == null ? null : _object(row.lastErrorJson!),
    ),
    needsRecreate: row.needsRecreate,
    placement: row.placement,
    rigId: row.rigId,
    createdBy: row.createdBy,
    createdAt: row.createdAt.toUtc(),
    lastUsedAt: row.lastUsedAt.toUtc(),
  );

  /// Entity → row.
  SpaceEnvironmentsTableCompanion environmentToCompanion(
    SpaceEnvironment environment,
  ) {
    final lastError = environment.lastError;
    return SpaceEnvironmentsTableCompanion(
      id: Value(environment.id),
      spaceId: Value(environment.spaceId),
      definitionId: Value(environment.definitionId),
      name: Value(environment.name),
      status: Value(environment.status.wire),
      placement: Value(environment.placement),
      rigId: Value(environment.rigId),
      portsJson: Value(jsonEncode(environment.ports)),
      endpointsJson: Value(
        jsonEncode([
          for (final endpoint in environment.endpoints) endpoint.toJson(),
        ]),
      ),
      componentsJson: Value(
        jsonEncode([
          for (final component in environment.components) component.toJson(),
        ]),
      ),
      optionsJson: Value(jsonEncode(environment.options)),
      warningsJson: Value(jsonEncode(environment.warnings)),
      lastErrorJson: Value(
        lastError == null ? null : jsonEncode(lastError.toJson()),
      ),
      needsRecreate: Value(environment.needsRecreate),
      createdBy: Value(environment.createdBy),
      createdAt: Value(environment.createdAt),
      lastUsedAt: Value(environment.lastUsedAt),
    );
  }

  /// Row → entity.
  EnvironmentRun runFromRow(EnvironmentRunsTableData row) => EnvironmentRun(
    id: row.id,
    workspaceId: row.workspaceId,
    spaceId: row.spaceId,
    environmentId: row.environmentId,
    definitionId: row.definitionId,
    repoId: row.repoId,
    kind: EnvironmentRunKind.parse(row.kind),
    label: row.label,
    status: EnvironmentRunStatus.parse(row.status),
    startedAt: row.startedAt.toUtc(),
    completedAt: row.completedAt?.toUtc(),
    exitCode: row.exitCode,
    error: row.error,
    output: row.outputText,
  );

  /// Entity → row.
  EnvironmentRunsTableCompanion runToCompanion(EnvironmentRun run) =>
      EnvironmentRunsTableCompanion(
        id: Value(run.id),
        workspaceId: Value(run.workspaceId),
        spaceId: Value(run.spaceId),
        environmentId: Value(run.environmentId),
        definitionId: Value(run.definitionId),
        repoId: Value(run.repoId),
        kind: Value(run.kind.name),
        label: Value(run.label),
        status: Value(run.status.name),
        startedAt: Value(run.startedAt),
        completedAt: Value(run.completedAt),
        exitCode: Value(run.exitCode),
        error: Value(run.error),
        outputText: Value(run.output),
      );

  /// Row → entity.
  EnvironmentLease leaseFromRow(EnvironmentSlotLeasesTableData row) =>
      EnvironmentLease(
        block: row.block,
        firstPort: row.firstPort,
        size: row.size,
        workspaceId: row.workspaceId,
        spaceId: row.spaceId,
        definitionId: row.definitionId,
        createdAt: row.createdAt.toUtc(),
        poolKey: row.poolKey,
        poolSlot: row.poolSlot,
      );

  /// Entity → row.
  EnvironmentSlotLeasesTableCompanion leaseToCompanion(
    EnvironmentLease lease,
  ) => EnvironmentSlotLeasesTableCompanion(
    block: Value(lease.block),
    firstPort: Value(lease.firstPort),
    size: Value(lease.size),
    workspaceId: Value(lease.workspaceId),
    spaceId: Value(lease.spaceId),
    definitionId: Value(lease.definitionId),
    poolKey: Value(lease.poolKey),
    poolSlot: Value(lease.poolSlot),
    createdAt: Value(lease.createdAt),
  );

  static Map<String, dynamic> _object(String text) {
    final decoded = _decode(text);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
  }

  static List<Object?> _array(String text) {
    final decoded = _decode(text);
    return decoded is List ? decoded : const [];
  }

  static Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static EnvironmentComponentState? _component(Object? json) {
    if (json is! Map) {
      return null;
    }
    try {
      return EnvironmentComponentState.fromJson(
        Map<String, dynamic>.from(json),
      );
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }
}
