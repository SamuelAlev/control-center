import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Opens/closes an overlay anchored by [CcOverlayAnchor].
class CcOverlayController extends ChangeNotifier {
  bool _open = false;

  /// Whether the overlay is currently shown.
  bool get isOpen => _open;

  /// Shows the overlay.
  void show() {
    if (!_open) {
      _open = true;
      notifyListeners();
    }
  }

  /// Hides the overlay.
  void hide() {
    if (_open) {
      _open = false;
      notifyListeners();
    }
  }

  /// Toggles the overlay.
  void toggle() => _open ? hide() : show();
}

/// Builds anchored-overlay content. [targetSize] is the laid-out size of the
/// anchor target (useful for width-matching a dropdown to its trigger).
typedef CcOverlayContentBuilder = Widget Function(
  BuildContext context,
  Size? targetSize,
);

/// Anchors a floating overlay (dropdown, popover, menu, autocomplete list) to a
/// [target] widget.
///
/// The shared overlay primitive for cc_ui — built on [OverlayPortal] +
/// [CompositedTransformTarget]/[CompositedTransformFollower] + [LayerLink], with
/// outside-tap and Escape dismissal. Components drive it through a
/// [CcOverlayController].
class CcOverlayAnchor extends StatefulWidget {
  /// Creates a [CcOverlayAnchor].
  const CcOverlayAnchor({
    super.key,
    required this.controller,
    required this.target,
    required this.overlayBuilder,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 4),
    this.matchTargetWidth = false,
    this.barrierDismissible = true,
  });

  /// Controls open/close state.
  final CcOverlayController controller;

  /// The anchor widget (e.g. a trigger button or field).
  final Widget target;

  /// Builds the floating content.
  final CcOverlayContentBuilder overlayBuilder;

  /// Point on the target the follower aligns to.
  final Alignment targetAnchor;

  /// Point on the follower aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the follower.
  final Offset offset;

  /// Constrain the follower to the target's width (dropdown-style).
  final bool matchTargetWidth;

  /// Whether tapping outside the overlay closes it.
  final bool barrierDismissible;

  @override
  State<CcOverlayAnchor> createState() => _CcOverlayAnchorState();
}

class _CcOverlayAnchorState extends State<CcOverlayAnchor> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(CcOverlayAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final shouldShow = widget.controller.isOpen;
    if (shouldShow && !_portal.isShowing) {
      _portal.show();
    } else if (!shouldShow && _portal.isShowing) {
      _portal.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(link: _link, child: widget.target),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final targetSize = _link.leaderSize;
    Widget content = widget.overlayBuilder(context, targetSize);
    if (widget.matchTargetWidth && targetSize != null) {
      content = SizedBox(width: targetSize.width, child: content);
    }
    // Escape closes the overlay when focus is within it.
    content = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              widget.controller.hide();
              return null;
            },
          ),
        },
        child: content,
      ),
    );

    final follower = CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      child: Align(alignment: widget.followerAnchor, child: content),
    );

    if (!widget.barrierDismissible) {
      return follower;
    }
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.controller.hide,
          ),
        ),
        follower,
      ],
    );
  }
}
