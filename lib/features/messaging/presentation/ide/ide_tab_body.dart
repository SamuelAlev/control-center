import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/environments/presentation/environment_logs_pane.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_shell_output_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_pool.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/file_viewer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/review_code_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/space_provisioning_logs_pane.dart';
import 'package:control_center/features/observability/presentation/tool_render/run_activity_opener_scope.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plan_studio_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_pane.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The content of one messaging IDE tab, by [EditorTab.kind].
///
/// Keep-alive, lazy build and webview suspension wrap this in the IDE's
/// `EditorBodyHost`; this widget only picks the pane. Tabs that carry a
/// workspace are checked against [workspaceId] — a restored layout must never
/// render another tenant's data, so a mismatch renders nothing.
class MessagingIdeTabBody extends StatelessWidget {
  /// Creates the body of [tab].
  const MessagingIdeTabBody({
    super.key,
    required this.tab,
    required this.workspaceId,
    required this.selectedSpaceId,
    required this.isVisible,
    required this.windowPool,
    required this.conversationOpenerFor,
    required this.openSubagentRun,
    required this.terminalPane,
  });

  /// The tab to render.
  final EditorTab tab;

  /// The active workspace, or null before it resolves.
  final String? workspaceId;

  /// The conversation (space) the IDE shows.
  final String? selectedSpaceId;

  /// Whether the tab is the visible one of its pane.
  final bool isVisible;

  /// The embedded editor windows shared by the code-server tabs.
  final CodeServerWindowPool windowPool;

  /// The interned conversation opener for a space's chat tabs.
  final void Function(String conversationId) Function(String spaceId)
  conversationOpenerFor;

  /// Opens the subagent run a transcript's `task` cell spawned.
  final void Function({required String runId, required String label})
  openSubagentRun;

  /// Builds a terminal tab's body (its session lives with the host).
  final Widget Function(EditorTab tab) terminalPane;

