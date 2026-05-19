import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Shared primitives for the per-tool renderer cards: ANSI stripping, tail
/// capping, status icons, output/code blocks and key/value grids. Built on the
/// `cc_ui` design tokens so every tool card shares one look.

final _ansiPattern = RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]');

/// Strips ANSI CSI escape sequences (colors, cursor moves) from [text].
String ansiStrip(String text) => text.replaceAll(_ansiPattern, '');

/// ANSI-strips [text] and keeps only its last [maxLines] lines, prefixing an
/// `… (N earlier lines)` marker when content was dropped.
String tailLines(String text, {int maxLines = 12}) {
  final clean = ansiStrip(text).trimRight();
  if (clean.isEmpty) {
    return '';
  }
  final lines = clean.split('\n');
  if (lines.length <= maxLines) {
    return clean;
  }
  final dropped = lines.length - maxLines;
  final tail = lines.sublist(lines.length - maxLines);
  return '… ($dropped earlier ${dropped == 1 ? 'line' : 'lines'})\n${tail.join('\n')}';
}

/// A status glyph for a tool call: spinner while running, check / cross / alert
/// for ok / error / interrupted. Paired with text elsewhere, never color-alone.
Widget toolStatusIcon(BuildContext context, ToolSegmentStatus status) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  switch (status) {
    case ToolSegmentStatus.running:
      return const SizedBox(width: 14, height: 14, child: CcSpinner(size: 12));
    case ToolSegmentStatus.ok:
      return Icon(AppIcons.circleCheck, size: 14, color: t.textSuccessPrimary);
    case ToolSegmentStatus.error:
      return Icon(AppIcons.circleX, size: 14, color: t.textErrorPrimary);
    case ToolSegmentStatus.interrupted:
      return Icon(AppIcons.circleAlert, size: 14, color: t.textWarningPrimary);
  }
}

/// A monospace, tail-capped output block. Renders nothing for empty text.
class OutputBlock extends StatelessWidget {
  /// Creates an [OutputBlock].
  const OutputBlock({
    super.key,
    required this.text,
    this.maxLines = 12,
    this.error = false,
    this.title,
  });

  /// Raw (possibly ANSI-laden) output text.
  final String text;

  /// Maximum trailing lines shown.
  final int maxLines;

  /// Whether to tint the text as an error.
  final bool error;

  /// Optional small caption above the block.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final shown = tailLines(text, maxLines: maxLines);
    if (shown.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Text(
              title!,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: t.bgTertiary,
            borderRadius: AppRadii.brLg,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              shown,
              style: CcTypography.monoNum.copyWith(
                fontSize: 12,
                height: 1.4,
                color: error ? t.textErrorPrimary : t.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact two-column key/value grid for tool arguments.
class ToolKvGrid extends StatelessWidget {
  /// Creates a [ToolKvGrid].
  const ToolKvGrid({super.key, required this.entries});

  /// The rows, in order.
  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    entry.key,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.value,
                    style: CcTypography.monoNum.copyWith(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A tiny inline chip for tool metadata (op names, flags, exit codes).
class ToolChip extends StatelessWidget {
  /// Creates a [ToolChip].
  const ToolChip({super.key, required this.label, this.tone = ObsTone.neutral});

  /// The chip text.
  final String label;

  /// Accent tone.
  final ObsTone tone;

  @override
  Widget build(BuildContext context) {
    final variant = switch (tone) {
      ObsTone.neutral => CcBadgeVariant.neutral,
      ObsTone.brand => CcBadgeVariant.brand,
      ObsTone.success => CcBadgeVariant.success,
      ObsTone.warning => CcBadgeVariant.warning,
      ObsTone.danger => CcBadgeVariant.danger,
    };
    return CcBadge(label: label, variant: variant);
  }
}

/// Formats a single tool-argument value compactly for a summary line: strings
/// pass through (collapsed whitespace), everything else is JSON-ish.
String compactArg(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return value.toString();
}

/// Truncates [text] to [max] characters with an ellipsis.
String ellipsize(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}…';

/// Formats a tool's duration for the card header (empty when unknown).
String toolDurationLabel(int? durationMs) =>
    durationMs == null ? '' : fmtDuration(durationMs);
