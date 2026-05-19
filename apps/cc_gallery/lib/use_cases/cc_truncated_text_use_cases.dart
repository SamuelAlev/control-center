import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTruncatedText] — single-line text that truncates with an
/// ellipsis and discloses its full content in a tooltip only when actually
/// truncated.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Content → CcTruncatedText`. Hover the
/// truncated sample to see the disclosure tooltip.

const _path = '[Components]/Content';

/// Fitting text renders as a plain label; the constrained copy truncates and
/// discloses its full text on hover.
@widgetbook.UseCase(
  name: 'Fits vs truncated',
  type: CcTruncatedText,
  path: _path,
)
Widget ccTruncatedTextUseCase(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 240, child: CcTruncatedText('Fits without truncation')),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 240,
          child: CcTruncatedText(
            'feature/orchestration-guardrails-rollout-plan-v2-final-really',
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — shrink the width until the label truncates and the
/// hover tooltip appears.
@widgetbook.UseCase(name: 'Playground', type: CcTruncatedText, path: _path)
Widget ccTruncatedTextPlaygroundUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: 'Text',
    initialValue: 'workspaces/acme-prod/agents/reviewer-01',
  );
  final width = context.knobs.double.slider(
    label: 'Width',
    initialValue: 160,
    min: 40,
    max: 400,
  );
  return Center(
    child: SizedBox(width: width, child: CcTruncatedText(text)),
  );
}
