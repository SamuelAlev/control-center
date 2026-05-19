import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// LOC-change thresholds from Cisco/SmartBear research.
const _warnLoc = 200;
const _blockLoc = 400;

/// Minutes-per-100-LOC estimate used for review time hints.
const _minutesPer100Loc = 15;

/// A badge showing PR complexity (LOC + file count) with a time estimate.
///
/// Turns amber at ≥200 LOC, red at ≥400 LOC, and surfaces a "consider
/// splitting" recommendation for large PRs (research shows review quality
/// collapses past ~400 LOC).
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
    final level = _level;
    final color = switch (level) {
      _ComplexityLevel.low => Colors.green,
      _ComplexityLevel.medium => Colors.orange,
      _ComplexityLevel.high => Colors.red,
    };
    final estimatedMinutes = ((totalLoc / 100) * _minutesPer100Loc)
        .round()
        .clamp(5, 240);

    return CcTooltip(
      message: _tooltipLabel(estimatedMinutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.fileText, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              '$_locLabel  ·  $fileCount ${fileCount == 1 ? 'file' : 'files'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tooltipLabel(int estimatedMinutes) {
    return totalLoc >= _blockLoc
        ? 'Large PR — consider splitting before review'
        : totalLoc >= _warnLoc
        ? 'Medium PR — block ~$estimatedMinutes min to review'
        : 'Small PR — ~$estimatedMinutes min to review';
  }

  String get _locLabel {
    if (totalLoc >= 1000) {
      return '${(totalLoc / 1000).toStringAsFixed(1)}k LOC';
    }
    return '$totalLoc LOC';
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
