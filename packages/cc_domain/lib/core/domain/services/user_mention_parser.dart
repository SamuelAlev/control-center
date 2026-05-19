import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';

/// Minimal workspace-member projection used for mention resolution — kept
/// decoupled from the full `User`/`WorkspaceMember` join so this parser has
/// no persistence dependency of its own.
typedef MentionableMember = ({String id, String handle, String displayName});

/// User (human) mention parser — the human-mention counterpart to
/// [AgentMentionParser] (PRD 16 §15: `@mentions` resolve to **principals**,
/// humans and agents alike, not just agents).
///
/// `MessagingService.sendAndDispatch` first resolves `@token`s against the
/// workspace's agents; any token that does not match an agent is handed here
/// to resolve against the workspace's human members by handle. A resolved
/// human mention never dispatches anything — unlike an agent mention, it
/// exists purely so the notification router (PRD 16 §7) can ping the
/// mentioned person.
class UserMentionParser {
  /// Creates a new [UserMentionParser].
  const UserMentionParser();

  /// Resolves `@handle` tokens in [text] against [members].
  ///
  /// Matches case-insensitively: an exact handle match first, then a
  /// handle-prefix match — mirroring [AgentMentionParser]'s agent-name
  /// matching so the two parsers read as one convention. Tokens already
  /// listed in [excludeTokens] (lower-cased; e.g. ones already claimed by an
  /// agent mention) are skipped so one `@word` never resolves to two
  /// different principals. Returns the distinct matched members, deduplicated
  /// by id.
  List<MentionableMember> resolveMentions(
    String text,
    List<MentionableMember> members, {
    Set<String> excludeTokens = const {},
  }) {
    if (members.isEmpty) {
      return const [];
    }
    final tokens = RegExp(r'@(\w+)')
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .where((t) => !excludeTokens.contains(t));
    final resolved = <String, MentionableMember>{};
    for (final token in tokens) {
      final member = members
          .where(
            (m) =>
                m.handle.toLowerCase() == token ||
                m.handle.toLowerCase().startsWith(token),
          )
          .firstOrNull;
      if (member != null) {
        resolved[member.id] = member;
      }
    }
    return resolved.values.toList(growable: false);
  }
}
