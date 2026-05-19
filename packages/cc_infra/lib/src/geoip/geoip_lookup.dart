import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/geoip/geoip_country_data.dart' as data;

/// Offline IP → ISO 3166-1 alpha-2 country resolution, backed by the embedded
/// RIR delegation table in `geoip_country_data.dart` (regenerated from the
/// five registry stats files by `tool/gen_geoip_country.dart` — run it and
/// commit both).
///
/// Fully synchronous and allocation-light: the gzip+base64 blob is decoded
/// lazily on the FIRST lookup (never on a boot path) and cached for the
/// process. No network, no database, no I/O beyond the one decode.
///
/// Returns the UPPERCASE two-letter code, or null for private / loopback /
/// reserved / unparseable input — the audit trail stores null for those.
class GeoIpLookup {
  /// Creates a [GeoIpLookup]. The embedded table is decoded lazily on the
  /// first [countryCodeFor], so constructing one on a hot path is free.
  GeoIpLookup();

  _GeoIpTable? _table;

  /// Resolves [ipLiteral] (a dotted IPv4 or textual IPv6 literal, never a
  /// hostname) to its ISO 3166-1 alpha-2 country code (uppercase), or null
  /// for private/loopback/reserved/unknown/unparseable input.
  String? countryCodeFor(String ipLiteral) {
    final bytes = _parseIp(ipLiteral);
    if (bytes == null) {
      return null;
    }
    final table = _table ??= _GeoIpTable.decode();
    if (bytes.length == 4) {
      final ip = ByteData.sublistView(bytes).getUint32(0);
      if (_isNonPublicV4(ip)) {
        return null;
      }
      return table.lookupV4(ip);
    }
    if (_isNonPublicV6(bytes)) {
      return null;
    }
    return table.lookupV6(bytes);
  }

  /// Parses an IPv4/IPv6 literal to its raw bytes, or null on any parse
  /// failure (garbage strings, hostnames, partial octets). A zone id
  /// (`fe80::1%eth0`) is stripped — the address, not the interface, is looked
  /// up.
  static Uint8List? _parseIp(String literal) {
    var candidate = literal.trim();
    if (candidate.isEmpty) {
      return null;
    }
    final zone = candidate.indexOf('%');
    if (zone >= 0) {
      candidate = candidate.substring(0, zone);
    }
    try {
      return InternetAddress(candidate).rawAddress;
    } on ArgumentError {
      return null;
    }
  }

  /// IPv4 ranges that never map to a country: loopback, RFC 1918 private,
  /// link-local, CGNAT, benchmarking, documentation, multicast and the
  /// "this network"/reserved blocks. These are never delegated in the RIR
  /// stats (so the binary search would already miss them), but the explicit
  /// gate documents intent and guards against a malformed table.
  static bool _isNonPublicV4(int ip) {
    final a = ip >>> 24;
    if (a == 0 || a == 10 || a == 127 || a >= 224) {
      // 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, multicast (224/4) + reserved (240/4).
      return true;
    }
    final b = (ip >>> 16) & 0xff;
    if (a == 169 && b == 254) {
      return true; // 169.254.0.0/16 link-local
    }
    if (a == 172 && (b >= 16 && b <= 31)) {
      return true; // 172.16.0.0/12
    }
    if (a == 192 && b == 168) {
      return true; // 192.168.0.0/16
    }
    if (a == 100 && (b >= 64 && b <= 127)) {
      return true; // 100.64.0.0/10 CGNAT
    }
    if (a == 198 && (b == 18 || b == 19)) {
      return true; // 198.18.0.0/15 benchmarking
    }
    // Documentation prefixes: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24.
    final c = (ip >>> 8) & 0xff;
    if (a == 192 && b == 0 && c == 2) {
      return true;
    }
    if (a == 198 && b == 51 && c == 100) {
      return true;
    }
    if (a == 203 && b == 0 && c == 113) {
      return true;
    }
    return false;
  }

  /// IPv6 ranges that never map to a country: unspecified (::), loopback
  /// (::1), unique-local (fc00::/7), link-local (fe80::/10), multicast
  /// (ff00::/8) and documentation (2001:db8::/32).
  static bool _isNonPublicV6(Uint8List b) {
    final first = b[0];
    if (first == 0xff) {
      return true; // ff00::/8 multicast
    }
    if (first == 0xfe && (b[1] & 0xc0) == 0x80) {
      return true; // fe80::/10 link-local
    }
    if ((first & 0xfe) == 0xfc) {
      return true; // fc00::/7 unique-local
    }
    if (first == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) {
      return true; // 2001:db8::/32 documentation
    }
    var allZero = true;
    var nonzeroIndex = -1;
    for (var i = 0; i < 16; i++) {
      if (b[i] != 0) {
        allZero = false;
        nonzeroIndex = i;
        break;
      }
    }
    if (allZero) {
      return true; // :: unspecified
    }
    if (nonzeroIndex == 15 && b[15] == 1) {
      return true; // ::1 loopback
    }
    return false;
  }
}

