import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the pointer rests on a space before it is warmed. Long enough
/// that sweeping down the sidebar warms nothing, short enough to beat the
/// click that usually follows.
const Duration _kDwell = Duration(milliseconds: 60);

/// Warms what opening [spaceId] waits on while the pointer rests on its row.
///
/// Opening a space the client has not held recently pays a chain of
/// round-trips: the editor layout, the standing conversation, then its feed.
/// Hover usually leads the click by a few hundred milliseconds, which is
/// most of that chain. Each warmed provider holds itself briefly after its
/// last listener (see `_holdAfterLastListener` in messaging_providers), so
/// the listen here is opened and closed at once and the click finds the
/// data in memory.
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
  ProviderSubscription<AsyncValue<String>>? _standing;

  @override
  void dispose() {
    _dwell?.cancel();
    _standing?.close();
    super.dispose();
  }

  void _onEnter() {
    _dwell?.cancel();
    _dwell = Timer(_kDwell, _warm);
  }

  void _onExit() {
    _dwell?.cancel();
  }

  /// Drops a listen opened only to start the provider; its own hold keeps it
  /// for the click.
  void _touch(ProviderSubscription<Object?> subscription) {
    subscription.close();
  }

  void _warm() {
    final workspaceId = widget.workspaceId;
    if (!mounted || workspaceId == null) {
      return;
    }
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
    if (_standing != null) {
      return;
    }
    // The feed is keyed by the standing conversation, which is itself a
    // round-trip; stay subscribed until it resolves, then warm the feed.
    void settle(AsyncValue<String> value) {
      if (!value.hasValue && !value.hasError) {
        return;
      }
      _standing?.close();
      _standing = null;
      final id = value.value;
      if (id != null && mounted) {
        _touch(
          ref.listenManual(
            spaceFeedWindowedProvider((spaceId: spaceId, conversationId: id)),
            (_, _) {},
          ),
        );
      }
    }

    final sub = ref.listenManual(
      standingConversationIdProvider(spaceId),
      (_, next) => settle(next),
    );
    _standing = sub;
    settle(sub.read());
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: widget.child,
    );
  }
}
