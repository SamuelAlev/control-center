import 'dart:collection';

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:flutter/widgets.dart';

/// Share of the switcher's width a page travels while it enters or leaves.
/// Proportional rather than fixed so the same drill reads as a nudge in a
/// 54px rail and as a short slide in a 248px sidebar.
const double _kTravelFraction = 0.1;

/// Swaps [child] whenever [depth] changes, sliding along the reading axis like
/// a navigation stack: going deeper, the current page drifts toward the start
/// edge and fades while the new one arrives from the end; going back runs the
/// same motion mirrored. Directions follow [Directionality].
///
/// Shallower pages stay mounted (offstage, tickers paused) while a deeper one
/// is shown, so returning restores their scroll offsets and expansion state.
/// Deeper pages are disposed once the way back has finished.
///
/// A reversal mid-flight (back before the drill settled) runs the transition
/// backwards from where it is instead of jumping. Reduced motion
/// ([CcMotion.reduced]) drops the travel and keeps a short cross-fade. Focus
/// inside the outgoing page moves to the first focusable of the incoming one.
class CcDepthSwitcher extends StatefulWidget {
  /// Creates a [CcDepthSwitcher].
  const CcDepthSwitcher({super.key, required this.depth, required this.child});

  /// Navigation depth of [child]. The page identity: a new value starts a
  /// transition, an unchanged one just updates the current page.
  final int depth;

  /// The page at [depth].
  final Widget child;

  @override
  State<CcDepthSwitcher> createState() => _CcDepthSwitcherState();
}

class _CcDepthSwitcherState extends State<CcDepthSwitcher>
    with SingleTickerProviderStateMixin {
  /// Mounted pages by depth: the shown one plus every shallower one retained
  /// beneath it, and the deeper one while a way back is still in flight.
  final SplayTreeMap<int, Widget> _pages = SplayTreeMap();
  final Map<int, FocusNode> _focusNodes = {};

  /// 0 shows [_from], 1 shows [_to].
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  )..addStatusListener(_onStatus);

  late int _to = widget.depth;
  int? _from;

  /// Set while rewinding the controller to 0 for a new transition, so the
  /// `dismissed` status that rewind emits is not mistaken for a finished way
  /// back.
  bool _rewinding = false;

  @override
  void initState() {
    super.initState();
    _pages[widget.depth] = widget.child;
  }

  @override
  void didUpdateWidget(covariant CcDepthSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    final depth = widget.depth;
    _pages[depth] = widget.child;
    final from = _from;
    if (depth == _to) {
      if (_controller.status == AnimationStatus.reverse) {
        _controller.forward();
      }
      return;
    }
    if (depth == from) {
      // Back before the drill settled: retrace it from where it is.
      _handOffFocus(from: _to, to: depth);
      _controller.reverse();
      return;
    }
    final shown = from != null && _controller.value < 0.5 ? from : _to;
    _handOffFocus(from: shown, to: depth);
    _from = shown;
    _to = depth;
    _controller.duration = CcMotion.reduced(context)
        ? CcMotion.fade
        : CcMotion.slow;
    _rewinding = true;
    _controller.value = 0;
    _rewinding = false;
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (_rewinding) {
      return;
    }
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _to = _from ?? _to;
        _from = null;
        _prune();
      });
      _controller.value = 1;
    } else if (status == AnimationStatus.completed && _from != null) {
      setState(() {
        _from = null;
        _prune();
      });
    }
  }

  /// Drops pages deeper than the one now shown.
  void _prune() {
    final deeper = _pages.keys.where((d) => d > _to).toList();
    for (final d in deeper) {
      _pages.remove(d);
      _focusNodes.remove(d)?.dispose();
    }
  }

  /// When focus sits in the page that is leaving, the page's subtree stops
  /// being focusable this frame; land focus on the arriving page instead of
  /// dropping it on the floor.
  void _handOffFocus({required int from, required int to}) {
    if (!(_focusNodes[from]?.hasFocus ?? false)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNodes[to]?.traversalDescendants.firstOrNull?.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    final reversing = _controller.status == AnimationStatus.reverse;
    final active = reversing && from != null ? from : _to;
    // Deeper arrives from the end edge, shallower from the start edge.
    final forward = from == null || _to > from;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final travel = CcMotion.reduced(context)
        ? 0.0
        : _kTravelFraction * (forward ? 1 : -1) * (rtl ? -1 : 1);

    return Stack(
      fit: StackFit.passthrough,
      // Clip only while pages are travelling; at rest, content such as a
      // bleeding divider or a focus ring keeps painting past the edge.
      clipBehavior: from == null ? Clip.none : Clip.hardEdge,
      children: [
        for (final MapEntry(key: depth, value: page) in _pages.entries)
          KeyedSubtree(
            key: ValueKey<int>(depth),
            child: _DepthPage(
              animation: _controller,
              role: depth == _to
                  ? (from == null ? _PageRole.settled : _PageRole.incoming)
                  : depth == from
                  ? _PageRole.outgoing
                  : _PageRole.retained,
              interactive: depth == active,
              travel: travel,
              focusNode: _focusNodes.putIfAbsent(
                depth,
                () => FocusNode(
                  debugLabel: 'CcDepthSwitcher page $depth',
                  skipTraversal: true,
                  canRequestFocus: false,
                ),
              ),
              child: page,
            ),
          ),
      ],
    );
  }
}

enum _PageRole { settled, incoming, outgoing, retained }

/// One page of a [CcDepthSwitcher]. The wrapper tree is identical in every
/// role, so a page changing role never remounts its subtree.
class _DepthPage extends StatelessWidget {
  const _DepthPage({
    required this.animation,
    required this.role,
    required this.interactive,
    required this.travel,
    required this.focusNode,
    required this.child,
  });

  final Animation<double> animation;
  final _PageRole role;
  final bool interactive;

  /// Signed horizontal travel, as a fraction of the page width, for an
  /// incoming page at t=0. The outgoing page travels the opposite way.
  final double travel;
  final FocusNode focusNode;
  final Widget child;

  // The leaving page clears out over the first 60% (the exit runs one tier
  // quicker than the entrance); the arriving one resolves over the last 70%,
  // so both are briefly faint together rather than ever stacking at full ink.
  static const Curve _exitFade = Interval(0, 0.6, curve: CcMotion.standard);
  static const Curve _enterFade = Interval(0.3, 1, curve: CcMotion.standard);

  @override
  Widget build(BuildContext context) {
    final retained = role == _PageRole.retained;
    return Offstage(
      offstage: retained,
      child: TickerMode(
        enabled: !retained,
        child: IgnorePointer(
          ignoring: !interactive,
          child: ExcludeSemantics(
            excluding: !interactive,
            child: Focus(
              focusNode: focusNode,
              descendantsAreFocusable: interactive,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, page) {
                  final t = animation.value;
                  final (opacity, dx) = switch (role) {
                    _PageRole.incoming => (
                      _enterFade.transform(t),
                      travel * (1 - CcMotion.emphasized.transform(t)),
                    ),
                    _PageRole.outgoing => (
                      1 - _exitFade.transform(t),
                      -travel * CcMotion.emphasized.transform(t),
                    ),
                    _PageRole.settled || _PageRole.retained => (1.0, 0.0),
                  };
                  return Opacity(
                    opacity: opacity,
                    child: FractionalTranslation(
                      // Already signed for the ambient Directionality.
                      translation: Offset(dx, 0),
                      child: page,
                    ),
                  );
                },
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
