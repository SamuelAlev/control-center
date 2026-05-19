// Web binding for the filter-list update operations behind
// `filterListUpdateProvider` in `newsfeed_providers.dart`.
//
// Filter-list rules drive the desktop in-app ad-blocking WEBVIEW (a desktop-only
// surface) and are cached into the local app-support directory. A web thin
// client has neither, so the update operations are honest no-ops returning an
// empty (no-rules) state. The newsfeed settings screen still renders; it just
// shows zero managed rules on web.
library;

import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const FilterListUpdateState _empty = FilterListUpdateState(
  isUpdating: false,
  errors: [],
  cookieHidingRules: 0,
  adHidingRules: 0,
  networkBlockRules: 0,
  removeParamsCount: 0,
);

/// Empty state: the filter-list cache is desktop-only.
FilterListUpdateState readFilterListState(Ref ref) => _empty;

/// No-op on web: there is no local filter-list cache to update.
Future<FilterListUpdateState> autoUpdateFilterList(Ref ref) async => _empty;

/// No-op on web: there is no local filter-list cache to refresh.
Future<FilterListUpdateState> refreshFilterList(Ref ref) async => _empty;
