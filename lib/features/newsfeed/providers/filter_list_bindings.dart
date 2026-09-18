import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_domain/features/newsfeed/domain/ports/filter_list_port.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host-cached ABP filter lists. Desktop and web share this RPC adapter —
/// neither dials EasyList / uBlock directly.
final filterListPortProvider = Provider<FilterListPort>(
  (ref) => RpcFilterListPort(ref.watch(rpcClientProvider)),
);

/// Reads the persisted filter-list update state (empty until the first RPC).
FilterListUpdateState readFilterListState(Ref ref) =>
    FilterListUpdateState.empty;

/// Performs an auto-update if one is due (host-side 24h cooldown).
Future<FilterListUpdateState> autoUpdateFilterList(Ref ref) =>
    ref.read(filterListPortProvider).refresh(force: false);

/// Forces a full filter-list refresh on the host.
Future<FilterListUpdateState> refreshFilterList(Ref ref) =>
    ref.read(filterListPortProvider).refresh(force: true);
