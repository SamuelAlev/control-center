import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_tab.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The localized label for a context segment kind.
String contextSegmentLabel(AppLocalizations l10n, ContextSegmentKind kind) =>
    switch (kind) {
      ContextSegmentKind.systemPrompt => l10n.contextSegmentSystemPrompt,
      ContextSegmentKind.rules => l10n.contextSegmentRules,
      ContextSegmentKind.skills => l10n.contextSegmentSkills,
      ContextSegmentKind.toolDefinitions => l10n.contextSegmentToolDefinitions,
      ContextSegmentKind.mcpTools => l10n.contextSegmentMcpTools,
      ContextSegmentKind.deferredTools => l10n.contextSegmentDeferredTools,
      ContextSegmentKind.subagents => l10n.contextSegmentSubagents,
      ContextSegmentKind.memory => l10n.contextSegmentMemory,
      ContextSegmentKind.conversation => l10n.contextSegmentConversation,
    };

/// The color of a segment kind, keyed by its DECLARATION index into the
/// categorical chart palette — stable across renders, unlike hash- or
/// order-based assignment.
Color contextSegmentColor(DesignSystemTokens tokens, ContextSegmentKind kind) =>
    tokens.chartCategorical[kind.index % tokens.chartCategorical.length];

/// The stacked context-window bar: one colored segment per non-empty
/// [ContextSegment] (in [ContextSegmentKind] declaration order — the
/// [ContextBreakdown] merge guarantees it), on a tertiary track.
class ContextStackedBar extends StatelessWidget {
  /// Creates a [ContextStackedBar].
  const ContextStackedBar({super.key, required this.segments, this.height = 6});

  /// The segments to stack, in declaration order.
  final List<ContextSegment> segments;

  /// Bar height in logical pixels (fully rounded ends).
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final nonEmpty = [
      for (final s in segments)
        if (s.tokens > 0) s,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: tokens.bgTertiary)),
            Row(
              children: [
                for (final s in nonEmpty)
                  Flexible(
                    flex: s.tokens,
                    child: Container(
                      color: contextSegmentColor(tokens, s.kind),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The context-meter popover: "N% full", the stacked per-category bar and one
/// row per segment, with a footer that opens the full context explorer tab.
///
/// Never blocks on the summary RPC: the client-known conversation row renders
/// immediately and the persistent categories slot in when the server answers.
class ContextUsageFlyout extends ConsumerWidget {
  /// Creates a [ContextUsageFlyout] for the [spaceId] / [agentId] pair.
  const ContextUsageFlyout({
    super.key,
    required this.spaceId,
    required this.agentId,
    required this.controller,
    this.agentName,
  });

  /// The space whose context to break down.
  final String spaceId;

  /// The agent whose context window this is.
  final String agentId;

  /// The agent's display name, when the space holds more than one agent and
  /// the breakdown therefore has to say whose window it is. Null in the
  /// single-agent case, where the answer is not in doubt.
  final String? agentName;

  /// The popover's controller — the footer action closes the popover after
  /// opening the explorer.
  final CcOverlayController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final breakdown = ref.watch(
      contextBreakdownProvider((spaceId: spaceId, agentId: agentId)),
    );
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    // Off-Material overlay: supply a concrete default so nothing falls through
    // to the engine's 48px yellow error fallback.
    return DefaultTextStyle(
      style: TextStyle(
        color: tokens.textPrimary,
        fontSize: 13,
        decoration: TextDecoration.none,
      ),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // Whose window, when several are in play — the same
                      // "title · agent" shape the explorer pane uses.
                      agentName == null || agentName!.isEmpty
                          ? l10n.contextUsage
                          : '${l10n.contextUsage} · ${agentName!}',
                      style: CcTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CcIconButton(
                    icon: AppIcons.x,
                    size: CcButtonSize.sm,
                    semanticLabel: l10n.close,
                    onPressed: controller.hide,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(breakdown.fraction * 100).round()}% '
                    '${l10n.contextUsageFull}',
                    style: CcTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    '~${formatContextTokenCount(breakdown.totalTokens)} / '
                    '${formatContextTokenCount(breakdown.windowTokens)} '
                    '${l10n.contextUsageTokens}',
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ContextStackedBar(segments: breakdown.segments),
              const SizedBox(height: AppSpacing.md),
              // The conversation row is client-known and always renders; the
              // server's persistent categories slot in beneath it. While the
              // summary is in flight a small placeholder stands in for them.
              for (final segment in breakdown.segments)
                if (segment.kind == ContextSegmentKind.conversation ||
                    segment.tokens > 0)
                  _SegmentRow(
                    color: contextSegmentColor(tokens, segment.kind),
                    label: contextSegmentLabel(l10n, segment.kind),
                    tokens: segment.tokens,
                  ),
              if (breakdown.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Center(child: CcSpinner(size: 12)),
                )
              else if (breakdown.hasError)
                Text(
                  l10n.contextExplorerUnavailable,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                fullWidth: true,
                icon: AppIcons.arrowUpRight,
                // The explorer needs the active workspace to build its tab;
                // without one the action would dead-end, so it disables.
                onPressed: workspaceId == null
                    ? null
                    : () {
                        openContextExplorer(
                          context,
                          workspaceId: workspaceId,
                          spaceId: spaceId,
                          agentId: agentId,
                          agentName: agentName,
                        );
                        controller.hide();
                      },
                child: Text(l10n.contextSeeMore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.color,
    required this.label,
    required this.tokens,
  });

  final Color color;
  final String label;
  final int tokens;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatContextTokenCount(tokens),
            style: CcFonts.code(
              textStyle: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
