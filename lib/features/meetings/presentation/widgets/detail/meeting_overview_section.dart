import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:flutter/widgets.dart';

/// A rail section: a mono heading with an optional count, its body, and an
/// optional footer of links.
class MeetingOverviewSection extends StatelessWidget {
  /// Creates a [MeetingOverviewSection].
  const MeetingOverviewSection({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.footer = const [],
  });

  /// The section heading, rendered as a mono label.
  final String title;

  /// How many things the section covers, shown beside [title].
  final int? count;

  /// The section body.
  final Widget child;

  /// Links under the body (view all, add).
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MeetingEyebrow(title),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  color: ds.hoverStrong,
                  child: Text(
                    '$count',
                    style: meetingMono(context, fontSize: 11, color: ds.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          if (footer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.lg, children: footer),
          ],
        ],
      ),
    );
  }
}

/// A muted line for an empty or settled overview section.
class MeetingOverviewNote extends StatelessWidget {
  /// Creates a [MeetingOverviewNote].
  const MeetingOverviewNote(this.text, {super.key});

  /// The note.
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 13, height: 1.4, color: context.ds.muted),
  );
}

/// A text link at the foot of a section, flush with the section's content
/// rather than inset by a button's padding. Ink, underlined on hover; the row
/// keeps a 32px target.
class MeetingOverviewLink extends StatelessWidget {
  /// Creates a [MeetingOverviewLink].
  const MeetingOverviewLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// The link label.
  final String label;

  /// Called when pressed.
  final VoidCallback onPressed;

  /// Optional leading glyph.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states) {
        final hot =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        return SizedBox(
          height: 32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: hot ? ds.fg : ds.muted),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ds.fg,
                  decoration: hot
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: ds.fg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
