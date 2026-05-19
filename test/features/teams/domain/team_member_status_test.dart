import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show RunLiveness;
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart'
    show AgentStatus;
import 'package:cc_domain/features/teams/domain/services/team_member_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveTeamMemberStatus precedence', () {
    test('archived always wins', () {
      expect(
        deriveTeamMemberStatus(
          archived: true,
          runtimeStatus: AgentStatus.running,
          liveness: RunLiveness.alive,
          activeTicketCount: 5,
        ),
        TeamMemberStatus.archived,
      );
    });

    test('working wins over runtime health (active tickets)', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: null,
          liveness: RunLiveness.looping,
          activeTicketCount: 1,
        ),
        TeamMemberStatus.working,
      );
    });

    test('running runtime → working', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: AgentStatus.running,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.working,
      );
    });

    test('aborted runtime → unstable', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: AgentStatus.aborted,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.unstable,
      );
    });

    test('unhealthy liveness (idle but stalled) → unstable', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: AgentStatus.idle,
          liveness: RunLiveness.stalled,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.unstable,
      );
    });

    test('absent from registry → offline', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: null,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.offline,
      );
    });

    test('parked → offline', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: AgentStatus.parked,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.offline,
      );
    });

    test('idle + healthy → idle', () {
      expect(
        deriveTeamMemberStatus(
          archived: false,
          runtimeStatus: AgentStatus.idle,
          liveness: RunLiveness.completed,
          activeTicketCount: 0,
        ),
        TeamMemberStatus.idle,
      );
    });
  });
}
