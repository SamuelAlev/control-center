import 'dart:async';

import 'package:cc_domain/core/domain/ports/space_provisioning_log_port.dart';
import 'package:cc_infra/src/repos/space_provisioning_log.dart';
import 'package:test/test.dart';

void main() {
  /// Everything [log] holds for the space right now.
  Future<List<SpaceProvisioningLogLine>> read(
    InMemorySpaceProvisioningLog log, {
    String workspaceId = 'ws-a',
    String spaceId = 'space-1',
  }) async {
    final lines = <SpaceProvisioningLogLine>[];
    final subscription = log.follow(workspaceId, spaceId).listen(lines.add);
    await pumpEventQueue();
    await subscription.cancel();
    return lines;
  }

  test('a late reader gets what was written, then the live lines', () async {
    final log = InMemorySpaceProvisioningLog()
      ..write('ws-a', 'space-1', 'Copying')
      ..write('ws-a', 'space-1', 'Fetching main');

    final seen = <String>[];
    final subscription = log
        .follow('ws-a', 'space-1')
        .listen((line) => seen.add(line.text));
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    log.write('ws-a', 'space-1', 'Checking out');
    await pumpEventQueue();

    expect(seen, ['Copying', 'Fetching main', 'Checking out']);
  });

  test('a progress bar is one line that rewrites itself', () async {
    final log = InMemorySpaceProvisioningLog();
    for (final line in [
      'Fetching main',
      'Receiving objects:   1% (1/100)',
      'Receiving objects:  50% (50/100)',
      'Receiving objects: 100% (100/100), done.',
      'Resolving deltas:  10% (1/10)',
    ]) {
      log.write('ws-a', 'space-1', line);
    }

    final lines = await read(log);

    expect(lines.map((line) => line.text), [
      'Fetching main',
      'Receiving objects: 100% (100/100), done.',
      'Resolving deltas:  10% (1/10)',
    ]);
  });

  test('a follower sees a rewrite under the number it replaces', () async {
    final log = InMemorySpaceProvisioningLog();
    final seen = <SpaceProvisioningLogLine>[];
    final subscription = log.follow('ws-a', 'space-1').listen(seen.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    log
      ..write('ws-a', 'space-1', 'Receiving objects:  1% (1/100)')
      ..write('ws-a', 'space-1', 'Receiving objects: 50% (50/100)')
      ..write('ws-a', 'space-1', 'Unpacking');
    await pumpEventQueue();

    expect(seen[1].seq, seen[0].seq);
    expect(seen[2].seq, greaterThan(seen[1].seq));
  });

  test('lines are redacted and stripped of terminal control', () async {
    final log = InMemorySpaceProvisioningLog()
      ..write(
        'ws-a',
        'space-1',
        'fatal: https://x-access-token:ghs_secret@github.com/acme/app.git',
      )
      ..write('ws-a', 'space-1', '\x1B[32mdone\x1B[0m')
      ..write('ws-a', 'space-1', 'step 1\rstep 2');

    final lines = (await read(log)).map((line) => line.text).toList();

    expect(lines.join('\n'), isNot(contains('ghs_secret')));
    expect(lines[1], 'done');
    expect(lines[2], 'step 2');
  });

  test('text with several lines keeps them, without the blanks', () async {
    final log = InMemorySpaceProvisioningLog()
      ..write('ws-a', 'space-1', 'one\n\ntwo\n');

    expect((await read(log)).map((line) => line.text), ['one', 'two']);
  });

  test('the same space id in two workspaces shares nothing', () async {
    final log = InMemorySpaceProvisioningLog()
      ..write('ws-a', 'space-1', 'from a')
      ..write('ws-b', 'space-1', 'from b');

    expect((await read(log)).map((line) => line.text), ['from a']);
    expect((await read(log, workspaceId: 'ws-b')).map((line) => line.text), [
      'from b',
    ]);
  });

  test('a space keeps only its newest output', () async {
    final log = InMemorySpaceProvisioningLog(maxCharsPerSpace: 20);
    for (var i = 0; i < 10; i++) {
      log.write('ws-a', 'space-1', 'line $i');
    }

    final lines = (await read(log)).map((line) => line.text).toList();

    expect(lines.last, 'line 9');
    expect(lines, isNot(contains('line 0')));
    expect(lines.join('\n').length, lessThanOrEqualTo(20));
  });

  test('a very long line is cut', () async {
    final log = InMemorySpaceProvisioningLog(maxLineChars: 10)
      ..write('ws-a', 'space-1', 'x' * 100);

    expect((await read(log)).single.text, '${'x' * 10}…');
  });

  test('old spaces go first, but never one being followed', () async {
    final log = InMemorySpaceProvisioningLog(maxSpaces: 2)
      ..write('ws-a', 'followed', 'kept')
      ..write('ws-a', 'idle', 'dropped');
    final seen = <String>[];
    final subscription = log
        .follow('ws-a', 'followed')
        .listen((line) => seen.add(line.text));
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    log
      ..write('ws-a', 'new-1', 'a')
      ..write('ws-a', 'new-2', 'b')
      ..write('ws-a', 'followed', 'still here');
    await pumpEventQueue();

    expect(seen, ['kept', 'still here']);
    expect(await read(log, spaceId: 'idle'), isEmpty);
  });

  test('a rebuilt log numbers past the one it replaced', () async {
    final log = InMemorySpaceProvisioningLog(maxSpaces: 1)
      ..write('ws-a', 'space-1', 'before');
    final before = (await read(log)).single.seq;

    log.write('ws-a', 'other', 'evicts it');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    log.write('ws-a', 'space-1', 'after');

    expect((await read(log)).single.seq, greaterThan(before));
  });

  test('elapsed time reads the way a person says it', () {
    expect(provisioningElapsed(const Duration(seconds: 8)), '8s');
    expect(provisioningElapsed(const Duration(seconds: 125)), '2m 05s');
  });
}
