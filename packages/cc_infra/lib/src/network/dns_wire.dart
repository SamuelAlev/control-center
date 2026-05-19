/// Minimal DNS wire-format codec for the mDNS responder.
///
/// Hand-rolled on purpose: `cc_infra` must not depend on `multicast_dns`
/// (a Flutter-team package aimed at *querying*) and the responder only needs
/// a tiny, well-understood subset of RFC 1035/6762 — header + question +
/// answer/additional sections with PTR/SRV/TXT/A records, class IN and the
/// mDNS cache-flush / unicast-response bits.
///
/// Encoding always writes **uncompressed** names (legal and trivially
/// correct). Decoding fully supports RFC 1035 §4.1.4 compression pointers,
/// because real queriers (Bonjour, Avahi, `package:multicast_dns`) do
/// compress. All decode entry points are total: malformed input yields `null`,
/// never a throw.
library;

import 'dart:convert';
import 'dart:typed_data';

/// DNS record/query type: IPv4 host address (A).
const int dnsTypeA = 1;

/// DNS record/query type: domain-name pointer (PTR).
const int dnsTypePtr = 12;

/// DNS record/query type: text strings (TXT).
const int dnsTypeTxt = 16;

/// DNS record/query type: service locator (SRV, RFC 2782).
const int dnsTypeSrv = 33;

/// DNS query type matching any record type (ANY/`*`).
const int dnsTypeAny = 255;

/// DNS class IN (internet).
const int dnsClassInternet = 1;

/// DNS query class matching any class (ANY/`*`).
const int dnsClassAny = 255;

/// mDNS cache-flush bit (RFC 6762 §10.2), OR-ed into the class field of
/// records the responder is the sole authority for (SRV/TXT/A).
const int mdnsCacheFlushBit = 0x8000;

/// mDNS unicast-response ("QU") bit on question classes (RFC 6762 §5.4).
/// Strip it before comparing a question's class against [dnsClassInternet].
const int mdnsUnicastResponseBit = 0x8000;

/// Header flag: QR bit — set on responses, clear on queries.
const int dnsFlagResponse = 0x8000;

/// Header flag: AA bit — authoritative answer. mDNS responders always set it.
const int dnsFlagAuthoritative = 0x0400;

const int _headerSize = 12;
const int _maxLabelBytes = 63;
const int _maxNameBytes = 255;

/// A single DNS question (name + QTYPE + QCLASS).
///
/// Names are carried as label lists (never dotted strings) so labels that
/// contain dots or spaces — legal in mDNS service-instance names — survive
/// both directions unambiguously.
class DnsQuestion {
  /// Creates a question for [labels] with the given [type] and [dnsClass].
  const DnsQuestion({
    required this.labels,
    required this.type,
    this.dnsClass = dnsClassInternet,
  });

  /// The QNAME as ordered labels, e.g. `['_ccserver', '_tcp', 'local']`.
  final List<String> labels;

  /// The QTYPE, e.g. [dnsTypePtr].
  final int type;

  /// The raw QCLASS, possibly carrying [mdnsUnicastResponseBit].
  final int dnsClass;
}

/// An encodable DNS resource record (name + type + class + TTL + RDATA).
class DnsRecord {
  /// Creates a record owning [labels] with pre-encoded [rdata].
  const DnsRecord({
    required this.labels,
    required this.type,
    required this.dnsClass,
    required this.ttl,
    required this.rdata,
  });

  /// The record name as ordered labels.
  final List<String> labels;

  /// The record type, e.g. [dnsTypeSrv].
  final int type;

  /// The class field — [dnsClassInternet], optionally OR-ed with
  /// [mdnsCacheFlushBit] on records this host is the sole authority for.
  final int dnsClass;

  /// Time-to-live in seconds. `0` announces a goodbye (RFC 6762 §10.1).
  final int ttl;

  /// The record data, already in wire format (see [encodeDnsName],
  /// [encodeSrvRdata], [encodeTxtRdata]).
  final Uint8List rdata;

  /// A copy of this record with [ttl] replaced — used for goodbye packets.
  DnsRecord withTtl(int ttl) => DnsRecord(
    labels: labels,
    type: type,
    dnsClass: dnsClass,
    ttl: ttl,
    rdata: rdata,
  );
}

/// A resource record decoded from a packet. RDATA is kept as raw bytes — the
/// responder never needs to interpret foreign records and tests compare
/// against the encoder's output.
class DecodedDnsRecord {
  /// Creates a decoded record.
  const DecodedDnsRecord({
    required this.labels,
    required this.type,
    required this.dnsClass,
    required this.ttl,
    required this.rdata,
  });

  /// The record name as ordered labels (compression already resolved).
  final List<String> labels;

  /// The record type.
  final int type;

  /// The raw class field, possibly carrying [mdnsCacheFlushBit].
  final int dnsClass;

  /// Time-to-live in seconds.
  final int ttl;

