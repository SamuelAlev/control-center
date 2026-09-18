import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcColorTag] — a read-only forge-colored label chip.
const _path = '[Components]/Containers';

/// GitHub-style labels across light, mid and dark fills so ink contrast is
/// visible (yellow/cyan get dark type; red/blue get white).
@widgetbook.UseCase(name: 'GitHub colors', type: CcColorTag, path: _path)
Widget ccColorTagGitHubColorsUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcColorTag(label: 'bug', color: 'd73a4a'),
        CcColorTag(label: 'enhancement', color: 'a2eeef'),
        CcColorTag(
          label: 'dependencies',
          color: '0366d6',
          tooltip: 'Pull requests that update a dependency file',
        ),
        CcColorTag(label: 'documentation', color: '0075ca'),
        CcColorTag(label: 'good first issue', color: '7057ff'),
        CcColorTag(label: 'performance', color: '0e8a16'),
      ],
    ),
  );
}

/// Dense chips for inbox rows and activity-feed sentences.
@widgetbook.UseCase(name: 'Compact', type: CcColorTag, path: _path)
Widget ccColorTagCompactUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        CcColorTag(label: 'bug', color: 'd73a4a', compact: true),
        CcColorTag(label: 'dependencies', color: '0366d6', compact: true),
        CcColorTag(label: 'wip', compact: true),
      ],
    ),
  );
}

/// An empty or unparseable color still renders a named chip on the muted
/// secondary fill — GitLab's names-only list payload has no hex.
@widgetbook.UseCase(name: 'Fallback', type: CcColorTag, path: _path)
Widget ccColorTagFallbackUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcColorTag(label: 'needs-review'),
        CcColorTag(label: 'not-a-color', color: 'zzzzzz'),
      ],
    ),
  );
}
