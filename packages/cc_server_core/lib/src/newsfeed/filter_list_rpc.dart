import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show FilterListService;

/// Repo-RPC ops exposing the host-cached ABP filter lists to thin clients.
///
/// The client READS this surface (and can trigger a manual refresh); the
/// actual fetch and its disk cache under the server data dir run host-side.
/// Injected via `extraOps` so `remote_rpc_catalog.dart` is left untouched.
///
/// Not workspace-scoped: the lists are install-wide reference data.
List<RepoOp> buildFilterListOps(FilterListService lists) => [
  RepoOp(
    name: 'newsfeed.filterLists.state',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async => lists.readState().toJson(),
  ),
  RepoOp(
    name: 'newsfeed.filterLists.blocklist',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async => {'rules': await lists.readBlocklist()},
  ),
  RepoOp(
    name: 'newsfeed.filterLists.removeParams',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async => {'params': lists.readRemoveParams().toList()},
  ),
  RepoOp(
    name: 'newsfeed.filterLists.refresh',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    timeout: const Duration(minutes: 2),
    handler: (ctx) async {
      final force = ctx.args['force'] is bool
          ? ctx.args['force'] as bool
          : true;
      final state = await lists.refresh(force: force);
      return state.toJson();
    },
  ),
];
