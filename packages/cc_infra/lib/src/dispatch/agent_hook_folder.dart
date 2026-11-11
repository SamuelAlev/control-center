import 'package:path/path.dart' as p;

/// Where the server owner puts an agent's shell hooks: under the server's
/// data directory, outside every workspace's storage.
///
/// A workspace's storage is `<data dir>/<workspace id>` and a workspace id
/// starts with a letter or digit, so a folder named with a leading `_` can
/// never be one. The fs ops are confined to the workspace's own folder, a
/// repository may not point into the data directory, and every sandbox hides
/// the data directory, so no client op, run or member terminal can write
/// here. There is no op that writes it: the owner creates
/// `<data dir>/_agent_hooks/<workspace id>/<agent slug>/hooks.json` and the
/// scripts it names by hand on the host.
const agentHooksFolderName = '_agent_hooks';

/// `<dataDir>/_agent_hooks`.
String agentHooksRoot(String dataDir) => p.join(dataDir, agentHooksFolderName);

/// The hook folder for the agent whose config dir is [agentConfigDir] in
/// [workspaceId], under [root]; null when either is missing or is not a
/// single plain path segment.
String? agentHookFolder(
  String? root, {
  required String? workspaceId,
  required String? agentConfigDir,
}) {
  if (root == null || root.isEmpty || agentConfigDir == null) {
    return null;
  }
  final slug = p.basename(p.normalize(agentConfigDir));
  bool plain(String? segment) =>
      segment != null &&
      segment.isNotEmpty &&
      segment != '.' &&
      segment != '..' &&
      p.basename(segment) == segment &&
      !segment.contains(r'\');
  if (!plain(workspaceId) || !plain(slug)) {
    return null;
  }
  return p.join(root, workspaceId, slug);
}
