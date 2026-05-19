import 'package:cc_data/src/repositories/remote_pr_lifecycle_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PrLifecycleRepository] backed by the RPC client — the thin-client data
/// path for the local PR-lifecycle records (the compose-PR draft → publish →
/// created lifecycle).
///
/// Implements the domain interface over the host's `pr_lifecycle.*` ops + the
/// `pr_lifecycle.watchByWorkspace` subscription, mapping the [PrGenerationDto]
/// wire shape back to [PrGeneration]. The host is the single source of truth and
/// owns all persistence; this client never touches a database.
///
/// `PullRequests` is workspace-scoped: the host injects the authoritative bound
/// workspace per session (`session/set_workspace`), scopes every query by it,
/// and validates an id-keyed row belongs to it before mutating — so the
/// `workspaceId` the read methods take is enforced server-side via the session
/// binding (it is NOT sent on the wire), and each emitted row carries the
/// host-stamped authoritative `workspaceId` the client rebuilds the entity from.
/// Publishing ([createOnGitHub]) runs server-side against the host-resident
/// GitHub token.
class RpcPrLifecycleRepository implements PrLifecycleRepository {
  /// Creates an [RpcPrLifecycleRepository] over [client].
  RpcPrLifecycleRepository(RemoteRpcClient client)
    : _remote = RemotePrLifecycleRepository(client);

  final RemotePrLifecycleRepository _remote;

  static DateTime _parse(String? iso) => iso == null || iso.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static PrGeneration _fromDto(PrGenerationDto d) => PrGeneration(
    id: d.id,
    workspaceId: d.workspaceId,
    status: PrGenerationStatus.fromName(d.status),
    title: d.title,
    body: d.body,
    branch: d.branch,
    createdAt: _parse(d.createdAt),
    updatedAt: _parse(d.updatedAt),
  );

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) => _remote
      .watchByWorkspace()
      .map((list) => list.map(_fromDto).toList());

  @override
  Future<PrGeneration?> getById(String id) async {
    final dto = await _remote.getById(id);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) => _remote.createDraft(
    title: title,
    body: body,
    diffSummary: diffSummary,
  );

  @override
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) => _remote.updateDraft(
    prId,
    title: title,
    body: body,
    status: status,
    githubPrNumber: githubPrNumber,
    githubPrUrl: githubPrUrl,
  );

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
  }) => _remote.createOnGitHub(
    prId: prId,
    owner: owner,
    repo: repo,
    title: title,
    body: body,
    head: head,
    base: base,
    draft: draft,
    assignees: assignees,
    reviewerUsers: reviewerUsers,
    reviewerTeams: reviewerTeams,
  );

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
