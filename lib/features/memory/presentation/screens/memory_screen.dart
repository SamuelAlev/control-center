import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/screens/memory_fact_page.dart';
import 'package:control_center/features/memory/presentation/screens/memory_policy_page.dart';
import 'package:control_center/features/memory/presentation/widgets/facts_tab.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart';
import 'package:control_center/features/memory/presentation/widgets/policies_tab.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workspace-scoped knowledge browser: facts, policies and the knowledge
/// graph for the active workspace. Surfaces the previously UI-less memory
/// subdomain. All data is read through workspace-scoped providers keyed by the
/// active workspace id, preserving tenant isolation.
class MemoryScreen extends ConsumerStatefulWidget {
  /// Creates a [MemoryScreen].
  const MemoryScreen({super.key, this.record});

  /// The record the URL has open, or null for the list.
  final MemoryRecordRef? record;

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.navMemory,
        child: Center(
          child: Text(
            l10n.memoryNoWorkspace,
            style: TextStyle(color: tokens.textTertiary),
          ),
        ),
      );
    }

    final open = widget.record;
    final record = open?.workspaceId == workspaceId ? open : null;

    // The browser stays mounted under an open record, so Back lands on the same
    // search, scroll position and graph arrangement it left.
    return IndexedStack(
      index: record == null ? 0 : 1,
      sizing: StackFit.expand,
      children: [
        PageWrapper(
          title: l10n.navMemory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The strip's own rule stops at the page gutter, short of the
              // canvas and inspector below it, which run edge to edge. This one
              // carries it out to both sides.
              Stack(
                children: [
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    height: 1,
                    child: ColoredBox(color: tokens.borderPrimary),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: CcTabs(
                      tabs: [
                        CcTab(l10n.memoryTabFacts, icon: AppIcons.notebookText),
                        CcTab(l10n.memoryTabPolicies, icon: AppIcons.scale),
                        CcTab(l10n.memoryTabGraph, icon: AppIcons.workflow),
                      ],
                      selectedIndex: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                  ),
                ],
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
        ),
        switch (record) {
          null => const SizedBox.shrink(),
          (kind: MemoryRecordKind.fact, :final id, workspaceId: _) =>
            MemoryFactPage(
              key: ValueKey('fact:$id'),
              workspaceId: workspaceId,
              factId: id,
            ),
          (kind: MemoryRecordKind.policy, :final id, workspaceId: _) =>
            MemoryPolicyPage(
              key: ValueKey('policy:$id'),
              workspaceId: workspaceId,
              policyId: id,
            ),
        },
      ],
    );
  }
}
