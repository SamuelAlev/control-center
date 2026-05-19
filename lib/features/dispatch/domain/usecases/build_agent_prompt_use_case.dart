import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/app_locale.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:control_center/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';

export 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';

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
    ConversationMode mode = ConversationMode.chat,
    ModePromptContext? modeContext,
    MentionContext? mentionContext,
    WakeContext? wakeContext,
    AppLocale? locale,
  }) {
    if (agent == null) {
      return prompt;
    }

    return PromptBuilder()
        .identity(agent)
        .resourceProtocols(mode: mode)
        .workspaceLayout()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
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
    ConversationMode mode = ConversationMode.chat,
    ModePromptContext? modeContext,
  }) {
    return PromptBuilder()
        .identity(agent)
        .resourceProtocols(mode: mode)
        .workspaceLayout()
        .systemPrompt(agent.systemPrompt)
        .persona(agent.persona, role: agent.role)
        .skills(agent.skills)
        .executionContract(mode: mode)
        .executionProcedure(mode: mode)
        .mode(mode, ctx: modeContext)
        .buildPersistentBrief();
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
