import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

const String _usage = '''
usage: dart run cc_connect:config_tool <command> [options]

  keygen --out <seed-file>
      Writes a fresh 32-byte Ed25519 seed (mode 0600, refuses to overwrite)
      and prints its public key for hostedConfigRootKeys /
      CONNECT_CONFIG_PUBLIC_KEYS. Run it on the offline signing machine.

  sign --seed <seed-file> --payload <payload.json> [--out <signed.json>]
      Validates the payload as a /v1/config (protocol 1; issued_at defaults
      to now), signs the canonical JSON and writes the signed config
      (stdout without --out).

  verify --key <base64url-public-key> <signed.json>
      Exits 0 when the signature verifies against the key.

  seal-key
      Prints a fresh local seal keyring entry (kid:base64key). Prepend it to
      CONNECT_SEAL_KEYS to rotate; keep older entries until their seals age
      out.
''';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.first == '--help') {
    stdout.write(_usage);
    exitCode = arguments.isEmpty ? 64 : 0;
    return;
  }
  final command = arguments.first;
  final rest = arguments.sublist(1);
  try {
    switch (command) {
      case 'keygen':
        await _keygen(_options(rest, const {'--out'}));
      case 'sign':
        await _sign(_options(rest, const {'--seed', '--payload', '--out'}));
      case 'verify':
        await _verify(rest);
      case 'seal-key':
        stdout.writeln(newSealKeyEntry());
      default:
        throw _UsageError('unknown command "$command"');
    }
  } on _UsageError catch (error) {
    stderr
      ..writeln('error: ${error.message}')
      ..write(_usage);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('error: ${error.message}: ${error.path}');
    exitCode = 74;
  }
}

final class _UsageError implements Exception {
  const _UsageError(this.message);

  final String message;
}

Map<String, String> _options(List<String> args, Set<String> allowed) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final flag = args[i];
    if (!allowed.contains(flag) || i + 1 >= args.length) {
      throw _UsageError('unexpected argument "$flag"');
    }
    out[flag] = args[++i];
  }
  return out;
}

String _required(Map<String, String> options, String flag) =>
    options[flag] ?? (throw _UsageError('$flag is required'));

Future<void> _keygen(Map<String, String> options) async {
  final path = _required(options, '--out');
  final file = File(path);
  if (file.existsSync()) {
    throw _UsageError('$path exists; refusing to overwrite a signing seed');
  }
  final seed = randomBytes(32);
  await file.parent.create(recursive: true);
  // Created 0600 (never widened, never chmod-ed afterwards), then renamed
  // into place: no window where another account can open the seed.
  try {
    await writePrivateFile(path, seed, overwrite: false);
  } on FileSystemException {
    if (file.existsSync()) {
      throw _UsageError('$path exists; refusing to overwrite a signing seed');
    }
    rethrow;
  }
  stdout
    ..writeln('seed written to $path (keep it offline)')
    ..writeln('public key: ${await configPublicKeyForSeed(seed)}');
}

Future<List<int>> _readSeed(String path) async {
  final bytes = await File(path).readAsBytes();
  if (bytes.length == 32) {
    return bytes;
  }
  // Accept a base64url text seed too.
  try {
    final decoded = unb64url(utf8.decode(bytes).trim());
    if (decoded.length == 32) {
      return decoded;
    }
  } on FormatException {
    // Fall through.
  }
  throw const _UsageError('the seed file must hold exactly 32 bytes');
}

Future<void> _sign(Map<String, String> options) async {
  final seed = await _readSeed(_required(options, '--seed'));
  final payloadPath = _required(options, '--payload');
  final Object? decoded;
  try {
    decoded = jsonDecode(await File(payloadPath).readAsString());
  } on FormatException {
    throw _UsageError('$payloadPath is not JSON');
  }
  if (decoded is! Map<String, Object?>) {
    throw _UsageError('$payloadPath is not a JSON object');
  }
  final input = {
    'protocol': connectProtocolVersion,
    'issued_at': DateTime.now().toUtc().toIso8601String(),
    ...decoded,
  }..remove('signature');
  final ConnectConfig config;
  try {
    config = ConnectConfig.fromJson(input);
  } on FormatException catch (error) {
    throw _UsageError('payload: ${error.message}');
  }
  for (final lane in const ['github', 'google', 'linear', 'slack', 'klipy']) {
    final parsed = switch (lane) {
      'github' => config.github,
      'google' => config.google,
      'linear' => config.linear,
      'slack' => config.slack,
      _ => config.klipy,
    };
    if (input[lane] != null && parsed == null) {
      throw _UsageError('payload: lane $lane is malformed');
    }
  }
  final payload = config.payload();
  final signed = {
    ...payload,
    'signature': await signConnectConfig(payload, seed),
  };
  final text = '${const JsonEncoder.withIndent('  ').convert(signed)}\n';
  final out = options['--out'];
  if (out == null) {
    stdout.write(text);
  } else {
    await File(out).writeAsString(text, flush: true);
    stdout.writeln('signed config (epoch ${config.epoch}) written to $out');
  }
}

Future<void> _verify(List<String> args) async {
  if (args.length != 3 || args[0] != '--key') {
    throw const _UsageError('verify --key <public-key> <signed.json>');
  }
  final key = args[1];
  final decoded = jsonDecode(await File(args[2]).readAsString());
  if (decoded is! Map<String, Object?>) {
    throw const _UsageError('not a JSON object');
  }
  final ok = await verifyConnectConfigSignature(decoded, trustedKeys: [key]);
  stdout.writeln(ok ? 'signature ok' : 'signature INVALID');
  exitCode = ok ? 0 : 1;
}
