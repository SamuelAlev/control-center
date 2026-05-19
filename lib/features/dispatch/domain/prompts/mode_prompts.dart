import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/dispatch/domain/prompts/chat_mode_prompt.dart';
import 'package:control_center/features/dispatch/domain/prompts/plan_mode_prompt.dart';
import 'package:control_center/features/dispatch/domain/prompts/review_mode_prompt.dart';

/// Per-mode context needed to materialize the system-prompt block.
///
/// Most fields are optional — chat needs none; review wants PR metadata;
/// plan needs the plans-dir path and the goal sentence.
class ModePromptContext {
  /// Creates a new [ModePromptContext].
  const ModePromptContext({
    this.planGoal,
    this.plansDirAbsolutePath,
    this.prNumber,
    this.repoFullName,
    this.prTitle,
    this.prBody,
    this.priority,
  });

  /// One-sentence goal for the plan-mode conversation.
  final String? planGoal;

  /// Absolute path to the plans directory the agent is allowed to write to.
  final String? plansDirAbsolutePath;

  /// GitHub PR number, for review mode.
  final int? prNumber;

  /// Repository full name (`owner/repo`), for review mode.
  final String? repoFullName;

  /// PR title, for review mode.
  final String? prTitle;

  /// PR description body, for review mode.
  final String? prBody;

  /// Review priority (`low`, `medium`, `high`), for review mode.
  final String? priority;
}

/// Returns the system-prompt block that should be injected for [mode].
///
/// Returns an empty string for [ConversationMode.chat] so the caller can
/// skip the block entirely without an `if` chain.
String buildModeSystemBlock(
  ConversationMode mode, {
  ModePromptContext? ctx,
}) {
  switch (mode) {
    case ConversationMode.chat:
      return buildChatModePrompt();
    case ConversationMode.review:
      return reviewModeSystemPrompt;
    case ConversationMode.plan:
      return buildPlanModePrompt(
        conversationGoal: ctx?.planGoal ?? '',
        plansDirAbsolutePath: ctx?.plansDirAbsolutePath ?? '',
      );
  }
}
