import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// WebDriverAgent release pinned by Control Center.
const String kIosAutomationVersion = 'v16.12.8';

/// Source commit corresponding to [kIosAutomationVersion].
const String kIosAutomationCommit =
    '3e8aa7de81f254dbb0876baa9e9173c16b55b3a0';

/// SHA-256 of the pinned WebDriverAgent BSD-3-Clause notice.
const String kIosAutomationLicenseSha256 =
    'd9910c6ba5e4c29ae415ee3ce875c9e18a60d8bc4d7fe2c2d104db2a718b1bb4';

/// A byte source used to test installation without network access.
typedef IosAutomationSource = Future<Stream<List<int>>> Function(Uri uri);

/// A pinned release asset for one macOS architecture.
class IosAutomationArtifact {
  /// Creates an artifact description.
  const IosAutomationArtifact({
    required this.architecture,
    required this.url,
    required this.sha256,
  });

  /// Stable install-directory architecture name.
  final String architecture;

  /// Immutable HTTPS release URL.
  final String url;

  /// SHA-256 of the ZIP bytes.
  final String sha256;
}

/// Apple Silicon WebDriverAgent runner.
const IosAutomationArtifact kIosAutomationArm64 = IosAutomationArtifact(
  architecture: 'arm64',
  url:
      'https://github.com/appium/WebDriverAgent/releases/download/v16.12.8/'
      'WebDriverAgentRunner-Build-Sim-arm64.zip',
  sha256: '99bca36962e6f06bb140971f467e851f4cebf9e89c20af8d45bcd6f3bd00aab4',
);

/// Intel WebDriverAgent runner.
const IosAutomationArtifact kIosAutomationX64 = IosAutomationArtifact(
  architecture: 'x86_64',
  url:
      'https://github.com/appium/WebDriverAgent/releases/download/v16.12.8/'
      'WebDriverAgentRunner-Build-Sim-x86_64.zip',
  sha256: 'bf683d59a8ffc031031ddeeb3d5edf9556f3060692694904edcf4b8aa5ba05a2',
);

/// Validates that a ZIP symlink stays inside the staged archive root.
///
/// Returns the normalized archive-relative target. Exposed so the
/// supply-chain boundary can be pinned without relying on a platform ZIP
/// encoder preserving Unix creator metadata.
String validateIosArchiveSymlink(String entryPath, String target) {
  final zip = p.Context(style: p.Style.posix);
  final resolved = zip.normalize(zip.join(zip.dirname(entryPath), target));
  if (zip.isAbsolute(target) ||
      resolved == '..' ||
      resolved.startsWith('../')) {
    throw IosAutomationException(
      'Unsafe symlink in WebDriverAgent archive: $entryPath -> $target',
    );
  }
  return resolved;
}

/// Failure to install or validate the pinned iOS automation bridge.
class IosAutomationException implements Exception {
  /// Creates an installation failure.
  const IosAutomationException(this.message);

  /// Operator-facing failure detail.
  final String message;

  @override
  String toString() => 'IosAutomationException: $message';
}

/// Owns the checksum-pinned WebDriverAgent runner under the server data dir.
class IosAutomationStore {
  /// Creates the store.
  IosAutomationStore({
    required String dataDir,
    String? architecture,
    this.source,
  }) : _root = p.join(dataDir, 'rigs', 'ios', 'wda', kIosAutomationVersion),
       _architecture = architecture ?? _hostArchitecture,
       _artifactOverride = null;

  /// Creates a deterministic store with a test-owned pinned artifact.
  ///
  /// Production composition uses the default constructor; this seam lets
  /// tests exercise exact hash and archive behavior without network access.
  IosAutomationStore.forTesting({
    required String dataDir,
    required IosAutomationArtifact artifact,
    required this.source,
  }) : _root = p.join(dataDir, 'rigs', 'ios', 'wda', kIosAutomationVersion),
       _architecture = artifact.architecture,
       _artifactOverride = artifact;

  static const int _maxArchiveBytes = 64 * 1024 * 1024;
  static const Duration _connectTimeout = Duration(seconds: 20);
  static const Duration _downloadTimeout = Duration(minutes: 3);

