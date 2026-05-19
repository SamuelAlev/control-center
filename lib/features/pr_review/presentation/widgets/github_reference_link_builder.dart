import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/features/pr_review/presentation/widgets/references/commit_reference_chip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/references/pr_reference_chip.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:control_center/shared/widgets/github_user_mention_link_builder.dart';
import 'package:flutter/widgets.dart';

/// cc_markdown `'link'` node builder that swaps GitHub references out for
/// inline preview chips.
///
/// Handles three kinds of references:
///
/// * **Pull requests** — same-repo `#123` (rewritten by the preprocessor to
///   the app's `control-center://` deep-link scheme) and any full PR URL
///   whose target repo is the host repo or one of [knownWorkspaceRepos].
///   Renders a [PrReferenceChip].
/// * **Commits** — any `https://github.com/<owner>/<repo>/commit/<sha>` URL
///   (host repo or a workspace repo). Renders a [CommitReferenceChip].
/// * **User / team mentions** — `@login` rewritten to `control-center://user/`
///   (and `@org/team`). Delegates to [GitHubUserMentionLinkBuilder] so
///   overlaying this builder via `withOverrides` does not drop mention chips.
///
/// [canBuild] claims ONLY those references; every other link falls through to
/// the engine's default link rendering (which owns its own tap recognizer and
/// routes through the ambient `onTapLink`). The chip is embedded as a
/// `WidgetSpan` in the paragraph's single `Text.rich` by the engine.
class GitHubReferenceLinkBuilder extends CcNodeBuilder {
  /// Creates a [GitHubReferenceLinkBuilder].
  const GitHubReferenceLinkBuilder({
    required this.currentOwner,
    required this.currentRepo,
    required this.knownWorkspaceRepos,
    this.onSwitchToRepo,
  });

  static const _mentions = GitHubUserMentionLinkBuilder();

  /// Owner of the host PR.
  final String currentOwner;

  /// Repo of the host PR.
  final String currentRepo;

  /// Lowercased `owner/repo` pairs registered in the active workspace. Used
  /// to decide whether a cross-repo reference should become a chip.
  final Set<String> knownWorkspaceRepos;

  /// Forwarded to the chip's `handleGitHubLink` call when the target repo is
  /// in a different workspace slot.
  final Future<void> Function(String workspaceId, String repoId)?
  onSwitchToRepo;

  bool _isKnownTarget(String owner, String repo) {
    final isSame =
        owner.toLowerCase() == currentOwner.toLowerCase() &&
        repo.toLowerCase() == currentRepo.toLowerCase();
    if (isSame) {
      return true;
    }
    return knownWorkspaceRepos.contains(
      '${owner.toLowerCase()}/${repo.toLowerCase()}',
    );
  }

  /// Resolves [node] to a known PR/commit reference, or null.
  Object? _reference(CcNode node) {
    if (node is! CcLink) {
      return null;
    }
    // Only autolinked bare URLs or preprocessor-emitted control-center://
    // hrefs become chips; author-labelled links keep their text.
    if (!node.autolink && !node.url.startsWith('control-center://')) {
      return null;
    }
    final reference = parseAnyGitHubReference(
      node.url,
      currentOwner: currentOwner,
      currentRepo: currentRepo,
    );
    if (reference is GitHubPrReference &&
        _isKnownTarget(reference.owner, reference.repo)) {
      return reference;
    }
    if (reference is GitHubCommitReference &&
        _isKnownTarget(reference.owner, reference.repo)) {
      return reference;
    }
    return null;
  }

  @override
  bool canBuild(CcNode node) =>
      _mentions.canBuild(node) || _reference(node) != null;

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    if (_mentions.canBuild(node)) {
      return _mentions.build(node, style, context);
    }
    final reference = _reference(node);
    if (reference is GitHubPrReference) {
      return PrReferenceChip(
        reference: reference,
        currentOwner: currentOwner,
        currentRepo: currentRepo,
        onSwitchToRepo: onSwitchToRepo,
      );
    }
    if (reference is GitHubCommitReference) {
      return CommitReferenceChip(reference: reference);
    }
    // canBuild gated this out; defensively fall back to plain text.
    return const SizedBox.shrink();
  }
}
