import 'package:flutter/widgets.dart';

/// Keeps arrow-key focus moves inside [child], a pane of the screen.
///
/// Flutter's default arrow-key traversal searches the whole focus scope by
/// geometry, so ↓ from the last control of one pane lands in whichever pane
/// sits nearest below or beside it. Inside this widget an arrow key moves only
/// among the pane's own focusable descendants and does nothing at the pane's
/// edge. It is also a [FocusTraversalGroup], so Tab finishes the pane before
/// moving to the next one.
///
/// A descendant that maps arrow keys itself (a text field, a list with its own
/// row model) still wins: its handler sits closer to the focused node.
class ConfinedDirectionalFocus extends StatefulWidget {
  /// Creates a confined pane around [child].
  const ConfinedDirectionalFocus({super.key, required this.child, this.policy});

  /// The pane.
  final Widget child;

  /// Tab order inside the pane. Defaults to the ambient group's policy.
  final FocusTraversalPolicy? policy;

  @override
  State<ConfinedDirectionalFocus> createState() =>
      _ConfinedDirectionalFocusState();
}

class _ConfinedDirectionalFocusState extends State<ConfinedDirectionalFocus> {
  final FocusNode _region = FocusNode(
    debugLabel: 'ConfinedDirectionalFocus',
    canRequestFocus: false,
    skipTraversal: true,
  );

  late final Map<Type, Action<Intent>> _actions = {
    DirectionalFocusIntent: _ConfinedDirectionalFocusAction(_region),
  };

  @override
  void dispose() {
    _region.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: widget.policy,
      child: Focus(
        focusNode: _region,
        includeSemantics: false,
        child: Actions(actions: _actions, child: widget.child),
      ),
    );
  }
}

class _ConfinedDirectionalFocusAction extends Action<DirectionalFocusIntent> {
  _ConfinedDirectionalFocusAction(this.region);

  final FocusNode region;

  @override
  bool isEnabled(DirectionalFocusIntent intent) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || !primary.ancestors.contains(region)) {
      return false;
    }
    // Same rule as Flutter's DirectionalFocusAction: a text field keeps its
    // arrow keys.
    final context = primary.context;
    if (intent.ignoreTextFields &&
        context != null &&
        (context.widget is EditableText ||
            context.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    return true;
  }

  @override
  void invoke(DirectionalFocusIntent intent) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) {
      return;
    }
    final next = nearestInDirection(
      primary.rect,
      intent.direction,
      region.traversalDescendants.where((n) => n != primary),
    );
    if (next == null) {
      // The pane's edge: stay put rather than leak into a neighbour.
      return;
    }
    next.requestFocus();
    final context = next.context;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: switch (intent.direction) {
          TraversalDirection.up || TraversalDirection.left =>
            ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          TraversalDirection.down || TraversalDirection.right =>
            ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        },
      );
    }
  }
}

/// The candidate nearest to [from] in [direction], or null when none lies
/// that way.
///
/// Candidates overlapping [from] across the direction (the same column for
/// ↑/↓, the same row for ←/→) win over the rest; among those the nearest
/// along the direction wins, then the nearest across it.
@visibleForTesting
FocusNode? nearestInDirection(
  Rect from,
  TraversalDirection direction,
  Iterable<FocusNode> candidates,
) {
  final vertical =
      direction == TraversalDirection.up ||
      direction == TraversalDirection.down;
  bool ahead(Rect r) => switch (direction) {
    TraversalDirection.down => r.center.dy >= from.bottom,
    TraversalDirection.up => r.center.dy <= from.top,
    TraversalDirection.right => r.center.dx >= from.right,
    TraversalDirection.left => r.center.dx <= from.left,
  };
  bool inBand(Rect r) => vertical
      ? r.left < from.right && r.right > from.left
      : r.top < from.bottom && r.bottom > from.top;
  double along(Rect r) => switch (direction) {
    TraversalDirection.down => r.top - from.bottom,
    TraversalDirection.up => from.top - r.bottom,
    TraversalDirection.right => r.left - from.right,
    TraversalDirection.left => from.left - r.right,
  };
  double across(Rect r) => vertical
      ? (r.center.dx - from.center.dx).abs()
      : (r.center.dy - from.center.dy).abs();

  FocusNode? best;
  var bestInBand = false;
  var bestAlong = double.infinity;
  var bestAcross = double.infinity;
  for (final node in candidates) {
    final r = node.rect;
    if (!ahead(r)) {
      continue;
    }
    final band = inBand(r);
    final a = along(r).clamp(0.0, double.infinity);
    final c = across(r);
    final better = switch ((band, bestInBand)) {
      (true, false) => true,
      (false, true) => false,
      _ => a < bestAlong || (a == bestAlong && c < bestAcross),
    };
    if (best == null || better) {
      best = node;
      bestInBand = band;
      bestAlong = a;
      bestAcross = c;
    }
  }
  return best;
}
