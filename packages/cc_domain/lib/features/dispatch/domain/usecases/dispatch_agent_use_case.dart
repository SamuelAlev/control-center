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

/// The most history, in characters, a dispatch inlines into the prompt.
const int maxConversationContextChars = 50000;

/// The history block's character budget for an agent whose window is
/// [contextTokens] tokens (null: unset).
///
/// Capped at [maxConversationContextChars] so dispatch stays small and prompt
/// prefixes stay stable — older history is fetched on demand. A small window
/// shrinks it further: history never takes more than a quarter of the window,
/// at ~4 characters per token, which is the window's own token count.
int conversationCharacterBudget(int? contextTokens) => contextTokens == null
    ? maxConversationContextChars
    : contextTokens.clamp(0, maxConversationContextChars);

/// The fully-resolved result of preparing an agent dispatch, containing
/// the effective prompt, conversation target, resolved adapter and mode.
class PreparedDispatch {
  /// Creates a [PreparedDispatch] with the given resolved values.
  const PreparedDispatch({
    required this.effectivePrompt,
    required this.promptParts,
    required this.effectiveConversationId,
    required this.agent,
    required this.mode,
    required this.resolvedAdapterId,
    required this.cliName,
    this.rawUserText = '',
  });

  /// The fully-built prompt text, including all layers.
  ///
  /// Identical to `promptParts.fullPrompt`; kept as its own field because
  /// every existing dispatch callsite reads it.
  final String effectivePrompt;

  /// The same prompt split into its standing brief and per-turn delta.
  ///
  /// A native-resumed turn sends `promptParts.resumePrompt` — the new message
  /// plus the new per-turn context only — instead of [effectivePrompt], so the
  /// standing instructions and the conversation the session already holds are
  /// never replayed.
  final AgentPromptParts promptParts;

  /// The user's message verbatim, before any context layering.
  ///
  /// [effectivePrompt] is wrapped as `<context>…</context>\n\n<text>`, which
  /// means a leading-slash test against it always fails — that is why `/plan`,
  /// `/goal`, `/loop` and `/skill:<name>` silently did nothing when typed in a
  /// space. Slash-command parsing reads this field instead.
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
/// prompt with all layers, determines the mode and adapter and returns a
/// [PreparedDispatch] ready for the dispatch port.
class DispatchAgentUseCase {
  /// Creates a [DispatchAgentUseCase].
  DispatchAgentUseCase({
    required this._agentRepo,
    this._memoryContextUseCase,
    this._conversationContextUseCase,
    this._modeResolver,
    this._locale,
  });

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
    String? spaceId,
    String? conversationId,
    String? adapterId,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    final agent = await _agentRepo.getById(workspaceId, agentId);
    // An agent with no adapter — every seeded specialist until someone picks
    // one — runs on the BUILT-IN loop, not on an external CLI. The built-in
    // adapter ships inside the server, so the worst case is a legible
    // "connect a provider" error instead of a missing binary.
    final resolvedAdapter =
        predefinedAdapters
            .where((a) => a.id == (adapterId ?? agent?.adapterId))
            .firstOrNull ??
        builtInAdapter;
    // Reported rather than left null, so the run log records what actually ran
    // and the per-adapter launch overrides resolve for the fallback too.
    final resolvedAdapterId = resolvedAdapter.id;
    final cliName = resolvedAdapter.cliName;

    final effectiveConversationId = conversationId ?? spaceId;

    // The authorization boundary is the agent lookup above: `workspaceId`
    // scopes it, so an agent id from another workspace resolves to nothing and
    // every read below is scoped to THIS workspace (memory to the agent's own
    // workspace, which is never null; history and the roster to
    // `workspaceId`). Past that boundary the four reads are independent, so
    // they run CONCURRENTLY — the dispatch waits on the slowest, not their
    // sum. Each read keeps its own try/catch, so one failing (memory store
    // down, roster lookup error) yields an empty layer and logs, and never
    // aborts the others: the prompt still assembles.
    final results = await Future.wait<Object?>([
      _resolveMode(workspaceId, spaceId),
      _loadMemoryContext(agent, prompt),
      _loadConversationContext(agent, workspaceId, spaceId, prompt),
      _loadTeammates(agent),
    ]);

