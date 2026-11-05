import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/content_synthesizer_resolver.dart';

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

  /// Whether the workspace has no content synthesizer to interview with.
  final bool unavailable;

  /// Whether the interview is finished.
  bool get isReady => objective != null;
}

/// Turns a rough request into an unsupervised agent objective via interview.
///
/// Vague briefs are expensive on long autonomous runs. Each question maps to a
/// failure mode: missing success/verification/cap/boundaries/stop conditions.
/// [reviewGoalObjective] is the syntactic floor (missing vs present; fake-
/// checkable phrasing) — without it a model can end the interview early.
class GuidedGoalService {
  /// Creates a [GuidedGoalService].
  GuidedGoalService({
    required this._runner,
    required this._synthesizer,
    this.maxTurns = 6,
    this._timeout = const Duration(minutes: 2),
  });

  final AdapterOneShotRunner _runner;
  final ContentSynthesizerResolver _synthesizer;
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
    final synthesizer = await _synthesizer.forWorkspace(workspaceId);
    if (synthesizer == null) {
      return const GuidedGoalStep(unavailable: true);
    }

    final String? answer;
    try {
      answer = await _runner.complete(
        adapterId: synthesizer.adapterId,
        modelId: synthesizer.modelId,
        systemPrompt: synthesizer.systemPromptFor(guidedGoalSystemPrompt),
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
