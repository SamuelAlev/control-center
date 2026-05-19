import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/widgets.dart';

/// Provides mention suggestions for a given query.
///
/// Sources are pure functions of the query — they should not hold UI state.
/// Async sources (file search, fff) return a stream so the popup can render
/// results progressively.
abstract class MentionSource {
  /// Stable kind tag (e.g. `'agent'`, `'file'`). Used to group / dedupe.
  String get kind;

  /// Triggers this source listens to.
  Set<MentionTrigger> get triggers;

  /// Optional section header shown above the source's rows.
  String? sectionLabel(BuildContext context) => null;

  /// Returns suggestions for the [query]. May complete with an empty list.
  ///
  /// Implementations should cap their own result count; the popup caller
  /// will further trim per-source.
  Stream<List<MentionSuggestion>> suggest(MentionQuery query);
}

/// Convenience base for sources that produce results synchronously from an
/// in-memory list (agents, channels, slash commands).
abstract class SyncMentionSource extends MentionSource {
  @override
  Stream<List<MentionSuggestion>> suggest(MentionQuery query) {
    return Stream<List<MentionSuggestion>>.value(suggestSync(query));
  }

  /// Suggest sync.
  List<MentionSuggestion> suggestSync(MentionQuery query);
}

