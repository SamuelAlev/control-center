import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Live indicator of the [DiffWorkerPool] state — one coloured dot per
/// long-lived worker plus a small badge showing the number of files still in
/// flight. Hovering reveals a tooltip with the full per-worker breakdown
/// and the LRU cache size.
///
/// Colour semantics per dot:
/// - green  — worker idle (no jobs)
/// - amber  — light load (1 job)
/// - orange — medium load (2–3 jobs)
/// - red    — heavy load (4+ jobs)
class DiffWorkerPoolIndicator extends StatelessWidget {
  /// Creates a [DiffWorkerPoolIndicator].
  const DiffWorkerPoolIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final pool = DiffWorkerPool.instance;
    return AnimatedBuilder(
      animation: pool,
      builder: (context, _) {
        final backlogs = pool.workerBacklogs;
        final active = pool.activeJobCount;
        final cache = pool.cacheSize;
        final workerCount = pool.workerCount == 0
            ? DiffWorkerPool.kWorkerCount
            : pool.workerCount;
        return FTooltip(
          // Open downward — the indicator now sits in the toolbar
          // crowded against the row above (tabs / PR header), so the
          // default upward tip would either get clipped or cover the
          // toolbar contents the user is hovering past.
          tipAnchor: Alignment.topCenter,
          childAnchor: Alignment.bottomCenter,
          tipBuilder: (_, _) => _Tooltip(
            backlogs: backlogs,
            workerCount: workerCount,
            active: active,
            cache: cache,
          ),
          child: _Pill(
            backlogs: backlogs,
            workerCount: workerCount,
            active: active,
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.backlogs,
    required this.workerCount,
    required this.active,
  });

  final List<int> backlogs;
  final int workerCount;
  final int active;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spawned = backlogs.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < workerCount; i++) ...[
            _WorkerDot(backlog: spawned ? backlogs[i] : 0, spawned: spawned),
            if (i != workerCount - 1) const SizedBox(width: 4),
          ],
          if (active > 0) ...[
            const SizedBox(width: 6),
            Text(
              '$active',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkerDot extends StatelessWidget {
  const _WorkerDot({required this.backlog, required this.spawned});

  final int backlog;
  final bool spawned;

  static Color _colorFor(int backlog, bool spawned) {
    if (!spawned) {
      return const Color(0xFF8B949E); // muted grey — pool not yet spawned
    }
    if (backlog <= 0) {
      return const Color(0xFF2DA44E); // green: idle
    }
    if (backlog == 1) {
      return const Color(0xFFFFBE2E); // amber: light
    }
    if (backlog <= 3) {
      return const Color(0xFFE36209); // orange: medium
    }
    return const Color(0xFFCF222E); // red: heavy
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(backlog, spawned);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: backlog > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.backlogs,
    required this.workerCount,
    required this.active,
    required this.cache,
  });

  final List<int> backlogs;
  final int workerCount;
  final int active;
  final int cache;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = <Widget>[
      _TooltipLine(
        label: l10n.diffWorkerPool,
        value: backlogs.isEmpty ? l10n.notYetSpawned : l10n.workersCount(workerCount),
        bold: true,
      ),
      const SizedBox(height: 4),
      for (var i = 0; i < workerCount; i++)
        _TooltipLine(
          label: l10n.workerLabel(i + 1),
          value: backlogs.isEmpty
              ? l10n.idleStatus
              : _describeBacklog(l10n, backlogs[i]),
        ),
      const SizedBox(height: 4),
      _TooltipLine(label: l10n.inFlightLabel, value: l10n.filesCount(active)),
      _TooltipLine(label: l10n.cached, value: l10n.filesCount(cache)),
    ];
    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  static String _describeBacklog(AppLocalizations l10n, int backlog) {
    if (backlog <= 0) {
      return l10n.idleStatus;
    }
    return l10n.jobCount(backlog);
  }
}

class _TooltipLine extends StatelessWidget {
  const _TooltipLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: base?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: base?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
