import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:rhttp/rhttp.dart';

/// DeepSeek prepaid balance via `GET <api>/user/balance`.
///
/// DeepSeek sells no plan: a key spends a balance the account tops up, so the
/// reading is money left rather than a share of a window. It reports one
/// balance per currency the account holds (CNY, USD), granted and topped-up
/// credit already summed in `total_balance`.
///
/// The credential is supplied by the caller from the harness provider
/// credential store and is only ever sent to a recognised DeepSeek host.
class DeepSeekUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [DeepSeekUsageStrategy].
  DeepSeekUsageStrategy({required this._httpClient})
    : super(providerId: 'deepseek', displayName: 'DeepSeek');

  final RhttpClient _httpClient;

  static const _defaultOrigin = 'https://api.deepseek.com';
  static const _balancePath = '/user/balance';

  @override
  Future<SubscriptionUsage> fetchAccount(
    SubscriptionUsageAccount account,
  ) async {
    final key = account.apiKey?.trim() ?? '';
    if (key.isEmpty) {
      return unconfigured(
        'Add a DeepSeek key in Settings → Adapters to see usage.',
      );
    }
    final origin = _originOf(account.baseUrl);
    if (origin == null) {
      // A key routed through a proxy or self-hosted endpoint: the balance is
      // only readable from DeepSeek's own hosts.
      return unconfigured('The balance is only readable from DeepSeek.');
    }
    try {
      final resp = await boundedRequest(
        (token) => _httpClient.get(
          '$origin$_balancePath',
          headers: HttpHeaders.rawMap({
            'Authorization': 'Bearer $key',
            'Accept': 'application/json',
          }),
          cancelToken: token,
        ),
      );
      final body = jsonObject(resp);
      final balances = <SubscriptionBalance>[];
      for (final raw in body?['balance_infos'] as List? ?? const []) {
        if (raw is! Map) {
          continue;
        }
        final total = asNum(raw['total_balance']);
        final currency = raw['currency'];
        if (total == null || currency is! String || currency.isEmpty) {
          continue;
        }
        balances.add(
          SubscriptionBalance(
            amountMinor: (total * 100).round(),
            currency: currency.toUpperCase(),
          ),
        );
      }
      // DeepSeek's own verdict on whether the balance still pays for a call.
      if (body?['is_available'] == false) {
        return exhausted('Balance too low for API calls. Top up to continue.');
      }
      if (balances.isEmpty) {
        return error('Unavailable');
      }
      return ok(const [], balances: balances);
    } on RhttpStatusCodeException catch (e) {
      // DeepSeek answers a spent account with 402 on its paid endpoints.
      if (e.statusCode == 402) {
        return exhausted('Balance too low for API calls. Top up to continue.');
      }
      return error(shortError(e));
    } catch (e) {
      return error(shortError(e));
    }
  }

  /// The https origin of a stored chat-API base URL (`…/v1` is the usual
  /// shape), or the public API when none is stored. Null for anything that is
  /// not https on a DeepSeek host, so the key is never sent anywhere else.
  String? _originOf(String? base) {
    final trimmed = base?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _defaultOrigin;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'https' || !_isDeepSeekHost(uri.host)) {
      return null;
    }
    return uri.origin;
  }

  bool _isDeepSeekHost(String host) {
    final h = host.toLowerCase();
    return h == 'deepseek.com' || h.endsWith('.deepseek.com');
  }
}
