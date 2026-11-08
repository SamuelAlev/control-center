import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/claude_cli_usage_probe.dart';
import 'package:cc_infra/src/usage/claude_usage_strategy.dart';
import 'package:cc_infra/src/usage/codex_usage_strategy.dart';
import 'package:cc_infra/src/usage/cursor_usage_strategy.dart';
import 'package:cc_infra/src/usage/kimi_usage_strategy.dart';
import 'package:cc_infra/src/usage/mistral_usage_strategy.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:cc_infra/src/usage/zai_usage_strategy.dart';
import 'package:rhttp/rhttp.dart';

/// The plan-usage providers, in the order the pill and the popover render
/// them. A missing account for any of these still yields one `unconfigured`
/// snapshot so the surface never has a hole.
const List<({String id, String name})> kSubscriptionUsageProviders = [
  (id: 'claude', name: 'Claude'),
  (id: 'codex', name: 'Codex'),
  (id: 'zai', name: 'z.ai'),
  (id: 'kimi-code', name: 'Kimi Code'),
  (id: 'cursor', name: 'Cursor'),
  (id: 'mistral', name: 'Mistral'),
];

/// Providers whose credential is a plain API key that MAY carry a plan.
///
/// A Mistral key bills pay-as-you-go unless its organization holds a Vibe
/// plan, and the same key shape serves both. A key without a plan reports
/// `unconfigured`; it is dropped instead of paged, because it is not an
/// account of the plan, and only when no key has a plan does the provider fall
/// back to its single `unconfigured` snapshot.
const Set<String> _planOptionalProviders = {'mistral'};

/// Fetches live subscription-usage quotas for the AI coding plans — Claude
/// Code, OpenAI Codex, Cursor, the z.ai (Zhipu) GLM Coding Plan, Kimi Code and
/// the Mistral Vibe plan —
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
  /// [_httpClient] is the outbound HTTP client (the host passes its shared
  /// `createHttpClient` instance). [claudeUsageReader] defaults to asking the
  /// installed `claude` CLI; tests replace it so they stay independent of the
  /// host's real Claude Code login. [fetchClaudeCached] is the single-flight
  /// cache in front of that read, which spawns a process: the pill and the
  /// dispatch-time headroom check share it.
  SubscriptionUsageService({
    required this._httpClient,
    ClaudeUsageReader? claudeUsageReader,
    this.fetchClaudeCached,
  }) : _claudeUsageReader = claudeUsageReader ?? ClaudeCliUsageProbe().read;

  final RhttpClient _httpClient;
  final ClaudeUsageReader _claudeUsageReader;

  /// Optional Claude usage cache. When set, a named Claude account is read
  /// through it instead of spawning the CLI on every poll.
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
      'codex': CodexUsageStrategy(httpClient: _httpClient),
      'zai': ZaiUsageStrategy(httpClient: _httpClient),
      'kimi-code': KimiUsageStrategy(httpClient: _httpClient),
      'cursor': CursorUsageStrategy(httpClient: _httpClient),
      'mistral': MistralUsageStrategy(httpClient: _httpClient),
    };

    final futures = <Future<List<SubscriptionUsage>>>[];
    for (final meta in kSubscriptionUsageProviders) {
      final strategy = strategies[meta.id]!;
      final list = byProvider[meta.id] ?? const <SubscriptionUsageAccount>[];
      if (list.isEmpty) {
        futures.add(strategy.guarded().then((u) => [u]));
        continue;
      }
      final identify = list.length > 1;
      final fetched = Future.wait([
        for (final account in list)
          _fetchOne(strategy, account, identify: identify),
      ]);
      futures.add(
        _planOptionalProviders.contains(meta.id)
            ? fetched.then((all) => _withoutPlanless(strategy, all))
            : fetched,
      );
    }
    return Future.wait(
      futures,
    ).then((groups) => groups.expand((g) => g).toList());
  }

  /// [all] minus the keys that carry no plan, or one nameless `unconfigured`
  /// snapshot when none does — see [_planOptionalProviders].
  static List<SubscriptionUsage> _withoutPlanless(
    SubscriptionUsageStrategy strategy,
    List<SubscriptionUsage> all,
  ) {
    final plans = [
      for (final u in all)
        if (u.status != SubscriptionStatus.unconfigured) u,
    ];
    if (plans.isNotEmpty) {
      return plans;
    }
    // Nameless, so the pill drops it like any provider that is not set up.
    return [strategy.unconfigured(all.first.error ?? '')];
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

    if (identify || account.accountId != null || account.accountLabel != null) {
      return usage.copyWith(
        accountId: account.accountId,
        accountLabel: account.accountLabel,
      );
    }
    return usage;
  }

  ClaudeUsageStrategy _claude() =>
      ClaudeUsageStrategy(read: _claudeUsageReader);

  static bool _present(String? value) =>
      value != null && value.trim().isNotEmpty;
}
