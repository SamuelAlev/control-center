@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The grammar INSTALL path: download → SHA-256 verify → publish.
///
/// [GrammarManager] fetches executable native libraries over the network, so the
/// properties pinned here are the ones whose regression is not a test failure
/// but a shipped defect: an unverified dylib that a later `resolve()` dlopens
/// (the checksums are REQUIRED), or a truncated/cancelled download left at the
/// name the search dirs look for (which would be resolved as an installed
/// grammar on the next index run).
///
/// No native library and no `cc_infra`: the HTTP client is the seam —
/// GrammarManager takes an injected `RhttpClient` — so this runs under a plain
/// `dart test` with a scoped fake, which is also why the download must go
/// through that client rather than a transport of its own.
void main() {
  late Directory grammars;

  setUp(() {
    grammars = Directory.systemTemp.createTempSync('cc-grammars');
  });
  tearDown(() {
    if (grammars.existsSync()) {
      grammars.deleteSync(recursive: true);
    }
  });

  final runtimeBytes = List<int>.generate(64, (i) => i);
  final grammarBytes = List<int>.generate(32, (i) => 64 + i);

  String sha256Of(List<int> bytes) =>
      sha256.convert(bytes).toString().toUpperCase();

  /// The two URLs every case uses; the fake only serves these.
  late GrammarSource source;
  setUp(() {
    source = GrammarSource(
      runtimeUrl: 'https://example.invalid/tree-sitter',
      grammarUrl: 'https://example.invalid/tree-sitter-dart',
      runtimeSha256: sha256Of(runtimeBytes),
      grammarSha256: sha256Of(grammarBytes),
    );
  });

  GrammarManager managerOver(RhttpClient client) =>
      GrammarManager(httpClient: client, grammarsDir: () async => grammars);

  late String runtimePath;
  late String grammarPath;
  setUp(() {
    runtimePath = p.join(grammars.path, platformLibraryFileName('tree-sitter'));
    grammarPath = p.join(
      grammars.path,
      platformLibraryFileName('tree-sitter-dart'),
    );
  });

  test('downloads, verifies and publishes both natives', () async {
    final client = _FakeHttpClient({
      source.runtimeUrl: runtimeBytes,
      source.grammarUrl: grammarBytes,
    });
    final phases = <(double, String)>[];

    final installed = await managerOver(client).install(
      'dart',
      source: source,
      onProgress: (p, phase) => phases.add((p, phase)),
    );

    expect(installed?.runtimePath, runtimePath);
    expect(installed?.grammarPath, grammarPath);
    expect(File(runtimePath).readAsBytesSync(), runtimeBytes);
    expect(File(grammarPath).readAsBytesSync(), grammarBytes);
    expect(client.requested, [
      source.runtimeUrl,
      source.grammarUrl,
    ], reason: 'the runtime is fetched first, then the grammar');
    expect(phases.first, (0.0, 'downloading'));
    expect(phases.last, (1.0, 'ready'));
    // The runtime is the first half of the bar and the grammar the second.
    expect(phases.where((e) => e.$2 == 'downloading').map((e) => e.$1), [
      0.0,
      0.5,
      1.0,
    ], reason: 'each download reports its own half of the progress');
    expect(
      grammars.listSync().map((e) => p.basename(e.path)).toList()..sort(),
      [p.basename(runtimePath), p.basename(grammarPath)]..sort(),
      reason: 'the staging file must not survive a successful install',
    );
  });

  test('is idempotent: an installed grammar is not downloaded again', () async {
    File(runtimePath).writeAsBytesSync(runtimeBytes);
    File(grammarPath).writeAsBytesSync(grammarBytes);
    final client = _FakeHttpClient(const {});
    final phases = <(double, String)>[];

    final installed = await managerOver(client).install(
      'dart',
      source: source,
      onProgress: (p, phase) => phases.add((p, phase)),
    );

    expect(installed?.grammarPath, grammarPath);
    expect(client.requested, isEmpty);
    expect(phases, [(1.0, 'ready')]);
  });

  test('a checksum mismatch throws and leaves nothing behind', () async {
    final client = _FakeHttpClient({
      source.runtimeUrl: runtimeBytes,
      source.grammarUrl: grammarBytes,
    });
    final tampered = GrammarSource(
      runtimeUrl: source.runtimeUrl,
      grammarUrl: source.grammarUrl,
      // The runtime matches; the grammar does not — the case a corrupted
      // download or a swapped artifact produces.
      runtimeSha256: sha256Of(runtimeBytes),
      grammarSha256: sha256Of(const [1, 2, 3]),
    );

    await expectLater(
      managerOver(client).install('dart', source: tampered),
      throwsA(
        isA<GrammarInstallException>().having(
          (e) => e.message,
          'message',
          contains('checksum mismatch'),
        ),
      ),
    );

    // Neither the unverified bytes nor the already-verified runtime may stay:
    // a later resolve() would dlopen them as an installed grammar.
    expect(
      grammars.listSync(),
      isEmpty,
      reason: 'unverified bytes must never be left where resolve() looks',
    );
  });

  test('a cancelled download throws and leaves nothing behind', () async {
    final client = _FakeHttpClient({
      source.grammarUrl: grammarBytes,
    }, fail: (url) => RhttpCancelException(HttpRequest(url: url)));

    await expectLater(
      managerOver(client).install('dart', source: source),
      throwsA(
        isA<GrammarInstallException>().having(
          (e) => e.message,
          'message',
          contains('grammar download failed'),
        ),
      ),
    );
    expect(grammars.listSync(), isEmpty);
  });
}

/// A scoped [RhttpClient] double: serves [bodies] by URL, optionally throwing
/// [fail] instead. Only `requestBytes` is exercised — the grammar downloader has
/// no other transport use — so every other member goes through `noSuchMethod`.
class _FakeHttpClient implements RhttpClient {
  _FakeHttpClient(this.bodies, {this.fail});

  final Map<String, List<int>> bodies;
  final Object Function(String url)? fail;

  /// The URLs requested, in order.
  final List<String> requested = [];

  @override
  Future<HttpBytesResponse> requestBytes({
    required HttpMethod method,
    required String url,
    Map<String, String>? query,
    List<(String, String)>? queryRaw,
    HttpHeaders? headers,
    HttpBody? body,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    requested.add(url);
    final failure = fail;
    if (failure != null) {
      throw failure(url);
    }
    final bytes = bodies[url];
    if (bytes == null) {
      throw StateError('unexpected download of $url');
    }
    // The real client reports progress from the byte stream, with the total
    // taken from Content-Length.
    onReceiveProgress?.call(bytes.length, bytes.length);
    return HttpBytesResponse(
      remoteIp: null,
      request: HttpRequest(method: method, url: url),
      version: HttpVersion.http1_1,
      statusCode: 200,
      headers: const [],
      body: Uint8List.fromList(bytes),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
