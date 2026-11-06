import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

/// One service a compose file declares.
class EnvironmentComposeService {
  /// Creates an [EnvironmentComposeService].
  const EnvironmentComposeService({required this.name, this.ports = const []});

  /// The service name.
  final String name;

  /// Its published container ports.
  final List<String> ports;
}

/// Where a compose file lives.
typedef EnvironmentComposeKey = ({
  String workspaceId,
  String repoId,
  String? file,
  String? directory,
});

const _discovered = [
  'compose.yaml',
  'compose.yml',
  'docker-compose.yaml',
  'docker-compose.yml',
];

/// The container port of one `ports:` entry, in either compose form.
String? _containerPort(Object? entry) {
  if (entry is Map) {
    return entry['target'] == null ? null : '${entry['target']}';
  }
  final text = '$entry'.split('/').first;
  return text.isEmpty ? null : text.split(':').last;
}

List<Object?> _portsOf(Object? service) {
  final ports = service is Map ? service['ports'] : null;
  return ports is List ? List<Object?>.of(ports) : const [];
}

/// The services in [yaml], or null when it isn't a compose document.
List<EnvironmentComposeService>? parseEnvironmentComposeServices(String yaml) {
  final Object? document;
  try {
    document = loadYaml(yaml);
  } on YamlException {
    return null;
  }
  if (document is! Map || document['services'] is! Map) {
    return null;
  }
  final services = document['services'] as Map;
  return [
    for (final name in services.keys)
      EnvironmentComposeService(
        name: '$name',
        ports: [
          for (final port in _portsOf(services[name])) ?_containerPort(port),
        ],
      ),
  ];
}

/// The services of a repo's compose file, read from its registered checkout.
///
/// A form hint, not a plan: this reads the file as written, so `include`,
/// `extends` and profiles aren't expanded the way the server's
/// `docker compose config` expands them. Nothing is decided from it here.
final environmentComposeServicesProvider = FutureProvider.autoDispose
    .family<List<EnvironmentComposeService>, EnvironmentComposeKey>((
      ref,
      key,
    ) async {
      final prefix = key.directory == null ? '' : '${key.directory}/';
      final file = key.file;
      for (final path in file == null ? _discovered : [file]) {
        try {
          final read = await ref.watch(
            repoFileContentProvider((
              workspaceId: key.workspaceId,
              repoId: key.repoId,
              path: '$prefix$path',
              spaceId: null,
            )).future,
          );
          final services = parseEnvironmentComposeServices(read.content);
          if (services != null) {
            return services;
          }
        } on RemoteRpcException {
          // Not this name. The next one, or an empty list and a note.
          continue;
        }
      }
      return const [];
    });
