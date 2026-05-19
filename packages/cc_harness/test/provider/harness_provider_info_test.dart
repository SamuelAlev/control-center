import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Round-trip + derived-bool coverage for the harness provider/model/OAuth
/// wire DTOs returned by the `providers.*` RPC ops.
void main() {
  group('HarnessAuthMethod / HarnessProviderEnabled', () {
    test('HarnessProviderEnabled wire is the enum name', () {
      for (final v in HarnessProviderEnabled.values) {
        expect(v.wire, v.name);
      }
    });

    test('HarnessProviderEnabled.fromWire parses known names', () {
      expect(
        HarnessProviderEnabled.fromWire('env'),
        HarnessProviderEnabled.env,
      );
      expect(
        HarnessProviderEnabled.fromWire('account'),
        HarnessProviderEnabled.account,
      );
      expect(
        HarnessProviderEnabled.fromWire('oauth'),
        HarnessProviderEnabled.oauth,
      );
      expect(
        HarnessProviderEnabled.fromWire('local'),
        HarnessProviderEnabled.local,
      );
      expect(
        HarnessProviderEnabled.fromWire('custom'),
        HarnessProviderEnabled.custom,
      );
    });

    test(
      'HarnessProviderEnabled.fromWire defaults unknown/null to disabled',
      () {
        expect(
          HarnessProviderEnabled.fromWire(null),
          HarnessProviderEnabled.disabled,
        );
        expect(
          HarnessProviderEnabled.fromWire('garbage'),
          HarnessProviderEnabled.disabled,
        );
      },
    );
  });

  group('HarnessProviderInfo', () {
    const info = HarnessProviderInfo(
      id: 'anthropic',
      displayName: 'Anthropic',
      authMethods: [HarnessAuthMethod.apiKey, HarnessAuthMethod.oauth],
      enabled: HarnessProviderEnabled.account,
      hasCredential: true,
      accountLabel: 'Personal',
      baseUrl: 'https://custom.example',
    );

    test('credentials survive the wire round-trip', () {
      const withCreds = HarnessProviderInfo(
        id: 'anthropic',
        displayName: 'Anthropic',
        authMethods: [HarnessAuthMethod.apiKey, HarnessAuthMethod.oauth],
        enabled: HarnessProviderEnabled.account,
        hasCredential: true,
        credentials: [
          HarnessCredentialSummary(
            credentialId: 'key:1a2b3c4d',
            method: HarnessAuthMethod.apiKey,
            isActive: true,
            removable: true,
            hint: '…wxyz',
          ),
          HarnessCredentialSummary(
            credentialId: 'oauth:dev@example.com',
            method: HarnessAuthMethod.oauth,
            isActive: false,
            removable: true,
            label: 'dev@example.com',
          ),
        ],
      );
      final restored = HarnessProviderInfo.fromJson(withCreds.toJson());
      expect(restored.credentials, hasLength(2));
      expect(restored.credentials[0].credentialId, 'key:1a2b3c4d');
      expect(restored.credentials[0].isActive, isTrue);
      expect(restored.credentials[0].hint, '…wxyz');
      expect(restored.credentials[1].method, HarnessAuthMethod.oauth);
      expect(restored.credentials[1].label, 'dev@example.com');
    });

    test('a payload without credentials parses to an empty list', () {
      // Older servers (and custom providers) send no credentials array — the
      // client must degrade to the single-credential UI, not crash.
      final restored = HarnessProviderInfo.fromJson(info.toJson());
      expect(restored.credentials, isEmpty);
    });

    test('derived getters', () {
      expect(info.connected, isTrue);
      expect(info.supportsOAuth, isTrue);
      expect(info.supportsApiKey, isTrue);
    });

    test('connected is false only when disabled', () {
      final disabled = info.copyWith(
        // HarnessProviderInfo has no copyWith; rebuild directly.
        id: 'anthropic',
        displayName: 'Anthropic',
        authMethods: const [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.disabled,
        hasCredential: false,
      );
      expect(disabled.connected, isFalse);
    });

    test('supportsOAuth / supportsApiKey reflect the auth methods list', () {
      const keyOnly = HarnessProviderInfo(
        id: 'x',
        displayName: 'X',
        authMethods: [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.account,
        hasCredential: true,
      );
      expect(keyOnly.supportsApiKey, isTrue);
      expect(keyOnly.supportsOAuth, isFalse);
    });

    test('toJson round-trips through fromJson', () {
      final rebuilt = HarnessProviderInfo.fromJson(info.toJson());
      expect(rebuilt.id, 'anthropic');
      expect(rebuilt.displayName, 'Anthropic');
      expect(rebuilt.authMethods, [
        HarnessAuthMethod.apiKey,
        HarnessAuthMethod.oauth,
      ]);
      expect(rebuilt.isCustom, isFalse);
      expect(rebuilt.dialect, isNull);
      expect(rebuilt.enabled, HarnessProviderEnabled.account);
      expect(rebuilt.hasCredential, isTrue);
      expect(rebuilt.accountLabel, 'Personal');
      expect(rebuilt.baseUrl, 'https://custom.example');
    });

    test('fromJson applies defaults for missing/null fields', () {
      final rebuilt = HarnessProviderInfo.fromJson({});
      expect(rebuilt.id, '');
      expect(rebuilt.displayName, '');
      expect(rebuilt.authMethods, isEmpty);
      expect(rebuilt.isCustom, isFalse);
      expect(rebuilt.enabled, HarnessProviderEnabled.disabled);
      expect(rebuilt.hasCredential, isFalse);
      expect(rebuilt.accountLabel, isNull);
      expect(rebuilt.baseUrl, isNull);
    });

    test('fromJson maps unknown auth-method names to apiKey', () {
      final rebuilt = HarnessProviderInfo.fromJson({
        'id': 'x',
        'display_name': 'X',
        'auth_methods': ['unknown_method'],
      });
      expect(rebuilt.authMethods, [HarnessAuthMethod.apiKey]);
    });

    test('custom provider round-trips dialect + custom flag', () {
      const custom = HarnessProviderInfo(
        id: 'custom-ollama',
        displayName: 'Ollama',
        authMethods: [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.custom,
        hasCredential: false,
        baseUrl: 'http://localhost:11434/v1',
        isCustom: true,
        dialect: CustomProviderDialect.openai,
      );
      final rebuilt = HarnessProviderInfo.fromJson(custom.toJson());
      expect(rebuilt.isCustom, isTrue);
      expect(rebuilt.dialect, CustomProviderDialect.openai);
      expect(rebuilt.baseUrl, 'http://localhost:11434/v1');
    });

    test('toJson omits null accountLabel / baseUrl', () {
      const info = HarnessProviderInfo(
        id: 'x',
        displayName: 'X',
        authMethods: [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.account,
        hasCredential: false,
      );
      final json = info.toJson();
      expect(json.containsKey('account_label'), isFalse);
      expect(json.containsKey('base_url'), isFalse);
    });
  });

  group('HarnessModelInfo', () {
    const model = HarnessModelInfo(
      id: 'anthropic/claude-3',
      providerId: 'anthropic',
      displayName: 'Claude 3',
      inputCostPerMTokens: 3.0,
      outputCostPerMTokens: 15.0,
      contextWindow: 200000,
    );

    test('toJson round-trips through fromJson', () {
      final rebuilt = HarnessModelInfo.fromJson(model.toJson());
      expect(rebuilt.id, 'anthropic/claude-3');
      expect(rebuilt.providerId, 'anthropic');
      expect(rebuilt.displayName, 'Claude 3');
      expect(rebuilt.inputCostPerMTokens, 3.0);
      expect(rebuilt.outputCostPerMTokens, 15.0);
      expect(rebuilt.contextWindow, 200000);
    });

    test('fromJson defaults missing scalars', () {
      final rebuilt = HarnessModelInfo.fromJson({});
      expect(rebuilt.id, '');
      expect(rebuilt.providerId, '');
      expect(rebuilt.displayName, isNull);
      expect(rebuilt.inputCostPerMTokens, isNull);
      expect(rebuilt.outputCostPerMTokens, isNull);
      expect(rebuilt.contextWindow, isNull);
    });

    test('toJson omits null optional fields', () {
      const model = HarnessModelInfo(id: 'm', providerId: 'p');
      final json = model.toJson();
      expect(json, {'id': 'm', 'provider_id': 'p'});
    });

    test('override fields round-trip', () {
      const model = HarnessModelInfo(
        id: 'custom-x/llama',
        providerId: 'custom-x',
        contextWindow: 32768,
        maxOutputTokens: 4096,
        inputModalities: ['text', 'image'],
        outputModalities: ['text'],
        hasOverride: true,
        manual: true,
      );
      final rebuilt = HarnessModelInfo.fromJson(model.toJson());
      expect(rebuilt.maxOutputTokens, 4096);
      expect(rebuilt.inputModalities, ['text', 'image']);
      expect(rebuilt.outputModalities, ['text']);
      expect(rebuilt.hasOverride, isTrue);
      expect(rebuilt.manual, isTrue);
    });

    test('bareId strips the provider prefix', () {
      expect(model.bareId, 'claude-3');
      // A model id may itself contain slashes — only the provider segment is
      // stripped.
      const nested = HarnessModelInfo(
        id: 'openrouter/openai/gpt-4o',
        providerId: 'openrouter',
      );
      expect(nested.bareId, 'openai/gpt-4o');
    });
  });

  group('HarnessOAuthStart', () {
    test('fromJson rebuilds a wire map', () {
      // HarnessOAuthStart is read-only (no toJson on the type) — it is the
      // parsed result of the providers.startOAuth RPC response.
      final rebuilt = HarnessOAuthStart.fromJson({
        'flow_id': 'f1',
        'auth_url': 'https://example/auth',
        'manual_paste': false,
      });
      expect(rebuilt.flowId, 'f1');
      expect(rebuilt.authUrl, 'https://example/auth');
      expect(rebuilt.supportsManualPaste, isFalse);
    });

    test('fromJson defaults', () {
      final rebuilt = HarnessOAuthStart.fromJson({});
      expect(rebuilt.flowId, '');
      expect(rebuilt.authUrl, '');
      expect(rebuilt.supportsManualPaste, isTrue);
    });
  });

  group('HarnessOAuthState / HarnessOAuthStatus', () {
    test(
      'HarnessOAuthState.fromWire parses known names and defaults to pending',
      () {
        expect(
          HarnessOAuthState.fromWire('pending'),
          HarnessOAuthState.pending,
        );
        expect(
          HarnessOAuthState.fromWire('completed'),
          HarnessOAuthState.completed,
        );
        expect(HarnessOAuthState.fromWire('error'), HarnessOAuthState.error);
        expect(HarnessOAuthState.fromWire(null), HarnessOAuthState.pending);
        expect(
          HarnessOAuthState.fromWire('garbage'),
          HarnessOAuthState.pending,
        );
      },
    );

    test('HarnessOAuthStatus.fromJson rebuilds a status map', () {
      final status = HarnessOAuthStatus.fromJson({
        'status': 'completed',
        'account': 'me@example',
        'error': null,
      });
      expect(status.state, HarnessOAuthState.completed);
      expect(status.account, 'me@example');
      expect(status.error, isNull);
    });

    test(
      'HarnessOAuthStatus.fromJson defaults to pending with null extras',
      () {
        final status = HarnessOAuthStatus.fromJson({});
        expect(status.state, HarnessOAuthState.pending);
        expect(status.account, isNull);
        expect(status.error, isNull);
      },
    );
  });

  group('HarnessOAuthStart', () {
    test('a redirect flow carries no user code and accepts a paste', () {
      final start = HarnessOAuthStart.fromJson(const {
        'flow_id': 'f1',
        'auth_url': 'https://auth.example/authorize',
        'manual_paste': true,
      });
      expect(start.userCode, isNull);
      expect(start.isDeviceCode, isFalse);
      expect(start.supportsManualPaste, isTrue);
    });

    test('a device-code flow carries the code and refuses a paste', () {
      // The code has to survive the wire: it is the only thing the user can
      // check the browser prompt against.
      final start = HarnessOAuthStart.fromJson(const {
        'flow_id': 'f2',
        'auth_url': 'https://www.kimi.com/code/authorize_device?user_code=AB12',
        'manual_paste': false,
        'user_code': 'AB12-CD34',
      });
      expect(start.userCode, 'AB12-CD34');
      expect(start.isDeviceCode, isTrue);
      expect(start.supportsManualPaste, isFalse);
    });
  });

  group('harnessProviderMetas', () {
    test('Kimi Code is OAuth-only — there is no plan API key to paste', () {
      final meta = harnessProviderMetas['kimi-code']!;
      expect(meta.supportsOAuth, isTrue);
      expect(meta.supportsApiKey, isFalse);
    });

    test('Moonshot is API-key-only and keyed to its models.dev id', () {
      final meta = harnessProviderMetas['moonshotai']!;
      expect(meta.supportsApiKey, isTrue);
      expect(meta.supportsOAuth, isFalse);
      expect(meta.catalogProviderId, 'moonshotai');
    });

    test('Kimi Code looks up models.dev under kimi-for-coding', () {
      final meta = harnessProviderMetas['kimi-code']!;
      expect(meta.modelsDevProviderId, 'kimi-for-coding');
      expect(meta.catalogProviderId, 'kimi-for-coding');
    });

    test('z.ai looks up models.dev under zhipuai', () {
      final meta = harnessProviderMetas['zai']!;
      expect(meta.modelsDevProviderId, 'zhipuai');
      expect(meta.catalogProviderId, 'zhipuai');
    });
  });
}

/// Local copyWith shim so the connected-is-false test can vary `enabled`
/// without mutating the shared `info` value. HarnessProviderInfo is immutable
/// (no copyWith on the type itself).
extension on HarnessProviderInfo {
  HarnessProviderInfo copyWith({
    String? id,
    String? displayName,
    List<HarnessAuthMethod>? authMethods,
    HarnessProviderEnabled? enabled,
    bool? hasCredential,
    String? accountLabel,
    String? baseUrl,
  }) => HarnessProviderInfo(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    authMethods: authMethods ?? this.authMethods,
    enabled: enabled ?? this.enabled,
    hasCredential: hasCredential ?? this.hasCredential,
    accountLabel: accountLabel ?? this.accountLabel,
    baseUrl: baseUrl ?? this.baseUrl,
  );
}
