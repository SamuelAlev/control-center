import 'dart:async';

import 'package:control_center/features/messaging/providers/space_attachment_upload_provider.dart';
import 'package:control_center/shared/widgets/composer/attachment_upload_controller.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _blobA =
    'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _blobB =
    'blob:sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

ComposerAttachment _attachment({int? size, List<int>? bytes}) =>
    ComposerAttachment(
      id: 'picker:1',
      kind: 'file',
      label: 'report #1.txt',
      bytes: bytes,
      sizeBytes: size,
      mimeType: 'text/plain',
    );

Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  test('over-limit attachment fails before network I/O', () async {
    var calls = 0;
    final service = SpaceAttachmentUploadService(
      workspaceId: 'ws-1',
      uploadUrl: 'https://host.test/blob',
      discardFile: (_, _) async {},
      post: (uri, {headers, body}) async {
        calls++;
        return http.Response('{}', 200);
      },
    );
    await expectLater(
      service.upload(
        _attachment(size: SpaceAttachmentUploadService.maxBytes + 1),
      ),
      throwsA(
        isA<AttachmentUploadException>().having(
          (e) => e.reason,
          'reason',
          AttachmentUploadError.tooLarge,
        ),
      ),
    );
    expect(calls, 0);
  });

  test('missing catalog identity never reports ready', () async {
    final service = SpaceAttachmentUploadService(
      workspaceId: 'ws-1',
      uploadUrl: 'https://host.test/blob',
      discardFile: (_, _) async {},
      post: (uri, {headers, body}) async => http.Response(
        '{\"ref\":\"$_blobA\",\"bytes\":3,\"media_type\":\"text/plain\"}',
        200,
      ),
    );
    await expectLater(
      service.upload(_attachment(bytes: [1, 2, 3])),
      throwsA(
        isA<AttachmentUploadException>().having(
          (e) => e.reason,
          'reason',
          AttachmentUploadError.transfer,
        ),
      ),
    );
  });

  test(
    'late completion after remove discards without reviving the draft',
    () async {
      final pending = Completer<UploadedAttachment>();
      final discarded = <String>[];
      final config = AttachmentUploadConfiguration(
        upload: (_) => pending.future,
        discard: (id) async {
          discarded.add(id);
        },
      );
      final container = ProviderContainer();
      final subscription = container.listen(
        attachmentUploadControllerProvider(config),
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(
        attachmentUploadControllerProvider(config).notifier,
      );
      controller.add(_attachment(bytes: [1]));
      expect(
        container
            .read(attachmentUploadControllerProvider(config))['picker:1']
            ?.uploadState,
        AttachmentUploadState.uploading,
      );
      controller.remove('picker:1');
      pending.complete(
        const UploadedAttachment(
          fileId: 'file-1',
          blobRef: _blobA,
          bytes: 1,
          mediaType: 'text/plain',
        ),
      );
      await _turn();
      expect(
        container.read(attachmentUploadControllerProvider(config)),
        isEmpty,
      );
      expect(discarded, ['file-1']);
    },
  );

  test(
    'failed upload retries, but release never discards successful file',
    () async {
      var attempts = 0;
      final discarded = <String>[];
      final config = AttachmentUploadConfiguration(
        upload: (_) async {
          attempts++;
          if (attempts == 1) {
            throw const AttachmentUploadException(
              AttachmentUploadError.transfer,
            );
          }
          return const UploadedAttachment(
            fileId: 'file-2',
            blobRef: _blobB,
            bytes: 1,
            mediaType: 'text/plain',
          );
        },
        discard: (id) async {
          discarded.add(id);
        },
      );
      final container = ProviderContainer();
      final subscription = container.listen(
        attachmentUploadControllerProvider(config),
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(
        attachmentUploadControllerProvider(config).notifier,
      );
      controller.add(_attachment(bytes: [1]));
      await _turn();
      expect(
        container
            .read(attachmentUploadControllerProvider(config))['picker:1']
            ?.uploadState,
        AttachmentUploadState.failed,
      );
      controller.retry('picker:1');
      await _turn();
      expect(
        container
            .read(attachmentUploadControllerProvider(config))['picker:1']
            ?.fileId,
        'file-2',
      );
      expect(
        container
            .read(attachmentUploadControllerProvider(config))['picker:1']
            ?.uploadState,
        AttachmentUploadState.ready,
      );
      controller.release('picker:1');
      expect(attempts, 2);
      expect(discarded, isEmpty);
    },
  );
}
