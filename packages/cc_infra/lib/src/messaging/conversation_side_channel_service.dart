import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart'
    show kConversationTitleAdapterSettingKey, kConversationTitleModelSettingKey;
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// What a side-channel request produced.
class SideChannelResult {
  /// Creates a [SideChannelResult].
  const SideChannelResult({
    this.text,
    this.unavailable = false,
    this.empty = false,
  });

  /// The answer, or null when there is none.
  final String? text;

  /// Whether no runner is configured for this workspace.
  final bool unavailable;

  /// Whether the conversation had nothing to work from.
  final bool empty;
}

/// Asks the current conversation a question WITHOUT adding to it.
///
/// **The two commands this backs, and why they share one implementation.**
/// `/handoff` writes a document for whoever continues the work and `/btw`
/// answers a side question. Both are the same shape: take the conversation as
/// it stands, ask one question about it, and do NOT let the question or the
/// answer become part of the conversation. Implemented once so they cannot
/// drift into two subtly different notions of "the context so far".
///
/// **Why the conversation is not mutated.** The value of a side question is
/// that asking it costs nothing later: the agent's next real turn sees exactly
/// what it would have seen anyway. An implementation that appends the question
/// changes what the agent is working from, which is the opposite of the point —
/// and on a long conversation it also pushes the compaction cut a turn earlier
/// for a question nobody wanted persisted.
class ConversationSideChannelService {
  /// Creates a [ConversationSideChannelService].
  ConversationSideChannelService({
    required MessagingRepository repo,
    required AdapterOneShotRunner runner,
    required WorkspaceSettingsRepository settings,
    Duration timeout = const Duration(minutes: 2),
    int maxPromptChars = 60000,
  }) : _repo = repo,
       _runner = runner,
       _settings = settings,
       _timeout = timeout,
       _maxPromptChars = maxPromptChars;

  final MessagingRepository _repo;
  final AdapterOneShotRunner _runner;
  final WorkspaceSettingsRepository _settings;
  final Duration _timeout;
  final int _maxPromptChars;

  /// Generates a handoff document for the conversation.
  Future<SideChannelResult> handoff({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String? focus,
  }) => _ask(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    question: focus == null || focus.trim().isEmpty
        ? handoffPrompt
        : '$handoffPrompt\n\nFocus especially on: ${focus.trim()}',
    maxTokens: 2048,
  );

  /// Answers an ephemeral side question about the work so far.
  Future<SideChannelResult> aside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String question,
  }) => _ask(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    question: sideQuestionPrompt(question),
    maxTokens: 1024,
  );

  Future<SideChannelResult> _ask({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String question,
    required int maxTokens,
  }) async {
    // The workspace's chosen one-shot runner, the same pair conversation
    // titling uses. No fallback: running a side question on some other model
    // than the operator configured would be a surprise on their bill.
    final adapterId = (await _settings.get(
      workspaceId,
      kConversationTitleAdapterSettingKey,
    ))?.trim();
    if (adapterId == null || adapterId.isEmpty) {
      return const SideChannelResult(unavailable: true);
    }
    final modelId = (await _settings.get(
      workspaceId,
      kConversationTitleModelSettingKey,
    ))?.trim();

    final messages = await _repo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    if (messages.isEmpty) {
      return const SideChannelResult(empty: true);
    }

    final transcript = renderConversationForSideChannel(
      messages,
      maxChars: _maxPromptChars,
    );
    try {
      final answer = await _runner.complete(
        adapterId: adapterId,
        modelId: modelId,
        systemPrompt:
            'You are reviewing a conversation between a person and one or '
            'more coding agents. Answer only what is asked. Be specific and '
            'concrete: name files, symbols and commands rather than '
            'describing them.',
        prompt: '$transcript\n\n---\n\n$question',
        timeout: _timeout,
        maxTokens: maxTokens,
      );
      final text = answer?.trim();
      return SideChannelResult(
        text: text == null || text.isEmpty ? null : text,
      );
    } on Object catch (e) {
      CcInfraLog.warning('side-channel request failed: $e');
      return const SideChannelResult();
    }
  }
}

/// Renders a conversation for a side-channel prompt.
///
/// Keeps the NEWEST messages when it has to cut: a handoff or a side question
/// is almost always about where the work currently stands, and dropping the
/// tail to preserve the opening would answer about the wrong end of the
/// conversation.
String renderConversationForSideChannel(
  List<Message> messages, {
  int maxChars = 60000,
}) {
  final rendered = <String>[];
  var total = 0;
  for (final message in messages.reversed) {
    final who = message.isUser
        ? 'User'
        : message.isAgentTurn
        ? (message.metadata?['agentName'] as String? ?? 'Agent')
        : 'System';
    final body = message.isAgentTurn && message.content.trim().isEmpty
        ? _transcriptText(message)
        : message.content.trim();
    if (body.isEmpty) {
      continue;
    }
    final line = '$who: $body';
    if (total + line.length > maxChars) {
      rendered.add('[…earlier conversation omitted]');
      break;
    }
    total += line.length;
    rendered.add(line);
  }
  return rendered.reversed.join('\n\n');
}

/// The readable text of an agent turn whose content is empty because its
/// substance lives in transcript segments.
String _transcriptText(Message message) {
  final parts = <String>[];
  for (final segment in message.transcript) {
    switch (segment) {
      case TextSegment(:final text):
        parts.add(text.trim());
      case ToolSegment(:final toolName, :final inputs):
        // The tool CALL is the useful signal for a handoff ("it edited
        // auth.dart"); the output is bulk and usually stale.
        final target = inputs?['path'] ?? inputs?['file_path'] ?? '';
        parts.add('[$toolName${target == '' ? '' : ' $target'}]');
      case ErrorSegment(:final message):
        parts.add('[error: $message]');
      case ReasoningSegment():
      case ViolationSegment():
        break;
    }
  }
  return parts.where((p) => p.isNotEmpty).join('\n');
}
