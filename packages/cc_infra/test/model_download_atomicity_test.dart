import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Serves canned bodies and runs [onMidTransfer] between two halves of every
/// response, so a test can look at the disk exactly as a process killed
/// mid-download would have left it.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.bodies, {this.onMidTransfer});

  /// URL substring → response bytes.
  final Map<String, List<int>> bodies;
  final Future<void> Function()? onMidTransfer;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    final body = bodies.entries
        .firstWhere(
          (e) => url.contains(e.key),
          orElse: () => throw StateError('no stub body for $url'),
        )
        .value;
    final half = body.length ~/ 2;

    Stream<Uint8List> chunks() async* {
      yield Uint8List.fromList(body.sublist(0, half));
      await onMidTransfer?.call();
      yield Uint8List.fromList(body.sublist(half));
    }

    return ResponseBody(
      chunks(),
      200,
      headers: {
        Headers.contentLengthHeader: ['${body.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

/// Builds a `.tar.bz2` holding [files] (path → contents), matching the shape
/// the sherpa-onnx releases ship.
List<int> _tarBz2(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.add(ArchiveFile.string(entry.key, entry.value));
  }
  return BZip2Encoder().encode(TarEncoder().encode(archive));
}

void main() {
  late Directory tmp;
  late CcPaths paths;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_model_atomicity');
    paths = CcPaths(tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  // The managers' `resolve()` is an existence check with no checksum or size
  // test, and a SIGKILL runs no `catch` block. So the ONLY thing keeping a
  // half-written file from being reported as an installed model forever is
  // that nothing reaches its final path until it is complete.

  group('EmbeddingModelManager', () {
    test(
      'no file reaches its final path until the transfer completed',
      () async {
        final dir = Directory(p.join(tmp.path, 'models', 'all-MiniLM-L6-v2'));
        final model = File(p.join(dir.path, 'model.onnx'));
        final vocab = File(p.join(dir.path, 'vocab.txt'));
        late EmbeddingModelManager manager;
        final probes = <bool>[];

        manager = EmbeddingModelManager(
          paths: paths,
          dio: _dioWith(
            _StubAdapter(
              {
                'model.onnx': List.filled(64, 1),
                'vocab.txt': List.filled(32, 2),
              },
              onMidTransfer: () async {
                probes.add(model.existsSync() || vocab.existsSync());
                // The decisive property: a boot interrupted here re-downloads.
                expect(await manager.resolve(), isNull);
              },
            ),
          ),
        );

        await manager.install();

        expect(probes, [false, false], reason: 'probed mid-model, mid-vocab');
        expect(await manager.resolve(), isNotNull);
        expect(model.readAsBytesSync(), hasLength(64));
        expect(vocab.readAsBytesSync(), hasLength(32));
        expect(
          dir.listSync().where((e) => e.path.endsWith('.part')),
          isEmpty,
          reason: 'the .part siblings are renamed away, not left behind',
        );
      },
    );

    test(
      'a partial .part from an earlier kill is overwritten, not appended',
      () async {
        final dir = Directory(p.join(tmp.path, 'models', 'all-MiniLM-L6-v2'))
          ..createSync(recursive: true);
        File(
          p.join(dir.path, 'model.onnx.part'),
        ).writeAsBytesSync(List.filled(999, 9));

        final manager = EmbeddingModelManager(
          paths: paths,
          dio: _dioWith(
            _StubAdapter({
              'model.onnx': List.filled(64, 1),
              'vocab.txt': List.filled(32, 2),
            }),
          ),
        );
        await manager.install();

        expect(
          File(p.join(dir.path, 'model.onnx')).readAsBytesSync(),
          hasLength(64),
        );
      },
    );
  });

  group('DiarizationModelManager', () {
    test('the embedding model appears only once fully downloaded', () async {
      final dir = Directory(
        p.join(tmp.path, 'models', 'sherpa-onnx-diarization'),
      );
      final embedding = File(
        p.join(dir.path, 'wespeaker_en_voxceleb_resnet34_LM.onnx'),
      );
      late DiarizationModelManager manager;
      final probes = <bool>[];

      manager = DiarizationModelManager(
        paths: paths,
        dio: _dioWith(
          _StubAdapter(
            {
              '.tar.bz2': _tarBz2({
                'sherpa-onnx-pyannote-segmentation-3-0/model.onnx': 'seg',
              }),
              'wespeaker': List.filled(64, 3),
            },
            onMidTransfer: () async {
              probes.add(embedding.existsSync());
              expect(await manager.resolve(), isNull);
            },
          ),
        ),
      );

      await manager.install();

      expect(probes, [false, false], reason: 'probed mid-archive, mid-model');
      expect(await manager.resolve(), isNotNull);
      expect(embedding.readAsBytesSync(), hasLength(64));
    });
  });

  group('VoiceModelManager', () {
    test(
      'the unpacked directory is renamed in, never extracted in place',
      () async {
        final unpacked = Directory(
          p.join(tmp.path, 'models', 'sherpa-onnx-whisper-base.en'),
        );
        final model = VoiceModelInfo.byId('sherpa-onnx-whisper-base.en');
        final manager = VoiceModelManager(
          paths: paths,
          model: model,
          dio: _dioWith(
            _StubAdapter({
              '.tar.bz2': _tarBz2({
                '${model.unpackedDirName}/${model.encoderFile}': 'enc',
                '${model.unpackedDirName}/${model.decoderFile}': 'dec',
                '${model.unpackedDirName}/${model.tokensFile}': 'tok',
              }),
            }),
          ),
        );

        // Whatever an interrupted earlier run left behind must not survive as a
        // half-model: `resolve()` rejected it, so the install replaces it.
        unpacked.createSync(recursive: true);
        File(
          p.join(unpacked.path, model.encoderFile),
        ).writeAsStringSync('stale');

        await manager.install();

        expect(await manager.resolve(), isNotNull);
        expect(
          File(p.join(unpacked.path, model.encoderFile)).readAsStringSync(),
          'enc',
        );
        expect(
          Directory(
            p.join(tmp.path, 'models'),
          ).listSync().map((e) => p.basename(e.path)),
          isNot(contains(startsWith('.'))),
          reason: 'the staging dir is cleaned up',
        );
      },
    );
  });
}
