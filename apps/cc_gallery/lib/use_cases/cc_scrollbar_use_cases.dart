import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcScrollbar] — the design system's angular scrollbar.
///
/// The thumb is a flat, square-cornered `lineStrong` overlay (zero radius, the
/// design system's geometry) drawn by [RawScrollbar] under the hood. App-wide,
/// [CcScrollBehavior] injects it on every vertical desktop scrollable; these
/// use-cases show the explicit widget for surfaces that need custom control.

const _path = '[Components]/Containers';

/// A vertical list with the always-visible angular thumb — the app default.
@widgetbook.UseCase(name: 'Vertical', type: CcScrollbar, path: _path)
Widget ccScrollbarVerticalUseCase(BuildContext context) {
  return const Center(child: _VerticalDemo());
}

/// A thin horizontal thumb pinned to the bottom edge, as in the editor tab
/// strip.
@widgetbook.UseCase(name: 'Horizontal thin', type: CcScrollbar, path: _path)
Widget ccScrollbarHorizontalUseCase(BuildContext context) {
  return const Center(child: _HorizontalDemo());
}

class _VerticalDemo extends StatefulWidget {
  const _VerticalDemo();

  @override
  State<_VerticalDemo> createState() => _VerticalDemoState();
}

class _VerticalDemoState extends State<_VerticalDemo> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 320,
      height: 220,
      decoration: BoxDecoration(border: Border.all(color: t.borderSecondary)),
      child: CcScrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _controller,
          itemCount: 40,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Run #${1024 + i} — completed',
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalDemo extends StatefulWidget {
  const _HorizontalDemo();

  @override
  State<_HorizontalDemo> createState() => _HorizontalDemoState();
}

class _HorizontalDemoState extends State<_HorizontalDemo> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 320,
      height: 48,
      decoration: BoxDecoration(border: Border.all(color: t.borderSecondary)),
      child: CcScrollbar(
        controller: _controller,
        thumbVisibility: true,
        thickness: 4,
        color: t.fgQuaternary,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: 20,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              'tab_$i.dart',
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
