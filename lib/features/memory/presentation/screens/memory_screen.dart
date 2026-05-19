import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/facts_tab.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart';
import 'package:control_center/features/memory/presentation/widgets/policies_tab.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Workspace-scoped knowledge browser: facts, policies, and the knowledge
/// graph for the active workspace. Surfaces the previously UI-less memory
/// subdomain. All data is read through workspace-scoped providers keyed by the
/// active workspace id, preserving tenant isolation.
class MemoryScreen extends ConsumerStatefulWidget {
  /// Creates a [MemoryScreen].
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.navMemory,
        child: Center(
          child: Text(
            l10n.memoryNoWorkspace,
            style: TextStyle(
              color: (context.designSystem ?? DesignSystemTokens.light())
                  .textTertiary,
            ),
          ),
        ),
      );
    }

    // Live counts surface "how much is in here" on the tabs themselves.
    final factCount = ref
        .watch(memoryFactsProvider(workspaceId))
        .maybeWhen(
          data: (facts) => facts.where((f) => !f.isSuperseded).length,
          orElse: () => null,
        );
    final policyCount = ref
        .watch(memoryPoliciesProvider(workspaceId))
        .maybeWhen(
          data: (policies) => policies.where((p) => p.active).length,
          orElse: () => null,
        );

    final tabs = [
      (label: l10n.memoryTabFacts, icon: LucideIcons.notebookText, count: factCount),
      (label: l10n.memoryTabPolicies, icon: LucideIcons.scale, count: policyCount),
      (label: l10n.memoryTabGraph, icon: LucideIcons.workflow, count: null),
    ];

    return PageWrapper(
      title: l10n.navMemory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    variant: _tab == i
                        ? CcButtonVariant.secondary
                        : CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    onPressed: () => setState(() => _tab = i),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tabs[i].icon, size: 14),
                        const SizedBox(width: AppSpacing.sm),
                        Text(tabs[i].label),
                        if (tabs[i].count != null && tabs[i].count! > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _TabCount(
                            count: tabs[i].count!,
                            selected: _tab == i,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => FactsTab(workspaceId: workspaceId),
              1 => PoliciesTab(workspaceId: workspaceId),
              _ => KnowledgeGraph(workspaceId: workspaceId),
            },
          ),
        ],
      ),
    );
  }
}

/// Small count pill shown on a memory tab. Quiet on inactive tabs; tinted
/// toward the brand on the selected tab so it reads as part of the selection.
class _TabCount extends StatelessWidget {
  const _TabCount({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: selected ? tokens.bgBrandPrimary : tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        '$count',
        style: CcTypography.caption.copyWith(
          color: selected ? tokens.textBrandPrimary : tokens.textTertiary,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
