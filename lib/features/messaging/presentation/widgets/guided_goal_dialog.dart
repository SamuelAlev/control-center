import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Turns a rough `/goal` into an objective an agent can pursue unsupervised.
///
/// **Why this interrupts at all.** An autonomous goal is the one place a vague
/// brief is genuinely expensive: the run works for hours on an objective whose
/// "done" nobody defined, and then reports success on its own terms. Six
/// questions here are cheaper than one overnight run that finished whenever it
/// felt finished.
///
/// **It never blocks.** Every step offers "skip and run as written", because a
/// person who knows exactly what they want should not have to argue with an
/// interviewer to get it. The interview is a default, not a gate.
class GuidedGoalDialog extends StatefulWidget {
  /// Creates a [GuidedGoalDialog].
  const GuidedGoalDialog({required this.rough, required this.step, super.key});

  /// The objective as the human first typed it.
  final String rough;

  /// Runs one interview step against the transcript so far.
  final Future<GuidedGoalStepResult> Function(List<String> transcript) step;

  @override
  State<GuidedGoalDialog> createState() => _GuidedGoalDialogState();
}

class _GuidedGoalDialogState extends State<GuidedGoalDialog> {
  final _controller = TextEditingController();
  final _transcript = <String>[];
  String? _question;
  String? _objective;
  List<String> _missing = const [];
  var _loading = true;

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
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Text(objective, style: CcTypography.body),
                ),
              ),
            ] else ...[
              Text(_question ?? '', style: CcTypography.body),
              const SizedBox(height: AppSpacing.md),
              CcTextField(
                controller: _controller,
                hintText: l10n.guidedGoalAnswerHint,
                maxLines: 3,
                autofocus: true,
                onSubmitted: (_) => _answer(),
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
                : () => Navigator.of(context).pop(objective),
            child: Text(
              objective == null ? l10n.guidedGoalNext : l10n.guidedGoalStart,
            ),
          ),
      ],
    );
  }
}
