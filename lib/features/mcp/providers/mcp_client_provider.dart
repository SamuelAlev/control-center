import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/mcp/data/secure_oauth_token_store.dart';
import 'package:control_center/features/mcp/providers/mcp_tools_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The in-process MCP CLIENT service for the desktop's reference background
/// stack (`_startBackgroundServices` / the in-process RPC host).
///
/// NOTE: the LIVE desktop + web both run as thin clients of a spawned
/// `cc_server`, which owns the real external-MCP client subsystem (it
/// auto-discovers and connects external servers in `cc_server_runtime`, and
/// exposes them over the `mcp.client.*` RPC ops the settings UI drives). This
/// provider only backs the kept-for-reference in-process host; it is never
/// reached from the web compilation graph (it imports `cc_mcp_client`, which is
/// `dart:io`-based, so it MUST stay behind the `bootstrap_io` seam). The
/// settings UI uses `mcp_external_provider.dart` (RPC, web-safe) instead.
final mcpClientServiceProvider = Provider<McpClientService>((ref) {
  ref.keepAlive();
  final registry = ref.watch(mcpToolRegistryProvider);
  final secure = ref.watch(secureStoreProvider);
  final service = McpClientService(
    registry: registry,
    tokenStore: SecureOAuthTokenStore(secure),
    launchBrowser: (url) async => openExternalUrl(url.toString()),
    log: (level, message, {Object? error}) =>
        AppLog.i('MCP-CLIENT', '[$level] $message'),
    onNeedsAuth: (config) =>
        AppLog.i('MCP-CLIENT', 'server "${config.name}" needs authorization'),
  );
  ref.onDispose(service.shutdown);
  return service;
});
