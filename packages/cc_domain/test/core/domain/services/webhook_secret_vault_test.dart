import 'dart:convert';

import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  test(
    'the route key is HMAC-SHA256 under a minted 32-byte server key',
    () async {
      final store = InMemorySecretStore();
      final vault = WebhookSecretVault(store);

      final routeKey = await vault.webhookRouteKey('tok');
      final serverKey = base64Url.decode(
        store.values[WebhookSecretVault.serverRouteKeySlot]!,
      );
      expect(serverKey, hasLength(32));
      expect(
        routeKey,
        Hmac(sha256, serverKey).convert(utf8.encode('tok')).toString(),
      );
      // Stable once minted, for this vault and any other over the same store.
      expect(await vault.webhookRouteKey('tok'), routeKey);
      expect(await WebhookSecretVault(store).webhookRouteKey('tok'), routeKey);
    },
  );

  test('a trigger reference carries its route key', () {
    final ref = WebhookSecretVault.pipelineTriggerRef('ws-1', 'abc123');
    expect(WebhookSecretVault.routeKeyOfTriggerRef(ref), 'abc123');
  });

  test('workspace secrets never match another workspace', () async {
    final store = InMemorySecretStore();
    final vault = WebhookSecretVault(store);
    await vault.write(WebhookSecretVault.pipelineTriggerRef('ws-1', 'k'), 'a');
    await vault.write(WebhookSecretVault.ticketSyncRef('ws-1', 'cfg'), 'b');
    await vault.write(WebhookSecretVault.pipelineTriggerRef('ws-10', 'k'), 'c');
    await vault.webhookRouteKey('tok');

    expect(await vault.deleteForWorkspace('ws-1'), 2);
    expect(
      await vault.read(WebhookSecretVault.pipelineTriggerRef('ws-10', 'k')),
      'c',
    );
    expect(store.values, contains(WebhookSecretVault.serverRouteKeySlot));
  });
}
