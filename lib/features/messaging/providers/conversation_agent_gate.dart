import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';

/// Whether [participants] include an agent, the only thing that answers a
/// message. A space of humans alone has nothing to start work with.
bool spaceHasAgent(List<SpaceParticipant> participants) =>
    participants.any((p) => p.participantType == PrincipalType.agent);

/// How many agents [submission] mentions, picked from the menu or typed as
/// `@name`.
///
/// Typed tokens are matched the way the server resolves them: the name, or a
/// prefix of it. An `@token` naming nobody is not a mention here, so a team
/// handle or a path pasted into a message counts for nothing.
int agentMentionCount(
  ComposerSubmission submission, {
  required List<Agent> roster,
}) {
  final names = [for (final a in roster) a.name.toLowerCase()];
  final typed = const AgentMentionParser()
      .parseMentions(submission.text)
      .where((token) => names.any((name) => name.startsWith(token)));
  return submission.mentions.where((m) => m.kind == 'agent').length +
      typed.length;
}

/// Whether sending [submission] into a space with no agent reaches one.
///
/// True when it mentions an agent, so the mention adds the agent and dispatches
/// it. Slash commands pass too: the composer handles its own, and the rest are
/// the server's to answer.
bool submissionReachesAnAgent(
  ComposerSubmission submission, {
  required List<Agent> roster,
}) =>
    agentMentionCount(submission, roster: roster) > 0 ||
    parseSlashCommand(submission.text.trim()).isCommand;
