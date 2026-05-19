import 'package:cc_rpc/src/client/remote_channel_auth.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';
import 'package:cc_rpc/src/resolver/reachability_resolver.dart';

/// Why a connection attempt failed, distilled for presentation.
///
/// This is deliberately a *classifier*, not a message factory: copy belongs
/// to each surface (the app localizes it, `cc_remote` hardcodes its own), so
/// this enum is the single source of truth for "what went wrong" only.
enum ConnectionFailureKind {
  /// No descriptor path could be reached — server down, wrong network, or
  /// the relay probe failed.
  unreachable,

  /// The server presented an identity that doesn't match the pinned
  /// fingerprint — a rebind/MITM signal, or a reinstalled server.
  identityMismatch,

  /// The server refused the device credential (bad pairing key, unpaired
  /// device id, PSK proof mismatch).
  authRejected,

  /// Anything else. Surfaces show generic copy and keep the raw error
  /// reachable behind a "technical details" affordance.
  unknown,
}

/// Classifies a connection error into a [ConnectionFailureKind].
///
/// Accepts the raw exception or its string form — supervisor statuses carry
/// the reason as a string, so the well-known type names are recognized in
/// text too.
ConnectionFailureKind classifyConnectionError(Object error) {
  if (error is NoReachablePathException) {
    return ConnectionFailureKind.unreachable;
  }
  if (error is ServerIdentityMismatchException) {
    return ConnectionFailureKind.identityMismatch;
  }
  if (error is AuthRejectedException) {
    return ConnectionFailureKind.authRejected;
  }
  // Supervisor statuses and wrappers carry the reason as text (e.g.
  // `Exception('connect failed: NoReachablePathException: …')`), so match
  // the well-known markers in the string form too.
  final text = error.toString();
  if (text.contains('NoReachablePathException')) {
    return ConnectionFailureKind.unreachable;
  }
  if (text.contains('ServerIdentityMismatchException')) {
    return ConnectionFailureKind.identityMismatch;
  }
  if (text.contains('Server rejected the device') ||
      text.contains('Server auth proof mismatch')) {
    return ConnectionFailureKind.authRejected;
  }
  return ConnectionFailureKind.unknown;
}
