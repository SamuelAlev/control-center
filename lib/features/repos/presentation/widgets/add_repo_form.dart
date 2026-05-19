import 'package:control_center/core/domain/entities/git_repo_info.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Form that registers a repo by pointing at a local git checkout.
///
/// The user picks a folder; the form runs `git remote get-url origin` to
/// resolve the GitHub owner/repo and the current branch, then persists the
/// repo and reports the new id via [onCreated].
class AddRepoForm extends ConsumerStatefulWidget {
  /// Creates an [AddRepoForm].
  const AddRepoForm({
    super.key,
    required this.onCreated,
    this.onCancel,
    this.submitLabel = 'Add repository',
  });

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
      final useCase = ref.read(addRepoFromPathUseCaseProvider);
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        setState(() {
          _saving = false;
          _error = 'No active workspace selected';
        });
        return;
      }
      final repo = await useCase.execute(info.path, workspaceId: workspaceId);
      if (!mounted) {
        return;
      }

      widget.onCreated(repo.id);
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
        FButton(
          onPress: _inspecting || _saving ? null : _pickFolder,
          variant: info == null
              ? FButtonVariant.primary
              : FButtonVariant.secondary,
          child: Text(
            info == null ? 'Choose repository folder' : 'Change folder',
          ),
        ),
        if (_inspecting) ...[
          const SizedBox(height: 12),
          const Center(child: FCircularProgress()),
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
              FButton(
                onPress: _saving ? null : widget.onCancel,
                variant: FButtonVariant.ghost,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
            ],
            FButton(
              onPress: info == null || _saving ? null : _submit,
              mainAxisSize: MainAxisSize.min,
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
Future<String?> showAddRepoDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showFDialog<String?>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.addRepository),
      body: SizedBox(
        width: 420,
        child: AddRepoForm(
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}
