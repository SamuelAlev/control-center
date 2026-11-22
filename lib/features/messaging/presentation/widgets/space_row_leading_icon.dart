part of 'space_row_adornments.dart';

/// The mark in front of a space's title: a spinner while an agent is
/// running, otherwise the [AttentionDot] (unseen agent messages or a question
/// waiting on the user). Build it through [spaceRowSignal], which leaves a
/// quiet space without one.
class SpaceLeadingIcon extends StatelessWidget {
  /// Creates the leading icon.
  const SpaceLeadingIcon({
    super.key,
    required this.running,
    required this.selected,
  });

  /// Whether an agent is currently running in the space.
  final bool running;

  /// The spinner and the dot invert on the selected row.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (running) {
      return CcSpinner(
        size: kSpaceRowSignalSize,
        strokeWidth: 1.5,
        color: selected ? t.accentOn : null,
      );
    }
    return AttentionDot(selected: selected);
  }
}

/// The signal a space row puts in front of its title, or null when it is
/// neither running nor asking for attention, so a quiet title keeps the inset.
Widget? spaceRowSignal({
  required bool running,
  required bool attention,
  required bool selected,
}) => running || attention
    ? SpaceLeadingIcon(running: running, selected: selected)
    : null;
