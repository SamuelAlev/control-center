import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_worker/cc_worker.dart';
import 'package:test/test.dart';

/// The worker half of the fleet lease protocol.
///
/// The server side is tested (`fleet_scheduler_service_test.dart`,
/// `fleet_rpc_ops_test.dart`) but the protocol AS THE WORKER IMPLEMENTS IT was
/// not, so a drift between the two halves — an op renamed, an argument key
/// changed, a sequence number that skips — would first appear at runtime, on
/// somebody's fleet, as jobs that silently never report.
///
/// So these drive a real [JobExecutor] against a fake transport and assert on
/// the FRAMES it puts on the wire: op names, argument keys, and that every
/// frame survives the `WorkerEventFrame.fromJson` the server performs on
/// receipt. Nothing here mocks [FleetClient] — the point is to exercise the
/// encoding, which is where drift lives.
void main() {
  late _FakeChannel channel;
  late RemoteRpcClient rpc;
  late FleetClient client;
  late Directory cacheDir;

  setUp(() {
    channel = _FakeChannel();
    rpc = RemoteRpcClient(channel)..start();
    client = FleetClient(rpc);
    cacheDir = Directory.systemTemp.createTempSync('cc_worker_job');
  });

  tearDown(() async {
    await channel.close();
    cacheDir.deleteSync(recursive: true);
  });

  LeaseOffer leaseFor({
    Map<String, String> env = const {},
    String prompt = 'say something',
  }) => LeaseOffer(
    jobId: 'job-1',
    workspaceId: 'ws-1',
    kind: 'agentRun',
    specJson: jsonEncode({'agentId': 'agent-1', 'prompt': prompt}),
    leaseExpiresAtIso: DateTime.utc(2026).toIso8601String(),
    env: env,
  );

  Future<void> runJob(LeaseOffer lease) async {
    final executor = JobExecutor(
      lease: lease,
      client: client,
      cacheDir: cacheDir.path,
    )..start();
    await executor.done;
  }

  test('speaks the op names and argument keys the server declares', () async {
    await runJob(leaseFor());

    // `fleet.workerEvents` takes `frames`; `fleet.workerComplete` takes
    // `report`. Those are the server's `requiredArgs`, verbatim — a rename on
    // either side breaks here rather than in production.
    expect(
      channel.opsCalled.toSet(),
      containsAll(<String>{'fleet.workerEvents', 'fleet.workerComplete'}),
    );
    for (final call in channel.callsTo('fleet.workerEvents')) {
      expect(call, contains('frames'));
    }
    for (final call in channel.callsTo('fleet.workerComplete')) {
      expect(call, contains('report'));
    }
  });

  test('every frame decodes with the parser the server uses', () async {
    await runJob(leaseFor());

    final frames = channel.eventFrames;
    expect(frames, isNotEmpty);
    for (final raw in frames) {
      final decoded = WorkerEventFrame.fromJson(raw);
      expect(decoded.jobId, 'job-1');
      expect(decoded.seq, greaterThan(0));
    }
  });

  test('sequence numbers are 1..n with no gaps and no repeats', () async {
    await runJob(leaseFor());

    final seqs = channel.eventFrames
        .map((f) => (f['seq'] as num).toInt())
        .toList();
    expect(seqs, isNotEmpty);
    expect(
      seqs,
      List<int>.generate(seqs.length, (i) => i + 1),
      reason:
          'the server acks a high-water mark and renews the lease from it, so '
          'a gap or a repeat silently strands the job',
    );
  });

  test('the last event is Done and the report agrees with it', () async {
    await runJob(leaseFor());

    final frames = channel.eventFrames;
    expect(WorkerEventFrame.fromJson(frames.last).event, isA<DoneEvent>());

    final report = channel.completionReport!;
    expect(report.jobId, 'job-1');
    expect(report.success, isTrue);
    expect(report.eventsLost, 0);
    expect(
      report.lastSeq,
      (frames.last['seq'] as num).toInt(),
      reason: 'lastSeq must name the final frame actually emitted',
    );
  });

  test('a failed send is counted as lost, never silently dropped', () async {
    channel.failOp('fleet.workerEvents');
    await runJob(leaseFor());

    final report = channel.completionReport!;
    expect(
      report.eventsLost,
      greaterThan(0),
      reason:
          'PRD 20 §8: the completion report stays honest about what never '
          'reached the server',
    );
    expect(report.lastSeq, greaterThan(0));
  });

  test(
    'batches a long output stream instead of one call per line',
    () async {
      // 40 lines is past the 32-event flush threshold, so this also proves the
      // threshold path runs at all — the 250ms timer alone would hide it.
      await runJob(
        leaseFor(
          env: {'CC_JOB_COMMAND': r'for i in $(seq 1 40); do echo line$i; done'},
        ),
      );

      final calls = channel.callsTo('fleet.workerEvents');
      final frames = channel.eventFrames;
      expect(frames.length, greaterThan(40));
      expect(
        calls.length,
        lessThan(frames.length),
        reason: 'events must be batched, not sent one RPC per line',
      );
      expect(channel.completionReport!.success, isTrue);
    },
    // `for … in $(seq …)` is a POSIX shell construct; the Windows runner's
    // shell is cmd.
    testOn: '!windows',
  );

  test(
    'a non-zero exit is reported as a failure with the code',
    () async {
      await runJob(leaseFor(env: {'CC_JOB_COMMAND': 'exit 3'}));

      final report = channel.completionReport!;
      expect(report.success, isFalse);
      expect(
        report.error,
        contains('code 3'),
        reason:
            'the exit code must reach the report — this used to be 127 for '
            'every command with an argument, because the whole command line '
            'was passed as the program name',
      );
    },
    testOn: '!windows',
  );

  test(
    'cancel kills the child and WAITS for it before reporting',
    () async {
      final executor = JobExecutor(
        lease: leaseFor(env: {'CC_JOB_COMMAND': 'sleep 30'}),
        client: client,
        cacheDir: cacheDir.path,
      )..start();

      // Let the subprocess actually start before cancelling it.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await executor.cancel();
      await executor.done.timeout(const Duration(seconds: 10));

      final report = channel.completionReport!;
      expect(report.success, isFalse);
      expect(report.error, contains('cancelled'));
    },
    testOn: '!windows',
  );

  test('never puts the lease env on the wire', () async {
    await runJob(
      leaseFor(env: {'CC_SECRET_TOKEN': 'super-secret-value-do-not-log'}),
    );

    final wire = jsonEncode(channel.frames);
    expect(
      wire,
      isNot(contains('super-secret-value-do-not-log')),
      reason: 'lease env carries credentials; it is never echoed into events',
    );
  });
}

