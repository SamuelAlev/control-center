import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs `scripts/release/gen_appcast.sh` against fixture artifacts and a
/// throwaway key pair, then asserts the shape of the feeds it writes.
///
/// This exists because two defects shipped in the appcast that no Dart test
/// could see: the enclosure signature was emitted as `sparkle:ed25519` (a name
/// Sparkle does not parse, so every macOS update would have failed
/// verification), and the items carried no `sparkle:version` (so neither
/// updater could evaluate them at all). Both are one grep away once the script
/// is actually executed.
///
/// The script resolves the repo root from its own location and checks the
/// signing keys against the public halves committed there (`SUPublicEDKey`,
/// `dsa_pub.pem`). The real repo ships real keys, which a throwaway pair can
/// never match — so the test copies the script into a scaffold repo root that
/// carries the throwaway keys' OWN public halves. The gate then passes for the
/// reason it exists (derived == shipped) without touching the checkout.
///
/// The script signs with python3 + `cryptography`; so does this test. When
/// that is not installed there is nothing meaningful to assert, so the suite
/// skips with the reason rather than failing — CI installs it explicitly
/// (see the "Install appcast signing dependencies" step in release.yml).
String? _skipReason() {
  try {
    final probe = Process.runSync('python3', ['-c', 'import cryptography']);
    if (probe.exitCode != 0) {
      return 'python3 lacks the cryptography package '
          '(pip install cryptography) — appcast signing cannot be exercised.';
    }
  } on ProcessException {
    return 'python3 is not available — appcast signing cannot be exercised.';
  }
  return null;
}

