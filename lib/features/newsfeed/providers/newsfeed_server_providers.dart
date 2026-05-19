// VM-only newsfeed providers (server-side execution half of
// `newsfeed_providers.dart`).
//
// The Dao-backed newsfeed repository (cc_server_core, backing the RPC catalog +
// newsfeed MCP tools) and the ad/cookie filter-list service (which caches
// downloaded rule lists into the local app-support directory via path_provider,
// for the desktop in-app ad-blocking webview) are desktop/server-only. They
// live here, imported by the desktop bootstrap, the MCP/catalog server
// surfaces, the webview, and the newsfeed seam — never from the web graph. The
// web-safe newsfeed UI providers (RPC reads + grid/search/view UI state) stay
// in `newsfeed_providers.dart`.
library;

import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_infra/src/newsfeed/filter_list_service.dart';
import 'package:cc_infra/src/newsfeed/rss_fetcher_service.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedicated dio for RSS fetching (no auth interceptor — feeds are public).
final newsfeedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Provider for the RSS fetcher service.
final rssFetcherServiceProvider = Provider<RssFetcherService>((ref) {
  return RssFetcherService(ref.watch(newsfeedDioProvider));
});

/// Server-side Drift [NewsfeedRepository] backing the RPC catalog + the
/// newsfeed MCP tools. Keeps the RSS fetcher so server-side refresh works (the
/// RPC adapter only forwards ops).
final daoNewsfeedRepositoryProvider = Provider<NewsfeedRepository>((ref) {
  return DaoNewsfeedRepository(
    ref.watch(rssDaoProvider),
    ref.watch(rssFetcherServiceProvider),
  );
});

/// Provider for the filter-list download / cache service (desktop ad-blocking).
final filterListServiceProvider = Provider<FilterListService>((ref) {
  return FilterListService(
    ref.watch(newsfeedDioProvider),
    ref.watch(appPreferencesProvider),
    appCcPaths,
  );
});
