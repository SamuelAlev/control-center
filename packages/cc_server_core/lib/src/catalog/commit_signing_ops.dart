import 'package:cc_domain/cc_domain.dart' show RepoOpKind, ValidationException;
import 'package:cc_host/cc_host.dart' show RepoOp, SessionCapability;
import 'package:cc_server_core/src/identity/commit_signing_keys.dart';

/// `credentials.commitSigningKey`, `credentials.createCommitSigningKey` and
/// `credentials.deleteCommitSigningKey`: the caller's own commit signing key
/// (see [CommitSigningKeys]).
///
/// Self-service: every op is about `ctx.userId` and nobody else, so there is
/// no workspace, role or argument that could name another person's key. Only
/// the public half ever leaves the server; the person adds it to their forge
/// account themselves, as a signing key. Creating and deleting need a full
/// client: a companion phone can show the key, never mint or remove one.
/// Empty when no store is wired (demo).
List<RepoOp> buildCommitSigningOps(CommitSigningKeys? keys) {
  if (keys == null) {
    return const [];
  }

  Map<String, Object?> wire(CommitSigningKeyInfo? info) => {
    'key': info == null
        ? null
        : {
            'public_key': info.publicKey,
            'fingerprint': info.fingerprint,
            'created_at': info.createdAt.toIso8601String(),
          },
  };

  return [
    RepoOp(
      name: 'credentials.commitSigningKey',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => wire(await keys.describe(ctx.userId)),
    ),
    RepoOp(
      name: 'credentials.createCommitSigningKey',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        try {
          return wire(await keys.create(ctx.userId));
        } on StateError {
          throw const ValidationException(
            'You already have a commit signing key. Delete it first to '
            'replace it.',
          );
        }
      },
    ),
    RepoOp(
      name: 'credentials.deleteCommitSigningKey',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async => {'deleted': await keys.delete(ctx.userId)},
    ),
  ];
}
