import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/app_locale.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show AdapterTransport;

export 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart'
    show AgentPromptParts, PromptPartScope, PromptSection;
export 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
export 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';

/// Builds the full agent prompt by layering identity, persona, skills, mode,
/// and per-turn context (mentions, memory, conversation) via [PromptBuilder].
///
/// There is ONE assembly here, in [_standingBrief] plus the per-turn tail the
/// callers append, and every public method derives from it:
/// [execute] the whole prompt, [buildParts] its standing/per-turn split,
/// [buildPersistentBrief] the standing half alone and [inspectSections] the
/// attributed spans. That is deliberate — before, each of these rebuilt a
/// slightly different chain, so `buildPersistentBrief` carried a `Mode` block
/// the per-turn half did not, dropped the language line entirely and put the
/// mode span in a different place than [execute] did. One chain cannot drift
/// from itself.
class BuildAgentPromptUseCase {
  /// Creates a [BuildAgentPromptUseCase].
  const BuildAgentPromptUseCase();

  /// Builds the full agent prompt combining persistent brief and per-turn context.
  ///
  /// [transport] selects the tool-discovery wording ([PromptBuilder.toolCatalog]).
  ///
  /// A thin wrapper over [buildParts] so the flattened prompt and its split are
  /// one assembly, not two that can drift.
  String execute({
    required String prompt,
    required Agent? agent,
    String? memoryContext,
    String? conversationContext,
    List<PromptConversationEntry>? conversationEntries,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
    AppLocale? locale,
    List<TeammateBrief> teammates = const [],
    AdapterTransport? transport,
  }) => buildParts(
    prompt: prompt,
    agent: agent,
    memoryContext: memoryContext,
    conversationContext: conversationContext,
    conversationEntries: conversationEntries,
    mode: mode,
    modeContext: modeContext,
    mentionContext: mentionContext,
    wakeContext: wakeContext,
    locale: locale,
    teammates: teammates,
    transport: transport,
  ).fullPrompt;

  /// Builds the structured parts of the same assembly [execute] flattens:
  /// the standing brief, the genuinely-new per-turn context (minus the
  /// conversation window) and the full prompt.
  ///
  /// A native-resumed turn sends [AgentPromptParts.resumePrompt] instead of
  /// [AgentPromptParts.fullPrompt], so the standing instructions and the
  /// conversation already in the session are never replayed.
  AgentPromptParts buildParts({
    required String prompt,
    required Agent? agent,
    String? memoryContext,
    String? conversationContext,
    List<PromptConversationEntry>? conversationEntries,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
    AppLocale? locale,
    List<TeammateBrief> teammates = const [],
    AdapterTransport? transport,
  }) {
    if (agent == null) {
      return AgentPromptParts(
        userText: prompt,
        standing: '',
        turnContext: '',
        conversationContext: '',
        conversationEntries: const [],
        fullPrompt: prompt,
        standingRevision: PromptBuilder.promptRevisionOf(''),
        turnSections: const [],
      );
    }
    return _turnTail(
      _standingBrief(
        agent: agent,
        mode: mode,
        modeContext: modeContext,
        teammates: teammates,
        transport: transport,
      ),
      agent: agent,
      memoryContext: memoryContext,
      conversationContext: conversationContext,
      conversationEntries: conversationEntries ?? const [],
      mentionContext: mentionContext,
      wakeContext: wakeContext,
      locale: locale,
    ).parts(prompt);
  }

  /// Builds the persistent brief (identity, protocols, persona, skills, contract, mode).
  /// This content is stable across turns and can be cached or written to disk.
  String buildPersistentBrief({
    required Agent agent,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    List<TeammateBrief> teammates = const [],
    AppLocale? locale,
    AdapterTransport? transport,
  }) {
    return _standingBrief(
      agent: agent,
      mode: mode,
      modeContext: modeContext,
      teammates: teammates,
      transport: transport,
    ).locale(locale).buildPersistentBrief();
  }

  /// Builds the standing sections of the `<context>` block for INSPECTION.
  ///
  /// The same chain [execute] runs — identity through mode, then memory and
  /// locale — minus the layers that only exist for a concrete dispatch (wake
  /// context, mentions, the injected conversation window and the user prompt
  /// itself), returned as attributed [PromptSection]s instead of a flattened
  /// string so the context explorer can show each named span with its own
  /// size and content.
  List<PromptSection> inspectSections({
    required Agent agent,
    String? memoryContext,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    List<TeammateBrief> teammates = const [],
    AppLocale? locale,
    AdapterTransport? transport,
  }) {
    final builder = _standingBrief(
      agent: agent,
      mode: mode,
      modeContext: modeContext,
      teammates: teammates,
      transport: transport,
    ).memoryContext(memoryContext).locale(locale);
    return builder.sections();
  }

  /// Builds the per-turn prompt (mentions, memory context, conversation context).
  /// This content changes every turn.
  String buildPerTurnPrompt({
    required String prompt,
    required Agent agent,
    String? memoryContext,
    String? conversationContext,
    List<PromptConversationEntry>? conversationEntries,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
  }) {
    final builder = _turnTail(
      PromptBuilder(),
      agent: agent,
      memoryContext: memoryContext,
      conversationContext: conversationContext,
      conversationEntries: conversationEntries,
      mentionContext: mentionContext,
      wakeContext: wakeContext,
    );
    return builder.build(prompt);
  }

  /// The standing half of the assembly: everything stable across the turns of
  /// a conversation. Shared by every public builder method.
  static PromptBuilder _standingBrief({
    required Agent agent,
    required Mode mode,
    required List<TeammateBrief> teammates,
    ModePromptContext? modeContext,
    AdapterTransport? transport,
  }) => PromptBuilder()
      .identity(agent)
      .toolCatalog(transport: transport)
      .resourceProtocols(mode: mode)
      .workspaceLayout()
      .systemPrompt(agent.systemPrompt)
      .persona(agent.persona, role: agent.role)
      .team(teammates, mode: mode)
      .skills(agent.skills)
      .executionContract(mode: mode)
      .executionProcedure(mode: mode)
      .mode(mode, ctx: modeContext);

  /// The per-turn half: why the run started, who summoned it, what memory
  /// answered, the injected conversation window and the response language.
  static PromptBuilder _turnTail(
    PromptBuilder builder, {
    required Agent agent,
    String? memoryContext,
    String? conversationContext,
    List<PromptConversationEntry>? conversationEntries,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
    AppLocale? locale,
  }) => builder
      .wakeContext(wakeContext)
      .mentions(mentionContext, agent.name)
      .memoryContext(memoryContext)
      .conversationContext(conversationContext)
      .conversationEntries(conversationEntries ?? const [])
      .locale(locale);
}
