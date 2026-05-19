import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/markdown_style.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The inline "peek" expanded under a PR row: a quiet summary of the change on
/// the left and the PR's measurable shape (checks, files, commits, comments) on
/// the right. Built only from data we already hold on [PullRequest] — no extra
/// fetch — so it stays instant. Deeper inspection is one click away via the
/// actions, which open the full PR.
class PrPeekPanel extends StatelessWidget {
  /// Creates a [PrPeekPanel].
  const PrPeekPanel({super.key, required this.pr, required this.onOpen});

  /// The pull request being peeked.
  final PullRequest pr;

  /// Opens the full PR (navigates to the detail screen).
  final VoidCallback onOpen;

  /// Below this width the summary and checks stack vertically; at or above it
  /// the checks sit in a rail beside the summary.
  static const double _sideBySideThreshold = 620;

  /// Fixed width of the checks rail in the side-by-side layout. The summary
  /// takes whatever's left, so it never drops below
  /// `_sideBySideThreshold - _checksRailWidth` (~340px) of reading width.
  static const double _checksRailWidth = 280;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final border = tokens?.borderSecondary ?? colors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tokens?.rail ?? colors.muted,
        borderRadius: AppRadii.brMd,
        border: Border(
          left: BorderSide(color: border),
          right: BorderSide(color: border),
        ),
      ),
      // Checks sit beside the summary when the row is wide enough, and drop
      // below it when it isn't. Either way each side gets a *bounded width,
      // natural height* (side-by-side: Expanded summary + fixed-width checks;
      // stacked: a full-width Column), so we sidestep the two traps a naive
      // equal-height Row hits here: the summary's rendered markdown contains
      // image/video LayoutBuilders, so IntrinsicHeight dry-lays-out them
      // (crash), and CrossAxisAlignment.stretch leaves the row unsized in this
      // unbounded-height context (the peek sits in a scrolling list). The
      // side-by-side separator is a left border on the checks rail rather than
      // a full-height VerticalDivider, which would need that same height
      // measurement.
      child: ClipRRect(
        borderRadius: AppRadii.brMd,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _sideBySideThreshold) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SummaryColumn(pr: pr, onOpen: onOpen)),
                  Container(
                    width: _checksRailWidth,
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: border)),
                    ),
                    child: _ChecksColumn(pr: pr),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryColumn(pr: pr, onOpen: onOpen),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, thickness: 1, color: border),
                _ChecksColumn(pr: pr),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.pr, required this.onOpen});

  final PullRequest pr;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeekHeading(l10n.summary),
          const SizedBox(height: AppSpacing.sm),
          // The list comes from a GraphQL batch that omits the body, so the
          // description is fetched on demand by [_SummaryBody]; it owns the
          // loading / empty / markdown states.
          _SummaryBody(
            repoFullName: pr.repoFullName,
            prNumber: pr.number,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FButton(
                onPress: onOpen,
                variant: FButtonVariant.outline,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(LucideIcons.gitPullRequestArrow, size: 14),
                child: Text(l10n.openFullDiff),
              ),
              FButton(
                onPress: onOpen,
                variant: FButtonVariant.secondary,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(LucideIcons.files, size: 14),
                child: Text(l10n.viewFiles),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders the PR description as markdown at the row's compact `bodySmall`
/// size, so headings/lists/emphasis read as formatting instead of literal
/// `###` syntax. Long bodies are clipped behind a "Show more" disclosure so
/// the peek stays glanceable.
class _SummaryBody extends ConsumerStatefulWidget {
  const _SummaryBody({
    required this.repoFullName,
    required this.prNumber,
  });

  final String repoFullName;
  final int prNumber;

  @override
  ConsumerState<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends ConsumerState<_SummaryBody> {
  static const double _collapsedMaxHeight = 132;
  bool _expanded = false;

  /// One content refetch recovers a genuinely-expired 5-minute JWT. Beyond
  /// that the failure is persistent (a PAT can't fetch the asset, a 404, an
  /// unexpected content-type), and each refetch only mints a fresh URL that
  /// resets the image widget's failure guard and fires the callback again — an
  /// unbounded loop. Cap recovery at one attempt; the attachment card covers
  /// the broken image.
  static const _maxAttachmentRefreshes = 1;
  int _attachmentRefreshes = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final colors = context.theme.colors;

    final parts = widget.repoFullName.split('/');
    final owner = parts.length >= 2 ? parts[0] : '';
    final repo = parts.length >= 2 ? parts[1] : '';

    // The list comes from a GraphQL batch that omits body/body_html, so both
    // are fetched here scoped to this PR's own repo (the list spans repos, so
    // the active-repo `prDetailProvider` can't be reused). body_html carries
    // the pre-signed `private-user-images.*` URLs that let private-repo
    // screenshots load — without it the raw `user-attachments` URLs 404 with a
    // PAT and the renderer falls back to the "open in GitHub" attachment card.
    final contentKey = (
      owner: owner,
      repo: repo,
      number: widget.prNumber,
    );
    final contentAsync = ref.watch(peekPrContentProvider(contentKey));
    final content = contentAsync.value;
    final body = (content?.body ?? '').trim();
    final bodyHtml = content?.bodyHtml;

    // While the description is still loading there's nothing to render yet;
    // show a quiet placeholder rather than flashing "no description" first.
    // A body that's only HTML comments (e.g. an untouched PR template) renders
    // to nothing, so treat it as empty too — otherwise the peek shows a blank
    // gap instead of the placeholder.
    if (isMarkdownBodyEffectivelyEmpty(body)) {
      if (contentAsync.isLoading) {
        return const _SummaryLoadingPlaceholder();
      }
      return Text(
        l10n.noDescriptionProvided,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tokens?.muted ?? colors.mutedForeground,
          height: 1.5,
        ),
      );
    }

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

    final markdown = GitHubMarkdownBody(
      data: body,
      repoOwner: owner,
      repoName: repo,
      styleSheet: _peekMarkdownStyleSheet(context),
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
      bodyHtml: bodyHtml,
      attachmentsPending: contentAsync.isLoading,
      onAttachmentLoadFailed: () {
        // A failure here means a stale JWT on an already-spliced pre-signed
        // URL. Refetch to mint a fresh one — but only when content has
        // resolved (a failure while still loading can't come from a fetched
        // attachment) and only up to the cap, so a persistently-broken image
        // can't loop the refetch.
        if (_attachmentRefreshes >= _maxAttachmentRefreshes) {
          return;
        }
        if (!ref.read(peekPrContentProvider(contentKey)).isLoading) {
          _attachmentRefreshes++;
          ref.invalidate(peekPrContentProvider(contentKey));
        }
      },
      onSwitchToRepo: switchToRepo,
      githubToken: ref.watch(githubAuthTokenProvider),
    );

    // Same deterministic heuristic the detail screen uses — keyed on raw
    // markdown size so there's no post-layout measurement or flicker. Short
    // bodies render untouched.
    final collapsible =
        body.length > 600 || '\n'.allMatches(body).length >= 8;
    if (!collapsible) {
      return markdown;
    }

    final fade = tokens?.rail ?? colors.muted;
    final collapsedBody = _expanded
        ? markdown
        : SizedBox(
            height: _collapsedMaxHeight,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: markdown,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [fade.withValues(alpha: 0), fade],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    // The collapsed/expanded swap is instant — no AnimatedSize. Wrapping the
    // markdown in an animated box made it resize on every async change
    // (body_html arriving, each image loading), which read as the body
    // "shifting like crazy". An instant toggle stays calm.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        collapsedBody,
        const SizedBox(height: 2),
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

/// Quiet skeleton shown while the PR description is being fetched, so the peek
/// doesn't flash "no description provided" before the body lands. Three muted
/// bars roughly the height of a short summary.
class _SummaryLoadingPlaceholder extends StatelessWidget {
  const _SummaryLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final bar = (tokens?.borderSecondary ?? colors.border).withValues(
      alpha: 0.6,
    );

    Widget line(double widthFactor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: bar,
          borderRadius: AppRadii.brSm,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        line(1),
        const SizedBox(height: 6),
        line(0.92),
        const SizedBox(height: 6),
        line(0.6),
      ],
    );
  }
}

/// A flattened variant of [prMarkdownStyleSheet] tuned for the peek panel:
/// every block (paragraphs, headings, lists, quotes) renders at the row's
/// `bodySmall` size so the rendered markdown keeps the same footprint as the
/// plain-text summary it replaces — headings read as bold, not as large type.
MarkdownStyleSheet _peekMarkdownStyleSheet(BuildContext context) {
  final base = prMarkdownStyleSheet(context, compact: true);
  final size = Theme.of(context).textTheme.bodySmall?.fontSize ?? 12;
  final secondary =
      context.designSystem?.textSecondary ?? context.theme.colors.foreground;

  TextStyle? sized(TextStyle? s, {FontWeight? weight, Color? color}) => s
      ?.copyWith(fontSize: size, height: 1.5, fontWeight: weight, color: color);

  const headingPad = EdgeInsets.only(top: 6, bottom: 2);
  return base.copyWith(
    p: sized(base.p, color: secondary),
    pPadding: const EdgeInsets.only(bottom: 6),
    h1: sized(base.h1, weight: FontWeight.w700),
    h1Padding: headingPad,
    h2: sized(base.h2, weight: FontWeight.w700),
    h2Padding: headingPad,
    h3: sized(base.h3, weight: FontWeight.w600),
    h3Padding: headingPad,
    h4: sized(base.h4, weight: FontWeight.w600),
    h4Padding: headingPad,
    h5: sized(base.h5, weight: FontWeight.w600),
    h6: sized(base.h6, weight: FontWeight.w600),
    listBullet: sized(base.listBullet, color: secondary),
    blockquote: sized(base.blockquote),
    code: base.code?.copyWith(fontSize: size - 1),
  );
}

class _ChecksColumn extends ConsumerWidget {
  const _ChecksColumn({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final colors = context.theme.colors;

    // `changedFiles`/`commitsCount` are peek-only — they're left out of the
    // PR-list batch query and arrive with the same on-demand fetch that loads
    // the body (`peekPrContentProvider`, deduped with `_SummaryBody`).
    final parts = pr.repoFullName.split('/');
    final content = parts.length >= 2
        ? ref
              .watch(
                peekPrContentProvider((
                  owner: parts[0],
                  repo: parts[1],
                  number: pr.number,
                )),
              )
              .value
        : null;
    final changedFiles = content?.changedFiles ?? pr.changedFiles;
    final commitsCount = content?.commitsCount ?? pr.commitsCount;

    final (
      IconData icon,
      Color color,
      String label,
    ) = switch (pr.checksStatus) {
      PrChecksStatus.passing => (
        LucideIcons.circleCheck,
        tokens?.success ?? const Color(0xFF079455),
        l10n.checksPassing,
      ),
      PrChecksStatus.failing => (
        LucideIcons.circleX,
        tokens?.danger ?? const Color(0xFFD92D20),
        l10n.checksFailing,
      ),
      PrChecksStatus.pending => (
        LucideIcons.clock,
        tokens?.warn ?? const Color(0xFFCA8504),
        l10n.checksRunning,
      ),
      PrChecksStatus.none => (
        LucideIcons.minus,
        tokens?.muted ?? colors.mutedForeground,
        l10n.noOpenPullRequests,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeekHeading(l10n.checksLabel),
          const SizedBox(height: AppSpacing.sm),
          if (pr.checksStatus != PrChecksStatus.none)
            _StatRow(icon: icon, label: label, color: color),
          if (changedFiles > 0)
            _StatRow(
              icon: LucideIcons.fileDiff,
              label: l10n.filesChanged,
              value: '$changedFiles',
            ),
          if (commitsCount > 0)
            _StatRow(
              icon: LucideIcons.gitCommitHorizontal,
              label: l10n.commits,
              value: '$commitsCount',
            ),
          if (pr.commentsCount > 0)
            _StatRow(
              icon: LucideIcons.messageSquare,
              label: l10n.commentsLabel,
              value: '${pr.commentsCount}',
            ),
          _StatRow(
            icon: LucideIcons.clock3,
            label: l10n.updatedAgo(
              formatRelative(pr.updatedAt ?? pr.createdAt),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeekHeading extends StatelessWidget {
  const _PeekHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: tokens?.muted ?? colors.mutedForeground,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        fontSize: 11,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final fg = color ?? tokens?.textSecondary ?? colors.foreground;
    final muted = tokens?.muted ?? colors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color ?? muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}
