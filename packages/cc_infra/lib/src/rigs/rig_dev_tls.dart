// TLS for rig dev domains: a server-local CA and one shared leaf certificate,
// so `https://myapp.test` inside the Browser (VM) carries a padlock instead
// of an interstitial.
//
// The shape, and why it is this shape:
//
//  * ONE leaf keypair for every dev domain, with wildcard SANs
//    (`*.test`, `*.localhost`). Dart's `SecureServerSocket` binds one
//    `SecurityContext` per listener — there is no per-SNI certificate
//    selection — so per-domain leaves would need a rebind on every domain
//    change. A single wildcard leaf never needs rotating when a domain is
//    added.
//
//  * Trust reaches the enclosed browser as an SPKI FINGERPRINT, not a trust-
//    store install. The headless browser image has no certutil/NSS tooling
//    and no egress to fetch any, so installing a root there is not a real
//    option. Chromium's `--ignore-certificate-errors-spki-list` treats any
//    certificate whose public key matches the listed SHA-256 as valid — and
//    because the fingerprint pins OUR key specifically, it is not the blunt
//    `--ignore-certificate-errors` hammer: TLS to anything else still
//    validates normally.
//
//  * The CA and leaf keys are minted on the HOST, stored 0600 under the data
//    dir, and never enter any guest. The only thing that crosses the boundary
//    is the fingerprint of a PUBLIC key.
//
// Everything is minted by shelling out to the host's `openssl` — the same
// discipline as `ssh-keygen`/`qemu-img` (`runHostTool`), and the invocations
// are config-file based so they work on LibreSSL (macOS) and OpenSSL (Linux)
// alike. A host with no openssl simply has no HTTPS lane: the dev domains
// keep working over plain HTTP and the panel says nothing untrue.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart'
    show RigLaunchException, RigToolException;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Mints and holds the dev-domain TLS material for this server.
class RigDevTlsMaterial {
  /// Creates the material store rooted at `<dataDir>/rigs/tls`.
  RigDevTlsMaterial({required String dataDir})
    : _dir = p.join(dataDir, 'rigs', 'tls');

  final String _dir;

  String get _caKeyPath => p.join(_dir, 'ca.key');
  String get _caCertPath => p.join(_dir, 'ca.pem');
  String get _leafKeyPath => p.join(_dir, 'leaf.key');
  String get _leafCertPath => p.join(_dir, 'leaf.pem');

  bool _ready = false;
  String? _spkiFingerprint;

  /// Whether the material exists and loaded. False until [ensure] succeeds.
  bool get isReady => _ready;

  /// The base64 SHA-256 of the leaf public key's SubjectPublicKeyInfo — the
  /// value the browser workload pins. Null until [ensure] succeeds. PUBLIC
  /// information by construction; it is the only TLS artifact that ever
  /// reaches a guest.
  String? get spkiFingerprint => _spkiFingerprint;

