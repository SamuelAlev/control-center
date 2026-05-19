import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';

/// VCS host identifier.
enum VcsHost {
  github,
  gitlab,
  bitbucket,
  local,
  unknown,
}

/// Detects the VCS host from a [Repo]'s GitHub remote info.
/// Currently only GitHub is supported; other hosts return [VcsHost.unknown].
VcsHost detectVcsHost(Repo repo) {
  if (repo.hasGitHubRemote) {
    return VcsHost.github;
  }
  return VcsHost.unknown;
}

/// Context object passed to a [VcsProviderFactory] when constructing a
/// [PrReviewRepository].
class VcsProviderContext {
  const VcsProviderContext({
    required this.repo,
    required this.workspaceId,
  });

  final Repo repo;
  final String workspaceId;
}

/// Factory that creates a [PrReviewRepository] for a specific [VcsHost].
abstract interface class VcsProviderFactory {
  VcsHost get host;
  PrReviewRepository create(VcsProviderContext ctx);
}

/// Registry of [VcsProviderFactory] instances, keyed by host.
class VcsProviderRegistry {
  VcsProviderRegistry(List<VcsProviderFactory> factories)
      : _registry = {for (final f in factories) f.host: f};

  final Map<VcsHost, VcsProviderFactory> _registry;

  /// Returns the [PrReviewRepository] for the host inferred from [ctx.repo].
  /// Falls back to [EmptyPrReviewRepository] for unknown/unsupported hosts.
  PrReviewRepository resolve(VcsProviderContext ctx) {
    final host = detectVcsHost(ctx.repo);
    final factory = _registry[host];
    if (factory == null) {
      return const EmptyPrReviewRepository();
    }
    return factory.create(ctx);
  }
}
