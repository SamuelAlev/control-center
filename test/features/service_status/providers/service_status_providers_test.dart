import 'dart:async';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [RemoteRpcClient] stand-in answering only `serviceStatus.getAll`
/// through a controllable callback; everything else throws if touched.
class _FakeStatusRpcClient implements RemoteRpcClient {
  _FakeStatusRpcClient(this.getAll);

  final Future<Map<String, dynamic>> Function() getAll;

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) => op == 'serviceStatus.getAll'
      ? getAll()
      : throw UnimplementedError('FakeStatusRpcClient.op $op');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeStatusRpcClient.${invocation.memberName}');
}

Map<String, dynamic> _summaryPage() => <String, dynamic>{
  'status': {'indicator': 'none', 'description': 'All Systems Operational'},
};

Map<String, dynamic> _allOperational() => <String, dynamic>{
  'github': _summaryPage(),
  'claude': _summaryPage(),
  'openai': _summaryPage(),
  'kimi': _summaryPage(),
};

void main() {
  group('ServiceStatusesNotifier.refresh', () {
    test('retains the last snapshot while the fetch is in flight', () async {
      // First fetch resolves healthy; the second (the manual refresh) hangs
      // until the test completes it.
      var callCount = 0;
      final hangingFetch = Completer<Map<String, dynamic>>();
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(
            _FakeStatusRpcClient(() {
              callCount++;
              return callCount == 1
                  ? Future.value(_allOperational())
                  : hangingFetch.future;
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Land the first snapshot.
      await container.read(serviceStatusProvider.future);
      expect(callCount, 1);
      expect(
        container.read(githubStatusProvider).value?.indicator,
        GitHubStatusIndicator.none,
      );

      // Refresh: the reload must not blank the served snapshot. The sidebar
      // dot reads the slices' `.value`; a null headline mid-refresh is the
      // green → muted-gray ("black-ish") → green flash on every flyout open.
      // refresh() resolves only when the fetch does, so start it unawaited
      // and observe the mid-flight state while the second fetch hangs.
      unawaited(container.read(serviceStatusProvider.notifier).refresh());
      await Future<void>.delayed(Duration.zero);
      final midRefresh = container.read(serviceStatusProvider);
      expect(callCount, 2);
      expect(midRefresh.isLoading, isTrue);
      expect(
        container.read(githubStatusProvider).value?.indicator,
        GitHubStatusIndicator.none,
      );
      expect(
        container.read(kimiStatusProvider).value?.indicator,
        GitHubStatusIndicator.none,
      );

      hangingFetch.complete(_allOperational());
      await container.read(serviceStatusProvider.future);
      expect(container.read(serviceStatusProvider).isLoading, isFalse);
      expect(
        container.read(githubStatusProvider).value?.indicator,
        GitHubStatusIndicator.none,
      );
    });

    test('a failed refresh still surfaces the error state', () async {
      var callCount = 0;
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(
            _FakeStatusRpcClient(() {
              callCount++;
              return callCount == 1
                  ? Future.value(_allOperational())
                  : Future.error(StateError('fetch failed'));
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(serviceStatusProvider.future);

      await container.read(serviceStatusProvider.notifier).refresh();
      // The rebuild's future rejects; the state lands in the error state so
      // the flyout renders its fetch-failed blocks exactly as before.
      await container.read(serviceStatusProvider.future).catchError(
        (Object _) => const ServiceStatuses(),
      );
      expect(container.read(serviceStatusProvider).hasError, isTrue);
    });

    test('slices stay loading before the first snapshot lands', () async {
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(
            _FakeStatusRpcClient(
              () => Completer<Map<String, dynamic>>().future,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final github = container.read(githubStatusProvider);
      expect(github.isLoading, isTrue);
      expect(github.hasValue, isFalse);
    });
  });
}
