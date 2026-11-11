import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_close.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_dirty_support.dart';
import 'package:control_center/shared/editor/editor_live_close.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What [TabCloseGuard] reads from the messaging IDE whose tabs it guards.
abstract interface class TabCloseHost {
  /// A context under the IDE, for the prompts.
  BuildContext get context;

  /// Whether the IDE is still mounted; prompts are async.
  bool get mounted;

  /// The IDE's provider access.
  WidgetRef get ref;

  /// The workspace the IDE shows.
  String? get closeGuardWorkspaceId;

  /// The space the IDE shows.
  String? get closeGuardSpaceId;

  /// The conversation a chat tab with no id of its own stands for.
  String? get closeGuardStandingConversationId;

  /// Whether [tab] is a file tab with unsaved changes.
  bool isTabDirty(EditorTab tab);

  /// The live shell behind a terminal [tab], if one is attached.
  TerminalSessionController? terminalFor(EditorTab tab);

  /// Keeps [tab]'s shell running after the tab closes.
  void keepShell(EditorTab tab);

  /// Archives the conversation a chat [tab] shows, which is closing.
  /// [agentsStopped] says its agents were just stopped from the close prompt,
  /// so a busy mark that has not caught up yet does not keep it.
  void archiveClosedConversation(EditorTab tab, {bool agentsStopped = false});

  /// The label a terminal [tab] shows.
  String terminalLabel(EditorTab tab, AppLocalizations l10n);

  /// The label a chat [tab] shows.
  String chatLabel(EditorTab tab, AppLocalizations l10n);
}

/// The messaging IDE's tab-close confirmations: unsaved files, a booted rig,
/// a shell running a command and a conversation with agents at work. A user
/// close of a chat tab also archives its conversation; tabs leaving the tree
/// any other way (a drag, a space switch, an archive elsewhere) never pass
/// through here.
class TabCloseGuard {
  /// Creates the guard for the tabs of the IDE behind a [TabCloseHost].
  TabCloseGuard(this._host);

  final TabCloseHost _host;

  /// Close interceptor for every tab: live work behind it is asked about
  /// first; then a clean file tab closes immediately and a dirty one runs the shared Save / Don't save / Cancel prompt, saving via the
  /// embedded editor (the buffer's only holder) on Save.
  Future<bool> confirmClose(EditorTab tab) async {
    if (!await _confirmCloseLiveWork(tab)) {
      return false;
    }
    // The first prompt is async, so this state can be gone by now — and an
    // unmounted layout has no tab left to close.
    if (!_host.mounted) {
      return false;
    }
    final context = _host.context;
    if (!context.mounted || !_host.isTabDirty(tab)) {
      return context.mounted;
    }
    final path = tab.args['path'] as String? ?? '';
    return confirmCloseDirtyEditorTab(
      context: context,
      isDirty: true,
      fileName: path.isEmpty ? tab.label : path.split('/').last,
      onSave: () async {
        final spaceId = tab.args['spaceId'] as String?;
        if (spaceId != null && path.isNotEmpty) {
          await saveCodeServerFile(
            _host.ref.read(rpcClientProvider),
            spaceId: spaceId,
            repoId: tab.args['repoId'] as String?,
            path: path,
          );
        }
      },
      // The editor window outlives the tab now, so the unsaved buffer has to
      // be discarded explicitly.
      onDontSave: () async {
        final spaceId = tab.args['spaceId'] as String?;
        if (spaceId != null && path.isNotEmpty) {
          await closeCodeServerFile(
            _host.ref.read(rpcClientProvider),
            spaceId: spaceId,
            repoId: tab.args['repoId'] as String?,
            path: path,
            revert: true,
          );
        }
      },
    );
  }

  /// Asks what to do with the live work behind [tab] before it closes, and
  /// carries out the answer. Returns whether the close may proceed.
  ///
  /// Only tabs that are ACTUALLY busy prompt — a machine that is up, a shell
  /// with a command in the foreground, a conversation an agent is working in.
  /// A rig tab nobody started, a shell at its prompt and a quiet conversation
  /// close the way they always have, because a confirmation that fires on
  /// every close is one people learn to dismiss without reading, and it would
  /// fire on the ones that cost nothing.
  Future<bool> _confirmCloseLiveWork(EditorTab tab) async {
    final l10n = AppLocalizations.of(_host.context);
    return switch (tab.kind) {
      MessagingTabKinds.rig => _confirmCloseRig(tab, l10n),
      MessagingTabKinds.terminal => _confirmCloseTerminal(tab, l10n),
      MessagingTabKinds.chat => _confirmCloseConversation(tab, l10n),
      _ => Future.value(true),
    };
  }