  final String _root;
  final String _architecture;
  final IosAutomationArtifact? _artifactOverride;

  /// Optional byte source used by deterministic tests.
  final IosAutomationSource? source;

  Future<String>? _installing;

  /// The artifact selected for this host architecture.
  IosAutomationArtifact get artifact =>
      _artifactOverride ??
      switch (_architecture) {
        'arm64' || 'aarch64' => kIosAutomationArm64,
        'x64' || 'x86_64' => kIosAutomationX64,
        _ => throw IosAutomationException(
          'WebDriverAgent has no simulator runner for $_architecture.',
        ),
      };

  /// Final architecture directory.
  String get installDirectory => p.join(_root, artifact.architecture);

  /// Installed runner application path.
  String get runnerAppPath => p.join(
    installDirectory,
    'WebDriverAgentRunner-Runner.app',
  );

  /// Whether a structurally valid runner is already installed.
  bool get isInstalled => _validRunnerAt(installDirectory);

  /// Downloads, verifies and atomically installs the pinned runner.
  ///
  /// Concurrent callers join one installation. A checksum mismatch or invalid
  /// ZIP never leaves a directory that capability probing can mistake for an
  /// installed bridge.
  Future<String> install() {
    if (isInstalled) {
      return Future.value(runnerAppPath);
    }
    return _installing ??= _install().whenComplete(() => _installing = null);
  }

