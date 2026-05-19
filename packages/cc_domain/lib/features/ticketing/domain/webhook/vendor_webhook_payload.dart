import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';

/// The normalized result of parsing one inbound vendor webhook delivery.
class WebhookParseResult {
  /// Creates a [WebhookParseResult].
  const WebhookParseResult({
    required this.vendor,
    required this.deltas,
    this.eventType,
    this.dedupeKey,
  });

  /// An empty result (an event we recognize but do not act on).
  const WebhookParseResult.empty(this.vendor, {this.eventType, this.dedupeKey})
    : deltas = const [];

  /// Vendor identifier.
  final String vendor;

  /// The vendor event type (e.g. `issues.opened`, `jira:issue_updated`).
  final String? eventType;

  /// Idempotency token for the delivery (e.g. a delivery id header).
  final String? dedupeKey;

  /// Normalized deltas to apply.
  final List<TicketSyncDelta> deltas;
}

/// Parses a vendor webhook body (already JSON-decoded) into provider-neutral
/// [TicketSyncDelta]s. Vendor-specific JSON shapes live here and nowhere else;
/// the sync engine only ever sees the normalized deltas.
///
/// Parsing is defensive: a malformed / partial body yields an empty result
/// rather than throwing, so a noisy vendor never crashes the webhook handler.
class VendorWebhookParser {
  /// Creates a [VendorWebhookParser].
  const VendorWebhookParser();

  /// Parses [body] for [vendor]. [deliveryId] (a header value) becomes the
  /// dedupe key when present.
  WebhookParseResult parse(
    String vendor,
    Map<String, dynamic> body, {
    String? deliveryId,
  }) {
    switch (vendor) {
      case 'github':
        return _github(body, deliveryId);
      case 'linear':
        return _linear(body, deliveryId);
      case 'jira':
        return _jira(body, deliveryId);
      default:
        return WebhookParseResult.empty(vendor, dedupeKey: deliveryId);
    }
  }

  WebhookParseResult _github(Map<String, dynamic> body, String? deliveryId) {
    final action = body['action'] as String?;
    final issue = body['issue'];
    if (issue is! Map) {
      return WebhookParseResult.empty(
        'github',
        eventType: action,
        dedupeKey: deliveryId,
      );
    }
    final number = (issue['number'] as num?)?.toInt();
    if (number == null) {
      return WebhookParseResult.empty(
        'github',
        eventType: action,
        dedupeKey: deliveryId,
      );
    }
    final state = issue['state'] as String? ?? 'open';
    final labels =
        (issue['labels'] as List?)
            ?.whereType<Map>()
            .map((l) => '${l['name']}')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final delta = TicketSyncDelta(
      externalId: '$number',
      externalKey: '#$number',
      url: issue['html_url'] as String?,
      title: issue['title'] as String?,
      description: issue['body'] as String?,
      labels: labels,
      status: normalizeVendorStatus(state),
      rawStatus: state,
      assigneeExternalId: (issue['assignee'] is Map)
          ? '${(issue['assignee'] as Map)['login']}'
          : null,
      updatedAt: _parseTime(issue['updated_at']),
      deleted: action == 'deleted',
      dedupeKey: deliveryId,
    );
    return WebhookParseResult(
      vendor: 'github',
      eventType: action == null ? 'issues' : 'issues.$action',
      dedupeKey: deliveryId,
      deltas: [delta],
    );
  }

  WebhookParseResult _linear(Map<String, dynamic> body, String? deliveryId) {
    final action = body['action'] as String?;
    final data = body['data'];
    if (data is! Map) {
      return WebhookParseResult.empty(
        'linear',
        eventType: action,
        dedupeKey: deliveryId,
      );
    }
    final id = data['id'] as String?;
    if (id == null) {
      return WebhookParseResult.empty(
        'linear',
        eventType: action,
        dedupeKey: deliveryId,
      );
    }
    final stateName = (data['state'] is Map)
        ? '${(data['state'] as Map)['name']}'
        : null;
    final labels =
        (data['labels'] as List?)
            ?.whereType<Map>()
            .map((l) => '${l['name']}')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final delta = TicketSyncDelta(
      externalId: id,
      externalKey: data['identifier'] as String?,
      url: (data['url'] ?? body['url']) as String?,
      title: data['title'] as String?,
      description: data['description'] as String?,
      priority: data['priority'] is num
          ? TicketPriority.fromStorage((data['priority'] as num).toInt())
          : null,
      labels: labels,
      status: stateName == null ? null : normalizeVendorStatus(stateName),
      rawStatus: stateName,
      assigneeExternalId: data['assigneeId'] as String?,
      updatedAt: _parseTime(data['updatedAt']),
      deleted: action == 'remove',
      dedupeKey: deliveryId,
    );
    return WebhookParseResult(
      vendor: 'linear',
      eventType: action,
      dedupeKey: deliveryId,
      deltas: [delta],
    );
  }

  WebhookParseResult _jira(Map<String, dynamic> body, String? deliveryId) {
    final event = body['webhookEvent'] as String?;
    final issue = body['issue'];
    if (issue is! Map) {
      return WebhookParseResult.empty(
        'jira',
        eventType: event,
        dedupeKey: deliveryId,
      );
    }
    final id = issue['id'] as String?;
    if (id == null) {
      return WebhookParseResult.empty(
        'jira',
        eventType: event,
        dedupeKey: deliveryId,
      );
    }
    final fields = issue['fields'];
    final f = fields is Map ? fields : const {};
    final statusName = (f['status'] is Map)
        ? '${(f['status'] as Map)['name']}'
        : null;
    final labels =
        (f['labels'] as List?)
            ?.map((l) => '$l')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final delta = TicketSyncDelta(
      externalId: id,
      externalKey: issue['key'] as String?,
      title: f['summary'] as String?,
      description: f['description'] as String?,
      priority: _jiraPriority(f['priority']),
      labels: labels,
      status: statusName == null ? null : normalizeVendorStatus(statusName),
      rawStatus: statusName,
      assigneeExternalId: (f['assignee'] is Map)
          ? '${(f['assignee'] as Map)['accountId']}'
          : null,
      updatedAt: _parseTime(f['updated']),
      deleted: event != null && event.contains('deleted'),
      dedupeKey: deliveryId,
    );
    return WebhookParseResult(
      vendor: 'jira',
      eventType: event,
      dedupeKey: deliveryId,
      deltas: [delta],
    );
  }

  static TicketPriority? _jiraPriority(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final name = '${raw['name']}'.toLowerCase();
    if (name.contains('highest') ||
        name.contains('urgent') ||
        name.contains('critical')) {
      return TicketPriority.urgent;
    }
    if (name.contains('high')) {
      return TicketPriority.high;
    }
    if (name.contains('medium') || name.contains('normal')) {
      return TicketPriority.medium;
    }
    if (name.contains('low')) {
      return TicketPriority.low;
    }
    return null;
  }

  static DateTime? _parseTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
