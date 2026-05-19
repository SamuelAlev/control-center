import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart'
    show kConversationTitleAdapterSettingKey, kConversationTitleModelSettingKey;
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// One step of the objective interview.
class GuidedGoalStep {
  /// Creates a [GuidedGoalStep].
  const GuidedGoalStep({
    this.question,
    this.objective,
    this.missing = const [],
    this.weaknesses = const [],
    this.unavailable = false,
  });

  /// The next question to ask, or null when the objective is ready.
  final String? question;

  /// The finished objective, or null while the interview continues.
  final String? objective;

  /// Requirements the draft still does not cover.
  final List<GoalObjectiveRequirement> missing;

  /// Anti-patterns found in what it does say.
  final List<String> weaknesses;

  /// Whether no one-shot runner is configured for this workspace.
  final bool unavailable;

  /// Whether the interview is finished.
  bool get isReady => objective != null;
}

/// Turns a rough request into an objective an agent can pursue unsupervised.
///
/// **Why an interview rather than a template.** An autonomous goal is the one
/// place a vague brief is genuinely expensive: the loop runs for hours on an
/// objective whose "done" nobody defined, and then reports success on its own
/// terms. Every question here corresponds to a way that goes wrong — no
/// checkable success means it decides when it is finished; no verification
/// command means it grades its own homework; no cap means it cannot fail, only
/// run out of money; no boundaries means it edits whatever seems related; no
/// stop conditions means it guesses at ambiguity rather than asking.
///
/// **The syntactic review is the floor, not the ceiling.** [reviewGoalObjective]
/// is pure and needs no model call: it cannot tell a good success criterion
/// from a bad one, but it can tell a MISSING one from a present one and it
/// catches the specific phrasings that sound checkable and are not. The model
/// is what turns a rough sentence into the five sections; the review is what
/// refuses to accept the result when a section is missing. Without the review,
/// a model that decides the objective "looks complete" ends the interview
/// early — which is the failure the interview exists to prevent.
class GuidedGoalService {
  /// Creates a [GuidedGoalService].
  GuidedGoalService({
    required AdapterOneShotRunner runner,
    required WorkspaceSettingsRepository settings,
    this.maxTurns = 6,
    Duration timeout = const Duration(minutes: 2),
  }) : _runner = runner,
       _settings = settings,
       _timeout = timeout;

  final AdapterOneShotRunner _runner;
  final WorkspaceSettingsRepository _settings;
  final Duration _timeout;

  /// Cap on interview turns.
  ///
  /// A ceiling on patience, not on rigour: past this the objective is emitted
  /// with whatever it has plus an explicit list of what is still missing, so
  /// the human sees the gap rather than an interview that will not end.
  final int maxTurns;

  /// Runs one interview step against [transcript] so far.
  Future<GuidedGoalStep> step({
    required String workspaceId,
    required String roughObjective,
    List<String> transcript = const [],
  }) async {
    final adapterId = (await _settings.get(
      workspaceId,
      kConversationTitleAdapterSettingKey,
    ))?.trim();
    if (adapterId == null || adapterId.isEmpty) {
      return const GuidedGoalStep(unavailable: true);
    }
    final modelId = (await _settings.get(
      workspaceId,
      kConversationTitleModelSettingKey,
    ))?.trim();

    final String? answer;
    try {
      answer = await _runner.complete(
        adapterId: adapterId,
        modelId: modelId,
        systemPrompt: guidedGoalSystemPrompt,
        prompt: guidedGoalTurnPrompt(
          roughObjective: roughObjective,
          transcript: transcript,
        ),
        timeout: _timeout,
        maxTokens: 1500,
      );
    } on Object catch (e) {
      CcInfraLog.warning('guided goal step failed: $e');
      return const GuidedGoalStep();
    }

    final text = answer?.trim();
    if (text == null || text.isEmpty) {
      return const GuidedGoalStep();
    }

    // A draft is only an objective when the sections are actually there. The
    // model announcing that it is done is not the test — a model that decides
    // the objective "looks complete" is exactly what ends an interview early.
    final review = reviewGoalObjective(text);
    final looksLikeObjective = text.contains('## Objective');
    if (looksLikeObjective && review.isReady) {
      return GuidedGoalStep(objective: text);
    }
    // Past the turn cap, emit what there is WITH the gaps named, rather than
    // asking a seventh question nobody will answer.
    if (transcript.length >= maxTurns * 2 && looksLikeObjective) {
      return GuidedGoalStep(
        objective: text,
        missing: review.missing,
        weaknesses: review.weaknesses,
      );
    }
    return GuidedGoalStep(
      // The model's own question when it asked one; otherwise the highest-value
      // gap the review found, so the interview always advances on something
      // concrete rather than on the model's mood.
      question: looksLikeObjective
          ? review.nextQuestion ?? _firstQuestion(text)
          : _firstQuestion(text) ?? review.nextQuestion,
      missing: review.missing,
      weaknesses: review.weaknesses,
    );
  }

  /// The first question-shaped line in [text].
  static String? _firstQuestion(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.endsWith('?')) {
        return trimmed;
      }
    }
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
