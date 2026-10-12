import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const ToolOutputScope _scope = ToolOutputScope(
  workspaceId: 'ws',
  conversationId: 'conv',
  agentId: 'agent',
);

HarnessToolContext _ctx({String? workspaceId = 'ws'}) => HarnessToolContext(
  workingDirectory: '/workspace',
  workspaceId: workspaceId,
  conversationId: 'conv',
  agentId: 'agent',
);

/// Reads a stored output back in full, paging through every bounded slice.
Future<String> _recover(
  ToolOutputStore store,
  ToolOutputReference reference,
) async {
  final buffer = StringBuffer();
  var offset = 0;
  while (true) {
    final result = await store.read(
      _scope,
      reference.handle,
      offsetChars: offset,
      limitChars: kToolOutputReadMaxChars,
    );
    expect(result.status, ToolOutputReadStatus.ok);
    final chunk = result.chunk!;
    buffer.write(chunk.text);
    if (!chunk.hasMore) {
      break;
    }
    offset = chunk.nextOffsetChars;
  }
  return buffer.toString();
}

/// A store that records attempts so "did ingestion even try to store?" is
/// observable, and can fail or decline like a real one.
class _SpyStore implements ToolOutputStore {
  _SpyStore({this.delegate, this.fail = false, this.decline = false});

  final ToolOutputStore? delegate;
  final bool fail;
  final bool decline;
  int puts = 0;

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async {
    puts++;
    if (fail) {
      throw StateError('disk full');
    }
    if (decline) {
      return null;
    }
    return delegate!.put(write);
  }

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) => delegate!.read(
    scope,
    handle,
    offsetChars: offsetChars,
    limitChars: limitChars,
  );

  @override
  Future<void> clearScope(ToolOutputScope scope) => delegate!.clearScope(scope);

  @override
  Future<void> clearConversation(ToolOutputScope scope) =>
      delegate!.clearConversation(scope);
}

