import 'dart:async';

import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_scramble_text.stories.g.dart';

/// Stories for [CcScrambleText] — a label that churns through random
/// characters while its real value is on its way (a conversation title a
/// model is generating), then reveals it character by character.
///
/// The stories below are listed under `Components → Feedback →
/// CcScrambleText`. With reduced motion the label shows as plain text, with
/// no churn and no reveal.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcScrambleText', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcScrambleTextPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    text: StringArg('Git rebase question', name: 'Text'),
    scrambling: BoolArg(true, name: 'Scrambling'),
    durationMs: IntArg(
      800,
      name: 'Reveal duration (ms)',
      style: const SliderIntArgStyle(min: 200, max: 3000, divisions: 28),
    ),
    speedMs: IntArg(
      40,
      name: 'Speed (ms)',
      style: const SliderIntArgStyle(min: 16, max: 200, divisions: 23),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccScrambleTextPlaygroundStory(context, args),
  ),
);

final $TitleGeneration = _Story(
  name: 'Title generation',
  args: _Args.fixed(preview: ccScrambleTextTitleGenerationStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcScrambleTextPlayground {
  CcScrambleTextPlayground({
    required this.text,
    required this.scrambling,
    required this.durationMs,
    required this.speedMs,
  });

  final String text;
  final bool scrambling;
  final int durationMs;
  final int speedMs;
}

/// A conversation being named, on a loop: the placeholder churns while the
/// "model" works, then the generated title is revealed. Shown at the three
/// places the app uses it — the tab, the conversation header and the
/// sidebar row.
Widget ccScrambleTextTitleGenerationStory(BuildContext context) =>
    const Center(child: _TitleGenerationLoop());

/// Interactive playground — flip Scrambling off to watch the reveal.
Widget ccScrambleTextPlaygroundStory(
  BuildContext context,
  CcScrambleTextPlaygroundArgs args,
) {
  final t = context.designSystem;
  return Center(
    child: CcScrambleText(
      args.text,
      scrambling: args.scrambling,
      duration: Duration(milliseconds: args.durationMs),
      speed: Duration(milliseconds: args.speedMs),
      style: CcTypography.body.copyWith(
        fontWeight: FontWeight.w600,
        color: t?.textPrimary,
      ),
    ),
  );
}

class _TitleGenerationLoop extends StatefulWidget {
  const _TitleGenerationLoop();

  @override
  State<_TitleGenerationLoop> createState() => _TitleGenerationLoopState();
}

class _TitleGenerationLoopState extends State<_TitleGenerationLoop> {
  static const _placeholder = 'Untitled conversation';
  static const _titles = [
    'Git rebase question',
    'Flaky sidebar widget test',
    'Adding RTL support to diffs',
  ];

  Timer? _timer;
  var _index = 0;
  var _generating = true;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Generates for 2.5s, holds the title for 3s, then names the next one.
  void _schedule() {
    _timer = Timer(
      Duration(milliseconds: _generating ? 2500 : 3000),
      () => setState(() {
        if (!_generating) {
          _index = (_index + 1) % _titles.length;
        }
        _generating = !_generating;
        _schedule();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem;
    final text = _generating ? _placeholder : _titles[_index];
    Widget sample(String label, TextStyle style) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CcTypography.caption.copyWith(color: t?.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          CcScrambleText(text, scrambling: _generating, style: style),
        ],
      ),
    );
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sample(
            'Tab',
            TextStyle(
              fontSize: 12,
              fontWeight: CcTypography.mediumWeight,
              color: t?.textPrimary,
            ),
          ),
          sample(
            'Header',
            CcTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: t?.textPrimary,
            ),
          ),
          sample(
            'Sidebar',
            CcTypography.bodySm.copyWith(color: t?.textSecondary),
          ),
        ],
      ),
    );
  }
}
