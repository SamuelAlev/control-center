import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentRole', () {
    test('all values have correct labels', () {
      expect(AgentRole.ceo.label, 'CEO');
      expect(AgentRole.coder.label, 'Coder');
      expect(AgentRole.reviewer.label, 'Reviewer');
      expect(AgentRole.qa.label, 'QA');
      expect(AgentRole.designer.label, 'Designer');
      expect(AgentRole.security.label, 'Security');
      expect(AgentRole.devops.label, 'DevOps');
      expect(AgentRole.pm.label, 'PM');
      expect(AgentRole.general.label, 'General');
    });

    test('all values have non-empty descriptions', () {
      for (final role in AgentRole.values) {
        expect(role.description, isNotEmpty, reason: role.name);
      }
    });

    test('tryParse with exact name returns correct value', () {
      expect(AgentRole.tryParse('ceo'), AgentRole.ceo);
      expect(AgentRole.tryParse('coder'), AgentRole.coder);
      expect(AgentRole.tryParse('reviewer'), AgentRole.reviewer);
      expect(AgentRole.tryParse('qa'), AgentRole.qa);
      expect(AgentRole.tryParse('designer'), AgentRole.designer);
      expect(AgentRole.tryParse('security'), AgentRole.security);
      expect(AgentRole.tryParse('devops'), AgentRole.devops);
      expect(AgentRole.tryParse('pm'), AgentRole.pm);
      expect(AgentRole.tryParse('general'), AgentRole.general);
    });

    test('tryParse is case-insensitive', () {
      expect(AgentRole.tryParse('CEO'), AgentRole.ceo);
      expect(AgentRole.tryParse('CODER'), AgentRole.coder);
      expect(AgentRole.tryParse('Reviewer'), AgentRole.reviewer);
      expect(AgentRole.tryParse('Qa'), AgentRole.qa);
      expect(AgentRole.tryParse('DESIGNER'), AgentRole.designer);
      expect(AgentRole.tryParse('Security'), AgentRole.security);
      expect(AgentRole.tryParse('DEVOPS'), AgentRole.devops);
      expect(AgentRole.tryParse('Pm'), AgentRole.pm);
      expect(AgentRole.tryParse('GENERAL'), AgentRole.general);
    });

    test('tryParse returns null for null', () {
      expect(AgentRole.tryParse(null), isNull);
    });

    test('tryParse returns null for unrecognized string', () {
      expect(AgentRole.tryParse('unknown'), isNull);
      expect(AgentRole.tryParse(''), isNull);
      expect(AgentRole.tryParse('CEO '), isNull);
    });

    test('all values are distinct', () {
      expect(AgentRole.values.toSet().length, AgentRole.values.length);
    });
  });
}
