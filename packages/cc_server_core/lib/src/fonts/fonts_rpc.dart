import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_host/cc_host.dart';

/// Repo-RPC ops exposing the selectable font catalogue to thin clients.
///
/// The client READS this surface to populate the font picker; the upstream
/// catalogue fetch, its disk cache and variant→file resolution all run
/// host-side in `FontsourceCatalogService` (`cc_infra`). The bytes themselves
/// travel over the host's `/proxy/font` route, so a client never dials a font
/// CDN — which is not just consistency: Skia cannot decode the `woff2` that
/// upstreams serve to anything browser-shaped and only the host can ask for
/// `ttf`.
///
/// Not workspace-scoped: a font choice is a per-user display preference and the
/// catalogue is identical for every workspace.
///
/// Injected into the catalog via `extraOps` (the same seam the weather, fleet,
/// and evals ops use), so the 12k-line `remote_rpc_catalog.dart` is untouched.
List<RepoOp> buildFontsOps(FontCatalogRepository fonts) => [
  RepoOp(
    name: 'fonts.list',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      final catalog = await fonts.catalog();
      return {
        'fonts': [
          for (final family in catalog)
            FontFamilyDto.fromEntity(family).toJson(),
        ],
      };
    },
  ),
];
