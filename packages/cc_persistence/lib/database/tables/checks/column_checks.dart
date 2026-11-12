import 'package:drift/drift.dart';

/// `CHECK` expressions shared by the table classes.
///
/// A check is declared on the column (`text().check(isJson(payloadJson))()`)
/// so the rule lives in the schema: a row that breaks it is refused by SQLite
/// whichever code path wrote it. drift copies the expression into the
/// generated database library, which is why these helpers and the
/// `*StoredValues` classes beside them are imported there.
///
/// A `CHECK` passes when its expression is NULL, so none of these needs a
/// separate case for a nullable column.

/// The column holds well-formed JSON.
Expression<bool> isJson(Expression<String> column) =>
    FunctionCallExpression<bool>('json_valid', [column]);

/// The column holds well-formed JSON or the empty string.
///
/// Only for a column whose "nothing" has always been written as `''`: new
/// columns use NULL for that and [isJson].
Expression<bool> isJsonOrEmpty(Expression<String> column) =>
    column.equals('') | isJson(column);

/// The column holds a JSON object (`{…}`), not merely any JSON value.
Expression<bool> isJsonObject(Expression<String> column) =>
    isJson(column) &
    FunctionCallExpression<String>('json_type', [column]).equals('object');

/// The column holds a JSON array (`[…]`), not merely any JSON value.
Expression<bool> isJsonArray(Expression<String> column) =>
    isJson(column) &
    FunctionCallExpression<String>('json_type', [column]).equals('array');
