// Regenerates the embedding equivalence goldens.
//
// `test/inference/embedding/golden_minilm_vectors.json` is the reference set
// `embedding_equivalence_test.dart` checks every embedding against. Its job is
// to catch a change that silently MOVES the vectors — a runtime bump, a
// pooling edit, a tokenizer change — because the 384-d vectors already stored
// in sqlite_vector are compared against freshly computed query vectors, and
// the two must stay in the same space.
//
// Only re-run this when the MODEL itself intentionally changes. Re-running it
// after any other change overwrites the baseline with whatever the current
// code produces, which silently destroys the guarantee.
//
// Usage (needs the model installed and the native staged):
//
//   CC_NATIVE_LIB_DIR=build/natives fvm dart run \
//     packages/cc_natives/tool/gen_embedding_goldens.dart \
//     [--model-dir <dir>] [--out <file>]

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/embedding_model_paths.dart';
import 'package:cc_natives/src/inference/embedding/text_embedder.dart';

/// The fixed corpus. Deliberately spans the cases where two runtimes are most
/// likely to disagree: a sequence long enough to hit the 256-token cap, text
/// that tokenizes to `[UNK]`-heavy sequences, non-Latin scripts, and the
/// degenerate whitespace/empty inputs the callers really do pass.
const List<String> corpus = [
  'hello world',
  'The quick brown fox jumps over the lazy dog.',
  'a',
  '   ',
  '',
  'café naïve façade — em-dash, curly “quotes”, and ellipsis…',
  '日本語のテキストと、絵文字 🎉 を含む文字列',
  'Здравствуй, мир! Это тестовая строка.',
  'snake_case camelCase kebab-case SCREAMING_SNAKE 0x1F4A9 3.14159',
  'class FooBar extends Baz implements Qux { void run() => print("hi"); }',
  // Longer than the 256-token cap, so truncation behaviour is covered too.
  // ignore: no_adjacent_strings_in_list
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
      'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
      'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
      'commodo consequat. Duis aute irure dolor in reprehenderit in voluptate '
      'velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '
      'occaecat cupidatat non proident, sunt in culpa qui officia deserunt '
      'mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus '
      'error sit voluptatem accusantium doloremque laudantium, totam rem '
      'aperiam, eaque ipsa quae ab illo inventore veritatis et quasi '
      'architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam '
      'voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia '
      'consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.',
  'workspace isolation is enforced by the database split, not by WHERE clauses',
];

/// Vector width and token cap of `sentence-transformers/all-MiniLM-L6-v2`,
/// matching `EmbeddingModelInfo.allMiniLmL6V2`.
const int dimension = 384;
const int maxSequenceLength = 256;

Future<void> main(List<String> args) async {
  final modelDir = _arg(args, '--model-dir') ??
      '${Platform.environment['HOME']}/Library/Application Support/'
          'control-center/models/all-MiniLM-L6-v2';
  final outPath = _arg(args, '--out') ??
      'packages/cc_natives/test/inference/embedding/golden_minilm_vectors.json';

  final paths = EmbeddingModelPaths(
    model: '$modelDir/model.onnx',
    vocab: '$modelDir/vocab.txt',
  );
  for (final file in [paths.model, paths.vocab]) {
    if (!File(file).existsSync()) {
      stderr.writeln('Missing model file: $file');
      stderr.writeln('Install the embedding model first, or pass --model-dir.');
      exitCode = 2;
      return;
    }
  }

  final embedder = await TextEmbedder.load(
    paths: paths,
    dimension: dimension,
    maxSequenceLength: maxSequenceLength,
  );
  final vectors = <Map<String, Object?>>[];
  try {
    for (final text in corpus) {
      final vector = await embedder.embed(text);
      vectors.add({'text': text, 'vector': vector.toList()});
    }
  } finally {
    await embedder.dispose();
  }

  final out = File(outPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'model': 'sentence-transformers/all-MiniLM-L6-v2',
      'dimension': dimension,
      'maxSequenceLength': maxSequenceLength,
      'vectors': vectors,
    }),
  );
  stdout.writeln('Wrote ${vectors.length} golden vectors to $outPath');
}

String? _arg(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}
