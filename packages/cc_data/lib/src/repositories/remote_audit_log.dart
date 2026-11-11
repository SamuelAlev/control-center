import 'package:cc_domain/core/domain/ports/audit_log_port.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [AuditLogPort] over RPC: subscribes to `audit.watchLog`.
class RemoteAuditLog implements AuditLogPort {
  /// Creates the adapter over [_client].
  const RemoteAuditLog(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<AuditLogPageDto> watchPage(AuditLogQuery query) => _client
      .subscribe('audit.watchLog', query.toArgs())
      .map(AuditLogPageDto.fromJson);
}
