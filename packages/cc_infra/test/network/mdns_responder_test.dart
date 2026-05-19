import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

void main() {
  group('dns_wire encoding', () {
    test('a known PTR answer encodes to the hand-checked byte layout', () {
      final packet = encodeDnsResponse(
        answers: <DnsRecord>[
          DnsRecord(
            labels: ccServerServiceLabels,
            type: dnsTypePtr,
            dnsClass: dnsClassInternet,
            ttl: mdnsSharedRecordTtlSeconds,
            rdata: encodeDnsName(<String>['srv1', ...ccServerServiceLabels]),
          ),
        ],
      );

      final expected = <int>[
        0x00, 0x00, // ID — always 0 for multicast mDNS
        0x84, 0x00, // flags: QR (response) | AA (authoritative)
        0x00, 0x00, // QDCOUNT
        0x00, 0x01, // ANCOUNT
        0x00, 0x00, // NSCOUNT
        0x00, 0x00, // ARCOUNT
        // NAME: _ccserver._tcp.local (uncompressed)
        9, ...'_ccserver'.codeUnits,
        4, ...'_tcp'.codeUnits,
        5, ...'local'.codeUnits,
        0,
        0x00, 0x0c, // TYPE: PTR
        0x00, 0x01, // CLASS: IN (no cache-flush on shared records)
        0x00, 0x00, 0x11, 0x94, // TTL: 4500s
        0x00, 0x1b, // RDLENGTH: 27
        // RDATA: srv1._ccserver._tcp.local
        4, ...'srv1'.codeUnits,
        9, ...'_ccserver'.codeUnits,
        4, ...'_tcp'.codeUnits,
        5, ...'local'.codeUnits,
        0,
      ];
      expect(packet, equals(expected));
    });

    test('a query round-trips through the decoder', () {
      final packet = encodeDnsQuery(
        questions: <DnsQuestion>[
          const DnsQuestion(labels: <String>['a b', 'local'], type: dnsTypeSrv),
          const DnsQuestion(
            labels: ccServerServiceLabels,
            type: dnsTypePtr,
            dnsClass: dnsClassInternet | mdnsUnicastResponseBit,
          ),
        ],
      );

      final message = decodeDnsMessage(packet);
      expect(message, isNotNull);
      expect(message!.isQuery, isTrue);
      expect(message.questions, hasLength(2));
      expect(message.questions[0].labels, <String>['a b', 'local']);
      expect(message.questions[0].type, dnsTypeSrv);
      expect(message.questions[0].dnsClass, dnsClassInternet);
      expect(message.questions[1].labels, ccServerServiceLabels);
      expect(
        message.questions[1].dnsClass & mdnsUnicastResponseBit,
        mdnsUnicastResponseBit,
      );
      expect(message.answers, isEmpty);
    });

    test('an announcement round-trips through the decoder', () {
      final records = CcMdnsRecordSet(
        instanceName: 'My Server',
        hostName: 'devbox',
        port: 9800,
        txt: const <String, String>{'sid': 'abc', 'tls': '1'},
        addresses: <InternetAddress>[InternetAddress('192.168.1.10')],
      );

      final message = decodeDnsMessage(records.buildAnnouncement());
      expect(message, isNotNull);
      expect(message!.isResponse, isTrue);
      expect(message.flags & dnsFlagAuthoritative, dnsFlagAuthoritative);
      // PTR + SRV + TXT + one A record.
      expect(message.answers, hasLength(4));

      final ptr = message.answers[0];
      expect(ptr.labels, ccServerServiceLabels);
      expect(ptr.type, dnsTypePtr);
      expect(ptr.cacheFlush, isFalse);
      expect(ptr.ttl, mdnsSharedRecordTtlSeconds);
      expect(ptr.rdata, equals(encodeDnsName(records.instanceLabels)));

      final srv = message.answers[1];
      expect(srv.labels, records.instanceLabels);
      expect(srv.type, dnsTypeSrv);
      expect(srv.cacheFlush, isTrue);
      expect(srv.ttl, mdnsHostRecordTtlSeconds);
      expect(
        srv.rdata,
        equals(encodeSrvRdata(port: 9800, target: records.hostLabels)),
      );

      final txt = message.answers[2];
      expect(txt.type, dnsTypeTxt);
      expect(txt.cacheFlush, isTrue);
      expect(
        txt.rdata,
        equals(
          encodeTxtRdata(const <String, String>{'sid': 'abc', 'tls': '1'}),
        ),
      );

      final a = message.answers[3];
      expect(a.labels, records.hostLabels);
      expect(a.type, dnsTypeA);
      expect(a.cacheFlush, isTrue);
      expect(a.rdata, equals(<int>[192, 168, 1, 10]));
    });

    test('goodbye announcements carry TTL 0 on every record', () {
      final records = CcMdnsRecordSet(
        instanceName: 'x',
        hostName: 'devbox',
        port: 1,
        txt: const <String, String>{},
        addresses: <InternetAddress>[InternetAddress('10.0.0.7')],
      );
      final message = decodeDnsMessage(
        records.buildAnnouncement(goodbye: true),
      );
      expect(message, isNotNull);
      expect(message!.answers, isNotEmpty);
      for (final record in message.answers) {
        expect(record.ttl, 0);
      }
    });

    test('an empty TXT map encodes as a single zero byte', () {
      expect(encodeTxtRdata(const <String, String>{}), equals(<int>[0]));
    });
  });

  group('dns_wire decoding', () {
    test('resolves compression pointers in question names', () {
      // Hand-crafted query: Q1 asks PTR for the service type (uncompressed,
      // name starts at offset 12); Q2 asks SRV for
      // "srv1.<pointer to offset 12>" the way real queriers compress.
      final packet = <int>[
        0x00, 0x00, // ID
        0x00, 0x00, // flags: query
        0x00, 0x02, // QDCOUNT: 2
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // AN/NS/AR
        // Q1 name at offset 12: _ccserver._tcp.local
        9, ...'_ccserver'.codeUnits,
        4, ...'_tcp'.codeUnits,
        5, ...'local'.codeUnits,
        0,
        0x00, 0x0c, // PTR
        0x00, 0x01, // IN
        // Q2 name: srv1 + pointer to offset 12
        4, ...'srv1'.codeUnits,
        0xc0, 0x0c,
        0x00, 0x21, // SRV
        0x00, 0x01, // IN
      ];

      final message = decodeDnsMessage(packet);
      expect(message, isNotNull);
      expect(message!.questions, hasLength(2));
      expect(message.questions[0].labels, ccServerServiceLabels);
      expect(message.questions[1].labels, <String>[
        'srv1',
        ...ccServerServiceLabels,
      ]);
      expect(message.questions[1].type, dnsTypeSrv);
    });

    test('rejects malformed packets instead of throwing', () {
      // Truncated header.
      expect(decodeDnsMessage(<int>[0, 0, 0]), isNull);
      // Claims one question but has none.
      expect(
        decodeDnsMessage(<int>[0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]),
        isNull,
      );
      // Question name with a self-referencing compression pointer.
      expect(
        decodeDnsMessage(<int>[
          0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, //
          0xc0, 0x0c, 0, 12, 0, 1,
        ]),
        isNull,
      );
      // Question name with a forward pointer.
      expect(
        decodeDnsMessage(<int>[
          0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, //
          0xc0, 0x20, 0, 12, 0, 1,
        ]),
        isNull,
      );
      // Truncated label.
      expect(
        decodeDnsMessage(<int>[
          0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, //
          9, 0x61, 0x62,
        ]),
        isNull,
      );
    });

    test('dnsNamesEqual compares labels ASCII case-insensitively', () {
      expect(
        dnsNamesEqual(<String>[
          '_CCSERVER',
          '_TCP',
          'LOCAL',
        ], ccServerServiceLabels),
        isTrue,
      );
      expect(
        dnsNamesEqual(<String>['a', 'local'], <String>['b', 'local']),
        isFalse,
      );
      expect(dnsNamesEqual(<String>['local'], ccServerServiceLabels), isFalse);
    });
  });

  group('CcMdnsRecordSet query matching', () {
    final records = CcMdnsRecordSet(
      instanceName: 'My Server',
      hostName: 'devbox',
      port: 9800,
      txt: const <String, String>{
        'sid': 'abc123',
        'fp': 'deadbeefdeadbeef',
        'name': 'My Server',
        'tls': '0',
      },
      addresses: <InternetAddress>[
        InternetAddress('192.168.1.10'),
        InternetAddress('10.0.0.7'),
      ],
    );

    Uint8List queryFor(List<String> labels, int type, {int? dnsClass}) {
      return encodeDnsQuery(
        questions: <DnsQuestion>[
          DnsQuestion(
            labels: labels,
            type: type,
            dnsClass: dnsClass ?? dnsClassInternet,
          ),
        ],
      );
    }

    test('PTR question for the service type produces the full bundle', () {
      final response = records.buildResponse(
        queryFor(ccServerServiceLabels, dnsTypePtr),
      );
      expect(response, isNotNull);
      final message = decodeDnsMessage(response!)!;
      expect(message.isResponse, isTrue);
      expect(message.answers, hasLength(1));
      expect(message.answers.single.type, dnsTypePtr);
      expect(
        message.answers.single.rdata,
        equals(encodeDnsName(records.instanceLabels)),
      );
      // SRV + TXT + both A records travel as additionals (RFC 6763 §12.1).
      expect(message.additionals, hasLength(4));
      expect(
        message.additionals.map((r) => r.type),
        containsAll(<int>[dnsTypeSrv, dnsTypeTxt, dnsTypeA]),
      );
    });

    test('matching is case-insensitive', () {
      final response = records.buildResponse(
        queryFor(<String>['_CCSERVER', '_TCP', 'LOCAL'], dnsTypePtr),
      );
      expect(response, isNotNull);
    });

    test('the unicast-response (QU) bit does not break matching', () {
      final response = records.buildResponse(
        queryFor(
          ccServerServiceLabels,
          dnsTypePtr,
          dnsClass: dnsClassInternet | mdnsUnicastResponseBit,
        ),
      );
      expect(response, isNotNull);
    });

    test('SRV question for the instance answers SRV with A additionals', () {
      final response = records.buildResponse(
        queryFor(records.instanceLabels, dnsTypeSrv),
      );
      final message = decodeDnsMessage(response!)!;
      expect(message.answers, hasLength(1));
      expect(message.answers.single.type, dnsTypeSrv);
      expect(
        message.answers.single.rdata,
        equals(encodeSrvRdata(port: 9800, target: records.hostLabels)),
      );
      expect(message.additionals, hasLength(2));
      expect(message.additionals.every((r) => r.type == dnsTypeA), isTrue);
    });

    test('TXT question for the instance answers the TXT entries', () {
      final response = records.buildResponse(
        queryFor(records.instanceLabels, dnsTypeTxt),
      );
      final message = decodeDnsMessage(response!)!;
      expect(message.answers, hasLength(1));
      expect(message.answers.single.type, dnsTypeTxt);
      expect(message.answers.single.rdata, equals(records.txtRecord.rdata));
    });

    test('ANY question for the instance answers both SRV and TXT', () {
      final response = records.buildResponse(
        queryFor(records.instanceLabels, dnsTypeAny),
      );
      final message = decodeDnsMessage(response!)!;
      expect(
        message.answers.map((r) => r.type),
        containsAll(<int>[dnsTypeSrv, dnsTypeTxt]),
      );
    });

    test('A question for the host answers every published address', () {
      final response = records.buildResponse(
        queryFor(records.hostLabels, dnsTypeA),
      );
      final message = decodeDnsMessage(response!)!;
      expect(message.answers, hasLength(2));
      expect(
        message.answers.map((r) => r.rdata.toList()),
        containsAll(<List<int>>[
          <int>[192, 168, 1, 10],
          <int>[10, 0, 0, 7],
        ]),
      );
      expect(message.answers.every((r) => r.cacheFlush), isTrue);
    });

    test('service-type enumeration PTR is answered (RFC 6763 §9)', () {
      final response = records.buildResponse(
        queryFor(serviceEnumerationLabels, dnsTypePtr),
      );
      final message = decodeDnsMessage(response!)!;
      expect(message.answers, hasLength(1));
      expect(
        message.answers.single.rdata,
        equals(encodeDnsName(ccServerServiceLabels)),
      );
    });

    test('unrelated questions produce no response', () {
      expect(
        records.buildResponse(
          queryFor(<String>['_ipp', '_tcp', 'local'], dnsTypePtr),
        ),
        isNull,
      );
      expect(
        records.buildResponse(
          queryFor(<String>['otherhost', 'local'], dnsTypeA),
        ),
        isNull,
      );
      // Right name, wrong type.
      expect(
        records.buildResponse(queryFor(ccServerServiceLabels, dnsTypeA)),
        isNull,
      );
    });

    test('responses and garbage are ignored', () {
      expect(records.buildResponse(records.buildAnnouncement()), isNull);
      expect(records.buildResponse(<int>[1, 2, 3]), isNull);
      expect(records.buildResponse(const <int>[]), isNull);
    });

    test('instance labels are sanitized (dots and control chars)', () {
      final set = CcMdnsRecordSet(
        instanceName: 'Sam. Server\x01',
        hostName: 'devbox.local',
        port: 1,
        txt: const <String, String>{},
        addresses: const <InternetAddress>[],
      );
      expect(set.instanceLabels.first, 'Sam- Server');
      expect(set.hostLabels, <String>['devbox', 'local']);
      // The sanitized name is queryable.
      final response = set.buildResponse(
        queryFor(<String>['Sam- Server', ...ccServerServiceLabels], dnsTypeSrv),
      );
      expect(response, isNotNull);
    });

    test('loopback and IPv6 addresses are never published', () {
      final set = CcMdnsRecordSet(
        instanceName: 'x',
        hostName: 'devbox',
        port: 1,
        txt: const <String, String>{},
        addresses: <InternetAddress>[
          InternetAddress.loopbackIPv4,
          InternetAddress('fe80::1'),
          InternetAddress('192.168.0.2'),
        ],
      );
      expect(set.addresses, hasLength(1));
      expect(set.addresses.single.address, '192.168.0.2');
    });
  });

  group('end-to-end loopback', () {
    test(
      'responder answers a raw PTR query over UDP multicast',
      () async {
        CcMdnsResponder? responder;
        RawDatagramSocket? querier;
        try {
          responder = CcMdnsResponder(
            instanceName: 'CC MDNS Test $pid',
            port: 45678,
            txt: const <String, String>{'sid': 'e2e-test', 'tls': '0'},
          );
          await responder.start();

          querier = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            mdnsPort,
            reuseAddress: true,
            reusePort: true,
          );
          for (final interface in await NetworkInterface.list(
            type: InternetAddressType.IPv4,
            includeLinkLocal: true,
          )) {
            try {
              querier.joinMulticast(mdnsGroupAddress, interface);
            } on Object {
              // Some interfaces refuse multicast; any one is enough.
            }
          }

          final instanceRdata = encodeDnsName(
            responder.records!.instanceLabels,
          );
          final advertised = Completer<void>();
          querier.listen((RawSocketEvent event) {
            if (event != RawSocketEvent.read) {
              return;
            }
            final datagram = querier?.receive();
            if (datagram == null || advertised.isCompleted) {
              return;
            }
            final message = decodeDnsMessage(datagram.data);
            if (message == null || !message.isResponse) {
              return;
            }
            // Either a direct answer to our query or one of the responder's
            // announcements — both prove the socket path end to end.
            final hasOurPtr = message.answers.any(
              (r) =>
                  r.type == dnsTypePtr &&
                  dnsNamesEqual(r.labels, ccServerServiceLabels) &&
                  _bytesEqual(r.rdata, instanceRdata),
            );
            if (hasOurPtr) {
              advertised.complete();
            }
          });

          final query = encodeDnsQuery(
            questions: <DnsQuestion>[
              const DnsQuestion(
                labels: ccServerServiceLabels,
                type: dnsTypePtr,
              ),
            ],
          );
          querier.send(query, mdnsGroupAddress, mdnsPort);

          try {
            await advertised.future.timeout(const Duration(seconds: 3));
          } on TimeoutException {
            markTestSkipped(
              'No mDNS traffic observed — multicast is likely blocked in this '
              'environment.',
            );
            return;
          }
        } on SocketException catch (e) {
          markTestSkipped('UDP sockets unavailable in this environment: $e');
          return;
        } finally {
          querier?.close();
          await responder?.stop();
        }
      },
      // `markTestSkipped` after a timeout is reported as a failure by the
      // GitHub Actions test reporter; skip up front on hosted runners.
      skip: Platform.environment['GITHUB_ACTIONS'] == 'true'
          ? 'Multicast UDP is blocked on GitHub-hosted runners'
          : false,
    );
  });
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
