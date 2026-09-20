import 'dart:io';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/claude_usage_strategy.dart';
import 'package:cc_infra/src/usage/codex_usage_strategy.dart';
import 'package:cc_infra/src/usage/cursor_usage_strategy.dart';
import 'package:cc_infra/src/usage/kimi_usage_strategy.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:cc_infra/src/usage/zai_usage_strategy.dart';
import 'package:dio/dio.dart';

/// The five plan-usage providers, in the order the pill and the popover
/// render them. A missing account for any of these still yields one
/// `unconfigured` snapshot so the surface never has a hole.
const List<({String id, String name})> kSubscriptionUsageProviders = [
  (id: 'claude', name: 'Claude'),
  (id: 'codex', name: 'Codex'),
  (id: 'zai', name: 'z.ai'),
  (id: 'kimi-code', name: 'Kimi Code'),
  (id: 'cursor', name: 'Cursor'),
];

/// Fetches live subscription-usage quotas for the AI coding plans — Claude
/// Code, OpenAI Codex, Cursor, the z.ai (Zhipu) GLM Coding Plan and Kimi Code —
/// the data behind the title-bar usage pill ("X% used, resets in Y").
///
/// Runs **server-side**. Each provider is its own [SubscriptionUsageStrategy]
/// in its own file, answering [SubscriptionUsageStrategy.fetchAccount] for
/// every [SubscriptionUsageAccount] the caller supplies. That is what lets
/// pinned / round-robin / serial rotation show remaining quota per account
/// the same way Claude Code already does. This class is only the coordinator:
/// it groups accounts by provider, runs them concurrently, and never lets one
/// failure blank out the others.
class SubscriptionUsageService {
  /// Creates a [SubscriptionUsageService].
  ///
  /// [_dio] is the outbound HTTP client (the host passes its shared `createDio`
  /// instance). [homeDir]/[environment] default to the process environment.
  /// [fetchClaudeCached] is the single-flight cache in front of Claude's
  /// rate-limited usage endpoint — the pill and the dispatch-time headroom
  /// check share it so multi-account does not 429 itself.
  SubscriptionUsageService({
    required this._dio,
    String? homeDir,
    Map<String, String>? environment,
    this.readClaudeKeychain = true,
    this.fetchClaudeCached,
  }) : _env = environment ?? Platform.environment,
       _home = homeDir;

  final Dio _dio;
  final Map<String, String> _env;
  final String? _home;

  /// Whether to fall back to the macOS Keychain for the Claude token (disabled
  /// in tests to keep them independent of the host's real Claude Code login).
  final bool readClaudeKeychain;

  /// Optional Claude usage cache. When set, a named Claude account is read
  /// through it instead of hitting the endpoint on every poll.
  final Future<SubscriptionUsage> Function(String configDir)? fetchClaudeCached;

