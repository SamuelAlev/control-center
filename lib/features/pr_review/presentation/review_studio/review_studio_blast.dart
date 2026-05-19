import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Center pane: the beyond-the-diff blast-radius map (PRD 18 §6). The operator
/// picks a changed file; the server returns the reverse-dependency subgraph
/// from the code graph, grouped by hop distance (direct callers → transitive).
class BlastRadiusPanel extends ConsumerWidget {
  /// Creates a [BlastRadiusPanel].
  const BlastRadiusPanel({
    super.key,
    required this.target,
    required this.changedFiles,
  });

  /// The PR target.
  final ReviewStudioTarget target;

  /// The PR's changed files (the picker source).
  final List<String> changedFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedBlastFileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in changedFiles)
                CcChip(
                  label: f.split('/').last,
                  selected: f == selected,
                  onTap: () =>
                      ref.read(selectedBlastFileProvider.notifier).state = f,
                ),
            ],
          ),
        ),
        const CcDivider(),
        Expanded(
          child: selected == null
              ? Center(
                  child: Text(
                    l10n.reviewStudioSelectFileForBlast,
                    style: TextStyle(color: ds.textTertiary, fontSize: 13),
                  ),
                )
              : _BlastResult(target: target, file: selected),
        ),
      ],
    );
  }
}

class _BlastResult extends ConsumerWidget {
  const _BlastResult({required this.target, required this.file});

  final ReviewStudioTarget target;
  final String file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(
      reviewBlastRadiusProvider((target: target, file: file)),
    );
    return async.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(
        child: Text('$e', style: TextStyle(color: ds.danger, fontSize: 12)),
      ),
      data: (data) {
        if (data['indexed'] != true) {
          return Center(
            child: Text(
              l10n.reviewStudioNotIndexed,
              style: TextStyle(color: ds.textTertiary, fontSize: 13),
            ),
          );
        }
        final nodes = ((data['nodes'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
        // depth 0 = the changed symbol; group the rest by hop distance.
        final byDepth = <int, List<Map<String, dynamic>>>{};
        for (final n in nodes) {
          final d = (n['depth'] as num?)?.toInt() ?? 0;
          byDepth.putIfAbsent(d, () => []).add(n);
        }
        final root = data['root'] as Map?;
        final depths = byDepth.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (root != null)
              Row(
                children: [
                  Icon(AppIcons.code, size: 14, color: ds.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      root['qualifiedName'] as String? ?? '',
                      style: TextStyle(
                        color: ds.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              l10n.reviewStudioAffectedCount(nodes.length - 1),
              style: TextStyle(color: ds.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final d in depths.where((d) => d > 0)) ...[
              Text(
                d == 1
                    ? l10n.reviewStudioDirectCallers
                    : l10n.reviewStudioTransitiveAt(d),
                style: TextStyle(
                  color: ds.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final n in byDepth[d]!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: ds.accent.withValues(alpha: 1 - d * 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          n['qualifiedName'] as String? ??
                              n['name'] as String? ??
                              '',
                          style: TextStyle(color: ds.textPrimary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        (n['filePath'] as String? ?? '').split('/').last,
                        style: TextStyle(color: ds.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}
