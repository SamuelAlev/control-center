import 'dart:io';

/// Whether [uri] points at an address the media proxy must refuse: loopback,
/// link-local (incl. 169.254.169.254), `metadata.google.internal`, or
/// RFC-1918 / IPv6 unique-local ranges. IP literals checked directly; bare
/// `localhost` refused by name. Re-run on every redirect hop so a signed URL
/// cannot 3xx to an internal address.
///
/// A bare hostname returns `false` — pair with [resolvesToBlockedAddress],
/// which resolves and applies the same rules to every answer.
bool isBlockedProxyTarget(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return true;
  }
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host == 'metadata.google.internal') {
    return true;
  }
  final addr = InternetAddress.tryParse(host);
  if (addr == null) {
    return false; // A hostname; the PSK signature is the trust boundary.
  }
  if (addr.isLoopback || addr.isLinkLocal || addr.isMulticast) {
    return true;
  }
  final raw = addr.rawAddress;
  if (addr.type == InternetAddressType.IPv4) {
    final a = raw[0];
    final b = raw[1];
    if (a == 0 || a == 10 || a == 127) {
      return true;
    }
    if (a == 172 && b >= 16 && b <= 31) {
      return true;
    }
    if (a == 192 && b == 168) {
      return true;
    }
    return false;
  }
  // IPv6 unique-local (fc00::/7) or unspecified (::). Loopback (::1) and
  // link-local (fe80::/10) are already caught by the isLoopback/isLinkLocal
  // check above. IPv4-mapped (::ffff:a.b.c.d) smuggles a private IPv4
  // literal past the IPv4 branch, so re-check its embedded v4 (defense-in-
  // depth behind the PSK signature).
  if (raw[0] == 0xfc || raw[0] == 0xfd || addr.address == '::') {
    return true;
  }
  if (raw.length >= 16 && raw[10] == 0xff && raw[11] == 0xff) {
    final a = raw[12];
    final b = raw[13];
    if (a == 0 ||
        a == 10 ||
        a == 127 ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168)) {
      return true;
    }
  }
  return false;
}

/// Whether [uri]'s host resolves to a media-proxy-blocked address.
///
/// [isBlockedProxyTarget] only judges IP literals; hostnames need resolution
/// (DNS rebinding to private IPs). Resolution failure is BLOCKED. Callers
/// re-check every redirect hop.
///
/// Residual: connects by name, so a resolver that answers differently between
/// check and connect can still slip; full close needs connect-by-IP with
/// preserved Host/SNI.
Future<bool> resolvesToBlockedAddress(Uri uri) async {
  final host = uri.host;
  if (host.isEmpty || InternetAddress.tryParse(host) != null) {
    return false; // Literals were already judged synchronously.
  }
  try {
    final addresses = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 5));
    if (addresses.isEmpty) {
      return true;
    }
    return addresses.any(
      (a) => isBlockedProxyTarget(Uri(scheme: uri.scheme, host: a.address)),
    );
  } on Object {
    return true;
  }
}
