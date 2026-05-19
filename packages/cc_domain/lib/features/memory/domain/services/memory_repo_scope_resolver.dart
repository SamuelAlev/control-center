import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';

/// Raised when a caller names a repo that the workspace does not have.
///
/// A miss is an error rather than a silent fall-back to workspace-wide scope:
/// writing a repo-scoped fact into the global namespace because of a typo is
/// invisible at the call site and only shows up much later as memory that
/// leaks across every repo.
class UnknownMemoryRepoScope implements Exception {
  /// Creates an [UnknownMemoryRepoScope].
  UnknownMemoryRepoScope({required this.workspaceId, required this.input});

  /// The workspace the lookup ran in.
  final String workspaceId;

  /// The repo identifier the caller supplied.
  final String input;

  @override
  String toString() =>
      'Repository "$input" is not part of workspace $workspaceId. '
      'Call list_repos to see the repos available here, or omit `repo` to '
      'record this as workspace-wide memory.';
}

/// Resolves the `repo` argument of a memory tool into a canonical repo slug.
///
/// Agents address a repo however they saw it last — an id from `list_repos`,
/// an `owner/name` from a PR, or a scope slug echoed back from
/// `list_memory_domains`. All three resolve here, and all three land on the
/// single canonical [repoSlugFor] value, so two agents naming the same repo
/// differently still write into one memory scope.
class MemoryRepoScopeResolver {
  /// Creates a [MemoryRepoScopeResolver].
  const MemoryRepoScopeResolver(this._repos);

  final RepoRepository _repos;

  /// Resolves [input] to a canonical repo slug within [workspaceId].
  ///
  /// Returns null when [input] is null or blank — the caller wants
  /// workspace-wide scope. Throws [UnknownMemoryRepoScope] when [input] names
  /// a repo the workspace does not have; membership in the workspace IS the
  /// check, since a repo id from another workspace simply does not resolve.
  Future<String?> resolve(String workspaceId, String? input) async {
    final wanted = input?.trim();
    if (wanted == null || wanted.isEmpty) {
      return null;
    }

    final byId = await _repos.getById(workspaceId, wanted);
    if (byId != null) {
      return repoSlugFor(byId);
    }

    final all = await _repos.getAll(workspaceId);
    final match = _matchByName(all, wanted);
    if (match != null) {
      return repoSlugFor(match);
    }
    throw UnknownMemoryRepoScope(workspaceId: workspaceId, input: wanted);
  }

  /// Matches [wanted] against every name a caller could reasonably use.
  ///
  /// Compared on the slugified form so `Owner/My-Repo`, `owner/my-repo` and
  /// `owner-my-repo` are one repo. The bare remote name is tried LAST and only
  /// when it is unambiguous: two repos called `api` under different owners must
  /// not silently resolve to whichever was registered first.
  static Repo? _matchByName(List<Repo> repos, String wanted) {
    final target = slugifyRepoScope(wanted);
    if (target.isEmpty) {
      return null;
    }
    for (final repo in repos) {
      if (repoSlugFor(repo) == target ||
          slugifyRepoScope(repo.fullName) == target) {
        return repo;
      }
    }
    final byRemoteName = repos
        .where((r) => slugifyRepoScope(r.remoteName) == target)
        .toList();
    return byRemoteName.length == 1 ? byRemoteName.first : null;
  }
}
