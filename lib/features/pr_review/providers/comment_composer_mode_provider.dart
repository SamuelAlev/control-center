import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted preference key for where the diff comment composer sends.
///
/// Synced: the reviewer's habit follows them to every client.
const String prCommentComposerModeKey = 'pr_comment_composer_mode';

/// Where a comment written on the diff goes when it is sent.
enum CommentComposerMode {
  /// Hands the comment to the pull request's agent chat. Nothing reaches the
  /// forge.
  agent('agent'),

  /// Posts the comment on its own, right now.
  comment('comment'),

  /// Queues the comment for the next review submission.
  review('review');

  const CommentComposerMode(this.wireValue);

  /// The persisted value.
  final String wireValue;

  /// Parses a persisted value, or null for anything unrecognised.
  static CommentComposerMode? fromWire(String? value) {
    for (final mode in CommentComposerMode.values) {
      if (mode.wireValue == value) {
        return mode;
      }
    }
    return null;
  }
}

/// The modes a composer offers, in display order.
List<CommentComposerMode> commentComposerModes({
  required bool agent,
  required bool review,
}) => [
  if (agent) CommentComposerMode.agent,
  CommentComposerMode.comment,
  if (review) CommentComposerMode.review,
];

/// The mode to send with: [preferred] when [available] offers it, otherwise
/// review, otherwise a single comment.
///
/// Review is the fallback because it is what a reviewer working through a diff
/// almost always means. Nothing is written back: a composer that cannot batch
/// must not overwrite the choice the user made where it could.
CommentComposerMode resolveCommentComposerMode(
  CommentComposerMode? preferred,
  List<CommentComposerMode> available,
) {
  if (preferred != null && available.contains(preferred)) {
    return preferred;
  }
  if (available.contains(CommentComposerMode.review)) {
    return CommentComposerMode.review;
  }
  return available.contains(CommentComposerMode.comment)
      ? CommentComposerMode.comment
      : available.first;
}

/// The last mode the user picked in a diff comment composer, or null before
/// they have picked one.
final commentComposerModeProvider =
    NotifierProvider<CommentComposerModeNotifier, CommentComposerMode?>(
      CommentComposerModeNotifier.new,
    );

/// Reads and persists [commentComposerModeProvider] through [AppPreferences].
class CommentComposerModeNotifier extends Notifier<CommentComposerMode?> {
  late AppPreferences _prefs;

  @override
  CommentComposerMode? build() {
    _prefs = ref.watch(appPreferencesProvider);
    return CommentComposerMode.fromWire(
      _prefs.getString(prCommentComposerModeKey),
    );
  }

  /// Remembers [mode] as the user's choice.
  void setMode(CommentComposerMode mode) {
    if (state == mode) {
      return;
    }
    _prefs.setString(prCommentComposerModeKey, mode.wireValue);
    state = mode;
  }
}
