import 'package:cc_data/cc_data.dart' show RemoteConfirmationRepository;
import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long "approve for a while" lasts. Deliberately a fixed, short window
/// rather than a picker: the point is to stop a burst of identical prompts,
/// not to let someone quietly grant a long-lived exemption from a dialog.
/// The server clamps it regardless.
const int kApprovalRememberSeconds = 8 * 60 * 60;

/// The RPC-backed repository for host-global agent-action approvals.
///
/// Backs the desktop/web approval surface, mirroring the phone's
/// (`cc_remote`) responder: it reads the SERVER's live pending queue and
/// resolves entries. The server publishes a request whenever an agent hits an
/// approval-gated action and blocks until a decision arrives (the registry has
/// no timeout — see `PendingConfirmationRegistry`).
final confirmationRepositoryProvider = Provider<RemoteConfirmationRepository>(
  (ref) => RemoteConfirmationRepository(ref.watch(rpcClientProvider)),
);

/// Live pending agent-action approvals across all workspaces (host-global). Each
/// entry is a privileged action an agent is blocked on until the user approves
/// or denies. Empty when nothing awaits a decision.
final pendingConfirmationsProvider =
    StreamProvider.autoDispose<List<ConfirmationRequestDto>>(
      (ref) => ref.watch(confirmationRepositoryProvider).watchPending(),
    );

/// The route to the conversation [request] is blocking, or null when there is
/// nowhere to go (the request names no space, or no workspace is known).
///
/// The queue is host-global, so the request's own workspace wins over
/// [activeWorkspaceId]: a request from another workspace must not open a
/// space id under the one being viewed. The route targets the blocked
/// conversation's own tab, where the inline prompt lives, not whichever
/// conversation of the space is standing.
String? confirmationConversationRoute(
  ConfirmationRequestDto request, {
  required String? activeWorkspaceId,
}) {
  final workspaceId = request.workspaceId ?? activeWorkspaceId;
  if (workspaceId == null || request.spaceId.isEmpty) {
    return null;
  }
  final conversationId = request.conversationId;
  return spaceRoute(
    workspaceId,
    request.spaceId,
    tab: conversationId == null || conversationId.isEmpty
        ? null
        : conversationTabKey(conversationId),
  );
}

/// Whether the approval card leads with "approve for a while" instead of a
/// one-time approve, on this device.
///
/// The card keeps both, one as its button and the other behind the caret.
/// Picking the one behind the caret is the person saying which they reach
/// for, so it trades places and leads from then on. It only orders the two
/// choices: every approval is still a click, and a request the server will
/// not remember offers the one-time approve alone.
final approvalPrefersRememberProvider =
    NotifierProvider<ApprovalPrefersRememberNotifier, bool>(
      ApprovalPrefersRememberNotifier.new,
    );

/// Reads and writes [approvalPrefersRememberProvider] to [AppPreferences].
class ApprovalPrefersRememberNotifier extends Notifier<bool> {
  late AppPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getBool(approvalPrefersRememberKey) ?? false;
  }

  /// Persists which choice leads.
  void set({required bool remember}) {
    if (state == remember) {
      return;
    }
    _prefs.setBool(approvalPrefersRememberKey, value: remember);
    state = remember;
  }
}
