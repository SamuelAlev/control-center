import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_stack_ordering.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/widgets.dart';

/// A space's PR inventory, grouped by repository with bottom-first stack rails.
class PullRequestsSection extends StatelessWidget {
  /// Creates the section; a missing [onOpen] leaves the inventory read-only.
  const PullRequestsSection({
    super.key,
    required this.pullRequests,
    this.onOpen,
  });

  /// Deduplicated linked and branch-matched PR snapshots for the active space.
  final List<PullRequest> pullRequests;

  /// Opens the selected PR in the workspace's review surface.
  final ValueChanged<PullRequest>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (pullRequests.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final groups = groupPrsByStack(pullRequests);
    return CollapsibleSidebarSection(
      icon: AppIcons.gitPullRequest,
      label: AppLocalizations.of(context).pullRequests,
      count: '${pullRequests.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups.entries)
            Padding(
              key: ValueKey(group.key),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      group.key,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  for (final chain in group.value)
                    if (chain.length > 1)
                      _PrStack(
                        key: ValueKey(chain.first.number),
                        chain: chain,
                        onOpen: onOpen,
                      )
                    else
                      _PrRow(
                        key: ValueKey(chain.single.number),
                        pr: chain.single,
                        onOpen: onOpen,
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrStack extends StatefulWidget {
  const _PrStack({super.key, required this.chain, required this.onOpen});

  final List<PullRequest> chain;
  final ValueChanged<PullRequest>? onOpen;

  @override
  State<_PrStack> createState() => _PrStackState();
}

class _PrStackState extends State<_PrStack> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final chain = widget.chain;
    final label =
        '${l10n.stackSection} · \u2066#${chain.first.number} · ${chain.first.baseRef}\u2069';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Semantics(
              expanded: _expanded,
              child: CcTappable(
                onPressed: () => setState(() => _expanded = !_expanded),
                semanticLabel:
                    '${chain.first.repoFullName}, $label, ${chain.length}',
                builder: (context, states) => Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  color: states.contains(WidgetState.hovered)
                      ? tokens.hover
                      : null,
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Icon(
                          _expanded
                              ? AppIcons.chevronDown
                              : AppIcons.chevronRight,
                          size: 14,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          AppIcons.layers,
                          size: 14,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SidebarSectionCountBadge(label: '${chain.length}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          CcCollapsible(
            expanded: _expanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < chain.length; i++)
                  _PrRow(
                    key: ValueKey(chain[i].number),
                    pr: chain[i],
                    onOpen: widget.onOpen,
                    position: i + 1,
                    total: chain.length,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({
    super.key,
    required this.pr,
    required this.onOpen,
    this.position,
    this.total,
  });

  final PullRequest pr;
  final ValueChanged<PullRequest>? onOpen;
  final int? position;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final markerSize = MediaQuery.textScalerOf(context).scale(20);
    final markerCenter = AppSpacing.sm + markerSize / 2;
    final markerCenterY = AppSpacing.xs + markerSize / 2;
    final status = switch (pr.state) {
      PrState.merged => (
        icon: AppIcons.gitMerge,
        color: tokens.fgMergedPrimary,
        label: l10n.merged,
      ),
      PrState.closed => (
        icon: AppIcons.gitPullRequestClosed,
        color: tokens.textErrorPrimary,
        label: l10n.closed,
      ),
      PrState.open when pr.isDraft => (
        icon: AppIcons.gitPullRequestDraft,
        color: tokens.textSecondary,
        label: l10n.draft,
      ),
      PrState.open => (
        icon: AppIcons.gitPullRequest,
        color: tokens.textSuccessPrimary,
        label: l10n.openStatus,
      ),
    };
    final title = stripInlineCode(pr.title);
    final stackLabel = position == null
        ? ''
        : ', ${l10n.partOfStack(position!, total!)}';
    return CcTooltip(
      tip: ExcludeSemantics(
        child: Text(
          '$title\n${l10n.baseBranchLabel}: ${pr.baseRef}\n'
          '${l10n.compareBranchLabel}: ${pr.headRef}',
        ),
      ),
      child: CcTappable(
        onPressed: onOpen == null ? null : () => onOpen!(pr),
        semanticLabel:
            '${pr.repoFullName} #${pr.number}, $title, ${status.label}, '
            '${l10n.baseBranchLabel}: ${pr.baseRef}, '
            '${l10n.compareBranchLabel}: ${pr.headRef}$stackLabel',
        builder: (context, states) => ColoredBox(
          color: states.contains(WidgetState.hovered)
              ? tokens.hover
              : tokens.bgPrimary,
          child: ExcludeSemantics(
            child: Stack(
              children: [
                if (position != null)
                  PositionedDirectional(
                    start: markerCenter - 0.5,
                    top: position == 1 ? markerCenterY : 0,
                    bottom: position == total ? null : 0,
                    height: position == total ? markerCenterY : null,
                    width: 1,
                    child: ColoredBox(color: tokens.borderPrimary),
                  ),
                Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (position != null)
                        Container(
                          width: markerSize,
                          height: markerSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.bgPrimary,
                            border: Border.all(color: tokens.borderPrimary),
                          ),
                          child: Text(
                            '$position',
                            style: AppFonts.codeStyle(
                              fontSize: 10,
                              color: tokens.textSecondary,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: markerSize,
                          height: markerSize,
                          child: Icon(
                            status.icon,
                            size: 16,
                            color: status.color,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle.merge(
                              style: CcTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                              child: PrTitleText(
                                pr.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Row(
                              children: [
                                Text(
                                  '#${pr.number}',
                                  textDirection: TextDirection.ltr,
                                  style: AppFonts.codeStyle(
                                    fontSize: 11,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                if (position != null) ...[
                                  Icon(
                                    status.icon,
                                    size: 12,
                                    color: status.color,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Flexible(
                                  child: Text(
                                    status.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
