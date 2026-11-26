import 'package:flutter/widgets.dart';

/// Keeps keyboard focus in the inline composer while the diff swaps the
/// composer slot's element for a new one.
///
/// The diff builds the slot again while it opens. The old composer held focus,
/// so the new one, told not to take focus a second time, would be left without
/// it. The old tracker raises [handoff] as it leaves with focus inside, and
/// the next one (already mounted, or mounting later) lowers it and puts focus
/// back in its text field. A composer the person moved away from holds no
/// focus when it leaves, so nothing is pulled back.
class ComposerFocusTracker extends StatefulWidget {
  /// Creates a tracker around [child].
  const ComposerFocusTracker({
    super.key,
    required this.handoff,
    required this.onFocused,
    required this.child,
  });

  /// Shared by every mount of the composer slot; owned by the host.
  final ValueNotifier<bool> handoff;

  /// Focus landed inside the composer.
  final VoidCallback onFocused;

  /// The composer.
  final Widget child;

  @override
  State<ComposerFocusTracker> createState() => _ComposerFocusTrackerState();
}

class _ComposerFocusTrackerState extends State<ComposerFocusTracker> {
  // Never takes focus itself: it only reports whether focus is inside.
  final FocusNode _region = FocusNode(
    debugLabel: 'ComposerFocusTracker',
    canRequestFocus: false,
    skipTraversal: true,
  );
  late final ValueNotifier<bool> _handoff = widget.handoff;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _handoff.addListener(_takeOver);
    _takeOver();
  }

  void _takeOver() {
    if (_leaving || !_handoff.value) {
      return;
    }
    _handoff.value = false;
    // After the frame: the composer that left hands focus to its opener as it
    // is disposed, and this request has to come after that one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _region.hasFocus) {
        return;
      }
      for (final node in _region.traversalDescendants) {
        if (node.context?.findAncestorWidgetOfExactType<EditableText>() !=
            null) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  @override
  void activate() {
    super.activate();
    _leaving = false;
  }

  @override
  void deactivate() {
    _leaving = true;
    // Read while the subtree is still attached.
    if (_region.hasFocus) {
      _handoff.value = true;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _handoff.removeListener(_takeOver);
    _region.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _region,
      includeSemantics: false,
      onFocusChange: (focused) {
        if (focused) {
          widget.onFocused();
        }
      },
      child: widget.child,
    );
  }
}
