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

/// Whether sending [submission] into a space with no agent reaches one.
///
/// True when it mentions an agent, picked from the menu or typed as `@name`
/// (matched the way the server resolves it: the name, or a prefix of it), so
/// the mention adds the agent and dispatches it. Slash commands pass too: the
/// composer handles its own, and the rest are the server's to answer.
bool submissionReachesAnAgent(
  ComposerSubmission submission, {
  required List<Agent> roster,
}) {
  if (submission.mentions.any((m) => m.kind == 'agent')) {
    return true;
  }
  final text = submission.text.trim();
  if (parseSlashCommand(text).isCommand) {
    return true;
  }
  final names = [for (final a in roster) a.name.toLowerCase()];
  return const AgentMentionParser()
      .parseMentions(text)
      .any((token) => names.any((n) => n == token || n.startsWith(token)));
}
