import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:test/test.dart';

/// [head] then [unit] repeated, cut to [size] characters.
String _fill(String head, String unit, int size) {
  final out = StringBuffer(head);
  while (out.length < size) {
    out.write(unit);
  }
  return out.toString().substring(0, size);
}

/// The worst shapes found for each pattern family of [redactSecrets]: a
/// prefix that starts a match repeated, or followed by a run the match
/// cannot finish, so a pattern that rescans from every start would show it.
final Map<String, String Function(int size)> _shapes = {
  'URL credentials, colons': (n) => _fill('a://', ':', n),
  'URL credentials, a: repeated': (n) => _fill('a://', 'a:', n),
  'URL credentials, :// repeated': (n) => _fill('', 'a://a:', n),
  'x-access-token: repeated': (n) => _fill('', 'x-access-token:', n),
  'x-access-token: then a run': (n) => _fill('x-access-token:', 'a', n),
  'JWT, -eyJaaaaaaaa repeated': (n) => _fill('', '-eyJaaaaaaaa', n),
  'JWT, header then .eyJ repeated': (n) =>
      _fill('eyJaaaaaaaa', '.eyJaaaaaaaa', n),
  'JWT, eyJ then a run': (n) => _fill('eyJ', 'a', n),
  '--api-key= then spaces': (n) => _fill('--api-key=', ' ', n),
  '--token then spaces': (n) => _fill('--token', ' ', n),
  '--key repeated': (n) => _fill('', '--key', n),
  'Authorization: then spaces': (n) => _fill('Authorization:', ' ', n),
  'Authorization: Bearer repeated': (n) => _fill('', 'Authorization:Bearer', n),
  'x-access-token base64 prefix repeated': (n) =>
      _fill('', 'eC1hY2Nlc3MtdG9rZW46!', n),
  'CLAUDE_CODE_OAUTH_TOKEN then spaces': (n) =>
      _fill('CLAUDE_CODE_OAUTH_TOKEN', ' ', n),
  'GH_TOKEN repeated': (n) => _fill('', 'GH_TOKEN ', n),
  '"token" then spaces': (n) => _fill('"token"', ' ', n),
  '"token":" then no quote': (n) => _fill('"token":"', 'a', n),
  '"api_key" repeated': (n) => _fill('', '"api_key":', n),
  'Bearer repeated': (n) => _fill('', 'Bearer a ', n),
  'sk- repeated, short': (n) => _fill('', '-sk-a', n),
  'sk-ant- repeated': (n) => _fill('', ' sk-ant-a', n),
  'AIza repeated': (n) => _fill('', ' AIzaa', n),
  'AKIA repeated': (n) => _fill('', ' AKIAAAAAAAAAAAAAAA', n),
  'ghp_ then dots': (n) => _fill('ghp_a', '.', n),
  'ghp_ repeated, short': (n) => _fill('', ' ghp_a', n),
  'github_pat_ repeated': (n) => _fill('', ' github_pat_a', n),
  'glpat- repeated': (n) => _fill('', ' glpat-a', n),
  'ATATT repeated': (n) => _fill('', ' ATATTa', n),
  'xoxb- repeated': (n) => _fill('', ' xoxb-a', n),
  'lin_api_ repeated': (n) => _fill('', ' lin_api_a', n),
  'ya29. repeated': (n) => _fill('', ' ya29.a', n),
  '1// repeated': (n) => _fill('', ' 1//a', n),
  // The prefixes found glued to the text before them: every position of a
  // run of letters may start one.
  'sk-ant- glued, repeated': (n) => _fill('', 'xsk-ant-a', n),
  'ghp_ glued, repeated': (n) => _fill('', 'xghp_a', n),
  'ghp_ glued, short bodies': (n) => _fill('', 'xghp_a!', n),
  'ghp_ glued then dots': (n) => _fill('xghp_a', '.', n),
  'github_pat_ glued, repeated': (n) => _fill('', 'xgithub_pat_a', n),
  'glpat- glued, repeated': (n) => _fill('', 'xglpat-a', n),
  'xoxb- glued, repeated': (n) => _fill('', 'xxoxb-a', n),
  'xoxe.xoxb- glued, repeated': (n) => _fill('', 'xoxe.xoxe.', n),
  'xoxb- then .xox repeated': (n) => _fill('xoxb-', '.xox', n),
  'ya29. glued, repeated': (n) => _fill('', 'xya29.a', n),
  // The glued shapes, each one character short of a match, repeated.
  'sk-ant- glued kind, short body': (n) =>
      _fill('', 'xsk-ant-api03-${'a' * 31}!', n),
  'sk-ant- glued, kind then a run': (n) => _fill('xsk-ant-api03-', 'a', n),
  'ghp_ glued, short alphanumeric body': (n) =>
      _fill('', 'xghp_${'a' * 29}!', n),
  'github_pat_ glued, one short': (n) =>
      _fill('', 'xgithub_pat_${'a' * 22}_${'a' * 58}!', n),
  'glpat- glued, routable without its tail': (n) =>
      _fill('', 'xglpat-${'a' * 120}.', n),
  'glpat- glued, then a run': (n) => _fill('xglpat-', 'a', n),
  'xoxb- glued, workspace id then nothing': (n) =>
      _fill('', 'xxoxb-${'1' * 13}-', n),
  'xoxe- glued, version then a short body': (n) =>
      _fill('', 'xxoxe.xoxp-1-${'A' * 99}!', n),
  'ya29. glued, short body': (n) => _fill('', 'xya29.${'a' * 63}!', n),
  'ghs_ glued, app id and a JWT header with no dot': (n) =>
      _fill('', 'xghs_1_eyJ${'a' * 200}', n),
  'ghs_ glued, app id and a header, repeated': (n) =>
      _fill('', 'ghs_1_eyJaaaaaaaa', n),
  'ghs_ glued, header then dots': (n) => _fill('xghs_1_eyJ${'a' * 8}', '.', n),
  'glptt- glued, one short': (n) => _fill('', 'xglptt-${'a' * 39}!', n),
  'gloas- glued, one short': (n) => _fill('', 'xgloas-${'a' * 63}!', n),
  'glagent- glued, one short': (n) => _fill('', 'xglagent-${'a' * 49}!', n),
  'glimt- glued, one short': (n) => _fill('', 'xglimt-${'a' * 24}!', n),
  'glcbt- glued, one short': (n) => _fill('', 'xglcbt-64_${'a' * 19}!', n),
  'glrt- glued, one short': (n) => _fill('', 'xglrt-t1_${'a' * 19}!', n),
  'glcbt- glued, id repeated': (n) => _fill('xglcbt-', 'a_', n),
  'xoxa- glued, one short': (n) => _fill('', 'xxoxa-2-${'a' * 29}!', n),
  'xoxa- glued, repeated': (n) => _fill('', 'xoxa-2-', n),
  'ya29.c. glued, one short': (n) => _fill('', 'xya29.c.${'a.' * 31}a!', n),
  'ya29.c. glued, repeated': (n) => _fill('', 'ya29.c.', n),
  'BEGIN header then letters': (n) => _fill('-----BEGIN ', 'A ', n),
  'BEGIN block, END headers': (n) =>
      _fill('-----BEGIN PRIVATE KEY-----', '-----END A', n),
  'BEGIN repeated': (n) => _fill('', '-----BEGIN PUBLIC KEY-----', n),
  'letters': (n) => _fill('', 'a', n),
  'whitespace': (n) => _fill('', ' \n\t', n),
};

