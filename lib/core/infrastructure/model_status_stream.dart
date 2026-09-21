// Shared live stream for the three on-device-model settings cards
// (voice / embedding / diarization).
library;

import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Live model-status stream the settings cards watch.
/// A server without the ops (`opUnknown`) degrades to `null` so the card can render the
/// "managed on the server host" placeholder instead of spinning forever.
/// The seed is load-bearing: `models.watch*` can emit its only snapshot in the same burst
/// as the `sub/subscribe` ack, and a client that has not yet registered the subscription id
/// drops that emission.
Stream<ModelStatusSnapshot?> modelStatusStream(ModelControl control) {
  late final StreamController<ModelStatusSnapshot?> controller;
  StreamSubscription<ModelStatusSnapshot>? sub;
  var cancelled = false;
  controller = StreamController<ModelStatusSnapshot?>(
    onListen: () async {
      try {
        final seed = await control.status();
        if (cancelled || controller.isClosed) {
          return;
        }
        controller.add(seed);
        sub = control.watch().listen(
          (snapshot) {
            if (!controller.isClosed) {
              controller.add(snapshot);
            }
          },
          onError: (Object e, StackTrace st) {
            _forwardError(controller, e, st);
          },
          onDone: () {
            if (!controller.isClosed) {
              unawaited(controller.close());
            }
          },
        );
      } on Object catch (e, st) {
        if (cancelled || controller.isClosed) {
          return;
        }
        _forwardError(controller, e, st);
      }
    },
    onCancel: () async {
      cancelled = true;
      await sub?.cancel();
    },
  );
  return controller.stream;
}

void _forwardError(
  StreamController<ModelStatusSnapshot?> controller,
  Object e,
  StackTrace st,
) {
  if (controller.isClosed) {
    return;
  }
  if (e is RemoteRpcException && e.code == RpcErrorCodes.opUnknown) {
    controller.add(null);
    unawaited(controller.close());
    return;
  }
  controller.addError(e, st);
  unawaited(controller.close());
}
