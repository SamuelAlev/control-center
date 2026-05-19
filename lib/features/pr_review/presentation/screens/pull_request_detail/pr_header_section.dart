import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/markdown_style.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_body_editor.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/reaction_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// PrHeaderSection.
class PrHeaderSection extends ConsumerWidget {
  /// PrHeaderSection({.
  const PrHeaderSection({
    super.key,
    required this.pr,
    required this.prNumber,
    required this.isWide,
  });

  /// PullRequest.
  final PullRequest pr;
  /// Pull request number (used for data lookups).
  final int prNumber;
  /// Whether the layout is wide enough for side-by-side.
  final bool isWide;

  /// Width of the inline sidebar in wide mode.
  static const double _sidebarWidth = 240;

  /// Horizontal gap between body and sidebar in wide mode.
  static const double _sidebarGap = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final githubToken = ref.watch(githubAuthTokenProvider);
    final markdown = PrBodyMarkdown(
      body: pr.body,
      bodyHtml: pr.bodyHtml,
      repoFullName: pr.repoFullName,
      githubToken: githubToken,
      onAttachmentLoadFailed: () {
        ref
            .read(prDetailPollingProvider(prNumber).notifier)
            .invalidateAttachments();
      },
    );
    // Long descriptions push the diff (the operator's actual work) below the
    // fold, so collapse them by default behind a "Show more" disclosure. The
    // heuristic is on raw markdown size — deterministic and flicker-free, no
    // post-layout height measurement. Short bodies render in full, untouched.
    final trimmedBody = pr.body.trim();
    final collapsible = trimmedBody.length > 600 ||
        '\n'.allMatches(trimmedBody).length >= 8;

    // The body editor is gated on edit access: the PR author, or a user with
    // write/admin on the repo (same derivation as the merge/close actions in
    // the title bar). The title itself moved to the fixed title row.
    final canEdit = ref.watch(prCanEditProvider(prNumber));

    final body = PrBodyEditor(
      prNumber: prNumber,
      initialMarkdown: pr.body,
      repoFullName: pr.repoFullName,
      githubToken: githubToken,
      canEdit: canEdit,
      bodyHtml: pr.bodyHtml,
      readChild: _CollapsiblePrBody(collapsible: collapsible, child: markdown),
    );
    final checks =
        ref.watch(prCheckRunsProvider(prNumber)).value ?? <CheckRun>[];
    final optimisticMyState =
        ref.watch(prOptimisticReviewStateProvider)[prNumber];

    final reactionBar = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ReactionBar(
        reactions: pr.reactions,
        onToggle: (content, {required add}) async {
          await toggleReaction(
            ref,
            ReactionTarget.pullRequest,
            prNumber: prNumber,
            content: content,
            add: add,
          );
        },
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                body,
                reactionBar,
              ],
            ),
          ),
          const SizedBox(width: _sidebarGap),
          SizedBox(
            width: _sidebarWidth,
            child: PrSidebar(
              pr: pr,
              checks: checks,
              canEdit: canEdit,
              optimisticMyState: optimisticMyState,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        reactionBar,
        const SizedBox(height: 24),
        PrSidebar(pr: pr, checks: checks, canEdit: canEdit),
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

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '#${pr.number} ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.theme.colors.mutedForeground,
            ),
          ),
          TextSpan(
            text: pr.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.theme.colors.foreground,
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
    this.onAttachmentLoadFailed,
    this.githubToken = '',
  });
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
  final String githubToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMarkdownBodyEffectivelyEmpty(body)) {
      return Text(
        AppLocalizations.of(context).noDescriptionProvided,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      );
    }

    final parts = repoFullName.split('/');
    final owner = parts.length >= 2 ? parts[0] : '';
    final repo = parts.length >= 2 ? parts[1] : '';

    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final workspaceRepos = workspaceId == null
        ? const <String>{}
        : (ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [])
            .map(
              (r) =>
                  '${r.githubOwner.toLowerCase()}/${r.githubRepoName.toLowerCase()}',
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
      styleSheet: prMarkdownStyleSheet(context),
      checkboxBuilder: prCheckboxBuilder(context),
      builders: {
        'code': InlineCodeBuilder(),
        'pre': CodeBlockBuilder(),
        'a': GitHubReferenceLinkBuilder(
          currentOwner: owner,
          currentRepo: repo,
          knownWorkspaceRepos: workspaceRepos,
          onSwitchToRepo: switchToRepo,
        ),
      },
      onSwitchToRepo: switchToRepo,
      githubToken: githubToken,
      embedVideos: true,
    );
  }
}

/// Wraps the PR description so a long body doesn't push the diff below the
/// fold. When [collapsible] is false the [child] renders untouched. When true
/// it starts capped at a fixed height with a bottom fade and a "Show more"
/// toggle; expanding reveals the full body.
///
/// The cap uses a non-scrolling `SingleChildScrollView` so the markdown lays
/// out at its natural height and is clipped to the window — no RenderFlex
/// overflow, no fragile post-layout measurement. The expand/collapse swap is
/// instant: animating the box made the body resize on every async change
/// (body_html arriving, each image loading), which read as the description
/// "shifting" repeatedly.
class _CollapsiblePrBody extends StatefulWidget {
  const _CollapsiblePrBody({required this.collapsible, required this.child});

  final bool collapsible;
  final Widget child;

  @override
  State<_CollapsiblePrBody> createState() => _CollapsiblePrBodyState();
}

class _CollapsiblePrBodyState extends State<_CollapsiblePrBody> {
  static const double _collapsedMaxHeight = 240;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.collapsible) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;

    final content = _expanded
        ? widget.child
        : SizedBox(
            height: _collapsedMaxHeight,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: widget.child,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.background.withValues(alpha: 0),
                            colors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    // Instant collapsed/expanded swap — no AnimatedSize. Animating the box
    // made the body resize on every async change (body_html, each image
    // loading), which read as the description "shifting like crazy".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadii.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? l10n.showLess : l10n.showMore,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

