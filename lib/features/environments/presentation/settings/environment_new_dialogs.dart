import 'dart:convert';

import 'package:cc_data/cc_data.dart' show EnvironmentDraft;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proposes a definition from a repo, opened in the editor unsaved.
Future<void> showEnvironmentDraftDialog(
  BuildContext context, {
  required String workspaceId,
}) => showCcDialog<void>(
  context: context,
  builder: (_) => _RepoDialog(workspaceId: workspaceId, askPath: false),
);

/// Links a definition to a file on a repo's default branch.
Future<void> showEnvironmentLinkDialog(
  BuildContext context, {
  required String workspaceId,
}) => showCcDialog<void>(
  context: context,
  builder: (_) => _RepoDialog(workspaceId: workspaceId, askPath: true),
);

class _RepoDialog extends ConsumerStatefulWidget {
  const _RepoDialog({required this.workspaceId, required this.askPath});

  final String workspaceId;

  /// Link a file rather than scan the repo.
  final bool askPath;

  @override
  ConsumerState<_RepoDialog> createState() => _RepoDialogState();
}

class _RepoDialogState extends ConsumerState<_RepoDialog> {
  final _path = TextEditingController(text: '.cc/environment.json');
  String? _repoId;
  String? _error;
  bool _busy = false;

  /// The repo each of the file's roles binds to in this workspace.
  final Map<String, String> _bindings = {};

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repoId = _repoId;
    if (repoId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(environmentRepositoryProvider);
    try {
      final EnvironmentEditorSeed seed;
      if (widget.askPath) {
        final record = await repository.approveSource(
          widget.workspaceId,
          repoId: repoId,
          path: _path.text.trim(),
          overrides: _bindings.isEmpty
              ? null
              : {
                  'repos': {
                    for (final entry in _bindings.entries)
                      entry.key: {'repoId': entry.value},
                  },
                },
        );
        ref.invalidate(environmentDefinitionsProvider(widget.workspaceId));
        seed = EnvironmentEditorSeed.record(record);
      } else {
        final EnvironmentDraft draft = await repository.draftDefinition(
          widget.workspaceId,
          repoId,
        );
        seed = EnvironmentEditorSeed(
          workspaceId: widget.workspaceId,
          draft: draft.definition,
          notes: draft.notes,
        );
      }
      if (mounted) {
        openEnvironmentEditor(context, ref, seed);
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = environmentFailureMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    final error = _error;
    return CcDialog(
      title: widget.askPath
          ? l10n.environmentsLinkFile
          : l10n.environmentsDraftFromRepo,
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcSelect<String>(
            label: l10n.prPropertyRepository,
            value: _repoId,
            options: [
              for (final repo in repos)
                CcSelectOption(value: repo.id, label: repo.name),
            ],
            onChanged: (value) => setState(() {
              _repoId = value;
              _bindings.clear();
            }),
          ),
          if (widget.askPath) ...[
            const SizedBox(height: AppSpacing.md),
            // RTL carve-out: a repo path reads left to right.
            Directionality(
              textDirection: TextDirection.ltr,
              child: CcTextField(
                controller: _path,
                label: l10n.environmentsLinkPath,
                helperText: l10n.environmentsLinkHelp,
                onChanged: (_) => setState(_bindings.clear),
              ),
            ),
            if (_repoId != null)
              _RoleBindings(
                workspaceId: widget.workspaceId,
                repoId: _repoId!,
                path: _path.text.trim(),
                repos: repos,
                bindings: _bindings,
                onChanged: (role, repoId) =>
                    setState(() => _bindings[role] = repoId),
              ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(variant: CcAlertVariant.danger, title: error),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: _repoId == null || _busy ? null : _submit,
          child: Text(
            widget.askPath
                ? l10n.environmentsLinkConfirm
                : l10n.environmentsDraftFromRepo,
          ),
        ),
      ],
    );
  }
}

/// The roles a linked file declares, each bound to one of this workspace's
/// repos. The file can't know the workspace's repo ids, so these become its
/// `overrides.repos.<role>.repoId`.
class _RoleBindings extends ConsumerWidget {
  const _RoleBindings({
    required this.workspaceId,
    required this.repoId,
    required this.path,
    required this.repos,
    required this.bindings,
    required this.onChanged,
  });

  final String workspaceId;
  final String repoId;
  final String path;
  final List<Repo> repos;
  final Map<String, String> bindings;
  final void Function(String role, String repoId) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (path.isEmpty) {
      return const SizedBox.shrink();
    }
    final file = ref.watch(
      repoFileContentProvider((
        workspaceId: workspaceId,
        repoId: repoId,
        path: path,
        spaceId: null,
      )),
    );
    final roles = file.whenOrNull(data: (read) => _roles(read.content));
    if (roles == null || roles.isEmpty) {
      return file.isLoading
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.environmentsLinkNoFile,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            );
    }
    final ids = {for (final repo in repos) repo.id};
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.environmentsLinkRoles,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          for (final entry in roles.entries)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: CcSelect<String>(
                label: entry.key,
                value:
                    bindings[entry.key] ??
                    (ids.contains(entry.value) ? entry.value : null),
                options: [
                  for (final repo in repos)
                    CcSelectOption(value: repo.id, label: repo.name),
                ],
                onChanged: (value) => onChanged(entry.key, value),
              ),
            ),
        ],
      ),
    );
  }

  /// Role name to the repo id the file names, from the file's JSON.
  static Map<String, String> _roles(String content) {
    try {
      final json = jsonDecode(content);
      final repos = json is Map ? json['repos'] : null;
      if (repos is! Map) {
        return const {};
      }
      return {
        for (final entry in repos.entries)
          '${entry.key}': entry.value is Map
              ? '${(entry.value as Map)['repoId'] ?? ''}'
              : '',
      };
    } on FormatException {
      return const {};
    }
  }
}
