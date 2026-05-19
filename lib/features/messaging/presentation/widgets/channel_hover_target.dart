import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_hover_card.dart';
import 'package:control_center/features/messaging/providers/channel_activity_summary_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gap between the sidebar row and the flyout. Rendered as padding INSIDE the
/// card's own [MouseRegion], so the pointer crossing it never closes the card.
const double _gap = 10;

/// Wraps a sidebar channel row so dwelling on it (or focusing it from the
/// keyboard) reveals a [ChannelHoverCard] to its right: what is running in that
/// channel, which agents and subagents are doing it, for how long and how much
/// context each has left.
///
/// The card is interactive — the pointer can travel into it and its rows open
/// the channel or a subagent's activity — so the usual "hide on exit" is
/// deferred by [_closeGrace] and entering the card cancels the pending close.
///
/// Hover-only information would be an accessibility failure, so the card also
/// opens on focus and everything it reports is reachable by simply opening the
/// channel. On touch (the phone remote) no pointer ever enters, the card never
/// shows and the row behaves exactly as it did before.
class ChannelHoverTarget extends ConsumerStatefulWidget {
  /// Creates a [ChannelHoverTarget] for [channel] wrapping [child].
  const ChannelHoverTarget({
    super.key,
    required this.channel,
    required this.child,
    this.enabled = true,
    this.showDelay = const Duration(milliseconds: 450),
  });

  /// The channel the card describes.
  final Channel channel;

  /// The sidebar row.
  final Widget child;

  /// When false the card never shows and [child] renders verbatim.
  final bool enabled;

  /// Hover dwell before the card appears.
  final Duration showDelay;

  @override
  ConsumerState<ChannelHoverTarget> createState() => _ChannelHoverTargetState();
}

/// How long the card survives the pointer leaving it or the row, so the cursor
/// can cross the gap between them.
const Duration _closeGrace = Duration(milliseconds: 120);

class _ChannelHoverTargetState extends ConsumerState<ChannelHoverTarget> {
  final CcOverlayController _controller = CcOverlayController();
  Timer? _open;
  Timer? _close;

  @override
  void dispose() {
    _open?.cancel();
    _close?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleOpen() {
    if (!widget.enabled) {
      return;
    }
    _close?.cancel();
    _close = null;
    if (_controller.isOpen) {
      return;
    }
    _open?.cancel();
    _open = Timer(widget.showDelay, () {
      if (mounted) {
        _controller.show();
      }
    });
  }

  void _scheduleClose() {
    _open?.cancel();
    _open = null;
    _close?.cancel();
    _close = Timer(_closeGrace, () {
      if (mounted) {
        _controller.hide();
      }
    });
  }

  /// Closes immediately — used when the card's own action navigates away, where
  /// waiting out the grace period would leave the card hanging over the new
  /// screen.
  void _closeNow() {
    _open?.cancel();
    _close?.cancel();
    _controller.hide();
  }

  void _onFocusChange(bool hasFocus) {
    if (!widget.enabled) {
      return;
    }
    if (hasFocus) {
      // Keyboard arrival is deliberate, so it needs no dwell.
      _close?.cancel();
      _controller.show();
    } else {
      _scheduleClose();
    }
  }

  void _openChannel(String workspaceId) {
    _closeNow();
    GoRouter.of(context).go(channelRoute(workspaceId, widget.channel.id));
  }

  /// Opens one subagent run's activity. The IDE owns tabs and the sidebar
  /// cannot reach into it, so the target is parked in a one-shot provider the
  /// IDE claims once the conversation it belongs to is open.
  void _openRun(String workspaceId, ChannelLiveRun run, String label) {
    ref.read(pendingAgentRunProvider.notifier).set((
      channelId: widget.channel.id,
      agentId: run.agentId,
      runId: run.runId,
      label: label,
      isSubAgent: true,
    ));
    _openChannel(workspaceId);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (!widget.enabled || workspaceId == null) {
      return widget.child;
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      child: MouseRegion(
        onEnter: (_) => _scheduleOpen(),
        onExit: (_) => _scheduleClose(),
        child: CcOverlayAnchor(
          controller: _controller,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          // The panel supplies the visual gap itself as bridged padding, so the
          // anchor adds none of its own.
          offset: Offset.zero,
          barrierDismissible: false,
          target: widget.child,
          overlayBuilder: (context, _) => _bridge(
            child: ChannelHoverCard(
              channel: widget.channel,
              workspaceId: workspaceId,
              onOpenChannel: () => _openChannel(workspaceId),
              onOpenRun: (run, label) => _openRun(workspaceId, run, label),
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps the card in its own hover region, padded by the visual gap so the
  /// dead space between row and card is still "inside" the card as far as the
  /// pointer is concerned.
  Widget _bridge({required Widget child}) {
    return MouseRegion(
      onEnter: (_) {
        _close?.cancel();
        _close = null;
      },
      onExit: (_) => _scheduleClose(),
      child: Padding(
        padding: const EdgeInsets.only(left: _gap),
        child: _FadeIn(child: child),
      ),
    );
  }
}

/// Fades the card in on mount, so each open animates rather than snapping.
/// Collapses to an instant appearance under reduced motion via [CcMotion].
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _opaque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opaque = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opaque ? 1 : 0,
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      child: widget.child,
    );
  }
}
