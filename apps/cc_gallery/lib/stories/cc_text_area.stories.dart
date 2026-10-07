import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_text_area.stories.g.dart';

/// Stories for [CcTextArea] — the design system's multi-line text input.
///
/// The stories below are listed under `Components → Inputs → CcTextArea` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcTextArea', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTextAreaPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    hintText: StringArg(
      'Describe the change for this pull request…',
      name: 'Hint text',
    ),
    errorText: StringArg('', name: 'Error text'),
    enabled: BoolArg(true, name: 'Enabled'),
    minLines: IntArg(
      3,
      name: 'Min lines',
      style: const SliderIntArgStyle(min: 1, max: 8, divisions: 7),
    ),
    maxLength: IntArg(
      280,
      name: 'Max length',
      style: const SliderIntArgStyle(min: 40, max: 600, divisions: 70),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccTextAreaPlaygroundStory(context, args),
  ),
);

final $EmptyAndFilled = _Story(
  name: 'Empty and filled',
  args: _Args.fixed(preview: ccTextAreaEmptyAndFilledStory),
);

final $ErrorAndDisabled = _Story(
  name: 'Error and disabled',
  args: _Args.fixed(preview: ccTextAreaErrorAndDisabledStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTextAreaPlayground {
  CcTextAreaPlayground({
    required this.hintText,
    required this.errorText,
    required this.enabled,
    required this.minLines,
    required this.maxLength,
  });

  final String hintText;
  final String errorText;
  final bool enabled;
  final int minLines;
  final int maxLength;
}

/// Empty resting state next to a pre-filled one, so the hint vs. content
/// treatment reads at a glance.
Widget ccTextAreaEmptyAndFilledStory(BuildContext context) {
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
Widget ccTextAreaErrorAndDisabledStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTextArea(
            hintText: 'Review summary',
            errorText:
                'A review summary is required before requesting changes.',
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

/// Interactive playground — drive every arg to see the full state space.
Widget ccTextAreaPlaygroundStory(
  BuildContext context,
  CcTextAreaPlaygroundArgs args,
) {
  final hintText = args.hintText;
  final errorText = args.errorText;
  final enabled = args.enabled;
  final minLines = args.minLines;
  final maxLength = args.maxLength;
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
    text:
        'Migrate the dispatch path onto `claude -p --output-format '
        'stream-json` so agents stream structured events instead of shelling '
        'out, then backfill the workspace isolation tests for the new '
        'run-process lifecycle.',
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
