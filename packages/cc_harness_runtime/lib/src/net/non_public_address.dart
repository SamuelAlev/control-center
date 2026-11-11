import 'dart:io';
import 'dart:typed_data';

/// Whether [address] is anything but a globally reachable unicast address:
/// every IANA special-purpose range not marked globally reachable, plus
/// multicast and reserved space, and any IPv6 form that embeds an IPv4
/// address judged by the IPv4 rules (mapped, compatible, NAT64, 6to4).
///
/// The one rule for every server-side fetch of a URL somebody else chose:
/// the media and font proxy, the Connect origin check, agent web fetch and
/// web push.
///
/// IPv4 refused: 0/8, 10/8, 100.64/10, 127/8, 169.254/16, 172.16/12,
/// 192.0.0/24, 192.0.2/24, 192.88.99/24, 192.168/16, 198.18/15,
/// 198.51.100/24, 203.0.113/24, 224/4 and 240/4 (which holds the broadcast
/// address).
///
/// IPv6 passes only inside global unicast 2000::/3, and not in 2001::/23
/// (protocol assignments, Teredo among them), 2001:db8::/32 or 3fff::/20
/// (documentation). Everything else is refused: `::`, `::1`, fc00::/7,
/// fe80::/10, fec0::/10, ff00::/8, 100::/64, 64:ff9b:1::/48 and the rest.
/// `::ffff:a.b.c.d`, `::a.b.c.d`, 64:ff9b::/96 and 2002::/16 carry an IPv4
/// address and are judged by it.
bool isNonPublicAddress(InternetAddress address) {
  final b = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return _nonPublicV4(b);
  }
  if (address.type != InternetAddressType.IPv6 || b.length != 16) {
    return true;
  }
  bool zero(int from, int to) {
    for (var i = from; i < to; i++) {
      if (b[i] != 0) {
        return false;
      }
    }
    return true;
  }

  // ::ffff:a.b.c.d (mapped) and ::a.b.c.d (compatible; `::` and `::1` fall
  // in 0/8 and are refused by the IPv4 rule).
  if (zero(0, 10) && b[10] == 0xff && b[11] == 0xff) {
    return _nonPublicV4(b.sublist(12));
  }
  if (zero(0, 12)) {
    return true;
  }
  // NAT64 well-known prefix 64:ff9b::/96.
  if (b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xff && b[3] == 0x9b) {
    return !zero(4, 12) || _nonPublicV4(b.sublist(12));
  }
  // Global unicast is 2000::/3; anything outside it is not public.
  if ((b[0] & 0xe0) != 0x20) {
    return true;
  }
  // 6to4 2002:a.b.c.d::/48.
  if (b[0] == 0x20 && b[1] == 0x02) {
    return _nonPublicV4(b.sublist(2, 6));
  }
  // 2001::/23, which holds 2001:db8::/32 as well.
  if (b[0] == 0x20 && b[1] == 0x01 && b[2] < 0x02) {
    return true;
  }
  if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) {
    return true;
  }
  // 3fff::/20.
  if (b[0] == 0x3f && b[1] == 0xff && b[2] < 0x10) {
    return true;
  }
  return false;
}

bool _nonPublicV4(List<int> v4) {
  final [a, b, c, _] = Uint8List.fromList(v4);
  return a == 0 ||
      a == 10 ||
      (a == 100 && b >= 64 && b <= 127) ||
      a == 127 ||
      (a == 169 && b == 254) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 0 && (c == 0 || c == 2)) ||
      (a == 192 && b == 88 && c == 99) ||
      (a == 192 && b == 168) ||
      (a == 198 && (b == 18 || b == 19)) ||
      (a == 198 && b == 51 && c == 100) ||
      (a == 203 && b == 0 && c == 113) ||
      a >= 224;
}
