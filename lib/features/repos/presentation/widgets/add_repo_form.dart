import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/server_providers.dart'
    show gitRepoInspectorPortProvider;
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Form that registers a repo by pointing at a local git checkout.
///
/// The user picks a folder; the form runs `git remote get-url origin` to
/// resolve the GitHub owner/repo and the current branch, then persists the
/// repo and reports the new id via [onCreated].
class AddRepoForm extends ConsumerStatefulWidget {
  /// Creates an [AddRepoForm].
  const AddRepoForm({
    super.key,
    required this.workspaceId,
    required this.onCreated,
    this.onCancel,
    this.submitLabel = 'Add repository',
  });

  /// The workspace the new repo is linked to. Supplied by the caller from the
  /// route's `:workspaceId` — never resolved implicitly — so the repo always
  /// lands in the workspace the user is actually viewing.
  final String workspaceId;

  /// Called after the repo row is inserted, with the new repo id.
  final void Function(String repoId) onCreated;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  /// Label of the submit button.
  final String submitLabel;

  @override
  ConsumerState<AddRepoForm> createState() => _AddRepoFormState();
}

class _AddRepoFormState extends ConsumerState<AddRepoForm> {
  GitRepoInfo? _info;
  String? _error;
  bool _inspecting = false;
  bool _saving = false;

  Future<void> _pickFolder() async {
    setState(() {
      _error = null;
      _inspecting = true;
    });
    try {
      final path = await getDirectoryPath();
      if (path == null) {
        setState(() => _inspecting = false);
        return;
      }
      final inspector = ref.read(gitRepoInspectorPortProvider);
      final info = await inspector.inspect(path);
      setState(() {
        _info = info;
        _inspecting = false;
      });
    } on GitRepoInspectionException catch (e) {
      setState(() {
        _error = e.message;
        _inspecting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to inspect repository: $e';
        _inspecting = false;
      });
    }
  }

  Future<void> _submit() async {
    final info = _info;
    if (info == null) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Register over RPC: the host inspects + registers the checkout and links
      // it to the bound (active) workspace, firing `RepoAdded` server-side so the
      // code-indexing pipeline runs. The desktop is a thin client and owns no DB,
      // so it never registers locally. The native folder picker + git inspection
      // above resolve a path on the desktop's machine — which IS the server's
      // machine in the default self-serve setup.
      final register = ref.read(addRepoFromServerPathProvider);
      final repoId = await register(info.path);
      if (!mounted) {
        return;
      }

      widget.onCreated(repoId);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to register repository: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final info = _info;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        CcButton(
          onPressed: _inspecting || _saving ? null : _pickFolder,
          variant: info == null
              ? CcButtonVariant.primary
              : CcButtonVariant.secondary,
          child: Text(
            info == null ? 'Choose repository folder' : 'Change folder',
          ),
        ),
        if (_inspecting) ...[
          const SizedBox(height: 12),
          const Center(child: CcSpinner()),
        ],
        if (info != null) ...[
          const SizedBox(height: 16),
          _RepoSummary(info: info),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onCancel != null) ...[
              CcButton(
                onPressed: _saving ? null : widget.onCancel,
                variant: CcButtonVariant.ghost,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
            ],
            CcButton(
              onPressed: info == null || _saving ? null : _submit,
              child: Text(_saving ? 'Adding…' : widget.submitLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _RepoSummary extends StatelessWidget {
  const _RepoSummary({required this.info});

  final GitRepoInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        children: [
          GitHubUserAvatar(
            login: info.owner,
            avatarUrl: 'https://github.com/${info.owner}.png',
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.owner}/${info.repoName}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  info.branch.isEmpty
                      ? info.path
                      : '${info.branch} • ${info.path}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the add-repo dialog. Returns the new repo id, or null when cancelled.
///
/// [ref] is accepted for signature parity with the web variant (which needs it
/// to bridge the root-overlay `ProviderScope`); the desktop form reads its own
/// providers in-tree, where the app's `ProviderScope` is the root ancestor.
Future<String?> showAddRepoDialog(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) {
  final l10n = AppLocalizations.of(context);
  return showCcDialog<String?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addRepository,
      content: SizedBox(
        width: 420,
        child: AddRepoForm(
          workspaceId: workspaceId,
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}
