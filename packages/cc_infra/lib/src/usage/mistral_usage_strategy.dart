import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:rhttp/rhttp.dart';

/// Mistral Vibe plan usage (Le Chat Pro / Team) via
/// `GET <api>/v1/billing/budget`, the endpoint Mistral's own Vibe CLI reads
/// for its footer gauge.
///
/// The same API key serves both pay-as-you-go and plan accounts, so most keys
/// have no plan at all. Those answer with no `vibe_budget` (or a zero
/// allowance) and report [SubscriptionStatus.unconfigured]; the service drops
/// them so a metered key never shows up as a plan.
///
/// The credential is supplied by the caller from the harness provider
/// credential store and is only ever sent to a recognised Mistral host.
class MistralUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [MistralUsageStrategy].
  MistralUsageStrategy({required this._httpClient})
    : super(providerId: 'mistral', displayName: 'Mistral');

  final RhttpClient _httpClient;

  static const _defaultOrigin = 'https://api.mistral.ai';
  static const _budgetPath = '/v1/billing/budget';
  static const _subscriptionPath = '/v1/billing/subscription';

  /// Why a key reports no plan. The service keys the "drop planless keys" rule
  /// off [SubscriptionStatus.unconfigured], not this text.
  static const noPlanReason = 'No Mistral Vibe plan on this key.';

  @override
  Future<SubscriptionUsage> fetchAccount(
    SubscriptionUsageAccount account,
  ) async {
    final key = account.apiKey?.trim() ?? '';
    if (key.isEmpty) {
      return unconfigured(
        'Add a Mistral key with a Vibe plan in Settings → Adapters to see '
        'usage.',
      );
    }
    final origin = _originOf(account.baseUrl);
    if (origin == null) {
      // A key routed through a proxy or self-hosted endpoint: the plan, if
      // any, is only readable from Mistral's own hosts.
      return unconfigured(noPlanReason);
    }
    try {
      final HttpResponse resp;
      try {
        resp = await _get('$origin$_budgetPath', key);
      } on RhttpStatusCodeException catch (e) {
        return switch (e.statusCode) {
          // A platform that does not serve billing has no plan to report.
          404 => unconfigured(noPlanReason),
          // An org member without `see_org_inference_usage`: the plan may be
          // real, so say why it cannot be read rather than hide it.
          403 => error('This key cannot read the organization’s Vibe usage.'),
          _ => error(shortError(e)),
        };
      }
      final budget = jsonObject(resp)?['vibe_budget'];
      if (budget is! Map) {
        return unconfigured(noPlanReason);
      }
      final allowance = asNum(budget['initial_budget']);
      final percent = asNum(budget['usage_percentage']);
      if (allowance == null || allowance <= 0 || percent == null) {
        return unconfigured(noPlanReason);
      }
      final used = (percent / 100).clamp(0.0, 1.0).toDouble();
      final window = SubscriptionWindow(
        id: 'month',
        label: 'Monthly',
        usedFraction: used,
        resetsAt: parseIso(budget['reset_at'])?.toUtc(),
      );
      if (used >= 1.0 && !await _paygEnabled(origin, key, budget)) {
        // Past the allowance with pay-as-you-go off, Vibe stops serving.
        return exhausted('Monthly Vibe budget spent.');
      }
      return ok([window]);
    } catch (e) {
      return error(shortError(e));
    }
  }

  /// Whether pay-as-you-go picks up Vibe past its allowance. The budget says
  /// so directly when it knows; otherwise the subscription does. Only asked
  /// once the allowance is spent, so a healthy plan costs one request.
  Future<bool> _paygEnabled(String origin, String key, Map budget) async {
    final direct = budget['payg_enabled'];
    if (direct is bool) {
      return direct;
    }
    try {
      final resp = await _get('$origin$_subscriptionPath', key);
      return jsonObject(resp)?['vibe_payg_enabled'] == true;
    } on Object {
      // Unknown reads as off, the same default Vibe itself applies.
      return false;
    }
  }

  Future<HttpResponse> _get(String url, String key) => boundedRequest(
    (token) => _httpClient.get(
      url,
      headers: HttpHeaders.rawMap({
        'Authorization': 'Bearer $key',
        'Accept': 'application/json',
      }),
      cancelToken: token,
    ),
  );

  /// The https origin of a stored chat-API base URL (`…/v1` is the usual
  /// shape), or the public API when none is stored. Null for anything that is
  /// not https on a Mistral host, so the key is never sent anywhere else.
  String? _originOf(String? base) {
    final trimmed = base?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _defaultOrigin;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'https' || !_isMistralHost(uri.host)) {
      return null;
    }
    return uri.origin;
  }

  bool _isMistralHost(String host) {
    final h = host.toLowerCase();
    return h == 'mistral.ai' || h.endsWith('.mistral.ai');
  }
}
