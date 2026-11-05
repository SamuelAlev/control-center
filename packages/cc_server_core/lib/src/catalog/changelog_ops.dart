import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_host/cc_host.dart' show RepoOp;

/// Fetches the website's raw changelog Markdown. The browser client cannot
/// fetch it cross-origin.
typedef ChangelogFetcher = Future<String> Function();

/// `changelog.get`: the website's changelog, relayed raw for the client to
/// parse. Global and token-less; a failed fetch reads as no changelog. Injected
/// via `extraOps` so `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildChangelogOps(ChangelogFetcher fetch) => [
  RepoOp(
    name: 'changelog.get',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      try {
        return {'markdown': await fetch()};
      } catch (_) {
        return {'markdown': null};
      }
    },
  ),
];
