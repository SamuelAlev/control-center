import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:dio/dio.dart';

/// Claude Code usage via `GET https://api.anthropic.com/api/oauth/usage`.
///
/// Reads the OAuth access token from `~/.claude/.credentials.json` (or an
/// explicit `CLAUDE_CONFIG_DIR` / [SubscriptionUsageAccount.configDir]),
/// falling back to the macOS Keychain. An explicit config dir is exclusive:
/// falling back to `~/.claude` or the keychain would silently report a
/// different account's quota.
class ClaudeUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [ClaudeUsageStrategy].
  ClaudeUsageStrategy({
    required this._dio,
    required Map<String, String> environment,
    String? homeDir,
    this.readClaudeKeychain = true,
  }) : _env = environment,
       _home = homeDir,
       super(providerId: 'claude', displayName: 'Claude');

  final Dio _dio;
  final Map<String, String> _env;
  final String? _home;

  /// Whether to fall back to the macOS Keychain for the Claude token (disabled
  /// in tests to keep them independent of the host's real Claude Code login).
  final bool readClaudeKeychain;

  static const _usageUrl = 'https://api.anthropic.com/api/oauth/usage';
  static const _beta = 'oauth-2025-04-20';
  // The usage endpoint aggressively rate-limits callers without a recognised
  // Claude Code User-Agent (returns persistent 429s), so we send one.
  static const _userAgent = 'claude-code/2.1.0';

  String? get _homeDir => _home ?? _env['HOME'] ?? _env['USERPROFILE'];

  @override
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account) async {
    try {
      final explicit = account.accessToken?.trim();
      final token = (explicit != null && explicit.isNotEmpty)
          ? explicit
          : await _readToken(configDir: account.configDir);
      if (token == null || token.isEmpty) {
        return unconfigured('Sign in to Claude Code to see usage.');
      }
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(_usageUrl),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer $token',
            'anthropic-beta': _beta,
            'User-Agent': _userAgent,
          },
          sendTimeout: SubscriptionUsageStrategy.requestTimeout,
          receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
        ),
      );
      final data = resp.data ?? const {};
      final windows = <SubscriptionWindow>[];
      void add(String key, String wid, String label) {
        final w = data[key];
        if (w is! Map) {
          return;
        }
        final util = (w['utilization'] as num?)?.toDouble();
        if (util == null) {
          return;
        }
        windows.add(
          SubscriptionWindow(
            id: wid,
            label: label,
            usedFraction: (util / 100).clamp(0.0, 1.0),
            resetsAt: parseIso(w['resets_at']),
          ),
        );
      }

      add('five_hour', '5h', 'Session');
      add('seven_day', '7d', 'Weekly');
      // An account billed per token rather than on a plan reports NO windows
      // — `five_hour` and `seven_day` come back null — and a dollar balance
      // instead. Reading only the windows told that operator "no usage
      // reported" for an account they were actively spending on.
      final spend = SubscriptionSpend.fromJson(
        (data['spend'] as Map?)?.cast<String, dynamic>(),
      );
      if (windows.isEmpty && spend == null) {
        return unconfigured('No usage reported.');
      }
      return ok(windows, spend: spend);
    } catch (e) {
      return error(shortError(e));
    }
  }

  /// Reads the Claude Code OAuth access token from `.credentials.json`,
  /// falling back to the macOS Keychain (Claude Code 2.1+ stores the same JSON
  /// blob there). Returns null when unavailable.
  Future<String?> _readToken({String? configDir}) async {
    final home = _homeDir;
    final dir = configDir ?? _env['CLAUDE_CONFIG_DIR'];
    // An EXPLICIT config dir is exclusive: it names one account, and falling
    // back to `~/.claude` or the keychain would silently report a different
    // account's quota next to that account's name.
    final candidates = <String>[
      if (dir != null && dir.isNotEmpty) '$dir/.credentials.json',
      if (configDir == null && home != null) '$home/.claude/.credentials.json',
    ];
    for (final path in candidates) {
      final token = _tokenFromCredentialsBlob(await _readFileOrNull(path));
      if (token != null) {
        return token;
      }
    }
    if (configDir == null && readClaudeKeychain && Platform.isMacOS) {
      return _readKeychain();
    }
    return null;
  }

  Future<String?> _readKeychain() async {
    for (final service in const ['Claude Code-credentials', 'claudeAiOauth']) {
      try {
        final r = await Process.run('security', [
          'find-generic-password',
          '-s',
          service,
          '-w',
        ]).timeout(const Duration(seconds: 5));
        if (r.exitCode != 0) {
          continue;
        }
        final out = (r.stdout as String).trim();
        if (out.isEmpty) {
          continue;
        }
        final token = _tokenFromCredentialsBlob(out);
        if (token != null) {
          return token;
        }
      } catch (_) {
        // Keychain unavailable / denied — fall through to the next service.
      }
    }
    return null;
  }

  /// Extracts `claudeAiOauth.accessToken` from a credentials JSON blob.
  String? _tokenFromCredentialsBlob(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      final oauth = json is Map ? json['claudeAiOauth'] : null;
      final token = oauth is Map ? oauth['accessToken'] : null;
      if (token is String && token.isNotEmpty) {
        return token;
      }
    } catch (_) {
      // Not JSON — ignore.
    }
    return null;
  }

  Future<String?> _readFileOrNull(String path) async {
    try {
      final f = File(path);
      if (!f.existsSync()) {
        return null;
      }
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }
}
