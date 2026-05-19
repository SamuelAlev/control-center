import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_rpc_client.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith(_FakeLocaleNotifier.new),
        rpcClientProvider.overrideWithValue(fakeRpcClient()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('workspaceFilesystemPortProvider resolves', () {
    final container = createContainer();
    final port = container.read(workspaceFilesystemPortProvider);
    expect(port, isNotNull);
  });

  test('adapterRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(adapterRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('agentMentionParserProvider resolves', () {
    final container = createContainer();
    final parser = container.read(agentMentionParserProvider);
    expect(parser, isNotNull);
  });

  // Was `sendSpaceMessageUseCaseProvider resolves`. That use case was a pure
  // delegator to `MessagingPort.sendAndDispatch` and is gone; the composer
  // calls the port directly, so the port's provider is what the composition
  // root now has to be able to build.
  test('messagingServiceProvider resolves', () {
    final container = createContainer();
    expect(container.read(messagingServiceProvider), isNotNull);
  });

  test('processDetectionServiceProvider resolves', () {
    final container = createContainer();
    expect(container.read(processDetectionServiceProvider), isNotNull);
  });

}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => null;
}
