import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Newest messages a freshly opened thread subscribes to. Older pages grow
/// the window; the cap stops a fling through a huge thread from shipping it.
const int kRemoteFeedInitialWindow = 60;

/// Older messages revealed each time the reader reaches the top.
const int kRemoteFeedWindowStep = 60;

/// Upper bound on [remoteFeedWindowProvider].
const int kRemoteFeedMaxWindow = 2000;

/// Per-space feed window. Auto-disposed with the screen, so leaving a thread
/// drops a grown window instead of re-subscribing to it on the next open.
class RemoteFeedWindow extends Notifier<int> {
  /// Creates a window for [spaceId].
  RemoteFeedWindow(this.spaceId);

  /// The space this window belongs to.
  final String spaceId;

  @override
  int build() => kRemoteFeedInitialWindow;

  /// Reveals one older page, up to [kRemoteFeedMaxWindow].
  void loadMore() {
    if (state >= kRemoteFeedMaxWindow) {
      return;
    }
    state = (state + kRemoteFeedWindowStep).clamp(
      kRemoteFeedInitialWindow,
      kRemoteFeedMaxWindow,
    );
  }
}

/// Provides [RemoteFeedWindow] for one space.
final remoteFeedWindowProvider =
    NotifierProvider.autoDispose.family<RemoteFeedWindow, int, String>(
      RemoteFeedWindow.new,
    );
