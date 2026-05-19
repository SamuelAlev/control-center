import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';

import 'cassette.dart';

/// Thrown when a cassette would be written with credentials in it. The write is
/// refused; [findings] lists every offending `{path, reason}` so the leak can
/// be tracked down.
class UnsafeCassetteError implements Exception {
  /// Creates an [UnsafeCassetteError].
  const UnsafeCassetteError({
    required this.cassetteName,
    required this.findings,
  });

  /// The cassette that was refused.
  final String cassetteName;

  /// The secrets that were detected.
  final List<SecretFinding> findings;

  @override
  String toString() =>
      'UnsafeCassetteError: refusing to write cassette "$cassetteName" because '
      'it contains possible secrets: ${findings.join(', ')}';
}

/// Reads and writes cassette JSON files under a recordings directory, applying
/// a hard secret-scanning gate on write.
class CassetteStore {
  /// Creates a [CassetteStore].
  CassetteStore({String? directory, SecretScanner? scanner})
    : directory =
          directory ?? '${Directory.current.path}/test/fixtures/recordings',
      _scanner = scanner ?? const SecretScanner();

  /// Where `<name>.json` files live.
  final String directory;

  final SecretScanner _scanner;

  File _file(String name) => File('$directory/$name.json');

  /// Whether a cassette named [name] exists on disk.
  bool exists(String name) => _file(name).existsSync();

  /// Reads cassette [name], or null when it does not exist.
  Future<Cassette?> read(String name) async {
    final file = _file(name);
    if (!file.existsSync()) {
      return null;
    }
    final raw = await file.readAsString();
    return Cassette.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Scans [cassette] for secrets without writing — returns every finding.
  List<SecretFinding> scan(Cassette cassette) =>
      _scanner.scan(cassette.toJson());

  /// Writes [cassette] to `<name>.json`, pretty-printed with a trailing
  /// newline. Throws [UnsafeCassetteError] (and writes nothing) if the cassette
  /// contains anything that looks like a credential.
  Future<void> write(String name, Cassette cassette) async {
    final findings = scan(cassette);
    if (findings.isNotEmpty) {
      throw UnsafeCassetteError(cassetteName: name, findings: findings);
    }
    final file = _file(name);
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(cassette.toJson())}\n');
  }
}
