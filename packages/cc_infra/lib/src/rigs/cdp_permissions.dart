import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/browser_permission_probe.dart';
import 'package:cc_infra/src/rigs/browser_permission_script.dart';

/// CDP `Browser.grantPermissions` names a headless guest needs so a page
/// that awaits `getUserMedia` / notifications on boot can paint. Failures
/// are swallowed by the caller: an older CDP that rejects a name still
/// leaves `--use-fake-ui-for-media-stream` in place.
const List<String> kCdpHeadlessPermissionGrants = [
  'audioCapture',
  'videoCapture',
  'geolocation',
  'notifications',
  'clipboardReadWrite',
  'clipboardSanitizedWrite',
  'midi',
  'displayCapture',
];

/// Permissions-API kind → CDP `PermissionType`. `durableStorage` is not in
/// the handshake list because Chromium still prompts for it; it is granted
/// only after the human allows it on the shield.
const Map<String, String> kCdpPermissionTypeByKind = {
  'camera': 'videoCapture',
  'microphone': 'audioCapture',
  'notifications': 'notifications',
  'geolocation': 'geolocation',
  'persistent-storage': 'durableStorage',
  'clipboard-read': 'clipboardReadWrite',
  'display-capture': 'displayCapture',
  'midi': 'midi',
};

/// Sends a CDP method. Matches `CdpClient._send`.
typedef CdpSend =
    Future<Map<String, dynamic>> Function(
      String method, {
      Map<String, dynamic>? params,
      Duration? timeout,
      bool duringHandshake,
    });

/// Reads a `Runtime.bindingCalled` event into a probe, or null when it is
/// not ours.
BrowserPermissionProbe? probeFromCdpBinding({
  required String method,
  required Map<String, dynamic> params,
}) {
  if (method != 'Runtime.bindingCalled') {
    return null;
  }
  if (params['name'] != kBrowserPermissionBinding) {
    return null;
  }
  final contextId = params['executionContextId'];
  return BrowserPermissionProbe.parse(
    params['payload'],
    contextId: contextId is int ? contextId : null,
  );
}

/// Handshake grants so a page awaiting getUserMedia can paint. Persistent
/// storage is not in the list — that prompt is the shield flyout.
Future<void> grantCdpHeadlessPermissions(
  CdpSend send, {
  String? origin,
  bool duringHandshake = false,
}) async {
  try {
    await send(
      'Browser.grantPermissions',
      params: {
        'permissions': kCdpHeadlessPermissionGrants,
        if (origin != null) 'origin': origin,
      },
      duringHandshake: duringHandshake,
    );
  } on Object catch (e) {
    CcInfraLog.debug('rig/cdp: grantPermissions skipped: $e');
  }
}

/// Binding + new-document script + current-document evaluate.
Future<void> installCdpPermissionInterceptor(
  CdpSend send, {
  bool duringHandshake = false,
}) async {
  try {
    await send(
      'Runtime.addBinding',
      params: {'name': kBrowserPermissionBinding},
      duringHandshake: duringHandshake,
    );
    await send(
      'Page.addScriptToEvaluateOnNewDocument',
      params: {'source': kBrowserPermissionInstallScript},
      duringHandshake: duringHandshake,
    );
    await send(
      'Runtime.evaluate',
      params: {
        'expression': kBrowserPermissionInstallScript,
        'returnByValue': true,
      },
      duringHandshake: duringHandshake,
    );
  } on Object catch (e) {
    CcInfraLog.debug('rig/cdp: permission interceptor skipped: $e');
  }
}

/// Grants the origin permission when allowed, then resolves the page promise.
Future<void> resolveCdpPermissionProbe(
  CdpSend send,
  BrowserPermissionProbe probe, {
  required bool allow,
}) async {
  if (allow) {
    final type = kCdpPermissionTypeByKind[probe.kind];
    if (type != null && probe.origin.isNotEmpty) {
      try {
        await send(
          'Browser.grantPermissions',
          params: {
            'permissions': [type],
            'origin': probe.origin,
          },
        );
      } on Object catch (e) {
        CcInfraLog.debug('rig/cdp: origin grant skipped: $e');
      }
    }
  }
  await send(
    'Runtime.evaluate',
    params: {
      'expression': browserPermissionResolveScript(probe.id, allow: allow),
      if (probe.contextId != null) 'contextId': probe.contextId,
      'returnByValue': true,
    },
  );
}
