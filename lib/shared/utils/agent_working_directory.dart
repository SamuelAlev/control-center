/// Working directory from agent md path.
String workingDirectoryFromAgentMdPath(String agentMdPath) {
  if (agentMdPath.isEmpty) {
    return '/tmp';
  }

  final lastSep = agentMdPath.lastIndexOf('/');
  if (lastSep > 0) {
    return agentMdPath.substring(0, lastSep);
  }
  return '/tmp';
}

