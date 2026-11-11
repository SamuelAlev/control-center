import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/src/rpc/protocol.dart' show RpcErrorCodes;

/// Why the server refused someone the code of a repository in a space (file
/// tree, file content, diffs, a terminal, IDE data): their own forge sign-in
/// does not let them read it. Not being signed in at all is the separate
/// `needs_sign_in` refusal.
enum ForgeReadRefusal {
  /// Their forge account cannot read the repository.
  cannotRead('forge_cannot_read'),

  /// The forge could not be asked whether they can; refused until it
  /// answers.
  unconfirmed('forge_unconfirmed');

  const ForgeReadRefusal(this.kind);

  /// The `data.kind` a server answers with its unauthorized code.
  final String kind;
}

/// The forge read refusal an RPC error carries, or null for any other error.
///
/// Wire: `unauthorized` with `data: {kind: forge_cannot_read |
/// forge_unconfirmed}`, and `forge` (the forge's wire name) when the server
/// names it. The forge is null when it does not, so a client words the refusal
/// without a forge name rather than guessing one.
({ForgeReadRefusal reason, ForgeHost? forge})? forgeReadRefusalFromRpc({
  required int code,
  Object? data,
}) {
  if (code != RpcErrorCodes.unauthorized || data is! Map) {
    return null;
  }
  final named = ForgeHost.fromWire(data['forge'] as String?);
  final forge = named == ForgeHost.local ? null : named;
  for (final reason in ForgeReadRefusal.values) {
    if (reason.kind == data['kind']) {
      return (reason: reason, forge: forge);
    }
  }
  return null;
}
