import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart';

/// The audit log (`audit.watchLog`): one live, newest-first table of the
/// server trail and every workspace trail the caller administers. The server
/// decides which trails a person reads; [AuditLogPageDto.scopes] says which
/// ones that was.
abstract interface class AuditLogPort {
  /// Live page for [query]. Re-emits as records land.
  Stream<AuditLogPageDto> watchPage(AuditLogQuery query);
}
