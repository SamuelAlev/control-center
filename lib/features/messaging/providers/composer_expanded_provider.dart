import 'package:control_center/features/messaging/providers/editing_message_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether one conversation's composer is expanded to fill most of its pane.
///
/// Two widgets read it: the composer (to fill the height it is given) and the
/// conversation pane (to give it that height, shrinking the feed above).
/// Neither owns the other, so the flag lives here. Auto-disposed with the
/// pane, so a conversation always reopens with its feed in full view.
class ComposerExpandedNotifier extends Notifier<bool> {
  /// Creates the flag for [conversation].
  ComposerExpandedNotifier(this.conversation);

  /// The conversation whose composer this flag sizes.
  final EditingConversation conversation;

  @override
  bool build() => false;

  /// Expands or collapses the composer.
  void set(bool expanded) {
    state = expanded;
  }
}

/// The expanded flag for one conversation's composer.
final composerExpandedProvider = NotifierProvider.autoDispose
    .family<ComposerExpandedNotifier, bool, EditingConversation>(
      ComposerExpandedNotifier.new,
    );
