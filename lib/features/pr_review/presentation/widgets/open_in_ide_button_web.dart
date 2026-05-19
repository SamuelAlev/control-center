// Web "open PR in IDE" button — routes over RPC to the server host.
//
// The desktop button opens the PR's branch in a local editor directly. On web
// the browser has no editors or filesystem, so the button asks the server
// (which owns the checkout + editors) to materialize the PR's worktree and
// launch the chosen editor on its display — over the `ide.detectEditors` +
// `ide.openPrInEditor` ops. When the server reports no editors (e.g. a headless
// server with no display), the button hides itself, exactly like the desktop
// button on an unsupported platform. This keeps the worktree port + native
// editor launcher (cc_natives / server_providers) off the web compile graph.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RepoDto;
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The installed editors the server host reports (empty against a headless
/// server). Cached by Riverpod for the session.
final _serverEditorsProvider = FutureProvider.autoDispose<List<IdeEditor>>((
  ref,
) async {
  final editors = await RemoteIdeRepository(
    ref.watch(rpcClientProvider),
  ).detectEditors();
  return [
    for (final e in editors)
      if (e.installed) e,
  ];
});

/// Fallback order used to pick a default editor (file manager always last).
const List<String> _priority = [
  'cursor',
  'vscode',
  'zed',
  'windsurf',
  'antigravity',
  'intellij',
  'webstorm',
  'pycharm',
  'sublime',
  'warp',
];

IdeEditor? _effective(List<IdeEditor> installed) {
  for (final id in _priority) {
    for (final e in installed) {
      if (e.id == id) {
        return e;
      }
    }
  }
  return installed.isEmpty ? null : installed.first;
}

/// Opens a pull request's branch in an editor on the server host, over RPC.
class OpenInIdeButton extends ConsumerStatefulWidget {
  /// Creates an [OpenInIdeButton] for [pr] in [repo].
  const OpenInIdeButton({
    super.key,
    required this.pr,
    required this.repo,
    required this.workspaceId,
  });

  /// The pull request whose branch is opened.
  final PullRequest pr;

  /// The locally-registered repo the PR belongs to (the CoW source on the host).
  final Repo repo;

  /// The active workspace that owns the ephemeral worktree.
  final String workspaceId;

  @override
  ConsumerState<OpenInIdeButton> createState() => _OpenInIdeButtonState();
}

class _OpenInIdeButtonState extends ConsumerState<OpenInIdeButton> {
  bool _opening = false;

  Future<void> _open(IdeEditor editor) async {
    if (_opening) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    setState(() => _opening = true);
    try {
      await RemoteIdeRepository(ref.read(rpcClientProvider)).openPrInEditor(
        repo: RepoDto(
          id: widget.repo.id,
          name: widget.repo.name,
          path: widget.repo.path,
          githubOwner: widget.repo.githubOwner,
          githubRepoName: widget.repo.githubRepoName,
          createdAt: widget.repo.createdAt.toIso8601String(),
          updatedAt: widget.repo.updatedAt.toIso8601String(),
        ),
        prNumber: widget.pr.number,
        prHeadRef: widget.pr.headRef,
        editorId: editor.id,
      );
    } on Object catch (e) {
      toaster.show(
        l10n.failedToOpenInIde(editor.displayName, '$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed =
        ref.watch(_serverEditorsProvider).value ?? const <IdeEditor>[];
    final effective = _effective(installed);
    // No editors on the host (headless server / unsupported) → render nothing.
    if (effective == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return CcButton(
      size: CcButtonSize.sm,
      variant: CcButtonVariant.secondary,
      icon: AppIcons.code,
      onPressed: _opening ? null : () => _open(effective),
      child: Text(
        _opening ? '…' : l10n.openInIde(effective.displayName),
      ),
    );
  }
}
