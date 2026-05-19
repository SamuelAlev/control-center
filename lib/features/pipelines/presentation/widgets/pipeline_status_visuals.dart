import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Resolved colors for rendering a pipeline run / step status, sourced from the
/// design system semantic tokens.
///
/// One source of truth shared by the status badge, the run cards and the
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
    PipelineRunStatus.queued => _Tone.neutral,
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
    PipelineStepStatus.pending => AppIcons.circle,
    PipelineStepStatus.running => AppIcons.loader,
    PipelineStepStatus.suspended => AppIcons.pauseCircle,
    PipelineStepStatus.completed => AppIcons.checkCircle2,
    PipelineStepStatus.failed => AppIcons.xCircle,
    PipelineStepStatus.skipped => AppIcons.minusCircle,
    PipelineStepStatus.cancelled => AppIcons.ban,
  };
}

/// Localized label for a run status — the badge's wording, shared so the run
/// history menu names a run the same way the badge on it does.
String pipelineRunStatusLabel(PipelineRunStatus s, AppLocalizations l10n) {
  return switch (s) {
    PipelineRunStatus.pending => l10n.pipelineStatusPending,
    PipelineRunStatus.queued => l10n.pipelineStatusQueued,
    PipelineRunStatus.running => l10n.pipelineStatusRunning,
    PipelineRunStatus.suspended => l10n.pipelineStatusSuspended,
    PipelineRunStatus.completed => l10n.pipelineStatusCompleted,
    PipelineRunStatus.failed => l10n.pipelineStatusFailed,
    PipelineRunStatus.cancelled => l10n.pipelineStatusCancelled,
  };
}

/// Localized label for a step status — the badge's wording, shared so the
/// attempt history names an interrupted or failed try the same way the badge
/// on the live row does.
String pipelineStepStatusLabel(PipelineStepStatus s, AppLocalizations l10n) {
  return switch (s) {
    PipelineStepStatus.pending => l10n.pipelineStatusPending,
    PipelineStepStatus.running => l10n.pipelineStatusRunning,
    PipelineStepStatus.suspended => l10n.pipelineStatusSuspended,
    PipelineStepStatus.completed => l10n.pipelineStatusCompleted,
    PipelineStepStatus.failed => l10n.pipelineStatusFailed,
    PipelineStepStatus.skipped => l10n.pipelineStatusSkipped,
    PipelineStepStatus.cancelled => l10n.pipelineStatusCancelled,
  };
}

/// Status glyph for a whole run. Mirrors [pipelineStepStatusIcon].
IconData pipelineRunStatusIcon(PipelineRunStatus status) {
  return switch (status) {
    PipelineRunStatus.pending => AppIcons.circle,
    // Distinct from pending's empty circle: queued and pending share a neutral
    // tone, so the glyph is the only thing telling "about to start" from
    // "waiting behind the template's concurrency cap".
    PipelineRunStatus.queued => AppIcons.clock,
    PipelineRunStatus.running => AppIcons.loader,
    PipelineRunStatus.suspended => AppIcons.pauseCircle,
    PipelineRunStatus.completed => AppIcons.checkCircle2,
    PipelineRunStatus.failed => AppIcons.xCircle,
    PipelineRunStatus.cancelled => AppIcons.ban,
  };
}
