import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the pointer rests on a space before its cheap reads are warmed
/// (editor layout, conversations, participants, thread rollups). Long enough
/// that sweeping down the sidebar warms nothing, short enough to beat a
/// deliberate click. A press warms everything at once regardless (see
/// [SpaceHoverPrefetch]), so a quick click never waits on this.
const Duration _kDwell = Duration(milliseconds: 200);

/// How long the pointer has to stay before the feed window is warmed too. The
/// feed is the expensive read (a 60-message window), so a hover that merely
/// pauses on a row on its way somewhere does not pay for it.
const Duration _kFeedDwell = Duration(milliseconds: 450);

/// How long warmed reads stay subscribed after the pointer leaves. Moving
/// back onto the row, or a press that lands just after the exit, finds them
/// still cached instead of refetching.
const Duration _kHold = Duration(seconds: 4);

/// Warms what opening [spaceId] waits on while the pointer rests on its row.
///
/// Opening a space the client has not held recently pays a chain of
/// round-trips: the editor layout, the standing conversation, then its feed.
/// Hover usually leads the click by a few hundred milliseconds, and a press
/// leads the route change by a frame or more. The listeners are released a
/// few seconds after the pointer leaves (or the space opens and its screen
/// takes over), so a pointer that moved on does not keep a revalidation
/// running.
class SpaceHoverPrefetch extends ConsumerStatefulWidget {
  /// Creates a [SpaceHoverPrefetch].
  const SpaceHoverPrefetch({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.child,
  });

  /// Workspace owning [spaceId]. Null warms nothing (the open space is
  /// already warm).
  final String? workspaceId;

  /// The space to warm.
  final String spaceId;

  /// The row.
  final Widget child;

  @override
  ConsumerState<SpaceHoverPrefetch> createState() => _SpaceHoverPrefetchState();
}

class _SpaceHoverPrefetchState extends ConsumerState<SpaceHoverPrefetch> {
  Timer? _dwell;
  Timer? _feedDwell;
  Timer? _release;
  ProviderSubscription<AsyncValue<String>>? _standing;
  final List<ProviderSubscription<Object?>> _warmed = [];

  /// The cheap reads are subscribed.
  var _warm = false;

  /// The feed window is wanted (long dwell or press); it is subscribed once
  /// the standing conversation resolves.
  var _feedWanted = false;
  var _feedWarm = false;

  @override
  void didUpdateWidget(SpaceHoverPrefetch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      _closeAll();
    } else if (oldWidget.workspaceId != widget.workspaceId) {
      _stopDwell();
      if (widget.workspaceId == null) {
        // The space just opened. Its screen subscribes the same reads a
        // frame or two later; holding ours across that handoff is what keeps
        // them from being disposed and refetched in between.
        _scheduleRelease();
      } else {
        _closeAll();
      }
    }
  }

  @override
  void dispose() {
    _closeAll();
    super.dispose();
  }

  void _onEnter() {
    _release?.cancel();
    _release = null;
    if (widget.workspaceId == null) {
      return;
    }
    if (!_warm) {
      _dwell?.cancel();
      _dwell = Timer(_kDwell, _warmReads);
    }
    if (!_feedWanted) {
      _feedDwell?.cancel();
      _feedDwell = Timer(_kFeedDwell, _wantFeed);
    }
  }

  void _onExit() {
    _stopDwell();
    _scheduleRelease();
  }

  /// A press is the strongest signal there is: warm everything now, so the
  /// card's conversation list and the feed are usually cached by the time
  /// the route change lands.
  void _onPointerDown() {
    _release?.cancel();
    _release = null;
    _stopDwell();
    _warmReads();
    _wantFeed();
  }

  void _stopDwell() {
    _dwell?.cancel();
    _dwell = null;
    _feedDwell?.cancel();
    _feedDwell = null;
  }

  void _scheduleRelease() {
    if (!_warm && _standing == null) {
      return;
    }
    _release?.cancel();
    _release = Timer(_kHold, _closeAll);
  }

  void _closeAll() {
    _stopDwell();
    _release?.cancel();
    _release = null;
    _standing?.close();
    _standing = null;
    for (final subscription in _warmed) {
      subscription.close();
    }
    _warmed.clear();
    _warm = false;
    _feedWanted = false;
    _feedWarm = false;
  }

  void _touch(ProviderSubscription<Object?> subscription) {
    _warmed.add(subscription);
  }

  void _warmReads() {
    final workspaceId = widget.workspaceId;
    if (!mounted || workspaceId == null || _warm) {
      return;
    }
    _warm = true;
    final spaceId = widget.spaceId;
    unawaited(
      ref
          .read(editorLayoutMemoProvider)
          .prefetch(
            ref.read(editorLayoutCacheRepositoryProvider),
            workspaceId,
            editorLayoutCacheKind,
            spaceId,
          ),
    );
    _touch(ref.listenManual(spaceConversationsProvider(spaceId), (_, _) {}));
    _touch(ref.listenManual(spaceParticipantsProvider(spaceId), (_, _) {}));
    _touch(ref.listenManual(spaceThreadSummariesProvider(spaceId), (_, _) {}));
    // The feed is keyed by the standing conversation, which is itself a
    // round-trip; stay subscribed until it resolves, then warm the feed if
    // it is wanted by then.
    final sub = ref.listenManual(
      standingConversationIdProvider(spaceId),
      (_, next) => _settleStanding(next),
    );
    _standing = sub;
    _settleStanding(sub.read());
  }

  void _wantFeed() {
    if (!mounted || widget.workspaceId == null) {
      return;
    }
    _feedWanted = true;
    final standing = _standing;
    if (standing != null) {
      _settleStanding(standing.read());
    }
  }

  void _settleStanding(AsyncValue<String> value) {
    if (!value.hasValue && !value.hasError) {
      return;
    }
    final id = value.value;
    if (!_feedWanted || _feedWarm || id == null || !mounted || !_warm) {
      return;
    }
    _feedWarm = true;
    _touch(
      ref.listenManual(
        spaceFeedWindowedProvider((
          spaceId: widget.spaceId,
          conversationId: id,
        )),
        (_, _) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onPointerDown(),
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: widget.child,
      ),
    );
  }
}
