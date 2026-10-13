import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// Orders [prs] into a valid pull request stack chain, bottom first, by
/// following `baseRef`/`headRef` links: each PR's base branch must be the
/// previous PR's head branch (GitHub's own stack-creation rule).
///
/// Returns null when the PRs don't form exactly one chain — no unique bottom
/// (zero or several PRs whose base isn't another selected PR's head), a fork
/// (two PRs based on the same head), or a break in the links. A null result
/// means GitHub would reject the stack with a 422, so callers surface it as
/// a validation error rather than trying the call.
List<PullRequest>? orderPrChain(List<PullRequest> prs) {
  if (prs.length < 2) {
    return null;
  }
  // Unenriched rows (no refs) can't be validated — refuse rather than guess.
  if (prs.any((pr) => pr.headRef.isEmpty || pr.baseRef.isEmpty)) {
    return null;
  }
  final heads = {for (final pr in prs) pr.headRef};
  final bottoms = prs.where((pr) => !heads.contains(pr.baseRef)).toList();
  if (bottoms.length != 1) {
    return null;
  }
  final ordered = <PullRequest>[bottoms.first];
  final remaining = {for (final pr in prs) pr.number: pr}
    ..remove(bottoms.first.number);
  while (remaining.isNotEmpty) {
    final next = remaining.values
        .where((pr) => pr.baseRef == ordered.last.headRef)
        .toList();
    if (next.length != 1) {
      return null;
    }
    ordered.add(next.first);
    remaining.remove(next.first.number);
  }
  return ordered;
}

/// Groups a space's PR inventory by repository and unambiguous branch chains.
///
/// Each chain runs bottom first. Unrelated PRs remain singleton chains; blank
/// refs, reused head branches, forks and cycles never imply a merge order.
/// This describes the loaded branch links, not GitHub stack registration.
Map<String, List<List<PullRequest>>> groupPrsByStack(List<PullRequest> prs) {
  final byRepo = <String, List<PullRequest>>{};
  for (final pr in prs) {
    (byRepo[pr.repoFullName] ??= []).add(pr);
  }
  return {
    for (final entry in byRepo.entries) entry.key: _branchChains(entry.value),
  };
}

List<List<PullRequest>> _branchChains(List<PullRequest> prs) {
  final byHead = <String, List<PullRequest>>{};
  final byBase = <String, List<PullRequest>>{};
  for (final pr in prs) {
    if (pr.headRef.isNotEmpty) {
      (byHead[pr.headRef] ??= []).add(pr);
    }
    if (pr.baseRef.isNotEmpty) {
      (byBase[pr.baseRef] ??= []).add(pr);
    }
  }
  final next = <int, PullRequest>{};
  final hasParent = <int>{};
  for (final pr in prs) {
    final parents = byHead[pr.baseRef];
    if (pr.baseRef.isEmpty ||
        pr.headRef.isEmpty ||
        byHead[pr.headRef]!.length != 1 ||
        parents == null ||
        parents.length != 1 ||
        byBase[pr.baseRef]!.length != 1) {
      continue;
    }
    final parent = parents.single;
    if (parent.number == pr.number || parent.baseRef.isEmpty) {
      continue;
    }
    next[parent.number] = pr;
    hasParent.add(pr.number);
  }
  final chains = <List<PullRequest>>[];
  final visited = <int>{};
  for (final root in prs) {
    if (hasParent.contains(root.number)) {
      continue;
    }
    final chain = <PullRequest>[];
    PullRequest? current = root;
    while (current != null && visited.add(current.number)) {
      chain.add(current);
      current = next[current.number];
    }
    chains.add(chain);
  }
  // No root exists in a cycle. Keep every affected PR reachable, without a rail.
  for (final pr in prs) {
    if (visited.add(pr.number)) {
      chains.add([pr]);
    }
  }
  return chains;
}
