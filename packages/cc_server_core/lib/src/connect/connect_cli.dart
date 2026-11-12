import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/connect_ops.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/dotenv.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';

/// `cc_server connect status | enable [--url URL] | disable`.
///
/// Reads and writes the same server settings Settings → Connect does, from
/// the data directory, without starting the server. A running server
/// notices the changed choice or key on its next Connect config read
/// (`ConnectSettings.noticeExternalChanges`) and drops what it cached, as the
/// Settings screen does at once. Returns the process exit code: 78 when
/// `CC_CONNECT_URL` is unusable, as the server's boot refuses it.
Future<int> runConnectCommand({
  required List<String> args,
  IOSink? out,
  IOSink? err,
}) async {
  // The process's stdio (or the caller's sinks): never ours to close.
  // ignore: close_sinks
  final stdoutSink = out ?? stdout;
  // ignore: close_sinks
  final stderrSink = err ?? stderr;
  final command = args.isEmpty ? 'status' : args.first;
  final rest = args.isEmpty ? const <String>[] : args.sublist(1);
  if (command == '--help' || command == '-h' || command == 'help') {
    stdoutSink.writeln(connectUsage);
    return 0;
  }
  final environment = environmentWithDotenv();
  try {
    ConnectSettings.checkEnvironment(environment);
  } on ConnectEnvironmentInvalid catch (e) {
    stderrSink.writeln(
      'cc_server connect: CC_CONNECT_URL is not usable: ${e.reason}',
    );
    return 78;
  }
  final config = CcServerConfig.resolve(rest, environment: environment);
  Directory(config.dataDir).createSync(recursive: true);
  final db = GlobalDatabase.atDataDir(config.dataDir);
  try {
    final secrets = FileSecretsStore(dataDir: config.dataDir);
    final settings = ConnectSettings(
      secrets: secrets,
      settings: db.serverSettingDao,
      environment: environment,
    );
    final client = ConnectClient(settings: settings);
    final apps = ProviderAppSettings(
      secrets: secrets,
      settings: db.serverSettingDao,
      ownAppsActive: settings.serverOwnAppsActive,
    );
    final klipy = KlipyGifs(connect: client, ownAppKey: config.klipyAppKey);
    switch (command) {
      case 'status':
        await _printStatus(stdoutSink, client, apps, klipy);
        return 0;
      case 'enable':
        final url = _flag(rest, 'url') ?? '';
        await settings.setChoice(
          url.isEmpty ? ConnectMode.hosted : ConnectMode.custom,
          url: url,
        );
        await _printStatus(stdoutSink, client, apps, klipy, refresh: true);
        return 0;
      case 'disable':
        await settings.setChoice(ConnectMode.off);
        await _printStatus(stdoutSink, client, apps, klipy);
        return 0;
      default:
        stderrSink
          ..writeln('Unknown connect command: $command')
          ..writeln(connectUsage);
        return 64;
    }
  } on ValidationException catch (e) {
    stderrSink.writeln('cc_server connect: ${e.message}');
    return 1;
  } finally {
    await db.close();
  }
}

/// The `cc_server connect` help text.
const String connectUsage = '''
Usage: cc_server connect <command> [--data-dir PATH]

  status               Show the Connect this server uses and each lane's source.
  enable [--url URL]   Use the hosted Connect, or a self-hosted one at URL.
  disable              Use own apps only.

CC_CONNECT_URL (hosted, off or a URL) overrides the stored choice.''';

Future<void> _printStatus(
  IOSink out,
  ConnectClient client,
  ProviderAppSettings apps,
  KlipyGifs klipy, {
  bool refresh = false,
}) async {
  final state = await client.configState(
    await client.serverTarget(),
    refresh: refresh,
  );
  final lanes = await connectLaneStatuses(
    apps: apps,
    config: state.usable ? state.config : null,
    klipy: klipy,
  );
  out
    ..writeln('Mode        ${state.choice.mode.name}')
    ..writeln(
      'URL         ${state.choice.baseUrl.isEmpty ? '-' : state.choice.baseUrl}',
    )
    ..writeln(
      'Locked      ${state.choice.lockedByEnvironment ? 'yes (CC_CONNECT_URL)' : 'no'}',
    )
    ..writeln('Install id  ${state.installId.isEmpty ? '-' : state.installId}')
    ..writeln(
      'Health      ${state.usable ? 'ok' : (state.error.isEmpty ? 'off' : state.error)}'
      '${state.stale ? ' (cached; Connect unreachable)' : ''}',
    );
  final pins = state.pendingPins;
  if (pins != null && pins.isNotEmpty) {
    out.writeln(
      'Pins        changed; confirm in Settings → Connect before lanes use it',
    );
  }
  out.writeln('Lanes');
  for (final lane in lanes) {
    out.writeln(
      '  ${lane.lane.padRight(11)}${lane.source.name}'
      '${lane.error.isEmpty ? '' : ' — ${lane.error}'}',
    );
  }
}

String? _flag(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--$name' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (arg.startsWith('--$name=')) {
      return arg.substring(name.length + 3);
    }
  }
  return null;
}
