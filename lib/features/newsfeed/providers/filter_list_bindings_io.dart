// Desktop binding for the filter-list update operations behind
// `filterListUpdateProvider` in `newsfeed_providers.dart`.
//
// Delegates to the real `FilterListService` (which caches downloaded ad/cookie
// rule lists into the local app-support directory — desktop-only).
library;

import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_server_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads the persisted filter-list update state.
FilterListUpdateState readFilterListState(Ref ref) =>
    ref.watch(filterListServiceProvider).readState();

/// Performs an auto-update if one is due.
Future<FilterListUpdateState> autoUpdateFilterList(Ref ref) =>
    ref.read(filterListServiceProvider).autoUpdate();

/// Forces a full filter-list refresh.
Future<FilterListUpdateState> refreshFilterList(Ref ref) =>
    ref.read(filterListServiceProvider).manualRefresh();
