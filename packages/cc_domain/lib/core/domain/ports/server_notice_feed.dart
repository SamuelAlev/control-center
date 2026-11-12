import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';

/// The server owner's open notices, as a client reads them
/// (`server.notices`).
///
/// Read-only on purpose: a notice is raised and closed by the server (a
/// workspace whose file failed its check, then a restore that replaced it),
/// never by a client. Only the server owner may read it; anyone else is
/// refused, so a client asks only when it knows it is the owner.
abstract interface class ServerNoticeFeed {
  /// Every open notice of a kind this build knows, oldest first.
  ///
  /// A notice of a kind a newer server added is left out rather than shown
  /// as a row this build cannot word.
  Future<List<ServerNotice>> open();
}