  /// The raw record data bytes.
  final Uint8List rdata;

  /// Whether the mDNS cache-flush bit is set on this record.
  bool get cacheFlush => dnsClass & mdnsCacheFlushBit != 0;
}

/// A decoded DNS message: header flags + all four sections.
class DnsMessage {
  /// Creates a decoded message.
  const DnsMessage({
    required this.id,
    required this.flags,
    required this.questions,
    required this.answers,
    required this.authorities,
    required this.additionals,
  });

  /// The message ID (always 0 for multicast mDNS).
  final int id;

  /// The raw header flags word.
  final int flags;

  /// The question section.
  final List<DnsQuestion> questions;

  /// The answer section.
  final List<DecodedDnsRecord> answers;

  /// The authority section.
  final List<DecodedDnsRecord> authorities;

  /// The additional section.
  final List<DecodedDnsRecord> additionals;

  /// Whether the QR bit marks this message as a query.
  bool get isQuery => flags & dnsFlagResponse == 0;

  /// Whether the QR bit marks this message as a response.
  bool get isResponse => !isQuery;
}

/// Encodes [labels] as an uncompressed DNS name (length-prefixed labels,
/// zero-terminated). Throws [ArgumentError] on labels that violate the wire
/// limits (empty, >63 bytes, or a total name >255 bytes) — encode inputs are
/// always our own names, so this is a programming error, not runtime input.
Uint8List encodeDnsName(List<String> labels) {
  final builder = BytesBuilder(copy: false);
  for (final label in labels) {
    final bytes = utf8.encode(label);
    if (bytes.isEmpty || bytes.length > _maxLabelBytes) {
      throw ArgumentError.value(
        label,
        'labels',
        'DNS labels must be 1-$_maxLabelBytes UTF-8 bytes',
      );
    }
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  builder.addByte(0);
  if (builder.length > _maxNameBytes) {
    throw ArgumentError.value(
      labels.join('.'),
      'labels',
      'encoded DNS name exceeds $_maxNameBytes bytes',
    );
  }
  return builder.toBytes();
}

/// Encodes SRV record data: priority, weight, [port], then the [target] host
/// name (uncompressed).
Uint8List encodeSrvRdata({
  required int port,
  required List<String> target,
  int priority = 0,
  int weight = 0,
}) {
  final builder = BytesBuilder(copy: false)
    ..add(_uint16(priority))
    ..add(_uint16(weight))
    ..add(_uint16(port))
    ..add(encodeDnsName(target));
  return builder.toBytes();
}

/// Encodes TXT record data as length-prefixed `key=value` strings, one per
/// map entry, in iteration order. An empty map encodes as the mandatory
/// single zero byte (RFC 6763 §6.1).
Uint8List encodeTxtRdata(Map<String, String> entries) {
  if (entries.isEmpty) {
    return Uint8List.fromList(const <int>[0]);
  }
  final builder = BytesBuilder(copy: false);
  for (final entry in entries.entries) {
    final bytes = utf8.encode('${entry.key}=${entry.value}');
    if (bytes.length > 255) {
      throw ArgumentError.value(
        entry.key,
        'entries',
        'a TXT entry must encode to at most 255 bytes',
      );
    }
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  return builder.toBytes();
}

/// Encodes an authoritative mDNS response carrying [answers] and, optionally,
/// [additionals]. The ID is 0 as RFC 6762 §18.1 requires for multicast.
Uint8List encodeDnsResponse({
  required List<DnsRecord> answers,
  List<DnsRecord> additionals = const <DnsRecord>[],
}) {
  return _encodeDnsMessage(
    flags: dnsFlagResponse | dnsFlagAuthoritative,
    answers: answers,
    additionals: additionals,
  );
}

/// Encodes a plain (QM) query for [questions] — used by tests and available
/// to any future prober.
Uint8List encodeDnsQuery({required List<DnsQuestion> questions}) {
  return _encodeDnsMessage(flags: 0, questions: questions);
}

Uint8List _encodeDnsMessage({
  required int flags,
  List<DnsQuestion> questions = const <DnsQuestion>[],
  List<DnsRecord> answers = const <DnsRecord>[],
  List<DnsRecord> additionals = const <DnsRecord>[],
}) {
  final builder = BytesBuilder(copy: false)
    ..add(_uint16(0)) // ID — always 0 for multicast mDNS.
    ..add(_uint16(flags))
    ..add(_uint16(questions.length))
    ..add(_uint16(answers.length))
    ..add(_uint16(0)) // NSCOUNT — the responder never fills authorities.
    ..add(_uint16(additionals.length));
  for (final question in questions) {
    builder
      ..add(encodeDnsName(question.labels))
      ..add(_uint16(question.type))
      ..add(_uint16(question.dnsClass));
  }
  for (final record in <DnsRecord>[...answers, ...additionals]) {
    builder
      ..add(encodeDnsName(record.labels))
      ..add(_uint16(record.type))
      ..add(_uint16(record.dnsClass))
      ..add(_uint32(record.ttl))
      ..add(_uint16(record.rdata.length))
      ..add(record.rdata);
  }
  return builder.toBytes();
}

/// Decodes a DNS message, resolving name-compression pointers.
///
/// Returns `null` for anything malformed (truncated packets, pointer loops,
/// oversized names) — the responder feeds it raw datagrams straight off the
/// wire, so it must never throw.
DnsMessage? decodeDnsMessage(List<int> packet) {
  final data = packet is Uint8List ? packet : Uint8List.fromList(packet);
  if (data.length < _headerSize) {
    return null;
  }
  final view = ByteData.sublistView(data);
  try {
    final questionCount = view.getUint16(4);
    final answerCount = view.getUint16(6);
    final authorityCount = view.getUint16(8);
    final additionalCount = view.getUint16(10);

    var offset = _headerSize;
    final questions = <DnsQuestion>[];
    for (var i = 0; i < questionCount; i++) {
      final name = _readName(data, offset);
      offset = name.end;
      _require(data, offset + 4);
      questions.add(
        DnsQuestion(
          labels: name.labels,
          type: view.getUint16(offset),
          dnsClass: view.getUint16(offset + 2),
        ),
      );
      offset += 4;
    }

    List<DecodedDnsRecord> readSection(int count) {
      final records = <DecodedDnsRecord>[];
      for (var i = 0; i < count; i++) {
        final name = _readName(data, offset);
        offset = name.end;
        _require(data, offset + 10);
        final type = view.getUint16(offset);
        final dnsClass = view.getUint16(offset + 2);
        final ttl = view.getUint32(offset + 4);
        final rdataLength = view.getUint16(offset + 8);
        offset += 10;
        _require(data, offset + rdataLength);
        records.add(
          DecodedDnsRecord(
            labels: name.labels,
            type: type,
            dnsClass: dnsClass,
            ttl: ttl,
            rdata: Uint8List.sublistView(data, offset, offset + rdataLength),
          ),
        );
        offset += rdataLength;
      }
      return records;
    }

    final answers = readSection(answerCount);
    final authorities = readSection(authorityCount);
    final additionals = readSection(additionalCount);
    return DnsMessage(
      id: view.getUint16(0),
      flags: view.getUint16(2),
      questions: questions,
      answers: answers,
      authorities: authorities,
      additionals: additionals,
    );
  } catch (_) {
    // Malformed packet (bounds, pointer loop, bad label) — treat as noise.
    return null;
  }
}

/// Compares two DNS names label-by-label, ASCII case-insensitively
/// (RFC 1035 §2.3.3). Comparing label lists — not joined dotted strings —
/// keeps labels containing dots unambiguous.
bool dnsNamesEqual(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].toLowerCase() != b[i].toLowerCase()) {
      return false;
    }
  }
  return true;
}

