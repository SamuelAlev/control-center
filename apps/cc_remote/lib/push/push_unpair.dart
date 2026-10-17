import 'package:cc_remote/push/push_browser.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Best-effort remote cleanup never prevents forgetting an offline pairing.
Future<void> unsubscribeBeforeRemoteUnpair(RemoteRpcClient? client) async {
  try {
    await client?.call(
      'push.remove',
      const {},
      timeout: const Duration(seconds: 3),
    );
  } on Object {
    // A disconnected server cannot acknowledge removal. Browser revocation is
    // independent; a later provider 404/410 or remote device revoke cleans it.
  } finally {
    try {
      await const BrowserPush().unsubscribe().timeout(
        const Duration(seconds: 3),
      );
    } on Object {
      // A failed browser API must not prevent clearing the device credential.
    }
  }
}
