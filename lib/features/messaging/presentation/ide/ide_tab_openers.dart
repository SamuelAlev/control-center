import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_shell_output_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/goal_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_host.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/quick_open/quick_open_dialog.dart';
import 'package:control_center/features/messaging/presentation/widgets/create_untitled_conversation.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/recent_files_provider.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';

/// Everything that opens (or focuses) a tab in the messaging IDE: the
/// keyboard commands, the sidebar's rows, the `[+]` menu and requests from
/// inside tab bodies. Each reads the IDE's live layout and space at call time.
class IdeTabOpeners {
  /// Creates the openers for the IDE behind [_host].
  ///
  /// `defaultEditorRepoId` is the repo a bare editor opens on;
  /// `publishTerminals` refreshes the sidebar's TERMINALS mirror.
  IdeTabOpeners(
    this._host, {
    required this._defaultEditorRepoId,
    required this._publishTerminals,
  });

  final IdeHost _host;
  final String? Function() _defaultEditorRepoId;
  final VoidCallback _publishTerminals;

  /// Whether this person may open the code-server editor.
  bool get _hostEditor => _host.ref.read(canUseHostProvider);

  /// Opens (or focuses) the conversation's code-server editor tab on its
  /// isolated worktree — the single place where files are created/saved.
  /// Driven by ⌘T and by double-clicking the tab-strip void. One code-server
  /// per conversation worktree, so a re-open refocuses the running instance
  /// rather than stacking a second tab.
  ///
  /// The editor runs on the server host outside any sandbox, so only someone
  /// with host access ([canUseHostProvider]) gets one; for anyone else this
  /// opens nothing.
  void openEditor() {
    final spaceId = _host.selectedSpaceId;
    if (spaceId == null || !_hostEditor) {
      return;
    }
    final l10n = AppLocalizations.of(_host.context);
    final layout = _host.layout;
    layout.focusOrOpenInLeaf(
      layout.activeLeafId,
      (t) =>
          t.kind == MessagingTabKinds.codeServer &&
          t.args['spaceId'] == spaceId &&
          t.args['path'] == null,
      () => MessagingIdeTabs.codeServerEditor(
        spaceId: spaceId,
        repoId: _defaultEditorRepoId(),
        label: l10n.ideCodeServer,
      ),
    );
  }

  /// Shows the quick open picker (⌘P) over the open conversation's worktrees
  /// and opens the pick: a tab in the active pane, or a new pane to the side.
  Future<void> quickOpen() async {
    final spaceId = _host.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final choice = await showQuickOpen(
      _host.context,
      workspaceId: _host.hostWorkspaceId,
      spaceId: spaceId,
    );
    // The conversation may have changed while the picker was up; its files
    // belong to the one it was opened for.
    if (choice == null || !_host.mounted || _host.selectedSpaceId != spaceId) {
      return;
    }
    openWorktreeFile(choice.file, toSide: choice.toSide);
  }

  /// Opens (or refocuses) the code-server tab for a worktree file — the
  /// Explorer's default open, Source control's "view source" and quick open.
  /// Each distinct file gets its own tab; a file already open in the pane
  /// ([leafId], else the active one) is refocused (dedup by path). [toSide]
  /// instead opens a fresh tab in a new pane split off to the right.
  ///
  /// Without host access there is no editor, so the file opens in the
  /// read-only quick view instead (in a new pane to the side for [toSide]).
  void openWorktreeFile(
    ({String repoId, String path}) target, {
    bool toSide = false,
    String? leafId,
  }) {
    final spaceId = _host.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    if (!_hostEditor) {
      // Still to the side when asked: the built-in view of the same file.
      if (toSide) {
        _host.layout.openInSplit(
          _host.layout.activeLeafId,
          MessagingIdeTabs.fileQuickView(target: target, spaceId: spaceId),
          DropEdge.right,
        );
        return;
      }
      quickViewFile(target);
      return;
    }
    final l10n = AppLocalizations.of(_host.context);
    final layout = _host.layout;
    EditorTab build() => MessagingIdeTabs.worktreeFile(
      spaceId: spaceId,
      target: target,
      fallbackLabel: l10n.ideCodeServer,
    );
    if (toSide) {
      layout.openInSplit(layout.activeLeafId, build(), DropEdge.right);
      return;
    }
    layout.focusOrOpenInLeaf(
      leafId ?? layout.activeLeafId,
      (t) =>
          t.kind == MessagingTabKinds.codeServer &&
          t.args['spaceId'] == spaceId &&
          t.args['path'] == target.path,
      build,
    );
  }

