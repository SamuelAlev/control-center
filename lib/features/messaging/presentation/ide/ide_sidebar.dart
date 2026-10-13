import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_view_strip.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/artifacts_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/general_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/notes_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/source_control_panel.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The IDE-style sidebar for the messaging screen.
/// Labelled tabs never fit a sidebar that narrows to 200px, so the rail is icon-only and
/// width-aware: the operator pins the views they want a cell for (persisted per user) and
/// whatever does not fit folds into the trailing caret menu.
class IdeSidebar extends ConsumerStatefulWidget {
  /// Creates an [IdeSidebar].
  const IdeSidebar({
    super.key,
    required this.tabNotifier,
    required this.layout,
    required this.workspaceId,
    this.spaceId,
    required this.onOpenFile,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
    required this.onOpenAgentRun,
    required this.onOpenAgentShell,
    required this.onFocusTerminal,
    required this.onKillTerminal,
    required this.onFocusRig,
    required this.onFocusBrowserTab,
    required this.onCloseBrowserTab,
    this.onQuickViewFile,
  });

  /// Drives the active sidebar view from the parent layout. Two-way: tapping a
  /// cell writes back here and an external write moves the rail.
  final ValueNotifier<IdeSidebarView> tabNotifier;

  /// The focused editor leaf supplies General's conversation and Explore's file.
  final EditorLayoutController layout;

  /// The workspace whose linked repos the panels are scoped to.
  final String workspaceId;

  /// The active conversation, whose isolated CoW worktree the Source Control
  /// diff reflects. Null when no conversation is open.
  final String? spaceId;

  /// Called when an Explorer file is opened (opens the code-server editor tab,
  /// the default). Right-click / long-press a file row for the read-only
  /// [onQuickViewFile] instead.
  final ValueChanged<({String repoId, String path})> onOpenFile;

  /// Optional read-only "Quick view" of an Explorer file (a secondary action:
  /// right-click / long-press a file row). Null on hosts without it.
  final ValueChanged<({String repoId, String path})>? onQuickViewFile;

  /// Called when a Source Control changed file is opened for review (opens a
  /// multi-file "Review code" tab anchored to the file).
  final ValueChanged<({String repoId, String repoFullName, PrFile file})>
  onOpenReview;

  /// Called to open a Source Control file in the conversation's editor.
  final ValueChanged<({String repoId, String path})> onViewSource;

  /// Called to revert one or more Source Control files to HEAD.
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  /// Called from the General panel (or the plan section) to open the tapped
  /// agent run — a subagent run gets its own activity tab, a top-level run
  /// brings the conversation forward. See [AgentRunTarget].
  final ValueChanged<AgentRunTarget> onOpenAgentRun;

  /// Opens the output captured for an agent command.
  final ValueChanged<AgentShellProcess> onOpenAgentShell;

  /// Called from the General panel to focus (or open) a terminal by session id.
  final ValueChanged<String> onFocusTerminal;

  /// Ends the terminal identified by its session id.
  final ValueChanged<String> onKillTerminal;

  /// Called from the General panel to focus (or open) a machine's rig tab.
  final ValueChanged<RigTabTarget> onFocusRig;

  /// Called from the General panel to focus a host web-browser tab by its
  /// mirror id (see `spaceBrowserTabsProvider`).
  final ValueChanged<String> onFocusBrowserTab;

  /// Called from the General panel to close a host web-browser tab by its
  /// mirror id — the BROWSERS row's hover ×.
  final ValueChanged<String> onCloseBrowserTab;

  @override
  ConsumerState<IdeSidebar> createState() => _IdeSidebarState();
}

class _IdeSidebarState extends ConsumerState<IdeSidebar> {
  late IdeSidebarView _view = widget.tabNotifier.value;
  late final void Function() _tabListener;

  @override
  void initState() {
    super.initState();
    _tabListener = () {
      if (!mounted) {
        return;
      }
      final next = widget.tabNotifier.value;
      if (next != _view) {
        setState(() => _view = next);
      }
    };
    widget.tabNotifier.addListener(_tabListener);
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_tabListener);
    super.dispose();
  }

  void _select(IdeSidebarView view) {
    if (view != _view) {
      setState(() => _view = view);
      widget.tabNotifier.value = view;
    }
  }

  Widget _buildExplorer() => ListenableBuilder(
    listenable: widget.layout,
    builder: (context, _) {
      final controller = widget.layout.activeLeaf.controller;
      final tab = controller.isEmpty
          ? null
          : controller.tabs[controller.selectedIndex];
      final repoId = tab?.args['repoId'];
      final path = tab?.args['path'];
      final isFile =
          tab?.kind == MessagingTabKinds.codeServer ||
          tab?.kind == MessagingTabKinds.file;
      return ExplorerPanel(
        key: ValueKey((widget.workspaceId, widget.spaceId)),
        workspaceId: widget.workspaceId,
        spaceId: widget.spaceId,
        revealKey: (widget.layout.activeLeafId, tab),
        activeFile:
            isFile &&
                tab?.args['spaceId'] == widget.spaceId &&
                repoId is String &&
                repoId.isNotEmpty &&
                path is String &&
                path.isNotEmpty
            ? (repoId: repoId, path: path)
            : null,
        onOpenFile: widget.onOpenFile,
        onQuickViewFile: widget.onQuickViewFile,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return ColoredBox(
      color: t.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IdeSidebarViewStrip(selected: _view, onChanged: _select),
          Expanded(
            child: switch (_view) {
              IdeSidebarView.general => ListenableBuilder(
                listenable: widget.layout,
                builder: (context, _) => GeneralPanel(
                  workspaceId: widget.workspaceId,
                  focusedTabKey: activeEditorTabKey(widget.layout),
                  onOpenAgentRun: widget.onOpenAgentRun,
                  onOpenAgentShell: widget.onOpenAgentShell,
                  onFocusTerminal: widget.onFocusTerminal,
                  onKillTerminal: widget.onKillTerminal,
                  onFocusRig: widget.onFocusRig,
                  onFocusBrowserTab: widget.onFocusBrowserTab,
                  onCloseBrowserTab: widget.onCloseBrowserTab,
                ),
              ),
              IdeSidebarView.explorer => _buildExplorer(),
              IdeSidebarView.sourceControl => SourceControlPanel(
                workspaceId: widget.workspaceId,
                spaceId: widget.spaceId,
                onOpenReview: widget.onOpenReview,
                onViewSource: widget.onViewSource,
                onRevertFiles: widget.onRevertFiles,
              ),
              IdeSidebarView.notes => NotesPanel(
                workspaceId: widget.workspaceId,
                spaceId: widget.spaceId,
              ),
              // Artifacts are conversation-scoped, so the view needs a space.
              // Without one there is nothing to list.
              IdeSidebarView.artifacts =>
                widget.spaceId == null
                    ? const SizedBox.shrink()
                    : ArtifactsPanel(spaceId: widget.spaceId!),
            },
          ),
        ],
      ),
    );
  }
}
