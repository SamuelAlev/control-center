/// The TLS-or-loopback invariant (PRD 15 §"Design tenets"), as one enforced
/// chokepoint: **no plaintext ever leaves the box**.
///
/// Every dial site — WS RPC connects, health probes, signaling brokers,
/// media/bulk fetches — routes its target URI through
/// `TransportSecurityPolicy.enforce` before any bytes flow. `wss`/`https` are
/// always allowed; `ws`/`http` only to loopback hosts; anything else requires
/// the explicit `--insecure` escape hatch (`insecureAllowed`), which the UI
/// flags loudly.
library;

/// Thrown when a plaintext transport would leave the machine without the
/// explicit insecure override.
class InsecureTransportException implements Exception {
  /// Creates an [InsecureTransportException] for [uri].
  const InsecureTransportException(this.uri);

  /// The refused target.
  final Uri uri;

  @override
  String toString() =>
      'InsecureTransportException: refusing plaintext transport to '
      '"$uri" — only wss/https may leave this machine. Use TLS, or start the '
      'server with --insecure to override (loudly flagged).';
}

/// Static policy: which transport targets are secure enough to dial.
final class TransportSecurityPolicy {
  TransportSecurityPolicy._();

  /// Whether [host] names this machine (plaintext to loopback is fine —
  /// it never crosses a network).
  static bool isLoopbackHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'localhost' ||
        lower == '127.0.0.1' ||
        lower == '::1' ||
        lower == '[::1]' ||
        lower.startsWith('127.');
  }

  /// Whether [host] names a tailnet node: a MagicDNS `*.ts.net` name or an
  /// IPv4 address in the Tailscale CGNAT range (100.64.0.0/10). Such hosts
  /// classify as a `TailnetPath` (not a generic `wss`/LAN path) so the
  /// reachability resolver orders them correctly.
  static bool isTailnetHost(String host) {
    final lower = host.toLowerCase();
    if (lower.endsWith('.ts.net')) {
      return true;
    }
    final parts = lower.split('.');
    if (parts.length != 4) {
      return false;
    }
    final octets = parts.map(int.tryParse).toList(growable: false);
    if (octets.any((o) => o == null || o < 0 || o > 255)) {
      return false;
    }
    final second = octets[1]!;
    return octets[0] == 100 && second >= 64 && second < 128;
  }

  /// Whether dialing [uri] complies with the TLS-or-loopback invariant.
  ///
  /// `wss`/`https` → always. `ws`/`http` → loopback only, unless
  /// [insecureAllowed] (the server's `--insecure` flag carried in its
  /// descriptor). Unknown schemes are refused.
  static bool allows(Uri uri, {bool insecureAllowed = false}) {
    switch (uri.scheme) {
      case 'wss':
      case 'https':
        return true;
      case 'ws':
      case 'http':
        return isLoopbackHost(uri.host) || insecureAllowed;
      default:
        return false;
    }
  }

  /// Throws [InsecureTransportException] when [allows] is false.
  static void enforce(Uri uri, {bool insecureAllowed = false}) {
    if (!allows(uri, insecureAllowed: insecureAllowed)) {
      throw InsecureTransportException(uri);
    }
  }
}
