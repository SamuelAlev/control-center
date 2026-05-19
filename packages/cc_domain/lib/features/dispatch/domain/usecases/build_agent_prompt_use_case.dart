import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/app_locale.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';

export 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
export 'package:cc_domain/features/dispatch/domain/value_objects/teammate_brief.dart';

/// Builds the full agent prompt by layering identity, persona, skills, mode,
/// and per-turn context (mentions, memory, conversation) via [PromptBuilder].
class BuildAgentPromptUseCase {
  /// Creates a [BuildAgentPromptUseCase].
  const BuildAgentPromptUseCase();

  /// Builds the full agent prompt combining persistent brief and per-turn context.
  String execute({
    required String prompt,
    required Agent? agent,
    String? memoryContext,
    String? conversationContext,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
    AppLocale? locale,
    List<TeammateBrief> teammates = const [],
  }) {
    if (agent == null) {
      return prompt;
    }

    return PromptBuilder()
        .identity(agent)
        .toolCatalog()
        .resourceProtocols(mode: mode)
        .workspaceLayout()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
        .team(teammates, mode: mode)
        .skills(agent.skills)
        .executionContract(mode: mode)
        .executionProcedure(mode: mode)
        .wakeContext(wakeContext)
        .mentions(mentionContext, agent.name)
        .mode(mode, ctx: modeContext)
        .memoryContext(memoryContext)
        .conversationContext(conversationContext)
        .locale(locale)
        .build(prompt);
  }

  /// Builds the persistent brief (identity, protocols, persona, skills, contract, mode).
  /// This content is stable across turns and can be cached or written to disk.
  String buildPersistentBrief({
    required Agent agent,
    Mode mode = Mode.chat,
    ModePromptContext? modeContext,
    List<TeammateBrief> teammates = const [],
  }) {
    return PromptBuilder()
        .identity(agent)
        .toolCatalog()
        .resourceProtocols(mode: mode)
        .workspaceLayout()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
        .team(teammates, mode: mode)
        .skills(agent.skills)
        .executionContract(mode: mode)
        .executionProcedure(mode: mode)
        .mode(mode, ctx: modeContext)
        .buildPersistentBrief();
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
  }) {
    final builder = PromptBuilder()
        .identity(agent)
        .toolCatalog()
        .resourceProtocols(mode: mode)
        .workspaceLayout()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
        .team(teammates, mode: mode)
        .skills(agent.skills)
        .executionContract(mode: mode)
        .executionProcedure(mode: mode)
        .mode(mode, ctx: modeContext)
        .memoryContext(memoryContext)
        .locale(locale);
    return builder.sections();
  }

  /// Builds the per-turn prompt (mentions, memory context, conversation context).
  /// This content changes every turn.
  String buildPerTurnPrompt({
    required String prompt,
    required Agent agent,
    String? memoryContext,
    String? conversationContext,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
  }) {
    final builder = PromptBuilder()
        .wakeContext(wakeContext)
        .mentions(mentionContext, agent.name)
        .memoryContext(memoryContext)
        .conversationContext(conversationContext);
    return builder.build(prompt);
  }
}
