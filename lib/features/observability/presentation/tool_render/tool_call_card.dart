import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_render_parts.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_renderers.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/widgets/nested_tool_calls.dart';
import 'package:flutter/widgets.dart';

/// An expandable card rendering one [ToolSegment] via its resolved renderer:
/// always-visible status + name + one-line summary, with a tappable body when
/// the renderer provides detail.
///
/// A call that ran a script lists the calls the script made in its body, each
/// as a card of its own, the way the chat transcript nests them.
class ToolCallCard extends StatefulWidget {
  /// Creates a [ToolCallCard].
  const ToolCallCard({
    super.key,
    required this.segment,
    this.initiallyExpanded = false,
    this.nestedCalls = const [],
  });

  /// The tool call to render.
  final ToolSegment segment;

  /// Whether the body starts expanded.
  final bool initiallyExpanded;

  /// The calls a script made from this call, in the order it made them.
  final List<ToolSegment> nestedCalls;

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final segment = widget.segment;
    final calls = widget.nestedCalls;
    final renderer = resolveToolRenderer(segment.toolName);
    final body = calls.isEmpty
        ? renderer.body(context, segment)
        : renderer.bodyWithCalls(
            context,
            segment,
            NestedToolCalls(
              script: segment,
              calls: calls,
              ended: segment.status != ToolSegmentStatus.running,
              codeFont: CcFonts.codeFamily,
              itemBuilder: (context, call) => ToolCallCard(segment: call),
            ),
          );
    final hasBody = body != null && !segment.isPruned;
    final duration = toolDurationLabel(segment.durationMs);

    final header = Row(
      children: [
        toolStatusIcon(context, segment.status),
        const SizedBox(width: AppSpacing.sm),
        Text(
          normalizeToolName(segment.toolName),
          style: CcTypography.label.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: renderer.summary(context, segment)),
        if (calls.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            nestedCallSummary(
              AppLocalizations.of(context),
              NestedCallTally.of(calls),
            ),
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
        if (segment.isPruned) ...[
          const SizedBox(width: AppSpacing.xs),
          const ToolChip(label: 'pruned', tone: ObsTone.warning),
        ],
        if (duration.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            duration,
            style: CcTypography.caption.copyWith(color: t.textQuaternary),
          ),
        ],
        if (hasBody)
          Icon(
            _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
            size: 14,
            color: t.fgTertiary,
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBody)
            CcTappable(
              onPressed: () => setState(() => _expanded = !_expanded),
              semanticExpanded: _expanded,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: header,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: header,
            ),
          if (hasBody)
            CcCollapsible(
              expanded: _expanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: body,
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders an ordered list of tool calls as a column of [ToolCallCard]s.
///
/// The calls a script made fold into the card of the call that ran it; one
/// whose parent is not in [segments] keeps a card of its own.
class TranscriptToolList extends StatelessWidget {
  /// Creates a [TranscriptToolList].
  const TranscriptToolList({super.key, required this.segments});

  /// The tool segments, in transcript order.
  final List<ToolSegment> segments;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (segments.isEmpty) {
      return Text(
        'No tool calls yet.',
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    final nested = foldNestedCalls(segments);
    final folded = {for (final children in nested.values) ...children};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < segments.length; i++)
          if (!folded.contains(i))
            ToolCallCard(
              segment: segments[i],
              nestedCalls: nestedCallsAt(nested[i] ?? const [], segments),
            ),
      ],
    );
  }
}
