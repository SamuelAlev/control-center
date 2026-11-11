import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/forge_read_refusal.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed, SignInNeed, TokenSignInNeed, needsSignIn;
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Why a space could not be opened, in words, with the sign-in that fixes it
/// when the refusal is `needs_sign_in`; null for anything that is not a
/// refusal, which the caller words its own way.
///
/// A space is readable only by a member who holds a read grant and forge
/// read on every repository it uses, so opening one is refused the way the
/// code ops refuse: by `data.kind`, never by message. Not signed in to the
/// forge, the forge account cannot read one of them (or the forge could not
/// confirm it), a repository was replaced, or no read grant
/// (`repo_grant_required`). Each names the forge when `data.forge` does.
({String message, SignInNeed? signIn})? spaceAccessFailureOf(
  AppLocalizations l10n,
  Object error,
) {
  final forge = spaceForgeAccessFailureOf(l10n, error);
  if (forge != null) {
    return forge;
  }
  // No read grant on one of its repositories; an uncoded refusal is not this.
  return isRepoGrantRefusal(error)
      ? (message: l10n.spaceAccessNoGrant, signIn: null)
      : null;
}

/// The part of [spaceAccessFailureOf] that follows the person's own forge
/// account (signed in, can read, confirmed, not replaced); null for the
/// read-grant refusal and anything else.
({String message, SignInNeed? signIn})? spaceForgeAccessFailureOf(
  AppLocalizations l10n,
  Object error,
) {
  final need = needsSignIn(error);
  if (need != null) {
    final provider = switch (need) {
      LaneSignInNeed(:final lane) => signInProviderName(lane),
      TokenSignInNeed(:final forge) => forge.displayName,
    };
    return (message: l10n.spaceAccessNeedsSignIn(provider), signIn: need);
  }
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.unauthorized) {
    return null;
  }
  final data = error.data;
  final refusal = forgeReadRefusalFromRpc(code: error.code, data: data);
  if (refusal != null) {
    final forge = refusal.forge?.displayName;
    final message = switch (refusal.reason) {
      ForgeReadRefusal.cannotRead =>
        forge == null
            ? l10n.spaceAccessForgeCannotReadUnnamed
            : l10n.spaceAccessForgeCannotRead(forge),
      ForgeReadRefusal.unconfirmed =>
        forge == null
            ? l10n.repoCodeForgeUnconfirmedUnnamed
            : l10n.repoCodeForgeUnconfirmed(forge),
    };
    return (message: message, signIn: null);
  }
  final kind = data is Map ? data['kind'] : null;
  if (kind == repoReplacedKind) {
    final named = ForgeHost.fromWire((data as Map)['forge'] as String?);
    return (
      message: named == ForgeHost.local
          ? l10n.repoCodeRepoReplaced
          : l10n.repoCodeRepoReplacedOn(named.displayName),
      signIn: null,
    );
  }
  return null;
}
