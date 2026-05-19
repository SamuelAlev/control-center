import 'package:cc_domain/core/domain/value_objects/mode.dart';

/// Resolves the [Mode] for a given conversation id (space id) within one
/// workspace.
///
/// Consulted by:
///   * the sandbox dispatch adapter, to carve filesystem write-allow rules.
///   * the MCP tool guard, to gate which tools may be called.
///   * the prompt builder, to inject mode-specific system blocks.
///
/// Implementations must return `Mode.chat` when `conversationId`
/// is `null` or the row is missing — chat is the safe default that preserves
/// existing behaviour for non-space-scoped dispatches (e.g. one-off agents).
abstract interface class ModeResolver {
  /// Returns the mode for `conversationId` within `workspaceId`, or `Mode.chat`
  /// if the id is null or the row cannot be found in that workspace.
  ///
  /// The space id resolves only inside `workspaceId`: a space belonging to
  /// another workspace is not found and the safe default applies.
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  );
}
