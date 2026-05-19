import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the **motion** tokens (`CcMotion`).
///
/// Motion is short and functional — it reports state change, never decorates.
/// Four durations (instant → slow) and two curves (`standard` easeOut,
/// `emphasized` easeOutCubic). `CcMotion.resolve` collapses every duration to
/// zero under the platform's reduce-motion setting, so the system has a built-in
/// accessible alternative.

const _path = '[Foundations]/Tokens';

@widgetbook.UseCase(name: 'Durations & curves', type: MotionSpecimen, path: _path)
Widget motionSpecimenUseCase(BuildContext context) {
  final duration = context.knobs.object.dropdown<Duration>(
    label: 'Duration',
    options: const [
      CcMotion.instant,
      CcMotion.fast,
      CcMotion.normal,
      CcMotion.slow,
    ],
    labelBuilder: (d) => switch (d.inMilliseconds) {
      0 => 'instant · 0ms',
      120 => 'fast · 120ms',
      180 => 'normal · 180ms',
      _ => 'slow · 240ms',
    },
  );
  final emphasized = context.knobs.boolean(label: 'Emphasized curve');
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
                duration: CcMotion.resolve(context, widget.duration),
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
