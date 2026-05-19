import 'package:flutter/foundation.dart';

/// Console tracing for the remote-control connection pipeline:
/// pairing → signaling → WebRTC (offer/answer/ICE) → PSK handshake → JSON-RPC.
///
/// Every call is gated on [kDebugMode], so the whole thing compiles out of
/// release builds. On web the output lands in the browser console (Chrome
/// DevTools → Console), prefixed with `[cc_remote]`, a wall-clock timestamp, and
/// a `stage` tag. Filter the console by `cc_remote` to watch a connection
/// attempt step through the pipeline and see exactly where it stalls or throws —
/// the UI only ever says "couldn't connect", this says why.
void rlog(String stage, String message, {Object? error, StackTrace? stack}) {
  if (!kDebugMode) {
    return;
  }
  final now = DateTime.now();
  final ts =
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}';
  final suffix = error != null ? '  ✗ ${error.runtimeType}: $error' : '';
  // ignore: avoid_print
  print('[cc_remote $ts] $stage — $message$suffix');
  if (stack != null) {
    // ignore: avoid_print
    print(stack);
  }
}
