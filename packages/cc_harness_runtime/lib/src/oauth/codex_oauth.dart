import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/openai_oauth.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// ChatGPT Plus/Pro (Codex) login — the same public client as the Codex CLI
/// and oh-my-pi, against `auth.openai.com`.
///
/// Two shapes, same stored credential:
///
/// - **Browser** ([HarnessOAuthProvider]): PKCE + loopback on port 1455, with
///   `codex_cli_simplified_flow` so ChatGPT shows the Codex consent screen.
/// - **Device** ([HarnessDeviceOAuthProvider]): headless poll used when 1455
///   is busy or the server's loopback is unreachable from the operator's
///   browser. The broker prefers browser and falls back to this.
class CodexOAuth extends OpenAiOAuth implements HarnessDeviceOAuthProvider {
  /// Creates a [CodexOAuth].
  CodexOAuth({super.http})
    : super(
        providerId: id,
        extraAuthorizeParams: const {
          'codex_cli_simplified_flow': 'true',
          'originator': originator,
        },
        fallbackAccountLabel: 'Codex account',
      );

  /// Harness provider id (usage, the credential store, Settings).
  static const String id = 'codex';

  /// Identify this app on the authorize URL and Codex backend headers.
  static const String originator = 'control-center';

  /// Pinned Codex client version. The backend version-gates `/codex/models`
  /// and `/codex/responses` against this (`gpt-6-astra` needs ≥ 0.153.0).
  static const String clientVersion = '0.153.0';

  /// ChatGPT account API origin (`wham/usage`, `/codex/models`, `/codex/responses`).
  static const String backendApi = 'https://chatgpt.com/backend-api';

  /// Metered OpenAI Responses origin used when the operator pastes an API key.
  static const String apiKeyBase = 'https://api.openai.com/v1';

  /// Plan usage endpoint under [backendApi].
  static const String usagePath = '/wham/usage';

  /// Model catalogue under [backendApi].
  static const String modelsPath = '/codex/models';

  /// Streaming completions under [backendApi].
  static const String responsesPath = '/codex/responses';

  static const String _deviceUserCodeUrl =
      'https://auth.openai.com/api/accounts/deviceauth/usercode';
  static const String _deviceTokenUrl =
      'https://auth.openai.com/api/accounts/deviceauth/token';
  static const String _deviceRedirectUri =
      'https://auth.openai.com/deviceauth/callback';
  static const String _deviceAuthUrl = 'https://auth.openai.com/codex/device';

  /// Headers the Codex backend expects on ChatGPT-OAuth requests.
  static Map<String, String> chatgptHeaders({
    required String accessToken,
    String? accountId,
    String? residency,
  }) {
    final id = accountId ?? accountIdFromToken(accessToken);
    final region = residency ?? residencyFromToken(accessToken);
    return {
      'Authorization': 'Bearer $accessToken',
      'OpenAI-Beta': 'responses=experimental',
      'originator': originator,
      'version': clientVersion,
      'User-Agent': 'Control-Center/$clientVersion',
      if (id != null && id.isNotEmpty) 'ChatGPT-Account-Id': id,
      if (region != null && region.isNotEmpty)
        'x-openai-internal-codex-residency': region,
    };
  }

  /// `chatgpt_account_id` from a Codex JWT, or null when absent/unparseable.
  static String? accountIdFromToken(String? token) {
    final auth = decodeJwtClaims(token)['https://api.openai.com/auth'];
    if (auth is! Map) {
      return null;
    }
    final id = auth['chatgpt_account_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// Workspace data-residency claim, when the account is region-pinned.
  static String? residencyFromToken(String? token) {
    final auth = decodeJwtClaims(token)['https://api.openai.com/auth'];
    if (auth is! Map) {
      return null;
    }
    for (final key in const [
      'chatgpt_data_residency',
      'chatgpt_compute_residency',
    ]) {
      final value = auth[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Whether [host] is a ChatGPT origin we may send the OAuth bearer to.
  static bool isChatgptHost(String host) {
    final h = host.toLowerCase();
    return h == 'chatgpt.com' ||
        h.endsWith('.chatgpt.com') ||
        h == 'chat.openai.com' ||
        h.endsWith('.chat.openai.com');
  }

  @override
  Future<HarnessDeviceAuthorization> authorize() async {
    final json = await http.postJson(
      Uri.parse(_deviceUserCodeUrl),
      headers: const {'Accept': 'application/json'},
      body: const {'client_id': OpenAiOAuth.clientId},
    );
    final deviceAuthId = json['device_auth_id'] as String?;
    final userCode = json['user_code'] as String?;
    if (deviceAuthId == null ||
        deviceAuthId.isEmpty ||
        userCode == null ||
        userCode.isEmpty) {
      throw const HarnessDeviceAuthException(
        'Codex device authorization response was missing required fields.',
      );
    }
    final intervalSec = _intervalSeconds(json['interval']);
    return HarnessDeviceAuthorization(
      // Poll needs both ids; `|` is not in either field.
      deviceCode: '$deviceAuthId|$userCode',
      userCode: userCode,
      verificationUri: _deviceAuthUrl,
      interval: Duration(seconds: intervalSec + 3),
      expiresIn: const Duration(minutes: 15),
    );
  }

  @override
  Future<ProviderCredential?> poll(String deviceCode) async {
    final split = deviceCode.split('|');
    if (split.length < 2) {
      throw const HarnessDeviceAuthException(
        'Codex sign-in is missing its poll secret. Start the login again.',
      );
    }
    final deviceAuthId = split.first;
    final userCode = split.sublist(1).join('|');
    final Map<String, dynamic> json;
    try {
      json = await http.postJson(
        Uri.parse(_deviceTokenUrl),
        headers: const {'Accept': 'application/json'},
        body: {'device_auth_id': deviceAuthId, 'user_code': userCode},
      );
    } on ProviderHttpException catch (e) {
      // 403/404 = authorization still pending.
      if (e.statusCode == 403 || e.statusCode == 404) {
        return null;
      }
      throw HarnessDeviceAuthException(
        'Codex device token polling failed: ${e.statusCode}',
      );
    }
    final authCode = json['authorization_code'] as String?;
    final verifier = json['code_verifier'] as String?;
    if (authCode == null ||
        authCode.isEmpty ||
        verifier == null ||
        verifier.isEmpty) {
      throw const HarnessDeviceAuthException(
        'Codex device token response was missing authorization_code or '
        'code_verifier.',
      );
    }
    return exchangeCode(
      code: authCode,
      verifier: verifier,
      redirectUri: _deviceRedirectUri,
    );
  }

  static int _intervalSeconds(Object? raw) {
    if (raw is num) {
      final n = raw.toInt();
      return n > 0 ? n : 5;
    }
    if (raw is String) {
      final n = int.tryParse(raw);
      if (n != null && n > 0) {
        return n;
      }
    }
    return 5;
  }
}
