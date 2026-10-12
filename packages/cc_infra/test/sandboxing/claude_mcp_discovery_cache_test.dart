import 'package:cc_infra/src/sandboxing/claude_mcp_discovery_cache.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudeMcpDiscoveryCachePolicy', () {
    test('disabled is the default: no env, CLI behaviour untouched', () {
      expect(
        ClaudeMcpDiscoveryCachePolicy.disabled.envFor(trustCache: true),
        isEmpty,
      );
      expect(
        ClaudeMcpDiscoveryCachePolicy.disabled.envFor(trustCache: false),
        isEmpty,
      );
    });

    test('enabled + trusted turns the cache on with bounded staleness', () {
      const policy = ClaudeMcpDiscoveryCachePolicy(enabled: true);
      final env = policy.envFor(trustCache: true);
      expect(env['MCP_DISCOVERY_CACHE'], '1');
      expect(env['MCP_DISCOVERY_CACHE_TTL_S'], '900');
      expect(env['MCP_DISCOVERY_CACHE_MAX_STALE_S'], '3600');
      expect(env['MCP_DISCOVERY_CACHE_STRIKES'], '1');
    });

    test('enabled but untrusted pins the cache OFF', () {
      // After the launch policy changed, a cached tool list may describe a
      // surface this run does not have — force a real connect.
      const policy = ClaudeMcpDiscoveryCachePolicy(enabled: true);
      expect(policy.envFor(trustCache: false), {'MCP_DISCOVERY_CACHE': '0'});
    });

    test('honours custom bounds', () {
      const policy = ClaudeMcpDiscoveryCachePolicy(
        enabled: true,
        ttlSeconds: 60,
        maxStaleSeconds: 120,
      );
      final env = policy.envFor(trustCache: true);
      expect(env['MCP_DISCOVERY_CACHE_TTL_S'], '60');
      expect(env['MCP_DISCOVERY_CACHE_MAX_STALE_S'], '120');
    });
  });
}
