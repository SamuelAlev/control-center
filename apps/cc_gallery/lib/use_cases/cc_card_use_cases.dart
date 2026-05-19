import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcCard] — the design system's flat panel surface.
///
/// Depth comes from the hairline border, not elevation. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

/// A small block of body copy rendered with the design-system text color.
Widget _copy(BuildContext context, String text) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Text(
    text,
    style: CcTypography.body.copyWith(color: t.textSecondary),
  );
}

/// The two token surfaces side by side: the white `panel` and the tighter
/// secondary `surface`.
@widgetbook.UseCase(name: 'Surfaces', type: CcCard, path: _path)
Widget ccCardSurfacesUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 260,
          child: CcCard(
            tokens: CcCardTokens.panel(t),
            child: _copy(context, 'Panel — the default white workspace surface.'),
          ),
        ),
        SizedBox(
          width: 260,
          child: CcCard(
            tokens: CcCardTokens.surface(t),
            child: _copy(context, 'Surface — the tighter secondary container.'),
          ),
        ),
      ],
    ),
  );
}

/// An interactive card that washes to the hover color and exposes itself as a
/// semantic button. Hover and press it in the canvas.
@widgetbook.UseCase(name: 'Interactive', type: CcCard, path: _path)
Widget ccCardInteractiveUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: SizedBox(
      width: 300,
      child: CcCard(
        interactive: true,
        onPressed: () {},
        semanticLabel: 'Open pull request',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'feat: stream agent transcripts',
              style: CcTypography.label.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 6),
            _copy(context, '#482 · opened by claude-opus · 3 files changed'),
          ],
        ),
      ),
    ),
  );
}

/// Padding scale — from a dense zero-inset row to a roomy detail panel.
@widgetbook.UseCase(name: 'Padding', type: CcCard, path: _path)
Widget ccCardPaddingUseCase(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: CcCard(
            padding: EdgeInsets.zero,
            child: _copy(context, 'No padding — host owns the insets.'),
          ),
        ),
        SizedBox(
          width: 220,
          child: CcCard(
            child: _copy(context, 'Default padding (md).'),
          ),
        ),
        SizedBox(
          width: 220,
          child: CcCard(
            padding: const EdgeInsets.all(28),
            child: _copy(context, 'Roomy padding for a detail panel.'),
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcCard, path: _path)
Widget ccCardPlaygroundUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final useSurface = context.knobs.boolean(label: 'Surface tokens');
  final interactive = context.knobs.boolean(
    label: 'Interactive',
    initialValue: true,
  );
  final padding = context.knobs.double.slider(
    label: 'Padding',
    initialValue: 16,
    min: 0,
    max: 40,
  );
  final body = context.knobs.string(
    label: 'Body',
    initialValue: 'Reviewing the workspace pipeline run.',
  );
  return Center(
    child: SizedBox(
      width: 300,
      child: CcCard(
        tokens: useSurface ? CcCardTokens.surface(t) : CcCardTokens.panel(t),
        interactive: interactive,
        onPressed: interactive ? () {} : null,
        semanticLabel: 'Workspace card',
        padding: EdgeInsets.all(padding),
        child: _copy(context, body),
      ),
    ),
  );
}
