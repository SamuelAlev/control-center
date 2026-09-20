// Operator-facing boot failure: a one-line reason, with the dump behind a
// disclosure so a WDA/QEMU log cannot take over the start screen.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The first line a person can act on, plus the rest of the dump if any.
class RigFailureParts {
  /// Creates [RigFailureParts].
  const RigFailureParts({required this.summary, this.details});

  /// One-line reason, exception class names stripped.
  final String summary;

  /// stdout/stderr (or anything after the first newline). Null when there
  /// is nothing to hide.
  final String? details;
}

final _exceptionPrefix = RegExp(r'^[A-Za-z][A-Za-z0-9_.]*Exception:\s*');

/// Splits a boot-failure dump into a short summary and optional details.
RigFailureParts splitRigFailure(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const RigFailureParts(summary: '');
  }
  final newline = trimmed.indexOf('\n');
  final firstLine = newline == -1
      ? trimmed
      : trimmed.substring(0, newline).trimRight();
  final rest = newline == -1 ? '' : trimmed.substring(newline + 1).trim();
  var summary = firstLine;
  for (var i = 0; i < 4; i++) {
    final next = summary.replaceFirst(_exceptionPrefix, '').trimLeft();
    if (next == summary) {
      break;
    }
    summary = next;
  }
  if (summary.isEmpty) {
    summary = firstLine;
  }
  if (rest.isEmpty) {
    return RigFailureParts(summary: summary);
  }
  return RigFailureParts(summary: summary, details: rest);
}

/// The start-screen treatment of a failed boot: short reason, dump collapsed.
class RigBootFailure extends StatefulWidget {
  /// Creates a [RigBootFailure].
  const RigBootFailure({super.key, required this.error});

  /// The raw failure, including any stdout/stderr the backend attached.
  final String error;

  @override
  State<RigBootFailure> createState() => _RigBootFailureState();
}

class _RigBootFailureState extends State<RigBootFailure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final parts = splitRigFailure(widget.error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          parts.summary,
          textAlign: TextAlign.center,
          style: CcTypography.caption.copyWith(color: t.danger),
        ),
        if (parts.details != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: CcTappable(
                  semanticLabel: l10n.rigTechnicalDetails,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  builder: (context, states) {
                    final color = states.contains(WidgetState.hovered)
                        ? t.textSecondary
                        : t.textTertiary;
                    return Row(
                      children: [
                        AnimatedRotation(
                          turns: _expanded ? 0.25 : 0,
                          duration: CcMotion.resolve(context, CcMotion.fast),
                          child: Icon(
                            AppIcons.chevronRight,
                            size: 12,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.rigTechnicalDetails,
                            style: CcTypography.caption.copyWith(color: color),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_expanded)
                CcIconButton(
                  icon: AppIcons.copy,
                  size: CcButtonSize.sm,
                  tooltip: l10n.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.error));
                  },
                ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: ConstrainedBox(
                key: const Key('rigBootFailureDetails'),
                constraints: const BoxConstraints(maxHeight: 180),
                child: ColoredBox(
                  color: t.bgTertiary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    // RTL carve-out: log output
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        parts.details!,
                        textAlign: TextAlign.start,
                        style: CcFonts.code(
                          textStyle: CcTypography.caption.copyWith(
                            color: t.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
