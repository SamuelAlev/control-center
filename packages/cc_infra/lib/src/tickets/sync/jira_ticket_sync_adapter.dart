import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:dio/dio.dart';

/// [TicketSyncAdapter] for Jira Cloud, over the REST v3 API. `vendorProjectId`
/// is the Jira project key (e.g. `PROJ`). Construct from a [Dio] authorized with
/// Basic auth (email:api-token) and based at the site's
/// `https://<site>.atlassian.net`.
class JiraTicketSyncAdapter implements TicketSyncAdapter {
  /// Creates a [JiraTicketSyncAdapter] over an authorized [Dio].
  JiraTicketSyncAdapter(this._dio, {this.issueTypeName = 'Task'});

  final Dio _dio;

  /// Issue type used when creating issues.
  final String issueTypeName;

  @override
  String get vendorId => 'jira';

  @override
  List<String> get allowedDomains => const ['atlassian.net'];

  @override
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rest/api/3/search',
      queryParameters: {
        'jql': 'project = "$vendorProjectId" ORDER BY updated DESC',
        'maxResults': 100,
        'fields': 'summary,description,status,priority,assignee,labels,updated',
      },
    );
    final issues = (response.data?['issues'] as List?) ?? const [];
    return issues.whereType<Map<String, dynamic>>().map(_toDelta).toList();
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
        '/rest/api/3/issue',
        data: {
          'fields': {
            'project': {'key': vendorProjectId},
            'summary': ticket.title,
            if (ticket.description != null)
              'description': _adf(ticket.description!),
            'issuetype': {'name': issueTypeName},
            if (_priorityName(ticket.priority) != null)
              'priority': {'name': _priorityName(ticket.priority)},
          },
        },
      );
      final data = response.data ?? const {};
      return TicketPushOutcome(
        externalId: '${data['id'] ?? ''}',
        externalKey: data['key'] as String?,
        url: data['self'] as String?,
      );
    }

    switch (changeType) {
      case TicketChangeType.statusChanged:
        await _transition(externalId, ticket.status);
      case TicketChangeType.created:
      case TicketChangeType.updated:
        await _dio.put<void>(
          '/rest/api/3/issue/$externalId',
          data: {
            'fields': {
              'summary': ticket.title,
              if (ticket.description != null)
                'description': _adf(ticket.description!),
            },
          },
        );
      case TicketChangeType.assigned:
      case TicketChangeType.commented:
      case TicketChangeType.deleted:
        break;
    }
    return TicketPushOutcome(externalId: externalId);
  }

  Future<void> _transition(String issueIdOrKey, TicketStatus target) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rest/api/3/issue/$issueIdOrKey/transitions',
    );
    final transitions = (response.data?['transitions'] as List?) ?? const [];
    for (final t in transitions.whereType<Map<String, dynamic>>()) {
      final toName = (t['to'] is Map) ? '${(t['to'] as Map)['name']}' : '';
      if (normalizeVendorStatus(toName) == target) {
        await _dio.post<void>(
          '/rest/api/3/issue/$issueIdOrKey/transitions',
          data: {
            'transition': {'id': t['id']},
          },
        );
        return;
      }
    }
  }

  @override
  Future<String?> resolveVendorUrl(String url) async {
    final match = RegExp(
      r'atlassian\.net/browse/([A-Z][A-Z0-9]+-\d+)',
    ).firstMatch(url);
    return match?.group(1);
  }

  @override
  TicketStatus mapVendorStatus(String vendorStatus) =>
      normalizeVendorStatus(vendorStatus);

  @override
  String mapCcStatus(TicketStatus ccStatus) => ccStatus.name;

  static String? _priorityName(TicketPriority p) => switch (p) {
    TicketPriority.urgent => 'Highest',
    TicketPriority.high => 'High',
    TicketPriority.medium => 'Medium',
    TicketPriority.low => 'Low',
    TicketPriority.none => null,
  };

  /// Wraps plain text in Atlassian Document Format (required by REST v3).
  static Map<String, dynamic> _adf(String text) => {
    'type': 'doc',
    'version': 1,
    'content': [
      {
        'type': 'paragraph',
        'content': [
          {'type': 'text', 'text': text},
        ],
      },
    ],
  };

  TicketSyncDelta _toDelta(Map<String, dynamic> issue) {
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
    return TicketSyncDelta(
      externalId: '${issue['id'] ?? ''}',
      externalKey: issue['key'] as String?,
      title: f['summary'] as String?,
      description: _plainFromAdf(f['description']),
      priority: _priorityFromName(f['priority']),
      labels: labels,
      status: statusName == null ? null : normalizeVendorStatus(statusName),
      rawStatus: statusName,
      assigneeExternalId: (f['assignee'] is Map)
          ? '${(f['assignee'] as Map)['accountId']}'
          : null,
      updatedAt: f['updated'] is String
          ? DateTime.tryParse(f['updated'] as String)
          : null,
    );
  }

  static TicketPriority? _priorityFromName(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final name = '${raw['name']}'.toLowerCase();
    if (name.contains('highest') || name.contains('critical')) {
      return TicketPriority.urgent;
    }
    if (name.contains('high')) {
      return TicketPriority.high;
    }
    if (name.contains('medium')) {
      return TicketPriority.medium;
    }
    if (name.contains('low')) {
      return TicketPriority.low;
    }
    return null;
  }

  /// Flattens an ADF description into plain text (best-effort).
  static String? _plainFromAdf(Object? adf) {
    if (adf is String) {
      return adf;
    }
    if (adf is! Map) {
      return null;
    }
    final buffer = StringBuffer();
    void walk(Object? node) {
      if (node is Map) {
        if (node['type'] == 'text' && node['text'] is String) {
          buffer.write(node['text']);
        }
        final content = node['content'];
        if (content is List) {
          for (final child in content) {
            walk(child);
          }
        }
      }
    }

    walk(adf);
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }
}
