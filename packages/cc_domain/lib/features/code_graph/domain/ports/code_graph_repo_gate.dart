/// Whether the code graph of [repoId] may be read in [workspaceId]: the
/// repository is linked to the workspace and the server still serves its
/// checkout. A repository whose stored path is refused keeps its index (a
/// relink makes it valid again and re-indexes it), but it is neither searched
/// nor listed in results until then.
typedef CodeGraphRepoGate =
    Future<bool> Function(String workspaceId, String repoId);
