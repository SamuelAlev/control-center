// Web binding for the analytics-snapshot aggregator keepalive.
//
// The snapshot aggregator rolls up analytics from the LOCAL database, which a
// web thin client does not have, so there is nothing to keep alive — this is a
// no-op. (The analytics screen renders from RPC/stub repos; aggregation is
// owned by the server.)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No local analytics aggregator on web — nothing to keep alive.
void keepAnalyticsSnapshotAlive(WidgetRef ref) {}
