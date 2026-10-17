class BrowserPushSubscription {
  const BrowserPushSubscription(this.endpoint, this.p256dh, this.auth);
  final String endpoint;
  final String p256dh;
  final String auth;
}

class BrowserPush {
  const BrowserPush();
  String? get unsupportedReason => 'unsupported';
  String get permission => 'unsupported';
  Future<BrowserPushSubscription?> existing() async => null;
  Future<BrowserPushSubscription> subscribe(String vapidPublicKey) async =>
      throw UnsupportedError('WebPush requires an installed browser PWA');
  Future<void> unsubscribe() async {}
}
