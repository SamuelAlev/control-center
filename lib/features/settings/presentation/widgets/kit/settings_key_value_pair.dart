import 'package:flutter/foundation.dart';

/// One row of a `SettingsKeyValueEditor`.
@immutable
class SettingsKeyValuePair {
  /// Creates a [SettingsKeyValuePair].
  const SettingsKeyValuePair(this.key, this.value);

  /// The left-hand side (a group name, an env var name).
  final String key;

  /// The right-hand side (a role, a value).
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsKeyValuePair && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}
