import 'package:cc_domain/core/domain/ports/server_notice_feed.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [ServerNoticeFeed] over RPC: `server.notices`.
class RemoteServerNotices implements ServerNoticeFeed {
  /// Creates the adapter over [_client].
  const RemoteServerNotices(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<ServerNotice>> open() async {
    final data = await _client.call('server.notices', const {});
    return [
      for (final raw in (data['notices'] as List?) ?? const [])
        if (raw is Map) ?serverNoticeFromWire(raw.cast<String, dynamic>()),
    ];
  }
}

/// One `server.notices` entry, or null when its kind is unknown to this
/// build or a required field is missing: such a notice is left out rather
/// than rendered half-understood.
ServerNotice? serverNoticeFromWire(Map<String, dynamic> wire) {
  final kindWire = wire['kind'];
  final subject = wire['subject'];
  final rawCreatedAt = wire['created_at'];
  final createdAt = rawCreatedAt is String
      ? DateTime.tryParse(rawCreatedAt)
      : null;
  ServerNoticeKind? kind;
  for (final candidate in ServerNoticeKind.values) {
    if (candidate.wire == kindWire) {
      kind = candidate;
    }
  }
  if (kind == null ||
      subject is! String ||
      subject.isEmpty ||
      createdAt == null) {
    return null;
  }
  final detail = wire['detail'];
  return ServerNotice(
    kind: kind,
    subject: subject,
    detail: detail is String ? detail : '',
    createdAt: createdAt,
  );
}