class _NameReadResult {
  const _NameReadResult(this.labels, this.end);

  final List<String> labels;

  /// Absolute offset of the first byte after the name at its original
  /// position (i.e. after the terminator, or after a compression pointer).
  final int end;
}

/// Reads a possibly-compressed name starting at [start]. Pointers must target
/// strictly earlier offsets than any previously visited position — the
/// standard loop guard, also used by `package:multicast_dns`.
_NameReadResult _readName(Uint8List data, int start) {
  final labels = <String>[];
  var offset = start;
  var nameBytes = 0;
  int? endAfterPointer;
  var pointerCeiling = start;
  // A name has at most 128 labels (255 bytes / 2); anything longer is a loop.
  for (var steps = 0; steps < 128; steps++) {
    _require(data, offset + 1);
    final length = data[offset];
    if (length & 0xc0 == 0xc0) {
      _require(data, offset + 2);
      final target = ((length & 0x3f) << 8) | data[offset + 1];
      endAfterPointer ??= offset + 2;
      if (target >= pointerCeiling) {
        throw const FormatException('forward or looping compression pointer');
      }
      pointerCeiling = target;
      offset = target;
    } else if (length == 0) {
      return _NameReadResult(labels, endAfterPointer ?? offset + 1);
    } else if (length > _maxLabelBytes) {
      throw const FormatException('label exceeds 63 bytes');
    } else {
      _require(data, offset + 1 + length);
      nameBytes += 1 + length;
      if (nameBytes > _maxNameBytes) {
        throw const FormatException('name exceeds 255 bytes');
      }
      labels.add(
        utf8.decode(
          Uint8List.sublistView(data, offset + 1, offset + 1 + length),
          allowMalformed: true,
        ),
      );
      offset += 1 + length;
    }
  }
  throw const FormatException('unterminated DNS name');
}

void _require(Uint8List data, int length) {
  if (data.length < length) {
    throw const FormatException('truncated DNS packet');
  }
}

Uint8List _uint16(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value);

Uint8List _uint32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value);
