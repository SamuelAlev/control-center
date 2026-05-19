import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/demo/demo_pr_review_repository.dart';

/// Resolves every forge to the demo's cache-backed, offline PR repository.
///
/// Registered for ALL forges rather than just GitHub: a demo should never
/// resolve to [EmptyPrReviewRepository] and render a blank page just because a
/// fixture named a different forge.
class DemoForgeProviderFactory implements ForgeProviderFactory {
  /// Creates a factory for [forge].
  const DemoForgeProviderFactory({
    required this.forge,
    required WorkspaceDatabaseManager workspaceDbs,
    required this.visitor,
  }) : _dbs = workspaceDbs;

  @override
  final ForgeHost forge;

  /// The identity a visitor's comments and reviews are authored as.
  final PrUser visitor;

  final WorkspaceDatabaseManager _dbs;

  @override
  PrReviewRepository create(ForgeProviderContext ctx) {
    final slug = ctx.repo.fullName;
    final slash = slug.indexOf('/');
    return DemoPrReviewRepository(
      db: _dbs.of(ctx.workspaceId),
      owner: slash == -1 ? slug : slug.substring(0, slash),
      repo: slash == -1 ? slug : slug.substring(slash + 1),
      visitor: visitor,
    );
  }
}

/// A registry covering every forge with the demo's offline repository.
ForgeProviderRegistry buildDemoForgeRegistry({
  required WorkspaceDatabaseManager workspaceDbs,
  required PrUser visitor,
}) => ForgeProviderRegistry([
  for (final forge in ForgeHost.values)
    DemoForgeProviderFactory(
      forge: forge,
      workspaceDbs: workspaceDbs,
      visitor: visitor,
    ),
]);
