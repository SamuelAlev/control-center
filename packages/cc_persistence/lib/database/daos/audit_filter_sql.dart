import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:drift/drift.dart';

/// The SQL predicate of [filter] over one audit table's columns, shared by
/// the workspace and server trails so both answer the same filter the same
/// way.
///
/// [searchColumns] are the machine columns the text search matches. A store
/// with no [countryCode] column records no country, so a country filter
/// matches none of its rows. A store with no [outcome] column holds only
/// calls that returned, so its rows are all [AuditOutcome.ok].
Expression<bool> auditFilterPredicate(
  AuditLogFilter filter, {
  required GeneratedColumn<String> userId,
  required GeneratedColumn<String> ip,
  required GeneratedColumn<DateTime> createdAt,
  required List<GeneratedColumn<String>> searchColumns,
  GeneratedColumn<String>? countryCode,
  GeneratedColumn<String>? outcome,
}) {
  Expression<bool> expr = const Constant(true);
  if (filter.actorIds.isNotEmpty) {
    expr = expr & userId.isIn(filter.actorIds);
  }
  if (filter.outcomes.isNotEmpty) {
    if (outcome == null) {
      if (!filter.outcomes.contains(AuditOutcome.ok)) {
        return const Constant(false);
      }
    } else {
      expr = expr & outcome.isIn([for (final o in filter.outcomes) o.name]);
    }
  }
  final address = filter.ip;
  if (address != null && address.isNotEmpty) {
    expr = expr & ip.equals(address);
  }
  if (filter.filtersCountry) {
    if (countryCode == null) {
      return const Constant(false);
    }
    final country = filter.countryCode;
    if (country != null && country.isNotEmpty) {
      expr = expr & countryCode.equals(country);
    }
    if (filter.localNetwork) {
      expr = expr & ip.isNotNull() & countryCode.isNull();
    }
  }
  for (final condition in filter.time) {
    final at = condition.at;
    expr =
        expr &
        switch (condition.op) {
          AuditTimeOperator.atOrAfter => createdAt.isBiggerOrEqualValue(at),
          AuditTimeOperator.after => createdAt.isBiggerThanValue(at),
          AuditTimeOperator.before => createdAt.isSmallerThanValue(at),
          AuditTimeOperator.atOrBefore => createdAt.isSmallerOrEqualValue(at),
        };
  }
  final needle = auditSearchNeedle(filter.query);
  final names = filter.searchUserIds.where((id) => id.isNotEmpty).toList();
  if (needle != null || names.isNotEmpty) {
    Expression<bool>? text;
    if (needle != null) {
      final pattern = '%$needle%';
      for (final column in searchColumns) {
        final match = column.lower().like(pattern);
        text = text == null ? match : text | match;
      }
    }
    if (names.isNotEmpty) {
      final byName = userId.isIn(names);
      text = text == null ? byName : text | byName;
    }
    expr = expr & text!;
  }
  return expr;
}

/// Rows that sort strictly older than [cursor] in `(createdAt, id)` order.
Expression<bool> auditOlderThan(
  GeneratedColumn<DateTime> createdAt,
  GeneratedColumn<String> id,
  ActivityCursor cursor,
) {
  final at = cursor.createdAt;
  return createdAt.isSmallerThanValue(at) |
      (createdAt.equals(at) & id.isSmallerThanValue(cursor.id));
}

/// Rows that sort strictly newer than [cursor] in `(createdAt, id)` order.
Expression<bool> auditNewerThan(
  GeneratedColumn<DateTime> createdAt,
  GeneratedColumn<String> id,
  ActivityCursor cursor,
) {
  final at = cursor.createdAt;
  return createdAt.isBiggerThanValue(at) |
      (createdAt.equals(at) & id.isBiggerThanValue(cursor.id));
}
