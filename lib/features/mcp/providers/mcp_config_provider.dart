import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/mcp/domain/mcp_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final mcpConfigProvider = NotifierProvider<McpConfigNotifier, McpConfig>(
  McpConfigNotifier.new,
);

class McpConfigNotifier extends Notifier<McpConfig> {
  static const _portKey = 'mcp_port';
  static const _tokenKey = 'mcp_token';
  static const _enabledKey = 'mcp_enabled';

  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;

  @override
  McpConfig build() {
    _prefs = ref.read(sharedPreferencesProvider);
    _secureStorage = ref.read(secureStorageProvider);
    final token = _prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      _secureStorage.write(key: _tokenKey, value: token);
      _prefs.remove(_tokenKey);
    }
    return McpConfig(
      port: _prefs.getInt(_portKey) ?? 9020,
      token: '',
      enabled: _prefs.getBool(_enabledKey) ?? true,
    );
  }

  Future<void> _loadToken() async {
    final token = await _secureStorage.read(key: _tokenKey) ?? '';
    state = McpConfig(port: state.port, token: token, enabled: state.enabled);
  }

  Future<void> setPort(int port) async {
    await _prefs.setInt(_portKey, port);
    state = McpConfig(port: port, token: state.token, enabled: state.enabled);
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secureStorage.delete(key: _tokenKey);
    } else {
      await _secureStorage.write(key: _tokenKey, value: token);
    }
    state = McpConfig(port: state.port, token: token, enabled: state.enabled);
  }

  Future<void> setEnabled({required bool enabled}) async {
    await _prefs.setBool(_enabledKey, enabled);
    state = McpConfig(port: state.port, token: state.token, enabled: enabled);
  }

  Future<McpConfig> loadFullConfig() async {
    await _loadToken();
    return state;
  }
}
