import 'package:cc_domain/features/meetings/domain/entities/meeting_template.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All meeting-note templates for the ACTIVE workspace = the built-in presets
/// followed by that workspace's custom templates.
///
/// **Workspace-scoped**: the templates (and the active one) shape summaries for
/// meetings that live in the workspace's own database, so every member must see
/// the same set — they are stored in `workspace_settings` (admin-gated writes,
/// watched live) rather than in device-local preferences, which is where they
/// lived before and which silently gave two members different templates.
///
/// Provider names and notifier APIs are kept identical to the old prefs-backed
/// versions so consumers (the record-screen picker, the recorder's `stop()` /
/// "Re-run summary") are unchanged.
class MeetingTemplatesNotifier extends Notifier<List<MeetingTemplate>> {
  @override
  List<MeetingTemplate> build() {
    // Watching the workspace setting re-runs this on every server-acknowledged
    // change (ours and another admin's), keeping the optimistic writes below
    // reconciled with the authoritative store.
    final raw = ref.watch(workspaceSettingProvider(meetingTemplatesSettingKey));
    return _compose(MeetingTemplate.decodeCustom(raw));
  }

  List<MeetingTemplate> _compose(List<MeetingTemplate> custom) => [
    ...MeetingTemplate.builtIns,
    ...custom,
  ];

  List<MeetingTemplate> get _custom =>
      state.where((t) => !t.builtIn).toList(growable: true);

  /// Adds a new custom template (or updates an existing custom one by id).
  ///
  /// Applies optimistically, then writes through; the settings watch reconciles
  /// on success and the optimistic value lingers on failure (the caller toasts).
  Future<void> upsert(MeetingTemplate template) async {
    if (template.builtIn) {
      return; // presets are immutable
    }
    final custom = _custom;
    final idx = custom.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      custom[idx] = template;
    } else {
      custom.add(template);
    }
    state = _compose(custom);
    await _writeWorkspaceSetting(
      ref,
      meetingTemplatesSettingKey,
      MeetingTemplate.encodeCustom(custom),
    );
  }

  /// Removes a custom template by [id] (built-ins are ignored).
  Future<void> remove(String id) async {
    final custom = _custom.where((t) => t.id != id).toList();
    state = _compose(custom);
    await _writeWorkspaceSetting(
      ref,
      meetingTemplatesSettingKey,
      MeetingTemplate.encodeCustom(custom),
    );
  }
}

/// Every meeting-note template for the active workspace (built-ins + custom).
final meetingTemplatesProvider =
    NotifierProvider<MeetingTemplatesNotifier, List<MeetingTemplate>>(
      MeetingTemplatesNotifier.new,
    );

/// The active template id for the ACTIVE workspace, persisted there. Defaults
/// to the no-op `default`.
class SelectedMeetingTemplateNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(
          workspaceSettingProvider(activeMeetingTemplateSettingKey),
        ) ??
        MeetingTemplate.defaultId;
  }

  /// Selects [id] and persists it in the active workspace.
  Future<void> select(String id) async {
    state = id;
    await _writeWorkspaceSetting(ref, activeMeetingTemplateSettingKey, id);
  }
}

/// The active meeting-note template id for the active workspace.
final selectedMeetingTemplateProvider =
    NotifierProvider<SelectedMeetingTemplateNotifier, String>(
      SelectedMeetingTemplateNotifier.new,
    );

/// The resolved active template (falls back to the default if the stored id
/// no longer exists, e.g. a custom template was deleted).
final activeMeetingTemplateProvider = Provider<MeetingTemplate>((ref) {
  final id = ref.watch(selectedMeetingTemplateProvider);
  final all = ref.watch(meetingTemplatesProvider);
  return all.firstWhere(
    (t) => t.id == id,
    orElse: () => MeetingTemplate.builtIns.first,
  );
});

/// Writes one meeting-template setting to the active workspace over the
/// admin-gated RPC op. A no-op when no workspace is active.
Future<void> _writeWorkspaceSetting(Ref ref, String key, String? value) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref
      .read(workspaceSettingsRepositoryProvider)
      .set(workspaceId, key, value);
}
