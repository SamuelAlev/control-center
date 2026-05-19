import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/gestures.dart'
    show
        HorizontalDragGestureRecognizer,
        LongPressGestureRecognizer,
        kLongPressTimeout;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One of the two actions a [CcSwipeActions] row can reveal.
///
/// Colors are passed in rather than read from tokens here so the component
/// stays semantic-free: only the caller knows whether its trailing action is a
/// success (acknowledge) or a destructive one (delete).
@immutable
class CcSwipeAction {
  /// Creates a [CcSwipeAction].
  const CcSwipeAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTriggered,
  });

  /// Glyph shown in the revealed panel.
  final IconData icon;

  /// Text beside the glyph. Also what the row announces as its semantic action,
  /// so it must be a real, localized verb phrase ("Mark as read", "Delete").
  final String label;

  /// Panel fill.
  final Color background;

  /// Glyph and label color. Must clear the contrast floor against
  /// [background] — the component does no correction.
  final Color foreground;

  /// Fired once, on release, when the drag passed the commit threshold.
  final VoidCallback onTriggered;
}

/// Wraps a row so a horizontal drag uncovers an action panel behind it, in the
/// idiom of a mobile mail list: drag one way to acknowledge, the other to
/// delete, release past the threshold to commit.
///
/// Two properties are deliberate:
///
/// * **The row always settles back to rest**, including after it fires. A
///   consuming action (delete) is expected to remove the row from the list by
///   the normal state path; the panel does not hold it off-screen waiting for
///   that. Holding it would mean inventing a stuck state to recover from when
///   the write fails, and there is no honest recovery from "the row is gone but
///   the server still has it".
/// * **The gesture is never the only way to reach the action.** It is
///   discoverable only by trying it, so a caller must keep a pointer- and
///   keyboard-reachable path (an overflow menu, a toolbar) to the same verbs.
///   The panel contributes [CustomSemanticsAction]s so assistive technology
///   gets them too, but those are additive, not the affordance.
class CcSwipeActions extends StatefulWidget {
  /// Creates a [CcSwipeActions].
  const CcSwipeActions({
    super.key,
    required this.child,
    this.startAction,
    this.endAction,
    this.requireLongPress = true,
    this.holdDuration = defaultHoldDuration,
    this.threshold = 0.26,
    this.maxTravel = 0.55,
    this.enabled = true,
  });

  /// How long the press must be held before a gated drag arms.
  ///
  /// Deliberately shorter than Flutter's own [kLongPressTimeout] (500ms), which
  /// is calibrated for "open a context menu" — a gesture you commit to. This
  /// one only picks a row up, and at half a second the row reads as
  /// unresponsive to someone who is already trying to drag it.
  static const Duration defaultHoldDuration = Duration(milliseconds: 180);

  /// The row itself.
  final Widget child;

  /// Action uncovered at the row's leading edge — dragging *right* in LTR.
  final CcSwipeAction? startAction;

  /// Action uncovered at the row's trailing edge — dragging *left* in LTR.
  final CcSwipeAction? endAction;

  /// Whether the drag must be armed by a long press first.
  ///
  /// A bare horizontal drag is the phone-mail idiom and costs nothing to start;
  /// the long press makes the gesture deliberate, which is what you want when
  /// one side of it deletes. It changes nothing else: the same drag, thresholds
  /// and panels follow either way.
  final bool requireLongPress;

  /// The hold that arms the drag. Ignored when [requireLongPress] is false.
  ///
  /// It has a floor in practice: the press must outlast a tap (a deliberate one
  /// runs to roughly 120ms) or the row would fire on a click, and it must stay
  /// still inside `kTouchSlop` for the whole of it. Below about 150ms those two
  /// meet and the gate stops being one.
  final Duration holdDuration;

  /// Fraction of the row's width the drag must pass to commit on release.
  final double threshold;

  /// Fraction of the row's width the content may travel.
  final double maxTravel;

  /// Whether the gesture is live. When false the row renders untouched.
  final bool enabled;

  @override
  State<CcSwipeActions> createState() => _CcSwipeActionsState();
}

