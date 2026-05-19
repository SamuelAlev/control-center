@TestOn('vm')
library;

import 'package:cc_host/cc_host.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_tools_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_server_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Headless cycle guard for the in-process RPC server graph (the "composition
/// flip").
///
/// The desktop self-serves its data over an in-process [InProcessRpcHost]:
/// `rpcClientProvider` is the SOLE entrypoint the UI repository providers talk
/// to once they are flipped to the cc_data `RpcX` adapters. The flip is
/// acyclic ONLY because the server side of the graph — the
/// [remoteRpcCatalogProvider] ops and every tool in [mcpToolRegistryProvider]
/// (reached via [mcpToolDispatcherProvider]) — reads the dedicated server-side
/// `dao*` repository providers, NOT the public `xRepositoryProvider`s (which now
/// resolve to RpcX adapters that call back into `rpcClientProvider`).
///
/// If a flip accidentally points a server-side reader at a public (now-RPC)
/// provider, building the host recurses:
///   catalog/registry -> RpcX repo -> rpcClient -> host -> dispatcher/catalog ...
/// which Riverpod reports as a circular dependency (and ultimately a
/// StackOverflowError). This test builds the real provider graph against an
/// in-memory database and asserts the host resolves WITHOUT such an error,
/// proving the rpcClient graph is acyclic.
void main() {
  ProviderContainer buildContainer(AppDatabase db) {
    final container = ProviderContainer(
      overrides: [
        // The only platform dependency the server graph needs is the database.
        // `appPreferencesProvider`/`secureStoreProvider` already default to
        // in-memory fakes, so no further overrides are required for a headless
        // build.
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'rpcClientProvider resolves without a circular dependency (acyclic graph)',
    () {
      final container = buildContainer(db);

      // Build the in-process RPC client. A residual server-side reader pointing
      // at a flipped (RPC) public provider would recurse here and Riverpod would
      // throw a CircularDependencyError / StackOverflowError instead of
      // returning a client.
      late final RemoteRpcClient client;
      expect(
        () => client = container.read(inProcessRpcClientProvider),
        returnsNormally,
        reason:
            'rpcClientProvider must build without recursing back into itself; '
            'a server-side reader (catalog op or MCP tool) is pointing at a '
            'public RpcX provider instead of its dao* counterpart.',
      );
      expect(client, isNotNull);
    },
  );

  test(
    'the server-side data surface (catalog + dispatcher + tool registry) '
    'resolves headlessly',
    () {
      final container = buildContainer(db);

      // These are the two halves of the host\'s data surface. Reading them
      // directly (as well as via rpcClientProvider above) localizes a cycle to
      // whichever half introduced it.
      expect(
        () => container.read(remoteRpcCatalogProvider),
        returnsNormally,
      );

      late final McpToolDispatcher dispatcher;
      expect(
        () => dispatcher = container.read(mcpToolDispatcherProvider),
        returnsNormally,
      );
      expect(dispatcher, isNotNull);

      // The tool registry is the largest fan-out of server-side repository
      // reads, so resolving it is the strongest single acyclicity signal.
      expect(
        () => container.read(mcpToolRegistryProvider),
        returnsNormally,
      );
    },
  );
}
