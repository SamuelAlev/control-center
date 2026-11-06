import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/shared/editor/host/editor_layout_memo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the SERVER-backed [CacheRepository] used to persist + restore
/// editor layouts. The server stores each layout per person, so the tab
/// someone last had open follows them across their devices.
final editorLayoutCacheRepositoryProvider = Provider<CacheRepository>(
  (ref) => RpcCacheRepository(ref.watch(rpcClientProvider)),
);

/// The in-process copy of editor layouts, shared by every host for the life
/// of the app, so a context switch restores its layout without a round-trip.
/// See [EditorLayoutMemo].
final editorLayoutMemoProvider = Provider<EditorLayoutMemo>(
  (ref) => EditorLayoutMemo(),
);