/// A [RemoteRpcChannelPort] that answers `repo/call` locally and records what
/// was asked.
///
/// Deliberately a real transport fake rather than a stubbed [FleetClient]: the
/// encoding between the two is exactly what this file exists to pin.
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();
  final List<Map<String, dynamic>> frames = <Map<String, dynamic>>[];
  final Set<String> _failing = <String>{};
  bool _closed = false;

  /// Makes [op] answer with a JSON-RPC error, so callers see a send failure.
  void failOp(String op) => _failing.add(op);

  /// Op names seen, in order.
  List<String> get opsCalled => [
    for (final f in frames)
      if (f['method'] == 'repo/call')
        ((f['params'] as Map)['op'] as String? ?? ''),
  ];

  /// The `args` maps of every call to [op].
  List<Map<String, dynamic>> callsTo(String op) => [
    for (final f in frames)
      if (f['method'] == 'repo/call' && (f['params'] as Map)['op'] == op)
        ((f['params'] as Map)['args'] as Map).cast<String, dynamic>(),
  ];

  /// Every event frame the worker sent, flattened across batches.
  List<Map<String, dynamic>> get eventFrames => [
    for (final args in callsTo('fleet.workerEvents'))
      for (final raw in (args['frames'] as List))
        (raw as Map).cast<String, dynamic>(),
  ];

  /// The terminal report, or null if the worker never sent one.
  JobCompletionReport? get completionReport {
    final calls = callsTo('fleet.workerComplete');
    if (calls.isEmpty) {
      return null;
    }
    return JobCompletionReport.fromJson(
      (calls.last['report'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => !_closed;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    frames.add(frame);
    final id = frame['id'];
    if (id == null) {
      return; // A notification; nothing to answer.
    }
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    final op = params['op'] as String? ?? '';
    if (_failing.contains(op)) {
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32000, 'message': 'injected failure for $op'},
      });
      return;
    }
    _incoming.add({
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'op': op,
        'data': switch (op) {
          'fleet.workerEvents' => {'ackedSeq': _highWater(params)},
          _ => <String, dynamic>{'ok': true},
        },
      },
    });
  }

  int _highWater(Map<String, dynamic> params) {
    final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
    final list = (args['frames'] as List?) ?? const [];
    var high = 0;
    for (final raw in list) {
      final seq = ((raw as Map)['seq'] as num?)?.toInt() ?? 0;
      if (seq > high) {
        high = seq;
      }
    }
    return high;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _state.add(RemoteChannelState.closed);
    await _incoming.close();
    await _state.close();
  }
}
