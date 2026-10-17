@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = RemoteMediaEndpoint(
    httpBase: Uri.parse('https://app.example/phone/_cc_resource/capability/'),
    deviceId: 'phone-device',
    psk: 'paired-secret',
  );
  final picked = PickedAttachment(
    name: 'résumé & plan (final).png',
    bytes: Uint8List.fromList([0, 10, 255]),
    mediaType: 'image/png',
  );

  test(
    'uploads original encoded filename and retains catalog id and blob ref',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'file_id': 'catalog-file-42',
            'ref': 'blob:sha256:${'a' * 64}',
          }),
          200,
        );
      });
      addTearDown(client.close);

      final stored = await uploadAttachment(
        picked: picked,
        workspaceId: 'workspace/one',
        endpoint: endpoint,
        order: 3,
        client: client,
      );

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.url.queryParameters['w'], 'workspace/one');
      expect(
        request.headers['x-cc-file-name'],
        Uri.encodeComponent(picked.name),
      );
      expect(request.headers['content-type'], 'image/png');
      expect(request.bodyBytes, picked.bytes);
      expect(stored.fileId, 'catalog-file-42');
      expect(stored.id, 'catalog-file-42');
      expect(stored.path, 'blob:sha256:${'a' * 64}');
      expect(stored.order, 3);
      expect(stored.toJson()['fileId'], 'catalog-file-42');
    },
  );

  test('failed upload leaves picked bytes in draft for retry', () async {
    final draft = ConversationDraft();
    addTearDown(draft.dispose);
    final pending = DraftAttachment(picked);
    draft.attachments.add(pending);
    var attempts = 0;
    final client = MockClient((_) async {
      attempts++;
      return attempts == 1
          ? http.Response('temporarily unavailable', 503)
          : http.Response(
              jsonEncode({'file_id': 'retried-id', 'ref': 'blob:retried'}),
              200,
            );
    });
    addTearDown(client.close);

    await expectLater(
      uploadAttachment(
        picked: pending.picked,
        workspaceId: 'ws',
        endpoint: endpoint,
        order: 0,
        client: client,
      ),
      throwsA(isA<http.ClientException>()),
    );
    expect(draft.attachments, contains(same(pending)));
    expect(pending.picked.bytes, [0, 10, 255]);
    expect(pending.stored, isNull);
    expect(draft.ready, isFalse);

    pending.stored = await uploadAttachment(
      picked: pending.picked,
      workspaceId: 'ws',
      endpoint: endpoint,
      order: 0,
      client: client,
    );
    expect(attempts, 2);
    expect(pending.stored!.fileId, 'retried-id');
    expect(draft.ready, isTrue);
  });

  test(
    'successful HTTP response without catalog file id cannot be sent',
    () async {
      final draft = ConversationDraft();
      addTearDown(draft.dispose);
      final pending = DraftAttachment(picked);
      draft.attachments.add(pending);
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'ref': 'blob:orphan'}), 200),
      );
      addTearDown(client.close);

      await expectLater(
        uploadAttachment(
          picked: pending.picked,
          workspaceId: 'ws',
          endpoint: endpoint,
          order: 0,
          client: client,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(pending.stored, isNull);
      expect(draft.attachments.single.picked, same(picked));
      expect(draft.ready, isFalse);
    },
  );
}
