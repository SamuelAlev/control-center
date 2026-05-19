import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The LIVE notification lane: a broadcast stream of every [AppNotification]
/// the mapper produces, published by `RecordingNotificationPort` BEFORE any
/// OS-level suppression (focus mode, quiet hours, on-route).
///
/// Ephemeral by design — nothing here is persisted or replayed. The ambient
/// banner rail listens to this lane so only genuinely-new arrivals can become
/// time-critical banners; the durable bell history is the server-side
/// notification feed, a separate lane entirely.
final liveNotificationLaneProvider = Provider<StreamController<AppNotification>>(
  (ref) {
    final controller = StreamController<AppNotification>.broadcast();
    ref.onDispose(controller.close);
    return controller;
  },
);
