import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/still_in_flight_row.dart';
import 'package:cc_harness/context.dart'
    show ToolCallForm, renderStillInFlightBlock;
import 'package:cc_infra/src/dispatch/still_in_flight_lines.dart';

/// Writes the "Still in flight" block on the conversation lane (plan section
/// 12, D24): after the conversation compactor folds a conversation, and
/// after a Claude Code session compacts its own context, the block is
/// appended as a system row marked [stillInFlightRowKey], which the prompt
/// builder hands to the agent's next turn.
///
/// Only one block of an agent is live in a conversation: writing a new one
/// marks every earlier one compacted, and so does a compaction that leaves
/// nothing in flight (the old block would claim what is no longer true).
class StillInFlightNotes {
  /// Creates the writer.
  StillInFlightNotes({
    required this._messages,
    required this._lines,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MessagingRepository _messages;
  final StillInFlightLines _lines;
  final DateTime Function() _now;

  /// The lines for a built-in harness run, for the kernel's seam: the
  /// stored keys are included, and a refresh is a script call when the run
  /// has `repl`.
  Future<List<String>> harnessLines({
    required String workspaceId,
    required String agentId,
    required String conversationId,
    required bool scripts,
  }) => _lines.linesFor(
    workspaceId: workspaceId,
    agentId: agentId,
    conversationId: conversationId,
    style: scripts ? ToolCallForm.script : ToolCallForm.plain,
    stored: scripts,
  );

  /// Writes the block of [agentId] in [conversationId] (in [spaceId]) after
  /// a compaction. [claude] marks a Claude Code session: only its `Goal:`,
  /// `Wakes:` and `Asked:` lines are written, as tool calls. [existing] is
  /// the conversation's rows when the caller already holds them. Returns the
  /// new row's id, or null when nothing is in flight.
  Future<String?> writeAfterCompaction({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required bool claude,
    List<Message>? existing,
  }) async {
    final rows =
        existing ??
        await _messages.getMessages(
          workspaceId,
          spaceId,
          conversationId: conversationId,
        );
    final earlier = [
      for (final m in rows)
        if (!m.compacted &&
            m.conversationId == conversationId &&
            stillInFlightRowAgent(m) == agentId)
          m.id,
    ];
    final lines = await _lines.linesFor(
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      style: ToolCallForm.plain,
      stored: !claude,
    );
    final block = renderStillInFlightBlock(at: _now(), lines: lines);
    if (earlier.isNotEmpty) {
      await _messages.markCompacted(workspaceId, earlier);
    }
    if (block == null) {
      return null;
    }
    return _messages.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: block,
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
      metadata: {stillInFlightRowKey: agentId},
    );
  }
}
