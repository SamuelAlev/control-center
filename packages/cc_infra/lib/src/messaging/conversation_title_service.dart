import 'dart:async';

import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Names conversations with ONE small, tool-less completion.
///
/// Fired (un-awaited) by `MessagingService.sendAndDispatch` once the first
/// human message of a conversation has persisted. The runner is the
/// WORKSPACE's choice — an **adapter + model pair** read from its admin-gated
/// settings ([kConversationTitleAdapterSettingKey] +
/// [kConversationTitleModelSettingKey]) — and **an unset adapter means OFF**:
/// there is deliberately no auto-picked fallback, so no generation happens
/// until an admin picks one in Settings. Workspace-scoped because the title it
/// writes is read by every member: keying it on the sender meant one space got
/// titled and the next did not depending on who typed first.
///
/// The pair, rather than a bare model id, because a model alone does not say
/// what runs it: the built-in harness folds its provider into the model id
/// while an external CLI adapter owns its own auth and model names, so
/// `sonnet` is ambiguous without the adapter beside it.
///
/// Like `SkillLlmReviewRunner`, this is inert by construction (no tools, tight
/// output budget, no caching, hard wall-clock timeout — see
/// [AdapterOneShotRunner]) and fail-open: any error keeps the conversation's
/// current title. It only ever renames a conversation whose title is still an
/// auto-minted default — never a title a human typed or a previous generation
/// wrote.
class ConversationTitleService {
  /// Creates a [ConversationTitleService].
  ConversationTitleService({
    required AdapterOneShotRunner runner,
    required WorkspaceSettingsRepository settings,
    required ConversationRepository conversationRepo,
    required MessagingRepository messagingRepo,
    Duration timeout = const Duration(seconds: 20),
    int maxTokens = 128,
  }) : _runner = runner,
       _settings = settings,
       _conversationRepo = conversationRepo,
       _messagingRepo = messagingRepo,
       _timeout = timeout,
       _maxTokens = maxTokens;

  final AdapterOneShotRunner _runner;
  final WorkspaceSettingsRepository _settings;
  final ConversationRepository _conversationRepo;
  final MessagingRepository _messagingRepo;
  final Duration _timeout;
  final int _maxTokens;

  /// The longest transcript excerpt sent to the model.
  static const int _maxPromptChars = 4000;

  /// The longest title written back (titles are "about 8 words or fewer").
  static const int _maxTitleLength = 80;

  /// The verbatim titling prompt. Not localized: it is an API prompt for a
  /// model, not user-facing copy.
  static const String _systemPrompt =
      'You are an expert in crafting pithy titles for chatbot conversations. '
      'You are presented with a chat conversation, and you reply with a brief '
      'title that captures the main topic of discussion in that '
      'conversation.\n'
      'Follow Microsoft content policies.\n'
      'Avoid content that violates copyrights.\n'
      'If you are asked to generate content that is harmful, hateful, racist, '
      'sexist, lewd, or violent, only respond with "Sorry, I can\'t assist '
      'with that."\n'
      'Keep your answers short and impersonal.\n'
      'The title should not be wrapped in quotes. It should about 8 words or '
      'fewer.\n'
      'Here are some examples of good titles:\n'
      '- Git rebase question\n'
      '- Installing Python packages\n'
      '- Location of LinkedList implentation in codebase\n'
      '- Adding a tree view to a VS Code extension\n'
      '- React useState hook usage';

  /// Generates and applies a title for [conversationId] (or the space's
  /// standing conversation when null) if — and only if — conditions hold:
  /// the workspace has a title model set, the conversation still carries an
  /// auto-minted default title, and it has a human message to name it from.
  ///
  /// Never throws: every failure is logged and the current title is kept.
  Future<void> maybeGenerate({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) async {
    try {
      await _generate(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('messaging: conversation titling failed: $e');
    }
  }

  Future<void> _generate({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) async {
    // Off until the workspace picked an adapter — no fallback, ever. The
    // ADAPTER is the switch: a model with nothing to run it on is not a
    // runner, while an adapter with no model is a valid "use your default".
    final adapterId = (await _settings.get(
      workspaceId,
      kConversationTitleAdapterSettingKey,
    ))?.trim();
    if (adapterId == null || adapterId.isEmpty) {
      return;
    }
    final modelId = (await _settings.get(
      workspaceId,
      kConversationTitleModelSettingKey,
    ))?.trim();

    final conversation = conversationId == null
        ? await _conversationRepo.ensure(
            workspaceId: workspaceId,
            spaceId: spaceId,
          )
        : await _conversationRepo.getById(
            workspaceId: workspaceId,
            conversationId: conversationId,
          );
    if (conversation == null) {
      return;
    }

    if (!_isDefaultTitle(conversation.title)) {
      return;
    }

    final messages = await _messagingRepo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversation.id,
    );
    final firstHuman = messages.where((m) => m.isUser).firstOrNull;
    final transcript = firstHuman?.content.trim() ?? '';
    if (transcript.isEmpty) {
      return;
    }

    // One tool-less turn on the workspace's runner. Null means the runner
    // cannot run at all (adapter unknown, its CLI not installed, no credential
    // for the harness provider) — a quiet skip, not a failure.
    final raw = await _runner.complete(
      adapterId: adapterId,
      modelId: modelId,
      systemPrompt: _systemPrompt,
      prompt: transcript.length > _maxPromptChars
          ? transcript.substring(0, _maxPromptChars)
          : transcript,
      timeout: _timeout,
      maxTokens: _maxTokens,
    );
    if (raw == null) {
      CcInfraLog.debug(
        'messaging: runner "$adapterId" unavailable; conversation left '
        'untitled',
      );
      return;
    }

    final title = _sanitizeTitle(raw);
    if (title == null) {
      return;
    }

    // A human rename (or another generation) may have raced us while the
    // model was thinking — never clobber it.
    final current = await _conversationRepo.getById(
      workspaceId: workspaceId,
      conversationId: conversation.id,
    );
    if (current == null || !_isDefaultTitle(current.title)) {
      return;
    }
    await _conversationRepo.rename(
      workspaceId: workspaceId,
      conversationId: conversation.id,
      title: title,
    );
  }

  /// A title the mint path could have produced: empty. The standing
  /// conversation mints untitled and the new-conversation flow creates
  /// untitled, so an empty title is the only auto-minted state — anything
  /// non-empty was written by a human, a pipeline step or a previous
  /// generation and must be left alone.
  static bool _isDefaultTitle(String title) => title.trim().isEmpty;

  /// Cleans the model's reply into a storable title, or null when the reply
  /// is unusable (empty, or the prompt's own refusal wording).
  static String? _sanitizeTitle(String raw) {
    var t = raw.trim();
    // The prompt asks for no quotes; honour a model that ignored that anyway.
    while (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) ||
            (t.startsWith("'") && t.endsWith("'")))) {
      t = t.substring(1, t.length - 1).trim();
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (t.endsWith('.') || t.endsWith('。')) {
      t = t.substring(0, t.length - 1).trimRight();
    }
    if (t.isEmpty || t.startsWith('Sorry, I can')) {
      return null;
    }
    if (t.length > _maxTitleLength) {
      final cut = t.substring(0, _maxTitleLength);
      final lastSpace = cut.lastIndexOf(' ');
      t = lastSpace > _maxTitleLength ~/ 2 ? cut.substring(0, lastSpace) : cut;
      t = t.trimRight();
      while (t.endsWith(',') || t.endsWith(';') || t.endsWith('-')) {
        t = t.substring(0, t.length - 1).trimRight();
      }
      if (t.isEmpty) {
        return null;
      }
    }
    return t;
  }
}
