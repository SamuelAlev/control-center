import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Prominent ship/hold/block verdict banner (PRD 18 §9), aggregated honestly
/// from the axis results. Shown at the top of the studio.
class ReviewVerdictHeader extends StatelessWidget {
  /// Creates a [ReviewVerdictHeader].
  const ReviewVerdictHeader({super.key, required this.verdict});

  /// The aggregated verdict.
  final ReviewVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final (label, color, bg) = switch (verdict.overall) {
      ReviewVerdictOverall.ship => (
        l10n.reviewStudioVerdictShip,
        ds.success,
        ds.successSoft,
      ),
      ReviewVerdictOverall.hold => (
        l10n.reviewStudioVerdictHold,
        ds.warn,
        ds.warnSoft,
      ),
      ReviewVerdictOverall.block => (
        l10n.reviewStudioVerdictBlock,
        ds.danger,
        ds.dangerSoft,
      ),
    };
    final blocking = verdict.blockingAxes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.shieldCheck, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              blocking.isEmpty
                  ? l10n.reviewStudioVerdictClear
                  : l10n.reviewStudioBlockingAxes(
                      blocking.map((a) => _axisLabel(l10n, a.axis)).join(', '),
                    ),
              style: TextStyle(color: ds.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-axis review dashboard (PRD 18 §7): one chip per axis with its verdict
/// and whether it gates the merge. Honest states — a gated axis that could not
/// run reads "unavailable"/"partial", never a silent pass.
class MultiAxisDashboard extends StatelessWidget {
  /// Creates a [MultiAxisDashboard].
  const MultiAxisDashboard({super.key, required this.axes});

  /// The per-axis results.
  final List<ReviewAxisResult> axes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem!;
    if (axes.isEmpty) {
      return Text(
        l10n.reviewStudioNoAxes,
        style: TextStyle(color: ds.textTertiary, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final a in axes) _AxisChip(result: a)],
    );
  }
}

class _AxisChip extends StatelessWidget {
  const _AxisChip({required this.result});

  final ReviewAxisResult result;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final (color, bg) = switch (result.verdict) {
      ReviewAxisVerdict.pass => (ds.success, ds.successSoft),
      ReviewAxisVerdict.warn => (ds.warn, ds.warnSoft),
      ReviewAxisVerdict.fail => (ds.danger, ds.dangerSoft),
      ReviewAxisVerdict.partial => (ds.warn, ds.warnSoft),
      ReviewAxisVerdict.unavailable => (ds.textTertiary, ds.bgSecondary),
    };
    return CcTooltip(
      message: result.note.isEmpty
          ? _verdictLabel(l10n, result.verdict)
          : result.note,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.gated)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  result.blocks ? AppIcons.lock : AppIcons.check,
                  size: 13,
                  color: color,
                ),
              ),
            Text(
              _axisLabel(l10n, result.axis),
              style: TextStyle(
                color: ds.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _verdictLabel(l10n, result.verdict),
              style: TextStyle(color: color, fontSize: 11),
            ),
            if (result.findingsCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${result.findingsCount}',
                style: TextStyle(color: ds.textTertiary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _axisLabel(AppLocalizations l10n, ReviewAxis axis) {
  switch (axis) {
    case ReviewAxis.correctness:
      return l10n.reviewAxisCorrectness;
    case ReviewAxis.security:
      return l10n.reviewAxisSecurity;
    case ReviewAxis.testGap:
      return l10n.reviewAxisTestGap;
    case ReviewAxis.performance:
      return l10n.reviewAxisPerformance;
    case ReviewAxis.visual:
      return l10n.reviewAxisVisual;
    case ReviewAxis.apiContract:
      return l10n.reviewAxisApiContract;
  }
}

String _verdictLabel(AppLocalizations l10n, ReviewAxisVerdict v) {
  switch (v) {
    case ReviewAxisVerdict.pass:
      return l10n.reviewAxisPass;
    case ReviewAxisVerdict.warn:
      return l10n.reviewAxisWarn;
    case ReviewAxisVerdict.fail:
      return l10n.reviewAxisFail;
    case ReviewAxisVerdict.partial:
      return l10n.reviewAxisPartial;
    case ReviewAxisVerdict.unavailable:
      return l10n.reviewAxisUnavailable;
  }
}
