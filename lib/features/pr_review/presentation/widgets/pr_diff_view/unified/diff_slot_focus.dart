import 'dart:async';
import 'dart:math' as math;

import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:flutter/widgets.dart';

/// What [DiffSlotFocus] needs from the diff view that owns the slots.
abstract interface class DiffSlotFocusHost {
  /// The current offset-ordered slot list.
  List<DiffSlot> get focusSlots;

  /// Index of the slot keyed [key] in [focusSlots], or null when it is gone.
  int? slotIndexOfKey(String key);

  /// The outer scroll position the diff lives in, or null before layout.
  ScrollPosition? get focusScrollPosition;

  /// Live absolute scroll offset of slot [index], or null before layout.
  double? slotScrollOffset(int index);

  /// Height of the pinned chrome above the diff (the tab strip inset).
  double get pinnedInset;

  /// Height of a file header, which docks over a file's rows while it scrolls.
  double get headerExtent;

  /// Whether scrolling should jump instead of animating.
  bool get reduceMotion;

  /// Whether slot [slot] is a stop for ↑/↓ when it is not built yet.
  bool isSlotNavigable(DiffSlot slot);
}

/// Keyboard focus model for the unified diff's sparse slot children.
///
/// Flutter's default arrow-key traversal is geometric across the whole focus
/// scope. The diff builds its slots lazily, so the next file header is often
/// not built when the user presses ↓, and the geometric search lands on the
/// nearest focusable below the current one: a row of the file tree beside the
/// diff. This model navigates by slot order instead. ↑/↓ move between the
/// diff's rows (file headers, gap expanders, comment threads, the composer),
/// built or not, scrolling the target into view first. ←/→ move between the
/// controls of the focused row. An arrow key never moves focus out of the
/// diff; Tab and Shift+Tab move between regions.
class DiffSlotFocus {
  final Map<String, FocusNode> _nodes = {};
  final Map<FocusNode, String> _keys = {};

  /// Bumped on every slot move so a stale in-flight move gives up.
  int _moveSerial = 0;

  /// The focus node wrapping slot [key]'s child. Not focusable itself; its
  /// descendants are the slot's controls.
  FocusNode nodeFor(String key) => _nodes.putIfAbsent(key, () {
    final node = FocusNode(
      debugLabel: 'diff slot $key',
      canRequestFocus: false,
      skipTraversal: true,
    );
    _keys[node] = key;
    return node;
  });

  /// Key of the slot containing [focus], or null when it is outside the diff.
  String? keyOfFocus(FocusNode? focus) {
    for (var node = focus; node != null; node = node.parent) {
      final key = _keys[node];
      if (key != null) {
        return key;
      }
    }
    return null;
  }

  /// Key of the slot holding the primary focus, or null.
  String? get focusedKey => keyOfFocus(FocusManager.instance.primaryFocus);

  /// Disposes the nodes of slots that no longer exist. A node still attached
  /// to a mounted child is kept until a later prune, after the child is gone.
  void prune(bool Function(String key) isLive) {
    final dead = [
      for (final MapEntry(:key, :value) in _nodes.entries)
        if (!isLive(key) && !_isBuilt(value)) key,
    ];
    for (final key in dead) {
      final node = _nodes.remove(key)!;
      _keys.remove(node);
      node.dispose();
    }
  }

