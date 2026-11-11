import 'dart:convert';

import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/gcp_auth.dart';
import 'package:cc_connect/src/upstream_http.dart';

/// [BindingStore] on Firestore over its REST API, authenticated with the
/// runtime service account's metadata-server token. Collections:
/// `cc_connect_slack/{team_id}` (`install_id`, `bot_id`, `bot_user_id`,
/// `app_id`, `bound_at`), `cc_connect_retired/{install_id}` (`retired_at`)
/// and the retired set's size in `cc_connect_retired_count/count`
/// (`count`). Opaque ids only. A retirement finds the install's teams with
/// a single-field `install_id` query (Firestore indexes it by default). A document missing a field is corrupt and
/// answers [BindingStoreUnavailable].
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

  static const String _slackCollection = 'cc_connect_slack';
  static const String _retiredCollection = 'cc_connect_retired';
  static const String _retiredCountCollection = 'cc_connect_retired_count';

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

  ({SlackTeamBinding binding, String updateTime})? _slackFrom(
    String teamId,
    Map<String, Object?>? doc,
  ) {
    if (doc == null) {
      return null;
    }
    final fields = _fields(doc);
    final install = _string(fields, 'install_id');
    final botId = _string(fields, 'bot_id');
    final appId = _string(fields, 'app_id');
    final botUserId = _string(fields, 'bot_user_id');
    final updateTime = doc['updateTime'];
    if (install == null ||
        botId == null ||
        appId == null ||
        botUserId == null ||
        botUserId.isEmpty ||
        updateTime is! String) {
      throw const BindingStoreUnavailable('firestore binding is corrupt');
    }
    return (
      binding: SlackTeamBinding(
        teamId: teamId,
        installId: install,
        botId: botId,
        appId: appId,
        boundAt: _time(fields, 'bound_at'),
        botUserId: botUserId,
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
      'bot_user_id': {'stringValue': binding.botUserId},
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
  Future<List<String>> slackTeamsOf(String installId) async {
    final response = await _send('POST', '$_root:runQuery', {
      'structuredQuery': {
        'from': [
          {'collectionId': _slackCollection},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'install_id'},
            'op': 'EQUAL',
            'value': {'stringValue': installId},
          },
        },
        'limit': maxTeamsPerInstall,
      },
    });
    final Object? rows;
    try {
      rows = response.ok ? jsonDecode(response.text) : null;
    } on FormatException {
      throw const BindingStoreUnavailable('firestore query');
    }
    if (rows is! List) {
      throw const BindingStoreUnavailable('firestore query');
    }
    return [
      for (final row in rows)
        if (row case {'document': {'name': final String name}})
          name.substring(name.lastIndexOf('/') + 1),
    ];
  }

  @override
  Future<bool> isRetired(String installId) async =>
      await _get(_retiredCollection, installId) != null;

  /// Creates the retired document and bumps the count in one commit, under
  /// preconditions (the document absent, the count unchanged), so two
  /// instances can neither both count one retirement nor pass the cap.
  @override
  Future<bool> retireInstall(String installId) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (await isRetired(installId)) {
        return true;
      }
      final counter = await _get(_retiredCountCollection, 'count');
      var count = 0;
      Object? updateTime;
      if (counter != null) {
        final value = _fields(counter)['count'];
        final raw = value is Map ? value['integerValue'] : null;
        final parsed = raw is String ? int.tryParse(raw) : null;
        updateTime = counter['updateTime'];
        if (parsed == null || updateTime is! String) {
          throw const BindingStoreUnavailable('firestore retired count');
        }
        count = parsed;
      }
      if (count >= maxRetiredInstalls) {
        return false;
      }
      final committed = await _commit([
        {
          'update': {
            'name': _name(_retiredCollection, installId),
            'fields': {
              'retired_at': {
                'timestampValue': _clock().toUtc().toIso8601String(),
              },
            },
          },
          'currentDocument': {'exists': false},
        },
        {
          'update': {
            'name': _name(_retiredCountCollection, 'count'),
            'fields': {
              'count': {'integerValue': '${count + 1}'},
            },
          },
          'currentDocument': updateTime == null
              ? {'exists': false}
              : {'updateTime': updateTime},
        },
      ]);
      if (committed) {
        return true;
      }
    }
    throw const BindingStoreUnavailable('firestore retire contention');
  }

  /// Reads a document that never exists: proves the metadata-server token,
  /// the IAM grant and the database (404 and 200 both answer).
  @override
  Future<void> probe() async {
    await _get(_slackCollection, '_probe');
  }

  @override
  Future<void> close() async {}
}
