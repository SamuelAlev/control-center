// Seam for the conversation working-tree diff provider.
//
// Desktop reads the diff straight off the local CoW worktrees (DAO + `git diff`,
// `conversation_changes_provider_io.dart`). Web has no local worktree, so it
// asks the server — which owns the checkouts — to compute the diff over RPC
// (`conversation_changes_provider_web.dart` → the `conversation.changes` op),
// returning the same `List<PrFile>`. The panel that renders it is identical on
// both platforms (it just watches `conversationChangesProvider`).
export 'conversation_changes_provider_io.dart'
    if (dart.library.js_interop) 'conversation_changes_provider_web.dart';
