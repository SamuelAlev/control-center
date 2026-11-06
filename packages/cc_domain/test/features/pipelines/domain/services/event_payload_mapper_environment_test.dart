import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/environment_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026);

  final events = <DomainEvent>[
    SpaceArchived(spaceId: 'space-1', workspaceId: 'ws-1', occurredAt: at),
    SpaceProvisioningChanged(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      status: SpaceProvisioningStatus.ready,
      occurredAt: at,
    ),
    PrHeadChanged(
      repoOwner: 'acme',
      repoName: 'shop',
      prNumber: 7,
      prTitle: 'Add checkout',
      previousHeadSha: 'aaa',
      headSha: 'bbb',
      workspaceId: 'ws-1',
      occurredAt: at,
    ),
    EnvironmentStatusChanged(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      environmentId: 'env-1',
      status: 'ready',
      occurredAt: at,
    ),
    EnvironmentReady(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      environmentId: 'env-1',
      url: 'https://shop.test',
      occurredAt: at,
    ),
    EnvironmentDestroyed(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      environmentId: 'env-1',
      occurredAt: at,
    ),
    EnvironmentProcessExited(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      environmentId: 'env-1',
      componentId: 'web',
      exitCode: 137,
      occurredAt: at,
    ),
  ];

  test('every environment event is known and carries its workspace', () {
    // A known type with no payload shows up as a trigger that never fires, and
    // a payload with no workspace_id would fire triggers in every workspace.
    for (final event in events) {
      expect(
        EventPayloadMapper.knownEventTypes,
        contains(EventPayloadMapper.typeName(event)),
      );
      expect(EventPayloadMapper.toPayload(event)?['workspace_id'], 'ws-1');
    }
  });

  test('payloads carry what a step needs', () {
    expect(EventPayloadMapper.toPayload(events[1])?['status'], 'ready');
    expect(EventPayloadMapper.toPayload(events[2]), {
      'workspace_id': 'ws-1',
      'repo_owner': 'acme',
      'repo_name': 'shop',
      'pr_number': 7,
      'pr_title': 'Add checkout',
      'previous_head_sha': 'aaa',
      'head_sha': 'bbb',
    });
    expect(
      EventPayloadMapper.toPayload(events[4])?['url'],
      'https://shop.test',
    );
    expect(EventPayloadMapper.toPayload(events[6]), {
      'workspace_id': 'ws-1',
      'space_id': 'space-1',
      'environment_id': 'env-1',
      'component_id': 'web',
      'exit_code': 137,
    });
  });

  test('a ready event without a url omits the key', () {
    final payload = EventPayloadMapper.toPayload(
      EnvironmentReady(
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        environmentId: 'env-1',
        occurredAt: at,
      ),
    );
    expect(payload, isNot(contains('url')));
  });

  test('dedup keys follow what makes an event distinct', () {
    expect(EventPayloadMapper.dedupKeyFor(events[1]), 'space-1:ready');
    expect(EventPayloadMapper.dedupKeyFor(events[2]), 'acme/shop#7:bbb');
    expect(EventPayloadMapper.dedupKeyFor(events[3]), 'env-1:ready');
    expect(EventPayloadMapper.dedupKeyFor(events[4]), 'env-1');
    expect(EventPayloadMapper.dedupKeyFor(events[5]), 'env-1');
    // Each exit is its own occurrence, and archiving has nothing to collapse.
    expect(EventPayloadMapper.dedupKeyFor(events[0]), isNull);
    expect(EventPayloadMapper.dedupKeyFor(events[6]), isNull);
  });
}
