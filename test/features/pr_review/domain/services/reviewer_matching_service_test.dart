import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/pr_review/domain/services/reviewer_matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _makeAgent({
  required String id,
  required String name,
  required String title,
  List<String> skills = const [],
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/agents/$id.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(skills),
    createdAt: DateTime(2025),
  );
}

void main() {
  group('ReviewerMatchingService', () {
    const service = ReviewerMatchingService();

    test('returns null for empty candidates', timeout: const Timeout.factor(2), () {
      final result = service.findBestMatch([], 'security');
      expect(result, isNull);
    });

    test('returns null when no candidate matches', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Designer', title: 'UI Designer'),
      ];
      final result = service.findBestMatch(candidates, 'security');
      expect(result, isNull);
    });

    test('matches agent by skill (highest weight)', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Coder', title: 'Code Reviewer'),
        _makeAgent(id: 'a2', name: 'SecExpert', title: 'Engineer', skills: ['security-review']),
      ];
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a2');
    });

    test('matches agent by title (weight 2)', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Alice', title: 'Security Auditor'),
        _makeAgent(id: 'a2', name: 'Bob', title: 'Backend Engineer'),
      ];
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a1');
    });

    test('matches agent by name (weight 1)', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'security-bot', title: 'Generic Agent'),
        _makeAgent(id: 'a2', name: 'Other', title: 'Other Agent'),
      ];
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a1');
    });

    test('skill match beats title match', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Agent1', title: 'Security Expert'),
        _makeAgent(id: 'a2', name: 'Agent2', title: 'General', skills: ['security']),
      ];
      // skill = 3 points, title = 2 points
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a2');
    });

    test('title match beats name match', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'security-bot', title: 'General Agent'),
        _makeAgent(id: 'a2', name: 'Other', title: 'Security Specialist'),
      ];
      // title = 2 points, name = 1 point
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a2');
    });

    test('matching is case-insensitive', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Bot', title: 'Senior Flutter Engineer', skills: ['Flutter']),
      ];
      final result = service.findBestMatch(candidates, 'FLUTTER')!;
      expect(result.id, 'a1');
    });

    test('role matching is case-insensitive on input', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Bot', title: 'security reviewer'),
      ];
      final result = service.findBestMatch(candidates, 'SECURITY')!;
      expect(result.id, 'a1');
    });

    test('returns highest scoring agent among multiple', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'dev', title: 'Developer', skills: ['backend']),
        _makeAgent(id: 'a2', name: 'sec', title: 'Security', skills: ['security', 'security-audit']),
        _makeAgent(id: 'a3', name: 'sec2', title: 'Security Junior'),
      ];
      // a2: skill(security) = 3, skill(security-audit) = 3, title = 2, name = 1 → total 9
      // a3: title = 2, name(security) contains "sec" but role is "security", let's see...
      // Actually name="sec2" doesn't contain "security" but "sec" — but role is "security" which contains "sec" too
      // Wait — needle is "security" and name is "sec2" which does NOT contain "security" (needle)
      // a3: title "Security Junior" contains "security" = 2 points
      // a2: skill match x2 + title + name(security contains "sec" which is part of "security" but we check if agent.name.contains(needle="security"))
      // agent.name="sec" — does "sec" contain "security"? No.
      // So a2: skill x2 = 6 + title = 2 = 8
      // a3: title = 2
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a2');
    });

    test('accumulates multiple skill matches', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'X', title: 'Generic', skills: ['flutter-ui', 'flutter-state']),
        _makeAgent(id: 'a2', name: 'Y', title: 'Flutter Developer'),
      ];
      // a1: skill(flutter-ui) contains "flutter" = 3, skill(flutter-state) contains "flutter" = 3 → total 6
      // a2: title contains "flutter" = 2
      final result = service.findBestMatch(candidates, 'flutter')!;
      expect(result.id, 'a1');
    });

    test('returns first agent when scores are equal', timeout: const Timeout.factor(2), () {
      final candidates = [
        _makeAgent(id: 'a1', name: 'Bot1', title: 'Security Expert'),
        _makeAgent(id: 'a2', name: 'Bot2', title: 'Security Specialist'),
      ];
      // Both score 2 on title, neither has name or skill match
      final result = service.findBestMatch(candidates, 'security')!;
      expect(result.id, 'a1');
    });
  });
}
