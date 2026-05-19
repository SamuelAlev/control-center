import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [localeProvider.overrideWith(_FakeLocaleNotifier.new)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('agentRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(agentRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('workspaceRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(workspaceRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('repoRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(repoRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('messagingRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(messagingRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('workspaceFilesystemPortProvider resolves', () {
    final container = createContainer();
    final port = container.read(workspaceFilesystemPortProvider);
    expect(port, isNotNull);
  });

  test('gitRepoInspectorPortProvider resolves', () {
    final container = createContainer();
    final port = container.read(gitRepoInspectorPortProvider);
    expect(port, isNotNull);
  });
  test('agentDispatchPortProvider resolves', () {
    final container = createContainer();
    final port = container.read(agentDispatchPortProvider);
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
  test('sendChannelMessageUseCaseProvider resolves', () {
    final container = createContainer();
    final useCase = container.read(sendChannelMessageUseCaseProvider);
    expect(useCase, isNotNull);
  });

  test('seedCeoAgentUseCaseProvider resolves', () {
    final container = createContainer();
    final useCase = container.read(seedCeoAgentUseCaseProvider);
    expect(useCase, isNotNull);
  });

  test('agentProcessMatcherProvider resolves', () {
    final container = createContainer();
    final matcher = container.read(agentProcessMatcherProvider);
    expect(matcher, isNotNull);
  });

  test('credentialsRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(credentialsRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('githubCliServiceProvider resolves', () {
    final container = createContainer();
    final service = container.read(githubCliServiceProvider);
    expect(service, isNotNull);
  });

  test('agentRepositoryProvider returns singleton', () {
    final container = createContainer();
    final a = container.read(agentRepositoryProvider);
    final b = container.read(agentRepositoryProvider);
    expect(identical(a, b), isTrue);
  });
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => null;
}
