import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The project's own GitHub star count, as the demo server reports it.
///
/// One one-shot read behind the tour's "Star on GitHub" button: the SERVER
/// fetches and caches the number (the `demo.repoStars` op and its
/// `DemoRepoStats`), because a client — web or desktop — never dials
/// api.github.com itself. AutoDispose so the number is only worth a request
/// while the tour panel is on screen; the server-side cache makes a re-mount
/// cheap. Null while loading and on any failure: a marketing number never
/// earns a spinner or an error state, and the button simply renders without
/// its count.
final demoRepoStarsProvider = FutureProvider.autoDispose<int?>((ref) async {
  if (!ref.watch(isDemoServerProvider)) {
    return null;
  }
  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('demo.repoStars', const {});
    final stars = data['stars'];
    return stars is num ? stars.toInt() : null;
  } catch (_) {
    return null;
  }
});
