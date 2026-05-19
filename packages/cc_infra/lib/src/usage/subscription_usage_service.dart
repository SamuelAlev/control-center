import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:dio/dio.dart';

/// Fetches live subscription-usage quotas for the AI coding plans — Claude
/// Code, OpenAI Codex, the z.ai (Zhipu) GLM Coding Plan, and Kimi Code — the
/// data behind the title-bar usage pill ("X% used, resets in Y").
///
/// Runs **server-side**, where the CLIs and their credentials live: it reads
/// each CLI's own credential file (or the macOS Keychain) and calls the
/// provider's usage endpoint. z.ai and Kimi Code have no local credential file,
/// so their credentials are passed in by the caller (the RPC op resolves them
/// from the harness provider credential store — Settings → Adapters →
/// Providers & models).
///
/// Every provider degrades **independently**: a missing credential yields a
/// [SubscriptionStatus.unconfigured] snapshot, a failed fetch yields a
/// [SubscriptionStatus.error] snapshot, and neither throws — so one provider
/// being down never blanks out the others.
class SubscriptionUsageService {
  /// Creates a [SubscriptionUsageService].
  ///
  /// [dio] is the outbound HTTP client (the host passes its shared `createDio`
  /// instance). [homeDir]/[environment] default to the process environment.
  /// [codexExecutable] is the Codex CLI binary name (overridable for tests).
  SubscriptionUsageService({
    required Dio dio,
    String? homeDir,
    Map<String, String>? environment,
    this.codexExecutable = 'codex',
    this.readClaudeKeychain = true,
  }) : _dio = dio,
       _env = environment ?? Platform.environment,
       _home = homeDir;

  final Dio _dio;
  final Map<String, String> _env;
  final String? _home;

  /// The Codex CLI binary name.
  final String codexExecutable;

  /// Whether to fall back to the macOS Keychain for the Claude token (disabled
  /// in tests to keep them independent of the host's real Claude Code login).
  final bool readClaudeKeychain;

  static const _claudeUsageUrl = 'https://api.anthropic.com/api/oauth/usage';
  static const _claudeBeta = 'oauth-2025-04-20';
  // The usage endpoint aggressively rate-limits callers without a recognised
  // Claude Code User-Agent (returns persistent 429s), so we send one.
  static const _claudeUserAgent = 'claude-code/2.1.0';
  static const _zaiDefaultBaseUrl = 'https://api.z.ai';
  static const _zaiUsagePath = '/api/monitor/usage/quota/limit';
  static const _kimiUsagePath = '/usages';

  String? get _homeDir => _home ?? _env['HOME'] ?? _env['USERPROFILE'];

  /// Fetches usage for every provider concurrently. The z.ai and Kimi Code
  /// credentials are supplied by the caller — the RPC op resolves them from the
  /// harness provider credential store, since neither has a local credential
  /// file. A null/empty credential yields an `unconfigured` snapshot for that
  /// provider rather than an error.
  ///
  /// [kimiAccessToken] is an OAuth access token the caller has already
  /// refreshed; this service never refreshes (the broker owns that), so an
  /// expired token simply reports an error for one cycle.
  Future<List<SubscriptionUsage>> fetchAll({
    String? zaiApiKey,
    String? zaiBaseUrl,
    String? kimiAccessToken,
    String? kimiBaseUrl,
    String? kimiDeviceId,
  }) async {
    // Each future is guarded so a stray throw anywhere in a fetcher (including
    // pre-`try` work like file-existence checks) degrades that one provider to
    // an error snapshot instead of rejecting the whole batch via `Future.wait`.
    return Future.wait([
      _guard('claude', 'Claude', _fetchClaude()),
      _guard('codex', 'Codex', _fetchCodex()),
      _guard('zai', 'z.ai', _fetchZai(apiKey: zaiApiKey, baseUrl: zaiBaseUrl)),
      _guard(
        'kimi-code',
        'Kimi Code',
        _fetchKimi(
          accessToken: kimiAccessToken,
          baseUrl: kimiBaseUrl,
          deviceId: kimiDeviceId,
        ),
      ),
    ]);
  }

