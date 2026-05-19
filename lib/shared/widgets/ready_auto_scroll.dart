import 'package:control_center/shared/widgets/auto_scroll/auto_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Drop-in [AutoScroll] replacement that survives asynchronously-loading
/// content and mid-attach scroll positions.
///
/// Our vendored [AutoScroll] reads `controller.position.maxScrollExtent`
/// from a post-frame callback in `initState`. That call has two failure
/// modes:
///
/// 1. **Empty content.** For scrollables whose extent only appears after a
///    Riverpod async load (PR detail diff, PR list, newsfeed grid, file
///    tree), the one-shot check sees `maxScrollExtent == 0` and middle-click
///    stays permanently disabled.
/// 2. **Mid-attach position.** During route transitions or when more than
///    one widget has attached the controller, the call either throws
///    `Null check operator used on a null value` (content dimensions not yet
///    applied) or trips the `ScrollController attached to multiple scroll
///    views` assertion.
///
/// To avoid both we never mount [AutoScroll] until we've actually observed
/// a [ScrollMetricsNotification] with a non-zero extent and exactly one
/// position attached to the controller — by then the scrollable is laid out
/// and safe to probe. Until then we render the child directly so middle-
/// click is simply inert (instead of crashing the subtree).
class ReadyAutoScroll extends StatefulWidget {
  /// Creates a [ReadyAutoScroll].
  const ReadyAutoScroll({
    super.key,
    required this.controller,
    required this.child,
    this.scrollDirection = Axis.vertical,
  });

  /// Controller attached to the wrapped scrollable.
  final ScrollController controller;

  /// Scroll axis to forward to [AutoScroll].
  final Axis scrollDirection;

  /// Wrapped scrollable.
  final Widget child;

  @override
  State<ReadyAutoScroll> createState() => _ReadyAutoScrollState();
}

class _ReadyAutoScrollState extends State<ReadyAutoScroll> {
  bool _ready = false;

  bool _isSafeToMount(ScrollMetricsNotification notification) {
    if (notification.metrics.maxScrollExtent <= 0) {
      return false;
    }
    // `AutoScroll.initState` calls `controller.position`, which throws when
    // the controller has zero or multiple positions attached. Wait until
    // exactly one position is attached before mounting.
    return widget.controller.positions.length == 1;
  }

  @override
  Widget build(BuildContext context) {
    final listener = NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (!_ready && _isSafeToMount(notification)) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_ready && widget.controller.positions.length == 1) {
              setState(() => _ready = true);
            }
          });
        }
        return false;
      },
      child: widget.child,
    );

    if (!_ready) {
      return listener;
    }

    return AutoScroll(
      controller: widget.controller,
      scrollDirection: widget.scrollDirection,
      child: listener,
    );
  }
}