  /// The Explorer's read-only "Quick view" of a worktree file.
  void quickViewFile(({String repoId, String path}) target) =>
      _host.layout.openInActiveLeaf(
        MessagingIdeTabs.fileQuickView(
          target: target,
          spaceId: _host.selectedSpaceId,
        ),
      );

  /// Opens (or re-anchors) the "Review code" tab of a Source Control file.
  void openReview(({String repoId, String repoFullName, PrFile file}) target) {
    final l10n = AppLocalizations.of(_host.context);
    _host.layout.openInActiveLeaf(
      MessagingIdeTabs.review(
        spaceId: _host.selectedSpaceId,
        target: target,
        label: l10n.ideReviewCodeInRepo(target.repoFullName),
      ),
    );
  }

  /// Feeds quick open's recent list: the file a worktree file tab shows, once
  /// it is the focused tab of the active pane. Every route there — Explorer,
  /// quick open, in-editor navigation, a tab press — counts as opening it.
  void recordRecentFile() {
    final spaceId = _host.selectedSpaceId;
    final controller = _host.layout.activeLeaf.controller;
    if (spaceId == null || controller.isEmpty) {
      return;
    }
    final tab = controller.tabs[controller.selectedIndex];
    final path = tab.args['path'];
    if ((tab.kind != MessagingTabKinds.codeServer &&
            tab.kind != MessagingTabKinds.file) ||
        tab.args['spaceId'] != spaceId ||
        path is! String ||
        path.isEmpty) {
      return;
    }
    final repoId = tab.args['repoId'] as String? ?? '';
    final args = (workspaceId: _host.hostWorkspaceId, spaceId: spaceId);
    // Layout changes can land mid-frame; a provider write must not.
    scheduleMicrotask(() {
      if (_host.mounted) {
        _host.ref
            .read(recentFilesProvider(args).notifier)
            .touch(repoId: repoId, path: path);
      }
    });
  }

