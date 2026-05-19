import 'package:cc_domain/features/pr_review/domain/usecases/compute_area_risk_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// An area's deterministic risk score, with the factors that produced it one
/// tap away.
///
/// The breakdown is the whole point. A bare "risk: 62" is a number a reviewer
/// has no reason to believe and no way to argue with; "62, because it touches
/// `payment/` and breaks two API contracts" is a claim they can check. So the
/// chip never appears without a way to see its derivation.
class ReviewHubRiskChip extends StatelessWidget {
  /// Creates a [ReviewHubRiskChip].
  const ReviewHubRiskChip({super.key, required this.risk, this.compact = true});

  /// The scored risk.
  final AreaRisk risk;

  /// Whether to render the tighter variant used in the area nav.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, background, icon) = _appearance(context);

    return CcTooltip(
      message: _breakdown(l10n),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The band always travels with an icon and a word: the score alone
            // in a color would be status-by-color, which fails the contrast
            // floor and every colorblind reader.
            Icon(icon, size: compact ? 10 : 12, color: color),
            const SizedBox(width: 4),
            Text(
              '${_levelLabel(l10n)} · ${risk.score}',
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _appearance(BuildContext context) {
    final ds = context.designSystem!;
    switch (risk.level) {
      case AreaRiskLevel.high:
        return (ds.danger, ds.dangerSoft, AppIcons.alertTriangle);
      case AreaRiskLevel.moderate:
        return (ds.warn, ds.warnSoft, AppIcons.alertCircle);
      case AreaRiskLevel.low:
        return (ds.textSecondary, ds.bgSecondary, AppIcons.circleCheck);
    }
  }

  String _levelLabel(AppLocalizations l10n) {
    switch (risk.level) {
      case AreaRiskLevel.high:
        return l10n.reviewHubRiskHigh;
      case AreaRiskLevel.moderate:
        return l10n.reviewHubRiskModerate;
      case AreaRiskLevel.low:
        return l10n.reviewHubRiskLow;
    }
  }

  /// The factor breakdown, largest contribution first.
  String _breakdown(AppLocalizations l10n) {
    final buffer = StringBuffer(l10n.reviewHubRiskFactors);
    for (final factor in risk.factors) {
      buffer
        ..write('\n• ')
        ..write(riskFactorLabel(l10n, factor.id))
        ..write(': ')
        ..write(_valueOf(factor))
        ..write(' (+')
        ..write(factor.contribution)
        ..write(')');
    }
    return buffer.toString();
  }

  String _valueOf(AreaRiskFactor factor) {
    // The known-zero-coverage factor's "value" is the absence itself, so a
    // literal 0 next to it would read as "no contribution".
    if (factor.id == AreaRiskFactorIds.noCoveringTests) {
      return '0';
    }
    final value = factor.value;
    return value is int ? '$value' : value.toStringAsFixed(1);
  }
}

/// The localized label for a risk factor id.
///
/// Lives here rather than in the domain because the factor ids are the
/// domain's stable contract and the words are the UI's.
String riskFactorLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case AreaRiskFactorIds.linesChanged:
      return l10n.reviewHubFactorLinesChanged;
    case AreaRiskFactorIds.fileCount:
      return l10n.reviewHubFactorFileCount;
    case AreaRiskFactorIds.impact:
      return l10n.reviewHubFactorImpact;
    case AreaRiskFactorIds.blockingFindings:
      return l10n.reviewHubFactorBlockingFindings;
    case AreaRiskFactorIds.criticalPath:
      return l10n.reviewHubFactorCriticalPath;
    case AreaRiskFactorIds.contractBreaking:
      return l10n.reviewHubFactorContractBreaking;
    case AreaRiskFactorIds.visualChange:
      return l10n.reviewHubFactorVisualChange;
    case AreaRiskFactorIds.dependencyChurn:
      return l10n.reviewHubFactorDependencyChurn;
    case AreaRiskFactorIds.noCoveringTests:
      return l10n.reviewHubFactorNoCoveringTests;
    default:
      // A factor id this build does not know about is still worth showing —
      // better a raw id than a silently dropped contribution.
      return id;
  }
}

/// The expanded factor breakdown, for surfaces with room for it (the deep-dive
/// header rather than the nav).
class ReviewHubRiskFactors extends StatelessWidget {
  /// Creates a [ReviewHubRiskFactors].
  const ReviewHubRiskFactors({super.key, required this.risk});

  /// The scored risk.
  final AreaRisk risk;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (risk.isEmpty) {
      return const SizedBox.shrink();
    }
    final max = risk.factors.first.contribution.clamp(1, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reviewHubRiskFactors,
          style: TextStyle(
            color: ds.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final factor in risk.factors)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    riskFactorLabel(l10n, factor.id),
                    style: TextStyle(color: ds.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (factor.contribution / max).clamp(
                          0.02,
                          1.0,
                        ),
                        child: Container(height: 6, color: ds.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${factor.contribution}',
                  style: TextStyle(color: ds.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
