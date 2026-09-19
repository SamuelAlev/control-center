import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:flutter/widgets.dart';

/// Floating tidy + zoom stack for the pipeline editor. Tidy sits above zoom
/// so both share the same corner without competing for the same hit target.
class PipelineEditorControls extends StatelessWidget {
  /// Creates a [PipelineEditorControls].
  const PipelineEditorControls({
    super.key,
    required this.controller,
    required this.viewport,
    required this.onFit,
    required this.onTidy,
  });

  /// Shared with the InteractiveViewer.
  final TransformationController controller;

  /// Viewport size, read on press (see [CanvasZoomControls.viewport]).
  final ValueGetter<Size> viewport;

  /// Fit-to-content — the zoom stack's reset.
  final VoidCallback onFit;

  /// Auto-layout; the screen owns the x/y rewrite.
  final VoidCallback onTidy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: tokens.bgPrimary,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: tokens.borderSecondary),
              borderRadius: AppRadii.brMd,
            ),
            shadows: AppShadows.soft,
          ),
          child: CcIconButton(
            icon: AppIcons.layoutGrid,
            tooltip: l10n.pipelineTidyUp,
            semanticLabel: l10n.pipelineTidyUp,
            onPressed: onTidy,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CanvasZoomControls(
          controller: controller,
          viewport: viewport,
          minScale: kPipelineEditorMinScale,
          maxScale: kPipelineEditorMaxScale,
          onReset: onFit,
        ),
      ],
    );
  }
}

/// Quiet bottom-start chip reminding the operator how to edit the graph.
class PipelineEditorHintChip extends StatelessWidget {
  /// Creates a [PipelineEditorHintChip].
  const PipelineEditorHintChip({super.key, required this.label});

  /// Localized hint copy.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgPrimary.withValues(alpha: 0.85),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: tokens.textPrimary),
        ),
      ),
    );
  }
}
