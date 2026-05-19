import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentSkills', () {
    group('constructor', () {
      test('creates instance with empty list', () {
        final skills = AgentSkills([]);
        expect(skills.isEmpty, isTrue);
        expect(skills.isNotEmpty, isFalse);
        expect(skills.toList(), isEmpty);
      });

      test('creates instance with single skill', () {
        final skills = AgentSkills(['coding']);
        expect(skills.isEmpty, isFalse);
        expect(skills.isNotEmpty, isTrue);
        expect(skills.toList(), ['coding']);
      });

      test('creates instance with multiple skills', () {
        final skills = AgentSkills(['coding', 'reviewing', 'testing']);
        expect(skills.toList(), ['coding', 'reviewing', 'testing']);
        expect(skills.isEmpty, isFalse);
        expect(skills.isNotEmpty, isTrue);
      });

      test('creates instance with duplicate skills', () {
        final skills = AgentSkills(['coding', 'coding']);
        expect(skills.toList(), ['coding', 'coding']);
      });
    });

    group('toList', () {
      test('returns unmodifiable list', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        final list = skills.toList();
        expect(list, ['coding', 'reviewing']);
        expect(() => list.add('testing'), throwsUnsupportedError);
      });

      test('returns a copy, not the internal list', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        final list1 = skills.toList();
        final list2 = skills.toList();
        expect(identical(list1, list2), isFalse);
      });
    });

    group('hasSkill', () {
      test('returns true for existing skill exact case', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        expect(skills.hasSkill('coding'), isTrue);
        expect(skills.hasSkill('reviewing'), isTrue);
      });

      test('returns true for existing skill different case', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        expect(skills.hasSkill('CODING'), isTrue);
        expect(skills.hasSkill('Coding'), isTrue);
        expect(skills.hasSkill('Reviewing'), isTrue);
      });

      test('returns false for non-existing skill', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        expect(skills.hasSkill('testing'), isFalse);
        expect(skills.hasSkill('debugging'), isFalse);
      });

      test('returns false for empty string', () {
        final skills = AgentSkills(['coding']);
        expect(skills.hasSkill(''), isFalse);
      });

      test('returns false for empty skills list', () {
        final skills = AgentSkills([]);
        expect(skills.hasSkill('coding'), isFalse);
      });

      test('case-insensitive with mixed case skills', () {
        final skills = AgentSkills(['CodeReview', 'UnitTest']);
        expect(skills.hasSkill('codereview'), isTrue);
        expect(skills.hasSkill('unittest'), isTrue);
        expect(skills.hasSkill('CodeReview'), isTrue);
        expect(skills.hasSkill('UNITTEST'), isTrue);
      });
    });

    group('isEmpty / isNotEmpty', () {
      test('isEmpty is true when list is empty', () {
        expect(AgentSkills([]).isEmpty, isTrue);
      });

      test('isEmpty is false when list has items', () {
        expect(AgentSkills(['coding']).isEmpty, isFalse);
      });

      test('isNotEmpty is false when list is empty', () {
        expect(AgentSkills([]).isNotEmpty, isFalse);
      });

      test('isNotEmpty is true when list has items', () {
        expect(AgentSkills(['coding']).isNotEmpty, isTrue);
      });
    });

    group('join', () {
      test('joins with separator', () {
        final skills = AgentSkills(['coding', 'reviewing', 'testing']);
        expect(skills.join(', '), 'coding, reviewing, testing');
      });

      test('join on empty list returns empty string', () {
        final skills = AgentSkills([]);
        expect(skills.join(', '), '');
      });

      test('join on single item returns item without separator', () {
        final skills = AgentSkills(['coding']);
        expect(skills.join(', '), 'coding');
      });

      test('join with custom separator', () {
        final skills = AgentSkills(['a', 'b', 'c']);
        expect(skills.join('|'), 'a|b|c');
      });
    });

    group('where', () {
      test('filters skills by predicate', () {
        final skills = AgentSkills(['coding', 'review', 'testing']);
        final result = skills.where((s) => s.contains('ing'));
        expect(result, ['coding', 'testing']);
      });

      test('returns empty list when no matches', () {
        final skills = AgentSkills(['coding', 'review']);
        final result = skills.where((s) => s.contains('z'));
        expect(result, isEmpty);
      });

      test('returns all skills when predicate always true', () {
        final skills = AgentSkills(['coding', 'review']);
        final result = skills.where((s) => true);
        expect(result, ['coding', 'review']);
      });
    });

    group('take', () {
      test('takes first n items', () {
        final skills = AgentSkills(['a', 'b', 'c', 'd']);
        expect(skills.take(2), ['a', 'b']);
      });

      test('take 0 returns empty list', () {
        final skills = AgentSkills(['a', 'b']);
        expect(skills.take(0), isEmpty);
      });

      test('take more than available returns all items', () {
        final skills = AgentSkills(['a', 'b']);
        expect(skills.take(10), ['a', 'b']);
      });
    });

    group('== and hashCode', () {
      test('== returns true for same skills', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['coding', 'reviewing']);
        expect(s1, equals(s2));
      });

      test('== returns true for same skills in different order', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['reviewing', 'coding']);
        expect(s1, equals(s2));
      });

      test('== returns true for same skills different case', () {
        final s1 = AgentSkills(['CODING', 'reviewing']);
        final s2 = AgentSkills(['coding', 'REVIEWING']);
        expect(s1, equals(s2));
      });

      test('== returns false for different skills', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['testing', 'debugging']);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different count', () {
        final s1 = AgentSkills(['coding']);
        final s2 = AgentSkills(['coding', 'reviewing']);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for partially overlapping skills', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['coding', 'testing']);
        expect(s1, isNot(equals(s2)));
      });

      test('== (identical)', () {
        final s = AgentSkills(['coding']);
        expect(s, equals(s));
      });

      test('hashCode equal for equal skill sets', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['coding', 'reviewing']);
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('hashCode differs for different order (order-dependent implementation)', () {
        final s1 = AgentSkills(['coding', 'reviewing']);
        final s2 = AgentSkills(['reviewing', 'coding']);
        expect(s1, equals(s2));
        expect(s1.hashCode, isNot(equals(s2.hashCode)));
      });

      test('hashCode equal for different case', () {
        final s1 = AgentSkills(['CODING', 'reviewing']);
        final s2 = AgentSkills(['coding', 'REVIEWING']);
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('hashCode differs for different skills', () {
        final s1 = AgentSkills(['coding']);
        final s2 = AgentSkills(['reviewing']);
        expect(s1.hashCode, isNot(equals(s2.hashCode)));
      });
    });

    group('toString', () {
      test('returns formatted string for multiple skills', () {
        final skills = AgentSkills(['coding', 'reviewing']);
        expect(skills.toString(), 'AgentSkills(coding, reviewing)');
      });

      test('returns formatted string for single skill', () {
        final skills = AgentSkills(['coding']);
        expect(skills.toString(), 'AgentSkills(coding)');
      });

      test('returns formatted string for empty skills', () {
        final skills = AgentSkills([]);
        expect(skills.toString(), 'AgentSkills()');
      });
    });

    test('can be used as map key with identical order', () {
      final s1 = AgentSkills(['coding', 'reviewing']);
      final map = {s1: 'value'};
      final s2 = AgentSkills(['coding', 'reviewing']);
      expect(map[s2], 'value');
    });

    test('const constructor', () {
      final skills = AgentSkills(['coding']);
      expect(skills.hasSkill('coding'), isTrue);
    });
  });
}
