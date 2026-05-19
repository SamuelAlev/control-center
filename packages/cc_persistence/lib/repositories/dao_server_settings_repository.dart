import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_persistence/database/daos/server_setting_dao.dart';

/// DAO-backed [ServerSettingsRepository] over the global database.
class DaoServerSettingsRepository implements ServerSettingsRepository {
  /// Creates a [DaoServerSettingsRepository] over the global DAO.
  DaoServerSettingsRepository(this._dao);

  /// Largest accepted value, in UTF-8 bytes.
  static const int maxValueBytes = 64 * 1024;

  /// Largest number of distinct keys the install may hold.
  static const int maxKeys = 256;

  final ServerSettingDao _dao;

  @override
  Future<String?> get(String key) => _dao.getValue(key);

  @override
  Future<Map<String, String>> getAll() async {
    final rows = await _dao.getAll();
    return {for (final row in rows) row.key: row.value};
  }

  @override
  Stream<Map<String, String>> watchAll() =>
      _dao.watchAll().map((rows) => {for (final r in rows) r.key: r.value});

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await _dao.deleteValue(key);
      return;
    }
    if (key.isEmpty) {
      throw const ValidationException('Setting key must not be empty.');
    }
    final bytes = utf8.encode(value).length;
    if (bytes > maxValueBytes) {
      throw ValidationException(
        'Setting "$key" is $bytes bytes, over the $maxValueBytes-byte limit.',
      );
    }
    if (await _dao.getValue(key) == null && (await _dao.getAll()).length >= maxKeys) {
      throw ValidationException(
        'Server setting limit reached ($maxKeys keys); cannot add "$key".',
      );
    }
    await _dao.setValue(key, value);
  }
}
