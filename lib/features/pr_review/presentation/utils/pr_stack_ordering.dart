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
