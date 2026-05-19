import 'package:cc_infra/src/claude_accounts/claude_account_store.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/usage/subscription_usage_service.dart';
import 'package:test/test.dart';

/// THROWAWAY — checks the spend block reaches the entity.
void main() {
  test('per-account readings, windows or spend', () async {
    const dataDir = '/Users/samuel.alev/dev/control-center/apps/cc_server/data';
    final store = ClaudeAccountStore(dataDir: dataDir);
    final service = SubscriptionUsageService(dio: createDio());
    for (final a in await store.list()) {
      await store.syncCredentialFromKeychain(a.id);
      final u = await service.fetchClaudeForConfigDir(store.configDirFor(a.id));
      final sp = u.spend;
      // ignore: avoid_print
      print(
        '${a.id.padRight(18)} status=${u.status.name.padRight(12)} '
        'windows=${[for (final w in u.windows) '${w.id}=${(w.usedFraction * 100).round()}%']} '
        'spend=${sp == null ? 'none' : '${sp.used.toStringAsFixed(2)}/${sp.limit.toStringAsFixed(2)} ${sp.currency} (${(sp.usedFraction * 100).toStringAsFixed(2)}%)'}',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