const _kib = 1024;

/// What 1 MiB of any shape may take. A pattern that rescans from every start
/// takes minutes at this size, and the scaling check below is what holds a
/// pattern linear; this only bounds the constant. The slowest shape
/// (`glpat- glued, repeated`) takes about 0.75 s on a developer machine and
/// took 2.1 to 2.6 s on a hosted macOS runner, a third of its speed, so the
/// ceiling leaves that runner room.
const _ceiling = Duration(seconds: 5);

/// Fixed slack in the scaling check, for timer and collector noise on
/// inputs that take a few milliseconds.
const _slackMs = 40;

/// Series measured before a shape fails. One slow sample on a loaded runner
/// (a collection, another suite's isolate) breaks a single series; a pattern
/// that rescans from every start breaks every one.
const _attempts = 3;

const _sizes = [64 * _kib, 256 * _kib, 1024 * _kib];

/// Milliseconds [redactSecrets] takes on [shape] at each of [_sizes],
/// stopping at the first size over [_ceiling]: a pattern that rescans from
/// every start would take minutes on the next one.
Map<int, int> _measure(String Function(int size) shape) {
  final times = <int, int>{};
  for (final size in _sizes) {
    final input = shape(size);
    final watch = Stopwatch()..start();
    redactSecrets(input);
    watch.stop();
    times[size] = watch.elapsedMilliseconds;
    if (watch.elapsed >= _ceiling) {
      break;
    }
  }
  return times;
}

/// Whether [times] stays under [_ceiling] and grows about linearly: four
/// times the input costs at most about six times the time.
bool _linear(Map<int, int> times) =>
    times.length == _sizes.length &&
    times.values.every((ms) => ms < _ceiling.inMilliseconds) &&
    times[256 * _kib]! <= 6 * times[64 * _kib]! + _slackMs &&
    times[1024 * _kib]! <= 6 * times[256 * _kib]! + _slackMs;

void main() {
  setUpAll(() {
    // Compiles every pattern before anything is timed.
    for (final shape in _shapes.values) {
      redactSecrets(shape(256));
    }
  });

  for (final MapEntry(key: name, value: shape) in _shapes.entries) {
    test('$name: linear in its input, 1 MiB under '
        '${_ceiling.inSeconds} s', () {
      final series = <Map<int, int>>[];
      do {
        series.add(_measure(shape));
      } while (!_linear(series.last) && series.length < _attempts);
      final times = series.last;
      for (final size in times.keys) {
        expect(
          times[size]!,
          lessThan(_ceiling.inMilliseconds),
          reason: '$size: $series',
        );
      }
      expect(
        times[256 * _kib]!,
        lessThanOrEqualTo(6 * times[64 * _kib]! + _slackMs),
        reason: '$series',
      );
      expect(
        times[1024 * _kib]!,
        lessThanOrEqualTo(6 * times[256 * _kib]! + _slackMs),
        reason: '$series',
      );
      // ignore: avoid_print
      print('TIMING $name $series');
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