  Future<SubscriptionUsage> _guard(
    String id,
    String name,
    Future<SubscriptionUsage> future,
  ) => future.catchError((Object e) => _error(id, name, _short(e)));

  // ── Claude Code ────────────────────────────────────────────────────────

  Future<SubscriptionUsage> _fetchClaude() async {
    const id = 'claude';
    const name = 'Claude';
    try {
      final token = await _readClaudeToken();
      if (token == null || token.isEmpty) {
        return _unconfigured(id, name, 'Sign in to Claude Code to see usage.');
      }
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(_claudeUsageUrl),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer $token',
            'anthropic-beta': _claudeBeta,
            'User-Agent': _claudeUserAgent,
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
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
            resetsAt: _parseIso(w['resets_at']),
          ),
        );
      }

      add('five_hour', '5h', 'Session');
      add('seven_day', '7d', 'Weekly');
      if (windows.isEmpty) {
        return _unconfigured(id, name, 'No usage reported.');
      }
      return _ok(id, name, windows);
    } catch (e) {
      return _error(id, name, _short(e));
    }
  }

  /// Reads the Claude Code OAuth access token from `~/.claude/.credentials.json`
  /// (Linux/Windows/macOS), falling back to the macOS Keychain (Claude Code
  /// 2.1+ stores the same JSON blob there). Returns null when unavailable.
  Future<String?> _readClaudeToken() async {
    final home = _homeDir;
    final configDir = _env['CLAUDE_CONFIG_DIR'];
    final candidates = <String>[
      if (configDir != null && configDir.isNotEmpty)
        '$configDir/.credentials.json',
      if (home != null) '$home/.claude/.credentials.json',
    ];
    for (final path in candidates) {
      final token = _tokenFromCredentialsBlob(await _readFileOrNull(path));
      if (token != null) {
        return token;
      }
    }
    if (readClaudeKeychain && Platform.isMacOS) {
      return _readClaudeKeychain();
    }
    return null;
  }

  Future<String?> _readClaudeKeychain() async {
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

  // ── OpenAI Codex ───────────────────────────────────────────────────────

  Future<SubscriptionUsage> _fetchCodex() async {
    const id = 'codex';
    const name = 'Codex';
    final home = _homeDir;
    final codexHome =
        _env['CODEX_HOME'] ?? (home == null ? null : '$home/.codex');
    // Cheap "is Codex signed in?" gate — avoid spawning a process otherwise.
    if (codexHome == null || !File('$codexHome/auth.json').existsSync()) {
      return _unconfigured(id, name, 'Sign in to Codex to see usage.');
    }
    try {
      final limits = await _readCodexRateLimits();
      if (limits == null) {
        return _error(id, name, 'Codex did not report limits.');
      }
      final windows = <SubscriptionWindow>[];
      void add(dynamic w, String wid, String label) {
        if (w is! Map) {
          return;
        }
        final used = (w['used_percent'] ?? w['usedPercent']) as num?;
        if (used == null) {
          return;
        }
        DateTime? reset;
        final resetsAt = (w['resets_at'] ?? w['resetsAt']) as num?;
        final resetsInSec =
            (w['resets_in_seconds'] ?? w['resetsInSeconds']) as num?;
        if (resetsAt != null) {
          // Codex reports the reset as a unix timestamp in seconds.
          reset = DateTime.fromMillisecondsSinceEpoch(
            resetsAt.toInt() * 1000,
            isUtc: true,
          );
        } else if (resetsInSec != null) {
          // UTC so the wire timestamp is unambiguous regardless of host tz.
          reset = DateTime.now().toUtc().add(
            Duration(seconds: resetsInSec.toInt()),
          );
        }
        windows.add(
          SubscriptionWindow(
            id: wid,
            label: label,
            usedFraction: (used.toDouble() / 100).clamp(0.0, 1.0),
            resetsAt: reset,
          ),
        );
      }

      add(limits['primary'], '5h', 'Session');
      add(limits['secondary'], '7d', 'Weekly');
      if (windows.isEmpty) {
        return _error(id, name, 'No usage reported.');
      }
      return _ok(id, name, windows);
    } catch (e) {
      return _error(id, name, _short(e));
    }
  }

  /// Drives the `codex app-server` JSON-RPC handshake to read the account's
  /// rate limits: `initialize` → `initialized` → (500ms+ later)
  /// `account/rateLimits/read`. Returns the `rateLimits` object or null.
  ///
  /// The stdout reader is framing-agnostic (it extracts complete JSON objects
  /// regardless of newline vs Content-Length framing); requests are written as
  /// newline-delimited JSON. The whole exchange is bounded by an 11s timeout
  /// and the process is always killed, so a protocol mismatch degrades to a
  /// null result rather than hanging.
  Future<Map<String, dynamic>?> _readCodexRateLimits() async {
    final Process proc;
    try {
      proc = await Process.start(codexExecutable, const [
        '-s',
        'read-only',
        '-a',
        'untrusted',
        'app-server',
      ], environment: _env);
    } on ProcessException {
      return null; // Codex CLI not installed / not on PATH.
    }

    final done = Completer<Map<String, dynamic>?>();
    var pending = '';
    var initialized = false;
    StreamSubscription<String>? sub;

    void send(Map<String, dynamic> msg) {
      try {
        proc.stdin.add(utf8.encode('${jsonEncode(msg)}\n'));
      } catch (_) {
        // stdin closed — the timeout/onDone path completes the future.
      }
    }

    sub = proc.stdout
        .transform(utf8.decoder)
        .listen(
          (chunk) {
            pending += chunk;
            final (objects, rest) = _drainJsonObjects(pending);
            pending = rest;
            for (final msg in objects) {
              final mid = msg['id'];
              if (mid == 1 && !initialized) {
                initialized = true;
                send({'jsonrpc': '2.0', 'method': 'initialized', 'params': {}});
                Future.delayed(const Duration(milliseconds: 600), () {
                  send({
                    'jsonrpc': '2.0',
                    'id': 2,
                    'method': 'account/rateLimits/read',
                    'params': {},
                  });
                });
              } else if (mid == 2 && !done.isCompleted) {
                final result = msg['result'];
                final rl = result is Map
                    ? (result['rateLimits'] ?? result['rate_limits'])
                    : null;
                done.complete(rl is Map ? rl.cast<String, dynamic>() : null);
              }
            }
          },
          onError: (_) {
            if (!done.isCompleted) {
              done.complete(null);
            }
          },
          onDone: () {
            if (!done.isCompleted) {
              done.complete(null);
            }
          },
        );

    send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'clientInfo': {'name': 'control-center', 'version': '1.0.0'},
      },
    });

    try {
      return await done.future.timeout(const Duration(seconds: 11));
    } on TimeoutException {
      return null;
    } finally {
      await sub.cancel();
      proc.kill();
      unawaited(proc.stdin.close().catchError((_) {}));
    }
  }

  // ── z.ai (Zhipu GLM Coding Plan) ─────────────────────────────────────────

  Future<SubscriptionUsage> _fetchZai({String? apiKey, String? baseUrl}) async {
    const id = 'zai';
    const name = 'z.ai';
    final key = apiKey?.trim() ?? '';
    if (key.isEmpty) {
      return _unconfigured(id, name, 'Sign in to z.ai to see usage.');
    }
    try {
      final base = (baseUrl == null || baseUrl.trim().isEmpty)
          ? _zaiDefaultBaseUrl
          : baseUrl.trim();
      // Never send the operator's key to an arbitrary host: require https and a
      // known z.ai/Zhipu host before attaching the credential.
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !_isZaiHost(parsed.host)) {
        return _error(id, name, 'Invalid z.ai base URL.');
      }
      final url = '${base.replaceAll(RegExp(r'/+$'), '')}$_zaiUsagePath';
      final resp = await _zaiGet(url, key);
      final windows = _parseZaiWindows(resp.data);
      if (windows.isEmpty) {
        return _error(id, name, 'Could not read z.ai usage.');
      }
      return _ok(id, name, windows);
    } catch (e) {
      return _error(id, name, _short(e));
    }
  }

  /// z.ai installs disagree on the auth scheme — some want the raw key in the
  /// `Authorization` header, others want `Bearer <key>`. Try raw first (the
  /// dominant convention) and fall back to Bearer on a 401/403.
  Future<Response<Map<String, dynamic>>> _zaiGet(
    String url,
    String apiKey,
  ) async {
    Options opts(String auth) => Options(
      responseType: ResponseType.json,
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en',
      },
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
    try {
      return await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(url),
        options: opts(apiKey),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return _dio.getUri<Map<String, dynamic>>(
          Uri.parse(url),
          options: opts('Bearer $apiKey'),
        );
      }
      rethrow;
    }
  }

  /// Parses the z.ai quota response: `{ data: { limits: [ { type, percentage,
  /// nextResetTime, unit } ] } }`. We surface the `TOKENS_LIMIT` entries (the
  /// coding token quota). The window is keyed off the entry's `unit`
  /// discriminator (3 = 5-hour session, 6 = weekly) rather than array order, so
  /// reordering or a single-window response still labels correctly; array
  /// position is the fallback when `unit` is absent/unrecognised.
  List<SubscriptionWindow> _parseZaiWindows(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }
    final inner = data['data'];
    final limits = inner is Map ? inner['limits'] : null;
    if (limits is! List) {
      return const [];
    }
    final tokenLimits = [
      for (final l in limits)
        if (l is Map && l['type'] == 'TOKENS_LIMIT') l,
    ];
    final windows = <SubscriptionWindow>[];
    for (var i = 0; i < tokenLimits.length; i++) {
      final l = tokenLimits[i];
      final pct = (l['percentage'] as num?)?.toDouble();
      if (pct == null) {
        continue;
      }
      final resetMs = (l['nextResetTime'] as num?)?.toInt();
      final (wid, label) = switch ((l['unit'] as num?)?.toInt()) {
        3 => ('5h', 'Session'),
        6 => ('7d', 'Weekly'),
        _ => switch (i) {
          0 => ('5h', 'Session'),
          1 => ('7d', 'Weekly'),
          _ => ('w$i', 'Window ${i + 1}'),
        },
      };
      windows.add(
        SubscriptionWindow(
          id: wid,
          label: label,
          usedFraction: (pct / 100).clamp(0.0, 1.0),
          resetsAt: resetMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(resetMs, isUtc: true),
        ),
      );
    }
    return windows;
  }

  // ── Kimi Code ────────────────────────────────────────────────────────────

  /// Kimi Code reports its plan quota at `GET <base>/usages`, authenticated
  /// with the plan's OAuth bearer plus the same `X-Msh-*` device identity every
  /// other Kimi call carries.
  Future<SubscriptionUsage> _fetchKimi({
    String? accessToken,
    String? baseUrl,
    String? deviceId,
  }) async {
    const id = 'kimi-code';
    const name = 'Kimi Code';
    final token = accessToken?.trim() ?? '';
    if (token.isEmpty) {
      return _unconfigured(
        id,
        name,
        'Sign in to Kimi Code in Settings → Adapters to see usage.',
      );
    }
    try {
      final base = (baseUrl == null || baseUrl.trim().isEmpty)
          ? KimiOAuth.apiBaseUrl
          : baseUrl.trim();
      // Never send the plan token to an arbitrary host: require https and a
      // known Kimi host before attaching the credential.
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !_isKimiHost(parsed.host)) {
        return _error(id, name, 'Invalid Kimi Code base URL.');
      }
      final url = '${base.replaceAll(RegExp(r'/+$'), '')}$_kimiUsagePath';
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            if (deviceId != null && deviceId.isNotEmpty)
              ...KimiOAuth.headersFor(deviceId),
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final windows = _parseKimiWindows(resp.data);
      if (windows.isEmpty) {
        return _error(id, name, 'Could not read Kimi Code usage.');
      }
      return _ok(id, name, windows);
    } catch (e) {
      return _error(id, name, _short(e));
    }
  }

  /// Parses Kimi's `/usages` payload: an optional `usage` summary plus a
  /// `limits` array, each entry pairing a `detail` (used/limit/remaining) with
  /// a `window` (duration + timeUnit).
  List<SubscriptionWindow> _parseKimiWindows(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }
    final windows = <SubscriptionWindow>[];

    /// Kimi reports absolute counts, not percentages, and spells "how much is
    /// left" either way round — derive the used fraction from whichever pair is
    /// present.
    double? fraction(Map<String, dynamic> row) {
      final limit = _num(row['limit']);
      if (limit == null || limit <= 0) {
        return null;
      }
      final remaining = _num(row['remaining']);
      final used =
          _num(row['used']) ?? (remaining == null ? null : limit - remaining);
      if (used == null) {
        return null;
      }
      return (used / limit).clamp(0.0, 1.0);
    }

    void add(
      String id,
      String label,
      Map<String, dynamic> row,
      DateTime? reset,
    ) {
      final f = fraction(row);
      if (f == null) {
        return;
      }
      windows.add(
        SubscriptionWindow(
          id: id,
          label: label,
          usedFraction: f,
          resetsAt: reset,
        ),
      );
    }

    final summary = data['usage'];
    if (summary is Map<String, dynamic>) {
      add('total', 'Total', summary, _kimiReset(summary));
    }
    final limits = data['limits'];
    if (limits is List) {
      for (var i = 0; i < limits.length; i++) {
        final entry = limits[i];
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final detail = entry['detail'] is Map<String, dynamic>
            ? entry['detail'] as Map<String, dynamic>
            : entry;
        final window = entry['window'] is Map<String, dynamic>
            ? entry['window'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final windowLabel = _kimiWindowLabel(window);
        add(
          windowLabel ?? 'limit-$i',
          (entry['name'] as String?) ??
              (entry['title'] as String?) ??
              windowLabel ??
              'Window ${i + 1}',
          detail,
          // Kimi puts the reset on the limit detail, not on the window.
          _kimiReset(detail) ?? _kimiReset(window),
        );
      }
    }
    return windows;
  }

  /// A window's human label from its `duration` + `timeUnit` pair
  /// (e.g. `{duration: 5, timeUnit: HOURS}` → `5h`).
  static String? _kimiWindowLabel(Map<String, dynamic> window) {
    final duration = _num(window['duration'])?.toInt();
    final unit = (window['timeUnit'] as String?)?.toUpperCase() ?? '';
    if (duration == null || unit.isEmpty) {
      return null;
    }
    if (unit.startsWith('MINUTE')) {
      return duration % 60 == 0 ? '${duration ~/ 60}h' : '${duration}m';
    }
    if (unit.startsWith('HOUR')) {
      return '${duration}h';
    }
    if (unit.startsWith('DAY')) {
      return '${duration}d';
    }
    if (unit.startsWith('SECOND')) {
      return '${duration}s';
    }
    return null;
  }

  /// A reset instant from any of the spellings Kimi uses — an ISO string, epoch
  /// seconds or millis, or a relative "resets in N seconds".
  static DateTime? _kimiReset(Map<String, dynamic> row) {
    for (final key in ['reset_at', 'resetAt', 'reset_time', 'resetTime']) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toUtc();
        }
      }
      final n = _num(value)?.toInt();
      if (n != null && n > 0) {
        // Epoch seconds and epoch millis are told apart by magnitude.
        return DateTime.fromMillisecondsSinceEpoch(
          n > 1000000000000 ? n : n * 1000,
          isUtc: true,
        );
      }
    }
    for (final key in ['reset_in', 'resetIn', 'ttl']) {
      final seconds = _num(row[key])?.toInt();
      if (seconds != null && seconds > 0) {
        return DateTime.now().toUtc().add(Duration(seconds: seconds));
      }
    }
    return null;
  }

  static num? _num(Object? raw) =>
      raw is num ? raw : (raw is String ? num.tryParse(raw) : null);

  /// Whether [host] is a recognised Kimi endpoint, so the plan token is only
  /// ever sent there.
  bool _isKimiHost(String host) {
    final h = host.toLowerCase();
    return h == 'kimi.com' ||
        h.endsWith('.kimi.com') ||
        h == 'moonshot.ai' ||
        h.endsWith('.moonshot.ai');
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  SubscriptionUsage _ok(
    String id,
    String name,
    List<SubscriptionWindow> windows,
  ) => SubscriptionUsage(
    providerId: id,
    displayName: name,
    status: SubscriptionStatus.ok,
    windows: windows,
    fetchedAt: DateTime.now().toUtc(),
  );

  SubscriptionUsage _unconfigured(String id, String name, String reason) =>
      SubscriptionUsage(
        providerId: id,
        displayName: name,
        status: SubscriptionStatus.unconfigured,
        error: reason,
        fetchedAt: DateTime.now().toUtc(),
      );

  SubscriptionUsage _error(String id, String name, String reason) =>
      SubscriptionUsage(
        providerId: id,
        displayName: name,
        status: SubscriptionStatus.error,
        error: reason,
        fetchedAt: DateTime.now().toUtc(),
      );

  /// Whether [host] is a recognised z.ai / Zhipu endpoint (global `z.ai` or the
  /// China `bigmodel.cn`), so the operator's key is only ever sent there.
  bool _isZaiHost(String host) {
    final h = host.toLowerCase();
    return h == 'z.ai' ||
        h.endsWith('.z.ai') ||
        h == 'bigmodel.cn' ||
        h.endsWith('.bigmodel.cn');
  }

  DateTime? _parseIso(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

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

  String _short(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null) {
        return 'HTTP $code';
      }
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Timed out',
        DioExceptionType.connectionError => 'Network error',
        _ => 'Request failed',
      };
    }
    if (e is TimeoutException) {
      return 'Timed out';
    }
    if (e is ProcessException) {
      return 'CLI unavailable';
    }
    return 'Unavailable';
  }

  /// Pulls complete top-level JSON objects out of [buffer], returning the
  /// parsed maps and the unconsumed tail. Framing-agnostic: it ignores anything
  /// between objects (newlines, `Content-Length:` headers) and tracks string /
  /// escape state so braces inside strings don't fool the depth counter.
  (List<Map<String, dynamic>>, String) _drainJsonObjects(String buffer) {
    final out = <Map<String, dynamic>>[];
    var depth = 0;
    var inStr = false;
    var esc = false;
    var start = -1;
    var consumed = 0;
    for (var i = 0; i < buffer.length; i++) {
      final c = buffer[i];
      if (inStr) {
        if (esc) {
          esc = false;
        } else if (c == r'\') {
          esc = true;
        } else if (c == '"') {
          inStr = false;
        }
        continue;
      }
      if (c == '"') {
        inStr = true;
      } else if (c == '{') {
        if (depth == 0) {
          start = i;
        }
        depth++;
      } else if (c == '}') {
        if (depth > 0) {
          depth--;
          if (depth == 0 && start >= 0) {
            try {
              final decoded = jsonDecode(buffer.substring(start, i + 1));
              if (decoded is Map) {
                out.add(decoded.cast<String, dynamic>());
              }
            } catch (_) {
              // Incomplete/garbled object — skip it.
            }
            start = -1;
            consumed = i + 1;
          }
        }
      }
    }
    return (out, buffer.substring(consumed));
  }
}
