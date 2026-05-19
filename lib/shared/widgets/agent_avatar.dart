import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Builder type for constructing a hover card widget for an agent.
typedef HoverCardBuilder = Widget Function(
  BuildContext context,
  String agentId,
);

/// Avatar for an AI agent. Renders the agent's initial inside an [FAvatar]
/// and — when [showHoverCard] is true — opens a hover card overlay via
/// [hoverCardBuilder].
class AgentAvatar extends StatefulWidget {
  /// Creates an [AgentAvatar].
  const AgentAvatar({
    super.key,
    required this.agentId,
    this.name,
    this.size = 24,
    this.showHoverCard = true,
    this.hoverCardBuilder,
  });

  /// Id of the agent backing this avatar.
  final String agentId;

  /// Display name used to derive the avatar initial.
  /// When null, a question mark is shown.
  final String? name;

  /// Logical pixel size of the avatar.
  final double size;

  /// When true and [hoverCardBuilder] is provided, tapping the avatar opens
  /// the hover card overlay.
  final bool showHoverCard;

  /// Builder that produces the hover-card widget shown on tap.
  final HoverCardBuilder? hoverCardBuilder;

  @override
  State<AgentAvatar> createState() => _AgentAvatarState();
}

class _AgentAvatarState extends State<AgentAvatar> {
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final GlobalKey _avatarKey = GlobalKey();
  Offset? _overlayOffset;

  static const _overlayWidth = 400.0;

  void _computeOverlayOffset() {
    final ctx = _avatarKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final avatarCenter = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height),
      ancestor: overlay,
    );
    final left = (avatarCenter.dx - _overlayWidth / 2).clamp(
      0.0,
      (overlay.size.width - _overlayWidth).clamp(0.0, double.infinity),
    );
    final top = avatarCenter.dy + 6;
    _overlayOffset = Offset(left, top);
  }

  void _toggle() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    } else {
      _computeOverlayOffset();
      _popupCtrl.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final initial = (name != null && name.isNotEmpty)
        ? name[0].toUpperCase()
        : '?';
    final avatar = FAvatar.raw(size: widget.size, child: Text(initial));

    if (!widget.showHoverCard || widget.hoverCardBuilder == null) {
      return KeyedSubtree(key: _avatarKey, child: avatar);
    }

    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        key: _avatarKey,
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final offset = _overlayOffset ?? Offset.zero;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _popupCtrl.hide,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy,
          width: _overlayWidth,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _popupCtrl.hide();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: widget.hoverCardBuilder!(context, widget.agentId),
          ),
        ),
      ],
    );
  }
}
