import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';

// Every factory declares the forge it serves, so anyone implementing or
// registering one needs the enum too.
export 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Context passed to a [ForgeProviderFactory] when constructing a
/// [PrReviewRepository].
class ForgeProviderContext {
  /// Creates a [ForgeProviderContext] for the given [repo] and workspace.
  const ForgeProviderContext({required this.repo, required this.workspaceId});

  /// The repo whose forge provider is being resolved. Its `forge` is what
  /// selects the factory.
  final Repo repo;

  /// The workspace ID associated with this provider context.
  final String workspaceId;
}

/// Factory that creates a [PrReviewRepository] for one [ForgeHost].
abstract interface class ForgeProviderFactory {
  /// The forge this factory serves.
  ForgeHost get forge;

  /// Creates a [PrReviewRepository] for the given [ctx].
  PrReviewRepository create(ForgeProviderContext ctx);
}

/// Registry of [ForgeProviderFactory] instances, keyed by forge.
///
/// Resolution is by `ctx.repo.forge`, so a workspace holding repos on three
/// different forges routes each to its own adapter with no caller-side
/// branching. A repo whose forge has no registered factory — an unauthenticated
/// forge on the server, an unsupported one on an old client — resolves to
/// [EmptyPrReviewRepository] rather than throwing, which keeps one
/// misconfigured forge from taking the whole PR surface down.
class ForgeProviderRegistry {
  /// Creates a [ForgeProviderRegistry] populated with the given [factories].
  ForgeProviderRegistry(List<ForgeProviderFactory> factories)
    : _registry = {for (final f in factories) f.forge: f};

  final Map<ForgeHost, ForgeProviderFactory> _registry;

  /// The forges that currently have a factory registered.
  Iterable<ForgeHost> get registeredForges => _registry.keys;

  /// Whether [forge] has a registered factory.
  bool supports(ForgeHost forge) => _registry.containsKey(forge);

  /// Returns the [PrReviewRepository] for `ctx.repo.forge`, or
  /// [EmptyPrReviewRepository] when that forge has no factory.
  PrReviewRepository resolve(ForgeProviderContext ctx) {
    final factory = _registry[ctx.repo.forge];
    if (factory == null) {
      return const EmptyPrReviewRepository();
    }
    return factory.create(ctx);
  }
}
