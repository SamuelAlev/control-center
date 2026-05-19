// Regenerates packages/cc_infra/lib/src/geoip/geoip_country_data.dart — the
// embedded IP→country table backing `GeoIpLookup` — from the five RIR
// delegation stats files (freely redistributable registry statistics):
//
//   https://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-latest
//   https://ftp.ripe.net/pub/stats/apnic/delegated-apnic-latest
//   https://ftp.ripe.net/pub/stats/arin/delegated-arin-extended-latest
//   https://ftp.ripe.net/pub/stats/afrinic/delegated-afrinic-latest
//   https://ftp.ripe.net/pub/stats/lacnic/delegated-lacnic-latest
//
// Usage (from the repo root):
//   fvm dart run tool/gen_geoip_country.dart
//
// Same discipline as tool/gen_embedded_queries.dart: run the generator,
// commit the regenerated Dart file alongside. The table rides INSIDE the
// server binary (a loose data file could not ride the `dart build cli`
// bundle), so the lookup works with zero staged assets.
//
// The tool is all-or-nothing: every RIR must download (one retry) and yield
// at least one allocated/assigned record, or the tool fails loudly and writes
// NOTHING — a partial table must never ship silently.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _rirs = {
  'ripencc': 'https://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-latest',
  'apnic': 'https://ftp.ripe.net/pub/stats/apnic/delegated-apnic-latest',
  'arin':
      // ARIN retired the classic `delegated-arin-latest` (see
      // ARIN-STATS-FORMAT-CHANGE.txt); the extended file keeps the same seven
      // leading columns and appends an opaque record id.
      'https://ftp.ripe.net/pub/stats/arin/delegated-arin-extended-latest',
  'afrinic': 'https://ftp.ripe.net/pub/stats/afrinic/delegated-afrinic-latest',
  'lacnic': 'https://ftp.ripe.net/pub/stats/lacnic/delegated-lacnic-latest',
};

const _outPath = 'packages/cc_infra/lib/src/geoip/geoip_country_data.dart';

/// One merged country range. v4 bounds are 32-bit; v6 bounds are 16 bytes.
final class _Range {
  _Range(this.start, this.end, this.country);

  /// Inclusive start: int for v4, BigInt for v6.
  final Object start;

  /// Inclusive end.
  Object end;
  final String country;
}

Future<void> main() async {
  final v4 = <_Range>[];
  final v6 = <_Range>[];
  var totalRecords = 0;

  for (final entry in _rirs.entries) {
    final body = await _download(entry.key, entry.value);
    final before = totalRecords;
    totalRecords += _parse(entry.key, body, v4, v6);
    final records = totalRecords - before;
    stdout.writeln('${entry.key}: $records allocated/assigned records');
    if (records == 0) {
      _fail(
        '${entry.key} yielded ZERO allocated/assigned records — refusing to '
        'emit a partial table.',
      );
    }
  }
  stdout.writeln(
    'parsed $totalRecords records (${v4.length} v4 + ${v6.length} v6 ranges)',
  );

  final mergedV4 = _merge(v4);
  final mergedV6 = _merge(v6);
  stdout.writeln(
    'merged to ${mergedV4.length} v4 + ${mergedV6.length} v6 ranges',
  );

  final blob = _encode(mergedV4, mergedV6);
  final gzipped = gzip.encode(blob);
  final b64 = base64.encode(gzipped);
  stdout.writeln(
    'blob: ${blob.length} bytes raw → ${gzipped.length} gzip → '
    '${b64.length} base64',
  );

  final out = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Generated from the five RIR delegation stats files by')
    ..writeln('// `tool/gen_geoip_country.dart`. To refresh the table, run:')
    ..writeln('//')
    ..writeln('//   fvm dart run tool/gen_geoip_country.dart')
    ..writeln('//')
    ..writeln('// and commit this file. Sources (freely redistributable registry')
    ..writeln('// statistics):')
    ..writeln('//');
  for (final url in _rirs.values) {
    out.writeln('//   $url');
  }
  out
    ..writeln('//')
    ..writeln('// Regenerated: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln()
    ..writeln('/// The gzip+base64-encoded country table decoded lazily by')
    ..writeln('/// `GeoIpLookup` on first use. Layout (little-endian): magic')
    ..writeln('/// `GEO1`, u16 country count + 2-byte ISO codes, u32 v4 count +')
    ..writeln('/// (u32 start, u32 end, u8 ccIdx) entries, u32 v6 count +')
    ..writeln('/// (16B start, 16B end, u8 ccIdx) entries. Ranges are sorted and')
    ..writeln('/// merged; only RIR allocated/assigned delegations are present,')
    ..writeln('/// so private/reserved space is absent by construction.')
    ..writeln('const String geoIpCountryBlob =');
  // Adjacent string literals, one base64 line per literal.
  for (var i = 0; i < b64.length; i += 100) {
    final end = i + 100 > b64.length ? b64.length : i + 100;
    out.writeln("    '${b64.substring(i, end)}'");
  }
  out.writeln('    ;');

  File(_outPath).writeAsStringSync(out.toString());
  stdout.writeln('wrote $_outPath');
}

/// Downloads [url] once, retrying ONE time on failure; any further failure is
/// fatal — a missing RIR must never silently shrink the table.
Future<String> _download(String rir, String url) async {
  Object? lastError;
  for (var attempt = 1; attempt <= 2; attempt++) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final body = await utf8.decoder.bind(response).join();
      return body;
    } catch (e) {
      lastError = e;
      stderr.writeln('$rir download attempt $attempt failed: $e');
      if (attempt == 1) {
        stderr.writeln('retrying once…');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      client.close(force: true);
    }
  }
  _fail('could not download $rir stats from $url after one retry: $lastError');
}

