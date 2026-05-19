import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:dio/dio.dart';

/// [TicketSyncAdapter] for ClickUp, over the REST v2 API. `vendorProjectId` is
/// the ClickUp **list id** that tickets sync into. Construct from a [Dio]
/// authorized with the caller's personal token (`Authorization: <token>`,
/// no `Bearer` prefix) and based at `https://api.clickup.com`.
///
/// Simpler than the Jira adapter: ClickUp descriptions are plain text/markdown
/// (no ADF), and a task's status is a direct field set by name (no transition
/// workflow), so a status change is a single `PUT` with `{status: "<name>"}`.
class ClickUpTicketSyncAdapter implements TicketSyncAdapter {
  /// Creates a [ClickUpTicketSyncAdapter] over an authorized [Dio].
  ClickUpTicketSyncAdapter(this._dio);

  final Dio _dio;

  @override
  String get vendorId => 'clickup';

  @override
  List<String> get allowedDomains => const ['clickup.com', 'api.clickup.com'];

  @override
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v2/list/$vendorProjectId/task',
      queryParameters: {
        'subtasks': true,
        'order_by': 'updated',
        if (since != null)
          'date_updated_gt': since.millisecondsSinceEpoch.toString(),
      },
    );
    final tasks = (response.data?['tasks'] as List?) ?? const [];
    return tasks.whereType<Map<String, dynamic>>().map(_toDelta).toList();
  }

  @override
  Future<TicketPushOutcome?> pushChange({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
    String? externalId,
    String vendorProjectId = '',
  }) async {
    if (externalId == null || externalId.isEmpty) {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v2/list/$vendorProjectId/task',
        data: {
          'name': ticket.title,
          if (ticket.description != null) 'description': ticket.description,
          if (_priorityInt(ticket.priority) != null)
            'priority': _priorityInt(ticket.priority),
        },
      );
      final data = response.data ?? const {};
      return TicketPushOutcome(
        externalId: '${data['id'] ?? ''}',
        url: data['url'] as String?,
      );
    }

    switch (changeType) {
      case TicketChangeType.statusChanged:
        // ClickUp sets status directly by name — no transition workflow.
        await _dio.put<void>(
          '/api/v2/task/$externalId',
          data: {'status': mapCcStatus(ticket.status)},
        );
      case TicketChangeType.created:
      case TicketChangeType.updated:
        await _dio.put<void>(
          '/api/v2/task/$externalId',
          data: {
            'name': ticket.title,
            if (ticket.description != null) 'description': ticket.description,
          },
        );
      case TicketChangeType.assigned:
      case TicketChangeType.commented:
      case TicketChangeType.deleted:
        break;
    }
    return TicketPushOutcome(externalId: externalId);
  }

  @override
  Future<String?> resolveVendorUrl(String url) async {
    // e.g. https://app.clickup.com/t/86abc123  (optionally /t/<team>/<id>)
    final match = RegExp(
      r'clickup\.com/t/(?:[0-9]+/)?([A-Za-z0-9]+)',
    ).firstMatch(url);
    return match?.group(1);
  }

  @override
  TicketStatus mapVendorStatus(String vendorStatus) =>
      normalizeVendorStatus(vendorStatus);

  @override
  String mapCcStatus(TicketStatus ccStatus) => ccStatus.name;

  /// ClickUp's create endpoint takes an integer priority: 1=urgent … 4=low,
  /// null = unset.
  static int? _priorityInt(TicketPriority p) => switch (p) {
    TicketPriority.urgent => 1,
    TicketPriority.high => 2,
    TicketPriority.medium => 3,
    TicketPriority.low => 4,
    TicketPriority.none => null,
  };

  static TicketPriority? _priorityFromField(Object? raw) {
    // ClickUp returns priority as {id, priority: "urgent"|...} or null.
    if (raw is! Map) {
      return null;
    }
    final name = '${raw['priority']}'.toLowerCase();
    if (name.contains('urgent')) {
      return TicketPriority.urgent;
    }
    if (name.contains('high')) {
      return TicketPriority.high;
    }
    if (name.contains('normal') || name.contains('medium')) {
      return TicketPriority.medium;
    }
    if (name.contains('low')) {
      return TicketPriority.low;
    }
    return null;
  }

  TicketSyncDelta _toDelta(Map<String, dynamic> task) {
    final statusName = (task['status'] is Map)
        ? '${(task['status'] as Map)['status']}'
        : null;
    final assignees = task['assignees'];
    final firstAssignee =
        (assignees is List && assignees.isNotEmpty && assignees.first is Map)
        ? '${(assignees.first as Map)['id']}'
        : null;
    final updatedMs = task['date_updated'];
    return TicketSyncDelta(
      externalId: '${task['id'] ?? ''}',
      url: task['url'] as String?,
      title: task['name'] as String?,
      // ClickUp exposes both a rich `description` and a flat `text_content`.
      description:
          (task['text_content'] as String?) ?? (task['description'] as String?),
      priority: _priorityFromField(task['priority']),
      status: statusName == null ? null : normalizeVendorStatus(statusName),
      rawStatus: statusName,
      assigneeExternalId: firstAssignee,
      updatedAt: updatedMs is String
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(updatedMs) ?? 0,
              isUtc: true,
            )
          : null,
    );
  }
}
