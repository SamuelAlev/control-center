import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A PR's membership in a stack: the stack itself plus the PR's 1-based
/// `position` (bottom = 1) out of `total` entries.
typedef PrStackMembership = ({PrStack stack, int position, int total});

/// The pull request stacks of the repo, fetched on demand from the host (the
/// GitHub stacks REST API over `pr_review.listStacks`).
///
/// Stacks are chrome, never a blocker: a fetch failure degrades to an empty
/// list (no badges) rather than erroring the surface. The provider re-fetches
/// when the repo's open-PR snapshot changes — a merge, close, or restack
/// shows up in the polled PR list first and that change is the signal that
/// the stack composition may have moved.
final prStacksForRepoProvider = FutureProvider.autoDispose
    .family<List<PrStack>, Repo>((ref, repo) async {
      final workspace = ref.watch(activeWorkspaceProvider);
      if (workspace == null) {
        return const <PrStack>[];
      }
      // Change signal only — the head/base refs of the repo's open PRs. A
      // restack rewires exactly those refs, so this re-runs the fetch without
      // keying on list identity (which would loop on every poll emission).
      ref.watch(
        prsByRepoProvider.select(
          (v) => v.value?.repos
              .where((g) => g.repo.id == repo.id)
              .firstOrNull
              ?.prs
              .map((p) => '${p.number}:${p.headSha}:${p.baseRef}')
              .join('|'),
        ),
      );
      final registry = ref.watch(forgeProviderRegistryProvider);
      final repository = registry.resolve(
        ForgeProviderContext(repo: repo, workspaceId: workspace.id),
      );
      try {
        return await repository.listStacks();
      } on Exception {
        return const <PrStack>[];
      }
    });

/// The stack membership of one PR, or null when it isn't stacked. Backed by
/// [prStacksForRepoProvider], so every row of a repo shares the one fetch.
final prStackMembershipProvider = Provider.autoDispose
    .family<PrStackMembership?, ({Repo repo, int prNumber})>((ref, key) {
      final stacks = ref.watch(prStacksForRepoProvider(key.repo)).value;
      if (stacks == null) {
        return null;
      }
      for (final stack in stacks) {
        final index = stack.pullRequests.indexWhere(
          (e) => e.number == key.prNumber,
        );
        if (index >= 0) {
          return (
            stack: stack,
            position: index + 1,
            total: stack.pullRequests.length,
          );
        }
      }
      return null;
    });

/// The stack containing this [PrRef], or null. Resolved against the PR's own
/// repo (from the [PrRef] — never the active repo) and re-fetched when the
/// PR's head/base refs move (a restack rewires both).
final currentPrStackProvider = FutureProvider.autoDispose
    .family<PrStack?, PrRef>((ref, pr) async {
      ref.watch(
        prDetailProvider(
          pr,
        ).select((v) => '${v.value?.headSha}:${v.value?.baseRef}'),
      );
      final repository = ref.watch(prRepositoryProvider(pr));
      if (repository == null) {
        return null;
      }
      try {
        final stacks = await repository.listStacks(prNumber: pr.number);
        return stacks.isEmpty ? null : stacks.first;
      } on Exception {
        return null;
      }
    });
