import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads work products — including agent-published artifacts — over the RPC
/// client.
///
/// The client had no path to this subsystem at all: work products, revisions,
/// and the `WorkProductService` were complete server-side and unreachable, so an
/// artifact an agent published could not be rendered anywhere. This is that
/// bridge.
///
/// Read-only by design. Artifacts are authored by the agent-facing MCP tools
/// (`publish_artifact` / `revise_artifact`) and revised/restored through the
/// server's `WorkProductService`, so there is no client write path to keep in
/// sync — and no way for a client to forge one.
///
/// The client injects its active `workspace_id`, so it does not travel on the
/// wire; the host injects the authoritative one and the repository scopes every
/// read by it. Mirrors the `workProduct.*` ops + watch queries in the host
/// catalog.
class RpcWorkProductRepository {
  /// Creates an [RpcWorkProductRepository] over [_client].
  RpcWorkProductRepository(this._client);

  final RemoteRpcClient _client;

  /// One work product by id, or null when it does not exist in the bound
  /// workspace.
  Future<WorkProduct?> getById(String workProductId) async {
    final data = await _client.call('workProduct.getById', {
      'work_product_id': workProductId,
    });
    return _product(data['work_product']);
  }

  /// Every work product in the bound workspace, newest first.
  Future<List<WorkProduct>> listForWorkspace() async {
    final data = await _client.call('workProduct.listForWorkspace', const {});
    return _products(data);
  }

  /// The revision history of [workProductId], newest first.
  Future<List<WorkProductRevision>> revisions(String workProductId) async {
    final data = await _client.call('workProduct.revisions', {
      'work_product_id': workProductId,
    });
    return ((data['revisions'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => _revisionFromWire(m.cast<String, dynamic>()))
        .toList();
  }

  /// One work product, live. Drives the artifact bubble: the message carries
  /// ids only, so a new revision re-renders the existing card.
  Stream<WorkProduct?> watchById(String workProductId) => _client
      .subscribe('workProduct.watchById', {'work_product_id': workProductId})
      .map((d) => _product(d['work_product']));

  /// The artifacts published into one conversation, newest first. Pass
  /// [conversationId] for a side conversation; it defaults to the space's main
  /// conversation.
  Stream<List<WorkProduct>> watchForSpace(
    String spaceId, {
    String? conversationId,
  }) => _client
      .subscribe('workProduct.watchForSpace', {
        'space_id': spaceId,
        'conversation_id': ?conversationId,
      })
      .map(_products);

  /// Parses a revision's `content` as an artifact block document, or null when
  /// it holds plain text instead (work products predate artifacts and
  /// `save_work_product_revision` still writes markdown).
  ///
  /// Uses the same `cc_domain` codec the server validates with, so there is one
  /// block schema rather than a wire copy that can drift.
  static ArtifactDocument? documentOf(WorkProductRevision revision) =>
      ArtifactDocument.tryParseContent(revision.content);

  List<WorkProduct> _products(Map<String, dynamic> data) =>
      ((data['work_products'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => _fromWire(m.cast<String, dynamic>()))
          .toList();

  WorkProduct? _product(Object? raw) =>
      raw is Map ? _fromWire(raw.cast<String, dynamic>()) : null;

  WorkProduct _fromWire(Map<String, dynamic> w) => WorkProduct(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    title: w['title'] as String? ?? 'Untitled',
    artifactType: WorkProductType.fromStorage(w['artifact_type'] as String?),
    ticketId: w['ticket_id'] as String?,
    agentId: w['agent_id'] as String?,
    currentRevisionId: w['current_revision_id'] as String?,
    createdAt: _time(w['created_at']),
    updatedAt: _time(w['updated_at']),
  );

  WorkProductRevision _revisionFromWire(Map<String, dynamic> w) =>
      WorkProductRevision(
        id: w['id'] as String,
        workProductId: w['work_product_id'] as String? ?? '',
        workspaceId: w['workspace_id'] as String? ?? '',
        revisionNumber: (w['revision_number'] as num?)?.toInt() ?? 1,
        content: w['content'] as String? ?? '',
        baseRevisionId: w['base_revision_id'] as String?,
        authorType: w['author_type'] as String? ?? 'agent',
        authorId: w['author_id'] as String?,
        summary: w['summary'] as String?,
        createdAt: _time(w['created_at']),
      );

  static DateTime _time(Object? raw) =>
      DateTime.tryParse(raw is String ? raw : '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  /// Restores [revisionId] as a new head revision of [workProductId].
  ///
  /// Append-a-new-head, never a rewrite: the revision history stays an audit
  /// trail. The only client-side write in this surface — agents revise by
  /// publishing, operators restore.
  Future<WorkProductRevision> restoreRevision(
    String workProductId,
    String revisionId,
  ) async {
    final data = await _client.call('workProduct.restoreRevision', {
      'work_product_id': workProductId,
      'revision_id': revisionId,
    });
    return _revisionFromWire((data['revision'] as Map).cast<String, dynamic>());
  }
}
