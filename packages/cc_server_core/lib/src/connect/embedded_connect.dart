import 'dart:io';

/// A Control Center Connect served by this server under `/connect`.
///
/// The service itself lives in `apps/cc_connect`; the `cc_server` binary
/// adapts it to this interface when the operator sets
/// `CC_SERVER_CONNECT_HOST=on`. It is routed before session and CORS
/// handling, reads only its own `CONNECT_*` credentials, and is closed by
/// default: without `CONNECT_ALLOWED_INSTALLS` and an HTTPS (or loopback)
/// public URL it does not start.
abstract interface class EmbeddedConnect {
  /// Whether [path] belongs to the mount.
  bool ownsPath(String path);

  /// Serves one request. Never throws.
  Future<void> handle(HttpRequest request);

  /// Stops background work.
  Future<void> close();
}

/// Builds the embedded Connect for this boot, or returns null when it is off.
/// [publicUrl] is this server's configured public URL; [environment] is the
/// boot environment (`.env` layered under the process environment).
typedef EmbeddedConnectFactory =
    Future<EmbeddedConnect?> Function({
      required Map<String, String> environment,
      required String publicUrl,
    });

/// The switch that turns the embedded Connect on.
const String embeddedConnectEnvironmentKey = 'CC_SERVER_CONNECT_HOST';
