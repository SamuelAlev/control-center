import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A resolved pull request paired with the repo it belongs to.
typedef _ResolvedPr = ({PullRequest pr, Repo repo});

/// A card listing the pull requests linked to a ticket. Each linked PR is
/// resolved against the workspace's open PRs (so it renders with its title,
/// number and live status and opens the PR on tap); links to PRs that aren't
/// in the open list (merged, closed, or not yet loaded) fall back to showing
/// the raw node id. An add control links further PRs and rows are removable on
/// hover.
///
/// PRs are linked by their GitHub GraphQL node id — the same identifier the
/// `link_ticket_to_pr` MCP tool uses — so in-app links and agent-made links
/// share one representation.
class TicketLinkedPrsCard extends ConsumerWidget {
  /// Creates a [TicketLinkedPrsCard].
  const TicketLinkedPrsCard({
    super.key,
    required this.ticket,
    required this.workspaceId,
  });

  /// The ticket whose linked PRs are shown.
  final Ticket ticket;

  /// The workspace that owns the ticket.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final repos =
        ref.watch(prsByRepoProvider).asData?.value.repos ??
        const <RepoPullRequests>[];
    final byNodeId = <String, _ResolvedPr>{
      for (final rp in repos)
        for (final pr in rp.prs) pr.nodeId: (pr: pr, repo: rp.repo),
    };

    return Container(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.linkedPullRequests,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: t.textTertiary,
                  ),
                ),
              ),
              _AddLinkedPrButton(
                ticket: ticket,
                workspaceId: workspaceId,
                repos: repos,
              ),
            ],
          ),
          if (ticket.linkedPrIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.noLinkedPullRequests,
                style: TextStyle(fontSize: 13, color: t.textQuaternary),
              ),
            )
          else
            for (final nodeId in ticket.linkedPrIds)
              _LinkedPrRow(
                nodeId: nodeId,
                resolved: byNodeId[nodeId],
                onOpen: byNodeId[nodeId] == null
                    ? null
                    : () => openPrInRepo(
                        ref,
                        context,
                        byNodeId[nodeId]!.repo,
                        byNodeId[nodeId]!.pr.number,
                      ),
                onRemove: () => ref
                    .read(ticketWorkflowServiceProvider)
                    .unlinkPullRequest(
                      ticket.id,
                      nodeId,
                      workspaceId: workspaceId,
                    ),
              ),
        ],
      ),
    );
  }
}

/// A single linked-PR row: status icon + title (or the raw node id when the PR
/// can't be resolved), tappable to open the PR, with hover-to-remove.
class _LinkedPrRow extends StatefulWidget {
  const _LinkedPrRow({
    required this.nodeId,
    required this.resolved,
    required this.onOpen,
    required this.onRemove,
  });

  final String nodeId;
  final _ResolvedPr? resolved;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  State<_LinkedPrRow> createState() => _LinkedPrRowState();
}

class _LinkedPrRowState extends State<_LinkedPrRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final resolved = widget.resolved;
    final status = resolved == null
        ? null
        : prStatusIconData(resolved.pr, context);

    final labelStyle = TextStyle(
      fontSize: resolved == null ? 12 : 13,
      color: resolved == null ? t.textQuaternary : t.textSecondary,
      fontWeight: resolved == null ? FontWeight.w400 : FontWeight.w500,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                status?.icon ?? LucideIcons.gitPullRequest,
                size: 14,
                color: status?.color ?? t.fgBrandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: resolved == null
                    ? Text(
                        widget.nodeId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      )
                    : PrTitleText(
                        resolved.pr.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                        leading: [
                          TextSpan(
                            text: '#${resolved.pr.number}  ',
                            style: labelStyle,
                          ),
                        ],
                      ),
              ),
              if (_hovered)
                CcTappable(
                  onPressed: widget.onRemove,
                  builder: (context, states) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(LucideIcons.x, size: 14, color: t.fgQuaternary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "+" control that opens a popover of the workspace's open PRs, grouped by
/// repo. Tapping a PR toggles its link; already-linked PRs show a check. The
/// popover stays open for multi-select and reflects link changes live.
class _AddLinkedPrButton extends ConsumerStatefulWidget {
  const _AddLinkedPrButton({
    required this.ticket,
    required this.workspaceId,
    required this.repos,
  });

  final Ticket ticket;
  final String workspaceId;
  final List<RepoPullRequests> repos;

  @override
  ConsumerState<_AddLinkedPrButton> createState() => _AddLinkedPrButtonState();
}

class _AddLinkedPrButtonState extends ConsumerState<_AddLinkedPrButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLink(PullRequest pr) {
    final workflow = ref.read(ticketWorkflowServiceProvider);
    if (widget.ticket.linkedPrIds.contains(pr.nodeId)) {
      workflow.unlinkPullRequest(
        widget.ticket.id,
        pr.nodeId,
        workspaceId: widget.workspaceId,
      );
    } else {
      workflow.linkPullRequest(
        widget.ticket.id,
        pr.nodeId,
        workspaceId: widget.workspaceId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    final reposWithPrs =
        widget.repos.where((r) => r.prs.isNotEmpty).toList();

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      target: CcTappable(
        onPressed: _controller.toggle,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(LucideIcons.plus, size: 16, color: t.fgTertiary),
        ),
      ),
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: card.bg,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: card.border),
            boxShadow: CcElevation.floating,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: reposWithPrs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.noOpenPullRequests,
                        style: TextStyle(fontSize: 13, color: t.textTertiary),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < reposWithPrs.length; i++) ...[
                          if (i > 0) const CcDivider(),
                          _MenuSectionLabel(label: reposWithPrs[i].repo.fullName),
                          for (final pr in reposWithPrs[i].prs)
                            CcTile(
                              leading: Icon(
                                prStatusIconData(pr, context).icon,
                                size: 16,
                                color: prStatusIconData(pr, context).color,
                              ),
                              title: PrTitleText(
                                '#${pr.number}  ${pr.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing:
                                  widget.ticket.linkedPrIds.contains(pr.nodeId)
                                  ? const Icon(LucideIcons.check, size: 16)
                                  : null,
                              onTap: () => _toggleLink(pr),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small caption-cased header that titles a section of menu rows.
class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: t.textTertiary,
        ),
      ),
    );
  }
}
