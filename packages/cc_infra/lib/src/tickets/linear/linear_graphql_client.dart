import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/tickets/linear/linear_issue_dto.dart';
import 'package:rhttp/rhttp.dart';

/// Client for the Linear GraphQL API. Adapter-internal — nothing outside
/// `lib/features/ticketing/data/providers/linear/` may import this; the rest of
/// the codebase talks to `TicketProviderPort` instead.
class LinearGraphQlClient {
  /// Creates a [LinearGraphQlClient] backed by an [RhttpClient].
  LinearGraphQlClient(this._httpClient);

  final RhttpClient _httpClient;

  /// Linear's GraphQL endpoint answers JSON; ask for it explicitly rather than
  /// relying on whatever default the shared client carries.
  static const HttpHeaders _headers = HttpHeaders.rawMap({
    'Accept': 'application/json',
  });

  /// POSTs one GraphQL document as a JSON body and returns the decoded text
  /// response.
  Future<Map<String, dynamic>?> _post(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final response = await _httpClient.post(
      '',
      headers: _headers,
      body: HttpBody.json(payload),
      cancelToken: cancelToken,
    );
    final body = httpJsonBody(response);
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return body.cast<String, dynamic>();
    }
    return null;
  }

  /// Fetches issues assigned to the current user.
  Future<List<LinearIssueDto>> getAssignedIssues({
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query {
        issues(filter: { assignee: { isMe: { eq: true } } }) {
          nodes {
            id
            identifier
            title
            description
            url
            state { name }
            priority
            team { name }
            assignee { id }
            labels { nodes { name } }
          }
        }
      }
    ''';
    try {
      final data = await _post({'query': query}, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
      final graphData = data?['data'] as Map<String, dynamic>?;
      final issuesMap = graphData?['issues'] as Map<String, dynamic>?;
      final issues = issuesMap?['nodes'];
      if (issues is List) {
        return issues
            .map(
              (e) =>
                  e is Map<String, dynamic> ? LinearIssueDto.fromJson(e) : null,
            )
            .whereType<LinearIssueDto>()
            .toList();
      }
      return [];
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Fetches a single issue by [issueId].
  Future<LinearIssueDto?> getIssue(
    String issueId, {
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query GetIssue($id: String!) {
        issue(id: $id) {
          id
          identifier
          title
          description
          url
          state { name }
          priority
          team { name }
          assignee { id }
          labels { nodes { name } }
        }
      }
    ''';
    try {
      final data = await _post({
        'query': query,
        'variables': {'id': issueId},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
      final graphData = data?['data'] as Map<String, dynamic>?;
      final issue = graphData?['issue'];
      if (issue is Map<String, dynamic>) {
        return LinearIssueDto.fromJson(issue);
      }
      return null;
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Creates a new Linear issue and returns it.
  Future<LinearIssueDto?> createIssue({
    required String title,
    required String description,
    required String teamId,
    int? priority,
    String? assigneeId,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
          success
          issue {
            id
            identifier
            title
            description
            url
            state { name }
            priority
            team { name }
            assignee { id }
            labels { nodes { name } }
          }
        }
      }
    ''';
    final input = <String, dynamic>{
      'title': title,
      'description': description,
      'teamId': teamId,
    };
    if (priority != null) {
      input['priority'] = priority;
    }
    if (assigneeId != null) {
      input['assigneeId'] = assigneeId;
    }
    try {
      final data = await _post({
        'query': mutation,
        'variables': {'input': input},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
      final graphData = data?['data'] as Map<String, dynamic>?;
      final create = graphData?['issueCreate'] as Map<String, dynamic>?;
      final issue = create?['issue'];
      if (issue is Map<String, dynamic>) {
        return LinearIssueDto.fromJson(issue);
      }
      return null;
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Updates an issue's title/description/priority.
  Future<void> updateIssue(
    String issueId, {
    String? title,
    String? description,
    int? priority,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
        issueUpdate(id: $id, input: $input) { success }
      }
    ''';
    final input = <String, dynamic>{};
    if (title != null) {
      input['title'] = title;
    }
    if (description != null) {
      input['description'] = description;
    }
    if (priority != null) {
      input['priority'] = priority;
    }
    try {
      final data = await _post({
        'query': mutation,
        'variables': {'id': issueId, 'input': input},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Assigns (or clears, when null) an issue's assignee.
  Future<void> assignIssue(
    String issueId,
    String? assigneeId, {
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation AssignIssue($id: String!, $assigneeId: String) {
        issueUpdate(id: $id, input: { assigneeId: $assigneeId }) { success }
      }
    ''';
    try {
      final data = await _post({
        'query': mutation,
        'variables': {'id': issueId, 'assigneeId': assigneeId},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Returns the workflow states `[{id,name}]` available to [issueId]'s team.
  Future<List<({String id, String name})>> getWorkflowStatesForIssue(
    String issueId, {
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query States($id: String!) {
        issue(id: $id) {
          team { states { nodes { id name } } }
        }
      }
    ''';
    try {
      final data = await _post({
        'query': query,
        'variables': {'id': issueId},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
      final issue =
          (data?['data'] as Map<String, dynamic>?)?['issue']
              as Map<String, dynamic>?;
      final team = issue?['team'] as Map<String, dynamic>?;
      final states = (team?['states'] as Map<String, dynamic>?)?['nodes'];
      if (states is List) {
        return states
            .whereType<Map<String, dynamic>>()
            .map(
              (s) => (
                id: s['id'] as String? ?? '',
                name: s['name'] as String? ?? '',
              ),
            )
            .where((s) => s.id.isNotEmpty)
            .toList();
      }
      return const [];
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Updates the state of an issue.
  Future<void> updateIssueState(
    String issueId,
    String stateId, {
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation UpdateIssueState($id: String!, $stateId: String!) {
        issueUpdate(id: $id, input: { stateId: $stateId }) { success }
      }
    ''';
    try {
      final data = await _post({
        'query': mutation,
        'variables': {'id': issueId, 'stateId': stateId},
      }, cancelToken: cancelToken);
      _checkGraphQLErrors(data);
    } on RhttpException catch (e) {
      throw _mapOrRethrowCancel(e);
    }
  }

  /// Re-throws a cancellation untouched (a subscriber standing down, not a
  /// failure) and maps every other transport failure to the app's typed
  /// [NetworkException].
  Object _mapOrRethrowCancel(RhttpException e) {
    if (e is RhttpCancelException) {
      return e;
    }
    return mapHttpException(e);
  }

  void _checkGraphQLErrors(Map<String, dynamic>? data) {
    final errors = data?['errors'];
    if (errors is List && errors.isNotEmpty) {
      final messages = errors
          .map(
            (e) => e is Map<String, dynamic>
                ? e['message'] ?? e.toString()
                : e.toString(),
          )
          .join('; ');
      throw NetworkException(
        messages,
        code: 'graphql_error',
        responseBody: data.toString(),
      );
    }
  }
}
