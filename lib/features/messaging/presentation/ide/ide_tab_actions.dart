import 'dart:async';

import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_host.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_rig_host.dart';
import 'package:control_center/features/messaging/presentation/widgets/rename_conversation_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/services.dart';

/// The messaging IDE's per-tab context-menu actions: rename / archive a
/// conversation, restart a shell, copy a file's path and a rig's audio
/// controls.
class IdeTabActions {
  /// Creates the actions for the tabs of the IDE behind [_host].
  IdeTabActions(this._host);

  final IdeHost _host;

  /// Context-menu extras per tab kind: a chat tab gets "Rename conversation"
  /// and "Archive conversation"; a terminal tab gets "Restart shell"; a file
  /// tab gets Copy path / Copy relative path; a rig tab its audio controls.
  List<CcMenuItem> contextMenuExtras(EditorTab tab) {
    final context = _host.context;
    if (tab.kind == MessagingTabKinds.rig) {
      return IdeRigHost.contextMenuItems(
        context: context,
        ref: _host.ref,
        tab: tab,
      );
    }
    final l10n = AppLocalizations.of(context);
    if (tab.kind == MessagingTabKinds.chat) {
      final conv = _host.conversations.conversationOf(tab);
      return [
        CcMenuItem(
          label: l10n.renameConversation,
          enabled: conv != null,
          onSelected: () => unawaited(renameConversation(tab)),
        ),
        CcMenuItem(
          label: l10n.archiveConversation,
          // The last active conversation stays: a space always keeps one live
          // stream (archiving it would just mint a fresh standing one).
          enabled:
              conv != null &&
              !conv.isArchived &&
              _host.conversations.activeCount > 1,
          onSelected: () => unawaited(archiveConversation(tab)),
        ),
      ];
    }
    if (tab.kind == MessagingTabKinds.terminal) {
      final controller = _host.terminals.controllerFor(tab);
      return [
        CcMenuItem(
          label: l10n.restartShell,
          enabled: controller != null && !controller.booting,
          onSelected: () => unawaited(controller?.restart()),
        ),
      ];
    }
    final relative = tab.args['path'] as String?;
    if (relative == null || relative.isEmpty) {
      return const [];
    }
    return [
      CcMenuItem(
        label: l10n.copyPath,
        onSelected: () => copyAbsolutePath(tab, relative),
      ),
      CcMenuItem(
        label: l10n.copyRelativePath,
        onSelected: () => copyToClipboard(relative),
      ),
    ];
  }

  /// Renames the conversation a chat [tab] shows. The dialog can ask the
  /// workspace's content synthesizer for a title; the tab label follows the
  /// live conversation watch.
  Future<void> renameConversation(EditorTab tab) async {
    final workspaceId = _host.activeWorkspaceId;
    final conv = _host.conversations.conversationOf(tab);
    if (workspaceId == null || conv == null) {
      return;
    }
    final ref = _host.ref;
    final title = await showRenameConversationDialog(
      _host.context,
      initialValue: conv.title,
      suggest: () => ref
          .read(conversationTitlePortProvider)
          .suggestTitle(workspaceId: workspaceId, conversationId: conv.id),
    );
    if (title == null || !_host.mounted) {
      return;
    }
    await ref
        .read(conversationRepositoryProvider)
        .rename(
          workspaceId: workspaceId,
          conversationId: conv.id,
          title: title,
        );
  }

  /// Archives the conversation a chat [tab] shows and closes the tab: the
  /// conversation leaves the global sidebar's rows and the space's tab strip
  /// (both filter to active conversations), and the space-open tab mirror
  /// never re-opens it.
  Future<void> archiveConversation(EditorTab tab) async {
    final workspaceId = _host.activeWorkspaceId;
    final conv = _host.conversations.conversationOf(tab);
    if (workspaceId == null || conv == null) {
      return;
    }
    await _host.ref
        .read(conversationRepositoryProvider)
        .setStatus(
          workspaceId: workspaceId,
          conversationId: conv.id,
          status: ConversationStatus.archived,
        );
    if (_host.mounted) {
      _host.layout.closeTabByIdentity(tab);
    }
  }

  /// Copies the file's absolute on-disk path — the isolated copy-on-write
  /// worktree the workbench actually edits when the tab is backed by a space
  /// worktree, else the repo's main working tree.
  Future<void> copyAbsolutePath(EditorTab tab, String relative) async {
    final worktree = await _worktreeBaseFor(tab);
    if (!_host.mounted) {
      return;
    }
    final base = worktree ?? _mainRepoPath(tab);
    final absolute = base == null
        ? relative
        : (base.endsWith('/') ? '$base$relative' : '$base/$relative');
    copyToClipboard(absolute);
  }

  /// The isolated worktree root for [tab]'s `(space, repo)` on the server, or
  /// null when the tab isn't backed by a space worktree (e.g. a read-only
  /// main-repo file view, which carries no space id).
  Future<String?> _worktreeBaseFor(EditorTab tab) async {
    final repoId = tab.args['repoId'] as String?;
    final spaceId = tab.args['spaceId'] as String?;
    if (repoId == null || spaceId == null) {
      return null;
    }
    final isolated = await _host.ref
        .read(isolatedRepoRepositoryProvider)
        .forUnitRepo(_host.hostWorkspaceId, spaceId, repoId);
    return isolated?.path;
  }

  /// The repo's main working-tree path for [tab] — the fallback when there is
  /// no isolated worktree (or the repo can't be resolved).
  String? _mainRepoPath(EditorTab tab) {
    final repoId = tab.args['repoId'] as String?;
    if (repoId == null) {
      return null;
    }
    final repos =
        _host.ref
            .read(reposForWorkspaceProvider(_host.hostWorkspaceId))
            .value ??
        const [];
    for (final repo in repos) {
      if (repo.id == repoId) {
        return repo.path;
      }
    }
    return null;
  }

  /// Copies [text] and confirms with a toast.
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (_host.mounted) {
      final context = _host.context;
      CcToastScope.of(context).show(
        AppLocalizations.of(context).copied,
        variant: CcToastVariant.success,
      );
    }
  }
}
