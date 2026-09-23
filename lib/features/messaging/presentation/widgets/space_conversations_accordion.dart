import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_height_reveal.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Where a nested conversation's title lines up with the space title.
const double _kTextStart =
    kSpaceSidebarPad + kSpaceSidebarMarkSlot + kSpaceSidebarMarkGap;

/// "N conversations" discloses the space's conversations.
///
/// A space with one conversation has no label. Selecting it must not insert
/// a row under the title.
class SpaceConversationsAccordion extends StatefulWidget {
  /// Creates a [SpaceConversationsAccordion].
  const SpaceConversationsAccordion({
    super.key,
    required this.label,
    required this.children,
  });

  /// The count line, already translated.
  final String label;

  /// Conversation rows. Empty renders the label with no disclosure.
  final List<Widget> children;

  @override
  State<SpaceConversationsAccordion> createState() =>
      _SpaceConversationsAccordionState();
}

class _SpaceConversationsAccordionState
    extends State<SpaceConversationsAccordion> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final expandable = widget.children.isNotEmpty;
    final header = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _kTextStart,
        end: kSpaceSidebarPad,
        // The gap above the count is the space row's bottom inset, so this
        // header does not add a second one. The gap below the count, before
        // the first conversation, stays here.
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
          if (expandable)
            AnimatedRotation(
              duration: CcMotion.resolve(context, CcMotion.moderate),
              curve: CcMotion.standard,
              // Collapsed points toward the end of the line: right in LTR,
              // left in RTL.
              turns: _expanded
                  ? 0
                  : Directionality.of(context) == TextDirection.rtl
                  ? 0.25
                  : -0.25,
              child: Icon(
                AppIcons.chevronDown,
                size: 14,
                color: t.textTertiary,
              ),
            ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expandable)
          Semantics(
            expanded: _expanded,
            child: CcTappable(
              onPressed: () => setState(() => _expanded = !_expanded),
              semanticLabel: widget.label,
              builder: (context, _) => header,
            ),
          )
        else
          header,
        if (expandable)
          SpaceHeightReveal(
            open: _expanded,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
