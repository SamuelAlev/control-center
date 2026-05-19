import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';
import 'package:cc_infra/src/tickets/linear/linear_graphql_client.dart';
import 'package:cc_infra/src/tickets/linear/linear_issue_dto.dart';
import 'package:dio/dio.dart';

/// [TicketProviderPort] backed by Linear's GraphQL API. The only place in the
/// codebase that knows about Linear specifics — status names, the GraphQL
/// client, priority numbering, and the required team id. Construct it from a
/// [Dio] so the transport client stays sealed inside this folder.
class LinearTicketAdapter implements TicketProviderPort {
  /// Creates a [LinearTicketAdapter] over an authorized [Dio]. [defaultTeamId]
  /// is used when a create draft does not carry a `teamId` in its extras.
  LinearTicketAdapter(Dio dio, {String? defaultTeamId})
      : _client = LinearGraphQlClient(dio),
        _defaultTeamId = defaultTeamId;

  final LinearGraphQlClient _client;
  final String? _defaultTeamId;

  @override
  TicketProvider get provider => TicketProvider.linear;

  @override
  TicketProviderCapabilities get capabilities =>
      const TicketProviderCapabilities(
        provider: TicketProvider.linear,
        supportsCreate: true,
        supportsUpdate: true,
        supportsStatusUpdate: true,
        supportsAssignee: true,
        supportsLabels: true,
        supportsPriority: true,
        supportsHierarchy: false,
        supportsList: true,
        supportsRemoteSync: true,
      );

  @override
  List<String> get allowedDomains => const ['linear.app', 'api.linear.app'];

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) async {
    final teamId = draft.providerExtras['teamId'] ?? _defaultTeamId;
    if (teamId == null || teamId.isEmpty) {
      throw StateError(
        'Linear requires a teamId to create an issue. Pass it via '
        'providerExtras["teamId"] or configure a default team.',
      );
    }
    final issue = await _client.createIssue(
      title: draft.title,
      description: draft.description ?? '',
      teamId: teamId,
      priority: draft.priority.toStorageInt(),
      assigneeId: draft.assigneeExternalId,
    );
    if (issue == null) {
      throw StateError('Linear issue creation returned no issue.');
    }
    return _toRemote(issue);
  }

  @override
  Future<RemoteTicket?> getByExternalId(String externalId) async {
    final issue = await _client.getIssue(externalId);
    return issue == null ? null : _toRemote(issue);
  }

  @override
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()}) async {
    final issues = await _client.getAssignedIssues();
    final mapped = issues.map(_toRemote);
    final filtered = query.statuses == null
        ? mapped
        : mapped.where((t) => query.statuses!.contains(t.status));
    return filtered.take(query.limit).toList();
  }

  @override
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch) async {
    await _client.updateIssue(
      externalId,
      title: patch.title,
      description: patch.description,
      priority: patch.priority?.toStorageInt(),
    );
    final issue = await _client.getIssue(externalId);
    if (issue == null) {
      throw StateError('Issue $externalId not found.');
    }
    return _toRemote(issue);
  }

  @override
  Future<RemoteTicket> transitionStatus(
    String externalId,
    TicketStatus target,
  ) async {
    final states = await _client.getWorkflowStatesForIssue(externalId);
    final match = _pickState(states, target);
    if (match != null) {
      await _client.updateIssueState(externalId, match.id);
    }
    final issue = await _client.getIssue(externalId);
    if (issue == null) {
      throw StateError('Issue $externalId not found.');
    }
    return _toRemote(issue);
  }

  @override
  Future<RemoteTicket> assign(
    String externalId,
    String? assigneeExternalId,
  ) async {
    await _client.assignIssue(externalId, assigneeExternalId);
    final issue = await _client.getIssue(externalId);
    if (issue == null) {
      throw StateError('Issue $externalId not found.');
    }
    return _toRemote(issue);
  }

  @override
  Stream<RemoteTicket> watchAssigned() async* {
    for (final issue in await _client.getAssignedIssues()) {
      yield _toRemote(issue);
    }
  }

  RemoteTicket _toRemote(LinearIssueDto i) {
    return RemoteTicket(
      externalId: i.id,
      externalKey: i.identifier,
      url: i.url,
      title: i.title,
      description: i.description,
      priority: TicketPriority.fromStorage(i.priority),
      labels: i.labels,
      status: _normalizeStatus(i.stateName),
      rawStatus: i.stateName,
      assigneeExternalId: i.assigneeId,
    );
  }

  /// Heuristic mapping of a Linear workflow state name to a canonical status.
  static TicketStatus _normalizeStatus(String stateName) {
    final s = stateName.toLowerCase();
    if (s.contains('progress')) {
      return TicketStatus.inProgress;
    }
    if (s.contains('review')) {
      return TicketStatus.inReview;
    }
    if (s.contains('done') || s.contains('complete') || s.contains('merged')) {
      return TicketStatus.done;
    }
    if (s.contains('cancel') || s.contains('duplicate')) {
      return TicketStatus.cancelled;
    }
    if (s.contains('block')) {
      return TicketStatus.blocked;
    }
    if (s.contains('backlog')) {
      return TicketStatus.backlog;
    }
    return TicketStatus.open;
  }

  /// Picks the workflow state whose name best matches [target].
  ({String id, String name})? _pickState(
    List<({String id, String name})> states,
    TicketStatus target,
  ) {
    for (final state in states) {
      if (_normalizeStatus(state.name) == target) {
        return state;
      }
    }
    return null;
  }
}
