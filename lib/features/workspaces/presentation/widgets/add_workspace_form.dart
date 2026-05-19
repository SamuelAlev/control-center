import 'dart:io';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Form that creates a workspace.
///
/// The user supplies a name and, optionally, a local image to use as the
/// workspace logo. Repositories are added later from Settings → Repositories.
class AddWorkspaceForm extends ConsumerStatefulWidget {
  /// Creates an [AddWorkspaceForm].
  const AddWorkspaceForm({
    super.key,
    required this.onCreated,
    this.onCancel,
    this.submitLabel = 'Add workspace',
  });

  /// Called after the workspace row is inserted, with the new workspace id.
  final void Function(String workspaceId) onCreated;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  /// Label of the submit button.
  final String submitLabel;

  @override
  ConsumerState<AddWorkspaceForm> createState() => _AddWorkspaceFormState();
}

class _AddWorkspaceFormState extends ConsumerState<AddWorkspaceForm> {
  final _nameController = TextEditingController();
  String? _logoPath;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context);
    final typeGroup = XTypeGroup(
      label: l10n.images,
      extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }

    setState(() => _logoPath = file.path);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final id = await ref
        .read(createWorkspaceProvider.notifier)
        .create(name: name, logoPath: _logoPath);
    if (!mounted) {
      return;
    }
    if (id != null) {
      widget.onCreated(id);
    } else {
      final asyncVal = ref.read(createWorkspaceProvider);
      setState(() {
        _saving = false;
        _error = 'Failed to create workspace: ${asyncVal.error ?? 'Unknown error'}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LogoPicker(
          path: _logoPath,
          onPick: _saving ? null : _pickLogo,
          onClear: _logoPath == null || _saving
              ? null
              : () => setState(() => _logoPath = null),
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _nameController),
          label: Text(l10n.workspaceName),
          hint: l10n.egPlatform,
          enabled: !_saving,
        ),
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
              onPress: _saving ? null : _submit,
              mainAxisSize: MainAxisSize.min,
              child: Text(_saving ? 'Adding…' : widget.submitLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final String? path;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.designSystem;
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          InkWell(
            onTap: onPick,
            borderRadius: AppRadii.brSm,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppRadii.brSm,
                border: Border.all(color: tokens?.borderSecondary ?? colorScheme.outlineVariant),
                image: path != null
                    ? DecorationImage(
                        image: FileImage(File(path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: path == null
                  ? Icon(LucideIcons.image, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Workspace logo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path == null ? 'Optional. Pick a local image file.' : path!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens?.textTertiary,
                    height: 1.45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onClear != null)
            FTooltip(
              tipBuilder: (_, _) => Text(l10n.removeLogo),
              child: FButton.icon(
                onPress: onClear,
                child: const Icon(LucideIcons.x, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
