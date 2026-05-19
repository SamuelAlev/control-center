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

  // The public agent/repo repository providers are RPC-flipped (composition
  // flip): reading them builds the in-process RPC host. The meaningful
  // "the DI graph constructs the repository" check is now against the
  // server-side Dao providers (lazy — they do not open the database).
  test('daoAgentRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(daoAgentRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('daoWorkspaceRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(daoWorkspaceRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('daoRepoRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(daoRepoRepositoryProvider);
    expect(repo, isNotNull);
  });

  test('daoMessagingRepositoryProvider resolves', () {
    final container = createContainer();
    final repo = container.read(daoMessagingRepositoryProvider);
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

  test('daoAgentRepositoryProvider returns singleton', () {
    final container = createContainer();
    final a = container.read(daoAgentRepositoryProvider);
    final b = container.read(daoAgentRepositoryProvider);
    expect(identical(a, b), isTrue);
  });
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => null;
}
