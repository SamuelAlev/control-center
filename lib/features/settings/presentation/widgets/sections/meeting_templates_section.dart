import 'package:cc_domain/features/meetings/domain/entities/meeting_template.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/meetings/providers/meeting_template_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Settings section to pick the active meeting-note template and manage custom
/// ones. Built-in presets are read-only; custom templates can be edited/removed.
class MeetingTemplatesSection extends ConsumerWidget {
  /// Creates a [MeetingTemplatesSection].
  const MeetingTemplatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(meetingTemplatesProvider);
    final activeId = ref.watch(selectedMeetingTemplateProvider);
    final custom = templates.where((t) => !t.builtIn).toList();

    final autoDetect = ref.watch(meetingAutoDetectEnabledProvider);

    return SectionCard(
      label: l10n.meetingTemplates,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.radio,
            title: l10n.meetingAutoDetect,
            subtitle: l10n.meetingAutoDetectDescription,
            trailing: CcSwitch(
              value: autoDetect,
              onChanged: (v) => ref
                  .read(meetingAutoDetectEnabledProvider.notifier)
                  .setEnabled(v),
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: AppIcons.layoutTemplate,
            title: l10n.meetingTemplateActive,
            subtitle: l10n.meetingTemplatesHint,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: CcSelect<String>(
                value: activeId,
                options: [
                  for (final t in templates)
                    CcSelectOption(value: t.id, label: t.name),
                ],
                onChanged:
                    ref.read(selectedMeetingTemplateProvider.notifier).select,
              ),
            ),
          ),
          for (final t in custom) ...[
            const SizedBox(height: 8),
            SettingsRow(
              icon: AppIcons.fileText,
              title: t.name,
              subtitle: t.instructions.isEmpty
                  ? l10n.meetingTemplateInstructionsHint
                  : t.instructions,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CcButton(
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    icon: AppIcons.pencil,
                    onPressed: () => _editDialog(context, ref, t),
                    child: Text(l10n.edit),
                  ),
                  const SizedBox(width: 8),
                  CcButton(
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    icon: AppIcons.trash2,
                    onPressed: () => ref
                        .read(meetingTemplatesProvider.notifier)
                        .remove(t.id),
                    child: Text(l10n.remove),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: () => _editDialog(context, ref, null),
              child: Text(l10n.meetingTemplateAdd),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref,
    MeetingTemplate? existing,
  ) async {
    final result = await showCcDialog<MeetingTemplate>(
      context: context,
      builder: (_) => _TemplateDialog(existing: existing),
    );
    if (result != null) {
      ref.read(meetingTemplatesProvider.notifier).upsert(result);
      // Selecting a freshly-created template is a sensible default.
      if (existing == null) {
        ref.read(selectedMeetingTemplateProvider.notifier).select(result.id);
      }
    }
  }
}

/// Name + instructions editor for a custom template. Pops a [MeetingTemplate]
/// on save, or null on cancel.
class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.existing});

  final MeetingTemplate? existing;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  static const _uuid = Uuid();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _instructions =
      TextEditingController(text: widget.existing?.instructions ?? '');

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    final existing = widget.existing;
    Navigator.of(context).pop(
      existing == null
          ? MeetingTemplate(
              id: _uuid.v4(),
              name: name,
              instructions: _instructions.text.trim(),
            )
          : existing.copyWith(name: name, instructions: _instructions.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem;
    return CcDialog(
      title: widget.existing == null
          ? l10n.meetingTemplateNewTitle
          : l10n.meetingTemplateEditTitle,
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.meetingTemplateNameLabel,
                style: TextStyle(fontSize: 12, color: ds?.textTertiary)),
            const SizedBox(height: 6),
            CcTextField(
              controller: _name,
              hintText: l10n.meetingTemplateNameHint,
            ),
            const SizedBox(height: 14),
            Text(l10n.meetingTemplateInstructionsLabel,
                style: TextStyle(fontSize: 12, color: ds?.textTertiary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ds?.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ds?.borderSecondary ?? const Color(0x22000000),
                ),
              ),
              child: TextField(
                controller: _instructions,
                minLines: 4,
                maxLines: 8,
                cursorColor: ds?.accent,
                style: TextStyle(fontSize: 13, height: 1.5, color: ds?.textPrimary),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.meetingTemplateInstructionsHint,
                  hintStyle: TextStyle(fontSize: 13, color: ds?.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
