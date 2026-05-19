import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Converts domain [PipelineTrigger] to Drift companion.
PipelineTriggersTableCompanion triggerToCompanion(PipelineTrigger t) {
  return PipelineTriggersTableCompanion(
    id: Value(t.id),
    eventType: Value(t.eventType),
    templateId: Value(t.templateId),
    workspaceId: Value(t.workspaceId),
    enabled: Value(t.enabled),
    cronExpression: Value(t.cronExpression),
    timezone: Value(t.timezone),
    nextRunAt: Value(t.nextRunAt?.toUtc()),
    webhookToken: Value(t.webhookToken),
    eventFiltersJson: Value(jsonEncode(t.eventFilters)),
    matchJson: Value(jsonEncode(t.match)),
    lastFiredAt: Value(t.lastFiredAt),
    catchUpPolicy: Value(t.catchUpPolicy.name),
    createdAt: Value(t.createdAt),
  );
}

/// Converts Drift row to domain [PipelineTrigger].
PipelineTrigger triggerFromRow(PipelineTriggersTableData row) {
  return PipelineTrigger(
    id: row.id,
    eventType: row.eventType,
    templateId: row.templateId,
    workspaceId: row.workspaceId,
    enabled: row.enabled,
    cronExpression: row.cronExpression,
    timezone: row.timezone,
    nextRunAt: row.nextRunAt,
    webhookToken: row.webhookToken,
    eventFilters: _decodeMap(row.eventFiltersJson),
    match: _decodeMap(row.matchJson),
    lastFiredAt: row.lastFiredAt,
    catchUpPolicy: CronCatchUpPolicy.fromName(row.catchUpPolicy),
    createdAt: row.createdAt,
  );
}

Map<String, dynamic> _decodeMap(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException {
    // Malformed JSON — treat as empty.
  }
  return const {};
}

/// Generates a new UUID.
String newTriggerId() => const Uuid().v4();
