import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:cc_infra/src/speech/tar_bz2_extract.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/util/http_file_download.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:path/path.dart' as p;
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Serves canned bodies and runs [onMidTransfer] between two halves of every
/// response, so a test can look at the disk exactly as a process killed
/// mid-download would have left it.
TestHttpClient _streamingClient(
  Map<String, List<int>> bodies, {
  Future<void> Function()? onMidTransfer,
}) => TestHttpClient(
  handler: (request) {
    final body = bodies.entries
        .firstWhere(
          (e) => request.url.contains(e.key),
          orElse: () => throw StateError('no stub body for ${request.url}'),
        )
        .value;
    final half = body.length ~/ 2;

    Stream<Uint8List> chunks() async* {
      yield Uint8List.fromList(body.sublist(0, half));
      await onMidTransfer?.call();
      yield Uint8List.fromList(body.sublist(half));
    }

    return HttpStreamResponse(
      remoteIp: null,
      request: request,
      version: HttpVersion.http1_1,
      statusCode: 200,
      headers: [('content-length', '${body.length}')],
      body: chunks(),
    );
  },
);

/// Builds a `.tar.bz2` holding [files] (path → contents), matching the shape
/// the sherpa-onnx releases ship.
List<int> _tarBz2(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.add(ArchiveFile.string(entry.key, entry.value));
  }
  return BZip2Encoder().encode(TarEncoder().encode(archive));
}

