import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart' show Value;

/// Converts a [WebhookDelivery] entity to a Drift companion.
WebhookDeliveriesTableCompanion webhookDeliveryToCompanion(WebhookDelivery d) {
  return WebhookDeliveriesTableCompanion(
    id: Value(d.id),
    workspaceId: Value(d.workspaceId),
    triggerId: Value(d.triggerId),
    status: Value(d.status.toStorageString()),
    signatureStatus: Value(d.signatureStatus.toStorageString()),
    dedupeKey: Value(d.dedupeKey),
    dedupeSource: Value(d.dedupeSource),
    eventAction: Value(d.eventAction),
    rawBody: Value(d.rawBody),
    headersJson: Value(jsonEncode(d.headers)),
    responseStatus: Value(d.responseStatus),
    responseBody: Value(d.responseBody),
    runId: Value(d.runId),
    createdAt: Value(d.createdAt),
  );
}

/// Reconstructs a [WebhookDelivery] from a database row.
WebhookDelivery webhookDeliveryFromRow(WebhookDeliveriesTableData row) {
  return WebhookDelivery(
    id: row.id,
    workspaceId: row.workspaceId,
    triggerId: row.triggerId,
    status: WebhookDeliveryStatus.fromString(row.status),
    signatureStatus: WebhookSignatureStatus.fromString(row.signatureStatus),
    dedupeKey: row.dedupeKey,
    dedupeSource: row.dedupeSource,
    eventAction: row.eventAction,
    rawBody: row.rawBody,
    headers: _decodeHeaders(row.headersJson),
    responseStatus: row.responseStatus,
    responseBody: row.responseBody,
    runId: row.runId,
    createdAt: row.createdAt,
  );
}

Map<String, String> _decodeHeaders(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  } on FormatException {
    // Malformed — empty headers.
  }
  return const {};
}
