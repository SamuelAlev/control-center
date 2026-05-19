import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/pull_request_dao.dart';
import 'package:cc_persistence/mappers/pr_lifecycle_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Dao pr lifecycle repository.
class DaoPrLifecycleRepository implements PrLifecycleRepository {
  /// Creates a new [Dao pr lifecycle repository].
  DaoPrLifecycleRepository(
    this._dao,
    this._githubClient, {
    DomainEventBus? eventBus,
  }) : _eventBus = eventBus;

  final PullRequestDao _dao;
  final GitHubApiClient _githubClient;
  final DomainEventBus? _eventBus;
  final PrLifecycleMapper _mapper = const PrLifecycleMapper();

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<PrGeneration?> getById(String id) async {
    final row = await _dao.getById(id);
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
    await _dao.insert(
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
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {
    final companion = PullRequestsTableCompanion(
      id: drift.Value(prId),
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      body: body != null ? drift.Value(body) : const drift.Value.absent(),
      status: status != null ? drift.Value(status) : const drift.Value.absent(),
      githubPrNumber: githubPrNumber != null
          ? drift.Value(githubPrNumber)
          : const drift.Value.absent(),
      githubPrUrl: githubPrUrl != null
          ? drift.Value(githubPrUrl)
          : const drift.Value.absent(),
    );
    await _dao.updatePr(prId, companion);
  }

  @override
  Future<Map<String, dynamic>> createOnGitHub({
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
    final result = await _githubClient.pr.createPullRequest(
      owner,
      repo,
      title: title,
      body: body,
      head: head,
      base: base,
      draft: draft,
    );

    final number = result['number'] as int?;
    final url = result['html_url'] as String?;
    if (number != null && url != null) {
      // Assignees and reviewers are applied after creation; failures here must
      // not undo the PR (it already exists on GitHub), so they're best-effort.
      if (assignees.isNotEmpty) {
        await _githubClient.pr.addAssignees(
          owner,
          repo,
          prNumber: number,
          logins: assignees,
        );
      }
      if (reviewerUsers.isNotEmpty || reviewerTeams.isNotEmpty) {
        await _githubClient.pr.requestReviewers(
          owner,
          repo,
          prNumber: number,
          reviewers: reviewerUsers,
          teamReviewers: reviewerTeams,
        );
      }
      await updateDraft(
        prId,
        status: 'created',
        githubPrNumber: number,
        githubPrUrl: url,
      );
      final row = await _dao.getById(prId);
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
  Future<void> delete(String id) => _dao.deleteById(id).then((_) {});
}
