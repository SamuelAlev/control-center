import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stale-while-revalidate for `autoDispose` providers behind surfaces that
/// unmount on a tab switch.
extension CacheFor on Ref {
  /// Keeps this provider's value for [ttl] after its last listener leaves,
  /// so coming back paints the held value instead of a spinner. A listener
  /// returning inside the window cancels the countdown; one leaving restarts
  /// it. The surface revalidates what it shows on mount, so the held value is
  /// a paint shortcut, never the final word.
  ///
  /// Call it at the top of the build, before any await: work the last
  /// listener abandons mid-flight is then released after [ttl] like a value.
  void cacheFor(Duration ttl) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() {
      timer?.cancel();
      timer = Timer(ttl, link.close);
    });
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}

/// The hold for a sidebar panel's reads: long enough that glancing at another
/// tab and back is free, short enough that a space left behind lets go.
const kPanelCacheTtl = Duration(minutes: 5);
