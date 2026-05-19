import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the create / edit project dialog. When [existing] is null a new
/// project is created; otherwise it edits in place. Returns the project id, or
/// null if cancelled / no active workspace.
Future<String?> showProjectDialog(BuildContext context, {Project? existing}) {
  return showCcDialog<String>(
    context: context,
    builder: (ctx) => _ProjectDialog(existing: existing),
  );
}

class _ProjectDialog extends ConsumerStatefulWidget {
  const _ProjectDialog({this.existing});

  final Project? existing;

  @override
  ConsumerState<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends ConsumerState<_ProjectDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late ProjectColor _color = widget.existing?.color ?? ProjectColor.blue;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final name = _nameController.text.trim();
    if (workspaceId == null || name.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final service = ref.read(projectServiceProvider);
    final description = _descriptionController.text.trim();
    try {
      String id;
      if (_isEdit) {
        await service.update(
          widget.existing!.id,
          workspaceId: workspaceId,
          name: name,
          description: description,
          color: _color,
        );
        id = widget.existing!.id;
      } else {
        final project = await service.create(
          workspaceId: workspaceId,
          name: name,
          description: description.isEmpty ? null : description,
          color: _color,
        );
        id = project.id;
      }
      if (mounted) {
        Navigator.of(context).pop(id);
      }
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      final l10n = AppLocalizations.of(context);
      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderPrimary),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Material(
            type: MaterialType.transparency,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                    _submit,
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    _submit,
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    Navigator.of(context).maybePop(),
              },
              child: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.box, size: 14, color: t.fgTertiary),
                          const SizedBox(width: 8),
                          Text(
                            _isEdit ? l10n.editProject : l10n.newProject,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        cursorColor: t.fgBrandPrimary,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: l10n.projectNamePlaceholder,
                          hintStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: t.textPlaceholder,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: TextField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 5,
                        cursorColor: t.fgBrandPrimary,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: t.textSecondary,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: l10n.projectDescriptionPlaceholder,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: t.textPlaceholder,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Text(
                        l10n.projectColorLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in ProjectColor.values)
                            _ColorSwatch(
                              color: c,
                              selected: c == _color,
                              onTap: () => setState(() => _color = c),
                            ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: t.borderSecondary),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CcButton(
                            variant: CcButtonVariant.secondary,
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          CcButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CcSpinner(),
                                  )
                                : Text(
                                    _isEdit ? l10n.save : l10n.createProject,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final ProjectColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final c = projectColorValue(t, color);
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c : t.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
