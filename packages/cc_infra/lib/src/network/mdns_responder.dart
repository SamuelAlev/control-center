/// Zero-config LAN discovery: the server-side mDNS responder (PRD 15 §7).
///
/// `cc_server` advertises itself as a DNS-SD service instance of type
/// [ccServerMdnsServiceType] over IPv4 mDNS (UDP 5353 / 224.0.0.251), so
/// desktop clients on the same LAN can list reachable servers without any
/// configuration. Pure `dart:io` — the wire format lives in
/// `package:cc_infra/src/network/dns_wire.dart`, hand-rolled so the server
/// binary takes no dependency on `package:multicast_dns` (the *client* side of
/// discovery, which lives in the desktop app, does use that package and must
/// stay in sync with these constants).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/network/dns_wire.dart';

/// The DNS-SD service type `cc_server` advertises.
///
/// KEEP IN SYNC with the desktop discoverer
/// (`lib/core/server/lan_discovery.dart` in the root app), which cannot import
/// this package (lib-boundary ratchet).
const String ccServerMdnsServiceType = '_ccserver._tcp.local';

/// [ccServerMdnsServiceType] as DNS labels.
const List<String> ccServerServiceLabels = <String>[
  '_ccserver',
  '_tcp',
  'local',
];

/// The DNS-SD service-type enumeration name (RFC 6763 §9) — answering it lets
/// generic browsers (`dns-sd -B`, Avahi) see that `_ccserver._tcp` exists.
const List<String> serviceEnumerationLabels = <String>[
  '_services',
  '_dns-sd',
  '_udp',
  'local',
];

/// The IPv4 mDNS multicast group.
final InternetAddress mdnsGroupAddress = InternetAddress('224.0.0.251');

/// The mDNS UDP port.
const int mdnsPort = 5353;

/// TTL for records naming a host (SRV/A) — RFC 6762 §10 recommends 120s.
const int mdnsHostRecordTtlSeconds = 120;

/// TTL for the remaining records (PTR/TXT) — RFC 6762 §10 recommends 75 min.
const int mdnsSharedRecordTtlSeconds = 4500;

/// Sanitizes a service-instance label. Instance names may contain spaces
/// (RFC 6763 §4.1.1) but a dot would split the label when queriers render the
/// name as a dotted string, so dots become dashes; control characters are
/// dropped; the result is capped at the 63-byte label limit.
String sanitizeMdnsInstanceLabel(String raw) {
  var label = raw
      .trim()
      .replaceAll('.', '-')
      .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
  while (label.isNotEmpty && utf8ByteLength(label) > 63) {
    label = label.substring(0, label.length - 1);
  }
  return label.isEmpty ? 'cc-server' : label;
}

/// Sanitizes a machine host label to the conservative letter-digit-hyphen
/// subset, stripping any `.local` suffix the platform may already report.
String sanitizeMdnsHostLabel(String raw) {
  var host = raw.trim();
  final lower = host.toLowerCase();
  if (lower.endsWith('.local')) {
    host = host.substring(0, host.length - '.local'.length);
  }
  host = host.replaceAll(RegExp('[^A-Za-z0-9-]'), '-');
  if (host.length > 63) {
    host = host.substring(0, 63);
  }
  return host.isEmpty ? 'cc-server' : host;
}

/// UTF-8 byte length of [value] (labels are limited in bytes, not runes).
int utf8ByteLength(String value) => utf8.encode(value).length;

/// The immutable set of mDNS records one `cc_server` instance owns, plus the
/// **pure** query→response logic. Kept free of sockets so the DNS behavior is
/// unit-testable byte-for-byte; [CcMdnsResponder] owns the thin UDP plumbing.
class CcMdnsRecordSet {
  /// Builds the record set for one advertised server.
  ///
  /// [instanceName] is the human-readable server name (spaces allowed; see
  /// [sanitizeMdnsInstanceLabel]); [hostName] the machine's host name without
  /// `.local`; [addresses] every non-loopback IPv4 address to publish as A
  /// records (non-IPv4/loopback entries are filtered defensively).
  CcMdnsRecordSet({
    required String instanceName,
    required String hostName,
    required this.port,
    required Map<String, String> txt,
    required List<InternetAddress> addresses,
  }) : instanceLabels = <String>[
         sanitizeMdnsInstanceLabel(instanceName),
         ...ccServerServiceLabels,
       ],
       hostLabels = <String>[sanitizeMdnsHostLabel(hostName), 'local'],
       txt = Map<String, String>.unmodifiable(txt),
       addresses = List<InternetAddress>.unmodifiable(
         addresses.where(
           (a) => a.type == InternetAddressType.IPv4 && !a.isLoopback,
         ),
       );

  /// The advertised port (carried in the SRV record).
  final int port;

  /// The advertised TXT entries (`sid`, `fp`, `name`, `tls`, …).
  final Map<String, String> txt;

  /// The published IPv4 addresses.
  final List<InternetAddress> addresses;

