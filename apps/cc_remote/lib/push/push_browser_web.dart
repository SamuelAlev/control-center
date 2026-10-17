import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class BrowserPushSubscription {
  const BrowserPushSubscription(this.endpoint, this.p256dh, this.auth);
  final String endpoint;
  final String p256dh;
  final String auth;
}

class BrowserPush {
  const BrowserPush();

  static const _workerPath = '/cc_push_worker.js';
  // Never replace Flutter's existing app-scope worker (offline shell).
  static const _workerScope = '/cc-push/';

  String? get unsupportedReason {
    if (!web.window.isSecureContext) return 'secure';
    if (!(web.window.navigator as JSObject)
            .hasProperty('serviceWorker'.toJS)
            .toDart ||
        !(web.window as JSObject).hasProperty('PushManager'.toJS).toDart ||
        !(web.window as JSObject).hasProperty('Notification'.toJS).toDart) {
      return 'unsupported';
    }
    final ua = web.window.navigator.userAgent;
    if (RegExp(r'iPad|iPhone|iPod', caseSensitive: false).hasMatch(ua) &&
        !web.window.matchMedia('(display-mode: standalone)').matches) {
      return 'install';
    }
    return null;
  }

  String get permission =>
      unsupportedReason == null ? web.Notification.permission : 'unsupported';

  Future<web.ServiceWorkerRegistration> _registration() async => web
      .window
      .navigator
      .serviceWorker
      .register(_workerPath.toJS, web.RegistrationOptions(scope: _workerScope))
      .toDart;
  Future<web.ServiceWorkerRegistration?> _ownRegistration() async {
    if (unsupportedReason == 'unsupported' || unsupportedReason == 'secure') {
      return null;
    }
    final found = await web.window.navigator.serviceWorker
        .getRegistration(_workerScope)
        .toDart;
    // getRegistration returns the best matching scope, including Flutter's
    // root worker when our narrow worker was never installed. Never touch it.
    return found?.scope == '${web.window.location.origin}$_workerScope'
        ? found
        : null;
  }

  BrowserPushSubscription _serialize(web.PushSubscription subscription) {
    final keys = subscription.toJSON().keys;
    final p256dh = keys.getProperty<JSString>('p256dh'.toJS).toDart;
    final auth = keys.getProperty<JSString>('auth'.toJS).toDart;
    return BrowserPushSubscription(subscription.endpoint, p256dh, auth);
  }

  Future<BrowserPushSubscription?> existing() async {
    if (unsupportedReason != null || web.Notification.permission == 'denied') {
      return null;
    }
    // Do not install or request permission merely by displaying Settings.
    final registration = await _ownRegistration();
    final sub = await registration?.pushManager.getSubscription().toDart;
    return sub == null ? null : _serialize(sub);
  }

  /// Must be invoked directly by an onPressed user gesture: permission prompt
  /// runs BEFORE the first await / RPC request and not during app startup.
  Future<BrowserPushSubscription> subscribe(String vapidPublicKey) async {
    final reason = unsupportedReason;
    if (reason != null) throw UnsupportedError('push.$reason');
    // A browser-level block (including global/OS policy) can report `denied`
    // without this site ever having displayed a prompt. Only `default` is
    // promptable; calling requestPermission on `denied` cannot override it.
    final permission = web.Notification.permission;
    if (permission == 'denied') throw StateError('push.permissionDenied');
    if (permission != 'granted' &&
        (permission != 'default' ||
            (await web.Notification.requestPermission().toDart).toDart !=
                'granted')) {
      throw StateError('push.permissionDenied');
    }
    final key = Uint8List.fromList(
      base64Url.decode(base64Url.normalize(vapidPublicKey)),
    );
    if (key.length != 65 || key[0] != 4) {
      throw const FormatException('Invalid server VAPID key');
    }
    final registration = await _registration();
    // A newly installed worker may not yet be active. Bounded wait: never
    // wait on navigator.serviceWorker.ready for this separate scoped worker.
    for (
      var attempt = 0;
      registration.active == null && attempt < 30;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (registration.active == null) throw StateError('push.workerUnavailable');
    final current = await registration.pushManager.getSubscription().toDart;
    // A VAPID rotation invalidates the browser's existing subscription.
    if (current != null) {
      final saved = current.options.applicationServerKey;
      if (saved != null && _b64(Uint8List.view(saved.toDart)) == _b64(key)) {
        return _serialize(current);
      }
      await current.unsubscribe().toDart;
    }
    final next = await registration.pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: key.toJS,
          ),
        )
        .toDart;
    return _serialize(next);
  }

  Future<void> unsubscribe() async {
    final registration = await _ownRegistration();
    final current = await registration?.pushManager.getSubscription().toDart;
    await current?.unsubscribe().toDart;
  }
}

String _b64(List<int> value) => base64Url.encode(value).replaceAll('=', '');
