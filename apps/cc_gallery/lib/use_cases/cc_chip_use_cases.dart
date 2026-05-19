import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcChip] — the design system's compact bordered tag.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Containers → CcChip` (from [CcChip] as the
/// `type` and the bracketed `path` segments). The builders return the component
/// directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Containers';

void _noop() {}

/// Resting, selected and disabled-looking chips side by side. A chip with no
/// [CcChip.onTap] is non-interactive — that's the right-most "read only" tag.
@widgetbook.UseCase(name: 'States', type: CcChip, path: _path)
Widget ccChipStatesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcChip(label: 'opus-4', onTap: _noop),
        CcChip(label: 'sonnet-4', selected: true, onTap: _noop),
        CcChip(label: 'haiku-4'),
      ],
    ),
  );
}

/// Chips with a leading icon — handy for typed filters like repos, agents and
/// pull-request labels.
@widgetbook.UseCase(name: 'With icon', type: CcChip, path: _path)
Widget ccChipWithIconUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcChip(label: 'control-center', leadingIcon: LucideIcons.gitBranch, onTap: _noop),
        CcChip(
          label: 'needs review',
          leadingIcon: LucideIcons.gitPullRequest,
          selected: true,
          onTap: _noop,
        ),
        CcChip(label: 'architect', leadingIcon: LucideIcons.bot),
      ],
    ),
  );
}

/// Deletable chips — setting [CcChip.onDeleted] adds a trailing `x`. This demo
/// is stateful so the tags actually leave the row when removed.
@widgetbook.UseCase(name: 'Deletable', type: CcChip, path: _path)
Widget ccChipDeletableUseCase(BuildContext context) {
  return const Center(child: _DeletableChips());
}

class _DeletableChips extends StatefulWidget {
  const _DeletableChips();

  @override
  State<_DeletableChips> createState() => _DeletableChipsState();
}

class _DeletableChipsState extends State<_DeletableChips> {
  final List<String> _labels = <String>['frontend', 'backend', 'flaky-test', 'infra'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    if (_labels.isEmpty) {
      return Text(
        'All filters cleared',
        style: CcTypography.bodySm.copyWith(color: tokens?.textTertiary),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final label in _labels)
          CcChip(
            label: label,
            leadingIcon: LucideIcons.tag,
            onDeleted: () => setState(() => _labels.remove(label)),
          ),
      ],
    );
  }
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcChip, path: _path)
Widget ccChipPlaygroundUseCase(BuildContext context) {
  final label = context.knobs.string(label: 'Label', initialValue: 'workspace');
  final selected = context.knobs.boolean(label: 'Selected');
  final withIcon = context.knobs.boolean(label: 'Leading icon', initialValue: true);
  final tappable = context.knobs.boolean(label: 'Tappable', initialValue: true);
  final deletable = context.knobs.boolean(label: 'Deletable');
  return Center(
    child: CcChip(
      label: label,
      selected: selected,
      leadingIcon: withIcon ? LucideIcons.tag : null,
      onTap: tappable ? _noop : null,
      onDeleted: deletable ? _noop : null,
    ),
  );
}