  @override
  Widget build(BuildContext context) {
    final workspaceId = this.workspaceId;
    switch (tab.kind) {
      case MessagingTabKinds.chat:
        return _chat(workspaceId);
      case MessagingTabKinds.terminal:
        return terminalPane(tab);
      case MessagingTabKinds.agentShellOutput:
        return _agentShellOutput(context, workspaceId);
      case MessagingTabKinds.browser:
        return BrowserPane(initialUrl: tab.args['url'] as String?);
      case MessagingTabKinds.environmentLogs:
        return environmentLogsTabBody(tab.args, workspaceId);
      case MessagingTabKinds.provisioningLogs:
        return spaceProvisioningLogsTabBody(tab.args, workspaceId);
      case MessagingTabKinds.rig:
        return RigTabPane(
          surface: tab.args['surface'] as String? ?? RigTabSurfaces.computer,
          engine: RigTabSurfaces.engineFromArgs(tab.args),
          slotId: RigTabSurfaces.slotFromArgs(tab.args),
          conversationId: selectedSpaceId,
          audioTabKey: tab,
          // A hidden rig tab stops streaming: the guest keeps encoding and the
          // link keeps carrying frames otherwise, for a picture on no screen.
          isVisible: isVisible,
        );
      case MessagingTabKinds.codeServer:
        final repoId = tab.args['repoId'] as String?;
        final path = tab.args['path'] as String?;
        return Consumer(
          builder: (context, ref, editor) {
            // The editor is the server owner's. A restored file tab of it
            // opens the file in the built-in view for anyone else; a bare
            // editor tab keeps the pane's own refusal, which points there.
            final workspace = workspaceId;
            if (!ref.watch(canUseHostProvider) &&
                workspace != null &&
                repoId != null &&
                path != null) {
              return FileViewerPane(
                workspaceId: workspace,
                repoId: repoId,
                path: path,
                spaceId: tab.args['spaceId'] as String?,
              );
            }
            return editor!;
          },
          child: CodeServerPane(
            spaceId: tab.args['spaceId'] as String,
            repoId: repoId,
            path: path,
            tab: tab,
            pool: windowPool,
          ),
        );
      case MessagingTabKinds.attachment:
        return AttachmentPreviewPane(
          attachmentId: tab.args[kAttachmentPreviewIdArg] as String? ?? '',
          label: tab.args['label'] as String?,
        );
      case MessagingTabKinds.file:
        final repoId = tab.args['repoId'] as String;
        final path = tab.args['path'] as String;
        if (workspaceId == null) {
          return const SizedBox.shrink();
        }
        return FileViewerPane(
          workspaceId: workspaceId,
          repoId: repoId,
          path: path,
          spaceId: tab.args['spaceId'] as String?,
        );
      case MessagingTabKinds.fileDiff:
        final prFile = tab.args['prFile'] as PrFile;
        // PrDiffView builds a sliver (it's designed to live inside the PR
        // detail screen's CustomScrollView). As a standalone tab body it must be
        // hosted in a viewport, else it's fed to the tab host's ColoredBox (a
        // RenderBox) and crashes ("expected a RenderBox but received a
        // RenderSliverMainAxisGroup").
        return CustomScrollView(
          slivers: [
            PrDiffView(files: [prFile], comments: const []),
          ],
        );
      case MessagingTabKinds.review:
        final repoId = tab.args['repoId'] as String;
        final anchorPath = tab.args['anchorPath'] as String? ?? '';
        if (workspaceId == null) {
          return const SizedBox.shrink();
        }
        return ReviewCodePane(
          workspaceId: workspaceId,
          repoId: repoId,
          anchorPath: anchorPath,
          spaceId: tab.args['spaceId'] as String?,
        );
      case MessagingTabKinds.plan:
        final planId = tab.args['planId'] as String?;
        if (workspaceId == null || planId == null) {
          return const SizedBox.shrink();
        }
        // Plan Studio hosted as a tab: the tab strip already names it, so the
        // page header is suppressed.
        return PlanStudioScreen(
          workspaceId: workspaceId,
          kind: tab.args['planKind'] as String? ?? 'document',
          id: planId,
          showPageHeader: false,
        );
      case MessagingTabKinds.artifact:
        final workProductId = tab.args['workProductId'] as String?;
        if (workProductId == null ||
            workspaceId == null ||
            workspaceId != tab.args['workspaceId']) {
          return const SizedBox.shrink();
        }
        return ArtifactDetailView(workProductId: workProductId);
      case MessagingTabKinds.contextExplorer:
        return _contextExplorer(workspaceId);
      case MessagingTabKinds.agentActivity:
        return _agentActivity(workspaceId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _chat(String? workspaceId) {
    final spaceId = tab.args['spaceId'] as String;
    final pane = ConversationPane(
      spaceId: spaceId,
      conversationId: tab.args['conversationId'] as String?,
      onSelectConversation: conversationOpenerFor(spaceId),
      autofocusComposer: isVisible,
    );
    if (workspaceId == null) {
      return pane;
    }
    // Lets the `task` cell in an agent turn open the subagent it spawned —
    // the transcript renderers take no callbacks, so the opener rides an
    // InheritedWidget instead.
    return RunActivityOpenerScope(
      workspaceId: workspaceId,
      spaceId: spaceId,
      openRun: openSubagentRun,
      child: pane,
    );
  }

  Widget _agentShellOutput(BuildContext context, String? workspaceId) {
    final tabSpaceId = tab.args['spaceId'] as String?;
    final outputId = tab.args['outputId'] as String?;
    if (workspaceId == null ||
        tab.args['workspaceId'] != workspaceId ||
        tabSpaceId == null ||
        tabSpaceId != selectedSpaceId ||
        outputId == null ||
        outputId.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.terminal,
        message: AppLocalizations.of(context).unavailable,
      );
    }
    return AgentShellOutputPane(
      workspaceId: workspaceId,
      spaceId: tabSpaceId,
      outputId: outputId,
      command: tab.args['command'] as String? ?? '',
    );
  }

  Widget _contextExplorer(String? workspaceId) {
    final explorerWorkspaceId = tab.args['workspaceId'] as String?;
    final explorerSpaceId = tab.args['spaceId'] as String?;
    final explorerConversationId = tab.args['conversationId'] as String?;
    final explorerAgentId = tab.args['agentId'] as String?;
    if (explorerWorkspaceId == null ||
        explorerSpaceId == null ||
        explorerConversationId == null ||
        explorerAgentId == null ||
        workspaceId == null ||
        workspaceId != explorerWorkspaceId) {
      return const SizedBox.shrink();
    }
    return ContextExplorerPane(
      workspaceId: explorerWorkspaceId,
      spaceId: explorerSpaceId,
      conversationId: explorerConversationId,
      agentId: explorerAgentId,
    );
  }

  Widget _agentActivity(String? workspaceId) {
    final tabWorkspaceId = tab.args['workspaceId'] as String?;
    final tabSpaceId = tab.args['spaceId'] as String?;
    final runId = tab.args['runId'] as String?;
    if (tabWorkspaceId == null ||
        tabSpaceId == null ||
        runId == null ||
        workspaceId == null ||
        workspaceId != tabWorkspaceId) {
      return const AgentActivityPane.unavailable();
    }
    return AgentActivityPane(
      workspaceId: tabWorkspaceId,
      spaceId: tabSpaceId,
      runId: runId,
      agentId: tab.args['agentId'] as String? ?? '',
      fallbackLabel: tab.args['label'] as String?,
    );
  }
}
