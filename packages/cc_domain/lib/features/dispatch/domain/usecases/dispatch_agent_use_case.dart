import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/app_locale.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// The fully-resolved result of preparing an agent dispatch, containing
/// the effective prompt, conversation target, resolved adapter, and mode.
class PreparedDispatch {
  /// Creates a [PreparedDispatch] with the given resolved values.
  const PreparedDispatch({
    required this.effectivePrompt,
    required this.effectiveConversationId,
    required this.agent,
    required this.mode,
    required this.resolvedAdapterId,
    required this.cliName,
    this.rawUserText = '',
  });

  /// The fully-built prompt text, including all layers.
  final String effectivePrompt;

  /// The user's message verbatim, before any context layering.
  ///
  /// [effectivePrompt] is wrapped as `<context>…</context>\n\n<text>`, which
  /// means a leading-slash test against it always fails — that is why `/plan`,
  /// `/goal`, `/loop`, and `/<skill>` silently did nothing when typed in a
  /// channel. Slash-command parsing reads this field instead.
  final String rawUserText;

  /// The effective conversation id to use, if any.
  final String? effectiveConversationId;

  /// The resolved agent, if found.
  final Agent? agent;

  /// The conversation mode (chat, pr_review, etc.).
  final Mode mode;

  /// The resolved adapter id, if determined.
  final String? resolvedAdapterId;

  /// The CLI name for the backend to use.
  final String cliName;
}

/// Orchestrates the full agent dispatch flow: resolves the agent, builds the
/// prompt with all layers, determines the mode and adapter, and returns a
/// [PreparedDispatch] ready for the dispatch port.
class DispatchAgentUseCase {
  /// Creates a [DispatchAgentUseCase].
  DispatchAgentUseCase({
    required AgentRepository agentRepo,
    BuildMemoryContextUseCase? memoryContextUseCase,
    BuildConversationContextUseCase? conversationContextUseCase,
    ModeResolver? modeResolver,
    AppLocale? locale,
  }) : _agentRepo = agentRepo,
       _memoryContextUseCase = memoryContextUseCase,
       _conversationContextUseCase = conversationContextUseCase,
       _modeResolver = modeResolver,
       _locale = locale;

  final AgentRepository _agentRepo;
  final BuildMemoryContextUseCase? _memoryContextUseCase;
  final BuildConversationContextUseCase? _conversationContextUseCase;
  final ModeResolver? _modeResolver;
  final AppLocale? _locale;
  final _buildPrompt = const BuildAgentPromptUseCase();

  void _log(String message) =>
      CcDomainLog.info('DispatchAgentUseCase: $message');

