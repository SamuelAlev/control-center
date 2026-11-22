import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The "still in flight" block the server writes when a conversation is
/// compacted (what was running, waiting and asked), handed to the agent that
/// continues. Collapsed to one line; expanded, its text shows as written
/// (plain, left to right), never rendered as markdown.
class StillInFlightRow extends StatefulWidget {
  /// Creates the row.
  const StillInFlightRow({
    super.key,
    required this.message,
    required this.agentName,
  });

  /// The system row (`metadata.stillInFlightFor`).
  final Message message;

  /// The agent it was handed to.
  final String agentName;

  @override
  State<StillInFlightRow> createState() => _StillInFlightRowState();
}

class _StillInFlightRowState extends State<StillInFlightRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final toggle = _open ? l10n.workFeedHideDetails : l10n.workFeedShowDetails;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTappable(
            onPressed: () => setState(() => _open = !_open),
            semanticLabel: toggle,
            builder: (context, states) => Row(
              children: [
                Icon(AppIcons.scrollText, size: 14, color: ds.textTertiary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.workFeedStillInFlight(widget.agentName),
                    style: CcTypography.caption.copyWith(
                      color: ds.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _open ? AppIcons.chevronUp : AppIcons.chevronDown,
                  size: 12,
                  color: ds.textTertiary,
                ),
              ],
            ),
          ),
          CcCollapsible(
            expanded: _open,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                top: AppSpacing.xs,
              ),
              // RTL carve-out: the handed-on state lists tool calls, paths and
              // commands as the server wrote them.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  inertText(widget.message.content),
                  style: CcFonts.code(
                    textStyle: CcTypography.caption.copyWith(
                      color: ds.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