/// Parses one delegated-stats body, appending v4/v6 ranges. Returns the number
/// of allocated/assigned records consumed. Lines are
/// `registry|cc|type|start|value|date|status[|extensions]`; only `ipv4`
/// (value = address count) and `ipv6` (value = prefix length) records with
/// status `allocated` or `assigned` and a two-letter country code count.
int _parse(String rir, String body, List<_Range> v4, List<_Range> v6) {
  var records = 0;
  for (final rawLine in const LineSplitter().convert(body)) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final f = line.split('|');
    if (f.length < 7) {
      continue;
    }
    final cc = f[1].toUpperCase();
    final type = f[2];
    final status = f[6].toLowerCase();
    if (cc.length != 2 ||
        cc == '*' ||
        (status != 'allocated' && status != 'assigned')) {
      continue;
    }
    if (type == 'ipv4') {
      final start = _parseV4(f[3]);
      final count = int.tryParse(f[4]);
      if (start == null || count == null || count <= 0) {
        _fail('$rir: malformed ipv4 record "$line"');
      }
      v4.add(_Range(start, start + count - 1, cc));
      records++;
    } else if (type == 'ipv6') {
      final start = _parseV6(f[3]);
      final prefix = int.tryParse(f[4]);
      if (start == null || prefix == null || prefix < 0 || prefix > 128) {
        _fail('$rir: malformed ipv6 record "$line"');
      }
      final size = BigInt.one << (128 - prefix);
      v6.add(_Range(start, start + size - BigInt.one, cc));
      records++;
    }
    // asn records and summary lines are ignored.
  }
  return records;
}

/// Sorts ranges by start and merges adjacent-or-overlapping ranges of the
/// same country. RIR delegations do not overlap across countries; same-
/// country overlaps collapse onto the wider bound.
List<_Range> _merge(List<_Range> ranges) {
  int cmp(Object a, Object b) {
    if (a is int && b is int) {
      return a.compareTo(b);
    }
    return (a as BigInt).compareTo(b as BigInt);
  }

  ranges.sort((a, b) => cmp(a.start, b.start));
  final merged = <_Range>[];
  for (final range in ranges) {
    final last = merged.isEmpty ? null : merged.last;
    if (last == null || last.country != range.country) {
      merged.add(range);
      continue;
    }
    final overlaps = cmp(range.start, last.end) <= 0;
    final adjacent = last.end is int
        ? (range.start as int) == (last.end as int) + 1
        : (range.start as BigInt) == (last.end as BigInt) + BigInt.one;
    if (!overlaps && !adjacent) {
      merged.add(range);
      continue;
    }
    // Overlapping or exactly adjacent same-country range: extend the end.
    if (cmp(range.end, last.end) > 0) {
      last.end = range.end;
    }
  }
  return merged;
}