  /// Releases every node.
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
    _keys.clear();
  }

  /// Whether this model handles [intent] for the current primary focus.
  bool handles(DirectionalFocusIntent intent) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || keyOfFocus(primary) == null) {
      return false;
    }
    // Same rule as Flutter's DirectionalFocusAction: a text field keeps its
    // arrow keys.
    if (intent.ignoreTextFields && _inTextField(primary)) {
      return false;
    }
    return true;
  }

  static bool _inTextField(FocusNode node) {
    final context = node.context;
    if (context == null) {
      return false;
    }
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Moves focus one step in [direction] from the focused slot control.
  void move(DiffSlotFocusHost host, TraversalDirection direction) {
    final primary = FocusManager.instance.primaryFocus;
    final key = keyOfFocus(primary);
    if (primary == null || key == null) {
      return;
    }
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.down:
        final index = host.slotIndexOfKey(key);
        if (index == null) {
          return;
        }
        final delta = direction == TraversalDirection.down ? 1 : -1;
        final target = _nextStop(host, index, delta);
        if (target != null) {
          unawaited(focusSlot(host, target));
        }
      case TraversalDirection.left:
      case TraversalDirection.right:
        _moveWithinRow(primary, _nodes[key]!, direction);
    }
  }

  int? _nextStop(DiffSlotFocusHost host, int from, int delta) {
    final slots = host.focusSlots;
    for (var i = from + delta; i >= 0 && i < slots.length; i += delta) {
      final node = _nodes[slots[i].key];
      if (node != null && _isBuilt(node)) {
        // Built: trust what it actually rendered (a thread that resolved to
        // an empty box has nothing to focus).
        if (node.traversalDescendants.isNotEmpty) {
          return i;
        }
        continue;
      }
      if (host.isSlotNavigable(slots[i])) {
        return i;
      }
    }
    return null;
  }

  /// Scrolls slot [index] into view and focuses its first control.
  Future<void> focusSlot(DiffSlotFocusHost host, int index) async {
    final serial = ++_moveSerial;
    final slots = host.focusSlots;
    if (index < 0 || index >= slots.length) {
      return;
    }
    final slot = slots[index];
    final position = host.focusScrollPosition;
    final top = host.slotScrollOffset(index);
    if (position != null && top != null) {
      final target = _revealTarget(host, position, slot, top);
      if ((target - position.pixels).abs() > 0.5) {
        if (host.reduceMotion) {
          position.jumpTo(target);
        } else {
          await position.animateTo(
            target,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        }
      }
    }
    // The slot builds during the layout that follows the scroll; give it a
    // few frames (a lazy structure parse can move it once more).
    for (var attempt = 0; attempt < 4; attempt++) {
      if (serial != _moveSerial) {
        return;
      }
      final node = _nodes[slot.key];
      final first = node == null || !_isBuilt(node)
          ? null
          : _firstControl(node);
      if (first != null) {
        first.requestFocus();
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Scroll offset that shows [slot] (whose live top is [top]) below the
  /// pinned chrome. A header docks at the top, where it would pin anyway;
  /// any other row scrolls the minimum, clear of its file's docked header.
  double _revealTarget(
    DiffSlotFocusHost host,
    ScrollPosition position,
    DiffSlot slot,
    double top,
  ) {
    double clamp(double v) =>
        v.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (slot.kind == DiffSlotKind.header) {
      return clamp(top - host.pinnedInset);
    }
    final cover = host.pinnedInset + host.headerExtent;
    final bottom = top + slot.height;
    final visibleTop = position.pixels + cover;
    final visibleBottom = position.pixels + position.viewportDimension;
    if (top < visibleTop) {
      return clamp(top - cover);
    }
    if (bottom > visibleBottom) {
      return clamp(math.min(bottom - position.viewportDimension, top - cover));
    }
    return position.pixels;
  }

  /// Whether [node]'s slot child is mounted. A node keeps its last context
  /// after the sliver drops the child, so the context alone says nothing.
  static bool _isBuilt(FocusNode node) => node.context?.mounted ?? false;

  static FocusNode? _firstControl(FocusNode slotNode) {
    final controls = slotNode.traversalDescendants.toList();
    if (controls.isEmpty) {
      return null;
    }
    // Reading order: topmost first, then the start edge. A row container (the
    // header's tap target) shares its children's top and starts at the row's
    // start edge, so it sorts first.
    final rtl = _isRtl(slotNode);
    controls.sort((a, b) {
      final dy = a.rect.top.compareTo(b.rect.top);
      if (dy != 0) {
        return dy;
      }
      return rtl
          ? b.rect.right.compareTo(a.rect.right)
          : a.rect.left.compareTo(b.rect.left);
    });
    return controls.first;
  }

  static bool _isRtl(FocusNode node) {
    final context = node.context;
    return context != null &&
        Directionality.maybeOf(context) == TextDirection.rtl;
  }

  /// ←/→ between the controls sharing the focused control's row.
  void _moveWithinRow(
    FocusNode primary,
    FocusNode slotNode,
    TraversalDirection direction,
  ) {
    final current = primary.rect;
    final row = slotNode.traversalDescendants
        .where(
          (n) =>
              n == primary ||
              (n.rect.top < current.bottom && n.rect.bottom > current.top),
        )
        .toList();
    if (!row.contains(primary)) {
      row.add(primary);
    }
    // Sorted from the start edge. A container (the header's tap target) has
    // the row's start edge, so it comes first.
    final rtl = _isRtl(slotNode);
    row.sort(
      (a, b) => rtl
          ? b.rect.right.compareTo(a.rect.right)
          : a.rect.left.compareTo(b.rect.left),
    );
    final towardEnd = (direction == TraversalDirection.right) != rtl;
    final i = row.indexOf(primary) + (towardEnd ? 1 : -1);
    if (i < 0 || i >= row.length) {
      return;
    }
    final next = row[i];
    next.requestFocus();
    final context = next.context;
    if (context != null) {
      unawaited(
        Scrollable.ensureVisible(
          context,
          alignmentPolicy: towardEnd
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ),
      );
    }
  }
}

/// Routes the app's arrow-key [DirectionalFocusIntent] through [DiffSlotFocus]
/// while focus is inside the diff. Disabled elsewhere, so the intent falls
/// through to the default action.
class DiffDirectionalFocusAction extends Action<DirectionalFocusIntent> {
  /// Creates the action.
  DiffDirectionalFocusAction(this.focus, this.host);

  /// The diff's focus model.
  final DiffSlotFocus focus;

  /// The diff view.
  final DiffSlotFocusHost host;

  @override
  bool isEnabled(DirectionalFocusIntent intent) => focus.handles(intent);

  @override
  void invoke(DirectionalFocusIntent intent) =>
      focus.move(host, intent.direction);
}
