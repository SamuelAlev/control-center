// -*- mode: dart -*-
// Local harness for the desktop in-app updater: serves a REAL, correctly
// EdDSA-signed Sparkle appcast from 127.0.0.1 whose payload is a copy of the
// locally built app with a bumped version — so the ENTIRE update flow runs
// for real: menu item / About → check → Sparkle's prompt with release notes →
// download → EdDSA verification → install → relaunch, with nothing published
// and no repo files touched.
//
// How it stays safe:
//  * The signing keypair is a THROWAWAY dev key living in
//    `.dart_tool/sparkle-dev/` (gitignored, regenerated at will). Its public
//    half is patched into the BUILT app bundle's Info.plist (SUPublicEDKey)
//    via PlistBuddy — a build artifact, never `macos/Runner/Info.plist` — so
//    the committed placeholder (and thus release verification) is untouched.
//  * The payload is a `ditto` copy of the built .app with its
//    CFBundleShortVersionString bumped to the fake version, so after
//    "installing", the relaunched app believes it is up to date and the fake
//    loop terminates by itself.
//  * Nothing binds off-loopback and nothing is cached.
//
// Usage (repo root):
//   fvm dart run tool/fake_update_server.dart            # Debug app, port 8642
//   fvm dart run tool/fake_update_server.dart --port 9000 --version 99.0.0
//
// Then, in another terminal, run the app with the feed pointed here:
//   fvm flutter run -d macos \
//     --dart-define=CC_APPCAST_URL=http://127.0.0.1:8642/appcast.xml
// (use the printed URL) and click Control Center → Check for Updates….
//
// No Sparkle at all? `--dart-define=CC_FAKE_UPDATE=available` simulates the
// outcome in Dart with no server, keys, or payload.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

const defaultPort = 8642;
const defaultVersion = '999.0.0';

