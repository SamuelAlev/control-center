import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// LOC-change thresholds from Cisco/SmartBear research.
const _warnLoc = 200;
const _blockLoc = 400;

/// Minutes-per-100-LOC estimate used for review time hints.
const _minutesPer100Loc = 15;

/// A plain tag showing PR size in changed lines, with a review-time estimate
/// in its tooltip.
///
/// Turns amber at ≥200 LOC, red at ≥400 LOC, and surfaces a "consider
/// splitting" recommendation for large PRs (research shows review quality
/// collapses past ~400 LOC). No leading icon: the tint carries the severity
/// and the label carries the number, so it reads as a tag beside its siblings.
/// [fileCount] only feeds the tooltip — the file count has its own home in the
/// "Files changed" section, so repeating it in the tag would just crowd the row.
class PrComplexityBadge extends StatelessWidget {
  /// Creates a [PrComplexityBadge] from a list of changed files.
  factory PrComplexityBadge.fromFiles(List<PrFile> files, {Key? key}) {
    final loc = files.fold(0, (s, f) => s + f.additions + f.deletions);
    return PrComplexityBadge(key: key, totalLoc: loc, fileCount: files.length);
  }

  /// Creates a [PrComplexityBadge] from raw counts.
  const PrComplexityBadge({
    super.key,
    required this.totalLoc,
    required this.fileCount,
  });

  /// Total lines added + removed.
  final int totalLoc;

  /// Number of files changed.
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    final variant = switch (_level) {
      _ComplexityLevel.low => CcBadgeVariant.success,
      _ComplexityLevel.medium => CcBadgeVariant.warning,
      _ComplexityLevel.high => CcBadgeVariant.danger,
    };
    final estimatedMinutes = ((totalLoc / 100) * _minutesPer100Loc)
        .round()
        .clamp(5, 240);

    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      message: _tooltipLabel(l10n, estimatedMinutes),
      child: CcBadge(label: l10n.prComplexityLoc(_locValue), variant: variant),
    );
  }

  /// The review-time hint. Carries the file count, which the tag itself omits.
  String _tooltipLabel(AppLocalizations l10n, int estimatedMinutes) {
    // Reuses the existing `diffFilesCount` plural rather than duplicating
    // per-language pluralization across three new keys.
    final files = l10n.diffFilesCount(fileCount);
    if (totalLoc >= _blockLoc) {
      return l10n.prComplexityTooltipLarge(files);
    }
    if (totalLoc >= _warnLoc) {
      return l10n.prComplexityTooltipMedium(files, estimatedMinutes);
    }
    return l10n.prComplexityTooltipSmall(files, estimatedMinutes);
  }

  /// The changed-line count, abbreviated past 1k. The "LOC" unit comes from
  /// the localized label.
  String get _locValue {
    if (totalLoc >= 1000) {
      return '${(totalLoc / 1000).toStringAsFixed(1)}k';
    }
    return '$totalLoc';
  }

  _ComplexityLevel get _level {
    if (totalLoc >= _blockLoc) {
      return _ComplexityLevel.high;
    }
    if (totalLoc >= _warnLoc) {
      return _ComplexityLevel.medium;
    }
    return _ComplexityLevel.low;
  }
}

enum _ComplexityLevel { low, medium, high }
