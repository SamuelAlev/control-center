import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-session dismissal state for the demo's first-run note and guided tour.
///
/// Deliberately NOT persisted to `user_preferences`: that lane SYNCS, and a
/// demo visitor's preferences are thrown away with their workspace 45 minutes
/// later. Keeping it in memory also means the note reappears for the next
/// person on the next visit, which is the behaviour a demo wants.
class DemoShellDismissals extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  /// Whether [id] has been dismissed this session.
  bool isDismissed(String id) => state.contains(id);

  /// Marks [id] dismissed for the rest of this session.
  void dismiss(String id) => state = {...state, id};
}

/// Session-scoped dismissals for the demo shell surfaces.
final demoShellDismissalsProvider =
    NotifierProvider<DemoShellDismissals, Set<String>>(DemoShellDismissals.new);

/// Dismissal id for the one-time first-run note.
const String kDemoFirstRunNoteId = 'demo.first-run-note';

/// Dismissal id for the guided tour panel.
const String kDemoTourId = 'demo.tour';
