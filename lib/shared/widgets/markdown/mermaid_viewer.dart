import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:flutter/widgets.dart';

/// Expanded diagram canvas with the same zoom/fit controls as other canvases.
class AppMermaidViewer extends StatefulWidget {
  /// Creates an expanded viewer. The parent supplies bounded height.
  const AppMermaidViewer({
    required this.source,
    required this.style,
    super.key,
  });

  /// Mermaid source, shared with the inline figure.
  final String source;

  /// Host-resolved colors and text metrics, preserved when expanding.
  final CcMermaidStyle style;

  @override
  State<AppMermaidViewer> createState() => _AppMermaidViewerState();
}

class _AppMermaidViewerState extends State<AppMermaidViewer> {
  final _controller = CcMermaidViewportController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CcMermaidView(
            source: widget.source,
            style: widget.style,
            interactive: true,
            controller: _controller,
          ),
        ),
        // Keep controls outside the drawing so no node or label is obscured.
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => CanvasZoomControls(
              controller: _controller,
              viewport: () => _controller.viewportSize,
              minScale: _controller.minScale,
              maxScale: _controller.maxScale,
              onReset: _controller.fit,
            ),
          ),
        ),
      ],
    );
  }
}
