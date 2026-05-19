import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A single pipeline run in the runs list rail.
///
/// Shows the pipeline's friendly name, how it was triggered and how long ago it
/// started, and the elapsed / total duration followed by the status badge.
/// Deleting a run lives in the detail header alongside Retry, not here.
class PipelineRunCard extends StatefulWidget {
  /// Creates a [PipelineRunCard].
  const PipelineRunCard({
    super.key,
    required this.run,
    required this.now,
    this.title,
    this.selected = false,
    this.onTap,
  });

  /// The pipeline run to display.
  final PipelineRun run;

  /// Current time for live duration / relative-time display. Supplied from a
  /// clock provider.
  final DateTime now;

  /// Friendly pipeline name resolved from the template. Falls back to the
  /// run's template id when null.
  final String? title;

  /// Whether this card is the currently selected run.
  final bool selected;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  State<PipelineRunCard> createState() => _PipelineRunCardState();
}

class _PipelineRunCardState extends State<PipelineRunCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final run = widget.run;

    final duration = run.finishedAt != null
        ? run.finishedAt!.difference(run.startedAt)
        : widget.now.difference(run.startedAt);

    final isManual =
        run.triggerEventType == null || run.triggerEventType == 'manual';
    final triggerIcon = isManual ? LucideIcons.play : LucideIcons.zap;
    final triggerLabel = isManual
        ? l10n.pipelineRunTriggerManual
        : l10n.pipelineRunTriggerAuto;
    final subtitle =
        '${_relativeLabel(relativePipelineTime(run.startedAt, widget.now), l10n)}'
        ' · $triggerLabel';

    final background = widget.selected
        ? tokens.bgActive
        : _hovered
        ? tokens.bgPrimaryHover
        : tokens.bgPrimary;
    final border = widget.selected
        ? tokens.borderBrand
        : tokens.borderSecondary;

    return Semantics(
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FTappable.static(
          onPress: widget.onTap,
          focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: border, width: widget.selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title ?? run.templateId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            triggerIcon,
                            size: 11,
                            color: tokens.fgQuaternary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.textTertiary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Text(
                  formatPipelineDurationCoarse(duration),
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacing.hGapSm,
                PipelineStatusBadge.forRun(status: run.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps a bucketed [RelativeTime] onto its localized label.
String _relativeLabel(RelativeTime r, AppLocalizations l10n) {
  return switch (r.unit) {
    RelativeTimeUnit.justNow => l10n.relativeJustNow,
    RelativeTimeUnit.minutes => l10n.relativeMinutesAgo(r.count),
    RelativeTimeUnit.hours => l10n.relativeHoursAgo(r.count),
    RelativeTimeUnit.days => l10n.relativeDaysAgo(r.count),
  };
}
