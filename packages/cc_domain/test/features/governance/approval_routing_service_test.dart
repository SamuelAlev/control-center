import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/services/approval_routing_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';
import 'package:test/test.dart';

void main() {
  const routing = ApprovalRoutingService();
  final createdAt = DateTime(2026, 7, 7, 12);

  WorkspaceMember member(String userId, WorkspaceRole role) => WorkspaceMember(
    id: 'm-$userId',
    workspaceId: 'ws-1',
    userId: userId,
    role: role,
    joinedAt: createdAt,
  );

  final members = [
    member('omar', WorkspaceRole.owner),
    member('ada', WorkspaceRole.admin),
    member('mia', WorkspaceRole.member),
    member('vera', WorkspaceRole.viewer),
  ];

  Approval approval() => Approval(
    id: 'ap-1',
    workspaceId: 'ws-1',
    title: 'Merge the release',
    requestedByActorType: 'user',
    requestedById: 'mia',
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  group('tierFor', () {
    const policy = ApprovalRoutingPolicy(
      escalationTimeout: Duration(minutes: 30),
    );

    test('starts at tier 0 and escalates one tier per elapsed timeout', () {
      expect(
        routing.tierFor(
          createdAt: createdAt,
          now: createdAt.add(const Duration(minutes: 29)),
          policy: policy,
        ),
        0,
      );
      expect(
        routing.tierFor(
          createdAt: createdAt,
          now: createdAt.add(const Duration(minutes: 31)),
          policy: policy,
        ),
        1,
      );
      expect(
        routing.tierFor(
          createdAt: createdAt,
          now: createdAt.add(const Duration(minutes: 61)),
          policy: policy,
        ),
        2,
      );
    });

    test('caps at the last tier', () {
      expect(
        routing.tierFor(
          createdAt: createdAt,
          now: createdAt.add(const Duration(days: 2)),
          policy: policy,
        ),
        ApprovalRoutingService.tierCount - 1,
      );
    });
  });

  group('targetsFor', () {
    test('requestingUser mode asks the requesting member first', () {
      final targets = routing.targetsFor(
        approval: approval(),
        policy: const ApprovalRoutingPolicy(),
        members: members,
        tier: 0,
        requestingUserId: 'mia',
      );
      expect(targets, ['mia']);
    });

    test('an unknown requesting user falls through to the admins', () {
      final targets = routing.targetsFor(
        approval: approval(),
        policy: const ApprovalRoutingPolicy(),
        members: members,
        tier: 0,
        requestingUserId: null,
      );
      expect(targets.toSet(), {'omar', 'ada'});
    });

    test('tier 1 asks every admin; tier 2 the owner alone', () {
      expect(
        routing
            .targetsFor(
              approval: approval(),
              policy: const ApprovalRoutingPolicy(),
              members: members,
              tier: 1,
              requestingUserId: 'mia',
            )
            .toSet(),
        {'omar', 'ada'},
      );
      expect(
        routing.targetsFor(
          approval: approval(),
          policy: const ApprovalRoutingPolicy(),
          members: members,
          tier: 2,
          requestingUserId: 'mia',
        ),
        ['omar'],
      );
    });

    test('owner mode asks only the owner from the start', () {
      final targets = routing.targetsFor(
        approval: approval(),
        policy: const ApprovalRoutingPolicy(mode: ApprovalRoutingMode.owner),
        members: members,
        tier: 0,
        requestingUserId: 'mia',
      );
      expect(targets, ['omar']);
    });
  });
}