  /// Opens (or refocuses) a tab requested from inside a tab body via
  /// `EditorTabOpenerScope`.
  ///
  /// De-dupes across the WHOLE split tree rather than just the active leaf: a
  /// plan already open in a side pane should be brought forward there, not
  /// duplicated next to the chat. Deferred a frame because the caller is
  /// typically mid-gesture (a bubble button) or mid-build (an auto-open on a
  /// freshly-arrived plan) and mutating the tab tree inside either trips the
  /// same mouse-tracker / build assertions [openNextFrame] guards against.
  void openFromScope(EditorTab tab) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_host.mounted) {
        return;
      }
      final layout = _host.layout;
      final key = tab.dedupKey;
      final reopenForEdit =
          tab.kind == MessagingTabKinds.goal &&
          tab.args['openContractEditor'] == true;
      if (key != null && !reopenForEdit && layout.focusTab((t) => t.dedupKey == key)) {
        return;
      }
      if (key != null && reopenForEdit) {
        for (final existing in layout.allTabs().toList()) {
          if (existing.dedupKey == key) {
            layout.closeTabByIdentity(existing);
          }
        }
      }
      layout.openInActiveLeaf(tab);
    });
  }

  /// Opens [tab] in [leafId] on the NEXT frame. The `[+]` menu invokes its
  /// `onSelected` synchronously while its overlay is still dismissing (a live
  /// pointer/mouse-tracker phase); mounting the new tab's platform view
  /// (browser/terminal/editor webview) right then mutates the MouseRegion /
  /// PlatformView tree mid device-update and trips
  /// `mouse_tracker.dart: '!_debugDuringDeviceUpdate'`. Deferring one frame
  /// lets the overlay finish tearing down first. Imperceptible (~1 frame).
  void openNextFrame(String leafId, EditorTab tab) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_host.mounted) {
        return;
      }
      _host.layout
        ..setActiveLeaf(leafId)
        ..openInActiveLeaf(tab);
    });
  }

  /// Creates the next conversation of the open space (no name prompt: it
  /// starts untitled and the workspace's title model names it after its first
  /// message) and opens it in [leafId].
  Future<void> newConversation(String leafId) async {
    final spaceId = _host.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final id = await createUntitledConversation(_host.ref, spaceId);
    if (id == null || !_host.mounted) {
      return;
    }
    openNextFrame(leafId, MessagingIdeTabs.chat(spaceId, conversationId: id));
  }

  /// Reverts [target]'s files to HEAD server-side, then refreshes the Source
  /// Control panel. Surfaces untracked-skipped files via a toast.
  Future<void> revertFiles(({String repoId, List<String> paths}) target) async {
    final spaceId = _host.selectedSpaceId;
    final workspaceId = _host.activeWorkspaceId;
    if (spaceId == null || workspaceId == null) {
      return;
    }
    final ref = _host.ref;
    final context = _host.context;
    WorktreeRevertResult? result;
    Object? refusal;
    try {
      result = await revertWorktreeFiles(
        ref.read(rpcClientProvider),
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: target.repoId,
        paths: target.paths,
      );
    } on RemoteRpcException catch (e) {
      refusal = e;
    }
    if (!context.mounted) {
      return;
    }
    // Always refresh the changes lists so the panel reflects the revert — both
    // the flat diff (the review tab) and the staged/unstaged split the Source
    // Control panel renders.
    final args = (
      workspaceId: workspaceId,
      repoId: target.repoId,
      spaceId: spaceId,
    );
    ref
      ..invalidate(repoChangesProvider(args))
      ..invalidate(repoChangesGroupedProvider(args));
    final l10n = AppLocalizations.of(context);
    if (result == null) {
      _showToast(
        l10n.ideRevertConfirmTitle,
        repoRefusalOf(l10n, refusal) ?? l10n.ideRevertFailed,
      );
    } else if (result.skipped.isNotEmpty) {
      _showToast(
        l10n.ideRevertConfirmTitle,
        l10n.ideRevertSomeSkipped(result.skipped.length),
      );
    }
  }

  void _showToast(String title, String body) {
    CcToastScope.maybeOf(
      _host.context,
    )?.show('$title — $body', variant: CcToastVariant.neutral);
  }

  /// Opens the tapped agent run.
  ///
  /// A SUBAGENT run gets its own activity tab: its work never becomes chat
  /// messages, so the conversation cannot show it. A top-level run's activity
  /// IS the conversation (bubbles, composer, steering, follow-mode), so that
  /// just brings the chat forward — reachable the other way via the row's
  /// context menu when the raw timeline is what you want.
  void openAgentRun(AgentRunTarget target) {
    if (target.isSubAgent) {
      openAgentActivity(target);
      return;
    }
    final spaceId = _host.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final layout = _host.layout;
    // Focus, never re-open: `openTab`'s dedupe REPLACES the tab instance,
    // which would tear down the live chat body.
    if (!layout.focusTab((t) => t.kind == MessagingTabKinds.chat)) {
      layout.openInActiveLeaf(MessagingIdeTabs.chat(spaceId));
    }
  }

  /// Opens (or refocuses) a run-scoped activity tab.
  ///
  /// `focusTab` first for the same reason as above: a harmless re-tap must not
  /// drop the pane's live subscription and scroll position.
  void openAgentActivity(AgentRunTarget target) {
    final spaceId = _host.selectedSpaceId;
    final workspaceId = _host.activeWorkspaceId;
    if (spaceId == null || workspaceId == null) {
      return;
    }
    final layout = _host.layout;
    final found = layout.focusTab(
      (t) =>
          t.kind == MessagingTabKinds.agentActivity &&
          t.args['runId'] == target.runId,
    );
    if (found) {
      return;
    }
    layout.openInActiveLeaf(
      agentActivityTab(
        workspaceId: workspaceId,
        spaceId: spaceId,
        runId: target.runId,
        agentId: target.agentId,
        label: target.label,
        fallbackLabel: AppLocalizations.of(_host.context).ideAgentActivity,
      ),
    );
  }

  /// Opens the subagent run a transcript's `task` cell spawned. A method
  /// tear-off (equal across builds) so `RunActivityOpenerScope` does not
  /// notify every transcript cell on each layout rebuild.
  void openSubagentRun({required String runId, required String label}) =>
      openAgentActivity((
        agentId: '',
        runId: runId,
        label: label,
        isSubAgent: true,
      ));

  /// Opens the output captured for an agent command of this space. Focusing
  /// an existing tab must not replace its viewer and restart polling.
  void openAgentShell(AgentShellProcess process) {
    final workspaceId = _host.activeWorkspaceId;
    final spaceId = _host.selectedSpaceId;
    if (workspaceId == null ||
        spaceId == null ||
        process.workspaceId != workspaceId ||
        process.spaceId != spaceId) {
      return;
    }
    final tab = agentShellOutputTab(
      process: process,
      fallbackLabel: AppLocalizations.of(_host.context).shellOutput,
    );
    final layout = _host.layout;
    if (layout.focusTab((candidate) => candidate.dedupKey == tab.dedupKey)) {
      return;
    }
    layout.openInActiveLeaf(tab);
  }

  /// Opens/focuses a conversation's chat tab (the pane's
  /// `onSelectConversation`: opening a thread, starting one).
  ///
  /// The seeded chat tab carries no conversation arg (it renders whatever the
  /// space's standing conversation resolves to), so selecting THAT
  /// conversation must focus it rather than open a second tab onto the same
  /// stream. The standing id is already resolved by the pane that is asking,
  /// so reading the provider here is a cache hit.
  void openConversation(String spaceId, String conversationId) {
    final standingId = _host.ref
        .read(standingConversationIdProvider(spaceId))
        .value;
    final layout = _host.layout;
    final found = layout.focusTab(
      (t) =>
          t.kind == MessagingTabKinds.chat &&
          (t.args['conversationId'] == conversationId ||
              (t.args['conversationId'] == null &&
                  t.args['spaceId'] == spaceId &&
                  conversationId == standingId)),
    );
    if (!found) {
      layout.openInActiveLeaf(
        MessagingIdeTabs.chat(spaceId, conversationId: conversationId),
      );
    }
  }

  /// Opens (or refocuses) the editor tab for durable goal [goalId].
  void openGoal(String goalId) {
    final workspaceId = _host.activeWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    final layout = _host.layout;
    if (layout.focusTab(
      (t) => t.kind == MessagingTabKinds.goal && t.args['goalId'] == goalId,
    )) {
      return;
    }
    final title = _host.ref
        .read(goalRunViewProvider((workspaceId: workspaceId, id: goalId)))
        .value
        ?.goal
        .userText;
    layout.openInActiveLeaf(
      goalTab(
        workspaceId: workspaceId,
        goalId: goalId,
        label: goalTabLabel(_host.context, title),
      ),
    );
  }

  /// [openConversation] bound to one space, interned so a chat tab's pane
  /// gets the SAME callback on every layout rebuild instead of a fresh
  /// closure that defeats its rebuild short-circuits.
  void Function(String conversationId) conversationOpenerFor(String spaceId) =>
      _conversationOpeners.putIfAbsent(
        spaceId,
        () =>
            (conversationId) => openConversation(spaceId, conversationId),
      );

  final _conversationOpeners = <String, void Function(String)>{};

  /// Shows the shell [sessionId]: its tab if one is open anywhere in the
  /// tree, otherwise a tab that re-claims that very session.
  ///
  /// The id matters. A row in the TERMINALS list can name a shell whose tab
  /// was closed while a command kept running, and the tab this opens carries
  /// its session id — so the pane re-claims the live controller from the
  /// registry, scrollback and all, instead of spawning a blank shell beside
  /// the one still working.
  void focusOrOpenTerminal(String sessionId) {
    final layout = _host.layout;
    bool showsSession(EditorTab t) =>
        t.kind == MessagingTabKinds.terminal &&
        t.args['termSessionId'] == sessionId;
    if (layout.focusTab(showsSession)) {
      return;
    }
    final kept = _host.terminals.keptSession(sessionId);
    layout.openInActiveLeaf(
      kept == null
          ? MessagingIdeTabs.newTerminal()
          : MessagingIdeTabs.terminal(sessionId, backend: kept.backend),
    );
  }

  /// Ends the shell [sessionId] — a TERMINALS row's trash. No confirmation:
  /// the trash is the explicit, targeted version of the question the tab's ×
  /// asks (see `IdeTerminalSessions.end`).
  void killTerminal(String sessionId) {
    final tab = _host.terminals.end(sessionId);
    if (tab != null) {
      _host.layout.closeTabByIdentity(tab);
      return;
    }
    _publishTerminals();
  }
}
