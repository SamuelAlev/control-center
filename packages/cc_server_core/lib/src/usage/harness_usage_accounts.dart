import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';

/// Builds one [SubscriptionUsageAccount] per connected plan login.
///
/// Codex / Cursor / Kimi Code / z.ai all support more than one stored
/// credential, and the same pinned / round-robin / serial pool Claude Code
/// uses orders those credentials at dispatch. Usage has to fan out the same
/// way or the rotation editor would show remaining quota for only the active
/// login.
Future<List<SubscriptionUsageAccount>> collectHarnessUsageAccounts({
  required ProviderCredentialStore store,
  HarnessOAuthBroker? oauthBroker,
}) async {
  final out = <SubscriptionUsageAccount>[];

  Future<ProviderCredential> refresh(ProviderCredential cred) async {
    if (oauthBroker == null || cred.method != HarnessAuthMethod.oauth) {
      return cred;
    }
    return oauthBroker.refreshIfNeeded(cred);
  }

  // The quota is the GLM Coding Plan's. Plain `zai` is pay-as-you-go and
  // only a fallback so an install that connected its coding key before the
  // lanes were split keeps showing usage until it reconnects.
  var zai = await store.credentialsFor('zai-coding');
  if (zai.isEmpty) {
    zai = await store.credentialsFor('zai');
  }
  for (final cred in zai) {
    final key = cred.apiKey?.trim();
    if (key == null || key.isEmpty) {
      continue;
    }
    out.add(
      SubscriptionUsageAccount(
        providerId: 'zai',
        accountId: cred.credentialId,
        accountLabel: _labelOf(cred),
        apiKey: key,
        baseUrl: _httpsOrigin(cred.baseUrl),
      ),
    );
  }

  for (var cred in await store.credentialsFor('kimi-code')) {
    cred = await refresh(cred);
    final token = cred.accessToken?.trim();
    if (token == null || token.isEmpty) {
      continue;
    }
    out.add(
      SubscriptionUsageAccount(
        providerId: 'kimi-code',
        accountId: cred.credentialId,
        accountLabel: _labelOf(cred),
        accessToken: token,
        baseUrl: cred.baseUrl,
        deviceId: cred.accountId,
      ),
    );
  }

  for (var cred in await store.credentialsFor('cursor')) {
    cred = await refresh(cred);
    final token = (cred.accessToken ?? cred.apiKey)?.trim();
    if (token == null || token.isEmpty) {
      continue;
    }
    out.add(
      SubscriptionUsageAccount(
        providerId: 'cursor',
        accountId: cred.credentialId,
        accountLabel: _labelOf(cred),
        accessToken: token,
        apiKey: cred.apiKey,
        baseUrl: cred.baseUrl,
      ),
    );
  }

  // ChatGPT usage is `/wham/usage` and takes the OAuth bearer only — an API
  // key has no ChatGPT plan to report.
  for (var cred in await store.credentialsFor('codex')) {
    if (cred.method != HarnessAuthMethod.oauth) {
      continue;
    }
    cred = await refresh(cred);
    final token = cred.accessToken?.trim();
    if (token == null || token.isEmpty) {
      continue;
    }
    out.add(
      SubscriptionUsageAccount(
        providerId: 'codex',
        accountId: cred.credentialId,
        accountLabel: _labelOf(cred),
        accessToken: token,
        providerAccountId: cred.accountId,
        baseUrl: cred.baseUrl,
      ),
    );
  }

  return out;
}

String? _labelOf(ProviderCredential cred) => cred.email ?? cred.accountLabel;

/// Origin of a stored chat-API base URL, or null when it is not http(s).
///
/// z.ai usage lives at the host root; a stored URL often points at
/// `…/api/paas/v4`. Reusing the origin is what keeps a bigmodel.cn account
/// working.
String? _httpsOrigin(String? base) {
  final trimmed = base?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  return uri.origin;
}
