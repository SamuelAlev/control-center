import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CommandPolicy.evaluate', () {
    test('deny takes precedence over prompt', () {
      final policy = CommandPolicy(
        deny: ['git push'],
        prompt: ['git push'],
      );
      expect(policy.evaluate('git push'), CommandDecision.deny);
    });

    test('allow takes precedence over deny', () {
      final policy = CommandPolicy(
        deny: ['git push'],
        allow: ['git push'],
      );
      expect(policy.evaluate('git push'), CommandDecision.allow);
    });

    test('default is allow when no rule matches', () {
      const policy = CommandPolicy();
      expect(policy.evaluate('git log'), CommandDecision.allow);
    });

    test('evaluates pipelines — deny in any sub-command denies all', () {
      const policy = CommandPolicy(deny: ['sudo']);
      expect(policy.evaluate('echo hi && sudo rm -rf /'), CommandDecision.deny);
    });

    test('evaluates pipelines — prompt propagates', () {
      const policy = CommandPolicy(prompt: ['npm publish']);
      expect(
        policy.evaluate('npm test && npm publish'),
        CommandDecision.prompt,
      );
    });

    test('nested shell invocation is checked', () {
      const policy = CommandPolicy(deny: ['git push']);
      expect(
        policy.evaluate("bash -c 'git push'"),
        CommandDecision.deny,
      );
    });
  });

  group('commandPolicyForMode', () {
    test('chat denies always-dangerous', () {
      final policy = commandPolicyForMode(ConversationMode.chat);
      expect(policy.evaluate('sudo ls'), CommandDecision.deny);
      expect(policy.evaluate('rm -rf /'), CommandDecision.deny);
    });

    test('chat prompts on push/publish', () {
      final policy = commandPolicyForMode(ConversationMode.chat);
      expect(policy.evaluate('git push'), CommandDecision.prompt);
      expect(policy.evaluate('npm publish'), CommandDecision.prompt);
    });

    test('chat allows read/query commands', () {
      final policy = commandPolicyForMode(ConversationMode.chat);
      expect(policy.evaluate('git log'), CommandDecision.allow);
      expect(policy.evaluate('npm ls'), CommandDecision.allow);
      expect(policy.evaluate('git diff'), CommandDecision.allow);
    });

    test('plan denies git push (not prompt)', () {
      final policy = commandPolicyForMode(ConversationMode.plan);
      expect(policy.evaluate('git push'), CommandDecision.deny);
    });

    test('plan denies npm install', () {
      final policy = commandPolicyForMode(ConversationMode.plan);
      expect(policy.evaluate('npm install'), CommandDecision.deny);
    });

    test('plan allows read-only git commands', () {
      final policy = commandPolicyForMode(ConversationMode.plan);
      expect(policy.evaluate('git log'), CommandDecision.allow);
      expect(policy.evaluate('git show HEAD'), CommandDecision.allow);
    });

    test('review denies mutating commands', () {
      final policy = commandPolicyForMode(ConversationMode.review);
      expect(policy.evaluate('git commit'), CommandDecision.deny);
      expect(policy.evaluate('git add .'), CommandDecision.deny);
    });

    test('orchestrate denies docker', () {
      final policy = commandPolicyForMode(ConversationMode.orchestrate);
      expect(policy.evaluate('docker run alpine'), CommandDecision.deny);
    });

    test('mkfs.* glob match denies', () {
      final policy = commandPolicyForMode(ConversationMode.chat);
      expect(policy.evaluate('mkfs.ext4 /dev/sda'), CommandDecision.deny);
      expect(policy.evaluate('mkfs.xfs /dev/nvme0n1'), CommandDecision.deny);
    });
  });
}
