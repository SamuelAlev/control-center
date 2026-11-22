import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One row of the Goals, Schedules or Improvements list: a status tag, a
/// title with a line of facts under it, and something at the end (a time, an
/// amount). The whole row opens the record; its hover wash and cursor are
/// the affordance (no chevron).
class WorkListRow extends StatelessWidget {
  /// Creates the row.
  const WorkListRow({
    super.key,
    required this.tag,
    required this.title,
    required this.onPressed,
    this.meta = const [],
    this.trailing,
    this.first = false,
  });

  /// The status tag.
  final Widget tag;

  /// The title (data: plain text).
  final String title;

  /// Lines of facts under the title.
  final List<String> meta;

  /// What sits at the row's end.
  final Widget? trailing;

  /// Opens the record.
  final VoidCallback onPressed;

  /// Whether this is the first row (no hairline above it).
  final bool first;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: ds.borderSecondary)),
      ),
      child: CcTappable(
        onPressed: onPressed,
        semanticLabel: title,
        builder: (context, states) => ColoredBox(
          color: states.contains(WidgetState.hovered)
              ? ds.bgPrimaryHover
              : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: tag,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.bodySm.copyWith(
                          color: ds.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final line in meta)
                        if (line.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpacing.xxs,
                            ),
                            child: Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CcTypography.caption.copyWith(
                                color: ds.textSecondary,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                if (trailing case final t?) ...[
                  const SizedBox(width: AppSpacing.md),
                  t,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A group heading inside a list ("Waiting for you", "Ended").
class WorkListGroupHeading extends StatelessWidget {
  /// Creates the heading.
  const WorkListGroupHeading({
    super.key,
    required this.label,
    required this.count,
  });

  /// The group's name.
  final String label;

  /// How many rows it has.
  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        AppLocalizations.of(context).workListGroup(label, count),
        style: CcTypography.caption.copyWith(
          color: ds.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
