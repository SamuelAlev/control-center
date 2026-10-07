import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_title_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/settings/domain/services/short_task_runner.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Names conversations with one tool-less completion after the first human
/// message. Workspace adapter+model settings
/// ([kShortTaskAdapterSettingKey] / [kShortTaskModelSettingKey]);
/// unset adapter = off (no fallback). Pair required: model alone is ambiguous
/// across harness vs CLI. Fail-open via [AdapterOneShotRunner]; only renames
/// auto-minted default titles. [suggestTitle] runs the same prompt on demand
/// and returns the title instead of writing it. [watchGenerating] reports the
/// automatic passes in flight, so clients can show the title being made.
class ConversationTitleService implements ConversationTitlePort {
  /// Creates a [ConversationTitleService].
  ConversationTitleService({
    required this._runner,
    required this._settings,
    required this._conversationRepo,
    required this._messagingRepo,
    this._firstHumanContent,
    this._timeout = const Duration(seconds: 20),
    this._maxTokens = 128,
    this._settleGrace = const Duration(milliseconds: 300),
  });

  final AdapterOneShotRunner _runner;
  final WorkspaceSettingsRepository _settings;
  final ConversationRepository _conversationRepo;
  final MessagingRepository _messagingRepo;

  /// Oldest human message text, without loading the conversation. Null keeps
  /// [MessagingRepository.getMessages], which tests use.
  final Future<String?> Function({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  })?
  _firstHumanContent;

  final Duration _timeout;
  final int _maxTokens;

  /// How long a pass stays "in flight" after writing its title, so the
  /// title reaches clients before the generating flag clears.
  final Duration _settleGrace;

  /// Automatic passes in flight, by conversation id. A count, because two
  /// quick sends can start two passes on one conversation before either
  /// writes a title.
  final Map<String, _InFlight> _inFlight = {};
  final StreamController<void> _inFlightChanged =
      StreamController<void>.broadcast(sync: true);

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
    // Off until the workspace picked an adapter — no fallback, ever.
    final runner = await _shortTaskRunner(workspaceId);
    if (runner == null) {
      return;
    }

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

    final transcript = await _firstHumanText(workspaceId, conversation);
    if (transcript.isEmpty) {
      return;
    }

