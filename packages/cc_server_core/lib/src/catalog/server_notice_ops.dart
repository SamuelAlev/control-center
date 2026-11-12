import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_host/cc_host.dart';

/// `server.notices`: what the server owner has to act on, oldest first.
///
/// Owner-only: a notice names workspaces by id and carries SQLite's own
/// finding about their files, which no workspace member should read about
/// another workspace. Empty when the host wires no [notices] (the demo).
List<RepoOp> buildServerNoticeOps({required ServerNoticeRepository? notices}) {
  if (notices == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'server.notices',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      serverAuthority: ServerAuthority.serverOwner,
      handler: (ctx) async => {
        'notices': [for (final notice in await notices.open()) notice.toWire()],
      },
    ),
  ];
}