  /// Executes the full dispatch preparation, returning a [PreparedDispatch].
  ///
  /// [workspaceId] is the workspace the dispatch runs in; it scopes the agent,
  /// mode and conversation-history reads, so an id from another workspace
  /// resolves to nothing instead of being read.
  Future<PreparedDispatch> execute({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    final agent = await _agentRepo.getById(workspaceId, agentId);
    final resolvedAdapterId = adapterId ?? agent?.adapterId;
    final resolvedAdapter = predefinedAdapters
        .where((a) => a.id == resolvedAdapterId)
        .firstOrNull;
    final cliName = resolvedAdapter?.cliName ?? 'pi';

    final effectiveConversationId = conversationId ?? channelId;

    final mode = await _resolveMode(workspaceId, channelId);

    final effectivePrompt = await _buildEffectivePrompt(
      workspaceId: workspaceId,
      prompt: prompt,
      agent: agent,
      channelId: channelId,
      mode: mode,
      mentionContext: mentionContext,
    );

    return PreparedDispatch(
      effectivePrompt: effectivePrompt,
      effectiveConversationId: effectiveConversationId,
      agent: agent,
      mode: mode,
      resolvedAdapterId: resolvedAdapterId,
      cliName: cliName,
      rawUserText: prompt,
    );
  }

  /// Resolves the conversation mode, defaulting to [Mode.chat] when there is no
  /// resolver wired or no channel to resolve against.
  Future<Mode> _resolveMode(String workspaceId, String? channelId) async {
    final resolver = _modeResolver;
    if (resolver == null || channelId == null) {
      return Mode.chat;
    }
    return resolver.resolveForConversation(workspaceId, channelId);
  }

  Future<String> _buildEffectivePrompt({
    required String workspaceId,
    required String prompt,
    required Agent? agent,
    String? channelId,
    Mode mode = Mode.chat,
    MentionContext? mentionContext,
  }) async {
    // The agent is the authority for its workspace (Agent.workspaceId is never
    // null), so memory is scoped to the agent's own workspace whenever the
    // agent is known — no more "skipped because workspaceId was null".
    final agentId = agent?.id;
    String? memoryContext;
    if (_memoryContextUseCase == null) {
      _log('Memory context: skipped (use case not wired)');
    } else if (agent == null) {
      _log('Memory context: skipped (agent not found)');
    } else {
      final workspaceId = agent.workspaceId;
      try {
        memoryContext = await _memoryContextUseCase.execute(
          workspaceId: workspaceId,
          agentId: agent.id,
          taskDescription: prompt,
        );
        if (memoryContext.isEmpty) {
          _log(
            'Memory context: returned empty for '
            'workspace=$workspaceId agent=${agent.id}',
          );
        } else {
          _log(
            'Memory context: ${memoryContext.length} chars loaded for '
            'workspace=$workspaceId agent=${agent.id}',
          );
        }
      } catch (e, st) {
        _log('Memory context: build failed — $e\n$st');
      }
    }

    String? conversationContext;
    if (_conversationContextUseCase == null ||
        channelId == null ||
        agentId == null) {
      _log('Conversation context: skipped');
    } else {
      try {
        // Cap the eager verbatim window so dispatch stays small/fast and prompt
        // prefixes stay stable. Older history is retrieved on-demand via the
        // get_channel_messages MCP tool, and the use case still surfaces
        // semantically-relevant older messages. Without a cap this was up to
        // ~2 MB (contextSize * 2, default 1 MB).
        const maxConversationChars = 50000;
        final contextSize = agent?.contextSize ?? 1000000;
        final characterBudget = (contextSize * 2).clamp(
          0,
          maxConversationChars,
        );
        conversationContext = await _conversationContextUseCase.execute(
          workspaceId: workspaceId,
          channelId: channelId,
          selfAgentId: agentId,
          selfAgentName: agent?.name ?? agentId,
          taskDescription: prompt,
          characterBudget: characterBudget,
        );
        if (conversationContext.isEmpty) {
          _log('Conversation context: empty');
        } else {
          _log('Conversation context: ${conversationContext.length} chars');
        }
      } catch (e, st) {
        _log('Conversation context: build failed — $e\n$st');
      }
    }

    final modeContext = mode == Mode.plan
        ? ModePromptContext(planGoal: prompt)
        : null;

    return _buildPrompt.execute(
      prompt: prompt,
      agent: agent,
      memoryContext: memoryContext,
      conversationContext: conversationContext,
      mode: mode,
      modeContext: modeContext,
      mentionContext: mentionContext,
      locale: _locale,
      teammates: agent == null ? const [] : await _loadTeammates(agent),
    );
  }

  /// The workspace's other agents, for the prompt's staffing decision.
  ///
  /// Best-effort: a roster lookup must never block a dispatch, and an agent with
  /// no roster simply falls back to doing the work itself.
  Future<List<TeammateBrief>> _loadTeammates(Agent agent) async {
    try {
      final agents = await _agentRepo.watchByWorkspace(agent.workspaceId).first;
      final mates = [
        for (final other in agents)
          if (other.id != agent.id)
            TeammateBrief(
              id: other.id,
              name: other.name,
              title: other.title,
              skills: other.skills.toList(),
              isTopLevel: other.isTopLevel,
            ),
      ];
      _log('Team roster: ${mates.length} teammate(s) for ${agent.name}');
      return mates;
    } catch (e, st) {
      _log('Team roster: lookup failed — $e\n$st');
      return const [];
    }
  }
}
