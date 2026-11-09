import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:flutter/foundation.dart';

/// The tabs the messaging IDE opens, built in one place so a tab and every
/// route that reopens it (a sidebar row, a deep link, the `[+]` menu) agree
/// about its args and its `?tab=` identity ([EditorTab.dedupKey]).
// ignore: avoid_classes_with_only_static_members
abstract final class MessagingIdeTabs {
  /// A chat tab for one conversation (stream) inside [spaceId].
  ///
  /// `dedupKey: 'chat:<conversationId>'` makes each conversation unique per
  /// group so re-opening it refocuses the existing tab instead of stacking,
  /// while distinct conversations each get their own tab.
  ///
  /// [conversationId] null means "the space's standing conversation" and the
  /// tab carries NO conversation arg — the pane resolves it. It is never
  /// substituted with the space id: that value names no conversation row.
  static EditorTab chat(
    String spaceId, {
    String? conversationId,
    String? title,
  }) => EditorTab(
    kind: MessagingTabKinds.chat,
    label: title ?? 'Chat',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.chat),
    args: {'spaceId': spaceId, 'conversationId': ?conversationId},
    dedupKey: conversationId == null
        ? MessagingTabKinds.chatSpaceTabKey(spaceId)
        : MessagingTabKinds.chatTabKey(conversationId),
  );

  /// A fresh terminal tab. With [backend] `'microvm'` the shell opens inside
  /// the conversation's enclosed VM instead of on the host.
  ///
  /// [initialInput] is typed at the first prompt and left there, never run.
  static EditorTab newTerminal({String? backend, String? initialInput}) =>
      terminal(
        'ide-terminal-${DateTime.now().microsecondsSinceEpoch}',
        backend: backend,
        initialInput: initialInput,
      );

  /// The terminal tab showing session [sessionId]. Keyed by the session so
  /// `?tab=` names this shell rather than whichever terminal comes first.
  static EditorTab terminal(
    String sessionId, {
    String? backend,
    String? initialInput,
  }) => EditorTab(
    kind: MessagingTabKinds.terminal,
    label: 'Terminal',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
    // Stable id so the tab re-claims its kept session from the registry
    // after a space switch (the arg round-trips through the persisted
    // layout snapshot). The backend rides in args so a restored layout
    // reopens the shell where it was, not silently on the host.
    args: {
      'termSessionId': sessionId,
      'backend': ?backend,
      'initialInput': ?initialInput,
    },
    dedupKey: '${MessagingTabKinds.terminal}:$sessionId',
  );

  /// A terminal tab attached to an environment process [sessionId] (or, with
  /// [setup], to its setup run).
  static EditorTab environmentTerminal(
    String sessionId,
    String label, {
    bool setup = false,
  }) {
    final tabSessionId = 'environment-$sessionId';
    return EditorTab(
      kind: MessagingTabKinds.terminal,
      label: label,
      icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
      args: {
        'termSessionId': tabSessionId,
        'attachSessionId': sessionId,
        if (setup) kEnvironmentSetupTabArg: true,
      },
      dedupKey: '${MessagingTabKinds.terminal}:$tabSessionId',
    );
  }

  /// Name for a browser tab + its menu entry. Desktop has a real in-app
  /// webview ("Web browser"); web only has a plain iframe ("Simple web
  /// browser").
  static String browserLabel(AppLocalizations l10n) =>
      kIsWeb ? l10n.ideSimpleWebBrowser : l10n.ideWebBrowser;

  /// A new, blank host browser tab — always its own instance.
  static EditorTab newBrowser(AppLocalizations l10n) => EditorTab(
    kind: MessagingTabKinds.browser,
    label: browserLabel(l10n),
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.browser),
    dedupKey: instanceTabKey(MessagingTabKinds.browser),
  );

  /// A host browser tab on [url], one per address.
  static EditorTab browserAt({required String url, required String label}) =>
      EditorTab(
        kind: MessagingTabKinds.browser,
        label: label,
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.browser),
        args: {'url': url},
        dedupKey: '${MessagingTabKinds.browser}:$url',
      );

  /// The logs of an environment [target] in [spaceId].
  static EditorTab environmentLogs({
    required String? workspaceId,
    required String spaceId,
    required String target,
    required String label,
  }) => EditorTab(
    kind: MessagingTabKinds.environmentLogs,
    label: label,
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.environmentLogs),
    args: {'workspaceId': workspaceId, 'spaceId': spaceId, 'target': target},
    dedupKey: '${MessagingTabKinds.environmentLogs}:$spaceId:$target',
  );

  /// The provisioning (setup) logs of [spaceId].
  static EditorTab provisioningLogs({
    required String? workspaceId,
    required String spaceId,
    required String label,
  }) => EditorTab(
    kind: MessagingTabKinds.provisioningLogs,
    label: label,
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.provisioningLogs),
    args: {'workspaceId': workspaceId, 'spaceId': spaceId},
    dedupKey: '${MessagingTabKinds.provisioningLogs}:$spaceId',
  );

  /// The conversation's code-server editor on its worktree, with no file:
  /// one per worktree, so a re-open refocuses the running instance.
  static EditorTab codeServerEditor({
    required String spaceId,
    required String? repoId,
    required String label,
  }) => EditorTab(
    kind: MessagingTabKinds.codeServer,
    label: label,
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.codeServer),
    args: {'spaceId': spaceId, 'repoId': ?repoId},
    dedupKey: MessagingTabKinds.codeServerWorktreeTabKey,
  );

  /// The code-server tab for one worktree file — one editor per file.
  static EditorTab worktreeFile({
    required String spaceId,
    required ({String repoId, String path}) target,
    required String fallbackLabel,
  }) {
    final fileName = target.path.split('/').last;
    return EditorTab(
      kind: MessagingTabKinds.codeServer,
      // Name the tab after the file the editor was opened with (the entry
      // file); falls back to the generic label when there's no path.
      label: fileName.isEmpty ? fallbackLabel : fileName,
      icon: MessagingTabKinds.iconFor(MessagingTabKinds.codeServer),
      args: {
        'spaceId': spaceId,
        if (target.repoId.isNotEmpty) 'repoId': target.repoId,
        'path': target.path,
      },
      // One editor per file (the refocus matches on path), so the path is its
      // `?tab=` identity — same shape as the PR workbench's editors.
      dedupKey: '${MessagingTabKinds.codeServer}:${target.path}',
    );
  }

  /// The lightweight read-only view of a worktree file (the Explorer's
  /// "Quick view").
  static EditorTab fileQuickView({
    required ({String repoId, String path}) target,
    required String? spaceId,
  }) => EditorTab(
    kind: MessagingTabKinds.file,
    label: target.path.split('/').last,
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.file),
    args: {
      'repoId': target.repoId,
      'path': target.path,
      // The quick view reads the conversation's own worktree — the copy the
      // Explorer listed.
      'spaceId': ?spaceId,
    },
    // Keyed by file, so `?tab=` names it and viewing the same file again
    // refocuses rather than stacking a second identical read-only copy.
    dedupKey: '${MessagingTabKinds.file}:${target.repoId}:${target.path}',
  );

  /// The multi-file "Review code" tab for a repo, anchored to the clicked
  /// file. One review tab per (spaceId, repoId), so re-clicking another file
  /// in the same repo re-anchors it.
  static EditorTab review({
    required String? spaceId,
    required ({String repoId, String repoFullName, PrFile file}) target,
    required String label,
  }) => EditorTab(
    kind: MessagingTabKinds.review,
    label: label,
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.review),
    dedupKey: 'review:${spaceId ?? ''}:${target.repoId}',
    args: {
      'spaceId': ?spaceId,
      'repoId': target.repoId,
      'anchorPath': target.file.filename,
    },
  );
}
