import 'package:cc_domain/core/domain/entities/agent.dart';

/// The `AGENT.md` the agent editor writes for [agent]: front matter naming it,
/// its title, its manager and its skills, then its persona (or a stub when it
/// has none).
String buildAgentMarkdown(Agent agent) {
  final buf = StringBuffer();
  buf.writeln('---');
  buf.writeln('name: ${agent.name}');
  buf.writeln('title: ${agent.title}');
  if (agent.reportsTo != null && agent.reportsTo!.isNotEmpty) {
    buf.writeln('reportsTo: ${agent.reportsTo}');
  }
  if (agent.skills.isNotEmpty) {
    buf.writeln('skills:');
    for (final skill in agent.skills.toList()) {
      buf.writeln('  - $skill');
    }
  }
  buf.writeln('---');
  buf.writeln();
  if (agent.persona != null && agent.persona!.isNotEmpty) {
    buf.writeln(agent.persona);
  } else {
    buf.writeln('# ${agent.title}');
    buf.writeln();
    buf.writeln('Agent profile for **${agent.name}**.');
  }
  return buf.toString();
}
