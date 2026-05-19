// Desktop (thin-client) binding for the analytics-snapshot aggregator keepalive.
//
// The snapshot aggregator rolls daily analytics up from the database, which the
// connected `cc_server` owns — it runs server-side. The thin client has no local
// aggregator to keep alive, so this is a no-op (the analytics screen reads the
// rolled-up snapshots over RPC), exactly like the web client.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No-op: snapshot aggregation runs on the server that owns the database.
void keepAnalyticsSnapshotAlive(WidgetRef ref) {}
