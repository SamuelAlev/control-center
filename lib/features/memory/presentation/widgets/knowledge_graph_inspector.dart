import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_data.dart'
    show NodeData, NodeType;
import 'package:control_center/features/memory/presentation/widgets/memory_fact_details.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_page.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Width of the inspector beside the canvas.
const double kKnowledgeGraphInspectorWidth = 380;

/// The selected node, docked beside the canvas.
///
/// Docked rather than modal: reading a node is a step in walking the graph, so
/// the canvas stays live and picking another node swaps what this shows.
class KnowledgeGraphInspector extends StatelessWidget {
  /// Creates a [KnowledgeGraphInspector] for [nodeData].
  const KnowledgeGraphInspector({
    super.key,
    required this.nodeData,
    required this.onClose,
    this.onOpen,
    this.onDelete,
    this.onToggleActive,
    this.onToggleFacts,
    this.factsShown = false,
  });

  /// The selected node.
  final NodeData nodeData;

  /// Dismisses the inspector.
  final VoidCallback onClose;

  /// Opens the node's record, to read in full or edit.
  final VoidCallback? onOpen;

  /// Deletes the node's record.
  final VoidCallback? onDelete;

  /// Turns the node's policy on or off.
  final ValueChanged<bool>? onToggleActive;

  /// Shows or hides a topic's facts on the canvas.
  final VoidCallback? onToggleFacts;

  /// Whether a topic's facts are on the canvas.
  final bool factsShown;

  (IconData, String) _kind(AppLocalizations l10n) => switch (nodeData.type) {
    NodeType.domain => (AppIcons.tag, l10n.domain),
    NodeType.topic => (AppIcons.hash, l10n.topic),
    NodeType.fact => (AppIcons.lightbulb, l10n.fact),
    NodeType.policy => (AppIcons.scale, l10n.policy),
  };

  /// A policy has no name of its own: its rule opens the panel instead.
  String? get _title => switch (nodeData.type) {
    NodeType.domain => nodeData.domainLabel ?? nodeData.domainSlug ?? '',
    NodeType.topic => nodeData.topic ?? '',
    NodeType.fact => nodeData.fact?.topic ?? '',
    NodeType.policy => null,
  };

  List<Widget> _body(BuildContext context, AppLocalizations l10n) {
    final fact = nodeData.fact;
    final policy = nodeData.policy;
    return switch (nodeData.type) {
      NodeType.domain => [
        SettingsSummary(
          facts: [
            SettingsFact(label: l10n.facts, value: '${nodeData.factCount}'),
            SettingsFact(
              label: l10n.policies,
              value: '${nodeData.policyCount}',
            ),
          ],
        ),
      ],
      NodeType.topic => [
        SettingsSummary(
          facts: [
            SettingsFact(label: l10n.facts, value: '${nodeData.factCount}'),
          ],
        ),
      ],
      NodeType.fact => [
        if (fact!.isSuperseded) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcStatusTag(
              label: l10n.superseded,
              tone: CcStatusTone.caution,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        StyledMarkdownBody(data: fact.content, compact: true),
        const SizedBox(height: AppSpacing.lg),
        const CcDivider(),
        const SizedBox(height: AppSpacing.sm),
        ...memoryFactDetailRows(l10n, fact),
      ],
      NodeType.policy => [
        StyledMarkdownBody(data: policy!.rule, compact: true),
        const SizedBox(height: AppSpacing.lg),
        const CcDivider(),
        const SizedBox(height: AppSpacing.sm),
        if (onToggleActive != null)
          MemoryDetailRow(
            label: l10n.memoryPolicyActive,
            child: CcSwitch(
              value: policy.active,
              semanticLabel: l10n.memoryPolicyActive,
              onChanged: onToggleActive,
            ),
          )
        else if (!policy.active)
          MemoryDetailRow(
            label: l10n.memoryPolicyActive,
            child: Text(l10n.inactive),
          ),
        ...memoryPolicyDetailRows(l10n, policy),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (icon, kind) = _kind(l10n);
    final hasFooter =
        onOpen != null || onDelete != null || onToggleFacts != null;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Focus(
        autofocus: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgPrimary,
            border: BorderDirectional(
              start: BorderSide(color: t.borderSecondary),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: t.fgTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        kind,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                    CcIconButton(
                      icon: AppIcons.x,
                      size: CcButtonSize.sm,
                      variant: CcButtonVariant.ghost,
                      tooltip: l10n.closeEsc,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const CcDivider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_title case final title?) ...[
                        Text(
                          title,
                          style: CcTypography.title.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ..._body(context, l10n),
                    ],
                  ),
                ),
              ),
              if (hasFooter) ...[
                const CcDivider(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      if (onOpen != null)
                        CcButton(
                          variant: CcButtonVariant.secondary,
                          size: CcButtonSize.sm,
                          onPressed: onOpen,
                          child: Text(l10n.openLabel),
                        ),
                      if (onToggleFacts != null)
                        CcButton(
                          variant: CcButtonVariant.secondary,
                          size: CcButtonSize.sm,
                          onPressed: onToggleFacts,
                          child: Text(
                            factsShown
                                ? l10n.memoryGraphHideFacts
                                : l10n.memoryGraphShowFacts,
                          ),
                        ),
                      const Spacer(),
                      if (onDelete != null)
                        CcIconButton(
                          icon: AppIcons.trash2,
                          size: CcButtonSize.sm,
                          variant: CcButtonVariant.ghost,
                          tooltip: l10n.delete,
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
