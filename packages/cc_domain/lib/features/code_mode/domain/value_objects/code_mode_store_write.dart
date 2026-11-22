import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';

/// One `store(key, value)` a script made, buffered on the host until the
/// script succeeds.
class CodeModeStoreWrite {
  /// Creates a write. [valueJson] is the value as JSON text, or null to
  /// delete the key (`store(key, undefined)`).
  const CodeModeStoreWrite({required this.key, this.valueJson});

  /// The key.
  final String key;

  /// The value as JSON text, or null for a delete.
  final String? valueJson;

  /// Whether this removes the key.
  bool get isDelete => valueJson == null;

  @override
  bool operator ==(Object other) =>
      other is CodeModeStoreWrite &&
      other.key == key &&
      other.valueJson == valueJson;

  @override
  int get hashCode => Object.hash(key, valueJson);

  @override
  String toString() => 'CodeModeStoreWrite($key)';
}

/// The caps on stored values, applied in one place so the host (which
/// rejects an oversized `store()` while the script runs) and the repository
/// (which commits the batch) cannot disagree.
///
/// Sizes are UTF-8 bytes. The total counts keys and values of one
/// conversation and agent.
// ignore: avoid_classes_with_only_static_members
abstract final class CodeModeStoreRules {
  /// Why one write is refused, or null when it is acceptable on its own.
  static String? checkWrite(CodeModeStoreWrite write) {
    if (write.key.isEmpty) {
      return 'store() needs a non-empty key.';
    }
    final keyBytes = utf8Length(write.key);
    if (keyBytes > CodeModeLimits.maxStoreKeyBytes) {
      return 'store() key is $keyBytes bytes; the limit is '
          '${CodeModeLimits.maxStoreKeyBytes}.';
    }
    final value = write.valueJson;
    if (value != null) {
      final valueBytes = utf8Length(value);
      if (valueBytes > CodeModeLimits.maxStoreValueBytes) {
        return 'store("${write.key}") value is $valueBytes bytes as JSON; the '
            'limit is ${CodeModeLimits.maxStoreValueBytes} per value.';
      }
    }
    return null;
  }

  /// The bytes [values] occupy: keys plus values.
  static int totalBytes(Map<String, String> values) {
    var total = 0;
    values.forEach((key, value) {
      total += utf8Length(key) + utf8Length(value);
    });
    return total;
  }

  /// [current] with [writes] applied in order, last write per key winning.
  ///
  /// Throws [ValidationException] (code `code_mode_store_limit`) when a write
  /// breaks a per-value cap or the result is over
  /// [CodeModeLimits.maxStoreTotalBytes]; nothing is applied then.
  static Map<String, String> apply(
    Map<String, String> current,
    Iterable<CodeModeStoreWrite> writes,
  ) {
    final next = Map<String, String>.of(current);
    for (final write in writes) {
      final problem = checkWrite(write);
      if (problem != null) {
        throw ValidationException(problem, code: 'code_mode_store_limit');
      }
      final value = write.valueJson;
      if (value == null) {
        next.remove(write.key);
      } else {
        next[write.key] = value;
      }
    }
    final total = totalBytes(next);
    if (total > CodeModeLimits.maxStoreTotalBytes) {
      throw ValidationException(
        'Stored values would take $total bytes; the limit is '
        '${CodeModeLimits.maxStoreTotalBytes} per conversation and agent.',
        code: 'code_mode_store_limit',
      );
    }
    return next;
  }
}
