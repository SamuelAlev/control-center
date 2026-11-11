import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    this.layout,
    this.initialName,
  });

  /// Called after the workspace row is inserted, with the new workspace id.
  final void Function(String workspaceId) onCreated;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  /// Label of the submit button.
  final String submitLabel;

  /// Composes the form's fields and its action row. Defaults to stacking them
  /// in a shrink-wrapping [Column]; onboarding passes a layout that scrolls
  /// the fields and pins the actions. The form keeps building both — only
  /// where they sit is the caller's to decide.
  final Widget Function(Widget fields, Widget actions)? layout;

  /// The name the field starts with (a suggestion the user can change).
  final String? initialName;

  @override
  ConsumerState<AddWorkspaceForm> createState() => _AddWorkspaceFormState();
}

class _AddWorkspaceFormState extends ConsumerState<AddWorkspaceForm> {
  late final _nameController = TextEditingController(text: widget.initialName);
  String? _logoPath;

  /// The picked image's extension with its dot (`.png`), from its name.
  String _logoExtension = '';
  String? _error;
  Uint8List? _logoBytes;
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

    // Read the bytes rather than keeping only a path: `File(path)` is a
    // `dart:io` call this widget also runs on web, where it throws, and a
    // path names a file on this machine, not the server. The bytes travel
    // to the server (`fs.persistLogoBytes`); the preview renders from memory.
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _logoPath = file.path;
      _logoBytes = bytes;
      _logoExtension = _extensionOf(file.name);
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final id = await ref
        .read(createWorkspaceProvider.notifier)
        .create(
          name: name,
          logoBytes: _logoBytes,
          logoExtension: _logoExtension,
        );
    if (!mounted) {
      return;
    }
    if (id != null) {
      widget.onCreated(id);
    } else {
      final error = ref.read(createWorkspaceProvider).error;
      if (error is ServerOwnerRequiredException) {
        // Re-read the right, so every create affordance follows the server.
        ref.invalidate(currentIdentityProvider);
      }
      setState(() {
        _saving = false;
        // Refused because only the server owner may create (the create right
        // was withdrawn after this form opened): say so, not the raw error.
        _error = error is ServerOwnerRequiredException
            ? l10n.workspaceCreateOwnerOnly
            : l10n.failedToCreateWorkspace(
                '${error ?? l10n.somethingWentWrong}',
              );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LogoPicker(
          path: _logoPath,
          bytes: _logoBytes,
          onPick: _saving ? null : _pickLogo,
          onClear: _logoPath == null || _saving
              ? null
              : () => setState(() {
                  _logoPath = null;
                  _logoBytes = null;
                }),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workspaceName),
            const SizedBox(height: 6),
            CcTextField(
              controller: _nameController,
              hintText: l10n.egPlatform,
              enabled: !_saving,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );

    final actions = Row(
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
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Adding…' : widget.submitLabel),
        ),
      ],
    );

    final layout = widget.layout;
    if (layout != null) {
      return layout(fields, actions);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [fields, const SizedBox(height: 20), actions],
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.path,
    required this.bytes,
    required this.onPick,
    required this.onClear,
  });

  final String? path;

  /// The picked image's bytes, previewed from memory so the widget stays
  /// web-safe (no `dart:io` `File`).
  final Uint8List? bytes;
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
                border: Border.all(
                  color: tokens?.borderSecondary ?? colorScheme.outlineVariant,
                ),
                image: bytes != null
                    ? DecorationImage(
                        image: MemoryImage(bytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: bytes == null
                  ? Icon(AppIcons.image, color: colorScheme.onSurfaceVariant)
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
                  style: CcTypography.body.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path == null ? 'Optional. Pick a local image file.' : path!,
                  style: CcTypography.caption.copyWith(
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
            CcIconButton(
              icon: AppIcons.x,
              onPressed: onClear,
              tooltip: l10n.removeLogo,
            ),
        ],
      ),
    );
  }
}

/// [name]'s extension with its dot, lower-cased (`Logo.PNG` → `.png`); empty
/// when it has none.
String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? '' : name.substring(dot).toLowerCase();
}
