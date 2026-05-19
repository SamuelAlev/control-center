import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';

/// [ConversationModeResolver] backed by the messaging DAO.
///
/// One indexed lookup on `channels.id` per dispatch. The fallback to
/// [ConversationMode.chat] preserves the existing free-for-all behaviour for
/// dispatches that aren't attached to a channel (e.g. CLI one-shots).
class DbConversationModeResolver implements ConversationModeResolver {
  /// Creates a new [DbConversationModeResolver].
  DbConversationModeResolver(this._dao);

  final MessagingDao _dao;

  @override
  Future<ConversationMode> resolveForConversation(
    String? conversationId,
  ) async {
    if (conversationId == null || conversationId.isEmpty) {
      return ConversationMode.chat;
    }
    final row = await _dao.getChannelById(conversationId);
    if (row == null) {
      return ConversationMode.chat;
    }
    return ConversationMode.fromDbValue(row.data.mode);
  }
}
