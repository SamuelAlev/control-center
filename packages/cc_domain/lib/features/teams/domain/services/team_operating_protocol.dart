import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/services/team_roster.dart';

/// Assembles the **hard operating protocol** a team leader receives when work
/// is routed to its team. This is a fixed behavioural contract — not a
/// user-configurable persona — that defines the coordinator role, the
/// stop-after-dispatch discipline, and the mandatory evaluation step.
///
/// The protocol is prepended to the leader's dispatch prompt. It is intentionally
/// directive: the leader does not do the work itself, it delegates to the
/// best-suited member (chosen from the skill-surfaced `buildTeamRoster`),
/// records its decision, and stops.
class TeamOperatingProtocol {
  const TeamOperatingProtocol._();

  /// The fixed coordinator briefing. [team]'s name and optional free-form
  /// [Team.instructions] are interpolated; the roster (built by
  /// `buildTeamRoster`) is appended so the leader can delegate by capability.
  static String build({
    required Team team,
    required List<TeamMember> members,
    required Map<String, Agent> agentsById,
    String? ticketId,
  }) {
    final roster = buildTeamRoster(
      team: team,
      members: members,
      agentsById: agentsById,
    );
    final ticketLine = ticketId != null
        ? 'The request is tracked as ticket `$ticketId`. '
        : '';

    final buf = StringBuffer()
      ..writeln(
        '# Team operating protocol — you are the leader of '
        '"${team.name}"',
      )
      ..writeln()
      ..writeln(
        'You are the **coordinator** for this team. ${ticketLine}You '
        'do NOT do the work yourself. Your job is to route the request to '
        'the single best-suited member and then stop.',
      )
      ..writeln()
      ..writeln('## Contract')
      ..writeln(
        '1. **Read the request** and the roster below. Pick the ONE '
        'member whose assigned skills best match the work. Match by '
        'capability (skills/role), never by guessing from names.',
      )
      ..writeln(
        '2. **Delegate** to that member by replying with their mention '
        'link (copy it verbatim from the roster). State precisely what you '
        'need them to do and the definition of done.',
      )
      ..writeln(
        '3. **Stop after dispatch.** Once you have delegated, do not '
        'keep working, do not poll, do not do the task yourself. You will be '
        're-woken when the member responds or finishes.',
      )
      ..writeln(
        '4. **Evaluate.** When the member reports back, call '
        '`record_team_activity` with the ticket id and an outcome of '
        '`action` (you delegated / are delegating further), `no_action` '
        '(nothing more to do — the work is complete or out of scope), or '
        '`failed` (the member could not complete it). This evaluation is '
        '**mandatory** — it both records the decision and prevents you from '
        'being re-woken in a loop.',
      )
      ..writeln(
        '5. If no member fits, record `no_action` with a short reason '
        'rather than forcing a poor match.',
      );

    if (team.instructions != null && team.instructions!.trim().isNotEmpty) {
      buf
        ..writeln()
        ..writeln('## Team instructions')
        ..writeln(team.instructions!.trim());
    }

    buf
      ..writeln()
      ..writeln(roster);

    return buf.toString().trimRight();
  }
}