  Future<String> _install() async {
    final selected = artifact;
    final parent = Directory(_root);
    await parent.create(recursive: true);
    final part = File(p.join(_root, '.${selected.architecture}.zip.part'));
    final stage = Directory(
      p.join(
        _root,
        '.${selected.architecture}.stage-'
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    if (part.existsSync()) {
      await part.delete();
    }
    if (stage.existsSync()) {
      await stage.delete(recursive: true);
    }

    try {
      final input = source == null
          ? _httpsSource(Uri.parse(selected.url))
          : source!(Uri.parse(selected.url));
      final stream = await input.timeout(_connectTimeout);
      final sink = part.openWrite();
      Digest? digest;
      final hasher = sha256.startChunkedConversion(
        ChunkedConversionSink<Digest>.withCallback(
          (values) => digest = values.single,
        ),
      );
      var received = 0;
      try {
        await for (final chunk in stream.timeout(_downloadTimeout)) {
          received += chunk.length;
          if (received > _maxArchiveBytes) {
            throw const IosAutomationException(
              'The WebDriverAgent archive exceeded the 64 MiB safety limit.',
            );
          }
          sink.add(chunk);
          hasher.add(chunk);
        }
        hasher.close();
        await sink.flush();
      } finally {
        await sink.close();
      }
      final actual = digest?.toString();
      if (actual != selected.sha256) {
        throw IosAutomationException(
          'WebDriverAgent checksum mismatch: expected ${selected.sha256}, '
          'got ${actual ?? 'no digest'}.',
        );
      }

      final executablePaths = await Isolate.run(
        () => _extractAndValidateArchive(
          archivePath: part.path,
          stagePath: stage.path,
        ),
      );
      for (final executable in executablePaths) {
        await _chmod(executable.$1, executable.$2);
      }

      final destination = Directory(installDirectory);
      if (destination.existsSync()) {
        if (_validRunnerAt(destination.path)) {
          await stage.delete(recursive: true);
          return runnerAppPath;
        }
        throw IosAutomationException(
          'Refusing to replace invalid existing automation directory '
          '${destination.path}; remove it after inspecting it.',
        );
      }
      await stage.rename(destination.path);
      return runnerAppPath;
    } finally {
      if (part.existsSync()) {
        await part.delete();
      }
      if (stage.existsSync()) {
        await stage.delete(recursive: true);
      }
    }
  }

  Future<Stream<List<int>>> _httpsSource(Uri uri) async {
    if (uri.scheme != 'https') {
      throw IosAutomationException('Refusing non-HTTPS automation URL: $uri');
    }
    final client = HttpClient()
      ..connectionTimeout = _connectTimeout
      ..userAgent = 'control-center-ios-automation/$kIosAutomationVersion';
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      for (final redirect in response.redirects) {
        if (redirect.location.scheme != 'https') {
          throw IosAutomationException(
            'Refusing non-HTTPS automation redirect: ${redirect.location}',
          );
        }
      }
      if (response.statusCode != HttpStatus.ok) {
        throw IosAutomationException(
          'WebDriverAgent download failed with HTTP ${response.statusCode}.',
        );
      }
      if (response.contentLength > _maxArchiveBytes) {
        throw const IosAutomationException(
          'The WebDriverAgent archive exceeded the 64 MiB safety limit.',
        );
      }
      return _closingStream(response, client);
    } catch (_) {
      client.close(force: true);
      rethrow;
    }
  }

  Stream<List<int>> _closingStream(
    HttpClientResponse response,
    HttpClient client,
  ) async* {
    try {
      yield* response;
    } finally {
      client.close(force: true);
    }
  }

  static List<(String, String)> _extractAndValidateArchive({
    required String archivePath,
    required String stagePath,
  }) {
    final stage = Directory(stagePath)..createSync(recursive: true);
    final bytes = File(archivePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final zip = p.Context(style: p.Style.posix);
    final links = <ArchiveFile>[];
    final executablePaths = <(String, String)>[];

    String relativePath(ArchiveFile entry) {
      final raw = entry.name.replaceAll('\\', '/');
      final normalized = zip.normalize(raw);
      if (zip.isAbsolute(raw) ||
          normalized == '.' ||
          normalized == '..' ||
          normalized.startsWith('../')) {
        throw IosAutomationException(
          'Unsafe path in WebDriverAgent archive: ${entry.name}',
        );
      }
      return normalized;
    }

    String outputPath(String relative) =>
        p.joinAll([stage.path, ...zip.split(relative)]);

    // Regular entries first. Links cannot influence where any bytes land.
    for (final entry in archive) {
      final relative = relativePath(entry);
      if (entry.isSymbolicLink) {
        links.add(entry);
        continue;
      }
      final output = outputPath(relative);
      if (entry.isDirectory) {
        Directory(output).createSync(recursive: true);
        continue;
      }
      Directory(p.dirname(output)).createSync(recursive: true);
      File(output).writeAsBytesSync(entry.content, flush: true);
      final mode = entry.unixPermissions;
      if (mode != 0) {
        executablePaths.add((mode.toRadixString(8).padLeft(3, '0'), output));
      }
    }

    for (final entry in links) {
      final relative = relativePath(entry);
      final target = entry.symbolicLink!;
      validateIosArchiveSymlink(relative, target);
      final output = outputPath(relative);
      Directory(p.dirname(output)).createSync(recursive: true);
      Link(output).createSync(target);
    }

    final info = File(
      p.join(
        stage.path,
        'WebDriverAgentRunner-Runner.app',
        'Info.plist',
      ),
    );
    if (!info.existsSync() || info.lengthSync() == 0) {
      throw const IosAutomationException(
        'The WebDriverAgent archive has no runner Info.plist.',
      );
    }
    File(p.join(stage.path, 'LICENSE.webdriveragent.txt')).writeAsStringSync(
      _licenseNotice,
      encoding: utf8,
      flush: true,
    );
    return executablePaths;
  }

  static Future<void> _chmod(String mode, String path) async {
    if (Platform.isWindows) {
      return;
    }
    final result = await Process.run('/bin/chmod', [mode, path]);
    if (result.exitCode != 0) {
      throw IosAutomationException(
        'chmod $mode failed for $path: ${result.stderr}',
      );
    }
  }

  static bool _validRunnerAt(String directory) {
    final info = File(
      p.join(
        directory,
        'WebDriverAgentRunner-Runner.app',
        'Info.plist',
      ),
    );
    return info.existsSync() && info.lengthSync() > 0;
  }

  static String get _hostArchitecture {
    final version = Platform.version;
    return version.contains('arm64') || version.contains('aarch64')
        ? 'arm64'
        : 'x86_64';
  }
}

const String _licenseNotice = '''BSD License

For WebDriverAgent software

Copyright (c) 2015-present, Facebook, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

 * Neither the name Facebook nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';