  /// Mints the CA + leaf on first run, loads them afterwards. Idempotent.
  ///
  /// Never throws out of here: a host without openssl (or with a read-only
  /// data dir) gets `isReady == false`, the HTTPS lane stays un-armed, and
  /// the plain-HTTP domain routing is untouched.
  Future<void> ensure() async {
    if (_ready) {
      return;
    }
    try {
      if (!_allPresent()) {
        await _mint();
      }
      _spkiFingerprint = await _computeSpkiFingerprint();
      _ready = true;
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/tls: dev-domain HTTPS unavailable ($e). Dev domains still work '
        'over plain HTTP.',
      );
    }
  }

  // Existence alone is not enough: a failed signing run leaves a zero-byte
  // leaf.pem behind (openssl opens the output before it can fail), and
  // treating that as present would serve broken material on every boot.
  bool _allPresent() =>
      [_caKeyPath, _caCertPath, _leafKeyPath, _leafCertPath].every((path) {
        final file = File(path);
        return file.existsSync() && file.lengthSync() > 0;
      });

  Future<void> _mint() async {
    final openssl = await _which('openssl');
    if (openssl == null) {
      throw const RigLaunchException(
        'openssl is not installed, so no dev-domain certificates can be '
        'minted.',
      );
    }
    final dir = Directory(_dir);
    await dir.create(recursive: true);
    // The directory holds two private keys; 0700 means a permission slip on
    // any future file in here is not immediately world-readable.
    await _chmod('700', _dir);

    // Config files rather than -addext: LibreSSL (macOS' openssl) predates
    // -addext, and a config section behaves identically on both flavors.
    final caCnf = File(p.join(_dir, 'ca.cnf'));
    await caCnf.writeAsString('''
[req]
distinguished_name = dn
x509_extensions = v3_ca
prompt = no
[dn]
CN = Control Center dev CA
[v3_ca]
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
''');
    final leafCnf = File(p.join(_dir, 'leaf.cnf'));
    await leafCnf.writeAsString('''
[req]
distinguished_name = dn
prompt = no
[dn]
CN = Control Center dev domains
[v3_leaf]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:*.test, DNS:*.localhost, DNS:localhost, IP:127.0.0.1
''');

    Future<void> run(List<String> args, {String? hint}) =>
        _runTool('openssl', args, executable: openssl, hint: hint);

    // CA: EC P-256, self-signed, ten years. It signs exactly one leaf and its
    // key never leaves this directory.
    await run([
      'ecparam',
      '-name',
      'prime256v1',
      '-genkey',
      '-noout',
      '-out',
      _caKeyPath,
    ]);
    await _chmod('600', _caKeyPath);
    await run([
      'req',
      '-x509',
      '-new',
      '-sha256',
      '-key',
      _caKeyPath,
      '-out',
      _caCertPath,
      '-days',
      '3650',
      '-config',
      caCnf.path,
    ]);

    // Leaf: one key, wildcard SANs for both dev TLDs. 825 days — long enough
    // to be forgettable, short enough that a leaked dev key ages out.
    final csrPath = p.join(_dir, 'leaf.csr');
    await run([
      'ecparam',
      '-name',
      'prime256v1',
      '-genkey',
      '-noout',
      '-out',
      _leafKeyPath,
    ]);
    await _chmod('600', _leafKeyPath);
    await run([
      'req',
      '-new',
      '-sha256',
      '-key',
      _leafKeyPath,
      '-out',
      csrPath,
      '-config',
      leafCnf.path,
    ]);
    // -CAserial must be explicit: without it, LibreSSL derives the serial
    // path by truncating the CA path at its FIRST dot, so a data dir under a
    // home like /Users/samuel.alev yields /Users/samuel.srl — outside the
    // data dir and unwritable.
    final serialPath = p.join(_dir, 'ca.srl');
    await run(
      [
        'x509',
        '-req',
        '-sha256',
        '-in',
        csrPath,
        '-CA',
        _caCertPath,
        '-CAkey',
        _caKeyPath,
        '-CAserial',
        serialPath,
        '-CAcreateserial',
        '-out',
        _leafCertPath,
        '-days',
        '825',
        '-extfile',
        leafCnf.path,
        '-extensions',
        'v3_leaf',
      ],
      hint:
          'Without a signed leaf there is nothing for the HTTPS lane to '
          'serve.',
    );
    for (final scratch in [csrPath, caCnf.path, leafCnf.path, serialPath]) {
      try {
        await File(scratch).delete();
      } on Object {
        // Best effort.
      }
    }
    CcInfraLog.info('rig/tls: minted the dev-domain CA and leaf under $_dir');
  }

  /// SHA-256 over the leaf public key's DER SubjectPublicKeyInfo, base64 —
  /// exactly the form the browser's SPKI pin list expects.
  Future<String> _computeSpkiFingerprint() async {
    final openssl = await _which('openssl');
    if (openssl == null) {
      throw const RigLaunchException('openssl is not installed.');
    }
    final result = await Process.run(openssl, [
      'pkey',
      '-in',
      _leafKeyPath,
      '-pubout',
      '-outform',
      'der',
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw RigLaunchException(
        'Could not derive the leaf public key: ${result.stderr}',
      );
    }
    final der = result.stdout as List<int>;
    return base64Encode(sha256.convert(der).bytes);
  }

  /// A [SecurityContext] serving the leaf chained to the CA, or null when the
  /// material is not ready.
  SecurityContext? securityContext() {
    if (!_ready) {
      return null;
    }
    try {
      final chain = BytesBuilder(copy: false)
        ..add(File(_leafCertPath).readAsBytesSync())
        ..add(File(_caCertPath).readAsBytesSync());
      return SecurityContext()
        ..useCertificateChainBytes(chain.takeBytes())
        ..usePrivateKeyBytes(File(_leafKeyPath).readAsBytesSync());
    } on Object catch (e) {
      CcInfraLog.warning('rig/tls: could not load the TLS material: $e');
      return null;
    }
  }

  Future<void> _chmod(String mode, String path) async {
    if (Platform.isWindows) {
      return;
    }
    await _runTool('chmod', [mode, path]);
  }

  /// Runs a host tool and throws a [RigToolException] naming it on failure —
  /// an unchecked exit code here is a key minted at the wrong mode or a cert
  /// that silently never existed.
  static Future<void> _runTool(
    String tool,
    List<String> arguments, {
    String? executable,
    String? hint,
  }) async {
    final ProcessResult result;
    try {
      result = await Process.run(executable ?? tool, arguments);
    } on Object catch (e) {
      throw RigToolException(
        tool: tool,
        arguments: arguments,
        stderr: '$e',
        hint: hint ?? 'Is $tool installed and on PATH?',
      );
    }
    if (result.exitCode != 0) {
      throw RigToolException(
        tool: tool,
        arguments: arguments,
        exitCode: result.exitCode,
        stderr: '${result.stderr}'.trim(),
        hint: hint,
      );
    }
  }

  static Future<String?> _which(String binary) async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        binary,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final path = '${result.stdout}'.split('\n').first.trim();
      return path.isEmpty ? null : path;
    } on Object {
      return null;
    }
  }
}
