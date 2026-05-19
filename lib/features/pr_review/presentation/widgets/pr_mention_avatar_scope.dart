import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feeds [GitHubMentionAvatarScope] from this PR's reviewers and the repo's
/// requestable teams so markdown `@org/team` chips can reuse known logos.
class PrMentionAvatarScope extends ConsumerWidget {
  /// Creates a [PrMentionAvatarScope].
  const PrMentionAvatarScope({
    super.key,
    required this.pr,
    required this.child,
  });

  /// PR whose reviewer rows seed the lookup (its repo keys `owner/slug`).
  final PrRef pr;

  /// Subtree that renders GitHub markdown / reviewer chips.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewers =
        ref.watch(prReviewersProvider(pr)).asData?.value ??
        const <PrReviewer>[];
    final candidates =
        ref.watch(requestableReviewersProvider).asData?.value ??
        const <PrReviewerCandidate>[];
    final owner = pr.repoFullName.contains('/')
        ? pr.repoFullName.substring(0, pr.repoFullName.indexOf('/'))
        : '';
    return GitHubMentionAvatarScope(
      avatars: githubMentionAvatars(
        reviewers: reviewers,
        candidates: candidates,
        owner: owner,
      ),
      child: child,
    );
  }
}

/// Builds the mention-avatar map from known reviewers and picker candidates.
Map<String, String> githubMentionAvatars({
  List<PrReviewer> reviewers = const [],
  List<PrReviewerCandidate> candidates = const [],
  String owner = '',
}) {
  final out = <String, String>{};
  void put(String key, String url) {
    if (key.isEmpty || url.isEmpty) {
      return;
    }
    out.putIfAbsent(key.toLowerCase(), () => url);
  }

  for (final r in reviewers) {
    switch (r) {
      case PrUserReviewer():
        put(r.user.login, r.user.avatarUrl);
      case PrTeamReviewer():
        put(r.slug, r.avatarUrl);
        put(r.name, r.avatarUrl);
        if (owner.isNotEmpty) {
          put('$owner/${r.slug}', r.avatarUrl);
        }
    }
  }
  for (final c in candidates) {
    final url = c.avatarUrl ?? '';
    put(c.key, url);
    put(c.label, url);
    if (c.kind == ReviewerKind.team && owner.isNotEmpty) {
      put('$owner/${c.key}', url);
    }
  }
  return out;
}
