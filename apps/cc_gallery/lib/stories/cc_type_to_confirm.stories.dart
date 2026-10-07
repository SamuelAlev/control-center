import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_type_to_confirm.stories.g.dart';

/// Stories for [CcTypeToConfirmPrompt] — the sentence a destructive dialog asks
/// the operator to type back, with the value set in a copyable chip.
///
/// The chip is the value, not a separate control beside the sentence: a
/// translation can place it anywhere by keeping the placeholder the labels
/// are called with. Tap the chip to copy; the glyph swaps to a check until
/// the copied state resets.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcTypeToConfirmPrompt', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTypeToConfirmPromptPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(value: StringArg('acme-prod', name: 'Value')),
  builder: (context, args) => Showcase.playground(
    (context) => ccTypeToConfirmPlaygroundStory(context, args),
  ),
);

final $Default = _Story(
  args: _Args.fixed(preview: ccTypeToConfirmDefaultStory),
);

final $ValueMidSentence = _Story(
  name: 'Value mid-sentence',
  args: _Args.fixed(preview: ccTypeToConfirmMidSentenceStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTypeToConfirmPromptPlayground {
  CcTypeToConfirmPromptPlayground({required this.value});

  final String value;
}

/// The prompt as a confirm dialog shows it, against a width close to the
/// dialog's own.
Widget ccTypeToConfirmDefaultStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: CcTypeToConfirmPrompt(value: 'acme-prod'),
    ),
  );
}

/// The value sitting somewhere other than the end of the sentence, which is
/// what a translation that leads with the name has to do.
Widget ccTypeToConfirmMidSentenceStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 420,
      child: CcTypeToConfirmPrompt(
        value: 'acme-prod',
        labels: CcTypeToConfirmLabels(
          prompt: (value) => '「$value」と入力して確定します。',
          copy: 'コピー',
          copied: 'コピーしました',
        ),
      ),
    ),
  );
}

/// Interactive playground — drive the value the chip copies.
Widget ccTypeToConfirmPlaygroundStory(
  BuildContext context,
  CcTypeToConfirmPromptPlaygroundArgs args,
) {
  final value = args.value;
  return Center(
    child: SizedBox(width: 420, child: CcTypeToConfirmPrompt(value: value)),
  );
}
