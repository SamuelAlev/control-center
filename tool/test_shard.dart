// Splits the test files under a root directory into balanced shards and prints
// the files belonging to one shard, one per line.
//
// Usage:
//   dart run tool/test_shard.dart --index 0 --total 6 --output shard.txt [--root test]
//
// The file list goes to `--output`, not stdout: `dart run` prints build-hook
// progress ("Running build hooks...") to stdout in this workspace and that
// would be captured as a bogus test path.
//
// Why this exists instead of `flutter test --total-shards/--shard-index`:
// package:test applies those flags *inside* each suite (see `_shardSuite` in
// test_core's runner.dart) — every shard still loads and compiles every test
// file and only runs a slice of the `test()` cases in it. For a Flutter app
// suite the compile + `flutter_tester` boot per file is the dominant cost, so
// that form of sharding parallelizes almost nothing. Splitting the *file list*
// is what actually divides the work.
//
// Balance is by file size rather than file count: a shard's cost tracks how
// many test cases it carries and bytes are a closer proxy for that than a file
// count that weighs a 20-line file the same as a 900-line one.
import 'dart:io';

void main(List<String> args) {
  final options = _parseArgs(args);

  final rootDir = Directory(options.root);
  if (!rootDir.existsSync()) {
    _fail('Test root not found: ${options.root}');
  }

  final files =
      rootDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .toList()
        // Sort by path so the input to the packer is identical on every runner;
        // the split must be reproducible or shards would overlap or drop files.
        ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    _fail('No *_test.dart files found under ${options.root}');
  }
  if (options.total > files.length) {
    _fail(
      'Requested ${options.total} shards but only ${files.length} test files '
      'exist under ${options.root}.',
    );
  }

  final shards = _pack(files, options.total);
  for (final shard in shards) {
    if (shard.isEmpty) {
      _fail(
        'Packing produced an empty shard for ${files.length} files across '
        '${options.total} shards.',
      );
    }
  }

  final shard = shards[options.index];
  File(options.output).writeAsStringSync('${shard.join('\n')}\n');
  stderr.writeln(
    'test_shard: shard ${options.index}/${options.total} -> '
    '${shard.length} of ${files.length} files, written to ${options.output}',
  );
}

/// Greedy longest-processing-time bin packing: place the largest remaining file
/// into the lightest bin. Deterministic for a given file list.
List<List<String>> _pack(List<File> files, int total) {
  final sizes = {for (final f in files) f.path: f.lengthSync()};

  final bySizeDesc = files.map((f) => f.path).toList()
    ..sort((a, b) {
      final bySize = sizes[b]!.compareTo(sizes[a]!);
      // Ties broken by path so equal-sized files land deterministically.
      return bySize != 0 ? bySize : a.compareTo(b);
    });

  final bins = List.generate(total, (_) => <String>[]);
  final weights = List<int>.filled(total, 0);

  for (final path in bySizeDesc) {
    var lightest = 0;
    for (var i = 1; i < total; i++) {
      if (weights[i] < weights[lightest]) {
        lightest = i;
      }
    }
    bins[lightest].add(path);
    weights[lightest] += sizes[path]!;
  }

  // Restore path order within each shard: neighbouring test files tend to share
  // imports, so the incremental compiler does less work when they run together.
  for (final bin in bins) {
    bin.sort();
  }
  return bins;
}

class _Options {
  const _Options({
    required this.index,
    required this.total,
    required this.root,
    required this.output,
  });

  final int index;
  final int total;
  final String root;
  final String output;
}

_Options _parseArgs(List<String> args) {
  int? index;
  int? total;
  String? output;
  var root = 'test';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String next() {
      if (i + 1 >= args.length) {
        _fail('Missing value for $arg');
      }
      return args[++i];
    }

    switch (arg) {
      case '--index':
        index = int.tryParse(next());
      case '--total':
        total = int.tryParse(next());
      case '--root':
        root = next();
      case '--output':
        output = next();
      default:
        _fail('Unknown argument: $arg');
    }
  }

  if (total == null || total < 1) {
    _fail('--total must be an integer >= 1');
  }
  if (index == null || index < 0 || index >= total) {
    _fail('--index must be an integer in [0, $total)');
  }
  if (output == null || output.isEmpty) {
    _fail('--output is required');
  }
  return _Options(index: index, total: total, root: root, output: output);
}

Never _fail(String message) {
  stderr.writeln('test_shard: $message');
  exit(64);
}
