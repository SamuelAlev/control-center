import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart'
    show NodeData, NodeType;
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that shows details for a selected knowledge graph node.
class KnowledgeGraphNodeSheet extends StatelessWidget {
  /// Creates a [KnowledgeGraphNodeSheet] for the given [nodeData].
  const KnowledgeGraphNodeSheet({
    super.key,
    required this.nodeData,
    required this.workspaceId,
    this.onEditFact,
    this.onDeleteFact,
    this.onEditPolicy,
    this.onDeletePolicy,
    this.onTogglePolicy,
  });

  /// The node data to display in this sheet.
  final NodeData nodeData;
  /// The workspace identifier.
  final String workspaceId;
  /// Called when the user wants to edit the associated fact.
  final VoidCallback? onEditFact;
  /// Called when the user wants to delete the associated fact.
  final VoidCallback? onDeleteFact;
  /// Called when the user wants to edit the associated policy.
  final VoidCallback? onEditPolicy;
  /// Called when the user wants to delete the associated policy.
  final VoidCallback? onDeletePolicy;
  /// Called when the user wants to toggle the associated policy's active state.
  final VoidCallback? onTogglePolicy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (nodeData.type) {
      case NodeType.domain:
        return _DomainDetail(
          domainLabel: nodeData.domainLabel ?? nodeData.domainSlug ?? '',
          factCount: nodeData.factCount,
          policyCount: nodeData.policyCount,
        );
      case NodeType.topic:
        return _TopicDetail(
          topic: nodeData.topic!,
          factCount: nodeData.factCount,
        );
      case NodeType.fact:
        return _FactDetail(
          fact: nodeData.fact!,
          onEdit: onEditFact,
          onDelete: onDeleteFact,
        );
      case NodeType.policy:
        return _PolicyDetail(
          policy: nodeData.policy!,
          onEdit: onEditPolicy,
          onDelete: onDeletePolicy,
          onToggle: onTogglePolicy,
        );
    }
  }
}

class _DomainDetail extends StatelessWidget {
  const _DomainDetail({
    required this.domainLabel,
    required this.factCount,
    required this.policyCount,
  });

  final String domainLabel;
  final int factCount;
  final int policyCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.tag, size: 22, color: tokens.textPrimary),
            const SizedBox(width: 8),
            Text(
              domainLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatRow(
          icon: AppIcons.lightbulb,
          label: l10n.facts,
          value: factCount,
        ),
        _StatRow(
          icon: AppIcons.shield,
          label: l10n.policies,
          value: policyCount,
        ),
      ],
    );
  }
}

class _TopicDetail extends StatelessWidget {
  const _TopicDetail({required this.topic, required this.factCount});

  final String topic;
  final int factCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.tag, size: 20, color: tokens.textTertiary),
            const SizedBox(width: 8),
            Text(
              topic,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatRow(
          icon: AppIcons.lightbulb,
          label: l10n.facts,
          value: factCount,
        ),
      ],
    );
  }
}

class _FactDetail extends StatelessWidget {
  const _FactDetail({required this.fact, this.onEdit, this.onDelete});

  final MemoryFact fact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: MemoryMetaChip(
                label: fact.topic,
                icon: AppIcons.lightbulb,
              ),
            ),
            if (fact.isSuperseded) ...[
              const SizedBox(width: 8),
              CcTooltip(
                message: AppLocalizations.of(context).supersededTooltip,
                child: MemoryMetaChip(
                  label: AppLocalizations.of(context).superseded,
                  tone: MemoryChipTone.error,
                ),
              ),
            ],
            const Spacer(),
            if (onEdit != null)
              CcIconButton(
                icon: AppIcons.pencil,
                onPressed: onEdit!,
                size: CcButtonSize.sm,
              ),
            const SizedBox(width: 4),
            if (onDelete != null)
              CcIconButton(
                icon: AppIcons.trash2,
                onPressed: onDelete!,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.bgSecondary,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Text(
            fact.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ConfidenceMeter(confidence: fact.confidence),
            const Spacer(),
            if (fact.authoredByRole != null)
              Text(
                AppLocalizations.of(context).authoredByLabel(fact.authoredByRole!.label),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).createdLabel(_formatDate(fact.createdAt)),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
        ),
      ],
    );
  }
}

class _PolicyDetail extends StatelessWidget {
  const _PolicyDetail({
    required this.policy,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  final MemoryPolicy policy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: MemoryMetaChip(
                label: policy.domain,
                icon: AppIcons.scale,
              ),
            ),
            if (!policy.active) ...[
              const SizedBox(width: 8),
              MemoryMetaChip(label: AppLocalizations.of(context).inactive),
            ],
            const Spacer(),
            if (onEdit != null)
              CcIconButton(
                icon: AppIcons.pencil,
                onPressed: onEdit!,
                size: CcButtonSize.sm,
              ),
            const SizedBox(width: 4),
            if (onDelete != null)
              CcIconButton(
                icon: AppIcons.trash2,
                onPressed: onDelete!,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.bgSecondary,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Text(
            policy.rule,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
          ),
        ),
        const SizedBox(height: 12),
        if (policy.requiredRole != null)
          Row(
            children: [
              Icon(AppIcons.user, size: 14, color: tokens.textTertiary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).requiredRoleLabel(policy.requiredRole!.label),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
              ),
            ],
          ),
        if (policy.sourceFactIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).sourceFacts,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final id in policy.sourceFactIds)
                MemoryMetaChip(
                  label: id.length > 8 ? id.substring(0, 8) : id,
                  monospace: true,
                ),
            ],
          ),
        ],
        if (onToggle != null) ...[
          const SizedBox(height: 12),
          CcButton(
            onPressed: onToggle!,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: policy.active ? AppIcons.eyeOff : AppIcons.eye,
            child: Text(policy.active ? AppLocalizations.of(context).deactivate : AppLocalizations.of(context).activate),
          ),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.textTertiary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