void main() {
  final skip = _skipReason();

  late Directory tmp;
  late String repoRoot;

  /// A throwaway Ed25519 private key, base64, in Sparkle's 64-byte export
  /// form (seed ‖ public). Generated per run so nothing secret is committed.
  late String edKey;
  late String dsaKeyPem;
  late String edPubKey;
  late String dsaPubPem;

  /// Scaffold repo root holding a copy of the script plus the throwaway keys'
  /// public halves — the script's `assert_public_keys` gate reads them
  /// relative to itself, so this keeps the gate exercised without pointing it
  /// at the real repo's committed keys.
  late String scaffoldRoot;

  setUpAll(() {
    repoRoot = Directory.current.path;
  });

  setUp(() async {
    if (skip != null) {
      return;
    }
    tmp = await Directory.systemTemp.createTemp('cc_appcast_test');

    // Key material via python3 + cryptography — the same toolchain the script
    // signs with, so a mismatch in expectations shows up here rather than in
    // a release.
    final keys = await Process.run('python3', [
      '-c',
      '''
import base64, json
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.asymmetric import dsa
from cryptography.hazmat.primitives import serialization

ed = Ed25519PrivateKey.generate()
seed = ed.private_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PrivateFormat.Raw,
    encryption_algorithm=serialization.NoEncryption(),
)
pub = ed.public_key().public_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PublicFormat.Raw,
)
dsa_key = dsa.generate_private_key(key_size=1024)
pem = dsa_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
).decode()
dsa_pub = dsa_key.public_key().public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
).decode()
print(json.dumps({
    "ed": base64.b64encode(seed + pub).decode(),
    "ed_pub": base64.b64encode(pub).decode(),
    "dsa": pem,
    "dsa_pub": dsa_pub,
}))
''',
    ]);
    if (keys.exitCode != 0) {
      fail('python3 + cryptography unavailable: ${keys.stderr}');
    }
    final parsed =
        jsonDecode((keys.stdout as String).trim()) as Map<String, dynamic>;
    edKey = parsed['ed'] as String;
    edPubKey = parsed['ed_pub'] as String;
    dsaKeyPem = parsed['dsa'] as String;
    dsaPubPem = parsed['dsa_pub'] as String;

    // Fixture artifacts in the exact layout the release job downloads.
    File('${tmp.path}/artifacts/macos/Control-Center-1.2.3-arm64.dmg')
      ..createSync(recursive: true)
      ..writeAsStringSync('fake dmg payload');
    File('${tmp.path}/artifacts/windows/Control-Center-1.2.3-x64-setup.exe')
      ..createSync(recursive: true)
      ..writeAsStringSync('fake installer payload');

    // Scaffold repo root: a copy of the script plus the public halves of the
    // throwaway keys, in the exact files `assert_public_keys` reads. The
    // script derives its repo root from its own path, so running the copy
    // redirects the gate here and away from the real repo's committed keys.
    //
    // Everything the script `source`s must be copied alongside it, at the same
    // repo-relative path — the copy resolves those against the SCAFFOLD root,
    // not the real checkout. A missing one is not a soft failure: `set -e`
    // aborts before any assertion in this file gets to run, so every test in
    // the suite fails with a bare "No such file or directory".
    scaffoldRoot = '${tmp.path}/repo';
    Directory('$scaffoldRoot/scripts/release').createSync(recursive: true);
    Directory('$scaffoldRoot/scripts/lib').createSync(recursive: true);
    File('$repoRoot/scripts/release/gen_appcast.sh').copySync(
      '$scaffoldRoot/scripts/release/gen_appcast.sh',
    );
    // The platform table: `release_ships_platform` decides which feeds the
    // script emits, so the real one has to come along or the scaffold would
    // be testing a different release matrix than the one that ships.
    File('$repoRoot/scripts/lib/artifact_names.sh').copySync(
      '$scaffoldRoot/scripts/lib/artifact_names.sh',
    );
    Directory('$scaffoldRoot/macos/Runner').createSync(recursive: true);
    File('$scaffoldRoot/macos/Runner/Info.plist').writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SUPublicEDKey</key>
	<string>$edPubKey</string>
</dict>
</plist>
''');
    File('$scaffoldRoot/dsa_pub.pem').writeAsStringSync(dsaPubPem);
  });

  tearDown(() {
    if (skip != null) {
      return;
    }
    try {
      tmp.deleteSync(recursive: true);
    } on Object {
      // Best-effort.
    }
  });

  Future<ProcessResult> runScript({String buildNumber = '4242'}) {
    return Process.run(
      'bash',
      [
        '$scaffoldRoot/scripts/release/gen_appcast.sh',
        '1.2.3',
        'v1.2.3',
        buildNumber,
      ],
      workingDirectory: tmp.path,
      environment: {
        'SPARKLE_ED25519_KEY': edKey,
        'SPARKLE_DSA_PRIVATE_KEY': dsaKeyPem,
        'GH_REPO': 'SamuelAlev/control-center',
      },
    );
  }

  test('emits the signature attribute Sparkle actually parses', () async {
    final result = await runScript();
    expect(result.exitCode, 0, reason: '${result.stderr}');

    final mac = File('${tmp.path}/appcast.xml').readAsStringSync();
    expect(mac, contains('sparkle:edSignature="'));
    // The name that shipped and would have failed every verification.
    expect(mac, isNot(contains('sparkle:ed25519=')));

    final win = File('${tmp.path}/appcast-windows.xml').readAsStringSync();
    expect(win, contains('sparkle:dsaSignature="'));
  }, skip: skip);

  test('every item carries a version the updaters can compare', () async {
    expect((await runScript()).exitCode, 0);

    final mac = File('${tmp.path}/appcast.xml').readAsStringSync();
    // Sparkle compares sparkle:version against the installed CFBundleVersion,
    // which CI sets to the build number.
    expect(mac, contains('<sparkle:version>4242</sparkle:version>'));
    expect(
      mac,
      contains(
        '<sparkle:shortVersionString>1.2.3</sparkle:shortVersionString>',
      ),
    );

    final win = File('${tmp.path}/appcast-windows.xml').readAsStringSync();
    expect(win, contains('<sparkle:version>'));
    expect(win, contains('<sparkle:shortVersionString>'));
  }, skip: skip);

  test('windows points at the installer WinSparkle can launch', () async {
    expect((await runScript()).exitCode, 0);
    final win = File('${tmp.path}/appcast-windows.xml').readAsStringSync();

    // WinSparkle *runs* the enclosure; a portable zip is not launchable.
    expect(win, contains('Control-Center-1.2.3-x64-setup.exe'));
    expect(win, isNot(contains('windows-x64.zip')));
    expect(win, contains('sparkle:installerArguments='));
  }, skip: skip);

  test('macOS points at the notarized dmg', () async {
    expect((await runScript()).exitCode, 0);
    final mac = File('${tmp.path}/appcast.xml').readAsStringSync();
    expect(mac, contains('Control-Center-1.2.3-arm64.dmg'));
    expect(mac, contains('length="'));
  }, skip: skip);

  test('the emitted EdDSA signature verifies against the key', () async {
    expect((await runScript()).exitCode, 0);
    final mac = File('${tmp.path}/appcast.xml').readAsStringSync();
    final signature = RegExp(
      r'sparkle:edSignature="([^"]+)"',
    ).firstMatch(mac)!.group(1)!;

    // Round-trip through the same primitive Sparkle uses: a signature the
    // script emits but the public half rejects is worse than none.
    final check = await Process.run('python3', [
      '-c',
      '''
import base64, sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from cryptography.exceptions import InvalidSignature

raw = base64.b64decode(sys.argv[1])
pub = Ed25519PublicKey.from_public_bytes(raw[32:64])
payload = open(sys.argv[2], "rb").read()
try:
    pub.verify(base64.b64decode(sys.argv[3]), payload)
    print("ok")
except InvalidSignature:
    print("bad")
''',
      edKey,
      '${tmp.path}/artifacts/macos/Control-Center-1.2.3-arm64.dmg',
      signature,
    ]);
    expect((check.stdout as String).trim(), 'ok');
  }, skip: skip);

  test('a 32-byte seed export is accepted too', () async {
    // Sparkle's generate_keys has shipped 32-, 64- and 96-byte export forms;
    // the script must not depend on a hand-trimmed secret.
    final seedOnly = base64.encode(base64.decode(edKey).sublist(0, 32));
    final result = await Process.run(
      'bash',
      ['$scaffoldRoot/scripts/release/gen_appcast.sh', '1.2.3', 'v1.2.3', '1'],
      workingDirectory: tmp.path,
      environment: {
        'SPARKLE_ED25519_KEY': seedOnly,
        'SPARKLE_DSA_PRIVATE_KEY': dsaKeyPem,
      },
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }, skip: skip);

  test('refuses to sign when the shipped public key is someone else\'s', () async {
    // The half-applied rotation the gate exists to catch: the checkout
    // carries a configured key that is not this signing key's half. Rewrite
    // the scaffold's plist with a different (but well-formed) key.
    final wrongKey = base64.encode(
      base64.decode(edPubKey).sublist(0).reversed.toList(),
    );
    File('$scaffoldRoot/macos/Runner/Info.plist').writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SUPublicEDKey</key>
	<string>$wrongKey</string>
</dict>
</plist>
''');
    final result = await runScript();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('SUPublicEDKey does not match'));
    expect(File('${tmp.path}/appcast.xml').existsSync(), isFalse);
  }, skip: skip);

  test('refuses to emit an unsigned feed when a key is missing', () async {
    final result = await Process.run(
      'bash',
      ['$scaffoldRoot/scripts/release/gen_appcast.sh', '1.2.3', 'v1.2.3', '1'],
      workingDirectory: tmp.path,
      environment: {'SPARKLE_DSA_PRIVATE_KEY': dsaKeyPem},
      includeParentEnvironment: false,
    );
    expect(result.exitCode, isNot(0));
    expect(File('${tmp.path}/appcast.xml').existsSync(), isFalse);
  }, skip: skip);

  test('refuses when an expected artifact is missing', () async {
    File(
      '${tmp.path}/artifacts/windows/Control-Center-1.2.3-x64-setup.exe',
    ).deleteSync();
    final result = await runScript();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('missing Windows artifact'));
  }, skip: skip);
}