/// Serves `body()` for every request, re-reading it per attempt, so a test can
/// hand the first install one body and a retry another.
TestHttpClient _bodyClient(List<int> Function() body) => TestHttpClient(
  handler: (request) {
    final bytes = body();
    return HttpStreamResponse(
      remoteIp: null,
      request: request,
      version: HttpVersion.http1_1,
      statusCode: 200,
      headers: [('content-length', '${bytes.length}')],
      body: Stream.value(Uint8List.fromList(bytes)),
    );
  },
);

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

  group('streamed archive completion', () {
    test('finishes progress after reading the compression trailer', () {
      final archive = File(p.join(tmp.path, 'model.tar.bz2'))
        ..writeAsBytesSync(_tarBz2({'model/data.bin': 'model contents'}));
      final progress = <double>[];
      extractTarBz2Streamed(
        archive.path,
        p.join(tmp.path, 'extracted'),
        onProgress: progress.add,
      );
      expect(progress.last, 1.0);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
      expect(
        File(p.join(tmp.path, 'extracted/model/data.bin')).readAsStringSync(),
        'model contents',
      );
    });

    test('rejects a truncated trailer even after writing the TAR entries', () {
      final bytes = _tarBz2({'model/data.bin': 'model contents'});
      final archive = File(p.join(tmp.path, 'truncated.tar.bz2'))
        ..writeAsBytesSync(bytes.sublist(0, bytes.length - 1));
      final progress = <double>[];
      expect(
        () => extractTarBz2Streamed(
          archive.path,
          p.join(tmp.path, 'extracted'),
          onProgress: progress.add,
        ),
        throwsA(isA<ArchiveException>()),
      );
      expect(progress, isNot(contains(1.0)));
    });
  });

  // The managers' `resolve()` is an existence check with no checksum or size
  // test, and a SIGKILL runs no `catch` block. So the ONLY thing keeping a
  // half-written file from being reported as an installed model forever is
  // that nothing reaches its final path until it is complete.

  // Receive-idle deadlines must fail stalled downloads and stop the transfer.
  group('downloadToFile', () {
    test('a stalled body fails on the receive-idle deadline', () async {
      final stalled = StreamController<Uint8List>();
      addTearDown(stalled.close);
      final destination = File(p.join(tmp.path, 'stalled.part'));

      final client = TestHttpClient(
        handler: (request) => HttpStreamResponse(
          remoteIp: null,
          request: request,
          version: HttpVersion.http1_1,
          statusCode: 200,
          headers: const [],
          // Opens but never emits and never closes: exactly a transfer that
          // stopped making progress.
          body: stalled.stream,
        ),
      );

      await expectLater(
        downloadToFile(
          client,
          'https://example.test/stall',
          destination.path,
          idleTimeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<RhttpTimeoutException>()),
      );
    });
  });

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
          httpClient: _streamingClient(
            {'model.onnx': List.filled(64, 1), 'vocab.txt': List.filled(32, 2)},
            onMidTransfer: () async {
              probes.add(model.existsSync() || vocab.existsSync());
              // The decisive property: a boot interrupted here re-downloads.
              expect(await manager.resolve(), isNull);
            },
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
          httpClient: _streamingClient({
            'model.onnx': List.filled(64, 1),
            'vocab.txt': List.filled(32, 2),
          }),
        );
        await manager.install();

        expect(
          File(p.join(dir.path, 'model.onnx')).readAsBytesSync(),
          hasLength(64),
        );
      },
    );
    test(
      'a transfer that fails mid-way leaves no partial file behind',
      () async {
        final dir = Directory(p.join(tmp.path, 'models', 'all-MiniLM-L6-v2'));
        final manager = EmbeddingModelManager(
          paths: paths,
          httpClient: TestHttpClient(
            handler: (request) => HttpStreamResponse(
              remoteIp: null,
              request: request,
              version: HttpVersion.http1_1,
              statusCode: 200,
              headers: const [],
              body: Stream<Uint8List>.error(StateError('connection reset')),
            ),
          ),
        );

        await expectLater(manager.install(), throwsA(isA<StateError>()));
        expect(await manager.resolve(), isNull);
        expect(
          dir.existsSync()
              ? dir.listSync().where((e) => e.path.endsWith('.part'))
              : const <FileSystemEntity>[],
          isEmpty,
          reason: 'the failed transfer deletes its .part sibling',
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
        httpClient: _streamingClient(
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
      );

      await manager.install();

      expect(probes, [false, false], reason: 'probed mid-archive, mid-model');
      expect(await manager.resolve(), isNotNull);
      expect(embedding.readAsBytesSync(), hasLength(64));
    });

    test('extracts the segmentation model with its exact bytes', () async {
      final manager = DiarizationModelManager(
        paths: paths,
        httpClient: _streamingClient({
          '.tar.bz2': _tarBz2({
            'sherpa-onnx-pyannote-segmentation-3-0/model.onnx':
                'segmentation-bytes',
          }),
          'wespeaker': List.filled(64, 3),
        }),
      );

      final resolved = await manager.install();

      expect(
        File(resolved.segmentation).readAsStringSync(),
        'segmentation-bytes',
      );
      expect(File(resolved.embedding).readAsBytesSync(), hasLength(64));
      expect(
        Directory(p.dirname(resolved.embedding))
            .listSync()
            .map((e) => p.basename(e.path))
            .where((name) => name.endsWith('.part')),
        isEmpty,
        reason: 'the downloaded archive is deleted once it is extracted',
      );
    });

    test('a truncated segmentation archive installs nothing', () async {
      final good = _tarBz2({
        'sherpa-onnx-pyannote-segmentation-3-0/model.onnx': 'seg',
      });
      final manager = DiarizationModelManager(
        paths: paths,
        httpClient: _bodyClient(() => good.sublist(0, good.length ~/ 2)),
      );

      // The streaming decoder reports the cut-off bzip2 stream, and because the
      // embedding download never runs, `resolve` stays null: the manifest a
      // caller might have written is never satisfied.
      await expectLater(manager.install(), throwsA(isA<ArchiveException>()));
      expect(await manager.resolve(), isNull);
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
          httpClient: _streamingClient({
            '.tar.bz2': _tarBz2({
              '${model.unpackedDirName}/${model.encoderFile}': 'enc',
              '${model.unpackedDirName}/${model.decoderFile}': 'dec',
              '${model.unpackedDirName}/${model.tokensFile}': 'tok',
            }),
          }),
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

    test(
      'writes every entry, nested paths included, with exact contents',
      () async {
        final model = VoiceModelInfo.byId('sherpa-onnx-whisper-base.en');
        final dir = model.unpackedDirName;
        final manager = VoiceModelManager(
          paths: paths,
          model: model,
          httpClient: _streamingClient({
            '.tar.bz2': _tarBz2({
              '$dir/${model.encoderFile}': 'encoder-bytes',
              '$dir/${model.decoderFile}': 'decoder-bytes',
              '$dir/${model.tokensFile}': 'tokens-bytes',
              '$dir/extra/config/vocab.json': '{"vocab":1}',
            }),
          }),
        );

        final resolved = await manager.install();

        expect(File(resolved.encoder).readAsStringSync(), 'encoder-bytes');
        expect(File(resolved.decoder).readAsStringSync(), 'decoder-bytes');
        expect(File(resolved.tokens).readAsStringSync(), 'tokens-bytes');
        final nested = File(
          p.join(p.dirname(resolved.encoder), 'extra', 'config', 'vocab.json'),
        );
        expect(nested.existsSync(), isTrue, reason: 'nested path created');
        expect(nested.readAsStringSync(), '{"vocab":1}');
        final leftovers = Directory(
          p.join(tmp.path, 'models'),
        ).listSync().map((e) => p.basename(e.path)).toList();
        expect(leftovers.where((name) => name.endsWith('.part')), isEmpty);
        expect(leftovers.where((name) => name.startsWith('.')), isEmpty);
      },
    );

    test(
      'a truncated archive installs nothing, and a retry still lands',
      () async {
        final model = VoiceModelInfo.byId('sherpa-onnx-whisper-base.en');
        final dir = model.unpackedDirName;
        final good = _tarBz2({
          '$dir/${model.encoderFile}': 'enc',
          '$dir/${model.decoderFile}': 'dec',
          '$dir/${model.tokensFile}': 'tok',
        });
        var attempt = 0;
        final manager = VoiceModelManager(
          paths: paths,
          model: model,
          httpClient: _bodyClient(
            () => attempt == 0 ? good.sublist(0, good.length ~/ 2) : good,
          ),
        );

        await expectLater(
          manager.install(),
          throwsA(isA<VoiceModelInstallException>()),
        );
        expect(await manager.resolve(), isNull, reason: 'nothing was adopted');

        // Whatever the failed attempt left in the staging directory is replaced,
        // not appended to, on the next try.
        attempt = 1;
        final resolved = await manager.install();
        expect(File(resolved.encoder).readAsStringSync(), 'enc');
        expect(File(resolved.decoder).readAsStringSync(), 'dec');
        expect(File(resolved.tokens).readAsStringSync(), 'tok');
      },
    );
  });
}