    final mode = results[0]! as Mode;
    final memoryContext = results[1] as String?;
    final conversationParts = results[2] as ConversationContextParts?;
    final teammates = results[3]! as List<TeammateBrief>;

    final modeContext = mode == Mode.plan
        ? ModePromptContext(planGoal: prompt)
        : null;

    // One assembly produces the flattened prompt AND its standing/per-turn
    // split. Order is fixed by the builder, never by which concurrent read
    // finished first. [wakeContext] rides the per-turn half: the execution
    // procedure tells the agent to check the "Why you were woken" section, so
    // it must actually reach the prompt rather than being dropped here.
    final promptParts = _buildPrompt.buildParts(
      prompt: prompt,
      agent: agent,
      memoryContext: memoryContext,
      conversationContext: conversationParts?.text,
      conversationEntries: conversationParts?.entries,
      mode: mode,
      modeContext: modeContext,
      mentionContext: mentionContext,
      wakeContext: wakeContext,
      locale: _locale,
      teammates: teammates,
      transport: resolvedAdapter.transport,
    );

    return PreparedDispatch(
      effectivePrompt: promptParts.fullPrompt,
      promptParts: promptParts,
      effectiveConversationId: effectiveConversationId,
      agent: agent,
      mode: mode,
      resolvedAdapterId: resolvedAdapterId,
      cliName: cliName,
      rawUserText: prompt,
    );
  }

  /// Resolves the conversation mode, defaulting to [Mode.chat] when there is no
  /// resolver wired or no space to resolve against.
  Future<Mode> _resolveMode(String workspaceId, String? spaceId) async {
    final resolver = _modeResolver;
    if (resolver == null || spaceId == null) {
      return Mode.chat;
    }
    return resolver.resolveForConversation(workspaceId, spaceId);
  }

  /// Loads the agent's memory context, scoped to the agent's own workspace
  /// (`Agent.workspaceId` is never null). Best-effort: a failure logs and
  /// yields null rather than aborting the dispatch.
  Future<String?> _loadMemoryContext(Agent? agent, String prompt) async {
    if (_memoryContextUseCase == null) {
      _log('Memory context: skipped (use case not wired)');
      return null;
    }
    if (agent == null) {
      _log('Memory context: skipped (agent not found)');
      return null;
    }
    final workspaceId = agent.workspaceId;
    try {
      final memoryContext = await _memoryContextUseCase.execute(
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
      return memoryContext;
    } catch (e, st) {
      _log('Memory context: build failed — $e\n$st');
      return null;
    }
  }

  /// Loads the conversation-history block, scoped to [workspaceId] and
  /// [spaceId]. Best-effort: a failure logs and yields null.
  Future<ConversationContextParts?> _loadConversationContext(
    Agent? agent,
    String workspaceId,
    String? spaceId,
    String prompt,
  ) async {
    final agentId = agent?.id;
    if (_conversationContextUseCase == null ||
        spaceId == null ||
        agentId == null) {
      _log('Conversation context: skipped');
      return null;
    }
    try {
      // Older history is retrieved on demand via the get_messages MCP tool,
      // and the use case still surfaces semantically-relevant older
      // messages. The context inspection sizes the same block.
      final characterBudget = conversationCharacterBudget(agent?.contextSize);
      final context = await _conversationContextUseCase.executeStructured(
        workspaceId: workspaceId,
        spaceId: spaceId,
        selfAgentId: agentId,
        selfAgentName: agent?.name ?? agentId,
        taskDescription: prompt,
        characterBudget: characterBudget,
      );
      if (context.text.isEmpty) {
        _log('Conversation context: empty');
      } else {
        _log(
          'Conversation context: ${context.text.length} chars, '
          '${context.entries.length} entries',
        );
      }
      return context;
    } catch (e, st) {
      _log('Conversation context: build failed — $e\n$st');
      return null;
    }
  }

  /// The workspace's other agents, for the prompt's staffing decision.
  ///
  /// Best-effort: a roster lookup must never block a dispatch and an agent with
  /// no roster simply falls back to doing the work itself.
  Future<List<TeammateBrief>> _loadTeammates(Agent? agent) async {
    if (agent == null) {
      return const [];
    }
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
