import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_hub_insight_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a failing CI job said, correlated back to the lines this PR changed —
/// the "the build is red, and here is the changed file it points at" view.
///
/// Every state is rendered distinctly on purpose. "This forge cannot report
/// per-job detail", "nothing is failing" and "the job failed but its logs are
/// not published yet" are three different claims, and collapsing any of them
/// into an empty list would read as "no failures".
class ReviewHubCiPanel extends ConsumerWidget {
  /// Creates a [ReviewHubCiPanel].
  const ReviewHubCiPanel({super.key, required this.target, this.cohortKey});

  /// The PR target.
  final ReviewStudioTarget target;

  /// When non-null, only correlations pointing into this area are listed. The
  /// job's own failing tests and error lines are always shown: they are
  /// properties of the job, not of an area.
  final String? cohortKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(reviewHubCiSignalsProvider(target));
    return async.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.alertTriangle, size: 14, color: ds.danger),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$e',
                style: TextStyle(color: ds.danger, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      data: (data) => _body(context, ds, l10n, data),
    );
  }

  Widget _body(
    BuildContext context,
    DesignSystemTokens ds,
    AppLocalizations l10n,
    Map<String, dynamic> data,
  ) {
    if (data['available'] != true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.reviewHubCiUnavailable,
            textAlign: TextAlign.center,
            style: TextStyle(color: ds.textTertiary, fontSize: 13),
          ),
        ),
      );
    }

    final failingCount = (data['failing_count'] as num?)?.toInt() ?? 0;
    if (failingCount == 0) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.checkCircle, size: 14, color: ds.success),
            const SizedBox(width: 8),
            Text(
              l10n.reviewHubCiAllPassing,
              style: TextStyle(color: ds.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final jobs = _maps(data['jobs']);
    final note = (data['note'] as String?)?.trim() ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < jobs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 12),
            const CcDivider(),
            const SizedBox(height: 12),
          ],
          _job(ds, l10n, jobs[i]),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(note, style: TextStyle(color: ds.textTertiary, fontSize: 11)),
        ],
      ],
    );
  }

  Widget _job(
    DesignSystemTokens ds,
    AppLocalizations l10n,
    Map<String, dynamic> job,
  ) {
    final conclusion = (job['conclusion'] as String?)?.trim() ?? '';
    final logsPublished = job['logs_published'] == true;
    final failingTests = _strings(job['failing_tests']);
    final errorLines = _strings(job['error_lines']);
    final correlations = _maps(
      job['correlations'],
    ).where(_matchesCohort).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.zap, size: 12, color: ds.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                job['name'] as String? ?? '',
                style: TextStyle(
                  color: ds.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conclusion.isNotEmpty) ...[
              const SizedBox(width: 8),
              _conclusionChip(ds, conclusion),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // A failing job with unreadable logs has nothing to list, and an empty
        // list would read as "nothing failed" — so say why it is empty.
        if (!logsPublished)
          Text(
            l10n.reviewHubCiLogsNotPublished,
            style: TextStyle(color: ds.textTertiary, fontSize: 12),
          )
        else ...[
          if (failingTests.isNotEmpty) ...[
            Text(
              l10n.reviewHubCiFailingTests,
              style: TextStyle(
                color: ds.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final test in failingTests)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.xCircle, size: 11, color: ds.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test,
                        style: CcFonts.code(
                          textStyle: TextStyle(
                            color: ds.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (errorLines.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final line in errorLines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  line,
                  style: CcFonts.code(
                    textStyle: TextStyle(color: ds.textSecondary, fontSize: 11),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          if (correlations.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final correlation in correlations)
              _correlation(ds, l10n, correlation),
          ],
        ],
      ],
    );
  }

  Widget _correlation(
    DesignSystemTokens ds,
    AppLocalizations l10n,
    Map<String, dynamic> correlation,
  ) {
    final filePath = correlation['file_path'] as String? ?? '';
    final line = (correlation['line'] as num?)?.toInt();
    final evidence = (correlation['evidence'] as String?)?.trim() ?? '';
    final label = line == null ? filePath : '$filePath:$line';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.crosshair, size: 11, color: ds.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reviewHubCiTouchesFile(label),
                  style: TextStyle(color: ds.textPrimary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                if (evidence.isNotEmpty)
                  Text(
                    evidence,
                    style: CcFonts.code(
                      textStyle: TextStyle(
                        color: ds.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The conclusion is spelled out as text beside its icon, never carried by
  /// the color alone.
  Widget _conclusionChip(DesignSystemTokens ds, String conclusion) {
    final (color, background, icon) = switch (conclusion) {
      'failure' => (ds.danger, ds.dangerSoft, AppIcons.xCircle),
      'timed_out' => (ds.warn, ds.warnSoft, AppIcons.clock),
      _ => (ds.textSecondary, ds.bgSecondary, AppIcons.alertTriangle),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            conclusion,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesCohort(Map<String, dynamic> correlation) =>
      cohortKey == null || correlation['cohort_key'] == cohortKey;

  /// Reads a wire list of objects, dropping anything that is not one. The blob
  /// crosses an RPC boundary, so a malformed row must be skipped rather than
  /// take the whole panel down.
  static List<Map<String, dynamic>> _maps(Object? raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();

  static List<String> _strings(Object? raw) =>
      ((raw as List?) ?? const []).whereType<String>().toList();
}