void main() {
  group('inline retention for later masking', () {
    // The floor is in estimated tokens and shared with ContextPolicies'
    // masking threshold, so these are derived from the one constant rather
    // than from magic character counts.
    const estimator = TokenEstimator.instance;
    final atFloor =
        'x' * (estimator.charsPerToken * kToolOutputRetentionMinTokens).ceil();

    test(
      'a fittable observation above the floor is stored unchanged',
      () async {
        final store = InMemoryToolOutputStore();
        expect(
          estimator.estimate(atFloor),
          greaterThanOrEqualTo(kToolOutputRetentionMinTokens),
        );
        final observation = await ToolObservationIngest(store: store).ingest(
          toolName: 'bash',
          result: HarnessToolResult.success('exit code 0\n$atFloor'),
          context: _ctx(),
        );

        // The text the model sees is the tool's output, byte for byte.
        expect(observation.content, 'exit code 0\n$atFloor');
        expect(observation.truncated, isFalse);
        expect(observation.storageFailure, isNull);
        // ...and a masking pass may now replace it, because the original is
        // retrievable.
        final reference = observation.reference;
        expect(reference, isNotNull);
        expect(reference!.charLength, observation.content.length);
        expect(reference.previewChars, 0, reason: 'nothing was cut in place');
        expect(await _recover(store, reference), observation.content);
      },
    );

    test('an observation below the floor is not written', () async {
      final spy = _SpyStore(delegate: InMemoryToolOutputStore());
      final content = atFloor.substring(0, atFloor.length - 20);
      expect(
        estimator.estimate(content),
        lessThan(kToolOutputRetentionMinTokens),
      );
      final observation = await ToolObservationIngest(store: spy).ingest(
        toolName: 'bash',
        result: HarnessToolResult.success(content),
        context: _ctx(),
      );
      expect(observation.content, content);
      expect(observation.reference, isNull);
      expect(spy.puts, 0);
    });

    test('an error is never retained (masks skip errors)', () async {
      final spy = _SpyStore(delegate: InMemoryToolOutputStore());
      final observation = await ToolObservationIngest(store: spy).ingest(
        toolName: 'edit',
        result: HarnessToolResult.error('anchor not found\n$atFloor'),
        context: _ctx(),
      );
      expect(observation.content, startsWith('anchor not found'));
      expect(observation.reference, isNull);
      expect(spy.puts, 0);
    });

    test('retention can be switched off', () async {
      final spy = _SpyStore(delegate: InMemoryToolOutputStore());
      final observation =
          await ToolObservationIngest(store: spy, retainMinTokens: 0).ingest(
            toolName: 'bash',
            result: HarnessToolResult.success(atFloor),
            context: _ctx(),
          );
      expect(observation.reference, isNull);
      expect(spy.puts, 0);
    });

    test('a failed retention write loses nothing and warns nothing', () async {
      final observation =
          await ToolObservationIngest(store: _SpyStore(fail: true)).ingest(
            toolName: 'bash',
            result: HarnessToolResult.success(atFloor),
            context: _ctx(),
          );
      // Nothing was dropped, so there is no loss to report: the text is intact
      // and simply cannot be masked recoverably.
      expect(observation.content, atFloor);
      expect(observation.reference, isNull);
      expect(observation.storageFailure, isNull);
    });

    test('retention never rewrites the observation text', () async {
      final store = InMemoryToolOutputStore();
      final content = 'exit code 0\n${'y' * 5000}';
      final observation = await ToolObservationIngest(store: store).ingest(
        toolName: 'bash',
        result: HarnessToolResult.success(content),
        context: _ctx(),
      );
      expect(observation.content, content);
      expect(observation.content, isNot(contains(omittedOutputPrefix)));
      expect(await _recover(store, observation.reference!), content);
    });
  });

  group('results that fit', () {
    test('pass through verbatim without touching the store', () async {
      final spy = _SpyStore(delegate: InMemoryToolOutputStore());
      final ingest = ToolObservationIngest(store: spy);
      final observation = await ingest.ingest(
        toolName: 'bash',
        result: HarnessToolResult.success('exit code 0\nall good'),
        context: _ctx(),
      );
      expect(observation.content, 'exit code 0\nall good');
      expect(observation.truncated, isFalse);
      expect(observation.reference, isNull);
      expect(observation.storageFailure, isNull);
      expect(spy.puts, 0);
    });

    test('a small error is preserved exactly', () async {
      final ingest = ToolObservationIngest(store: InMemoryToolOutputStore());
      final observation = await ingest.ingest(
        toolName: 'edit',
        result: HarnessToolResult.error('anchor not found at line 42'),
        context: _ctx(),
      );
      expect(observation.content, 'anchor not found at line 42');
      expect(observation.reference, isNull);
      expect(observation.truncated, isFalse);
    });
  });

  group('command observations', () {
    test(
      'a compacted build keeps its exit status, diagnostics and handle',
      () async {
        final store = InMemoryToolOutputStore();
        final ingest = ToolObservationIngest(store: store);
        final body = StringBuffer('exit code 1\n');
        for (var i = 0; i < 3000; i++) {
          body.writeln('building target $i: noise noise noise noise noise');
        }
        final raw =
            '${body.toString()}'
            'ERROR: cannot find symbol builder\n'
            'FAIL test/foo_test.dart\n';

        final observation = await ingest.ingest(
          toolName: 'bash',
          result: HarnessToolResult.success(raw),
          context: _ctx(),
        );

        expect(observation.truncated, isTrue);
        expect(
          observation.storageFailure,
          isNull,
          reason: observation.storageFailure,
        );
        expect(observation.reference, isNotNull);
        expect(observation.reference!.charLength, raw.length);
        expect(observation.reference!.toolName, 'bash');
        expect(observation.reference!.previewChars, greaterThan(0));

        final content = observation.content;
        expect(content, startsWith('exit code 1'));
        expect(content, contains('ERROR: cannot find symbol builder'));
        expect(content, contains('FAIL test/foo_test.dart'));
        expect(content, contains('diagnostic'));
        expect(content, contains(observation.reference!.handle));
        expect(content, contains('read_output'));
        expect(content.length, lessThan(raw.length));
        // The blind head/tail of build noise would not have contained these.
        expect(
          content,
          isNot(
            contains('noise noise noise noise noise\nbuilding target 2900'),
          ),
        );

        expect(
          await _recover(store, observation.reference!),
          raw,
          reason: 'the original must be retrievable byte for byte',
        );
      },
    );

    test('a test-runner failure summary is surfaced, and the block stays '
        'recoverable', () async {
      final store = InMemoryToolOutputStore();
      final raw = StringBuffer('exit code 1\n');
      for (var i = 0; i < 2500; i++) {
        raw.writeln('00:0${i % 10} +$i: some passing test in a big suite');
      }
      raw
        ..writeln('00:59 +2499 -1: test/a_test.dart: adds numbers [E]')
        ..writeln('  Expected: <3>')
        ..writeln('    Actual: <4>')
        ..writeln('Some tests failed.');

      final observation = await ToolObservationIngest(store: store).ingest(
        toolName: 'bash',
        result: HarnessToolResult.success(raw.toString()),
        context: _ctx(),
      );

      // The runner's own summary is what tells a model the call failed even
      // when it never reads the failure block: keep it, and keep the way back
      // to the detail.
      expect(observation.content, contains('exit code 1'));
      expect(observation.content, contains('Some tests failed.'));
      expect(observation.content, contains('diagnostic'));
      expect(observation.content, contains(observation.reference!.handle));
      expect(await _recover(store, observation.reference!), raw.toString());
    });

    test('output with no failure line keeps the head/tail policy', () async {
      final raw = StringBuffer('exit code 0\n');
      for (var i = 0; i < 3000; i++) {
        raw.writeln('log line $i with plenty of padding text to be long');
      }
      final ingest = ToolObservationIngest(store: InMemoryToolOutputStore());
      final observation = await ingest.ingest(
        toolName: 'bash',
        result: HarnessToolResult.success(raw.toString()),
        context: _ctx(),
      );
      expect(observation.truncated, isTrue);
      expect(observation.content, contains('exit code 0'));
      expect(observation.content, contains('log line 2999'));
      expect(observation.content, contains(omittedOutputPrefix));
    });

    test('a non-CC command shape falls back to the generic slice', () async {
      final raw = 'plain output\n${'x' * 60000}';
      final ingest = ToolObservationIngest(store: InMemoryToolOutputStore());
      final observation = await ingest.ingest(
        toolName: 'shell',
        result: HarnessToolResult.success(raw),
        context: _ctx(),
      );
      expect(observation.truncated, isTrue);
      expect(observation.content, contains(omittedOutputPrefix));
    });
  });

  group('read observations', () {
    test('keeps an exact head and an exact resume offset', () async {
      final store = InMemoryToolOutputStore();
      final ingest = ToolObservationIngest(store: store);
      final raw = List.generate(
        6000,
        (i) => '${i + 1}\tfinal value$i = compute($i);',
      ).join('\n');

      final observation = await ingest.ingest(
        toolName: 'read',
        args: const {'path': 'lib/big.dart'},
        result: HarnessToolResult.success(raw),
        context: _ctx(),
      );

      final reference = observation.reference!;
      expect(reference.charLength, raw.length);
      final resume = int.parse(
        RegExp(r'offset: (\d+)').firstMatch(observation.content)!.group(1)!,
      );
      // The head shown is exactly the original's prefix, so the offset is an
      // exact continuation point rather than an estimate.
      expect(observation.content, startsWith(raw.substring(0, resume)));
      expect(reference.previewChars, greaterThanOrEqualTo(resume));
      expect(reference.previewChars, lessThanOrEqualTo(resume + 1));

      expect(await _recover(store, reference), raw);
      // Resuming exactly at the marker continues the file with nothing lost
      // and nothing repeated.
      final result = await store.read(
        _scope,
        reference.handle,
        offsetChars: resume,
        limitChars: kToolOutputReadMaxChars,
      );
      expect(
        result.chunk!.text,
        raw.substring(resume, resume + kToolOutputReadMaxChars),
      );
    });
  });

  group('search observations', () {
    String searchOutput() {
      final lines = <String>[];
      for (var file = 0; file < 40; file++) {
        for (var match = 0; match < 50; match++) {
          lines.add(
            'lib/file$file.dart:${match * 10 + 1}: final x$match = $file;',
          );
        }
      }
      return lines.join('\n');
    }

    test('groups matches by file with exact line numbers', () async {
      final store = InMemoryToolOutputStore();
      final raw = searchOutput();
      final ingest = ToolObservationIngest(store: store);
      final observation = await ingest.ingest(
        toolName: 'search',
        args: const {'pattern': 'final x'},
        result: HarnessToolResult.success(raw),
        context: _ctx(),
      );

      final content = observation.content;
      expect(observation.truncated, isTrue);
      expect(content, contains('lib/file0.dart'));
      expect(content, contains(observation.reference!.handle));

      // Every listed match line is a verbatim `path:line:text` from the
      // original, so line numbers stay exact.
      final listed = content
          .split('\n')
          .where((line) => RegExp(r'^  \d+: ').hasMatch(line))
          .toList();
      expect(listed, isNotEmpty);
      expect(listed.length, lessThanOrEqualTo(25 * 8));
      final originals = raw.split('\n').toSet();
      var path = '';
      for (final line in content.split('\n')) {
        if (line.startsWith('lib/file') && line.endsWith('.dart')) {
          path = line;
        }
        final match = RegExp(r'^  (\d+): (.*)$').firstMatch(line);
        if (match != null) {
          expect(
            originals,
            contains('$path:${match.group(1)}:${match.group(2)}'),
          );
        }
      }

      expect(await _recover(store, observation.reference!), raw);
    });

    test('per-file caps retain matches from the last admitted file', () async {
      final observation =
          await ToolObservationIngest(
            formatter: const ToolObservationFormatter(
              maxSearchFiles: 2,
              maxMatchesPerFile: 2,
            ),
          ).ingest(
            toolName: 'search',
            result: HarnessToolResult.success(searchOutput()),
            context: _ctx(),
          );
      final parsed = <String, List<String>>{};
      String? path;
      for (final line in observation.content.split('\n')) {
        if (line.startsWith('lib/file') && line.endsWith('.dart')) {
          path = line;
          parsed.putIfAbsent(path, () => []);
        } else if (path != null && RegExp(r'^  \d+: ').hasMatch(line)) {
          parsed[path]!.add(line);
        }
      }
      expect(parsed.keys, ['lib/file0.dart', 'lib/file1.dart']);
      expect(parsed.values.map((rows) => rows.length), [2, 2]);
    });

    test('a bridged search tool name is recognized', () async {
      final store = InMemoryToolOutputStore();
      final ingest = ToolObservationIngest(store: store);
      final observation = await ingest.ingest(
        toolName: 'mcp__fs__search',
        result: HarnessToolResult.success(searchOutput()),
        context: _ctx(),
      );
      expect(observation.content, contains('lib/file0.dart'));
      expect(observation.content, contains('narrow the pattern'));
    });
  });

  group('storage outcomes and caps never claim recoverability', () {
    Future<ToolObservation> ingestLarge({
      required ToolObservationIngest ingest,
      required HarnessToolContext context,
    }) => ingest.ingest(
      toolName: 'bash',
      result: HarnessToolResult.success(
        'exit code 1\n${'noise\n' * 12000}error: nope',
      ),
      context: context,
    );

    test('no store wired', () async {
      final observation = await ingestLarge(
        ingest: ToolObservationIngest(),
        context: _ctx(),
      );
      expect(observation.truncated, isTrue);
      expect(observation.reference, isNull);
      expect(observation.recoverable, isFalse);
      expect(observation.storageFailure, contains('no tool-output store'));
      expect(observation.content, contains('original not stored'));
      expect(observation.content, isNot(contains('read_output')));
    });

    test('a run with no workspace scope', () async {
      final spy = _SpyStore(delegate: InMemoryToolOutputStore());
      final observation = await ingestLarge(
        ingest: ToolObservationIngest(store: spy),
        context: _ctx(workspaceId: null),
      );
      expect(observation.reference, isNull);
      expect(observation.storageFailure, contains('workspace scope'));
      expect(spy.puts, 0, reason: 'an unscoped run must not write anywhere');
      expect(observation.content, contains('original not stored'));
    });

    test('a store that throws', () async {
      final observation = await ingestLarge(
        ingest: ToolObservationIngest(store: _SpyStore(fail: true)),
        context: _ctx(),
      );
      expect(observation.reference, isNull);
      expect(observation.recoverable, isFalse);
      expect(observation.storageFailure, contains('failed'));
      expect(observation.content, contains('original not stored'));
    });

    test('a store that declines the write', () async {
      final spy = _SpyStore(decline: true);
      final observation = await ingestLarge(
        ingest: ToolObservationIngest(store: spy),
        context: _ctx(),
      );
      expect(spy.puts, 1);
      expect(observation.reference, isNull);
      expect(observation.storageFailure, contains('declined'));
      expect(observation.content, contains('original not stored'));
    });
    test(
      'a line-capped observation is cut by lines, not claimed empty',
      () async {
        final store = InMemoryToolOutputStore();
        final ingest = ToolObservationIngest(
          store: store,
          limits: const ToolOutputLimitTable(
            overrides: {
              'read': ToolOutputLimits(
                characterLimit: 0,
                lineLimit: 50,
                direction: TruncateDirection.head,
              ),
            },
          ),
        );
        final raw = List.generate(200, (i) => 'line $i').join('\n');
        final observation = await ingest.ingest(
          toolName: 'read',
          result: HarnessToolResult.success(raw),
          context: _ctx(),
        );
        expect(observation.truncated, isTrue);
        expect(observation.content, startsWith('line 0'));
        expect(observation.content, contains('line 49'));
        expect(observation.content, contains(omittedOutputPrefix));
        expect(
          observation.content,
          isNot(matches(RegExp(r'omitted: 0 chars'))),
        );
        expect(await _recover(store, observation.reference!), raw);
      },
    );
  });

  group('error and generic observations', () {
    test(
      'an enormous error keeps its head verbatim and stays recoverable',
      () async {
        final store = InMemoryToolOutputStore();
        final ingest = ToolObservationIngest(store: store);
        final raw =
            'fatal: merge conflict in lib/a.dart\n${'context line\n' * 12000}';
        final observation = await ingest.ingest(
          toolName: 'edit',
          result: HarnessToolResult.error(raw),
          context: _ctx(),
        );
        expect(
          observation.content,
          startsWith('fatal: merge conflict in lib/a.dart'),
        );
        expect(observation.content, contains(observation.reference!.handle));
        expect(await _recover(store, observation.reference!), raw);
      },
    );

    test('a generic over-long result keeps head and tail', () async {
      final ingest = ToolObservationIngest(store: InMemoryToolOutputStore());
      final raw = '${'H' * 40000}${'T' * 40000}';
      final observation = await ingest.ingest(
        toolName: 'write',
        result: HarnessToolResult.success(raw),
        context: _ctx(),
      );
      expect(observation.truncated, isTrue);
      expect(observation.content, startsWith('H'));
      expect(observation.content, endsWith('T'));
      expect(observation.content, contains(omittedOutputPrefix));
      expect(observation.reference!.charLength, raw.length);
    });
  });
}
