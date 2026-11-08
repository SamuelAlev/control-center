import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/claude_cli_usage_probe.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';

/// Claude Code usage, read through the `claude` CLI itself.
///
/// See [ClaudeCliUsageProbe] for why this never touches the account's token.
/// [SubscriptionUsageAccount.configDir] names one account; without it the
/// reading is the operator's own login.
class ClaudeUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [ClaudeUsageStrategy].
  ClaudeUsageStrategy({required this._read})
    : super(providerId: 'claude', displayName: 'Claude');

  final ClaudeUsageReader _read;

  static const _signIn = 'Sign in to Claude Code to see usage.';

  @override
  Future<SubscriptionUsage> fetchAccount(
    SubscriptionUsageAccount account,
  ) async {
    try {
      final reading = await _read(configDir: account.configDir);
      if (reading == null || reading.signedOut) {
        return unconfigured(_signIn);
      }
      if (!reading.available) {
        return unconfigured('No usage reported.');
      }
      final data = reading.rateLimits;
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
}
