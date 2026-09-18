import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the **motion** tokens (`CcMotion`).
///
/// Three enter speeds, a faster exit for each, and one fade kept under
/// reduced motion. No component invents its own timing.

const _path = '[Foundations]/Tokens';

@widgetbook.UseCase(
  name: 'Three speeds',
  type: MotionSpeedsSpecimen,
  path: _path,
)
Widget motionSpeedsUseCase(BuildContext context) =>
    const MotionSpeedsSpecimen();

@widgetbook.UseCase(
  name: 'Durations & curves',
  type: MotionSpecimen,
  path: _path,
)
Widget motionSpecimenUseCase(BuildContext context) {
  final duration = context.knobs.object.dropdown<Duration>(
    label: 'Duration',
    options: const [
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
  );
  final emphasized = context.knobs.boolean(label: 'Emphasized curve');
  return MotionSpecimen(
    duration: duration,
    curve: emphasized ? CcMotion.emphasized : CcMotion.standard,
  );
}

@widgetbook.UseCase(name: 'Fluid hover', type: FluidHoverSpecimen, path: _path)
Widget fluidHoverSpecimenUseCase(BuildContext context) {
  return const FluidHoverSpecimen();
}

/// Click a track to fire the enter spring, then the matching exit.
class MotionSpeedsSpecimen extends StatelessWidget {
  /// Creates the three-speed motion specimen.
  const MotionSpeedsSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Three speeds',
              style: CcTypography.title.copyWith(color: t.textPrimary),
            ),
            AppSpacing.vGapSm,
            Text(
              'Hover and small toggles use fast. Dropdowns and tabs use '
              'moderate. Dialogs and drawers use slow. Click a track to fire '
              'the enter, then the faster exit.',
              style: CcTypography.body.copyWith(color: t.textSecondary),
            ),
            AppSpacing.vGapLg,
            const _SpringTrack(
              label: 'fast',
              enter: CcMotion.fast,
              uses: 'Hover, fades, focus rings, checkbox, radio, tooltip',
            ),
            AppSpacing.vGapLg,
            const _SpringTrack(
              label: 'moderate',
              enter: CcMotion.moderate,
              uses: 'Dropdowns, tabs, switch thumb, toasts, short panels',
            ),
            AppSpacing.vGapLg,
            const _SpringTrack(
              label: 'slow',
              enter: CcMotion.slow,
              uses: 'Dialogs, drawers, large chrome',
            ),
            AppSpacing.vGapXl,
            Text(
              'Slow in, faster out',
              style: CcTypography.title.copyWith(color: t.textPrimary),
            ),
            AppSpacing.vGapSm,
            Text(
              'Both panels open on slow. The left leaves on the same slow; '
              'the right leaves on slow.exit. Toggle the left first — that '
              'slight drag on the way out is what the exit token avoids.',
              style: CcTypography.body.copyWith(color: t.textSecondary),
            ),
            AppSpacing.vGapMd,
            const Row(
              children: [
                Expanded(child: _ExitCompare(fasterExit: false)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: _ExitCompare(fasterExit: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpringTrack extends StatefulWidget {
  const _SpringTrack({
    required this.label,
    required this.enter,
    required this.uses,
  });

  final String label;
  final Duration enter;
  final String uses;

  @override
  State<_SpringTrack> createState() => _SpringTrackState();
}

class _SpringTrackState extends State<_SpringTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _controller, curve: CcMotion.standard);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fire() async {
    if (!mounted) {
      return;
    }
    final reduced = CcMotion.reduced(context);
    _controller.duration = reduced
        ? CcMotion.fade
        : CcMotion.resolveTravel(context, widget.enter);
    await _controller.forward(from: 0);
    if (!mounted) {
      return;
    }
    _controller.duration = reduced
        ? CcMotion.fade
        : CcMotion.resolveTravel(context, CcMotion.exitFor(widget.enter));
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    final reduced = CcMotion.reduced(context);
    final exit = CcMotion.exitFor(widget.enter);
    return GestureDetector(
      onTap: _fire,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: CcTypography.label.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '→ ${widget.enter.inMilliseconds}ms   '
            '← ${exit.inMilliseconds}ms',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.uses,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: t.borderPrimary),
            ),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: AnimatedBuilder(
                  animation: _curve,
                  builder: (context, _) {
                    final travel = reduced ? 1.0 : _curve.value;
                    final opacity = reduced ? _curve.value : 1.0;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.12 + travel * 0.88,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: opacity,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: t.fg,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExitCompare extends StatefulWidget {
  const _ExitCompare({required this.fasterExit});

  final bool fasterExit;

  @override
  State<_ExitCompare> createState() => _ExitCompareState();
}

class _ExitCompareState extends State<_ExitCompare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _controller, curve: CcMotion.emphasized);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!mounted) {
      return;
    }
    final reduced = CcMotion.reduced(context);
    if (_open) {
      _controller.duration = reduced
          ? CcMotion.fade
          : widget.fasterExit
          ? CcMotion.slowExit
          : CcMotion.slow;
      await _controller.reverse();
      if (mounted) {
        setState(() => _open = false);
      }
    } else {
      setState(() => _open = true);
      _controller.duration = reduced ? CcMotion.fade : CcMotion.slow;
      await _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _toggle,
          child: Text(_open ? 'Close panel' : 'Open panel'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.fasterExit
              ? 'Faster exit · slow.exit'
              : 'Same exit time · slow',
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 88,
          child: FadeTransition(
            opacity: _curve,
            child: CcMotion.reduced(context)
                ? _panel(t)
                : ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(_curve),
                    child: _panel(t),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _panel(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderPrimary),
        boxShadow: CcElevation.floating,
      ),
      child: Center(
        child: Text(
          widget.fasterExit ? 'Leaves quicker' : 'Drags on the way out',
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}

/// Shows nearest-target hover motion across one- and two-dimensional layouts.
class FluidHoverSpecimen extends StatelessWidget {
  /// Creates the fluid-hover motion specimen.
  const FluidHoverSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Center(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.xl,
        children: [
          _Specimen(
            label: 'Vertical list',
            width: 260,
            child: CcFluidHover(
              itemCount: 4,
              layoutBuilder: (context, children) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
              itemBuilder: (context, index) => CcTile(
                title: 'Workspace ${index + 1}',
                leadingIcon: CcIcons.folder,
                onTap: () {},
              ),
            ),
          ),
          _Specimen(
            label: 'Horizontal strip',
            width: 360,
            child: CcFluidHover(
              itemCount: 4,
              axis: CcFluidHoverAxis.x,
              layoutBuilder: (context, children) => Row(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    Expanded(child: children[index]),
                    if (index != children.length - 1)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
              itemBuilder: (context, index) => CcTappable(
                onPressed: () {},
                borderRadius: AppRadii.brSm,
                builder: (context, states) => SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      ['Overview', 'Activity', 'Runs', 'Files'][index],
                      style: CcTypography.label.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _Specimen(
            label: 'Two-dimensional grid',
            width: 360,
            child: SizedBox(
              height: 184,
              child: CcFluidHover(
                itemCount: 6,
                axis: CcFluidHoverAxis.xy,
                borderRadius: AppRadii.brLg,
                layoutBuilder: (context, children) => GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                  children: children,
                ),
                itemBuilder: (context, index) => CcCard(
                  interactive: true,
                  onPressed: () {},
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CcIcons.code, size: 18, color: t.textSecondary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Repo ${index + 1}',
                        style: CcTypography.label.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CcTypography.label.copyWith(color: t.textSecondary),
          ),
          AppSpacing.vGapSm,
          child,
        ],
      ),
    );
  }
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
