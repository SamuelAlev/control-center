import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/connect/klipy_gifs.dart';

/// The composer's GIF picker (`gif.*`), resolved on the host for the calling
/// member's workspace: its own Klipy key, else the server's key, else
/// Connect's Klipy lane. Items are `{id, title, width, height, preview_url,
/// gif_url}` with media on Klipy's CDN; the client loads them directly.
///
/// Workspace-scoped, so the dispatcher checks the workspace exists and the
/// caller belongs to it before any key is chosen. A null [gifs] (bare
/// catalogs) answers empty.
List<RepoOp> buildGifOps(KlipyGifs? gifs) => [
  RepoOp(
    name: 'gif.search',
    kind: RepoOpKind.read,
    requiredArgs: ['query'],
    handler: (ctx) async => {
      'gifs': [
        if (gifs != null)
          for (final gif in await gifs.search(
            ctx.workspaceId!,
            ctx.args['query'] as String,
          ))
            gif.toJson(),
      ],
    },
  ),
  RepoOp(
    name: 'gif.trending',
    kind: RepoOpKind.read,
    handler: (ctx) async => {
      'gifs': [
        if (gifs != null)
          for (final gif in await gifs.trending(ctx.workspaceId!)) gif.toJson(),
      ],
    },
  ),
];
