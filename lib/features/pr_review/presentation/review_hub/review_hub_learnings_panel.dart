import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_insight_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The glob stored for a guideline the operator left unscoped.
///
/// The reviewer reads a guideline's *topic* as its path glob, and `**` matches
/// every changed file — so an unscoped rule always applies. It is stored rather
/// than an empty string because [MemoryFact] asserts a non-empty topic: writing
/// `''` would trip that assert in debug the moment someone adds a
/// repository-wide rule.
const String _repoWideGlob = '**';

/// Whether [topic] means "applies to the whole repository" rather than naming a
/// subtree. Both spellings are accepted on read: facts harvested before this
/// panel existed may carry an empty topic.
bool _isRepoWide(String topic) => topic.isEmpty || topic == _repoWideGlob;

/// What the AI reviewer has learned for this workspace, and the controls to
/// curate it.
///
/// Two kinds of learning share one surface because they are the same lever from
/// the operator's seat — "review this differently next time":
///
/// * **Review guidelines** ([SystemMemoryDomains.reviewGuidelines]) are written
///   deliberately here. The fact's topic doubles as the path glob it is scoped
///   to and its content is the instruction.
/// * **Dismissed patterns** ([SystemMemoryDomains.reviewSuppressions]) are
///   harvested automatically when a human dismisses a finding, so they are
///   shown read-only — the way to change one is to dismiss (or stop dismissing)
///   findings, not to edit the harvested text.
///
/// Only active facts are listed: a superseded or expired fact is not in the
/// brief the reviewer receives, so showing it here would misreport what the
/// reviewer actually knows.
class ReviewHubLearningsPanel extends ConsumerWidget {
  /// Creates a [ReviewHubLearningsPanel].
  const ReviewHubLearningsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }

    final factsAsync = ref.watch(memoryFactsProvider(workspaceId));
    // Keep the last good list while a refresh is in flight: the rows are what
    // the panel is for, and blanking them on every stream re-emit would make
    // the delete affordance jump under the pointer.
    final facts = factsAsync.asData?.value ?? const <MemoryFact>[];
    final guidelines = _active(facts, SystemMemoryDomains.reviewGuidelines);
    final suppressions = _active(
      facts,
      SystemMemoryDomains.reviewSuppressions,
    ).take(_maxSuppressionRows).toList();

    final stats = ref.watch(reviewHubStatsProvider).asData?.value;
    final made = _statOf(stats, 'findings_total');
    final addressed = _statOf(stats, 'addressed');

    final nothingLearned = guidelines.isEmpty && suppressions.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // A reviewer nobody acts on is worth knowing about before curating what
        // it says, so the ratio leads. It is hidden outright at zero findings:
        // "0 made · 0 addressed" reads as a broken counter rather than as a
        // reviewer that has not run yet.
        if (made > 0) ...[
          Text(
            l10n.reviewHubStatsSummary(made, addressed),
            style: TextStyle(color: ds.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeader(
          label: l10n.reviewHubGuidelines,
          icon: AppIcons.listChecks,
        ),
        const SizedBox(height: 6),
        if (factsAsync.hasError && !factsAsync.hasValue)
          _StatusLine(
            icon: AppIcons.alertTriangle,
            label: l10n.failedToLoad,
            color: ds.textTertiary,
          )
        else if (factsAsync.isLoading && !factsAsync.hasValue)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: CcSpinner(size: 14),
          )
        else if (nothingLearned)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.reviewHubNoLearnings,
              style: TextStyle(color: ds.textTertiary, fontSize: 12),
            ),
          ),
        for (final fact in guidelines)
          _LearningRow(
            text: fact.content,
            glob: _isRepoWide(fact.topic) ? null : fact.topic,
            onDelete: () => _deleteFact(ref, workspaceId, fact.id),
          ),
        const SizedBox(height: 10),
        _GuidelineComposer(workspaceId: workspaceId),
        if (suppressions.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionHeader(
            label: l10n.reviewHubSuppressions,
            icon: AppIcons.eyeOff,
          ),
          const SizedBox(height: 6),
          for (final fact in suppressions)
            _LearningRow(
              text: fact.content,
              glob: null,
              subdued: true,
              onDelete: () => _deleteFact(ref, workspaceId, fact.id),
            ),
        ],
      ],
    );
  }

  /// The active (not superseded, not expired) facts of one memory [domain].
  static List<MemoryFact> _active(List<MemoryFact> facts, String domain) {
    final now = DateTime.now();
    return [
      for (final fact in facts)
        if (fact.domain == domain && !fact.isSuperseded && !fact.isExpired(now))
          fact,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// Dismissed patterns accumulate one row per dismissal, so the list is capped —
/// past a screenful it stops being something a person reads and starts being
/// something they scroll past.
const int _maxSuppressionRows = 25;

/// Reads an int counter out of the loosely-typed stats map. The server may add
/// or rename a counter, and a missing one means "nothing counted", never a
/// crash.
int _statOf(Map<String, dynamic>? stats, String key) =>
    (stats?[key] as num?)?.toInt() ?? 0;

/// Deletes [factId] and refreshes the list.
///
/// The invalidate is belt-and-braces: the facts provider is a live server
/// subscription that pushes a fresh snapshot on every change, but a cached
/// replay would otherwise leave the deleted row on screen until the next push.
Future<void> _deleteFact(
  WidgetRef ref,
  String workspaceId,
  String factId,
) async {
  await ref.read(memoryFactRepositoryProvider).delete(workspaceId, factId);
  if (!ref.context.mounted) {
    return;
  }
  ref.invalidate(memoryFactsProvider(workspaceId));
}

/// One learning: an optional path-glob chip, the text, and a delete affordance.
class _LearningRow extends StatelessWidget {
  const _LearningRow({
    required this.text,
    required this.glob,
    required this.onDelete,
    this.subdued = false,
  });

  /// The instruction (guideline) or the harvested pattern (suppression).
  final String text;

  /// The path glob this is scoped to, or null for repository-wide.
  final String? glob;

  /// Removes the underlying memory fact.
  final VoidCallback onDelete;

  /// Whether to render in the quieter treatment used for harvested rows.
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final scope = glob;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (scope != null) _GlobChip(glob: scope),
                Text(
                  text,
                  style: TextStyle(
                    color: subdued ? ds.textSecondary : ds.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CcTappable(
            onPressed: onDelete,
            borderRadius: BorderRadius.circular(6),
            semanticLabel: l10n.delete,
            builder: (context, states) => Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                AppIcons.trash2,
                size: 13,
                // The glyph, not the color, says "delete"; the danger tint on
                // hover is confirmation of what is about to happen.
                color: states.contains(WidgetState.hovered)
                    ? ds.danger
                    : ds.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The path glob a guideline is scoped to, rendered as a code-font pill.
class _GlobChip extends StatelessWidget {
  const _GlobChip({required this.glob});

  final String glob;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          glob,
          style: CcFonts.code(
            textStyle: TextStyle(color: ds.textSecondary, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

/// The reveal-then-fill composer for a standing review instruction.
///
/// Collapsed by default: writing a rule is the rarer act on this panel, and two
/// permanently-open fields would push the learnings themselves below the fold.
class _GuidelineComposer extends ConsumerStatefulWidget {
  const _GuidelineComposer({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_GuidelineComposer> createState() => _GuidelineComposerState();
}

class _GuidelineComposerState extends ConsumerState<_GuidelineComposer> {
  final TextEditingController _globController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  bool _open = false;
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _globController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final instruction = _textController.text.trim();
    // An empty instruction is not a rule; storing one would put a blank line in
    // every reviewer's brief.
    if (instruction.isEmpty || _saving) {
      return;
    }
    final glob = _globController.text.trim();
    final now = DateTime.now();
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(memoryFactRepositoryProvider)
          .upsert(
            MemoryFact(
              id: const Uuid().v4(),
              workspaceId: widget.workspaceId,
              domain: SystemMemoryDomains.reviewGuidelines,
              topic: glob.isEmpty ? _repoWideGlob : glob,
              content: instruction,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object {
      // Keep what was typed: the operator's text is the only copy, and a
      // cleared field after a failed write loses it silently.
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    _globController.clear();
    _textController.clear();
    setState(() {
      _saving = false;
      _open = false;
    });
    ref.invalidate(memoryFactsProvider(widget.workspaceId));
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (!_open) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CcButton(
          onPressed: () => setState(() => _open = true),
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.plus,
          child: Text(l10n.reviewHubAddGuideline),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTextField(
          controller: _globController,
          hintText: l10n.reviewHubGuidelineGlobHint,
          size: CcTextFieldSize.sm,
          enabled: !_saving,
        ),
        const SizedBox(height: 6),
        CcTextField(
          controller: _textController,
          hintText: l10n.reviewHubGuidelineTextHint,
          size: CcTextFieldSize.sm,
          enabled: !_saving,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        if (_failed) ...[
          const SizedBox(height: 6),
          _StatusLine(
            icon: AppIcons.alertTriangle,
            label: l10n.somethingWentWrong,
            color: ds.danger,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            CcButton(
              onPressed: _submit,
              size: CcButtonSize.sm,
              loading: _saving,
              child: Text(l10n.add),
            ),
            const SizedBox(width: 8),
            CcButton(
              onPressed: _saving ? null : () => setState(() => _open = false),
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ],
    );
  }
}

/// A section label: an icon plus an uppercase-weight caption.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return Row(
      children: [
        Icon(icon, size: 12, color: ds.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: ds.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A one-line status note — an icon carries the meaning so the color never has
/// to.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
