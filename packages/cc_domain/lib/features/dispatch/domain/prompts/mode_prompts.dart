import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/chat_mode_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/orchestrate_mode_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/plan_mode_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/review_mode_prompt.dart';

/// Per-mode context needed to materialize the system-prompt block.
///
/// Most fields are optional — chat needs none; review wants PR metadata;
/// plan needs only the goal sentence (its deliverable is a `submit_plan` call,
/// not a file, so there is no path to thread).
class ModePromptContext {
  /// Creates a new [ModePromptContext].
  const ModePromptContext({
    this.planGoal,
    this.prNumber,
    this.repoFullName,
    this.prTitle,
    this.prBody,
    this.priority,
    this.orchestrationId,
  });

  /// One-sentence goal for the plan-mode conversation.
  final String? planGoal;

  /// Existing orchestration id when re-dispatching the orchestrator to revise
  /// a proposal (orchestrate mode).
  final String? orchestrationId;

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
/// Returns an empty string for [Mode.chat] so the caller can
/// skip the block entirely without an `if` chain.
String buildModeSystemBlock(Mode mode, {ModePromptContext? ctx}) {
  switch (mode) {
    case Mode.chat:
      return buildChatModePrompt();
    case Mode.review:
      return reviewModeSystemPrompt;
    case Mode.plan:
      return buildPlanModePrompt(conversationGoal: ctx?.planGoal);
    case Mode.orchestrate:
      return buildOrchestrateModePrompt(orchestrationId: ctx?.orchestrationId);
  }
}
