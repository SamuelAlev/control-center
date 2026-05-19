/// Whether an open PR belongs in Needs your review for [viewerLogin].
///
/// The request must name the viewer (directly or via a still-pending team
/// they belong to), drafts are not reviewable yet, and the viewer's own PRs
/// belong to the author-centric inbox sections. GitHub drops a team from
/// `reviewRequests` once any member reviews, so a remaining slug means no
/// teammate has satisfied that request yet.
bool prNeedsYourReview({
  required bool isDraft,
  required String? authorLogin,
  required String viewerLogin,
  required Iterable<String> requestedUserLogins,
  required Iterable<String> requestedTeamSlugs,
  required String repoFullName,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  final me = viewerLogin.toLowerCase();
  if (me.isEmpty || isDraft) {
    return false;
  }
  if (authorLogin != null && authorLogin.toLowerCase() == me) {
    return false;
  }
  if (requestedUserLogins.any((login) => login.toLowerCase() == me)) {
    return true;
  }
  if (requestedTeamSlugs.isEmpty || viewerTeamsByOrg.isEmpty) {
    return false;
  }
  final slash = repoFullName.indexOf('/');
  final org = (slash > 0 ? repoFullName.substring(0, slash) : repoFullName)
      .toLowerCase();
  final mine = viewerTeamsByOrg[org];
  if (mine == null || mine.isEmpty) {
    return false;
  }
  return requestedTeamSlugs.any((slug) => mine.contains(slug.toLowerCase()));
}
