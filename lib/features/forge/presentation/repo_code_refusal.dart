import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/forge_read_refusal.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show
        LaneSignInNeed,
        SignInNeed,
        TokenSignInNeed,
        kNeedsSignInKind,
        needsSignIn;
import 'package:control_center/l10n/app_localizations.dart';

/// The `data.kind` of a refusal to act on a linked repository whose path now
/// names a different repository on its forge, until an admin relinks it.
const String repoReplacedKind = 'repo_replaced';

/// The `data.kind` of a refusal for want of a repository grant; `data.level`
/// says which the caller lacks (`read`, `review` or `write`).
const String repoGrantRequiredKind = 'repo_grant_required';

/// The `data.kind` of a refusal to drive a rig that carries somebody else's
/// own credentials: only the person it was opened for may drive it.
const String rigHolderOnlyKind = 'rig_holder_only';

/// Whether [error] is the refusal to drive a rig that is somebody else's
/// (`rig_holder_only`).
bool isRigHolderOnlyRefusal(Object error) =>
    error is RemoteRpcException &&
    error.code == RpcErrorCodes.unauthorized &&
    error.data is Map &&
    (error.data as Map)['kind'] == rigHolderOnlyKind;

/// Whether [error] is the refusal for want of a grant on a repository, at
/// [level] when given (`read`, `review` or `write`).
bool isRepoGrantRefusal(Object error, {String? level}) {
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.unauthorized) {
    return false;
  }
  final data = error.data;
  return data is Map &&
      data['kind'] == repoGrantRequiredKind &&
      (level == null || data['level'] == level);
}

/// Whether [error] refuses access to a space's repositories by kind: no
/// grant (`repo_grant_required`), the person's own forge account cannot read
/// one or the forge could not confirm it, a sign-in the forge needs, or a
/// repository replaced on its forge. An uncoded `unauthorized` is not one.
bool isRepoAccessRefusal(Object error) {
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.unauthorized) {
    return false;
  }
  final data = error.data;
  final kind = data is Map ? data['kind'] : null;
  return kind == repoGrantRequiredKind ||
      kind == repoReplacedKind ||
      kind == kNeedsSignInKind ||
      ForgeReadRefusal.values.any((reason) => reason.kind == kind);
}

/// A refusal to show a repository's code (file tree, file content, diffs, a
/// terminal in a space, IDE data), in words, or null for any other error.
///
/// Read by `data.kind`, never by message text: no read or write grant on
/// the repository (`repo_grant_required`), the person's own forge
/// account cannot read the repository, the forge could not confirm that it
/// can, or the repository was replaced and needs relinking. Each names the
/// forge when `data.forge` does, and words it without one otherwise. Not being signed
/// in at all (`needs_sign_in`) is offered as a sign-in elsewhere.
String? repoCodeRefusalMessage(AppLocalizations l10n, Object error) {
  if (error is! RemoteRpcException) {
    return null;
  }
  final data = error.data;
  if (error.code == RpcErrorCodes.unauthorized &&
      data is Map &&
      data['kind'] == repoReplacedKind) {
    final named = ForgeHost.fromWire(data['forge'] as String?);
    return named == ForgeHost.local
        ? l10n.repoCodeRepoReplaced
        : l10n.repoCodeRepoReplacedOn(named.displayName);
  }
  // No Control Center grant on the repository: to read it, or to change it
  // (save, revert, commit, push, publish, sync, checkout, stack moves).
  // A machine carrying somebody else's sign-ins is driven only by them.
  if (isRigHolderOnlyRefusal(error)) {
    return l10n.rigHolderOnly;
  }
  // `review` appears only on ops that declare it (approving, requesting
  // changes); any level this client does not know reads as the read grant.
  if (isRepoGrantRefusal(error)) {
    return switch ((data as Map)['level']) {
      'write' => l10n.repoCodeNoWriteGrant,
      'review' => l10n.repoCodeNoReviewGrant,
      _ => l10n.repoCodeNoReadGrant,
    };
  }
  final refusal = forgeReadRefusalFromRpc(code: error.code, data: data);
  if (refusal == null) {
    return null;
  }
  final forge = refusal.forge?.displayName;
  return switch (refusal.reason) {
    ForgeReadRefusal.cannotRead =>
      forge == null
          ? l10n.repoCodeForgeCannotReadUnnamed
          : l10n.repoCodeForgeCannotRead(forge),
    ForgeReadRefusal.unconfirmed =>
      forge == null
          ? l10n.repoCodeForgeUnconfirmedUnnamed
          : l10n.repoCodeForgeUnconfirmed(forge),
  };
}

/// [repoCodeRefusalMessage] for an error that may be absent: what a failed
/// repository change (save, commit, push, publish, sync, checkout, a stack
/// move) says when the server refused it by kind, else null for the caller's
/// own failure copy.
String? repoRefusalOf(AppLocalizations l10n, Object? error) =>
    error == null ? null : repoCodeRefusalMessage(l10n, error);

/// A refused code read in words, with the sign-in that fixes it when the
/// refusal is `needs_sign_in`; null for any other error, which the caller
/// words its own way.
///
/// The one reading behind every code view (the Explorer's tree and searches,
/// a file, a diff), so a member meets the same sentence wherever their own
/// forge account decides what they may read.
({String message, SignInNeed? signIn})? repoCodeFailureOf(
  AppLocalizations l10n,
  Object error,
) {
  final need = needsSignIn(error);
  if (need != null) {
    final provider = switch (need) {
      LaneSignInNeed(:final lane) => signInProviderName(lane),
      TokenSignInNeed(:final forge) => forge.displayName,
    };
    return (message: l10n.repoCodeNeedsSignIn(provider), signIn: need);
  }
  final message = repoCodeRefusalMessage(l10n, error);
  return message == null ? null : (message: message, signIn: null);
}