  /// The rig tab's machine: keep it running (reopen from the sidebar) or shut
  /// it down now. Nothing booted → nothing to ask about.
  Future<bool> _confirmCloseRig(EditorTab tab, AppLocalizations l10n) =>
      confirmCloseLiveRigTab(
        context: _host.context,
        ref: _host.ref,
        title: l10n.ideCloseKeepTitle(tab.label),
        workspaceId: _host.closeGuardWorkspaceId,
        conversationId: _host.closeGuardSpaceId,
        args: tab.args,
      );

  /// The terminal tab's shell: asked about only while a command holds the
  /// foreground. A shell at its prompt is closed and killed exactly as before
  /// — keeping every idle shell alive would fill the registry's six slots with
  /// prompts nobody is coming back to.
  Future<bool> _confirmCloseTerminal(
    EditorTab tab,
    AppLocalizations l10n,
  ) async {
    final controller = _host.terminalFor(tab);
    if (controller == null ||
        !controller.isRunningCommand ||
        tab.args['attachSessionId'] != null) {
      // An environment process outlives its tab, so closing costs nothing.
      return true;
    }
    final choice = await confirmCloseLiveTab(
      context: _host.context,
      title: l10n.ideCloseKeepTitle(_host.terminalLabel(tab, l10n)),
      body: l10n.ideCloseKeepBodyShell,
      shutDownLabel: l10n.ideCloseEndShell,
    );
    switch (choice) {
      case LiveTabCloseChoice.cancel:
        return false;
      case LiveTabCloseChoice.keepRunning:
        // The reconcile that follows the close reads this and detaches the
        // session instead of killing it; the TERMINALS list keeps showing it.
        _host.keepShell(tab);
        return true;
      case LiveTabCloseChoice.shutDown:
        return true;
    }
  }

  /// The chat tab's agents: closing the tab never stopped a run, so "keep
  /// running" is the status quo — what is new is being told, and being offered
  /// the stop that was otherwise only reachable from the composer of a tab you
  /// were about to close.
  ///
  /// Closing a chat tab archives its conversation, except when the user keeps
  /// an agent running in it: the prompt promises that conversation stays in
  /// the sidebar to come back to.
  Future<bool> _confirmCloseConversation(
    EditorTab tab,
    AppLocalizations l10n,
  ) async {
    final workspaceId = _host.closeGuardWorkspaceId;
    final conversationId =
        tab.args['conversationId'] as String? ??
        _host.closeGuardStandingConversationId;
    if (workspaceId == null || conversationId == null) {
      return true;
    }
    final runs =
        _host.ref
            .read(
              conversationActiveRunsProvider((
                workspaceId: workspaceId,
                conversationId: conversationId,
              )),
            )
            .asData
            ?.value ??
        const [];
    if (runs.isEmpty) {
      _host.archiveClosedConversation(tab);
      return true;
    }
    final choice = await confirmCloseLiveTab(
      context: _host.context,
      title: l10n.ideCloseKeepTitle(_host.chatLabel(tab, l10n)),
      body: l10n.ideCloseKeepBodyAgent,
      shutDownLabel: l10n.ideCloseStopAgent,
    );
    switch (choice) {
      case LiveTabCloseChoice.cancel:
        return false;
      case LiveTabCloseChoice.keepRunning:
        return true;
      case LiveTabCloseChoice.shutDown:
        // Every run in THIS conversation — a multi-agent room can have
        // several, and stopping one of them is not what "stop" reads as.
        final messaging = _host.ref.read(messagingServiceProvider);
        for (final run in runs) {
          await messaging.stopRun(workspaceId, run.id);
        }
        if (_host.mounted) {
          _host.archiveClosedConversation(tab, agentsStopped: true);
        }
        return true;
    }
  }
}
