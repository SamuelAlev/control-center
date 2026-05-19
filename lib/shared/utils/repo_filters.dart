import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The repos that resolve to a real forge coordinate, in workspace order.
///
/// Repos whose `origin` remote is not on a supported forge have nothing a PR
/// surface can query, so they are filtered out here rather than at each call
/// site. Every supported forge passes — this must never narrow to one of them.
List<Repo> forgeLinkedReposOf(AsyncValue<List<Repo>> async) {
  final repos = async.value ?? const <Repo>[];
  return repos.where((r) => r.hasForgeRemote).toList(growable: false);
}

/// Groups [repos] by the forge they live on.
///
/// The shape every cross-forge fan-out starts from: a workspace may mix forges
/// freely, so anything that talks to a forge API works one group at a time.
Map<ForgeHost, List<Repo>> reposByForge(Iterable<Repo> repos) {
  final grouped = <ForgeHost, List<Repo>>{};
  for (final repo in repos) {
    if (!repo.hasForgeRemote) {
      continue;
    }
    (grouped[repo.forge] ??= []).add(repo);
  }
  return grouped;
}
