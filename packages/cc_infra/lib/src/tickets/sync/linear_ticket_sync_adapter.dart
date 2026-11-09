import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:cc_infra/src/tickets/linear/linear_graphql_client.dart';
import 'package:cc_infra/src/tickets/linear/linear_issue_dto.dart';
import 'package:rhttp/rhttp.dart';

/// [TicketSyncAdapter] for Linear, over its GraphQL API. The only place that
/// knows Linear specifics (status names, the GraphQL client, priority numbers,
/// the required team id).
///
/// [_httpClientFor] resolves the authorized client PER WORKSPACE: each
/// workspace syncs as its own Linear app actor, never another workspace's.
class LinearTicketSyncAdapter implements TicketSyncAdapter {
  /// Creates a [LinearTicketSyncAdapter]. [_defaultTeamId] is used as the create
  /// target when a config's `vendorProjectId` is empty.
  LinearTicketSyncAdapter(this._httpClientFor, {this._defaultTeamId});

  final RhttpClient Function(String workspaceId) _httpClientFor;
  final String? _defaultTeamId;
  final Map<String, LinearGraphQlClient> _clients = {};

  LinearGraphQlClient _client(String workspaceId) => _clients.putIfAbsent(
    workspaceId,
    () => LinearGraphQlClient(_httpClientFor(workspaceId)),
  );

  @override
  String get vendorId => 'linear';

  @override
  List<String> get allowedDomains => const ['linear.app', 'api.linear.app'];

  @override
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  }) async {
    final issues = await _client(workspaceId).getAssignedIssues();
    return issues.map(_toDelta).toList();
  }

  @override
  Future<TicketPushOutcome?> pushChange({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
    String? externalId,
    String vendorProjectId = '',
  }) async {
    // Not yet synced → create regardless of the nominal change type.
    if (externalId == null || externalId.isEmpty) {
      final teamId = vendorProjectId.isNotEmpty
          ? vendorProjectId
          : _defaultTeamId;
      if (teamId == null || teamId.isEmpty) {
        throw StateError(
          'Linear requires a team id (config.vendorProjectId) to create an issue.',
        );
      }
      final issue = await _client(workspaceId).createIssue(
        title: ticket.title,
        description: ticket.description ?? '',
        teamId: teamId,
        priority: ticket.priority.toStorageInt(),
      );
      if (issue == null) {
        throw StateError('Linear issue creation returned no issue.');
      }
      return TicketPushOutcome(
        externalId: issue.id,
        externalKey: issue.identifier,
        url: issue.url,
      );
    }

    switch (changeType) {
      case TicketChangeType.statusChanged:
        final states = await _client(
          workspaceId,
        ).getWorkflowStatesForIssue(externalId);
        for (final state in states) {
          if (normalizeVendorStatus(state.name) == ticket.status) {
            await _client(workspaceId).updateIssueState(externalId, state.id);
            break;
          }
        }
      case TicketChangeType.updated:
      case TicketChangeType.created:
        await _client(workspaceId).updateIssue(
          externalId,
          title: ticket.title,
          description: ticket.description,
          priority: ticket.priority.toStorageInt(),
        );
      // A Control Center agent id has no Linear-user counterpart and Linear has
      // no issue-delete in this client surface, so these are intentionally not
      // mirrored. The link is preserved by returning the known external id.
      case TicketChangeType.assigned:
      case TicketChangeType.commented:
      case TicketChangeType.deleted:
        break;
    }
    return TicketPushOutcome(externalId: externalId);
  }

  @override
  Future<String?> resolveVendorUrl(String url) async {
    if (!url.contains('linear.app')) {
      return null;
    }
    final trimmed = url.split('?').first;
    final segments = trimmed.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.last;
  }

  @override
  TicketStatus mapVendorStatus(String vendorStatus) =>
      normalizeVendorStatus(vendorStatus);

  @override
  String mapCcStatus(TicketStatus ccStatus) => ccStatus.name;

  TicketSyncDelta _toDelta(LinearIssueDto i) => TicketSyncDelta(
    externalId: i.id,
    externalKey: i.identifier,
    url: i.url,
    title: i.title,
    description: i.description,
    priority: TicketPriority.fromStorage(i.priority),
    labels: i.labels,
    status: normalizeVendorStatus(i.stateName),
    rawStatus: i.stateName,
    assigneeExternalId: i.assigneeId,
  );
}
