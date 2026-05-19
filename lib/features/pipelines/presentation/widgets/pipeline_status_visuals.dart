import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolved colors for rendering a pipeline run / step status, sourced from the
/// design system semantic tokens.
///
/// One source of truth shared by the status badge, the run cards, and the
/// canvas nodes so a given status always reads the same everywhere.
class PipelineStatusColors {
  /// Creates a [PipelineStatusColors].
  const PipelineStatusColors({
    required this.foreground,
    required this.background,
    required this.dot,
    required this.border,
  });

  /// Text / icon color on top of [background].
  final Color foreground;

  /// Subtle fill behind a badge or node.
  final Color background;

  /// Solid status-indicator dot color.
  final Color dot;

  /// Outline color for canvas nodes.
  final Color border;
}

/// Semantic intent a status maps onto.
enum _Tone { neutral, brand, success, warning, error }

PipelineStatusColors _colorsFor(_Tone tone, DesignSystemTokens t) {
  return switch (tone) {
    _Tone.neutral => PipelineStatusColors(
        foreground: t.textTertiary,
        background: t.bgSecondary,
        dot: t.fgQuaternary,
        border: t.borderSecondary,
      ),
    _Tone.brand => PipelineStatusColors(
        // The dot mirrors the foreground rather than fgBrandPrimary: in dark
        // mode bgBrandPrimary is a bright solid (brand500) and fgBrandPrimary
        // is the same brand500, so a brand dot vanishes into the badge fill.
        // textBrandSecondary is the token proven to contrast with bgBrandPrimary
        // in both themes (brand700 on brand50 light, gray300 on brand500 dark).
        foreground: t.textBrandSecondary,
        background: t.bgBrandPrimary,
        dot: t.textBrandSecondary,
        border: t.borderBrand,
      ),
    _Tone.success => PipelineStatusColors(
        foreground: t.textSuccessPrimary,
        background: t.bgSuccessPrimary,
        dot: t.fgSuccessSecondary,
        border: t.fgSuccessSecondary,
      ),
    _Tone.warning => PipelineStatusColors(
        foreground: t.textWarningPrimary,
        background: t.bgWarningPrimary,
        dot: t.fgWarningSecondary,
        border: t.fgWarningSecondary,
      ),
    _Tone.error => PipelineStatusColors(
        foreground: t.textErrorPrimary,
        background: t.bgErrorPrimary,
        dot: t.fgErrorSecondary,
        border: t.borderError,
      ),
  };
}

/// Status colors for a pipeline run status.
PipelineStatusColors pipelineRunStatusColors(
  PipelineRunStatus status,
  DesignSystemTokens tokens,
) {
  final tone = switch (status) {
    PipelineRunStatus.pending => _Tone.neutral,
    PipelineRunStatus.running => _Tone.brand,
    PipelineRunStatus.suspended => _Tone.warning,
    PipelineRunStatus.completed => _Tone.success,
    PipelineRunStatus.failed => _Tone.error,
    PipelineRunStatus.cancelled => _Tone.neutral,
  };
  return _colorsFor(tone, tokens);
}

/// Status colors for a pipeline step status.
PipelineStatusColors pipelineStepStatusColors(
  PipelineStepStatus status,
  DesignSystemTokens tokens,
) {
  final tone = switch (status) {
    PipelineStepStatus.pending => _Tone.neutral,
    PipelineStepStatus.running => _Tone.brand,
    PipelineStepStatus.suspended => _Tone.warning,
    PipelineStepStatus.completed => _Tone.success,
    PipelineStepStatus.failed => _Tone.error,
    PipelineStepStatus.skipped => _Tone.neutral,
    PipelineStepStatus.cancelled => _Tone.neutral,
  };
  return _colorsFor(tone, tokens);
}

/// Status glyph for a step, so state reads by shape and not color alone
/// (the Status-Never-Alone rule). Shared by the timeline and the canvas nodes.
IconData pipelineStepStatusIcon(PipelineStepStatus status) {
  return switch (status) {
    PipelineStepStatus.pending => LucideIcons.circle,
    PipelineStepStatus.running => LucideIcons.loader,
    PipelineStepStatus.suspended => LucideIcons.pauseCircle,
    PipelineStepStatus.completed => LucideIcons.checkCircle2,
    PipelineStepStatus.failed => LucideIcons.xCircle,
    PipelineStepStatus.skipped => LucideIcons.minusCircle,
    PipelineStepStatus.cancelled => LucideIcons.ban,
  };
}

/// Status glyph for a whole run. Mirrors [pipelineStepStatusIcon].
IconData pipelineRunStatusIcon(PipelineRunStatus status) {
  return switch (status) {
    PipelineRunStatus.pending => LucideIcons.circle,
    PipelineRunStatus.running => LucideIcons.loader,
    PipelineRunStatus.suspended => LucideIcons.pauseCircle,
    PipelineRunStatus.completed => LucideIcons.checkCircle2,
    PipelineRunStatus.failed => LucideIcons.xCircle,
    PipelineRunStatus.cancelled => LucideIcons.ban,
  };
}
