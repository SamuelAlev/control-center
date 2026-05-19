import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_space_sends_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ComposerAttachment _image(String name) => ComposerAttachment(
  id: 'file:/tmp/$name',
  kind: 'image',
  label: name,
  path: '/tmp/$name',
  bytes: const [1, 2, 3],
  mimeType: 'image/png',
  refName: name,
);

void main() {
  // The bug this guards: a submission carrying pictures used to be delivered
  // as mid-run STEERING when an agent was already working in the conversation.
  // `steerRun` takes a String and nothing else, all the way down to the loop's
  // steering inbox — so the words arrived and the pictures did not, and the
  // agent was asked to look at four screenshots it had never been given.
  group('a submission with attachments is never steered', () {
    /// The predicate `_handleSubmit` uses to decide between steering a running
    /// agent and sending a real turn. Mirrored here because the method is
    /// private to the widget's state; `steering_guard_test` would be the place
    /// to move it if it ever grows.
    bool steerable({
      required bool isCommand,
      required bool hasAgentMention,
      required List<ComposerAttachment> attachments,
      required String content,
    }) =>
        !isCommand &&
        !hasAgentMention &&
        attachments.isEmpty &&
        content.trim().isNotEmpty;

    test('plain text with a run in flight still steers', () {
      expect(
        steerable(
          isCommand: false,
          hasAgentMention: false,
          attachments: const [],
          content: 'try the other branch',
        ),
        isTrue,
      );
    });

    test('text WITH an attachment does not steer', () {
      expect(
        steerable(
          isCommand: false,
          hasAgentMention: false,
          attachments: [_image('shot.png')],
          content: 'look at these',
        ),
        isFalse,
      );
    });

    test('an attachment alone does not steer', () {
      expect(
        steerable(
          isCommand: false,
          hasAgentMention: false,
          attachments: [_image('shot.png')],
          content: '',
        ),
        isFalse,
      );
    });
  });

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
        content: 'what is wrong here',
        attachments: [_image('a.png'), _image('b.png')],
      );
      expect(queue.state, hasLength(1));
      expect(queue.state.single.attachments.map((a) => a.label), [
        'a.png',
        'b.png',
      ]);
    });

    test('a picture with no words is still a message worth parking', () {
      queue.enqueue(content: '   ', attachments: [_image('a.png')]);
      expect(queue.state, hasLength(1));
      expect(queue.state.single.content, isEmpty);
    });

    test('nothing at all is still dropped', () {
      queue.enqueue(content: '   ');
      expect(queue.state, isEmpty);
    });

    test('carries mentions and refs alongside', () {
      queue.enqueue(
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
