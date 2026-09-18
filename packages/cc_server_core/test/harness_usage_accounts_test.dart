import 'package:cc_harness/provider.dart';
import 'package:cc_server_core/src/usage/harness_usage_accounts.dart';
import 'package:test/test.dart';

class _Store implements ProviderCredentialStore {
  _Store(this.map);

  final Map<String, List<ProviderCredential>> map;

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async {
    final list = map[providerId];
    return list == null || list.isEmpty ? null : list.first;
  }

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async =>
      map[providerId] ?? const [];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

void main() {
  test('fans out every connected plan login, not just the active one', () async {
    final store = _Store({
      'kimi-code': [
        const ProviderCredential(
          providerId: 'kimi-code',
          method: HarnessAuthMethod.oauth,
          accessToken: 'kimi-a',
          email: 'a@kimi.com',
          accountId: 'dev-a',
        ),
        const ProviderCredential(
          providerId: 'kimi-code',
          method: HarnessAuthMethod.oauth,
          accessToken: 'kimi-b',
          email: 'b@kimi.com',
          accountId: 'dev-b',
          isActive: false,
        ),
      ],
      'codex': [
        const ProviderCredential(
          providerId: 'codex',
          method: HarnessAuthMethod.oauth,
          accessToken: 'codex-tok',
          email: 'plus@openai.com',
          accountId: 'chatgpt-1',
        ),
        const ProviderCredential(
          providerId: 'codex',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-no-plan',
        ),
      ],
      'zai-coding': [
        const ProviderCredential(
          providerId: 'zai-coding',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'zai-1',
          accountLabel: 'work',
        ),
        const ProviderCredential(
          providerId: 'zai-coding',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'zai-2',
          accountLabel: 'home',
          isActive: false,
        ),
      ],
      'cursor': [
        const ProviderCredential(
          providerId: 'cursor',
          method: HarnessAuthMethod.oauth,
          accessToken: 'cursor-a',
          email: 'a@cursor.com',
        ),
        const ProviderCredential(
          providerId: 'cursor',
          method: HarnessAuthMethod.oauth,
          accessToken: 'cursor-b',
          email: 'b@cursor.com',
          isActive: false,
        ),
      ],
    });

    final accounts = await collectHarnessUsageAccounts(store: store);
    expect(accounts.map((a) => a.providerId).toList(), [
      'zai',
      'zai',
      'kimi-code',
      'kimi-code',
      'cursor',
      'cursor',
      'codex',
    ]);
    expect(
      accounts.where((a) => a.providerId == 'kimi-code').map((a) => a.accountLabel),
      ['a@kimi.com', 'b@kimi.com'],
    );
    expect(
      accounts.where((a) => a.providerId == 'zai').map((a) => a.accountLabel),
      ['work', 'home'],
    );
    expect(
      accounts.where((a) => a.providerId == 'cursor').map((a) => a.accountLabel),
      ['a@cursor.com', 'b@cursor.com'],
    );
    final codex = accounts.singleWhere((a) => a.providerId == 'codex');
    expect(codex.providerAccountId, 'chatgpt-1');
    expect(codex.accessToken, 'codex-tok');
    expect(accounts.where((a) => a.apiKey == 'sk-no-plan'), isEmpty);
  });
}
