/// Any line that already claims an agent opened or edited the pull request,
/// however the agent formatted it.
final RegExp _agentPrMarkerLine = RegExp(
  r'^[ \t>*_]*(?:Opened|Edited) by a Control Center agent\b.*$',
  caseSensitive: false,
  multiLine: true,
);

/// A line saying an agent opened the pull request.
final RegExp _agentPrOpenedLine = RegExp(
  r'^[ \t>*_]*Opened by a Control Center agent\b.*$',
  caseSensitive: false,
  multiLine: true,
);

/// The line every pull request a Control Center agent opens ends with: one
/// opened at [requesterLogin]'s request (their forge login), or one nobody
/// asked for. [edited] is the line a description an agent rewrote on a pull
/// request it did not open ends with instead.
///
/// A pull request an agent opens for a person is authored by that person on
/// the forge (their own downscoped token), so the forge alone cannot tell a
/// reader that an agent wrote it. The marker says so, and names who asked.
String agentPullRequestMarker({String? requesterLogin, bool edited = false}) {
  final login = requesterLogin?.trim() ?? '';
  final verb = edited ? 'Edited' : 'Opened';
  return login.isEmpty
      ? '_$verb by a Control Center agent._'
      : '_$verb by a Control Center agent at the request of @$login._';
}

/// Whether [body] says an agent opened its pull request.
bool hasAgentOpenedMarker(String body) => _agentPrOpenedLine.hasMatch(body);

/// [body] ending with exactly one [agentPullRequestMarker]: any marker line
/// already in it, the agent's own wording included, is replaced by the
/// server's, so a body cannot name someone else as the requester.
String withAgentPullRequestMarker(
  String body, {
  String? requesterLogin,
  bool edited = false,
}) {
  final marker = agentPullRequestMarker(
    requesterLogin: requesterLogin,
    edited: edited,
  );
  final stripped = body.replaceAll(_agentPrMarkerLine, '').trimRight();
  return stripped.isEmpty ? marker : '$stripped\n\n$marker';
}