  /// The full service-instance name as labels:
  /// `<instance>._ccserver._tcp.local`.
  final List<String> instanceLabels;

  /// The advertised host name as labels: `<host>.local`.
  final List<String> hostLabels;

  /// PTR `_ccserver._tcp.local` → instance. Shared record: no cache-flush
  /// (RFC 6762 §10.2 — many servers may advertise the same service type).
  late final DnsRecord servicePtr = DnsRecord(
    labels: ccServerServiceLabels,
    type: dnsTypePtr,
    dnsClass: dnsClassInternet,
    ttl: mdnsSharedRecordTtlSeconds,
    rdata: encodeDnsName(instanceLabels),
  );

  /// PTR `_services._dns-sd._udp.local` → `_ccserver._tcp.local`
  /// (service-type enumeration, RFC 6763 §9). Shared record.
  late final DnsRecord enumerationPtr = DnsRecord(
    labels: serviceEnumerationLabels,
    type: dnsTypePtr,
    dnsClass: dnsClassInternet,
    ttl: mdnsSharedRecordTtlSeconds,
    rdata: encodeDnsName(ccServerServiceLabels),
  );

  /// SRV instance → `<host>.local:<port>`. Unique record: cache-flush set.
  late final DnsRecord srv = DnsRecord(
    labels: instanceLabels,
    type: dnsTypeSrv,
    dnsClass: dnsClassInternet | mdnsCacheFlushBit,
    ttl: mdnsHostRecordTtlSeconds,
    rdata: encodeSrvRdata(port: port, target: hostLabels),
  );

  /// TXT instance → the advertised key/value entries. Unique record.
  late final DnsRecord txtRecord = DnsRecord(
    labels: instanceLabels,
    type: dnsTypeTxt,
    dnsClass: dnsClassInternet | mdnsCacheFlushBit,
    ttl: mdnsSharedRecordTtlSeconds,
    rdata: encodeTxtRdata(txt),
  );

  /// One A record per published IPv4 address. Unique records.
  late final List<DnsRecord> aRecords = List<DnsRecord>.unmodifiable(
    addresses.map(
      (a) => DnsRecord(
        labels: hostLabels,
        type: dnsTypeA,
        dnsClass: dnsClassInternet | mdnsCacheFlushBit,
        ttl: mdnsHostRecordTtlSeconds,
        rdata: Uint8List.fromList(a.rawAddress),
      ),
    ),
  );

  /// Builds the unsolicited announcement (RFC 6762 §8.3): every owned record
  /// in the answer section. With [goodbye] all TTLs are 0, telling caches to
  /// drop the service (RFC 6762 §10.1).
  Uint8List buildAnnouncement({bool goodbye = false}) {
    final records = <DnsRecord>[servicePtr, srv, txtRecord, ...aRecords];
    return encodeDnsResponse(
      answers: goodbye
          ? records.map((r) => r.withTtl(0)).toList(growable: false)
          : records,
    );
  }

  /// Pure query handler: decodes [queryPacket] and, when any question matches
  /// a record this instance owns, returns the encoded response — else `null`.
  ///
  /// Matches (QTYPE `ANY` counts for each):
  /// - PTR for the service type → PTR answer + SRV/TXT/A additionals
  ///   (RFC 6763 §12.1);
  /// - PTR for the service-type enumeration → enumeration PTR;
  /// - SRV/TXT for the instance → the matching record (+ A additionals for
  ///   SRV, RFC 6763 §12.2);
  /// - A for the host → all A records.
  ///
  /// Malformed packets and non-queries yield `null` — this function never
  /// throws on wire input.
  Uint8List? buildResponse(List<int> queryPacket) {
    final message = decodeDnsMessage(queryPacket);
    if (message == null || !message.isQuery || message.questions.isEmpty) {
      return null;
    }
    // LinkedHashSets keep first-seen order and de-dupe records matched by
    // more than one question (the record instances are canonical fields).
    final answers = <DnsRecord>{};
    final additionals = <DnsRecord>{};
    for (final question in message.questions) {
      final questionClass = question.dnsClass & ~mdnsUnicastResponseBit;
      if (questionClass != dnsClassInternet && questionClass != dnsClassAny) {
        continue;
      }
      final type = question.type;
      final wantsPtr = type == dnsTypePtr || type == dnsTypeAny;
      if (wantsPtr && dnsNamesEqual(question.labels, ccServerServiceLabels)) {
        answers.add(servicePtr);
        additionals
          ..add(srv)
          ..add(txtRecord)
          ..addAll(aRecords);
      }
      if (wantsPtr &&
          dnsNamesEqual(question.labels, serviceEnumerationLabels)) {
        answers.add(enumerationPtr);
      }
      if (dnsNamesEqual(question.labels, instanceLabels)) {
        if (type == dnsTypeSrv || type == dnsTypeAny) {
          answers.add(srv);
          additionals.addAll(aRecords);
        }
        if (type == dnsTypeTxt || type == dnsTypeAny) {
          answers.add(txtRecord);
        }
      }
      if ((type == dnsTypeA || type == dnsTypeAny) &&
          dnsNamesEqual(question.labels, hostLabels)) {
        answers.addAll(aRecords);
      }
    }
    if (answers.isEmpty) {
      return null;
    }
    additionals.removeAll(answers);
    return encodeDnsResponse(
      answers: answers.toList(growable: false),
      additionals: additionals.toList(growable: false),
    );
  }
}