/// Serializes the merged ranges + country dictionary into the binary blob
/// `GeoIpLookup` decodes (see its layout doc).
Uint8List _encode(List<_Range> v4, List<_Range> v6) {
  final countries = <String>{for (final r in v4) r.country}
    ..addAll([for (final r in v6) r.country]);
  final codes = countries.toList()..sort();
  if (codes.length > 255) {
    _fail('country dictionary overflow (${codes.length} codes > 255)');
  }
  final codeIndex = {for (var i = 0; i < codes.length; i++) codes[i]: i};

  final builder = BytesBuilder();
  void u16(int v) =>
      builder.add([v & 0xff, (v >> 8) & 0xff]);
  void u32(int v) => builder.add([
    v & 0xff,
    (v >> 8) & 0xff,
    (v >> 16) & 0xff,
    (v >> 24) & 0xff,
  ]);

  builder.add(ascii.encode('GEO1'));
  u16(codes.length);
  for (final code in codes) {
    builder.add(ascii.encode(code));
  }

  u32(v4.length);
  for (final r in v4) {
    u32(r.start as int);
    u32(r.end as int);
    builder.addByte(codeIndex[r.country]!);
  }

  u32(v6.length);
  for (final r in v6) {
    builder.add(_bigIntToBytes(r.start as BigInt));
    builder.add(_bigIntToBytes(r.end as BigInt));
    builder.addByte(codeIndex[r.country]!);
  }

  return builder.toBytes();
}

/// Renders a 128-bit address as 16 big-endian bytes.
Uint8List _bigIntToBytes(BigInt value) {
  final out = Uint8List(16);
  var v = value;
  for (var i = 15; i >= 0; i--) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v = v >> 8;
  }
  return out;
}

/// Parses a dotted-quad to its 32-bit value, or null when malformed.
int? _parseV4(String s) {
  final parts = s.split('.');
  if (parts.length != 4) {
    return null;
  }
  var value = 0;
  for (final part in parts) {
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) {
      return null;
    }
    value = (value << 8) | octet;
  }
  return value;
}

/// Parses an IPv6 literal (`::` compression, embedded v4 tail) to a 128-bit
/// BigInt, or null when malformed.
BigInt? _parseV6(String s) {
  var input = s;
  BigInt? embeddedV4;
  final lastColon = input.lastIndexOf(':');
  if (lastColon >= 0 && input.substring(lastColon + 1).contains('.')) {
    embeddedV4 = _parseV4(input.substring(lastColon + 1)) != null
        ? BigInt.from(_parseV4(input.substring(lastColon + 1))!)
        : null;
    if (embeddedV4 == null) {
      return null;
    }
    input = input.substring(0, lastColon + 1);
  }
  final halves = input.split('::');
  if (halves.length > 2) {
    return null;
  }
  List<int> groups(String part) {
    if (part.isEmpty) {
      return const [];
    }
    final out = <int>[];
    for (final g in part.split(':')) {
      if (g.isEmpty || g.length > 4) {
        return const [-1];
      }
      final value = int.tryParse(g, radix: 16);
      if (value == null) {
        return const [-1];
      }
      out.add(value);
    }
    return out;
  }

  final head = groups(halves[0]);
  final tail = halves.length == 2 ? groups(halves[1]) : const <int>[];
  if (head.contains(-1) || tail.contains(-1)) {
    return null;
  }
  final embeddedGroups = embeddedV4 == null ? 0 : 2;
  final missing = 8 - embeddedGroups - head.length - tail.length;
  if (halves.length == 2 ? missing < 0 : missing != 0) {
    return null;
  }
  if (halves.length == 1 && embeddedV4 != null && head.length != 6) {
    return null;
  }
  final all = [
    ...head,
    ...List.filled(missing, 0),
    ...tail,
    if (embeddedV4 != null) ...[
      ((embeddedV4 >> 16) & BigInt.from(0xffff)).toInt(),
      (embeddedV4 & BigInt.from(0xffff)).toInt(),
    ],
  ];
  if (all.length != 8) {
    return null;
  }
  var value = BigInt.zero;
  for (final g in all) {
    value = (value << 16) | BigInt.from(g);
  }
  return value;
}

Never _fail(String message) {
  stderr.writeln('gen_geoip_country FAILED: $message');
  exit(1);
}
