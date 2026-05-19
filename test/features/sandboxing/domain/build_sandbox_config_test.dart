import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/sandboxing/domain/sandbox_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const agentDir = '/agents/test-agent';

  group('buildSandboxConfig', () {
    test('returns SandboxConfig with sessionId', () {
      final config = buildSandboxConfig(
        sessionId: 'session-1',
        capabilities: const AgentCapabilities(),
        agentDir: agentDir,
        mode: ConversationMode.chat,
      );
      expect(config.sessionId, 'session-1');
    });

    group('network domains', () {
      test('includes baseline domains when canAccessNetwork is true', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(canAccessNetwork: true),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(config.network.allowedDomains, contains('anthropic.com'));
        expect(config.network.allowedDomains, contains('pypi.org'));
      });

      test('excludes baseline domains when canAccessNetwork is false', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(canAccessNetwork: false),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(config.network.allowedDomains, isNot(contains('anthropic.com')));
      });

      test('includes GitHub domains when canCallGitHubApi is true', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canCallGitHubApi: true,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(config.network.allowedDomains, contains('github.com'));
        expect(
          config.network.allowedDomains,
          contains('api.github.com'),
        );
      });

      test('includes GitHub domains when canPushToRepo is true', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canPushToRepo: true,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(config.network.allowedDomains, contains('github.com'));
      });

      test('excludes GitHub domains when neither flag is set', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canCallGitHubApi: false,
            canPushToRepo: false,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(
          config.network.allowedDomains,
          isNot(contains('github.com')),
        );
      });

      test('includes ticketing domains when canCallTicketing is true', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canCallTicketing: true,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
          ticketingDomains: const ['linear.app', 'linear-api.com'],
        );
        expect(config.network.allowedDomains, contains('linear.app'));
        expect(
          config.network.allowedDomains,
          contains('linear-api.com'),
        );
      });

      test('excludes ticketing domains when canCallTicketing is false', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canCallTicketing: false,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
          ticketingDomains: const ['linear.app'],
        );
        expect(
          config.network.allowedDomains,
          isNot(contains('linear.app')),
        );
      });

      test('deduplicates domains', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(
            canAccessNetwork: true,
            canCallGitHubApi: true,
          ),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        // Baseline + GitHub domains, but called once with toSet()
        final domainCount = config.network.allowedDomains.length;
        final uniqueCount = config.network.allowedDomains.toSet().length;
        expect(domainCount, uniqueCount);
      });
    });

    group('filesystem denyRead', () {
      test('denies sensitive dirs when homeDir is provided', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.chat,
          homeDir: '/home/user',
        );
        expect(config.filesystem.denyRead, contains('/home/user/.ssh'));
        expect(config.filesystem.denyRead, contains('/home/user/.aws'));
        expect(config.filesystem.denyRead, contains('/home/user/.gnupg'));
        expect(
          config.filesystem.denyRead,
          contains('/home/user/.config/gh'),
        );
        expect(
          config.filesystem.denyRead,
          contains('/home/user/Library/Keychains'),
        );
      });

      test('no denyRead when homeDir is null', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.chat,
          homeDir: null,
        );
        expect(config.filesystem.denyRead, isEmpty);
      });

      test('no denyRead when homeDir is empty', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.chat,
          homeDir: '',
        );
        expect(config.filesystem.denyRead, isEmpty);
      });
    });

    group('filesystem allowWrite by mode', () {
      test('chat mode allows agentDir and /tmp writes', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.chat,
        );
        expect(config.filesystem.allowWrite, contains(agentDir));
        expect(config.filesystem.allowWrite, contains('/tmp'));
      });

      test('review mode disallows all writes', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.review,
        );
        expect(config.filesystem.allowWrite, isEmpty);
      });

      test('plan mode allows agentDir/plans and /tmp writes', () {
        final config = buildSandboxConfig(
          sessionId: 'session-1',
          capabilities: const AgentCapabilities(),
          agentDir: agentDir,
          mode: ConversationMode.plan,
        );
        expect(
          config.filesystem.allowWrite,
          contains('$agentDir/plans'),
        );
        expect(config.filesystem.allowWrite, contains('/tmp'));
      });
    });
  });
}
