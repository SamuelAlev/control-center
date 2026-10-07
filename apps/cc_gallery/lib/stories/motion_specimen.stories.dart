import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'motion_specimen.stories.g.dart';

/// Foundation stories for the **motion** tokens (`CcMotion`).
///
/// Three enter speeds, a faster exit for each, and one fade kept under
/// reduced motion. No component invents its own timing.

const _path = '[Foundations]/Tokens';

const component = ComponentMeta(name: 'MotionSpecimen', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: MotionSpecimenPlayground.new,
);

final $DurationsCurves = _PlaygroundStory(
  name: 'Durations & curves',
  args: _PlaygroundArgs(
    duration: SingleArg<Duration>(
      CcMotion.instant,
      name: 'Duration',
      values: const [
        CcMotion.instant,
        CcMotion.fast,
        CcMotion.moderate,
        CcMotion.slow,
      ],
      labelBuilder: (d) => switch (d.inMilliseconds) {
        0 => 'instant · 0ms',
        80 => 'fast · 80ms',
        160 => 'moderate · 160ms',
        _ => 'slow · 240ms',
      },
    ),
    emphasized: BoolArg(false, name: 'Emphasized curve'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => motionSpecimenStory(context, args)),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class MotionSpecimenPlayground {
  MotionSpecimenPlayground({required this.duration, required this.emphasized});

  final Duration duration;
  final bool emphasized;
}

Widget motionSpecimenStory(
  BuildContext context,
  MotionSpecimenPlaygroundArgs args,
) {
  final duration = args.duration;
  final emphasized = args.emphasized;
  return MotionSpecimen(
    duration: duration,
    curve: emphasized ? CcMotion.emphasized : CcMotion.standard,
  );
}

/// Specimen: tap the surface to replay the transition with the chosen token.
class MotionSpecimen extends StatefulWidget {
  /// Creates a [MotionSpecimen] for the given [duration] + [curve].
  const MotionSpecimen({
    required this.duration,
    required this.curve,
    super.key,
  });

  /// The transition duration token under test.
  final Duration duration;

  /// The easing curve token under test.
  final Curve curve;

  @override
  State<MotionSpecimen> createState() => _MotionSpecimenState();
}

class _MotionSpecimenState extends State<MotionSpecimen> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _on = !_on),
            child: Container(
              width: 320,
              height: 120,
              alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadii.brLg,
                border: Border.all(color: t.borderPrimary),
              ),
              child: AnimatedContainer(
                duration: CcMotion.resolveTravel(context, widget.duration),
                curve: widget.curve,
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _on ? t.accent : t.idle,
                  borderRadius: AppRadii.brMd,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tap to replay · ${widget.duration.inMilliseconds}ms',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}
