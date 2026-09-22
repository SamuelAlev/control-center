import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart'
    show kConversationTitleAdapterSettingKey, kConversationTitleModelSettingKey;
import 'package:cc_domain/features/messaging/domain/services/side_channel_render.dart';
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
    required this._repo,
    required this._runner,
    required this._settings,
    this._sideChannelMessages,
    this._timeout = const Duration(minutes: 2),
    this._maxPromptChars = 60000,
  });

  final MessagingRepository _repo;
  final AdapterOneShotRunner _runner;
  final WorkspaceSettingsRepository _settings;

  /// Newest rows of the conversation, already cut to `maxChars` of rendered
  /// side-channel text. Null keeps [MessagingRepository.getMessages], which
  /// tests and hosts without the paged read still use.
  final Future<List<Message>> Function({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required int maxChars,
  })?
  _sideChannelMessages;

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

    final load = _sideChannelMessages;
    final messages = load == null
        ? await _repo.getMessages(
            workspaceId,
            spaceId,
            conversationId: conversationId,
          )
        : await load(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            maxChars: _maxPromptChars,
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
    final line = sideChannelLine(message);
    if (line == null) {
      continue;
    }
    if (total + line.length > maxChars) {
      rendered.add('[…earlier conversation omitted]');
      break;
    }
    total += line.length;
    rendered.add(line);
  }
  return rendered.reversed.join('\n\n');
}
