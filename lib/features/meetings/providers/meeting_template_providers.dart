import 'package:cc_domain/features/meetings/domain/entities/meeting_template.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All meeting-note templates = the built-in presets followed by the user's
/// custom templates (persisted in AppPreferences as JSON).
/// MeetingTemplates: presets are read-only; custom ones are user-managed.
class MeetingTemplatesNotifier extends Notifier<List<MeetingTemplate>> {
  late AppPreferences _prefs;

  @override
  List<MeetingTemplate> build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _compose(
      MeetingTemplate.decodeCustom(_prefs.getString(meetingTemplatesKey)),
    );
  }

  List<MeetingTemplate> _compose(List<MeetingTemplate> custom) => [
    ...MeetingTemplate.builtIns,
    ...custom,
  ];

  List<MeetingTemplate> get _custom =>
      state.where((t) => !t.builtIn).toList(growable: true);

  void _persist(List<MeetingTemplate> custom) {
    _prefs.setString(meetingTemplatesKey, MeetingTemplate.encodeCustom(custom));
    state = _compose(custom);
  }

  /// Adds a new custom template (or updates an existing custom one by id).
  void upsert(MeetingTemplate template) {
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
    _persist(custom);
  }

  /// Removes a custom template by [id] (built-ins are ignored).
  void remove(String id) {
    _persist(_custom.where((t) => t.id != id).toList());
  }
}

/// Every meeting-note template (built-ins + custom).
final meetingTemplatesProvider =
    NotifierProvider<MeetingTemplatesNotifier, List<MeetingTemplate>>(
      MeetingTemplatesNotifier.new,
    );

/// The selected template id, persisted. Defaults to the no-op `default`.
class SelectedMeetingTemplateNotifier extends Notifier<String> {
  late AppPreferences _prefs;

  @override
  String build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getString(selectedMeetingTemplateKey) ??
        MeetingTemplate.defaultId;
  }

  /// Selects [id] and persists it.
  void select(String id) {
    _prefs.setString(selectedMeetingTemplateKey, id);
    state = id;
  }
}

/// The selected meeting-note template id.
final selectedMeetingTemplateProvider =
    NotifierProvider<SelectedMeetingTemplateNotifier, String>(
      SelectedMeetingTemplateNotifier.new,
    );

/// The resolved active template (falls back to the default if the persisted id
/// no longer exists, e.g. a custom template was deleted).
final activeMeetingTemplateProvider = Provider<MeetingTemplate>((ref) {
  final id = ref.watch(selectedMeetingTemplateProvider);
  final all = ref.watch(meetingTemplatesProvider);
  return all.firstWhere(
    (t) => t.id == id,
    orElse: () => MeetingTemplate.builtIns.first,
  );
});
