import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_view_strip.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/artifacts_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/general_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/notes_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/prs_panel.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/source_control_panel.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The IDE-style sidebar for the messaging screen.
///
/// An icon rail — General, Explorer, Source Control, Pull Requests, Notes,
/// Artifacts — over the matching panel. Six labelled tabs never fit a sidebar
/// that narrows to 200px, so the rail is icon-only and width-aware: the
/// operator pins the views they want a cell for (persisted per user), and
/// whatever does not fit folds into the trailing caret menu. See
/// [IdeSidebarViewStrip].
///
/// The editor↔sidebar boundary is drawn by the resizable divider in the parent
/// layout, so this panel paints no left edge of its own (a border here would
/// double the divider hairline). General (the session dashboard: todos, agents,
/// terminals) is first and selected by default. Notes (PRD 16 §11) holds the
/// shared per-channel handoff doc both humans and agents read/write. The active
/// view is mirrored in [tabNotifier] so the parent layout (e.g. a "focus source
/// control" action from the chat header) can drive the selection from the
/// outside.
class IdeSidebar extends ConsumerStatefulWidget {
  /// Creates an [IdeSidebar].
  const IdeSidebar({
    super.key,
    required this.tabNotifier,
    required this.workspaceId,
    this.channelId,
    required this.onOpenFile,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
    required this.onOpenAgentRun,
    required this.onFocusTerminal,
    this.onQuickViewFile,
  });

  /// Drives the active sidebar view from the parent layout. Two-way: tapping a
  /// cell writes back here, and an external write moves the rail.
  final ValueNotifier<IdeSidebarView> tabNotifier;

  /// The workspace whose linked repos the panels are scoped to.
  final String workspaceId;

  /// The active conversation, whose isolated CoW worktree the Source Control
  /// diff reflects. Null when no conversation is open.
  final String? channelId;

  /// Called when an Explorer file is opened (opens the code-server editor tab,
  /// the default). Right-click / long-press a file row for the read-only
  /// [onQuickViewFile] instead.
  final ValueChanged<({String repoId, String path})> onOpenFile;

  /// Optional read-only "Quick view" of an Explorer file (a secondary action:
  /// right-click / long-press a file row). Null on hosts without it.
  final ValueChanged<({String repoId, String path})>? onQuickViewFile;

  /// Called when a Source Control changed file is opened for review (opens a
  /// multi-file "Review code" tab anchored to the file).
  final ValueChanged<({String repoId, PrFile file})> onOpenReview;

  /// Called to open a Source Control file in the conversation's editor.
  final ValueChanged<({String repoId, String path})> onViewSource;

  /// Called to revert one or more Source Control files to HEAD.
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  /// Called from the General panel (or the plan section) to open the tapped
  /// agent run — a subagent run gets its own activity tab, a top-level run
  /// brings the conversation forward. See [AgentRunTarget].
  final ValueChanged<AgentRunTarget> onOpenAgentRun;

  /// Called from the General panel to focus (or open) a terminal by session id.
  final ValueChanged<String> onFocusTerminal;

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
              IdeSidebarView.general => GeneralPanel(
                workspaceId: widget.workspaceId,
                onOpenAgentRun: widget.onOpenAgentRun,
                onFocusTerminal: widget.onFocusTerminal,
              ),
              IdeSidebarView.explorer => ExplorerPanel(
                workspaceId: widget.workspaceId,
                onOpenFile: widget.onOpenFile,
                onQuickViewFile: widget.onQuickViewFile,
              ),
              IdeSidebarView.sourceControl => SourceControlPanel(
                workspaceId: widget.workspaceId,
                channelId: widget.channelId,
                onOpenReview: widget.onOpenReview,
                onViewSource: widget.onViewSource,
                onRevertFiles: widget.onRevertFiles,
              ),
              IdeSidebarView.pullRequests => const PrsPanel(),
              IdeSidebarView.notes => NotesPanel(
                workspaceId: widget.workspaceId,
                channelId: widget.channelId,
              ),
              // Artifacts are conversation-scoped, so the view needs a channel.
              // Without one there is nothing to list.
              IdeSidebarView.artifacts =>
                widget.channelId == null
                    ? const SizedBox.shrink()
                    : ArtifactsPanel(channelId: widget.channelId!),
            },
          ),
        ],
      ),
    );
  }
}
