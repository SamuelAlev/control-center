import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_body_editor.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_meta_strip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/reaction_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Overview tab's main column: the metadata strip, the (editable) PR
/// description and the reaction bar. The reviewers/assignees/checks/files
/// rail moved to the Overview sidebar, rendered beside this column.
class PrHeaderSection extends ConsumerWidget {
  /// PrHeaderSection({.
  const PrHeaderSection({super.key, required this.pr, required this.prRef});

  /// PullRequest.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for PR-keyed providers.
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The page may be rendering off the list-row seed, which carries every
    // field except the two this section needs. An empty seeded body is
    // "not fetched yet", not "no description" — telling them apart is what
    // keeps the placeholder from asserting something false and then reflowing
    // when the real body lands.
    final descriptionPending =
        ref.watch(prDetailPendingProvider(prRef)) && pr.body.isEmpty;

    final markdown = PrBodyMarkdown(
      body: pr.body,
      bodyHtml: pr.bodyHtml,
      repoFullName: pr.repoFullName,
      pending: descriptionPending,
      onAttachmentLoadFailed: () {
        ref
            .read(prDetailPollingProvider(prRef).notifier)
            .invalidateAttachments();
      },
    );
    // The body editor is gated on edit access: the PR author, or a user with
    // write/admin on the repo (same derivation as the merge/close actions in
    // the title bar). The title itself moved to the fixed title row.
    final canEdit = ref.watch(prCanEditProvider(prRef));

    final body = PrBodyEditor(
      prRef: prRef,
      initialMarkdown: pr.body,
      repoFullName: pr.repoFullName,
      canEdit: canEdit,
      bodyHtml: pr.bodyHtml,
      readChild: markdown,
    );

    final reactionBar = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ReactionBar(
        reactions: pr.reactions,
        onToggle: (content, {required add}) async {
          await toggleReaction(
            ref,
            ReactionTarget.pullRequest,
            pr: prRef,
            content: content,
            add: add,
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PrMetaStrip(pr: pr, prRef: prRef),
        body,
        reactionBar,
      ],
    );
  }
}

/// Renders the PR number and title as rich text.
class PrTitle extends StatelessWidget {
  /// PrTitle({super.key,.
  const PrTitle({super.key, required this.pr});

  /// PullRequest.
  final PullRequest pr;

  /// The one shared title style — a document heading, not a page banner —
  /// used by the read view, the inline editor and the edit affordance's
  /// line-height math so they can never drift apart.
  static TextStyle? styleOf(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final style = styleOf(context);
    // Keep the title to a single line, truncating with an ellipsis when it
    // overruns; the full title is revealed on hover via [CcTooltip].
    return CcTooltip(
      message: stripInlineCode(pr.title),
      maxWidth: 480,
      child: PrTitleText(
        pr.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style?.copyWith(color: t.textPrimary),
        leading: [
          TextSpan(
            text: '#${pr.number} ',
            style: style?.copyWith(
              fontWeight: CcTypography.regularWeight,
              color: t.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the PR body as markdown, or a placeholder.
class PrBodyMarkdown extends ConsumerWidget {
  /// PrBodyMarkdown({super.key,.
  const PrBodyMarkdown({
    super.key,
    required this.body,
    required this.repoFullName,
    this.bodyHtml,
    this.pending = false,
    this.onAttachmentLoadFailed,
  });

  /// True while [body] is merely unfetched rather than genuinely absent —
  /// renders a skeleton instead of the "no description" placeholder.
  final bool pending;

  /// Markdown body text.
  final String body;

  /// GitHub-rendered HTML for the same body (used to recover pre-signed
  /// URLs for private user-attachments). Null when unavailable.
  final String? bodyHtml;

  /// Repository full name (owner/repo) used to resolve bare `#123` references.
  final String repoFullName;

  /// Invoked when a private user-attachment image fails to load — gives the
  /// parent a chance to refresh `bodyHtml` (the JWT in pre-signed URLs is
  /// only valid for 5 minutes).
  final VoidCallback? onAttachmentLoadFailed;

  /// GitHub bearer token forwarded to authenticated image fetches.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMarkdownBodyEffectivelyEmpty(body)) {
      if (pending) {
        return const PrDescriptionSkeleton();
      }
      final t = context.designSystem ?? DesignSystemTokens.light();
      return Text(
        AppLocalizations.of(context).noDescriptionProvided,
        style: CcTypography.body.copyWith(color: t.textTertiary),
      );
    }

    final parts = repoFullName.split('/');
    final owner = parts.length >= 2 ? parts[0] : '';
    final repo = parts.length >= 2 ? parts[1] : '';

    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final workspaceRepos = workspaceId == null
        ? const <String>{}
        : (ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [])
              .map(
                (r) =>
                    '${r.remoteOwner.toLowerCase()}/${r.remoteName.toLowerCase()}',
              )
              .toSet();

    Future<void> switchToRepo(String wsId, String repoId) async {
      await ref.read(activeWorkspaceIdProvider.notifier).setActive(wsId);
      await ref.read(activeRepoIdProvider.notifier).setActive(repoId);
    }

    return GitHubMarkdownBody(
      data: body,
      bodyHtml: bodyHtml,
      onAttachmentLoadFailed: onAttachmentLoadFailed,
      repoOwner: owner,
      repoName: repo,
      codeFontFamily: codeFont,
      codeLigatures: ref.watch(codeFontLigaturesProvider),
      linkBuilder: GitHubReferenceLinkBuilder(
        currentOwner: owner,
        currentRepo: repo,
        knownWorkspaceRepos: workspaceRepos,
        onSwitchToRepo: switchToRepo,
      ),
      onSwitchToRepo: switchToRepo,
      embedVideos: true,
    );
  }
}
