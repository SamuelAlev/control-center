import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:rhttp/rhttp.dart';

/// A 30-second connection deadline with no total transfer deadline.
///
/// Large model downloads can take minutes. [downloadToFile] limits inactivity
/// between chunks so a progressing download can finish while a stalled one
/// fails promptly.
const ClientSettings modelDownloadClientSettings = ClientSettings(
  timeoutSettings: TimeoutSettings(connectTimeout: Duration(seconds: 30)),
);

/// Streams the body of an HTTP GET for [url] straight to [destination] through
/// [client], so a multi-hundred-megabyte model never has to fit in memory.
///
/// The destination is created (or truncated — never appended) up front and
/// written chunk by chunk as they arrive; [onReceiveProgress] reports the
/// running `(received, total)` byte count (`total` is `-1` when the server
/// omits `Content-Length`).
///
/// If the server stalls for [idleTimeout] before the response headers or between
/// body chunks, the native request is cancelled and the download fails with
/// [RhttpTimeoutException]. Any failure (a non-2xx status, a
/// connection drop, an idle timeout or a cancellation through [cancelToken])
/// propagates to the caller after the file handle is released, leaving whatever
/// was written for the caller to discard.
Future<void> downloadToFile(
  RhttpClient client,
  String url,
  String destination, {
  CancelToken? cancelToken,
  ProgressCallback? onReceiveProgress,
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  // Honour a caller-supplied token as-is (their cancel must still work); only
  // mint our own when there is none, so a timeout has something to cancel.
  final token = cancelToken ?? CancelToken();

  // Bound the wait for response headers. rhttp has no read timeout, so without
  // this a server that completes the handshake then never answers would hang
  // the install forever.
  var headersTimedOut = false;
  final response = await client
      .request(
        method: HttpMethod.get,
        url: url,
        expectBody: HttpExpectBody.stream,
        cancelToken: token,
        onReceiveProgress: onReceiveProgress,
      )
      .then((raw) async {
        final response = raw as HttpStreamResponse;
        if (headersTimedOut) {
          // Headers can beat native cancellation after our deadline expired.
          // The discarded response still owns a stream and a receive port.
          await response.body.drain<void>();
          throw RhttpTimeoutException(response.request);
        }
        return response;
      })
      .timeout(
        idleTimeout,
        onTimeout: () {
          headersTimedOut = true;
          unawaited(token.cancel());
          throw RhttpTimeoutException(HttpRequest(url: url));
        },
      );

  final sink = File(destination).openWrite();
  try {
    await sink.addStream(
      _withReceiveIdleDeadline(
        response.body,
        idleTimeout,
        response.request,
        () => unawaited(token.cancel()),
      ),
    );
  } catch (_) {
    // Close before the caller removes a partial file, including on Windows.
    // A close error must not mask the transfer failure.
    try {
      await sink.close();
    } catch (_) {}
    rethrow;
  }
  await sink.close();
}

/// Applies a receive-idle deadline while preserving downstream backpressure.
Stream<Uint8List> _withReceiveIdleDeadline(
  Stream<Uint8List> source,
  Duration idleTimeout,
  HttpRequest request,
  void Function() onIdle,
) async* {
  final reader = StreamIterator(source);
  var failed = false;
  try {
    while (await reader.moveNext().timeout(
      idleTimeout,
      onTimeout: () {
        onIdle();
        throw RhttpTimeoutException(request);
      },
    )) {
      yield reader.current;
    }
  } catch (_) {
    failed = true;
    rethrow;
  } finally {
    try {
      await reader.cancel();
    } catch (_) {
      // Aborting Rust's stream can fail its Dart cancellation future too.
      // Preserve the transfer error (notably the receive-idle timeout).
      if (!failed) {
        rethrow;
      }
    }
  }
}
