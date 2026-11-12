import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Converts domain [PipelineTrigger] to Drift companion. The row keeps
/// [webhookTokenRef], the secrets-store reference of the trigger's token, and
/// never the token.
PipelineTriggersTableCompanion triggerToCompanion(
  PipelineTrigger t, {
  required String? webhookTokenRef,
}) {
  return PipelineTriggersTableCompanion(
    id: Value(t.id),
    eventType: Value(t.eventType),
    templateId: Value(t.templateId),
    workspaceId: Value(t.workspaceId),
    enabled: Value(t.enabled),
    cronExpression: Value(t.cronExpression),
    timezone: Value(t.timezone),
    nextRunAt: Value(t.nextRunAt?.toUtc()),
    webhookTokenRef: Value(webhookTokenRef),
    eventFiltersJson: Value(jsonEncode(t.eventFilters)),
    matchJson: Value(jsonEncode(t.match)),
    lastFiredAt: Value(t.lastFiredAt),
    catchUpPolicy: Value(t.catchUpPolicy.name),
    armedByUserIdsJson: Value(jsonEncode(t.armedByUserIds.toList()..sort())),
    createdAt: Value(t.createdAt),
  );
}

/// Converts Drift row to domain [PipelineTrigger], with [webhookToken] the
/// token resolved from the row's secrets-store reference.
PipelineTrigger triggerFromRow(
  PipelineTriggersTableData row, {
  required String? webhookToken,
}) {
  return PipelineTrigger(
    id: row.id,
    eventType: row.eventType,
    templateId: row.templateId,
    workspaceId: row.workspaceId,
    enabled: row.enabled,
    cronExpression: row.cronExpression,
    timezone: row.timezone,
    nextRunAt: row.nextRunAt,
    webhookToken: webhookToken,
    eventFilters: _decodeMap(row.eventFiltersJson),
    match: _decodeMap(row.matchJson),
    lastFiredAt: row.lastFiredAt,
    catchUpPolicy: CronCatchUpPolicy.fromName(row.catchUpPolicy),
    armedByUserIds: _decodeIds(row.armedByUserIdsJson),
    createdAt: row.createdAt,
  );
}

Set<String> _decodeIds(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return {
        for (final id in decoded)
          if (id is String && id.isNotEmpty) id,
      };
    }
  } on FormatException {
    // Malformed JSON — nobody recorded.
  }
  return const {};
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