  /// Fetches usage for every provider concurrently.
  ///
  /// [accounts] is the common multi-account input: one entry per connected
  /// login, already refreshed by the caller. A provider with no accounts
  /// yields a single `unconfigured` snapshot (Claude still probes the host's
  /// default `~/.claude` / keychain login). Two or more accounts for the same
  /// provider stamp [SubscriptionUsage.accountId] / `accountLabel` so the
  /// rotation editor can page them.
  ///
  /// The named `*Token` / `*Key` parameters are the single-account sugar the
  /// existing tests use; they are folded into [accounts].
  Future<List<SubscriptionUsage>> fetchAll({
    List<SubscriptionUsageAccount> accounts = const [],
    String? zaiApiKey,
    String? zaiBaseUrl,
    String? kimiAccessToken,
    String? kimiBaseUrl,
    String? kimiDeviceId,
    String? cursorAccessToken,
    String? cursorBaseUrl,
    String? codexAccessToken,
    String? codexAccountId,
    String? codexBaseUrl,
  }) {
    final merged = [
      ...accounts,
      if (_present(zaiApiKey))
        SubscriptionUsageAccount(
          providerId: 'zai',
          apiKey: zaiApiKey,
          baseUrl: zaiBaseUrl,
        ),
      if (_present(kimiAccessToken))
        SubscriptionUsageAccount(
          providerId: 'kimi-code',
          accessToken: kimiAccessToken,
          baseUrl: kimiBaseUrl,
          deviceId: kimiDeviceId,
        ),
      if (_present(cursorAccessToken))
        SubscriptionUsageAccount(
          providerId: 'cursor',
          accessToken: cursorAccessToken,
          baseUrl: cursorBaseUrl,
        ),
      if (_present(codexAccessToken))
        SubscriptionUsageAccount(
          providerId: 'codex',
          accessToken: codexAccessToken,
          providerAccountId: codexAccountId,
          baseUrl: codexBaseUrl,
        ),
    ];

    final byProvider = <String, List<SubscriptionUsageAccount>>{};
    for (final account in merged) {
      byProvider.putIfAbsent(account.providerId, () => []).add(account);
    }

    final claude = _claude();
    final strategies = <String, SubscriptionUsageStrategy>{
      'claude': claude,
      'codex': CodexUsageStrategy(dio: _dio),
      'zai': ZaiUsageStrategy(dio: _dio),
      'kimi-code': KimiUsageStrategy(dio: _dio),
      'cursor': CursorUsageStrategy(dio: _dio),
    };

    final futures = <Future<SubscriptionUsage>>[];
    for (final meta in kSubscriptionUsageProviders) {
      final strategy = strategies[meta.id]!;
      final list = byProvider[meta.id] ?? const <SubscriptionUsageAccount>[];
      if (list.isEmpty) {
        futures.add(strategy.guarded());
        continue;
      }
      final identify = list.length > 1;
      for (final account in list) {
        futures.add(
          _fetchOne(strategy, account, identify: identify),
        );
      }
    }
    return Future.wait(futures);
  }

  /// Usage for ONE Claude Code account, named by its `CLAUDE_CONFIG_DIR`.
  ///
  /// The account picker shows this per row so the operator can choose on
  /// remaining quota rather than on which login they happen to remember. Same
  /// degrade contract as [fetchAll]: never throws, reports `unconfigured` for
  /// an account that is not signed in.
  Future<SubscriptionUsage> fetchClaudeForConfigDir(String configDir) =>
      _claude().guarded(
        SubscriptionUsageAccount(providerId: 'claude', configDir: configDir),
      );

  Future<SubscriptionUsage> _fetchOne(
    SubscriptionUsageStrategy strategy,
    SubscriptionUsageAccount account, {
    required bool identify,
  }) async {
    if (account.knownStatus != null) {
      return SubscriptionUsage(
        providerId: strategy.providerId,
        displayName: strategy.displayName,
        status: account.knownStatus!,
        error: account.knownReason,
        fetchedAt: DateTime.now().toUtc(),
        accountId: account.accountId,
        accountLabel: account.accountLabel,
      );
    }

    final cached = fetchClaudeCached;
    final configDir = account.configDir;
    final SubscriptionUsage usage;
    if (strategy.providerId == 'claude' &&
        cached != null &&
        configDir != null &&
        configDir.isNotEmpty) {
      usage = await cached(configDir);
    } else {
      usage = await strategy.guarded(account);
    }

    if (identify ||
        account.accountId != null ||
        account.accountLabel != null) {
      return usage.copyWith(
        accountId: account.accountId,
        accountLabel: account.accountLabel,
      );
    }
    return usage;
  }

  ClaudeUsageStrategy _claude() => ClaudeUsageStrategy(
    dio: _dio,
    environment: _env,
    homeDir: _home,
    readClaudeKeychain: readClaudeKeychain,
  );

  static bool _present(String? value) =>
      value != null && value.trim().isNotEmpty;
}
