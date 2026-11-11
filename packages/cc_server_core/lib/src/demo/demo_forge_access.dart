import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';

/// The demo's forge reach: the seeded repositories are fictional and nobody
/// signs in to a forge, so every visitor's sign-in "reads" every seeded repo.
/// Grants still apply ([PrRepoVisibility] checks them first); only the forge
/// half is answered here, without any network.
final class DemoPersonForgeAccess implements PersonForgeAccess {
  /// Creates the demo access.
  const DemoPersonForgeAccess();

  @override
  Future<Set<String>?> readableRepoIds(
    String workspaceId,
    String userId,
    ForgeHost forge,
    List<Repo> repos,
  ) async => {for (final r in repos) r.id};

  @override
  Future<String> viewerLogin(
    String workspaceId,
    String userId,
    ForgeHost forge,
  ) async => '';

  @override
  Future<Map<String, Set<String>>> githubTeams(
    String workspaceId,
    String userId,
  ) async => const {};
}