/// The decoded embedded table: sorted, merged country ranges with a shared
/// country-code dictionary. Layout of the (gunzipped) blob, all integers
/// little-endian:
///
///   4 bytes  magic 'GEO1'
///   u16      country count N, then N × 2 ASCII bytes (the ISO codes)
///   u32      IPv4 range count, then per range: u32 start, u32 end, u8 ccIdx
///   u32      IPv6 range count, then per range: 16B start, 16B end, u8 ccIdx
class _GeoIpTable {
  _GeoIpTable._(
    this._countries,
    this._v4Start,
    this._v4End,
    this._v4Cc,
    this._v6Start,
    this._v6End,
    this._v6Cc,
  );

  final List<String> _countries;
  final Uint32List _v4Start;
  final Uint32List _v4End;
  final Uint8List _v4Cc;
  final Uint8List _v6Start;
  final Uint8List _v6End;
  final Uint8List _v6Cc;

  static _GeoIpTable decode() {
    final decoded = gzip.decode(base64.decode(data.geoIpCountryBlob));
    // `gzip.decode` already hands back a Uint8List on the VM; re-wrapping it
    // with `Uint8List.fromList` copied the whole table for nothing.
    final raw = decoded is Uint8List ? decoded : Uint8List.fromList(decoded);
    final reader = ByteData.sublistView(raw);
    var offset = 0;

    String ascii(int length) {
      final s = String.fromCharCodes(raw, offset, offset + length);
      offset += length;
      return s;
    }

    if (ascii(4) != 'GEO1') {
      throw StateError('geoip_country_data blob has a bad magic');
    }
    final countryCount = reader.getUint16(offset, Endian.little);
    offset += 2;
    final countries = [for (var i = 0; i < countryCount; i++) ascii(2)];

    final v4Count = reader.getUint32(offset, Endian.little);
    offset += 4;
    final v4Start = Uint32List(v4Count);
    final v4End = Uint32List(v4Count);
    final v4Cc = Uint8List(v4Count);
    for (var i = 0; i < v4Count; i++) {
      v4Start[i] = reader.getUint32(offset, Endian.little);
      v4End[i] = reader.getUint32(offset + 4, Endian.little);
      v4Cc[i] = raw[offset + 8];
      offset += 9;
    }

    final v6Count = reader.getUint32(offset, Endian.little);
    offset += 4;
    final v6Start = Uint8List(v6Count * 16);
    final v6End = Uint8List(v6Count * 16);
    final v6Cc = Uint8List(v6Count);
    for (var i = 0; i < v6Count; i++) {
      v6Start.setRange(i * 16, (i + 1) * 16, raw, offset);
      v6End.setRange(i * 16, (i + 1) * 16, raw, offset + 16);
      v6Cc[i] = raw[offset + 32];
      offset += 33;
    }

    return _GeoIpTable._(countries, v4Start, v4End, v4Cc, v6Start, v6End, v6Cc);
  }

  /// Binary search for the rightmost IPv4 range with start ≤ [ip]; a hit when
  /// [ip] also falls before its end. Ranges are sorted and non-overlapping.
  String? lookupV4(int ip) {
    var lo = 0;
    var hi = _v4Start.length - 1;
    var candidate = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >>> 1;
      final start = _v4Start[mid];
      if (start == ip) {
        candidate = mid;
        break;
      }
      if (start < ip) {
        candidate = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (candidate >= 0 && ip <= _v4End[candidate]) {
      return _countries[_v4Cc[candidate]];
    }
    return null;
  }

  /// Binary search over the 16-byte IPv6 ranges (byte-wise lexicographic).
  String? lookupV6(Uint8List ip) {
    var lo = 0;
    var hi = _v6Cc.length - 1;
    var candidate = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >>> 1;
      final cmp = _compareV6(ip, _v6Start, mid * 16);
      if (cmp == 0) {
        candidate = mid;
        break;
      }
      if (cmp > 0) {
        candidate = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (candidate >= 0 && _compareV6(ip, _v6End, candidate * 16) <= 0) {
      return _countries[_v6Cc[candidate]];
    }
    return null;
  }

  /// Lexicographic compare of [ip] against the 16 bytes in [table] at
  /// [offset]: negative when ip < table, zero when equal, positive when above.
  static int _compareV6(Uint8List ip, Uint8List table, int offset) {
    for (var i = 0; i < 16; i++) {
      final diff = ip[i] - table[offset + i];
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }
}
