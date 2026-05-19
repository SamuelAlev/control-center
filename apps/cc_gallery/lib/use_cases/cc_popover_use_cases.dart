import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcPopover] — a flat floating panel anchored to a trigger.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Navigation & Overlays → CcPopover`. Builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

void _noop() {}

/// A simple filter popover anchored under a button — the canonical usage.
@widgetbook.UseCase(name: 'Default', type: CcPopover, path: _path)
Widget ccPopoverDefaultUseCase(BuildContext context) {
  return Center(
    child: CcPopover(
      semanticLabel: 'Filter pull requests',
      target: const CcButton(
        variant: CcButtonVariant.secondary,
        icon: LucideIcons.listFilter,
        onPressed: _noop,
        child: Text('Filter'),
      ),
      overlayBuilder: (context, targetSize) {
        final t = context.designSystem!;
        return SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by status',
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: 10),
                for (final status in const ['Open', 'Merged', 'Closed']) ...[
                  Text(
                    status,
                    style: CcTypography.body.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Width-matched dropdown — the panel is constrained to the trigger's width,
/// the way a select or workspace switcher renders.
@widgetbook.UseCase(name: 'Match target width', type: CcPopover, path: _path)
Widget ccPopoverMatchWidthUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 260,
      child: CcPopover(
        matchTargetWidth: true,
        semanticLabel: 'Switch workspace',
        target: const CcButton(
          variant: CcButtonVariant.line,
          icon: LucideIcons.folderGit2,
          onPressed: _noop,
          child: Text('control-center'),
        ),
        overlayBuilder: (context, targetSize) {
          final t = context.designSystem!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ws in const ['control-center', 'rift', 'cc-ui'])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      ws,
                      style: CcTypography.body.copyWith(color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Driven by an external [CcOverlayController] — open/close is owned by the
/// host, here wired to a second button alongside the anchor.
@widgetbook.UseCase(name: 'Controller driven', type: CcPopover, path: _path)
Widget ccPopoverControllerUseCase(BuildContext context) {
  return const Center(child: _ControllerPopoverDemo());
}

/// Interactive playground — drive placement and dismissal behaviour.
@widgetbook.UseCase(name: 'Playground', type: CcPopover, path: _path)
Widget ccPopoverPlaygroundUseCase(BuildContext context) {
  final matchWidth = context.knobs.boolean(label: 'Match target width');
  final barrierDismissible = context.knobs.boolean(
    label: 'Barrier dismissible',
    initialValue: true,
  );
  final offsetY = context.knobs.double.slider(
    label: 'Vertical offset',
    initialValue: 6,
    min: 0,
    max: 24,
  );
  return Center(
    child: CcPopover(
      matchTargetWidth: matchWidth,
      barrierDismissible: barrierDismissible,
      offset: Offset(0, offsetY),
      semanticLabel: 'Agent actions',
      target: const CcButton(
        icon: LucideIcons.bot,
        onPressed: _noop,
        child: Text('Architect'),
      ),
      overlayBuilder: (context, targetSize) {
        final t = context.designSystem!;
        return SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final action in const ['Dispatch', 'View runs', 'Stop'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      action,
                      style: CcTypography.body.copyWith(color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ControllerPopoverDemo extends StatefulWidget {
  const _ControllerPopoverDemo();

  @override
  State<_ControllerPopoverDemo> createState() => _ControllerPopoverDemoState();
}

class _ControllerPopoverDemoState extends State<_ControllerPopoverDemo> {
  final _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcButton(
          variant: CcButtonVariant.secondary,
          icon: LucideIcons.sparkles,
          onPressed: _controller.show,
          child: const Text('Open details'),
        ),
        const SizedBox(width: 12),
        CcPopover(
          controller: _controller,
          toggleOnTargetTap: false,
          target: const CcButton(
            variant: CcButtonVariant.ghost,
            icon: LucideIcons.gitPullRequest,
            onPressed: _noop,
            child: Text('PR #128'),
          ),
          overlayBuilder: (context, targetSize) {
            final t = context.designSystem!;
            return SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wire the dispatch engine',
                      style: CcTypography.title.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reviewed by claude-opus · 3 files changed',
                      style:
                          CcTypography.caption.copyWith(color: t.textTertiary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
