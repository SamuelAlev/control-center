// Desktop binding for the filter-list update operations behind
// `filterListUpdateProvider` in `newsfeed_providers.dart`.
//
// Delegates to the real `FilterListService` (which caches downloaded ad/cookie
// rule lists into the local app-support directory — desktop-only). This is a
// genuine client capability (a local cache for the in-app ad-blocking
// webview), so it lives here directly rather than in the (deleted)
// server-execution provider file — cc_infra only, never cc_server_core/
// cc_persistence.
library;

import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedicated dio for filter-list downloads (no auth interceptor — rule lists
/// are public).
final _filterListDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Downloads / caches the ad and cookie rule lists for the desktop in-app
/// ad-blocking webview.
final filterListServiceProvider = Provider<FilterListService>((ref) {
  return FilterListService(
    ref.watch(_filterListDioProvider),
    ref.watch(appPreferencesProvider),
    appCcPaths,
  );
});

/// Reads the persisted filter-list update state.
FilterListUpdateState readFilterListState(Ref ref) =>
    ref.watch(filterListServiceProvider).readState();

/// Performs an auto-update if one is due.
Future<FilterListUpdateState> autoUpdateFilterList(Ref ref) =>
    ref.read(filterListServiceProvider).autoUpdate();

/// Forces a full filter-list refresh.
Future<FilterListUpdateState> refreshFilterList(Ref ref) =>
    ref.read(filterListServiceProvider).manualRefresh();
