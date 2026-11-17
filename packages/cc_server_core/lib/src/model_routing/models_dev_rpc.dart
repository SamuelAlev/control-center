import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ModelCatalogService;

/// Repo-RPC ops exposing the models.dev catalogue to thin clients.
///
/// The client READS this surface (and can trigger a manual refresh); the
/// actual fetch, its disk cache under the server data dir, and the in-memory
/// catalog the harness prices against all run host-side. There is no bundled
/// snapshot in source — a first run with no cache yields an empty document
/// until a refresh lands.
///
/// The document travels as `document_json`: the JSON text exactly as the
/// server cached it, inside one string. It is megabytes describing thousands
/// of models that only the client's own parser reads, so the server relays
/// the text instead of decoding it to encode it again, and the client parses
/// it provider by provider (`ModelsDevParser`) instead of
/// receiving it as tens of megabytes of decoded maps.
///
/// Not workspace-scoped: the catalogue is install-wide reference data.
///
/// Injected via `extraOps` (the same seam weather/fonts/fleet use), so the
/// 12k-line `remote_rpc_catalog.dart` is left untouched.
List<RepoOp> buildModelsDevOps({
  required ModelsDevSource source,
  required ModelCatalogService catalog,
}) => [
  RepoOp(
    name: 'models.catalog',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      await catalog.ensureLoaded();
      var text = await source.documentText();
      if (text == null || text.isEmpty) {
        await catalog.refresh(force: false);
        text = await source.documentText();
      }
      return {'document_json': text ?? ''};
    },
  ),
  RepoOp(
    name: 'models.refreshCatalog',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    timeout: const Duration(minutes: 1),
    handler: (ctx) async {
      final force = ctx.args['force'] is bool
          ? ctx.args['force'] as bool
          : true;
      await catalog.refresh(force: force);
      return {'document_json': await source.documentText() ?? ''};
    },
  ),
];
