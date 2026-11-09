import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/gcp_auth.dart';
import 'package:cc_connect/src/upstream_http.dart';

/// [BindingStore] on Firestore over its REST API, authenticated with the
/// runtime service account's metadata-server token. Collections:
/// `cc_connect_github/{installation_id}` (`install_ids` array, `bound_at`)
/// and `cc_connect_slack/{team_id}` (`install_id`, `bot_id`, `app_id`,
/// `bound_at`). Opaque ids only.
///
/// Wrap it in [CachedBindingStore]; Slack binds use create-if-absent and
/// `updateTime` preconditions so two instances can never both win a team.
final class FirestoreBindingStore implements BindingStore {
  /// Creates the store.
  FirestoreBindingStore({
    required this.project,
    required this.database,
    required this._http,
    required this._tokens,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The GCP project.
  final String project;

  /// The Firestore database id.
  final String database;
  final UpstreamHttp _http;
  final GcpTokenSource _tokens;
  final DateTime Function() _clock;

  static const String _githubCollection = 'cc_connect_github';
  static const String _slackCollection = 'cc_connect_slack';

  String get _root => 'projects/$project/databases/$database/documents';

  String _name(String collection, String id) => '$_root/$collection/$id';

  Uri _url(String suffix) =>
      Uri.parse('https://firestore.googleapis.com/v1/$suffix');

  Future<UpstreamResponse> _send(
    String method,
    String suffix, [
    Object? body,
  ]) async {
    final token = await _tokens.token();
    final headers = {'authorization': 'Bearer $token'};
    final response = body == null
        ? await _http.send(
            UpstreamRequest(
              method,
              _url(suffix),
              headers: {...headers, 'accept': 'application/json'},
            ),
          )
        : await _http.send(
            UpstreamRequest.json(method, _url(suffix), body, headers: headers),
          );
    if (response.isTransient || response.status == 401) {
      throw const BindingStoreUnavailable('firestore');
    }
    return response;
  }

  Future<Map<String, Object?>?> _get(String collection, String id) async {
    final response = await _send('GET', _name(collection, id));
    if (response.status == 404) {
      return null;
    }
    final json = response.jsonObject;
    if (!response.ok || json == null) {
      throw const BindingStoreUnavailable('firestore get');
    }
    return json;
  }

  /// Commits [writes]; false when a precondition failed.
  Future<bool> _commit(List<Map<String, Object?>> writes) async {
    final response = await _send('POST', '$_root:commit', {'writes': writes});
    if (response.ok) {
      return true;
    }
    if (response.status == 409 ||
        response.status == 400 ||
        response.status == 412) {
      return false;
    }
    throw const BindingStoreUnavailable('firestore commit');
  }

  static String? _string(Map<String, Object?> fields, String key) {
    final value = fields[key];
    if (value is Map) {
      final s = value['stringValue'];
      return s is String ? s : null;
    }
    return null;
  }

  static DateTime _time(Map<String, Object?> fields, String key) {
    final value = fields[key];
    if (value is Map) {
      final t = value['timestampValue'];
      if (t is String) {
        return DateTime.tryParse(t)?.toUtc() ?? DateTime.utc(1970);
      }
    }
    return DateTime.utc(1970);
  }

  static Map<String, Object?> _fields(Map<String, Object?> doc) {
    final fields = doc['fields'];
    return fields is Map<String, Object?> ? fields : const {};
  }

  @override
  Future<GitHubInstallationBinding?> github(int installationId) async {
    final doc = await _get(_githubCollection, '$installationId');
    if (doc == null) {
      return null;
    }
    final fields = _fields(doc);
    final ids = <String>{};
    final array = fields['install_ids'];
    if (array is Map) {
      final arrayValue = array['arrayValue'];
      final values = arrayValue is Map ? arrayValue['values'] : null;
      if (values is List) {
        for (final value in values) {
          final s = value is Map ? value['stringValue'] : null;
          if (s is String) {
            ids.add(s);
          }
        }
      }
    }
    return GitHubInstallationBinding(
      installationId: installationId,
      installIds: ids,
      boundAt: _time(fields, 'bound_at'),
    );
  }

  @override
  Future<void> addGitHub(int installationId, String installId) async {
    // Upsert: appendMissingElements is atomic server-side, so concurrent
    // binds of different servers both land.
    final ok = await _commit([
      {
        'update': {
          'name': _name(_githubCollection, '$installationId'),
          'fields': {
            'installation_id': {'integerValue': '$installationId'},
          },
        },
        'updateMask': {
          'fieldPaths': ['installation_id'],
        },
        'updateTransforms': [
          {
            'fieldPath': 'install_ids',
            'appendMissingElements': {
              'values': [
                {'stringValue': installId},
              ],
            },
          },
          {'fieldPath': 'bound_at', 'setToServerValue': 'REQUEST_TIME'},
        ],
      },
    ]);
    if (!ok) {
      throw const BindingStoreUnavailable('firestore github bind');
    }
  }

  ({SlackTeamBinding binding, String updateTime})? _slackFrom(
    String teamId,
    Map<String, Object?>? doc,
  ) {
    if (doc == null) {
      return null;
    }
    final fields = _fields(doc);
    final install = _string(fields, 'install_id');
    final updateTime = doc['updateTime'];
    if (install == null || updateTime is! String) {
      return null;
    }
    return (
      binding: SlackTeamBinding(
        teamId: teamId,
        installId: install,
        botId: _string(fields, 'bot_id') ?? '',
        appId: _string(fields, 'app_id') ?? '',
        boundAt: _time(fields, 'bound_at'),
      ),
      updateTime: updateTime,
    );
  }

  @override
  Future<SlackTeamBinding?> slack(String teamId, {bool fresh = false}) async =>
      _slackFrom(teamId, await _get(_slackCollection, teamId))?.binding;

  Map<String, Object?> _slackDocument(SlackTeamBinding binding) => {
    'name': _name(_slackCollection, binding.teamId),
    'fields': {
      'install_id': {'stringValue': binding.installId},
      'bot_id': {'stringValue': binding.botId},
      'app_id': {'stringValue': binding.appId},
      'bound_at': {'timestampValue': _clock().toUtc().toIso8601String()},
    },
  };

  @override
  Future<SlackTeamBinding> bindSlack(SlackTeamBinding binding) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final created = await _commit([
        {
          'update': _slackDocument(binding),
          'currentDocument': {'exists': false},
        },
      ]);
      if (created) {
        return binding;
      }
      final existing = _slackFrom(
        binding.teamId,
        await _get(_slackCollection, binding.teamId),
      );
      if (existing == null) {
        continue; // Released between the two calls; try to create again.
      }
      if (existing.binding.installId != binding.installId) {
        return existing.binding;
      }
      final updated = await _commit([
        {
          'update': _slackDocument(binding),
          'currentDocument': {'updateTime': existing.updateTime},
        },
      ]);
      if (updated) {
        return binding;
      }
    }
    throw const BindingStoreUnavailable('firestore slack bind contention');
  }

  @override
  Future<bool> releaseSlack(String teamId, {String? installId}) async {
    final existing = _slackFrom(teamId, await _get(_slackCollection, teamId));
    if (existing == null ||
        (installId != null && existing.binding.installId != installId)) {
      return false;
    }
    return _commit([
      {
        'delete': _name(_slackCollection, teamId),
        'currentDocument': {'updateTime': existing.updateTime},
      },
    ]);
  }

  @override
  Future<void> close() async {}
}
