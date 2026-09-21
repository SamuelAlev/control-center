import 'package:cc_rpc/cc_rpc.dart';

/// Connects a test client to a server this process just booted.
///
/// The desktop client's 30s request budget is how a UI notices a dead
/// socket. These tests share a runner whose boot loads ONNX Runtime, and
/// `workspace.upsert` (first database open plus seeding) has exceeded that
/// budget on CI — the call was still in flight when the client gave up.
/// Two minutes matches the suite's own test timeout.
Future<RemoteRpcClient> connectBootedServer({
  required Uri uri,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  bool insecureAllowed = false,
  Duration timeout = const Duration(seconds: 15),
}) {
  return connectRemoteRpc(
    uri: uri,
    deviceId: deviceId,
    psk: psk,
    pinnedFingerprint: pinnedFingerprint,
    insecureAllowed: insecureAllowed,
    timeout: timeout,
    requestTimeout: const Duration(minutes: 2),
  );
}
