import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTextArea] — the design system's multi-line text input.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcTextArea`. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Inputs';

/// Empty resting state next to a pre-filled one, so the hint vs. content
/// treatment reads at a glance.
@widgetbook.UseCase(name: 'Empty and filled', type: CcTextArea, path: _path)
Widget ccTextAreaEmptyAndFilledUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTextArea(hintText: 'Describe the change for this pull request…'),
          SizedBox(height: 16),
          _FilledTextArea(),
        ],
      ),
    ),
  );
}

/// The error and disabled treatments. Error swaps the border and background;
/// disabled greys the text and drops the focus affordance.
@widgetbook.UseCase(name: 'Error and disabled', type: CcTextArea, path: _path)
Widget ccTextAreaErrorAndDisabledUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTextArea(
            hintText: 'Review summary',
            errorText: 'A review summary is required before requesting changes.',
          ),
          SizedBox(height: 16),
          CcTextArea(
            enabled: false,
            hintText: 'Read-only while the agent is running…',
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcTextArea, path: _path)
Widget ccTextAreaPlaygroundUseCase(BuildContext context) {
  final hintText = context.knobs.string(
    label: 'Hint text',
    initialValue: 'Describe the change for this pull request…',
  );
  final errorText = context.knobs.string(
    label: 'Error text',
    initialValue: '',
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final minLines = context.knobs.double
      .slider(label: 'Min lines', initialValue: 3, min: 1, max: 8)
      .round();
  final maxLength = context.knobs.double
      .slider(label: 'Max length', initialValue: 280, min: 40, max: 600)
      .round();
  return Center(
    child: SizedBox(
      width: 380,
      child: CcTextArea(
        hintText: hintText,
        errorText: errorText.isEmpty ? null : errorText,
        enabled: enabled,
        minLines: minLines,
        maxLength: maxLength,
      ),
    ),
  );
}

/// Owns a controller seeded with sample content so the filled state renders
/// without typing. Disposes the controller it creates.
class _FilledTextArea extends StatefulWidget {
  const _FilledTextArea();

  @override
  State<_FilledTextArea> createState() => _FilledTextAreaState();
}

class _FilledTextAreaState extends State<_FilledTextArea> {
  late final TextEditingController _controller = TextEditingController(
    text: 'Migrate the dispatch path onto the Claude relay so agents stop '
        'shelling out to `claude -p`, then backfill the workspace isolation '
        'tests for the new run-process lifecycle.',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcTextArea(
      controller: _controller,
      hintText: 'Describe the change…',
      minLines: 4,
    );
  }
}
