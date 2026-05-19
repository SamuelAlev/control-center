import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Left panel: the cohort navigator (PRD 18 §1). Cohorts are impact-ranked;
/// path-derived cohorts are labelled honestly and offer one-click indexing.
class CohortNav extends ConsumerWidget {
  /// Creates a [CohortNav].
  const CohortNav({super.key, required this.cohorts, this.onIndexRepo});

  /// The cohorts, in reading order.
  final List<ReviewCohort> cohorts;

  /// Called when the operator asks to index an unindexed repo.
  final VoidCallback? onIndexRepo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedCohortKeyProvider);
    if (cohorts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.reviewStudioNoCohorts,
            style: TextStyle(color: ds.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final pathDerived = cohorts.any((c) => c.isPathDerived);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            l10n.reviewStudioCohortsHeader,
            style: TextStyle(
              color: ds.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        for (final c in cohorts)
          _CohortTile(
            cohort: c,
            selected: c.cohortKey == selected,
            onTap: () => ref.read(selectedCohortKeyProvider.notifier).state =
                c.cohortKey,
          ),
        if (pathDerived && onIndexRepo != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: CcButton(
              variant: CcButtonVariant.line,
              onPressed: onIndexRepo,
              child: Text(l10n.reviewStudioIndexRepo),
            ),
          ),
      ],
    );
  }
}

class _CohortTile extends StatelessWidget {
  const _CohortTile({
    required this.cohort,
    required this.selected,
    required this.onTap,
  });

  final ReviewCohort cohort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: CcTappable(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(8),
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? ds.bgActive : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.boxes, size: 14, color: ds.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cohort.title,
                        style: TextStyle(
                          color: ds.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      l10n.reviewStudioFilesCount(cohort.filePaths.length),
                      style: TextStyle(color: ds.textTertiary, fontSize: 11),
                    ),
                    if (cohort.impactScore > 0) ...[
                      const SizedBox(width: 8),
                      Icon(AppIcons.zap, size: 11, color: ds.textTertiary),
                      const SizedBox(width: 2),
                      Text(
                        '${cohort.impactScore}',
                        style: TextStyle(color: ds.textTertiary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                if (cohort.isPathDerived)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.reviewStudioGroupedByPath,
                      style: TextStyle(
                        color: ds.textWarningPrimary,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Right panel: the context rail (PRD 18 §2). Shows the selected cohort's
/// summary + file list; follows the walkthrough selection.
class CohortContextRail extends ConsumerWidget {
  /// Creates a [CohortContextRail].
  const CohortContextRail({super.key, required this.cohorts});

  /// The cohorts.
  final List<ReviewCohort> cohorts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final selectedKey = ref.watch(selectedCohortKeyProvider);
    final cohort = cohorts
        .where((c) => c.cohortKey == selectedKey)
        .followedBy(cohorts)
        .firstOrNull;
    if (cohort == null) {
      return Center(
        child: Text(
          l10n.reviewStudioSelectCohort,
          style: TextStyle(color: ds.textTertiary, fontSize: 12),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          cohort.title,
          style: TextStyle(
            color: ds.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (cohort.summaryMarkdown.isNotEmpty)
          StyledMarkdownBody(data: cohort.summaryMarkdown, compact: true)
        else
          Text(
            l10n.reviewStudioSummaryEmpty,
            style: TextStyle(
              color: ds.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.reviewStudioFilesInCohort,
          style: TextStyle(
            color: ds.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final f in cohort.filePaths)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(AppIcons.fileText, size: 12, color: ds.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f,
                    style: TextStyle(color: ds.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Center pane: the guided walkthrough (PRD 18 §2/§3). Renders the cohorts in
/// reading order with their summaries and graph-verified diagrams; a scroll
/// listener keeps the context rail's selection in sync ("summary follows
/// scroll").
class ReviewWalkthrough extends ConsumerStatefulWidget {
  /// Creates a [ReviewWalkthrough].
  const ReviewWalkthrough({super.key, required this.cohorts});

  /// The cohorts, in reading order.
  final List<ReviewCohort> cohorts;

  @override
  ConsumerState<ReviewWalkthrough> createState() => _ReviewWalkthroughState();
}

class _ReviewWalkthroughState extends ConsumerState<ReviewWalkthrough> {
  final _controller = ScrollController();
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncSelection);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSelection);
    _controller.dispose();
    super.dispose();
  }

  void _syncSelection() {
    // Pick the cohort whose section top is nearest the viewport top — the
    // "follows scroll" behaviour of the range-anchored context rail.
    String? nearest;
    var best = double.infinity;
    for (final entry in _keys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) {
        continue;
      }
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      final dist = (top - 120).abs();
      if (top < 240 && dist < best) {
        best = dist;
        nearest = entry.key;
      }
    }
    if (nearest != null && ref.read(selectedCohortKeyProvider) != nearest) {
      ref.read(selectedCohortKeyProvider.notifier).state = nearest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (widget.cohorts.isEmpty) {
      return Center(
        child: Text(
          l10n.reviewStudioNoCohorts,
          style: TextStyle(color: ds.textTertiary, fontSize: 13),
        ),
      );
    }
    return ListView(
      controller: _controller,
      padding: const EdgeInsets.all(16),
      children: [
        for (final c in widget.cohorts)
          _CohortSection(
            key: _keys.putIfAbsent(c.cohortKey, GlobalKey.new),
            cohort: c,
          ),
      ],
    );
  }
}

class _CohortSection extends StatelessWidget {
  const _CohortSection({super.key, required this.cohort});

  final ReviewCohort cohort;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ds.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${cohort.orderIndex + 1}',
                  style: TextStyle(
                    color: ds.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cohort.title,
                  style: TextStyle(
                    color: ds.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (cohort.summaryMarkdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            StyledMarkdownBody(data: cohort.summaryMarkdown),
          ],
          for (final d in cohort.diagrams) ...[
            const SizedBox(height: 12),
            reviewDiagramWidget(d),
          ],
        ],
      ),
    );
  }
}

/// Adapts a domain [ReviewDiagram] to its native cc_ui renderer (PRD 18 §3).
Widget reviewDiagramWidget(ReviewDiagram diagram) {
  switch (diagram) {
    case SequenceDiagram():
      return CcSequenceDiagram(
        participants: diagram.participants,
        messages: [
          for (final m in diagram.messages)
            CcSequenceMessage(
              from: m.from,
              to: m.to,
              label: m.label,
              verified: m.corroborated,
            ),
        ],
      );
    case StateMachineDiagram():
      return CcStateMachineDiagram(
        states: diagram.states,
        initialState: diagram.initialState,
        transitions: [
          for (final t in diagram.transitions)
            CcStateTransition(
              from: t.from,
              to: t.to,
              label: t.label,
              verified: t.corroborated,
            ),
        ],
      );
    case EntityRelationDiagram():
      return CcEntityRelationDiagram(
        entities: [
          for (final e in diagram.entities)
            CcErEntity(
              name: e.name,
              fields: [
                for (final f in e.fields)
                  CcErField(name: f.name, type: f.type, isKey: f.isKey),
              ],
            ),
        ],
        relations: [
          for (final r in diagram.relations)
            CcErRelation(from: r.from, to: r.to, label: r.label),
        ],
      );
  }
}