/// Advertises one `cc_server` instance over IPv4 mDNS.
///
/// On [start] it binds UDP 5353 (SO_REUSEADDR/SO_REUSEPORT so it coexists
/// with the OS resolver), joins 224.0.0.251 on every IPv4 interface, sends
/// two unsolicited announcements ~1s apart (RFC 6762 §8.3), then answers
/// matching queries. [stop] multicasts a goodbye (TTL 0) and closes the
/// socket. All DNS logic is delegated to the pure [CcMdnsRecordSet].
class CcMdnsResponder {
  /// Creates a responder advertising [instanceName] on [port] with the given
  /// [txt] entries (`sid`/`fp`/`name`/`tls`). [log] receives diagnostics;
  /// the responder itself never prints.
  CcMdnsResponder({
    required this.instanceName,
    required this.port,
    required Map<String, String> txt,
    this.log,
  }) : txt = Map<String, String>.unmodifiable(txt);

  /// The human-readable server name (spaces allowed; sanitized on the wire).
  final String instanceName;

  /// The TCP port the advertised server listens on.
  final int port;

  /// The advertised TXT entries.
  final Map<String, String> txt;

  /// Optional diagnostics sink.
  final void Function(String)? log;

  CcMdnsRecordSet? _records;
  RawDatagramSocket? _socket;
  Timer? _reannounceTimer;
  bool _running = false;

  /// Whether the responder is currently advertising.
  bool get isRunning => _running;

  /// The record set built by [start] — exposed for observability/tests.
  CcMdnsRecordSet? get records => _records;

  /// Binds the socket, joins the multicast group on every IPv4 interface and
  /// announces the service. Idempotent while running. Throws (after cleaning
  /// up) if the socket cannot be bound at all.
  Future<void> start() async {
    if (_running) {
      return;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: true,
      );
      final addresses = <InternetAddress>[
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback) address,
      ];
      _records = CcMdnsRecordSet(
        instanceName: instanceName,
        hostName: Platform.localHostname,
        port: port,
        txt: txt,
        addresses: addresses,
      );
      final socket = await _bind();
      _socket = socket;
      try {
        socket.multicastHops = 255;
      } on OSError catch (e) {
        _log('could not set multicast TTL: $e');
      }
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(mdnsGroupAddress, interface);
        } on Object catch (e) {
          _log('joinMulticast(${interface.name}) failed: $e');
        }
      }
      socket.listen(
        _onSocketEvent,
        onError: (Object e) => _log('mDNS socket error: $e'),
      );
      _running = true;
      _announce();
      _reannounceTimer = Timer(const Duration(seconds: 1), _announce);
      _log(
        'advertising "$instanceName" as $ccServerMdnsServiceType '
        'on port $port (${addresses.length} address(es))',
      );
    } on Object {
      _socket?.close();
      _socket = null;
      _records = null;
      _running = false;
      rethrow;
    }
  }

  /// Multicasts a goodbye (TTL 0) for the advertised records and closes the
  /// socket. Safe to call when not running.
  Future<void> stop() async {
    if (!_running) {
      return;
    }
    _running = false;
    _reannounceTimer?.cancel();
    _reannounceTimer = null;
    final records = _records;
    if (records != null) {
      _send(records.buildAnnouncement(goodbye: true));
    }
    _socket?.close();
    _socket = null;
    _records = null;
    _log('stopped advertising "$instanceName"');
  }

  Future<RawDatagramSocket> _bind() async {
    try {
      return await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        mdnsPort,
        reuseAddress: true,
        reusePort: true,
      );
    } on SocketException {
      // reusePort is unsupported on some platforms (notably Windows).
      return RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        mdnsPort,
        reuseAddress: true,
      );
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }
    try {
      final response = _records?.buildResponse(datagram.data);
      if (response != null) {
        _send(response);
      }
    } on Object catch (e) {
      // Defensive: buildResponse is total over wire input, but a handler
      // must never let anything escape into the socket's event loop.
      _log('failed handling mDNS packet from ${datagram.address.address}: $e');
    }
  }

  void _announce() {
    final records = _records;
    if (!_running || records == null) {
      return;
    }
    _send(records.buildAnnouncement());
  }

  void _send(Uint8List packet) {
    try {
      _socket?.send(packet, mdnsGroupAddress, mdnsPort);
    } on Object catch (e) {
      _log('mDNS send failed: $e');
    }
  }

  void _log(String message) => log?.call('CcMdnsResponder: $message');
}
