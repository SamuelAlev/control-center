import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:dio/dio.dart';

/// [TicketSyncAdapter] for GitHub Issues, over the REST API. `vendorProjectId`
/// is the `owner/repo` slug. Construct from a [Dio] authorized with a GitHub
/// token and based at `https://api.github.com`.
class GitHubIssuesTicketSyncAdapter implements TicketSyncAdapter {
  /// Creates a [GitHubIssuesTicketSyncAdapter] over an authorized [Dio].
  GitHubIssuesTicketSyncAdapter(this._dio);

  final Dio _dio;

  @override
  String get vendorId => 'github';

  @override
  List<String> get allowedDomains => const ['github.com', 'api.github.com'];

  ({String owner, String repo}) _split(String slug) {
    final parts = slug.split('/');
    if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
      throw StateError(
        'GitHub sync requires vendorProjectId as "owner/repo" (got "$slug").',
      );
    }
    return (owner: parts[0], repo: parts[1]);
  }

  @override
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  }) async {
    final r = _split(vendorProjectId);
    final response = await _dio.get<List<dynamic>>(
      '/repos/${r.owner}/${r.repo}/issues',
      queryParameters: {
        'state': 'all',
        'per_page': 100,
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );
    final items = response.data ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        // Exclude PRs: the issues endpoint returns PRs too, flagged by a
        // `pull_request` key.
        .where((i) => i['pull_request'] == null)
        .map(_toDelta)
        .toList();
  }

  @override
  Future<TicketPushOutcome?> pushChange({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
    String? externalId,
    String vendorProjectId = '',
  }) async {
    final r = _split(vendorProjectId);
    final base = '/repos/${r.owner}/${r.repo}/issues';

    if (externalId == null || externalId.isEmpty) {
      final response = await _dio.post<Map<String, dynamic>>(
        base,
        data: {
          'title': ticket.title,
          if (ticket.description != null) 'body': ticket.description,
          if (ticket.labels.isNotEmpty) 'labels': ticket.labels,
        },
      );
      final issue = response.data ?? const {};
      final number = (issue['number'] as num?)?.toInt();
      return TicketPushOutcome(
        externalId: '${number ?? ''}',
        externalKey: number == null ? null : '#$number',
        url: issue['html_url'] as String?,
      );
    }

    final issueUrl = '$base/$externalId';
    switch (changeType) {
      case TicketChangeType.statusChanged:
        await _dio.patch<Map<String, dynamic>>(
          issueUrl,
          data: _stateBody(ticket.status),
        );
      case TicketChangeType.created:
      case TicketChangeType.updated:
        await _dio.patch<Map<String, dynamic>>(
          issueUrl,
          data: {
            'title': ticket.title,
            if (ticket.description != null) 'body': ticket.description,
            if (ticket.labels.isNotEmpty) 'labels': ticket.labels,
          },
        );
      case TicketChangeType.deleted:
        // REST cannot delete an issue; close it as not-planned.
        await _dio.patch<Map<String, dynamic>>(
          issueUrl,
          data: {'state': 'closed', 'state_reason': 'not_planned'},
        );
      case TicketChangeType.commented:
      case TicketChangeType.assigned:
        // Comments are posted through the messaging path; a CC agent id has no
        // GitHub-login counterpart. Neither is mirrored here.
        break;
    }
    return TicketPushOutcome(
      externalId: externalId,
      externalKey: '#$externalId',
    );
  }

  @override
  Future<String?> resolveVendorUrl(String url) async {
    final match = RegExp(
      r'github\.com/[^/]+/[^/]+/issues/(\d+)',
    ).firstMatch(url);
    return match?.group(1);
  }

  @override
  TicketStatus mapVendorStatus(String vendorStatus) =>
      normalizeVendorStatus(vendorStatus);

  @override
  String mapCcStatus(TicketStatus ccStatus) =>
      (ccStatus == TicketStatus.done ||
          ccStatus == TicketStatus.cancelled ||
          ccStatus == TicketStatus.failed)
      ? 'closed'
      : 'open';

  Map<String, dynamic> _stateBody(TicketStatus status) {
    switch (status) {
      case TicketStatus.done:
        return {'state': 'closed', 'state_reason': 'completed'};
      case TicketStatus.cancelled:
      case TicketStatus.failed:
        return {'state': 'closed', 'state_reason': 'not_planned'};
      case TicketStatus.backlog:
      case TicketStatus.open:
      case TicketStatus.inProgress:
      case TicketStatus.blocked:
      case TicketStatus.inReview:
        return {'state': 'open'};
    }
  }

  TicketSyncDelta _toDelta(Map<String, dynamic> i) {
    final number = (i['number'] as num?)?.toInt();
    final state = i['state'] as String? ?? 'open';
    final labels =
        (i['labels'] as List?)
            ?.whereType<Map>()
            .map((l) => '${l['name']}')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    return TicketSyncDelta(
      externalId: '${number ?? ''}',
      externalKey: number == null ? null : '#$number',
      url: i['html_url'] as String?,
      title: i['title'] as String?,
      description: i['body'] as String?,
      labels: labels,
      status: normalizeVendorStatus(state),
      rawStatus: state,
      assigneeExternalId: (i['assignee'] is Map)
          ? '${(i['assignee'] as Map)['login']}'
          : null,
      updatedAt: i['updated_at'] is String
          ? DateTime.tryParse(i['updated_at'] as String)
          : null,
    );
  }
}
