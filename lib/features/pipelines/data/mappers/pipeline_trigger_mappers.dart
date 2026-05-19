import 'dart:convert';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
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
    matchJson: Value(jsonEncode(t.match)),
    lastFiredAt: Value(t.lastFiredAt),
    createdAt: Value(t.createdAt),
  );
}

/// Converts Drift row to domain [PipelineTrigger].
PipelineTrigger triggerFromRow(PipelineTriggersTableData row) {
  Map<String, dynamic> match = const {};
  try {
    final decoded = jsonDecode(row.matchJson);
    if (decoded is Map<String, dynamic>) match = decoded;
  } on FormatException {
    // Malformed filter — treat as "match everything".
  }
  return PipelineTrigger(
    id: row.id,
    eventType: row.eventType,
    templateId: row.templateId,
    workspaceId: row.workspaceId,
    enabled: row.enabled,
    cronExpression: row.cronExpression,
    match: match,
    lastFiredAt: row.lastFiredAt,
    createdAt: row.createdAt,
  );
}

/// Generates a new UUID.
String newTriggerId() => const Uuid().v4();
