import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:dio/dio.dart';

/// The project's own GitHub stars, fetched server-side and cached.
///
/// Backs the `demo.repoStars` op: the client's demo tour shows a "Star on
/// GitHub" button and the number next to it is this. All external network I/O
/// belongs to the server — a client (web or desktop) must never dial
/// api.github.com itself — so the count arrives through the same op lane the
/// newsfeed's real RSS does: the SERVER fetches, the visitor reads.
///
/// It is unauthenticated public metadata, which is why the cache matters more
/// than freshness: GitHub allows 60 unauthenticated requests per hour per
/// source IP, and a public demo's whole traffic shares one. A [ttl] of half
/// an hour keeps the demo to at most ~48 requests a day however many visitors
/// open the tour. FAILED fetches count against that same limit, so they get
/// their own shorter cooldown — and a failed refresh keeps serving the last
/// known count rather than flashing the number away.
class DemoRepoStats {
  /// Creates a stats fetcher.
  ///
  /// [dio] is injectable for tests; the default is a plain client with the
  /// same timeout shape the RSS fetcher uses, so a stalled GitHub cannot hold
  /// an RPC handler open.
  DemoRepoStats({
    Dio? dio,
    this.ttl = const Duration(minutes: 30),
    this.failureCooldown = const Duration(minutes: 5),
    void Function(String message)? onLog,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 5),
             ),
           ),
       _onLog = onLog;

  /// How long a successful fetch is trusted before the next call refreshes.
  final Duration ttl;

  /// How long a FAILED fetch holds the next one back. Failed requests count
  /// against GitHub's unauthenticated rate limit exactly like successful ones,
  /// so a demo whose egress is blocked must not retry per visitor.
  final Duration failureCooldown;

  /// GitHub requires a User-Agent on every API request.
  static const String _userAgent =
      'ControlCenter/1.0 (+https://github.com/$kDemoProjectRepoFullName)';

  final Dio _dio;
  final void Function(String message)? _onLog;

  int? _stars;
  DateTime? _fetchedAt;
  DateTime? _failedAt;
  Future<int?>? _inFlight;

  /// The current star count, or null when it has never been fetched
  /// successfully.
  ///
  /// Serves the cache while fresh; coalesces concurrent callers onto one
  /// request; on a failed refresh, keeps the stale count (the button loses
  /// nothing) and only returns null when there is nothing to lose.
  Future<int?> current() {
    final now = DateTime.now();
    final fetchedAt = _fetchedAt;
    if (fetchedAt != null && now.difference(fetchedAt) < ttl) {
      return Future.value(_stars);
    }
    final failedAt = _failedAt;
    if (failedAt != null && now.difference(failedAt) < failureCooldown) {
      return Future.value(_stars);
    }
    return _inFlight ??= _refresh();
  }

  Future<int?> _refresh() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$kDemoProjectRepoFullName',
        options: Options(headers: {'User-Agent': _userAgent}),
      );
      final stars = response.data?['stargazers_count'];
      if (stars is! num || stars < 0) {
        throw const FormatException('stargazers_count missing');
      }
      _stars = stars.toInt();
      _fetchedAt = DateTime.now();
      _failedAt = null;
      return _stars;
    } catch (e) {
      // A public marketing number is not worth an error banner: log it, keep
      // whatever was last known, and let the button render without a count.
      _failedAt = DateTime.now();
      _onLog?.call('demo: repo stars refresh failed: $e');
      return _stars;
    } finally {
      _inFlight = null;
    }
  }
}
