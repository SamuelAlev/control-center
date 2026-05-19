import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/infrastructure/model_status_stream.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatusThenHang implements ModelControl {
  _StatusThenHang(this.snapshot);

  final ModelStatusSnapshot snapshot;
  final StreamController<ModelStatusSnapshot> _hang =
      StreamController<ModelStatusSnapshot>();

  void dispose() => _hang.close();

  @override
  Future<ModelStatusSnapshot> status() async => snapshot;

  @override
  Stream<ModelStatusSnapshot> watch() => _hang.stream;

  @override
  Future<void> install() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> uninstall() async {}
}

class _MissingOps implements ModelControl {
  @override
  Future<ModelStatusSnapshot> status() async {
    throw RemoteRpcException(RpcErrorCodes.opUnknown, 'unknown');
  }

  @override
  Stream<ModelStatusSnapshot> watch() =>
      Stream.error(RemoteRpcException(RpcErrorCodes.opUnknown, 'unknown'));

  @override
  Future<void> install() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> uninstall() async {}
}

void main() {
  test('seeds from status even when watch never emits', () async {
    final control = _StatusThenHang(
      const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled),
    );
    addTearDown(control.dispose);

    final first = await modelStatusStream(control).first;
    expect(first, isNotNull);
    expect(first!.status, ModelLifecycleStatus.notInstalled);
  });

  test('opUnknown degrades to null', () async {
    final values = await modelStatusStream(_MissingOps()).toList();
    expect(values, [null]);
  });
}
