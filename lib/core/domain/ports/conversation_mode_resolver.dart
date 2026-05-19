
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';

/// Resolves the [ConversationMode] for a given conversation id (channel id).
///
/// Consulted by:
///   * the sandbox dispatch adapter, to carve filesystem write-allow rules.
///   * the MCP tool guard, to gate which tools may be called.
///   * the prompt builder, to inject mode-specific system blocks.
///
/// Implementations must return `ConversationMode.chat` when `conversationId`
/// is `null` or the row is missing — chat is the safe default that preserves
/// existing behaviour for non-channel-scoped dispatches (e.g. one-off agents).
abstract interface class ConversationModeResolver {
  /// Returns the mode for `conversationId`, or `ConversationMode.chat` if
  /// the id is null or the row cannot be found.
  Future<ConversationMode> resolveForConversation(String? conversationId);
}
