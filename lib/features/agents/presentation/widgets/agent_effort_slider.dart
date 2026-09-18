import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Stepped effort control: one stop per level the selected model accepts,
/// named with that level's label (Low, Medium, High, …).
///
/// A dropdown hid the ordered scale (least → most intensive) behind a click.
/// The slider is that scale: the thumb is the current effort, the names are
/// the stops, and aiming a neighbour previews it without committing.
class AgentEffortSlider extends StatelessWidget {
  /// Creates an [AgentEffortSlider].
  const AgentEffortSlider({
    super.key,
    required this.levels,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.defaultValue,
  });

  /// Ordered levels the model accepts, least → most intensive.
  final List<ThinkingLevel> levels;

  /// Currently staged level id, or null when unset.
  final String? value;

  /// Level id the model would run at if [value] is unset.
  final String? defaultValue;

  /// Commits a level id.
  final ValueChanged<String> onChanged;

  /// Accessibility name for the slider.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return const SizedBox.shrink();
    }
    if (levels.length == 1) {
      return Text(
        levels.first.label,
        style: CcTypography.bodySm.copyWith(color: context.ds.textPrimary),
      );
    }
    final index = _indexFor(levels, value, defaultValue);
    final last = levels.length - 1;
    return CcSlider(
      value: index.toDouble(),
      min: 0,
      max: last.toDouble(),
      divisions: last,
      stepLabels: [for (final level in levels) level.label],
      showValue: false,
      semanticLabel: semanticLabel,
      onChanged: (raw) {
        final next = raw.round().clamp(0, last);
        onChanged(levels[next].id);
      },
    );
  }
}

int _indexFor(List<ThinkingLevel> levels, String? value, String? defaultValue) {
  final ids = [for (final level in levels) level.id];
  final fromValue = value == null ? -1 : ids.indexOf(value);
  if (fromValue >= 0) {
    return fromValue;
  }
  final fromDefault = defaultValue == null ? -1 : ids.indexOf(defaultValue);
  if (fromDefault >= 0) {
    return fromDefault;
  }
  return 0;
}
