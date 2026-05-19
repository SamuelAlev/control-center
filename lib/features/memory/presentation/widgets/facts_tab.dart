import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/fact_edit_dialog.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_error_view.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How the fact list is ordered.
enum _FactSort { recent, confidence }

/// Searchable, sortable list of memory facts for the active workspace.
class FactsTab extends ConsumerStatefulWidget {
  /// Creates a [FactsTab].
  const FactsTab({super.key, required this.workspaceId});

  /// Workspace whose facts are shown.
  final String workspaceId;

  @override
  ConsumerState<FactsTab> createState() => _FactsTabState();
}

class _FactsTabState extends ConsumerState<FactsTab> {
  final _searchController = TextEditingController();
  bool _showSuperseded = false;
  _FactSort _sort = _FactSort.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final factsAsync = ref.watch(memoryFactsProvider(widget.workspaceId));

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: factsAsync.when(
            data: (facts) => _buildFactList(context, facts),
            loading: () => const Center(child: CcSpinner()),
            error: (e, _) => MemoryErrorView(
              error: e,
              onRetry: () => ref.invalidate(
                memoryFactsProvider(widget.workspaceId),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          CcTextField(
            controller: _searchController,
            hintText: l10n.searchFactsHint,
            prefix: Icon(
              LucideIcons.search,
              size: 16,
              color: (tokens ?? DesignSystemTokens.light()).fgQuaternary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _SortToggle(
                value: _sort,
                onChanged: (s) => setState(() => _sort = s),
              ),
              const Spacer(),
              CcSwitch(
                value: _showSuperseded,
                onChanged: (v) => setState(() => _showSuperseded = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.showSuperseded,
                style: CcTypography.body.copyWith(
                  color: (tokens ?? DesignSystemTokens.light()).textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactList(BuildContext context, List<MemoryFact> facts) {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = _showSuperseded
        ? facts
        : facts.where((f) => !f.isSuperseded).toList();

    if (query.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.topic.toLowerCase().contains(query) ||
            f.content.toLowerCase().contains(query) ||
            f.domain.toLowerCase().contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      switch (_sort) {
        case _FactSort.recent:
          return b.updatedAt.compareTo(a.updatedAt);
        case _FactSort.confidence:
          return b.confidence.compareTo(a.confidence);
      }
    });

    final l10n = AppLocalizations.of(context);

    if (filtered.isEmpty) {
      if (query.isNotEmpty) {
        return EmptyState(
          icon: LucideIcons.searchX,
          message: l10n.noFactsMatch,
          query: _searchController.text,
        );
      }
      return EmptyState(
        icon: LucideIcons.lightbulb,
        message: l10n.noFacts,
        description: l10n.factsHint,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final fact = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _FactCard(
            fact: fact,
            onEdit: () => _editFact(context, fact),
            onDelete: () => _deleteFact(context, fact),
          ),
        );
      },
    );
  }

  Future<void> _editFact(BuildContext context, MemoryFact fact) async {
    final edited = await showDialog<MemoryFact>(
      context: context,
      builder: (_) => FactEditDialog(fact: fact),
    );
    if (edited == null || !mounted) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.upsert(edited);
  }

  Future<void> _deleteFact(BuildContext context, MemoryFact fact) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deleteFact,
        content: Text(l10n.deleteTopicConfirm(fact.topic)),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final repo = ref.read(memoryFactRepositoryProvider);
    await repo.delete(fact.workspaceId, fact.id);
  }
}

/// Two-state segmented control for ordering the fact list.
class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.value, required this.onChanged});

  final _FactSort value;
  final ValueChanged<_FactSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SortButton(
          icon: LucideIcons.clock,
          label: l10n.sortRecent,
          selected: value == _FactSort.recent,
          onPressed: () => onChanged(_FactSort.recent),
        ),
        const SizedBox(width: AppSpacing.xs),
        _SortButton(
          icon: LucideIcons.gauge,
          label: l10n.sortConfidence,
          selected: value == _FactSort.confidence,
          onPressed: () => onChanged(_FactSort.confidence),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CcButton(
      variant: selected ? CcButtonVariant.secondary : CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _FactCard extends StatefulWidget {
  const _FactCard({
    required this.fact,
    required this.onEdit,
    required this.onDelete,
  });

  final MemoryFact fact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<_FactCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fact = widget.fact;

    return Opacity(
      opacity: fact.isSuperseded ? 0.55 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _hovered ? tokens.bgPrimaryHover : tokens.bgPrimary,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: MemoryMetaChip(
                      label: fact.topic,
                      icon: LucideIcons.tag,
                    ),
                  ),
                  if (fact.isSuperseded) ...[
                    const SizedBox(width: AppSpacing.sm),
                    CcTooltip(
                      message: l10n.supersededTooltip,
                      child: MemoryMetaChip(
                        label: l10n.superseded,
                        tone: MemoryChipTone.error,
                      ),
                    ),
                  ],
                  const Spacer(),
                  ConfidenceMeter(confidence: fact.confidence),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                fact.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CcIconButton(
                    icon: LucideIcons.pencil,
                    onPressed: widget.onEdit,
                    size: CcButtonSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcIconButton(
                    icon: LucideIcons.trash2,
                    onPressed: widget.onDelete,
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.destructive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

