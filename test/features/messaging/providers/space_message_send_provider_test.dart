import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _blob =
    'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'send metadata uses only staged catalog identity and content reference',
    () {
      final container = ProviderContainer(
        overrides: [isDemoServerProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      final stored = container
          .read(spaceMessageSendProvider.notifier)
          .attachmentMetadata([
            const ComposerAttachment(
              id: 'picker:1',
              kind: 'file',
              label: 'raw report.txt',
              refName: 'report.txt',
              path: '/Users/me/Desktop/raw report.txt',
              bytes: [1, 2, 3],
              mimeType: 'text/plain',
              sizeBytes: 3,
              fileId: 'file-1',
              blobRef: _blob,
              uploadState: AttachmentUploadState.ready,
            ),
          ]);
      expect(stored.single['fileId'], 'file-1');
      expect(stored.single['path'], _blob);
      expect(stored.single['name'], 'report.txt');
      expect(stored.single.containsKey('localPath'), isFalse);
      expect(stored.single.containsKey('bytes'), isFalse);
    },
  );

  test('unfinished client file cannot be silently sent as a path', () {
    final container = ProviderContainer(
      overrides: [isDemoServerProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    expect(
      () =>
          container.read(spaceMessageSendProvider.notifier).attachmentMetadata([
            const ComposerAttachment(
              id: 'picker:2',
              kind: 'file',
              label: 'draft.txt',
              path: '/Users/me/draft.txt',
              uploadState: AttachmentUploadState.failed,
            ),
          ]),
      throwsStateError,
    );
  });

  test(
    'server-side @file path survives; @task never pretends to be a blob',
    () {
      final container = ProviderContainer(
        overrides: [isDemoServerProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      final entries = container
          .read(spaceMessageSendProvider.notifier)
          .attachmentMetadata([
            const ComposerAttachment(
              id: 'file:/server/repo/file.dart',
              kind: 'file',
              label: 'file.dart',
              path: '/server/repo/file.dart',
              payload: {'path': '/server/repo/file.dart', 'isDirectory': false},
            ),
            const ComposerAttachment(
              id: 'scratchpad:ws-1',
              kind: 'scratchpad',
              label: 'notes',
              payload: {'scratchpadId': 'ws-1'},
            ),
          ]);
      expect(entries, hasLength(1));
      expect(entries.single['path'], '/server/repo/file.dart');
      expect(entries.single.containsKey('fileId'), isFalse);
    },
  );
}
