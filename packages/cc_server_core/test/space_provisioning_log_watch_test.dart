import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/repos/space_provisioning_log.dart';
import 'package:cc_server_core/src/catalog/space_provisioning_ops.dart';
import 'package:test/test.dart';

void main() {
  late InMemorySpaceProvisioningLog log;
  late WatchQuery query;
  late List<String> asked;

  const grants = {
    'reader': {'repo-a', 'repo-b'},
    'partial': {'repo-a'},
  };

  setUp(() {
    log = InMemorySpaceProvisioningLog()
      ..write('ws-a', 'space-1', 'Copying')
      ..write('ws-b', 'space-1', 'Another workspace');
    asked = [];
    query = buildSpaceProvisioningLogWatchQuery(
      log: log,
      reposExposedBySpace: (ctx) async {
        asked.add(ctx.args['space_id'] as String);
        return ['repo-a', 'repo-b'];
      },
      requireRepoReadGrant:
          ({
            required String workspaceId,
            required String userId,
            required String repoId,
          }) async {
            if (!(grants[userId]?.contains(repoId) ?? false)) {
              throw const AuthException('No read access to this repo');
            }
          },
      assertSpaceOwned: (workspaceId, spaceId) async {
        if (workspaceId == 'ws-other') {
          throw const WorkspaceMismatchException('Not this workspace');
        }
      },
    );
  });

  Stream<Map<String, dynamic>> open({
    String userId = 'reader',
    String workspaceId = 'ws-a',
    Map<String, dynamic> args = const {'space_id': 'space-1'},
  }) => query.handler(
    WatchQueryContext(
      args: args,
      workspaceId: workspaceId,
      deviceId: 'device',
      userId: userId,
    ),
  );

  test('is an event stream, so a burst is not coalesced away', () {
    expect(query.isEventStream, isTrue);
    expect(query.workspaceScoped, isTrue);
  });

  test('streams the space\'s lines with their numbers', () async {
    final first = await open().first;

    expect(first['line'], 'Copying');
    expect(first['seq'], isA<int>());
  });

  test('reads only the workspace it is bound to', () async {
    expect(
      (await open(workspaceId: 'ws-b').first)['line'],
      'Another workspace',
    );
  });

  test('refuses a member with no grant', () async {
    await expectLater(
      open(userId: 'stranger').first,
      throwsA(isA<AuthException>()),
    );
  });

  test('refuses a grant on only some of the repos', () async {
    await expectLater(
      open(userId: 'partial').first,
      throwsA(isA<AuthException>()),
    );
  });

  test('refuses a space of another workspace before anything else', () async {
    await expectLater(
      open(workspaceId: 'ws-other').first,
      throwsA(isA<WorkspaceMismatchException>()),
    );
    expect(asked, isEmpty);
  });

  test('refuses a missing space id', () async {
    await expectLater(
      open(args: const {}).first,
      throwsA(isA<ValidationException>()),
    );
  });
}
