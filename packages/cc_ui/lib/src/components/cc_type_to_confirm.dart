import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The labels a [CcTypeToConfirmPrompt] renders.
///
/// English by default, like the rest of cc_ui's built-in copy; the app hands
/// in its localized set.
@immutable
class CcTypeToConfirmLabels {
  /// Creates a [CcTypeToConfirmLabels].
  const CcTypeToConfirmLabels({
    this.prompt = _englishPrompt,
    this.copy = 'Copy',
    this.copied = 'Copied',
  });

  /// The instruction sentence around the value, e.g. `Type {value} to
  /// confirm.`
  ///
  /// Called with a stand-in rather than the value: where the stand-in lands is
  /// where the copyable chip goes, so a translation can put the value anywhere
  /// in its sentence. One that drops the placeholder gets the chip after it.
  final String Function(String value) prompt;

  /// Tooltip and accessible name of the chip before it is used.
  final String copy;

  /// Tooltip and accessible name right after the value was copied.
  final String copied;
}

String _englishPrompt(String value) => 'Type $value to confirm.';

/// The instruction line of a type-to-confirm dialog: the sentence with [value]
/// set inside it as a chip that copies it.
///
/// Pair with a field whose placeholder is [value] too, so the operator reads
/// the exact string in both places they look.
class CcTypeToConfirmPrompt extends StatelessWidget {
  /// Creates a [CcTypeToConfirmPrompt].
  const CcTypeToConfirmPrompt({
    super.key,
    required this.value,
    this.labels = const CcTypeToConfirmLabels(),
  });

  /// The exact string the operator has to type.
  final String value;

  /// The localized sentence and copy-state labels.
  final CcTypeToConfirmLabels labels;

  /// U+FFFC OBJECT REPLACEMENT CHARACTER: Unicode's own stand-in for an
  /// inline object, and never part of a translated sentence.
  static const _slot = '\uFFFC';

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final sentence = labels.prompt(_slot);
    final at = sentence.indexOf(_slot);
    final chip = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _CopyValueChip(value: value, labels: labels),
    );
    return Text.rich(
      TextSpan(
        children: at < 0
            ? [TextSpan(text: '$sentence '), chip]
            : [
                TextSpan(text: sentence.substring(0, at)),
                chip,
                TextSpan(text: sentence.substring(at + _slot.length)),
              ],
      ),
      style: CcTypography.body.copyWith(color: t.textPrimary),
    );
  }
}

/// The value as a dashed, square chip; activating it copies the value and
/// swaps the copy glyph for a check until [_resetAfter] passes.
class _CopyValueChip extends StatefulWidget {
  const _CopyValueChip({required this.value, required this.labels});

  final String value;
  final CcTypeToConfirmLabels labels;

  @override
  State<_CopyValueChip> createState() => _CopyValueChipState();
}

class _CopyValueChipState extends State<_CopyValueChip> {
  static const _resetAfter = Duration(seconds: 2);

  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_resetAfter, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final label = _copied ? widget.labels.copied : widget.labels.copy;
    final fade = CcMotion.resolveFade(context, CcMotion.fast);

    return CcTooltip(
      message: label,
      placement: CcTooltipPlacement.top,
      child: CcTappable(
        onPressed: _copy,
        semanticLabel: label,
        focusRingOffset: 2,
        builder: (context, states) {
          final pressed = states.contains(WidgetState.pressed);
          final active = pressed || states.contains(WidgetState.hovered);
          return CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color: active ? t.textTertiary : t.lineStrong,
            ),
            child: AnimatedContainer(
              duration: fade,
              curve: CcMotion.standard,
              color: pressed
                  ? Color.alphaBlend(t.hoverStrong, t.surface)
                  : active
                  ? Color.alphaBlend(t.hover, t.surface)
                  : t.surface,
              padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 5, 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.value,
                      style: CcFonts.code(
                        textStyle: CcTypography.monoNum.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: fade,
                    child: Icon(
                      _copied ? CcIcons.check : CcIcons.copy,
                      key: ValueKey(_copied),
                      size: 13,
                      color: _copied
                          ? t.textSuccessPrimary
                          : active
                          ? t.textSecondary
                          : t.textTertiary,
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
}

/// A 1px dashed outline on the box's inner edge. Dashed rather than solid so
/// the chip reads as a value lifted out of the sentence, not another control.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _dash = 3;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()..addRect((Offset.zero & size).deflate(0.5));
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + _dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
