import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/pr_lifecycle_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift-backed [PrLifecycleRepository] over the per-workspace databases.
///
/// PR generations live in their workspace's own database file, so the DAO is
/// resolved per call from the `workspaceId` the caller supplies.
class DaoPrLifecycleRepository implements PrLifecycleRepository {
  /// Creates a [DaoPrLifecycleRepository] over [_dbs].
  ///
  /// [_forgeClientFor] resolves the API client for a repo coordinate in a
  /// workspace, so publishing works on whichever forge that repo lives on.
  DaoPrLifecycleRepository(
    this._dbs,
    this._forgeClientFor, {
    DomainEventBus? eventBus,
  }) : _eventBus = eventBus;

  final WorkspaceDatabaseManager _dbs;

  /// The pull-request DAO for [workspaceId].
  PullRequestDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).pullRequestDao;

  /// Resolves the forge client for `(workspace, owner, repo)`.
  final Future<ForgePrClient?> Function(
    String workspaceId,
    String owner,
    String repo,
  )
  _forgeClientFor;
  final DomainEventBus? _eventBus;
  final PrLifecycleMapper _mapper = const PrLifecycleMapper();

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<PrGeneration?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    const uuid = Uuid();
    final id = uuid.v4();
    await _dao(workspaceId).insert(
      PullRequestsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        title: title,
        body: body,
        diffSummary: drift.Value(diffSummary),
      ),
    );
    return id;
  }

  @override
  Future<void> updateDraft(
    String workspaceId,
    String prId, {
    String? title,
    String? body,
    String? status,
    int? prNumber,
    String? prUrl,
  }) async {
    final companion = PullRequestsTableCompanion(
      id: drift.Value(prId),
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      body: body != null ? drift.Value(body) : const drift.Value.absent(),
      status: status != null ? drift.Value(status) : const drift.Value.absent(),
      prNumber: prNumber != null
          ? drift.Value(prNumber)
          : const drift.Value.absent(),
      prUrl: prUrl != null ? drift.Value(prUrl) : const drift.Value.absent(),
    );
    await _dao(workspaceId).updatePr(prId, companion);
  }

  @override
  Future<Map<String, dynamic>> publishToForge({
    required String workspaceId,
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  }) async {
    final client = await _forgeClientFor(workspaceId, owner, repo);
    if (client == null) {
      throw StateError(
        'No forge is connected for $owner/$repo in this workspace',
      );
    }

    final created = await client.createPullRequest(
      title: title,
      body: body,
      headBranch: head,
      baseBranch: base,
      draft: draft,
    );
    final result = <String, dynamic>{
      'number': created.number,
      'html_url': created.htmlUrl,
    };

    final number = created.number;
    final url = created.htmlUrl;
    if (number > 0 && url.isNotEmpty) {
      // Assignees and reviewers are applied after creation; a failure here must
      // not undo the PR (it already exists on the forge), and a forge that has
      // no such concept must not fail the publish either — hence the capability
      // checks and the swallowed errors.
      if (assignees.isNotEmpty) {
        try {
          await client.addAssignees(prNumber: number, logins: assignees);
        } on Object {
          // Best-effort: Bitbucket has no assignees at all.
        }
      }
      final teams = client.capabilities.teamReviewers
          ? reviewerTeams
          : const <String>[];
      if (reviewerUsers.isNotEmpty || teams.isNotEmpty) {
        try {
          await client.requestReviewers(
            prNumber: number,
            userLogins: reviewerUsers,
            teamSlugs: teams,
          );
        } on Object {
          // Best-effort for the same reason as assignees.
        }
      }
      await updateDraft(
        workspaceId,
        prId,
        status: 'created',
        prNumber: number,
        prUrl: url,
      );
      final row = await _dao(workspaceId).getById(prId);
      final wsId = row?.workspaceId;
      if (wsId != null) {
        _eventBus?.publish(
          PullRequestPublished(
            prId: prId,
            workspaceId: wsId,
            repoOwner: owner,
            repoName: repo,
            occurredAt: DateTime.now(),
          ),
        );
      }
    }

    return result;
  }

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(id).then((_) {});
}
