import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';

/// The label style of a small heading inside a section.
TextStyle workSectionLabelStyle(DesignSystemTokens ds) =>
    CcTypography.caption.copyWith(color: ds.textTertiary);

/// One section of a Goals, Schedules or Improvements page: a hairline above,
/// a heading with optional [actions] at its end, and the [child].
class WorkSection extends StatelessWidget {
  /// Creates the section.
  const WorkSection({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  /// The heading.
  final String title;

  /// The body.
  final Widget child;

  /// Square controls at the heading's end.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ds.borderSecondary)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: CcTypography.bodySm.copyWith(
                      color: ds.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final a in actions) ...[
                  const SizedBox(width: AppSpacing.xs),
                  a,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// A two-column list of label and value, with an optional hover card for a
/// value that is a time ([timestamps], keyed by label).
class WorkFactGrid extends StatelessWidget {
  /// Creates the grid.
  const WorkFactGrid({
    super.key,
    required this.facts,
    this.timestamps = const {},
  });

  /// Label and value, in order.
  final List<(String, String)> facts;

  /// The instant behind a value, by its label.
  final Map<String, DateTime> timestamps;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final label = CcTypography.caption.copyWith(color: ds.textTertiary);
    final value = CcTypography.bodySm.copyWith(color: ds.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, text) in facts)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 160, child: Text(name, style: label)),
                Expanded(
                  child: switch (timestamps[name]) {
                    final at? => AppTimestamp(
                      dateTime: at,
                      child: Text(text, style: value),
                    ),
                    null => Text(text, style: value),
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// [child] with a tooltip saying [message], or bare when there is nothing to
/// say (a disabled control's reason, absent while it is enabled).
class WorkTip extends StatelessWidget {
  /// Creates the tip.
  const WorkTip({super.key, required this.message, required this.child});

  /// What the tooltip says, or null for none.
  final String? message;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (message) {
    final m? => CcTooltip(message: m, child: child),
    null => child,
  };
}
