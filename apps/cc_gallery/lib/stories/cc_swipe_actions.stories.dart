import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_swipe_actions.stories.g.dart';

/// Stories for [CcSwipeActions] — the row wrapper that uncovers an action panel
/// behind a horizontal drag, in the idiom of a phone mail list.
///
/// The gesture is invisible at rest, so these entries exist mostly to say it is
/// there at all: hold a row (or drag it straight away, with the gate arg off),
/// pull left to acknowledge, right to delete.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcSwipeActions', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSwipeActionsPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    // On: hold the row before dragging. Off: a bare horizontal drag, which is
    // the phone-mail idiom but easier to fire by accident.
    gate: BoolArg(true, name: 'Require long press'),
    // Below ~150ms a deliberate click starts firing it; 500ms is the platform
    // long press, which reads as unresponsive here.
    holdMs: IntArg(
      CcSwipeActions.defaultHoldDuration.inMilliseconds,
      name: 'Hold (ms)',
      style: const SliderIntArgStyle(min: 80, max: 500, divisions: 21),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccSwipeActionsPlaygroundStory(context, args),
  ),
);

final $NotificationRows = _Story(
  name: 'Notification rows',
  args: _Args.fixed(preview: ccSwipeActionsRowsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSwipeActionsPlayground {
  CcSwipeActionsPlayground({required this.gate, required this.holdMs});

  final bool gate;
  final int holdMs;
}

/// The notification-center wiring: drag left to acknowledge, right to delete,
/// with a live list underneath so both verbs have a visible consequence.
Widget ccSwipeActionsRowsStory(BuildContext context) {
  return const Center(
    child: _InboxDemo(
      requireLongPress: true,
      holdDuration: CcSwipeActions.defaultHoldDuration,
    ),
  );
}

/// Interactive playground — the gate and how long it takes to pass are the two
/// decisions a caller actually makes, so they are the args.
Widget ccSwipeActionsPlaygroundStory(
  BuildContext context,
  CcSwipeActionsPlaygroundArgs args,
) {
  final gate = args.gate;
  final holdMs = args.holdMs;
  return Center(
    child: _InboxDemo(
      requireLongPress: gate,
      holdDuration: Duration(milliseconds: holdMs),
    ),
  );
}

class _DemoRow {
  _DemoRow(this.title, this.body, {this.read = false});

  final String title;
  final String body;
  bool read;
}

class _InboxDemo extends StatefulWidget {
  const _InboxDemo({
    required this.requireLongPress,
    required this.holdDuration,
  });

  final bool requireLongPress;
  final Duration holdDuration;

  @override
  State<_InboxDemo> createState() => _InboxDemoState();
}

class _InboxDemoState extends State<_InboxDemo> {
  late final List<_DemoRow> _rows = [
    _DemoRow('Review requested', 'chore: release packages (acme/cli#409)'),
    _DemoRow('Agent run finished', 'architect · 4m 12s · 18 files touched'),
    _DemoRow(
      'Pull request merged',
      'feat: split persistence by workspace (#2170)',
      read: true,
    ),
  ];

  String? _last;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CcEmptyState(
                icon: CcIcons.bell,
                message: 'Nothing left to swipe',
                iconSize: 28,
              ),
            )
          else
            for (final row in _rows)
              CcSwipeActions(
                key: ValueKey(row.title),
                requireLongPress: widget.requireLongPress,
                holdDuration: widget.holdDuration,
                startAction: CcSwipeAction(
                  icon: CcIcons.trash2,
                  label: 'Delete',
                  background: t.bgErrorSolid,
                  foreground: t.textWhite,
                  onTriggered: () => setState(() {
                    _rows.remove(row);
                    _last = 'Deleted "${row.title}"';
                  }),
                ),
                endAction: CcSwipeAction(
                  icon: row.read ? CcIcons.circleDashed : CcIcons.check,
                  label: row.read ? 'Mark as unread' : 'Mark as read',
                  background: t.bgSuccessSolid,
                  foreground: t.textWhite,
                  onTriggered: () => setState(() {
                    row.read = !row.read;
                    _last = '${row.read ? "Read" : "Unread"} — "${row.title}"';
                  }),
                ),
                child: _Row(row: row),
              ),
          const SizedBox(height: 12),
          Text(
            _last ?? 'Hold a row, then drag: left acknowledges, right deletes.',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// A stand-in for a notification row: enough of the real one (unread spine,
/// weight change, transparent background when read) to show that the panel
/// stays clipped to what the drag uncovered.
class _Row extends StatelessWidget {
  const _Row({required this.row});

  final _DemoRow row;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final unread = !row.read;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unread ? t.fgBrandPrimary.withValues(alpha: 0.05) : null,
        border: Border(
          left: BorderSide(
            color: unread ? t.fgBrandPrimary : const Color(0x00000000),
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(
                fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                color: unread ? t.textPrimary : t.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              row.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: unread ? t.textSecondary : t.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
