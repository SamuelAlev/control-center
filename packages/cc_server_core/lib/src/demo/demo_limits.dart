/// Operational bounds for a public demo server.
///
/// These are OPERATIONAL configuration, not credentials, so they read straight
/// from the environment (`CcServerConfig.pickCredential` and the secrets store
/// are for secrets). They are grouped into one object rather than scattered as
/// flat fields so the demo's whole policy is one thing a test can inspect.
///
/// Every value is clamped on the way in: a public endpoint whose TTL was set to
/// `0` by a typo would reap every visitor mid-session, and one whose disk
/// budget was set to `100000` MB would simply fall over.
///
/// There is deliberately NO global visitor cap: a demo exists to be entered,
/// and the abusive-shape guards that remain (per-IP concurrency, per-IP redeem
/// rate at the HTTP layer, the disk budget) bound the cost per ADDRESS rather
/// than the number of people who may walk in.
class DemoLimits {
  /// Creates limits, clamping each value into its supported range.
  DemoLimits({
    Duration? ttl,
    int? poolSize,
    int? diskBudgetMb,
    int? maxPerIp,
    String? inviteCode,
  }) : ttl = _clampDuration(
         ttl ?? const Duration(minutes: 45),
         const Duration(minutes: 5),
         const Duration(minutes: 1440),
       ),
       poolSize = _clampInt(poolSize ?? 4, 0, 32),
       diskBudgetMb = _clampInt(diskBudgetMb ?? 8192, 256, 131072),
       maxPerIp = _clampInt(maxPerIp ?? 3, 1, 25),
       inviteCode = (inviteCode == null || inviteCode.isEmpty)
           ? 'demo'
           : inviteCode;

  /// Reads limits from [environment] (defaults to nothing set).
  factory DemoLimits.fromEnvironment(Map<String, String> environment) =>
      DemoLimits(
        ttl: switch (_int(environment['CC_SERVER_DEMO_TTL_MINUTES'])) {
          final int m => Duration(minutes: m),
          _ => null,
        },
        poolSize: _int(environment['CC_SERVER_DEMO_POOL_SIZE']),
        diskBudgetMb: _int(environment['CC_SERVER_DEMO_DISK_BUDGET_MB']),
        maxPerIp: _int(environment['CC_SERVER_DEMO_MAX_PER_IP']),
        inviteCode: environment['CC_SERVER_DEMO_INVITE_CODE'],
      );

  /// How long a visitor's workspace lives from redemption.
  ///
  /// Fixed, never sliding: a sliding TTL lets one forgotten open tab hold a
  /// workspace for as long as the browser is running.
  final Duration ttl;

  /// How many workspaces are seeded ahead of time and kept warm.
  ///
  /// Seeding inside the redeem POST costs 1–3s of SQLite writes, and concurrent
  /// seeds serialise on one connection; a warm pool turns redemption into a
  /// claim.
  final int poolSize;

  /// Disk ceiling for the whole demo data directory, in megabytes.
  final int diskBudgetMb;

  /// Concurrent visitors allowed from one IP.
  final int maxPerIp;

  /// The invite code the public entry URL carries.
  final String inviteCode;

  /// The disk budget in bytes.
  int get diskBudgetBytes => diskBudgetMb * 1024 * 1024;

  static int? _int(String? raw) =>
      raw == null || raw.isEmpty ? null : int.tryParse(raw.trim());

  static int _clampInt(int value, int lo, int hi) =>
      value < lo ? lo : (value > hi ? hi : value);

  static Duration _clampDuration(Duration value, Duration lo, Duration hi) =>
      value < lo ? lo : (value > hi ? hi : value);

  @override
  String toString() =>
      'DemoLimits(ttl: ${ttl.inMinutes}m, pool: $poolSize, '
      'disk: ${diskBudgetMb}MB, perIp: $maxPerIp)';
}