Future<void> main(List<String> args) async {
  final appPath = _flag(args, 'app') ?? _findBuiltApp();
  final port =
      int.tryParse(_flag(args, 'port') ?? '$defaultPort') ?? defaultPort;
  final version = _flag(args, 'version') ?? defaultVersion;

  if (appPath == null) {
    stderr.writeln(
      'No built app found under build/macos/Build/Products/{Debug,Release}.\n'
      'Build one first (fvm flutter build macos --debug / run the app once),\n'
      'or pass --app <path/to/Control Center.app>.',
    );
    exit(1);
  }
  final app = Directory(appPath);
  if (!app.existsSync()) {
    stderr.writeln('No such app bundle: $appPath');
    exit(1);
  }

  // 1. Dev keypair (throwaway, gitignored).
  final keyDir = Directory('.dart_tool/sparkle-dev')
    ..createSync(recursive: true);
  final seedFile = File('${keyDir.path}/seed.b64');
  final pubFile = File('${keyDir.path}/pub.b64');
  final algorithm = Ed25519();
  SimpleKeyPair keyPair;
  if (seedFile.existsSync()) {
    keyPair = await algorithm.newKeyPairFromSeed(
      base64.decode(seedFile.readAsStringSync().trim()),
    );
  } else {
    keyPair = await algorithm.newKeyPair();
    seedFile.writeAsStringSync(
      base64.encode(await keyPair.extractPrivateKeyBytes()),
    );
    pubFile.writeAsStringSync(
      base64.encode((await keyPair.extractPublicKey()).bytes),
    );
  }
  final publicKey = base64.encode((await keyPair.extractPublicKey()).bytes);

  // 2. Patch the BUILT bundle's SUPublicEDKey (a build artifact — never the
  //    committed source plist) so Sparkle accepts the dev signature.
  final builtPlist = '${app.path}/Contents/Info.plist';
  await _plistBuddy(
    builtPlist,
    'Set :SUPublicEDKey $publicKey',
    orAdd: 'Add :SUPublicEDKey string $publicKey',
  );

  // 3. Payload: copy the app (ditto preserves symlinks/permissions), bump its
  //    version, zip it. Installing this "update" is byte-equivalent to the
  //    current build — only the version string moved.
  final zipName = 'Control-Center-fake-$version.zip';
  final payload = File('${keyDir.path}/$zipName');
  final staging = Directory('${keyDir.path}/staging');
  if (staging.existsSync()) {
    staging.deleteSync(recursive: true);
  }
  await _run('ditto', [app.path, '${staging.path}/Control Center.app']);
  final stagedPlist = '${staging.path}/Control Center.app/Contents/Info.plist';
  await _plistBuddy(stagedPlist, 'Set :CFBundleShortVersionString $version');
  await _plistBuddy(stagedPlist, 'Set :CFBundleVersion $version');
  await _run('ditto', [
    '-c',
    '-k',
    '--keepParent',
    '${staging.path}/Control Center.app',
    payload.path,
  ]);

  // 4. Sign the enclosure (detached Ed25519 over the zip bytes — Sparkle 2's
  //    sparkle:edSignature scheme).
  final signature = base64.encode(
    (await algorithm.sign(payload.readAsBytesSync(), keyPair: keyPair)).bytes,
  );

  // 5. Serve.
  const host = '127.0.0.1';
  final appcast =
      '''
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Control Center (local fake)</title>
    <link>http://$host:$port/appcast.xml</link>
    <description>Local fake update feed — tool/fake_update_server.dart</description>
    <language>en</language>
    <item>
      <title>Version $version (fake)</title>
      <pubDate>${_rfc822(DateTime.now().toUtc())}</pubDate>
      <sparkle:channel>stable</sparkle:channel>
      <sparkle:version>$version</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <description><![CDATA[
        <h3>Version $version — local fake</h3>
        <p>This is a FAKE update served from <code>$host:$port</code> by
        <code>tool/fake_update_server.dart</code>. It is EdDSA-signed with a
        throwaway dev key, so Sparkle verifies it for real. Installing replaces
        the app with this same build (version string bumped to $version) and
        relaunches it.</p>
      ]]></description>
      <enclosure url="http://$host:$port/$zipName" sparkle:edSignature="$signature" length="${payload.lengthSync()}" type="application/zip" />
    </item>
  </channel>
</rss>
''';

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout
    ..writeln('Fake update server for: ${app.path}')
    ..writeln('Dev public key patched into the BUILT bundle: $builtPlist')
    ..writeln('Payload: ${payload.path} (${payload.lengthSync()} bytes)')
    ..writeln('')
    ..writeln('Serving appcast on http://$host:$port/appcast.xml')
    ..writeln('')
    ..writeln('Run the app against this feed in another terminal:')
    ..writeln(
      '  fvm flutter run -d macos --dart-define=CC_APPCAST_URL=http://$host:$port/appcast.xml',
    )
    ..writeln('')
    ..writeln('Then use Control Center → Check for Updates… (app menu) or')
    ..writeln(
      'Settings → Advanced → About → Check for updates. Ctrl+C here to stop.',
    )
    ..writeln('');
  await for (final request in server) {
    final path = request.uri.path;
    if (path == '/appcast.xml') {
      final bytes = utf8.encode(appcast);
      request.response
        ..headers.contentType = ContentType(
          'application',
          'xml',
          charset: 'utf-8',
        )
        ..headers.set('Cache-Control', 'no-store')
        ..headers.contentLength = bytes.length
        ..add(bytes);
      await request.response.close();
    } else if (path == '/$zipName') {
      final bytes = payload.readAsBytesSync();
      request.response
        ..headers.contentType = ContentType('application', 'zip')
        ..headers.contentLength = bytes.length
        ..add(bytes);
      await request.response.close();
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..writeln(
          'Fake update feed. Appcast: http://$host:$port/appcast.xml — run the '
          'app with --dart-define=CC_APPCAST_URL=http://$host:$port/appcast.xml',
        );
      await request.response.close();
    }
  }
}

/// Finds the most recently built .app (Debug preferred, then Release).
String? _findBuiltApp() {
  for (final config in ['Debug', 'Release', 'Profile']) {
    final dir = Directory('build/macos/Build/Products/$config');
    if (!dir.existsSync()) {
      continue;
    }
    for (final entry in dir.listSync()) {
      if (entry is Directory && entry.path.endsWith('.app')) {
        return entry.path;
      }
    }
  }
  return null;
}

Future<void> _plistBuddy(String plist, String set, {String? orAdd}) async {
  final result = await _run('/usr/libexec/PlistBuddy', [
    '-c',
    set,
    plist,
  ], tolerateFailure: orAdd != null);
  if (result.exitCode != 0 && orAdd != null) {
    await _run('/usr/libexec/PlistBuddy', ['-c', orAdd, plist]);
  }
}

Future<ProcessResult> _run(
  String executable,
  List<String> arguments, {
  bool tolerateFailure = false,
}) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0 && !tolerateFailure) {
    stderr.writeln('$executable ${arguments.join(' ')} failed:');
    stderr.writeln(result.stderr);
    exit(1);
  }
  return result;
}

/// RFC-822 date, the form Sparkle's pubDate expects.
String _rfc822(DateTime utc) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${days[utc.weekday - 1]}, ${utc.day} ${months[utc.month - 1]} '
      '${utc.year} ${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} +0000';
}

String? _flag(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--$name' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (a.startsWith('--$name=')) {
      return a.substring(name.length + 3);
    }
  }
  return null;
}