    // From here a model is asked, so clients show the title being made until
    // the title is written or the pass gives up.
    _markInFlight(workspaceId, conversation);
    try {
      final renamed = await _completeAndRename(
        workspaceId: workspaceId,
        conversation: conversation,
        runner: runner,
        transcript: transcript,
      );
      // The conversation stream re-reads after the write, on its own
      // subscription. Clearing at once lets a client settle the scramble into
      // the old placeholder a beat before the new title lands.
      if (renamed) {
        await Future<void>.delayed(_settleGrace);
      }
    } finally {
      _clearInFlight(conversation.id);
    }
  }

  /// Whether a title was written.
  Future<bool> _completeAndRename({
    required String workspaceId,
    required Conversation conversation,
    required ({String adapterId, String? modelId}) runner,
    required String transcript,
  }) async {
    // Null means the runner cannot run at all (adapter unknown, its CLI not
    // installed, no credential for the harness provider) — a quiet skip, not
    // a failure.
    final raw = await _complete(runner, transcript);
    if (raw == null) {
      CcInfraLog.debug(
        'messaging: runner "${runner.adapterId}" unavailable; conversation '
        'left untitled',
      );
      return false;
    }

    final title = _sanitizeTitle(raw);
    if (title == null) {
      return false;
    }

    // A human rename (or another generation) may have raced us while the
    // model was thinking — never clobber it.
    final current = await _conversationRepo.getById(
      workspaceId: workspaceId,
      conversationId: conversation.id,
    );
    if (current == null || !_isDefaultTitle(current.title)) {
      return false;
    }
    await _conversationRepo.rename(
      workspaceId: workspaceId,
      conversationId: conversation.id,
      title: title,
    );
    return true;
  }

  /// Proposes a title for any conversation, whatever its current title, and
  /// writes nothing. Provider errors propagate so the caller can say the
  /// generation failed rather than silently returning nothing.
  @override
  Future<ConversationTitleSuggestion> suggestTitle({
    required String workspaceId,
    required String conversationId,
  }) async {
    final conversation = await _conversationRepo.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null) {
      throw const NotFoundException('conversation not found');
    }
    final runner = await _shortTaskRunner(workspaceId);
    if (runner == null) {
      return const ConversationTitleSuggestion(unavailable: true);
    }
    final transcript = await _firstHumanText(workspaceId, conversation);
    if (transcript.isEmpty) {
      return const ConversationTitleSuggestion(empty: true);
    }
    final raw = await _complete(runner, transcript);
    if (raw == null) {
      return const ConversationTitleSuggestion(unavailable: true);
    }
    return ConversationTitleSuggestion(title: _sanitizeTitle(raw));
  }

  @override
  Stream<Set<String>> watchGenerating({
    required String workspaceId,
    required String spaceId,
  }) => Stream<Set<String>>.multi((controller) {
    Set<String>? last;
    void emit() {
      final next = {
        for (final MapEntry(:key, :value) in _inFlight.entries)
          if (value.workspaceId == workspaceId && value.spaceId == spaceId) key,
      };
      if (last case final previous?
          when previous.length == next.length && previous.containsAll(next)) {
        return;
      }
      last = next;
      controller.add(next);
    }

    emit();
    final sub = _inFlightChanged.stream.listen((_) => emit());
    controller.onCancel = sub.cancel;
  });

  void _markInFlight(String workspaceId, Conversation conversation) {
    final current = _inFlight[conversation.id];
    _inFlight[conversation.id] = _InFlight(
      workspaceId: workspaceId,
      spaceId: conversation.spaceId,
      count: (current?.count ?? 0) + 1,
    );
    _inFlightChanged.add(null);
  }

  void _clearInFlight(String conversationId) {
    final current = _inFlight[conversationId];
    if (current == null) {
      return;
    }
    if (current.count > 1) {
      _inFlight[conversationId] = _InFlight(
        workspaceId: current.workspaceId,
        spaceId: current.spaceId,
        count: current.count - 1,
      );
      return;
    }
    _inFlight.remove(conversationId);
    _inFlightChanged.add(null);
  }

  /// The workspace's short-task runner, or null while none is chosen. The
  /// ADAPTER is the switch: a model with nothing to run it on is not a
  /// runner, while an adapter with no model is a valid "use your default".
  Future<({String adapterId, String? modelId})?> _shortTaskRunner(
    String workspaceId,
  ) async {
    final adapterId = (await _settings.get(
      workspaceId,
      kShortTaskAdapterSettingKey,
    ))?.trim();
    if (adapterId == null || adapterId.isEmpty) {
      return null;
    }
    final modelId = (await _settings.get(
      workspaceId,
      kShortTaskModelSettingKey,
    ))?.trim();
    return (adapterId: adapterId, modelId: modelId);
  }

  /// The conversation's first human message, trimmed; empty when it has none.
  Future<String> _firstHumanText(
    String workspaceId,
    Conversation conversation,
  ) async {
    final loadFirst = _firstHumanContent;
    if (loadFirst == null) {
      final messages = await _messagingRepo.getMessages(
        workspaceId,
        conversation.spaceId,
        conversationId: conversation.id,
      );
      return messages.where((m) => m.isUser).firstOrNull?.content.trim() ?? '';
    }
    return (await loadFirst(
          workspaceId: workspaceId,
          spaceId: conversation.spaceId,
          conversationId: conversation.id,
        ))?.trim() ??
        '';
  }

  /// One tool-less turn of the titling prompt; null when the runner cannot
  /// run.
  Future<String?> _complete(
    ({String adapterId, String? modelId}) runner,
    String transcript,
  ) => _runner.complete(
    adapterId: runner.adapterId,
    modelId: runner.modelId,
    systemPrompt: _systemPrompt,
    prompt: transcript.length > _maxPromptChars
        ? transcript.substring(0, _maxPromptChars)
        : transcript,
    timeout: _timeout,
    maxTokens: _maxTokens,
  );

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

/// One conversation's automatic titling passes in flight.
final class _InFlight {
  const _InFlight({
    required this.workspaceId,
    required this.spaceId,
    required this.count,
  });

  final String workspaceId;
  final String spaceId;
  final int count;
}
