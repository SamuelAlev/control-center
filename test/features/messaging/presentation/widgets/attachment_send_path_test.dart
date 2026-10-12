import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_space_sends_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ComposerAttachment _image(String name) => ComposerAttachment(
  id: 'picker:$name',
  kind: 'image',
  label: name,
  path: '/tmp/$name',
  bytes: const [1, 2, 3],
  mimeType: 'image/png',
  refName: name,
  fileId: 'file-$name',
  blobRef:
      'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  uploadState: AttachmentUploadState.ready,
);

void main() {
  // Same class of silent loss, different trigger: a message typed while the
  // space was still provisioning was parked, and the queue carried only the
  // words.
  group('the provisioning queue parks attachments with the words', () {
    late ProviderContainer container;
    late PendingSpaceSendsNotifier queue;

    setUp(() {
      // The notifier's `build` watches the space's provisioning status, so it
      // needs a real container; the status is pinned to `provisioning` so the
      // queue never auto-flushes mid-assertion.
      container = ProviderContainer(
        overrides: [
          spaceProvisioningStatusProvider.overrideWith(
            (ref, _) => SpaceProvisioningStatus.provisioning,
          ),
        ],
      );
      queue = container.read(pendingSpaceSendsProvider('space-1').notifier);
    });

    tearDown(() => container.dispose());

    test('keeps attachments on the parked send', () {
      queue.enqueue(
        workspaceId: 'workspace-a',
        content: 'what is wrong here',
        attachments: [_image('a.png'), _image('b.png')],
      );
      expect(queue.state, hasLength(1));
      expect(queue.state.single.attachments.map((a) => a.label), [
        'a.png',
        'b.png',
      ]);
      expect(queue.state.single.attachments.first.fileId, 'file-a.png');
      expect(
        queue.state.single.attachments.first.blobRef,
        'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      expect(queue.state.single.attachments.first.bytes, isNull);
      expect(queue.state.single.attachments.first.path, isNull);
    });

    test('a picture with no words is still a message worth parking', () {
      queue.enqueue(
        workspaceId: 'workspace-a',
        content: '   ',
        attachments: [_image('a.png')],
      );
      expect(queue.state, hasLength(1));
      expect(queue.state.single.content, isEmpty);
    });

    test('nothing at all is still dropped', () {
      queue.enqueue(workspaceId: 'workspace-a', content: '   ');
      expect(queue.state, isEmpty);
    });

    test('carries mentions and refs alongside', () {
      queue.enqueue(
        workspaceId: 'workspace-a',
        content: 'ship it',
        structuredMentions: [
          const StructuredMention(agentId: 'a1', raw: '@dev'),
        ],
        entityRefs: [const EntityRef(type: EntityRefType.ticket, id: 't1')],
        attachments: [_image('a.png')],
      );
      final parked = queue.state.single;
      expect(parked.structuredMentions, hasLength(1));
      expect(parked.entityRefs, hasLength(1));
      expect(parked.attachments, hasLength(1));
    });
  });
}
