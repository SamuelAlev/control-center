import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_launch_options.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/focus_on_mount.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turns a rough `/goal` into an objective an agent can pursue unsupervised.
///
/// Why this interrupts at all. An autonomous goal is the one place a vague
/// brief is genuinely expensive: the run works for hours on an objective whose
/// "done" nobody defined, and then reports success on its own terms. Six
/// questions here are cheaper than one overnight run that finished whenever it
/// felt finished.
///
/// It never blocks. Every step offers "skip and run as written", because a
/// person who knows exactly what they want should not have to argue with an
/// interviewer to get it. The interview is a default, not a gate.
///
/// Once the objective is ready, the person may add checks, a separate
/// checker, and the fresh and unattended options ([GoalLaunchOptions]);
/// Start returns the body with them in it ([composeGoalBody]).
class GuidedGoalDialog extends ConsumerStatefulWidget {
  /// Creates a [GuidedGoalDialog].
  const GuidedGoalDialog({
    required this.rough,
    required this.step,
    this.goalAgentId,
    super.key,
  });

  /// The objective as the human first typed it.
  final String rough;

  /// Runs one interview step against the transcript so far.
  final Future<GuidedGoalStepResult> Function(List<String> transcript) step;

  /// The agent that will pursue the goal, when known: not offered as its
  /// checker, and the provider the checker recommendation differs from.
  final String? goalAgentId;

  @override
  ConsumerState<GuidedGoalDialog> createState() => _GuidedGoalDialogState();
}

class _GuidedGoalDialogState extends ConsumerState<GuidedGoalDialog> {
  final _controller = TextEditingController();
  final _transcript = <String>[];
  String? _question;
  String? _objective;
  List<String> _missing = const [];
  var _loading = true;
  var _choice = const GoalLaunchChoice();
  var _checksValid = true;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    setState(() => _loading = true);
    final GuidedGoalStepResult result;
    try {
      result = await widget.step(List.of(_transcript));
    } on Object {
      // A failed interview must never trap the objective: fall through to the
      // raw text, which is what the person asked for in the first place.
      if (mounted) {
        Navigator.of(context).pop(widget.rough);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (result.unavailable) {
      Navigator.of(context).pop(widget.rough);
      return;
    }
    setState(() {
      _loading = false;
      _question = result.question;
      _objective = result.objective;
      _missing = result.missing;
    });
    if (result.objective == null && result.question == null) {
      Navigator.of(context).pop(widget.rough);
    }
  }

  void _answer() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      return;
    }
    _transcript
      ..add('Q: ${_question ?? ''}')
      ..add('A: $answer');
    _controller.clear();
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.ds;
    final objective = _objective;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId == null
        ? const <Never>[]
        : ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const [];

    return CcDialog(
      title: l10n.guidedGoalTitle,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.guidedGoalIntro,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: CcSpinner(),
              )
            else if (objective != null) ...[
              if (_missing.isNotEmpty) ...[
                Text(
                  l10n.guidedGoalStillMissing(_missing.join(', ')),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textWarningPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(objective, style: CcTypography.body),
                      const SizedBox(height: AppSpacing.lg),
                      GoalLaunchOptions(
                        agents: agents,
                        goalAgentId: widget.goalAgentId,
                        choice: _choice,
                        onChanged: (choice, checksValid) => setState(() {
                          _choice = choice;
                          _checksValid = checksValid ?? _checksValid;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(_question ?? '', style: CcTypography.body),
              const SizedBox(height: AppSpacing.md),
              // Asked for outright on each question: an autofocus would yield
              // to a dialog button focused earlier (Skip), which is where Next
              // hands focus as it goes.
              FocusOnMount(
                builder: (context, focusNode) => CcTextField(
                  controller: _controller,
                  focusNode: focusNode,
                  hintText: l10n.guidedGoalAnswerHint,
                  maxLines: 3,
                  onSubmitted: (_) => _answer(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(widget.rough),
          child: Text(l10n.guidedGoalSkip),
        ),
        if (!_loading)
          CcButton(
            onPressed: objective == null
                ? _answer
                : _checksValid
                ? () => Navigator.of(
                    context,
                  ).pop(composeGoalBody(objective, _choice))
                : null,
            child: Text(
              objective == null ? l10n.guidedGoalNext : l10n.guidedGoalStart,
            ),
          ),
      ],
    );
  }
}
