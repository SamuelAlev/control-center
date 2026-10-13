import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/evaluation/controlled_claude_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/controlled_claude_mcp_bridge.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_skill_evaluation.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  tearDownAll(ControlledEvaluationProcess.disposeRuntime);
  final unsupported = ControlledEvaluationProcess.capabilityReason();

  test(
    'MCP bridge confines reads and records only successful pinned loads',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cc-native-tools-',
      );
      final root = await Directory(p.join(directory.path, 'work')).create();
      final skill = File(
        p.join(root.path, '.agents', 'skills', 'demo', 'SKILL.md'),
      );
      await skill.parent.create(recursive: true);
      await skill.writeAsString('Pinned skill body');
      final secret = File(p.join(directory.path, 'host-secret'));
      await secret.writeAsString('DO NOT LEAK');
      final bridge = ControlledClaudeMcpBridge(
        root: root.path,
        cancellation: CancellationToken.none,
        visibleSkillHashes: const {'demo': 'sha256-pinned'},
        visibleSkillFiles: const {
          'demo': {'SKILL.md'},
        },
      );
      try {
        await bridge.start();
        Future<Map<String, dynamic>> call(
          String method, [
          Object? params,
        ]) async {
          final client = HttpClient();
          try {
            final request = await client.postUrl(Uri.parse(bridge.url));
            request.headers.set('Authorization', 'Bearer ${bridge.token}');
            request.headers.contentType = ContentType.json;
            request.write(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': 1,
                'method': method,
                if (params != null) 'params': params,
              }),
            );
            final response = await request.close();
            return jsonDecode(await utf8.decoder.bind(response).join())
                as Map<String, dynamic>;
          } finally {
            client.close(force: true);
          }
        }

        final unauthenticated = HttpClient();
        try {
          final request = await unauthenticated.postUrl(Uri.parse(bridge.url));
          request.write(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'}),
          );
          final response = await request.close();
          expect(response.statusCode, HttpStatus.forbidden);
          await response.drain<void>();
        } finally {
          unauthenticated.close(force: true);
        }
        final tools = await call('tools/list');
        expect((tools['result'] as Map)['tools'], hasLength(6));
        final denied = await call('tools/call', {
          'name': 'read',
          'arguments': {
            'path': secret.path,
            'call_description': 'Read host secret',
          },
        });
        expect(jsonEncode(denied), isNot(contains('DO NOT LEAK')));
        expect(bridge.skillEvents, isEmpty);
        final pinned = await call('tools/call', {
          'name': 'read',
          'arguments': {
            'path': '.agents/skills/demo/SKILL.md',
            'call_description': 'Read pinned skill',
          },
        });
        expect(jsonEncode(pinned), contains('Pinned skill body'));
        expect(bridge.skillEvents.single.kind, 'body_load');
        expect(bridge.skillEvents.single.skillHash, 'sha256-pinned');
        final mutation = await call('tools/call', {
          'name': 'write',
          'arguments': {
            'path': '.agents/skills/demo/SKILL.md',
            'content': 'tampered',
            'call_description': 'Tamper skill',
          },
        });
        expect((mutation['result'] as Map)['isError'], isTrue);
        expect(await skill.readAsString(), 'Pinned skill body');
      } finally {
        await bridge.close();
        await directory.delete(recursive: true);
      }
    },
    skip: unsupported,
  );

  test(
    'fake Claude native protocol pins MCP-only surface and honest cost',
    () async {
      final directory = await Directory.systemTemp.createTemp('cc-native-cli-');
      try {
        final root = await Directory(p.join(directory.path, 'work')).create();
        final account = await Directory(
          p.join(directory.path, 'account'),
        ).create();
        const accountToken = 'cc-evaluation-only-access-token';
        await File(p.join(account.path, '.credentials.json')).writeAsString(
          jsonEncode({
            'claudeAiOauth': {'accessToken': accountToken},
          }),
        );
        final executable = File(p.join(directory.path, 'claude'));
        await executable.writeAsString('''#!/usr/bin/python3
import json, sys, pathlib, urllib.request, os
args = sys.argv[1:]
if '--version' in args:
 print('2.1.293 (Claude Code)'); sys.exit()
if '--help' in args:
 print(' '.join(['--tools','--strict-mcp-config','--setting-sources',
 '--disable-slash-commands','--system-prompt','--permission-mode',
 '--no-session-persistence','--max-budget-usd','--mcp-config',
 '--input-format','--output-format','--model','--allowedTools'])); sys.exit()
assert args[args.index('--tools')+1] == ''
assert args[args.index('--setting-sources')+1] == ''
assert sorted(args[args.index('--allowedTools')+1].split(',')) == [
 'mcp__cc_controlled__bash','mcp__cc_controlled__edit',
 'mcp__cc_controlled__find','mcp__cc_controlled__read',
 'mcp__cc_controlled__search','mcp__cc_controlled__write']
assert '--bare' not in args
assert '--dangerously-skip-permissions' not in args
assert 'ANTHROPIC_API_KEY' not in os.environ
assert 'OPENAI_API_KEY' not in os.environ
assert 'CLAUDE_CODE_OAUTH_TOKEN' not in os.environ
credential = pathlib.Path(os.environ['CLAUDE_CONFIG_DIR']) / '.credentials.json'
assert json.loads(credential.read_text())['claudeAiOauth']['accessToken'] == '$accountToken'
assert 'HOME' in os.environ and os.environ['HOME'] != os.environ['CLAUDE_CONFIG_DIR']
assert json.loads(sys.stdin.readline())['type'] == 'user'
config = json.loads(pathlib.Path(args[args.index('--mcp-config')+1]).read_text())
server = config['mcpServers']['cc_controlled']
def rpc(method, params=None):
 data = {'jsonrpc':'2.0','id':1,'method':method}
 if params is not None: data['params'] = params
 req = urllib.request.Request(server['url'], json.dumps(data).encode(),
   {'Authorization':server['headers']['Authorization'],
    'Content-Type':'application/json'})
 return json.load(urllib.request.urlopen(req))['result']
rpc('initialize')
tools = rpc('tools/list')['tools']
assert sorted(t['name'] for t in tools) == ['bash','edit','find','read','search','write']
name = 'mcp__cc_controlled__'
print(json.dumps({'type':'system','subtype':'init','model':'claude-sonnet-4-5',
 'claude_code_version':'2.1.293','mcp_servers':[{'name':'cc_controlled','status':'connected'}],
 'tools':[name + t['name'] for t in tools],
 'plugins':[{'name':'cc-plugin-agents-md','path':'builtin',
   'source':'cc-plugin-agents-md@builtin'},
  {'name':'cc-plugin-plugin-authoring','path':'builtin',
   'source':'cc-plugin-plugin-authoring@builtin'}],
 'skills':[],'slash_commands':[]}),flush=True)
rpc('tools/call',{'name':'read','arguments':{'path':'notice.txt',
 'call_description':'Read fixture'}})
guest = rpc('tools/call',{'name':'bash','arguments':{
 'command':'cat "${account.path}/.credentials.json" 2>/dev/null || printf not-present',
 'description':'Check guest environment'}})
assert 'not-present' in json.dumps(guest) and '$accountToken' not in json.dumps(guest), json.dumps(guest)
print(json.dumps({'type':'result','subtype':'success','total_cost_usd':0.004,
 'usage':{'input_tokens':5,'output_tokens':2}}),flush=True)
''');
        await Process.run('chmod', ['+x', executable.path]);
        await File(p.join(root.path, 'notice.txt')).writeAsString('hello');
        final backend = ControlledClaudeEvaluationBackend(
          executable: executable.path,
          configDir: account.path,
          cancellation: CancellationToken.none,
          budgetMicros: 100000,
          systemPrompt: 'Only controlled MCP tools',
          visibleSkillHashes: const {},
          commandGuard: (_) async => null,
        );
        expect(
          await ControlledClaudeEvaluationBackend.capabilityReason(
            executable: executable.path,
            configDir: account.path,
          ),
          isNull,
        );
        final attempt = await backend.execute(
          EvaluationAttemptRequest(
            task: EvaluationTask(
              id: 't',
              kind: EvaluationTaskKind.bugfix,
              prompt: 'Read notice',
              verifiers: const [],
            ),
            arm: const EvaluationArm(
              id: 'candidate',
              axis: EvaluationAxis.skillIntervention,
              skillExposure: SkillExposure.available,
            ),
            effective: const EvaluationEffectiveConfig(
              adapter: 'claude-cli',
              providerId: 'anthropic',
              modelId: 'claude-sonnet-4-5',
              skillExposure: SkillExposure.available,
            ),
            manifest: EvaluationManifest(
              corpusId: 'c',
              corpusHash: 'hash',
              adapter: 'claude-cli',
              providerId: 'anthropic',
              modelId: 'claude-sonnet-4-5',
              toolCatalog: const [],
              toolCatalogHash: 'hash',
              skillKey: 'k',
              skillHash: 'h',
              ambientSkillHashes: const {},
              skillComparison: 'available',
              skillSnapshotMetadata: const {},
              configHash: 'hash',
            ),
            workspaceRoot: root.path,
            stratum: CacheStratum.cold,
            repetition: 0,
            seed: 1,
            ordinal: 0,
            attemptId: 'attempt',
          ),
        );
        expect(attempt.completed, isTrue, reason: attempt.error);
        expect(attempt.cost.estimatedApiMicros, 4000);
        expect(attempt.servedModel, 'claude-sonnet-4-5');
        expect(attempt.toolEvents.map((event) => event.name), ['read', 'bash']);
        expect(attempt.toolEvents.every((event) => !event.isError), isTrue);
        final files = {
          'SKILL.md': utf8.encode(
            '---\nname: demo\ndescription: Test skill\n---\nRead notice.txt.\n',
          ),
        };
        final campaign = await ControlledSkillEvaluation(
          workspaceId: 'native-test',
          campaignId: 'budget-overshoot',
          adapter: 'claude-cli',
          providerId: 'anthropic',
          modelId: 'claude-sonnet-4-5',
          claudeExecutable: executable.path,
          claudeConfigDir: account.path,
          candidate: SkillPackageSnapshot(
            slug: 'demo',
            origin: 'workspace',
            files: files,
            packageHash: SkillPackageSnapshot.computeHash(files),
          ),
          comparison: SkillComparison.absent,
          corpus: const EvaluationCorpus(
            id: 'native-budget',
            tasks: [
              EvaluationTask(
                id: 'notice',
                kind: EvaluationTaskKind.bugfix,
                prompt: 'Read notice.txt.',
                inlineFiles: {'notice.txt': 'hello'},
                verifiers: [],
              ),
            ],
          ),
          budgetMicros: 1000,
          repetitions: 2,
          outDir: p.join(directory.path, 'campaign'),
          cancellation: CancellationToken.none,
          onAttempt: (_) async {},
        ).run();
        expect(campaign.report.coverageComplete, isFalse);
        expect(campaign.report.attempts, hasLength(1));
        expect(campaign.report.attempts.single.completed, isTrue);
        expect(campaign.report.attempts.single.cost.estimatedApiMicros, 4000);
      } finally {
        await directory.delete(recursive: true);
      }
    },
    skip: unsupported,
  );

  test('uncontrolled native tool surface halts with unknown spend', () async {
    final directory = await Directory.systemTemp.createTemp(
      'cc-native-reject-',
    );
    try {
      final work = await Directory(p.join(directory.path, 'work')).create();
      final account = await Directory(
        p.join(directory.path, 'account'),
      ).create();
      final fake = File(p.join(directory.path, 'claude'));
      await fake.writeAsString('''#!/bin/sh
read prompt
printf '%s\\n' '{"type":"system","subtype":"init","model":"claude-sonnet-4-5","tools":["Bash"]}'
printf '%s\\n' '{"type":"result","subtype":"success","total_cost_usd":0.002,"usage":{"input_tokens":1,"output_tokens":1}}'
''');
      await Process.run('chmod', ['+x', fake.path]);
      final result =
          await ControlledClaudeEvaluationBackend(
            executable: fake.path,
            configDir: account.path,
            cancellation: CancellationToken.none,
            budgetMicros: 100000,
            systemPrompt: 'Confined tools only',
            visibleSkillHashes: const {},
            commandGuard: (_) async => null,
          ).execute(
            EvaluationAttemptRequest(
              task: const EvaluationTask(
                id: 't',
                kind: EvaluationTaskKind.bugfix,
                prompt: 'Work',
              ),
              arm: const EvaluationArm(
                id: 'candidate',
                axis: EvaluationAxis.skillIntervention,
                skillExposure: SkillExposure.available,
              ),
              effective: const EvaluationEffectiveConfig(
                adapter: 'claude-cli',
                providerId: 'anthropic',
                modelId: 'claude-sonnet-4-5',
                skillExposure: SkillExposure.available,
              ),
              manifest: const EvaluationManifest(
                corpusId: 'c',
                corpusHash: 'hash',
                adapter: 'claude-cli',
                providerId: 'anthropic',
                modelId: 'claude-sonnet-4-5',
              ),
              workspaceRoot: work.path,
              stratum: CacheStratum.cold,
              repetition: 0,
              seed: 1,
              ordinal: 0,
              attemptId: 'attempt',
            ),
          );
      expect(result.completed, isFalse);
      expect(result.error, contains('tool surface'));
      expect(result.cost.isComplete, isFalse);
    } finally {
      await directory.delete(recursive: true);
    }
  }, skip: unsupported);

  test('cancellation terminates the active native process', () async {
    final directory = await Directory.systemTemp.createTemp(
      'cc-native-cancel-',
    );
    final source = CancellationTokenSource();
    try {
      final work = await Directory(p.join(directory.path, 'work')).create();
      final account = await Directory(
        p.join(directory.path, 'account'),
      ).create();
      final ready = File(p.join(directory.path, 'ready'));
      final fake = File(p.join(directory.path, 'claude'));
      await fake.writeAsString('''#!/usr/bin/python3
import pathlib,time
pathlib.Path('${ready.path}').write_text('ready')
time.sleep(30)
''');
      await Process.run('chmod', ['+x', fake.path]);
      final pending =
          ControlledClaudeEvaluationBackend(
            executable: fake.path,
            configDir: account.path,
            cancellation: source.token,
            budgetMicros: 100000,
            systemPrompt: 'Confined tools only',
            visibleSkillHashes: const {},
            commandGuard: (_) async => null,
          ).execute(
            EvaluationAttemptRequest(
              task: const EvaluationTask(
                id: 't',
                kind: EvaluationTaskKind.bugfix,
                prompt: 'Work',
              ),
              arm: const EvaluationArm(
                id: 'candidate',
                axis: EvaluationAxis.skillIntervention,
                skillExposure: SkillExposure.available,
              ),
              effective: const EvaluationEffectiveConfig(
                adapter: 'claude-cli',
                providerId: 'anthropic',
                modelId: 'claude-sonnet-4-5',
                skillExposure: SkillExposure.available,
              ),
              manifest: const EvaluationManifest(
                corpusId: 'c',
                corpusHash: 'hash',
                adapter: 'claude-cli',
                providerId: 'anthropic',
                modelId: 'claude-sonnet-4-5',
              ),
              workspaceRoot: work.path,
              stratum: CacheStratum.cold,
              repetition: 0,
              seed: 1,
              ordinal: 0,
              attemptId: 'attempt',
            ),
          );
      for (var i = 0; i < 250 && !await ready.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(await ready.exists(), isTrue);
      source.cancel();
      final result = await pending.timeout(const Duration(seconds: 5));
      expect(result.completed, isFalse);
      expect(result.cost.isComplete, isFalse);
    } finally {
      source.cancel();
      await directory.delete(recursive: true);
    }
  }, skip: unsupported);

  test('offline API seam cannot target a real provider', () {
    expect(
      () => ControlledClaudeEvaluationBackend(
        executable: '/usr/bin/claude',
        configDir: '/tmp/unused',
        cancellation: CancellationToken.none,
        budgetMicros: 100000,
        systemPrompt: 'test',
        visibleSkillHashes: const {},
        commandGuard: (_) async => null,
        localApiEndpointForTesting: Uri.parse('https://api.anthropic.com'),
      ),
      throwsArgumentError,
    );
  });
}
