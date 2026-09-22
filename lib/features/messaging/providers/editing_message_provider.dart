import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A sent message loaded back into a conversation's composer.
class EditingMessage {
  /// Creates a session for [message].
  const EditingMessage(this.message);

  /// The message whose content the composer is holding.
  final Message message;
}

/// The conversation an edit session belongs to.
typedef EditingConversation = ({String spaceId, String conversationId});

/// Holds the message a conversation's composer is currently editing.
///
/// The composer parks whatever draft was already in the field and puts it
/// back when the session ends. Starting another edit while one is open keeps
/// that original draft — the in-progress edit is not an unsent message.
class EditingMessageNotifier extends Notifier<EditingMessage?> {
  /// Creates a session bound to [conversation].
  EditingMessageNotifier(this.conversation);

  /// The conversation whose composer this session drives.
  final EditingConversation conversation;

  @override
  EditingMessage? build() => null;

  /// Loads [message] into this conversation's composer.
  ///
  /// A message from another conversation is ignored: the composer that is
  /// watching this session must not be handed someone else's words.
  void begin(Message message) {
    if (message.spaceId != conversation.spaceId ||
        message.conversationId != conversation.conversationId) {
      return;
    }
    state = EditingMessage(message);
  }

  /// Closes the session so the composer can restore the parked draft.
  void end() {
    state = null;
  }
}

/// The edit session for one conversation, or null when the composer is free.
final editingMessageProvider = NotifierProvider.autoDispose
    .family<EditingMessageNotifier, EditingMessage?, EditingConversation>(
      EditingMessageNotifier.new,
    );
