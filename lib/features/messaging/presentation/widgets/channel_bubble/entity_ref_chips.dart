import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_reference_preview_provider.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Renders a message's tagged entity references (`#ticket` / `#pr` /
/// `#meeting`) as compact, live-resolving chips beneath the bubble. Each chip
/// resolves its entity through a workspace-scoped provider and falls back to
/// the label captured at tag time while loading or if the entity is gone.
class EntityRefChips extends StatelessWidget {
  /// Creates an [EntityRefChips].
  const EntityRefChips({super.key, required this.refs, this.alignEnd = false});

  /// The references to render.
  final List<EntityRef> refs;

  /// When true (user messages), chips align to the trailing edge.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    if (refs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: 6,
      runSpacing: 6,
      children: [for (final r in refs) _EntityRefChip(reference: r)],
    );
  }
}

class _EntityRefChip extends ConsumerWidget {
  const _EntityRefChip({required this.reference});

  final EntityRef reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    switch (reference.type) {
      case EntityRefType.ticket:
        final ticket = workspaceId == null
            ? null
            : ref
                  .watch(
                    ticketByIdProvider(
                      (workspaceId: workspaceId, ticketId: reference.id),
                    ),
                  )
                  .value;
        return _chip(
          context,
          icon: AppIcons.ticket,
          text: ticket?.displayKey ?? reference.label ?? l10n.entityRefTicketFallback,
          tooltip: ticket?.title,
          onTap: () => context.go(
            ticketDetailRoute(context.currentWorkspaceId!, reference.id),
          ),
        );
      case EntityRefType.meeting:
        final meeting = workspaceId == null
            ? null
            : ref
                  .watch(
                    meetingDetailProvider(
                      (workspaceId: workspaceId, meetingId: reference.id),
                    ),
                  )
                  .value;
        return _chip(
          context,
          icon: AppIcons.audioLines,
          text: meeting?.title ?? reference.label ?? l10n.entityRefMeetingFallback,
          onTap: () => context.go(
            meetingDetailRoute(context.currentWorkspaceId!, reference.id),
          ),
        );
      case EntityRefType.pullRequest:
        return _buildPr(context, ref, l10n);
    }
  }

  Widget _buildPr(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final number = int.tryParse(reference.id);
    final parts = (reference.repoFullName ?? '').split('/');
    final hasRepo =
        parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
    // Only resolve the live PR (title/state) when its repo is linked to the
    // ACTIVE workspace — never fetch a foreign-workspace PR ref. For others we
    // render from the captured label only and link straight to GitHub.
    final inWorkspace = hasRepo &&
        ref.watch(
          repoInActiveWorkspaceProvider((owner: parts[0], repo: parts[1])),
        );
    PrPreview? preview;
    if (inWorkspace && number != null) {
      preview = ref
          .watch(
            prReferencePreviewProvider(
              PrReferenceKey(owner: parts[0], repo: parts[1], number: number),
            ),
          )
          .value;
    }
    // Prefer the resolved html_url; otherwise build the canonical GitHub URL
    // from the ref's own owner/repo/number (repo-unambiguous, no API call).
    final String? webUrl = (preview?.htmlUrl.isNotEmpty ?? false)
        ? preview!.htmlUrl
        : (hasRepo && number != null
              ? 'https://github.com/${reference.repoFullName}/pull/$number'
              : null);
    return _chip(
      context,
      icon: AppIcons.gitPullRequest,
      text: number != null ? '#$number' : (reference.label ?? l10n.entityRefPrFallback),
      tooltip: preview?.title,
      onTap: webUrl == null ? null : () => openExternalUrl(webUrl),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? tooltip,
    required VoidCallback? onTap,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    Widget chip = MouseRegion(
      cursor: onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: t.borderSecondary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: t.fgTertiary),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null && tooltip.isNotEmpty) {
      chip = CcTooltip(message: tooltip, child: chip);
    }
    return chip;
  }
}
