import 'package:cc_domain/features/pr_review/domain/services/impact_mermaid_builder.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/mermaid_block.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The merged impact subgraph for a cohort: the area's dominant (changed)
/// symbols and everything transitively affected by them, grouped by hop
/// distance — the "see the blast radius of this whole area" view.
///
/// Two renderings of one payload. The list answers "how many things depend on
/// this"; only the drawn graph answers "does the payment path reach this",
/// which is the question a reviewer actually has. The list stays one tap away
/// because a large graph is slower to read than a list of twelve names.
class ReviewHubImpactPanel extends ConsumerStatefulWidget {
  /// Creates a [ReviewHubImpactPanel].
  const ReviewHubImpactPanel({
    super.key,
    required this.target,
    required this.cohortKey,
  });

  /// The PR target.
  final ReviewStudioTarget target;

  /// The area whose impact to render.
  final String cohortKey;

  @override
  ConsumerState<ReviewHubImpactPanel> createState() =>
      _ReviewHubImpactPanelState();
}

class _ReviewHubImpactPanelState extends ConsumerState<ReviewHubImpactPanel> {
  bool _asGraph = true;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final target = widget.target;
    final cohortKey = widget.cohortKey;
    final async = ref.watch(
      reviewHubCohortImpactProvider((target: target, cohortKey: cohortKey)),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ViewToggle(
                    label: l10n.reviewHubImpactGraph,
                    icon: AppIcons.network,
                    active: _asGraph,
                    onTap: () => setState(() => _asGraph = true),
                  ),
                  const SizedBox(width: 4),
                  _ViewToggle(
                    label: l10n.reviewHubImpactList,
                    icon: AppIcons.list,
                    active: !_asGraph,
                    onTap: () => setState(() => _asGraph = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _asGraph ? _GraphBody(data: data) : _ListBody(data: data),
            ),
          ],
        );
      },
    );
  }
}

/// The subgraph drawn natively via the app's mermaid renderer.
class _GraphBody extends StatelessWidget {
  const _GraphBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final graph = CohortImpactGraph.fromWire(data);
    if (graph.isEmpty) {
      return Center(
        child: Text(
          l10n.reviewStudioAffectedCount(0),
          style: TextStyle(color: ds.textTertiary, fontSize: 13),
        ),
      );
    }
    final source = const ImpactMermaidBuilder().buildFlowchart(
      graph,
      labels: ImpactGraphLabels(
        changed: l10n.reviewHubImpactChanged,
        hop: l10n.reviewHubImpactHops,
        more: (file, hidden) => l10n.reviewHubImpactMore(hidden, file),
      ),
    );
    if (source.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [AppMermaidFigure(source: source)],
    );
  }
}

/// The original depth-grouped list.
class _ListBody extends StatelessWidget {
  const _ListBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final roots = ((data['roots'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
    final nodes = ((data['nodes'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
    final byDepth = <int, List<Map<String, dynamic>>>{};
    for (final n in nodes) {
      final d = (n['depth'] as num?)?.toInt() ?? 0;
      byDepth.putIfAbsent(d, () => []).add(n);
    }
    final depths = byDepth.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.reviewHubChangedSymbols,
          style: TextStyle(
            color: ds.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final root in roots)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(AppIcons.code, size: 12, color: ds.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    root['qualifiedName'] as String? ??
                        root['name'] as String? ??
                        '',
                    style: TextStyle(
                      color: ds.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  (root['filePath'] as String? ?? '').split('/').last,
                  style: TextStyle(color: ds.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          l10n.reviewStudioAffectedCount(nodes.length - roots.length),
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
  }
}

/// One half of the Graph/List switch.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(6),
      builder: (context, states) => DecoratedBox(
        decoration: BoxDecoration(
          color: active ? ds.accentSoft : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: active ? ds.accent : ds.textTertiary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? ds.accent : ds.textTertiary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