class _CcSwipeActionsState extends State<CcSwipeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(vsync: this)
    ..addListener(_onSettle);

  /// Signed pixel offset of the content from rest, positive rightward *on
  /// screen* in both text directions. Which panel that uncovers is resolved
  /// through [Directionality] rather than baked into the sign.
  double _offset = 0;

  /// Offset the current settle animation is unwinding from.
  double _settleFrom = 0;

  /// Row width, sampled when a drag starts. Read from the render object rather
  /// than a [LayoutBuilder] so build stays free of layout-phase side effects.
  double _width = 0;

  bool _dragging = false;
  bool _past = false;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettle() {
    final t = CcMotion.standard.transform(_settle.value);
    setState(() => _offset = _settleFrom * (1 - t));
  }

  /// The action a displacement of [dx] uncovers, or null if that side has none.
  ///
  /// Moving the content right uncovers the row's LEFT edge, which is the
  /// leading edge in LTR and the trailing edge in RTL.
  CcSwipeAction? _actionFor(double dx) {
    if (dx == 0) {
      return null;
    }
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final leading = ltr == (dx > 0);
    return leading ? widget.startAction : widget.endAction;
  }

  void _onStart() {
    _settle.stop();
    final box = context.findRenderObject() as RenderBox?;
    _width = box?.size.width ?? 0;
    _dragging = true;
    _past = false;
    if (widget.requireLongPress) {
      // The arm cue. On a phone this is the whole signal that the row is now
      // draggable; the scale below covers the pointer case, where there are no
      // haptics to feel.
      HapticFeedback.selectionClick();
    }
  }

  void _apply(double dx) {
    if (_width <= 0) {
      return;
    }
    var next = _actionFor(dx) == null ? 0.0 : dx;
    final maxPx = _width * widget.maxTravel;
    next = next.clamp(-maxPx, maxPx);

    final past = next.abs() >= _width * widget.threshold;
    if (past != _past) {
      _past = past;
      if (past) {
        HapticFeedback.selectionClick();
      }
    }
    setState(() => _offset = next);
  }

  void _release() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final action = _past ? _actionFor(_offset) : null;
    _past = false;

    _settleFrom = _offset;
    // A committed swipe unwinds a touch slower than an abandoned one: the row
    // it acted on is usually about to disappear, and the extra beat keeps the
    // removal from reading as a glitch.
    _settle.duration = CcMotion.resolve(
      context,
      action == null ? CcMotion.normal : CcMotion.slow,
    );
    _settle.forward(from: 0);

    if (action != null) {
      HapticFeedback.mediumImpact();
      action.onTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final live =
        widget.enabled &&
        (widget.startAction != null || widget.endAction != null);
    if (!live) {
      return widget.child;
    }

    Widget content = widget.child;
    if (widget.requireLongPress) {
      // The pointer-side arm cue: the row shrinks a hair the moment the hold
      // registers, so a mouse user learns the gesture took without haptics.
      content = AnimatedScale(
        scale: _dragging ? 0.98 : 1,
        duration: CcMotion.resolve(context, CcMotion.fast),
        curve: CcMotion.standard,
        child: content,
      );
    }
    content = Transform.translate(offset: Offset(_offset, 0), child: content);

    final uncovered = _actionFor(_offset);
    final gate = widget.requireLongPress;

    // Annotation only, deliberately not a container: the row's own tappable
    // already owns the semantics node, and these have to land on it rather
    // than on a parent the focus never stops at.
    return Semantics(
      customSemanticsActions: {
        for (final action in [widget.startAction, widget.endAction])
          if (action != null)
            CustomSemanticsAction(label: action.label): action.onTriggered,
      },
      // Raw rather than a [GestureDetector] for one reason: the long press
      // deadline is fixed at [kLongPressTimeout] there, and half a second is
      // tuned for "open a context menu", not "pick this row up".
      child: RawGestureDetector(
        // Keyed on the hold: `RawGestureDetector` re-runs an existing
        // recognizer's initializer rather than reconstructing it, and
        // `duration` is constructor-only — without this a changed
        // [CcSwipeActions.holdDuration] would silently keep the old deadline.
        key: ValueKey(gate ? widget.holdDuration : null),
        behavior: HitTestBehavior.opaque,
        // Exactly one of the two lanes is wired. Both feed the same offset
        // state, so the visuals and thresholds cannot drift apart between them.
        gestures: {
          if (gate)
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: widget.holdDuration,
                    debugOwner: this,
                  ),
                  (instance) {
                    instance.onLongPressStart = (_) => _onStart();
                    instance.onLongPressMoveUpdate = (d) =>
                        _apply(d.localOffsetFromOrigin.dx);
                    instance.onLongPressEnd = (_) => _release();
                    // Also fires for a press that never became a long press,
                    // before `onLongPressStart`; `_release` is a no-op unless
                    // a drag is actually live.
                    instance.onLongPressCancel = _release;
                  },
                ),
          if (!gate)
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(() => HorizontalDragGestureRecognizer(debugOwner: this), (
                  instance,
                ) {
                  instance.onStart = (_) => _onStart();
                  instance.onUpdate = (d) => _apply(_offset + d.delta.dx);
                  instance.onEnd = (_) => _release();
                  instance.onCancel = _release;
                }),
        },
        child: Stack(
          children: [
            if (uncovered != null)
              Positioned.fill(
                child: _SwipeActionPanel(
                  action: uncovered,
                  extent: _offset.abs(),
                  onLeft: _offset > 0,
                  past: _past,
                ),
              ),
            content,
          ],
        ),
      ),
    );
  }
}

/// The strip uncovered behind the row.
///
/// Sized to exactly what the drag has uncovered and clipped, so the fill never
/// bleeds under a row whose own background is transparent. The glyph sits at a
/// fixed inset from the outer edge and is revealed by the strip widening, which
/// is what makes the panel read as sitting *under* the row rather than sliding
/// in beside it.
class _SwipeActionPanel extends StatelessWidget {
  const _SwipeActionPanel({
    required this.action,
    required this.extent,
    required this.onLeft,
    required this.past,
  });

  final CcSwipeAction action;
  final double extent;
  final bool onLeft;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedScale(
      // The commit tell, and not the only one: the label spells the verb out.
      scale: past ? 1.15 : 1,
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      child: Icon(action.icon, size: 16, color: action.foreground),
    );
    final label = Text(
      action.label,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      style: CcTypography.label.copyWith(color: action.foreground),
    );

    return Align(
      alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: extent,
        child: ClipRect(
          child: ColoredBox(
            color: action.background,
            // The content lays out at its natural width and is clipped by the
            // strip; constrained to `extent` it would overflow-and-shout the
            // moment the drag started.
            child: OverflowBox(
              alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
              maxWidth: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: onLeft
                      ? [icon, const SizedBox(width: AppSpacing.xs), label]
                      : [label, const SizedBox(width: AppSpacing.xs), icon],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
