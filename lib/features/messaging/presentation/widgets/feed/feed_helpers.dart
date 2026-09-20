import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// How many rows the feed will ever measure for real (see
/// [IdlePrecalculationPolicy]). Rows beyond it keep their estimate until they
/// are built.
const int kFeedPrecalcRowBudget = 24;

/// Precalculation policy that measures rows only while the feed is idle, and
/// only up to [kFeedPrecalcRowBudget] of them.
///
/// **Precalculating an extent builds the row.** SuperListView measures by
/// building the item off-screen, laying it out and throwing it away
/// (`measureExtentForItem`), so for this feed one measurement is a whole
/// [SpaceMessageBubble]: a markdown parse, the syntax-highlighted diffs a file
/// edit opens by default — and, for the lite list rows the wire ships without
/// their transcript, a `messaging.getMessageById` round trip apiece. Measuring
/// the window unconditionally therefore costs exactly what rendering the entire
/// conversation costs, which is the thing the windowed lazy list exists to
/// avoid: opening a long space spent seconds building sixty turns nobody was
/// looking at, and fired one transcript fetch per turn to do it.
///
/// So measurement is deferred out of the open (and out of every window growth
/// and scroll) and bounded. The budget is what buys back the original intent —
/// a stable scrollbar thumb and a growth delta the follow physics can trust —
/// for the rows around the viewport, where it is felt, without paying it for
/// scrollback nobody has reached. Beyond the budget rows keep
/// `estimateMessageRowExtent`, which is content-derived rather than the
/// package's flat 100px, and every row corrects itself the moment it is
/// genuinely built.
class IdlePrecalculationPolicy extends ExtentPrecalculationPolicy {
  bool _armed = false;

  /// Allows measurement again. Re-runs layout when this flips it back on: a
  /// policy that returned false is not consulted again until it says so.
  void arm() {
    if (_armed) {
      return;
    }
    _armed = true;
    valueDidChange();
  }

  /// Suspends measurement. Deliberately silent — the next layout pass asks the
  /// policy again anyway, and notifying here would mark the list dirty on every
  /// scroll tick.
  void disarm() => _armed = false;

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) {
    if (!_armed || context.numberOfItemsWithEstimatedExtent == 0) {
      return false;
    }
    final measured =
        context.numberOfItems - context.numberOfItemsWithEstimatedExtent;
    return measured < kFeedPrecalcRowBudget;
  }
}

/// Accent flash wrapper for the permalink-scroll highlight pulse.
class Highlight extends StatefulWidget {
  /// Creates a [Highlight] around [child].
  const Highlight({super.key, required this.child});

  /// The row to flash.
  final Widget child;

  @override
  State<Highlight> createState() => _HighlightState();
}

class _HighlightState extends State<Highlight>
    with SingleTickerProviderStateMixin {
  static const _pulse = Duration(milliseconds: 1200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    // The reduced-motion check is an inherited lookup (CcTheme / MediaQuery),
    // so it can only run here — reading it in initState throws.
    _controller
      ..duration = CcMotion.resolve(context, _pulse)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Fade an accentSoft wash in then out over the pulse window.
        final t = _controller.value;
        final alpha = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.accentSoft.withValues(alpha: alpha),
            borderRadius: AppRadii.brMd,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
