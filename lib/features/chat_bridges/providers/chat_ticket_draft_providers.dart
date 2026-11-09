import 'package:cc_data/cc_data.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The caller's ticket drafts from chat in the active workspace.
///
/// Watched because a draft arrives from a chat command (`/cc ticket …`), not
/// from this client. Empty for a read-only member: the server only lets
/// someone who can create tickets hold drafts, so subscribing would only be
/// refused.
final chatTicketDraftsProvider = StreamProvider<List<ChatTicketDraftView>>((
  ref,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final role = ref.watch(myWorkspaceRoleProvider(workspaceId));
  if (role == null || !role.canWrite) {
    return Stream.value(const []);
  }
  return ref.watch(chatClientProvider).watchTicketDrafts(workspaceId);
});

/// Creates or discards the caller's ticket drafts.
///
/// The state is keyed by draft id, so one row's failure or spinner never
/// shows on another. A finished action drops its entry: the draft itself
/// leaves the watched list, and with it the row.
class ChatTicketDraftController
    extends Notifier<Map<String, AsyncValue<void>>> {
  @override
  Map<String, AsyncValue<void>> build() => const {};

  RpcChatClient get _client => ref.read(chatClientProvider);

  /// Creates the backlog ticket [draftId] proposes with the corrected
  /// [title] and [description], returning it, or null when it failed (the
  /// row shows why).
  Future<ChatCreatedTicket?> confirm(
    String draftId, {
    required String title,
    required String description,
  }) => _run(
    draftId,
    (workspaceId) => _client.confirmTicketDraft(
      workspaceId: workspaceId,
      draftId: draftId,
      title: title,
      description: description,
    ),
  );

  /// Drops [draftId] without creating anything.
  Future<void> discard(String draftId) async {
    await _run<void>(
      draftId,
      (workspaceId) => _client.discardTicketDraft(workspaceId, draftId),
    );
  }

  Future<T?> _run<T>(
    String draftId,
    Future<T> Function(String workspaceId) action,
  ) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || (state[draftId]?.isLoading ?? false)) {
      return null;
    }
    _put(draftId, const AsyncLoading());
    try {
      final result = await action(workspaceId);
      state = {...state}..remove(draftId);
      return result;
    } on Object catch (e, st) {
      _put(draftId, AsyncError(e, st));
      return null;
    }
  }

  void _put(String draftId, AsyncValue<void> value) =>
      state = {...state, draftId: value};
}

/// Actions on the caller's ticket drafts.
final chatTicketDraftControllerProvider =
    NotifierProvider<ChatTicketDraftController, Map<String, AsyncValue<void>>>(
      ChatTicketDraftController.new,
    );
