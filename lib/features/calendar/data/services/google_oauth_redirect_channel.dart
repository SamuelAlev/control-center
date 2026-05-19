import 'dart:async';

import 'package:control_center/core/errors/app_exceptions.dart';

/// App-scoped bus that carries the Google OAuth redirect deep link from the
/// platform's URL handler (registered once at startup) to the in-flight
/// `GoogleOAuthService.authenticate` call.
///
/// With a public iOS-type client the authorization code comes back as a
/// custom-scheme deep link (`com.googleusercontent.apps.<client>:/oauth2redirect?code=…&state=…`)
/// routed to the running app by the OS — not over a loopback
/// HTTP server the flow owns. So a single long-lived channel decouples the
/// startup deep-link handler (which can't know whether a flow is in progress)
/// from the transient flow (which subscribes for exactly one redirect).
///
/// The stream is a broadcast so [next] subscribes lazily per flow; redirects
/// emitted while nobody is awaiting are simply dropped (the flow always begins
/// from a running app, so there is always a listener by the time Google
/// redirects back).
class GoogleOAuthRedirectChannel {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  /// Publishes a received OAuth redirect [uri] to any awaiting flow.
  void emit(Uri uri) {
    if (!_controller.isClosed) {
      _controller.add(uri);
    }
  }

  /// Awaits the next redirect URI, or throws [GoogleOAuthException] of kind
  /// [GoogleOAuthFailureKind.timedOut] when none arrives within [timeout].
  ///
  /// Subscribes synchronously when called, so the caller can start awaiting
  /// before opening the browser and never miss a fast callback.
  Future<Uri> next(Duration timeout) {
    return _controller.stream.first.timeout(
      timeout,
      onTimeout: () => throw const GoogleOAuthException(
        'Timed out waiting for Google sign-in to complete.',
        kind: GoogleOAuthFailureKind.timedOut,
      ),
    );
  }

  /// Closes the underlying stream. Call from the owning provider's `onDispose`.
  void dispose() {
    _controller.close();
  }
}
