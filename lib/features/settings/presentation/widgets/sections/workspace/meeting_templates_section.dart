import 'package:cc_domain/features/meetings/domain/entities/meeting_template.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_template_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Workspace → General: the active meeting-note template and the workspace's
/// custom ones. Built-in presets are read-only; custom templates can be
/// edited/removed.
///
/// **Workspace-scoped**: templates shape summaries for meetings that live in
/// this workspace's database, so every member reads the same set. Writes are
/// admin-gated server-side; non-admins get a read-only view.
class MeetingTemplatesSection extends ConsumerStatefulWidget {
  /// Creates a [MeetingTemplatesSection].
  const MeetingTemplatesSection({super.key});

  @override
  ConsumerState<MeetingTemplatesSection> createState() =>
      _MeetingTemplatesSectionState();
}

class _MeetingTemplatesSectionState
    extends ConsumerState<MeetingTemplatesSection> {
  /// Session guard for the one-time legacy migration (see [_seedLegacy]).
  static bool _legacySeedDone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(meetingTemplatesProvider);
    final activeId = ref.watch(selectedMeetingTemplateProvider);
    final custom = templates.where((t) => !t.builtIn).toList();

    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    // The one-time migration only runs once the workspace settings have
    // actually loaded — "key absent" is indistinguishable from "not yet read".
    if (!_legacySeedDone) {
      final settings = ref.watch(workspaceSettingsProvider).asData?.value;
      if (settings != null) {
        _legacySeedDone = true;
        _seedLegacy(settings);
      }
    }

    return SectionCard(
      label: l10n.meetingTemplates,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.layoutTemplate,
            title: l10n.meetingTemplateActive,
            subtitle: l10n.meetingTemplatesHint,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: CcSelect<String>(
                value: activeId,
                enabled: isAdmin,
                options: [
                  for (final t in templates)
                    CcSelectOption(value: t.id, label: t.name),
                ],
                onChanged: (id) => _guard(() => _select(id)),
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
                    onPressed: isAdmin ? () => _editDialog(context, t) : null,
                    child: Text(l10n.edit),
                  ),
                  const SizedBox(width: 8),
                  CcButton(
                    variant: CcButtonVariant.destructive,
                    size: CcButtonSize.sm,
                    icon: AppIcons.trash2,
                    onPressed: isAdmin ? () => _remove(t.id) : null,
                    child: Text(l10n.remove),
                  ),
                ],
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                icon: AppIcons.plus,
                onPressed: () => _editDialog(context, null),
                child: Text(l10n.meetingTemplateAdd),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Runs a write, surfacing a server rejection (e.g. a non-admin's attempt
  /// that slipped past the disabled controls) instead of dropping it silently.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  Future<void> _select(String id) async {
    await ref.read(selectedMeetingTemplateProvider.notifier).select(id);
  }

  Future<void> _remove(String id) async {
    await ref.read(meetingTemplatesProvider.notifier).remove(id);
  }

  Future<void> _editDialog(
    BuildContext context,
    MeetingTemplate? existing,
  ) async {
    final result = await showCcDialog<MeetingTemplate>(
      context: context,
      builder: (_) => _TemplateDialog(existing: existing),
    );
    if (result == null || !mounted) {
      return;
    }
    await _guard(() async {
      await ref.read(meetingTemplatesProvider.notifier).upsert(result);
      // Selecting a freshly-created template is a sensible default.
      if (existing == null) {
        await ref
            .read(selectedMeetingTemplateProvider.notifier)
            .select(result.id);
      }
    });
  }

  /// One-time migration from the old device-local store: when the workspace
  /// owns no templates yet and this client still carries custom ones in its
  /// legacy preferences, carry them up and clear the legacy keys — so the
  /// migration happens exactly once, in the first workspace opened, and never
  /// re-runs for another workspace or after a restart.
  Future<void> _seedLegacy(Map<String, String> settings) async {
    if (settings.containsKey(meetingTemplatesSettingKey) ||
        settings.containsKey(activeMeetingTemplateSettingKey)) {
      return;
    }
    final prefs = ref.read(appPreferencesProvider);
    final legacyCustom = MeetingTemplate.decodeCustom(
      prefs.getString(meetingTemplatesKey),
    );
    final legacySelected = prefs.getString(selectedMeetingTemplateKey);
    final carrySelection =
        legacySelected != null && legacySelected != MeetingTemplate.defaultId;
    if (legacyCustom.isEmpty && !carrySelection) {
      return;
    }

    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(workspaceSettingsRepositoryProvider);
    try {
      if (legacyCustom.isNotEmpty) {
        await repo.set(
          workspaceId,
          meetingTemplatesSettingKey,
          MeetingTemplate.encodeCustom(legacyCustom),
        );
      }
      if (carrySelection) {
        await repo.set(
          workspaceId,
          activeMeetingTemplateSettingKey,
          legacySelected,
        );
      }
      // The legacy keys are unread from here on; removing them makes the
      // migration idempotent across workspaces and sessions.
      await prefs.remove(meetingTemplatesKey);
      await prefs.remove(selectedMeetingTemplateKey);
    } on Object catch (_) {
      // A failed RPC leaves the legacy keys in place, so the next session
      // retries. The in-memory guard keeps this session quiet.
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
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _instructions = TextEditingController(
    text: widget.existing?.instructions ?? '',
  );

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
          : existing.copyWith(
              name: name,
              instructions: _instructions.text.trim(),
            ),
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
            Text(
              l10n.meetingTemplateNameLabel,
              style: TextStyle(fontSize: 12, color: ds?.textTertiary),
            ),
            const SizedBox(height: 6),
            CcTextField(
              controller: _name,
              hintText: l10n.meetingTemplateNameHint,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.meetingTemplateInstructionsLabel,
              style: TextStyle(fontSize: 12, color: ds?.textTertiary),
            ),
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
              child: CcTextField(
                controller: _instructions,
                minLines: 4,
                maxLines: 8,
                textStyle: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: ds?.textPrimary,
                ),
                hintText: l10n.meetingTemplateInstructionsHint,
                chromeless: true,
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
        CcButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
