import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcHarnessProviderRepository] — the provider/credential surface
/// over RPC. Pins the providers.* ops + args shape and the wire→DTO mapping.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcHarnessProviderRepository.listProviders', () {
    test('maps the providers array', () async {
      host.callResults['providers.list'] = {
        'providers': [
          {
            'id': 'anthropic',
            'display_name': 'Anthropic',
            'auth_methods': ['apiKey', 'oauth'],
            'is_local': false,
            'enabled_via': 'credential',
            'has_credential': true,
            'account_label': 'sam@example.com',
          },
        ],
      };
      final repo = RpcHarnessProviderRepository(client);
      final providers = await repo.listProviders();
      expect(providers.length, 1);
      final p = providers.first;
      expect(p.id, 'anthropic');
      expect(p.displayName, 'Anthropic');
      expect(p.authMethods.length, 2);
      expect(p.hasCredential, isTrue);
      expect(p.accountLabel, 'sam@example.com');
      expect(host.lastCall('providers.list')!.args, isEmpty);
    });

    test('returns empty when the key is absent', () async {
      host.callResults['providers.list'] = const {};
      final repo = RpcHarnessProviderRepository(client);
      expect(await repo.listProviders(), isEmpty);
    });
  });

  group('RpcHarnessProviderRepository.listModels', () {
    test('maps the models array and forwards provider_id', () async {
      host.callResults['providers.listModels'] = {
        'models': [
          {
            'id': 'anthropic/claude-opus',
            'provider_id': 'anthropic',
            'display_name': 'Opus',
            'context_window': 200000,
          },
        ],
      };
      final repo = RpcHarnessProviderRepository(client);
      final models = await repo.listModels(providerId: 'anthropic');
      expect(models.first.id, 'anthropic/claude-opus');
      expect(models.first.contextWindow, 200000);
      expect(
        host.lastCall('providers.listModels')!.args['provider_id'],
        'anthropic',
      );
    });

    test('omits provider_id when null', () async {
      host.callResults['providers.listModels'] = const {'models': []};
      final repo = RpcHarnessProviderRepository(client);
      await repo.listModels();
      expect(
        host.lastCall('providers.listModels')!.args.containsKey('provider_id'),
        isFalse,
      );
    });
  });

  group('RpcHarnessProviderRepository credentials', () {
    test('saveApiKey forwards provider_id + key + optional fields', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.saveApiKey(
        providerId: 'anthropic',
        apiKey: 'sk-x',
        baseUrl: 'https://api',
        accountLabel: 'work',
      );
      final call = host.lastCall('providers.saveApiKey')!;
      expect(call.args['provider_id'], 'anthropic');
      expect(call.args['api_key'], 'sk-x');
      expect(call.args['base_url'], 'https://api');
      expect(call.args['account_label'], 'work');
    });

    test('removeCredential forwards provider_id + account_label', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.removeCredential(
        providerId: 'anthropic',
        accountLabel: 'work',
      );
      final call = host.lastCall('providers.removeCredential')!;
      expect(call.args['provider_id'], 'anthropic');
      expect(call.args['account_label'], 'work');
    });
  });

  group('RpcHarnessProviderRepository custom providers', () {
    test(
      'addCustomProvider forwards the definition and returns the id',
      () async {
        host.callResults['providers.addCustom'] = {'id': 'custom-ollama'};
        final repo = RpcHarnessProviderRepository(client);
        final id = await repo.addCustomProvider(
          displayName: 'Ollama',
          dialect: CustomProviderDialect.openai,
          baseUrl: 'http://localhost:11434/v1',
        );
        expect(id, 'custom-ollama');
        final call = host.lastCall('providers.addCustom')!;
        expect(call.args['display_name'], 'Ollama');
        expect(call.args['dialect'], 'openai');
        expect(call.args['base_url'], 'http://localhost:11434/v1');
        expect(call.args.containsKey('api_key'), isFalse);
      },
    );

    test('addCustomProvider includes a non-empty api_key', () async {
      host.callResults['providers.addCustom'] = {'id': 'custom-proxy'};
      final repo = RpcHarnessProviderRepository(client);
      await repo.addCustomProvider(
        displayName: 'Internal proxy',
        dialect: CustomProviderDialect.anthropic,
        baseUrl: 'https://llm.internal.example',
        apiKey: 'sk-priv',
      );
      final call = host.lastCall('providers.addCustom')!;
      expect(call.args['dialect'], 'anthropic');
      expect(call.args['api_key'], 'sk-priv');
    });

    test('removeCustomProvider forwards the provider_id', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.removeCustomProvider('custom-ollama');
      expect(
        host.lastCall('providers.removeCustom')!.args['provider_id'],
        'custom-ollama',
      );
    });

    test('addCustomProvider forwards hand-registered models', () async {
      host.callResults['providers.addCustom'] = {'id': 'custom-llm'};
      final repo = RpcHarnessProviderRepository(client);
      await repo.addCustomProvider(
        displayName: 'Bare LLM',
        dialect: CustomProviderDialect.openai,
        baseUrl: 'http://localhost:8080/v1',
        models: const {
          'llama-3': ProviderModelOverride(
            contextWindow: 131072,
            inputModalities: ['text', 'image'],
            manual: true,
          ),
        },
      );
      final call = host.lastCall('providers.addCustom')!;
      final models = (call.args['models'] as List).cast<Map>();
      expect(models, hasLength(1));
      expect(models.first['id'], 'llama-3');
      expect(models.first['context_window'], 131072);
      expect(models.first['input_modalities'], ['text', 'image']);
      expect(models.first['manual'], isTrue);
      // Unset fields are omitted, not null — absence means "inherit".
      expect(models.first.containsKey('max_output_tokens'), isFalse);
    });
  });

  group('RpcHarnessProviderRepository model overrides', () {
    test('saveModelOverride forwards the override fields', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.saveModelOverride(
        providerId: 'anthropic',
        modelId: 'claude-opus-4-5',
        override: const ProviderModelOverride(
          contextWindow: 1000000,
          maxOutputTokens: 64000,
        ),
      );
      final call = host.lastCall('providers.saveModelOverride')!;
      expect(call.args['provider_id'], 'anthropic');
      expect(call.args['model_id'], 'claude-opus-4-5');
      expect(call.args['context_window'], 1000000);
      expect(call.args['max_output_tokens'], 64000);
      expect(call.args.containsKey('manual'), isFalse);
    });

    test('removeModelOverride forwards provider + model ids', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.removeModelOverride(
        providerId: 'anthropic',
        modelId: 'claude-opus-4-5',
      );
      final call = host.lastCall('providers.removeModelOverride')!;
      expect(call.args['provider_id'], 'anthropic');
      expect(call.args['model_id'], 'claude-opus-4-5');
    });
  });

  group('RpcHarnessProviderRepository.saveGenerationDefaults', () {
    test('forwards every configured field', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.saveGenerationDefaults(
        providerId: 'custom-mtplx',
        maxTokens: 2048,
        temperature: 0.6,
        topP: 0.95,
        topK: 20,
      );
      final args = host.lastCall('providers.saveGenerationDefaults')!.args;
      expect(args['provider_id'], 'custom-mtplx');
      expect(args['max_tokens'], 2048);
      expect(args['temperature'], 0.6);
      expect(args['top_p'], 0.95);
      expect(args['top_k'], 20);
    });

    test('omits unset fields so the server clears them', () async {
      // "Let the endpoint decide" is expressed by absence, not by a sentinel.
      final repo = RpcHarnessProviderRepository(client);
      await repo.saveGenerationDefaults(
        providerId: 'custom-mtplx',
        maxTokens: 2048,
      );
      final args = host.lastCall('providers.saveGenerationDefaults')!.args;
      expect(args['max_tokens'], 2048);
      expect(args.containsKey('temperature'), isFalse);
      expect(args.containsKey('top_p'), isFalse);
      expect(args.containsKey('top_k'), isFalse);
    });
  });

  group('providers.list generation defaults', () {
    test('maps a provider generation recipe', () async {
      host.callResults['providers.list'] = {
        'providers': [
          {
            'id': 'custom-mtplx',
            'display_name': 'MTPLX',
            'auth_methods': ['apiKey'],
            'enabled_via': 'custom',
            'has_credential': false,
            'custom': true,
            'dialect': 'openai',
            'generation': {'maxTokens': 2048, 'topP': 0.95, 'topK': 20},
          },
        ],
      };
      final repo = RpcHarnessProviderRepository(client);
      final p = (await repo.listProviders()).single;
      expect(p.generation.maxTokens, 2048);
      expect(p.generation.topP, 0.95);
      expect(p.generation.topK, 20);
      expect(p.generation.temperature, isNull);
    });

    test('an absent generation key reads as unconfigured', () async {
      host.callResults['providers.list'] = {
        'providers': [
          {
            'id': 'anthropic',
            'display_name': 'Anthropic',
            'auth_methods': ['apiKey'],
            'enabled_via': 'account',
            'has_credential': true,
          },
        ],
      };
      final repo = RpcHarnessProviderRepository(client);
      expect((await repo.listProviders()).single.generation.isEmpty, isTrue);
    });
  });

  group('RpcHarnessProviderRepository OAuth', () {
    test('startOAuth maps the start DTO', () async {
      host.callResults['providers.startOAuth'] = {
        'flow_id': 'f-1',
        'auth_url': 'https://oauth',
        'manual_paste': false,
      };
      final repo = RpcHarnessProviderRepository(client);
      final start = await repo.startOAuth('anthropic');
      expect(start.flowId, 'f-1');
      expect(start.authUrl, 'https://oauth');
      expect(start.supportsManualPaste, isFalse);
      expect(
        host.lastCall('providers.startOAuth')!.args['provider_id'],
        'anthropic',
      );
    });

    test('oauthStatus maps the status DTO', () async {
      host.callResults['providers.oauthStatus'] = {
        'status': 'completed',
        'account': 'sam@example.com',
      };
      final repo = RpcHarnessProviderRepository(client);
      final status = await repo.oauthStatus('f-1');
      expect(status.state, HarnessOAuthState.completed);
      expect(status.account, 'sam@example.com');
      expect(host.lastCall('providers.oauthStatus')!.args['flow_id'], 'f-1');
    });

    test('completeOAuth forwards flow_id + code', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.completeOAuth(flowId: 'f-1', code: 'c-1');
      final call = host.lastCall('providers.completeOAuth')!;
      expect(call.args['flow_id'], 'f-1');
      expect(call.args['code'], 'c-1');
    });

    test('cancelOAuth forwards the flow_id', () async {
      final repo = RpcHarnessProviderRepository(client);
      await repo.cancelOAuth('f-1');
      expect(host.lastCall('providers.cancelOAuth')!.args['flow_id'], 'f-1');
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
