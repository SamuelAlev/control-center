// The connected server's bulk-content lane, reachable outside the widget tree.
//
// `MediaProxyScope` publishes the same config to widgets, and that is the right
// shape for rendering: an image knows its BuildContext. Uploading does not —
// the composer's send path is a Riverpod notifier, and so is the queue that
// flushes messages parked behind workspace provisioning. Both need to POST a
// picture to the host, and neither has a context to look one up from.
library;

import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The active connection's media/bulk proxy, or null when the connection could
/// not be expressed as one (a relay-only path with no HTTP origin).
///
/// Overridden where the session container is built, beside the RPC client it
/// belongs with. The default is null so a test container — or a surface with no
/// server — simply has no upload lane rather than a missing-override crash.
final mediaProxyConfigProvider = Provider<MediaProxyConfig?>((ref) => null);
