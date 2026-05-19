import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentCapabilities', () {
    test('default constructor matches safeDefault', () {
      const caps = AgentCapabilities();
      expect(caps.canPushToRepo, false);
      expect(caps.canCallGitHubApi, false);
      expect(caps.canCallTicketing, false);
      expect(caps.canAccessNetwork, true);
      expect(caps, AgentCapabilities.safeDefault);
    });

    test('legacyDefault has all true', () {
      expect(AgentCapabilities.legacyDefault.canPushToRepo, true);
      expect(AgentCapabilities.legacyDefault.canCallGitHubApi, true);
      expect(AgentCapabilities.legacyDefault.canCallTicketing, true);
      expect(AgentCapabilities.legacyDefault.canAccessNetwork, true);
    });

    test('safeDefault has conservative values', () {
      expect(AgentCapabilities.safeDefault.canPushToRepo, false);
      expect(AgentCapabilities.safeDefault.canCallGitHubApi, false);
      expect(AgentCapabilities.safeDefault.canCallTicketing, false);
      expect(AgentCapabilities.safeDefault.canAccessNetwork, true);
    });

    group('fromJson', () {
      test('reads all fields', () {
        final caps = AgentCapabilities.fromJson(const {
          'canPushToRepo': true,
          'canCallGitHubApi': true,
          'canCallTicketing': false,
          'canAccessNetwork': false,
        });
        expect(caps.canPushToRepo, true);
        expect(caps.canCallGitHubApi, true);
        expect(caps.canCallTicketing, false);
        expect(caps.canAccessNetwork, false);
      });

      test('missing keys use defaults', () {
        final caps = AgentCapabilities.fromJson(const <String, dynamic>{});
        expect(caps.canPushToRepo, false);
        expect(caps.canCallGitHubApi, false);
        expect(caps.canCallTicketing, false);
        expect(caps.canAccessNetwork, true);
      });

      test('reads legacy canCallLinear key for canCallTicketing', () {
        final caps = AgentCapabilities.fromJson(const {
          'canCallLinear': true,
        });
        expect(caps.canCallTicketing, true);

        // canCallTicketing takes precedence over canCallLinear
        final caps2 = AgentCapabilities.fromJson(const {
          'canCallTicketing': false,
          'canCallLinear': true,
        });
        expect(caps2.canCallTicketing, false);
      });
    });

    group('fromJsonString', () {
      test('parses valid JSON', () {
        const raw = '{"canPushToRepo":true,"canCallGitHubApi":false,'
            '"canCallTicketing":true,"canAccessNetwork":false}';
        final caps = AgentCapabilities.fromJsonString(raw);
        expect(caps.canPushToRepo, true);
        expect(caps.canCallGitHubApi, false);
        expect(caps.canCallTicketing, true);
        expect(caps.canAccessNetwork, false);
      });

      test('empty string returns safeDefault', () {
        final caps = AgentCapabilities.fromJsonString('');
        expect(caps, AgentCapabilities.safeDefault);
      });

      test('malformed JSON returns safeDefault', () {
        final caps = AgentCapabilities.fromJsonString('not json');
        expect(caps, AgentCapabilities.safeDefault);
      });
    });
    group('fromJsonString (edge cases)', () {
      test('JSON array returns safeDefault', () {
        final caps = AgentCapabilities.fromJsonString('[true, false]');
        expect(caps, AgentCapabilities.safeDefault);
      });

      test('JSON with wrong types returns safeDefault', () {
        final caps = AgentCapabilities.fromJsonString(
          '{"canPushToRepo": "yes"}',
        );
        expect(caps, AgentCapabilities.safeDefault);
      });
    });

    group('copyWith', () {
      test('changes only specified fields', () {
        const original = AgentCapabilities();
        final updated = original.copyWith(canPushToRepo: true);
        expect(updated.canPushToRepo, true);
        expect(updated.canCallGitHubApi, false);
        expect(updated.canCallTicketing, false);
        expect(updated.canAccessNetwork, true);
      });

      test('with no args returns equal instance', () {
        const original = AgentCapabilities(
          canPushToRepo: true,
          canAccessNetwork: false,
        );
        final copy = original.copyWith();
        expect(copy, original);
        expect(copy.hashCode, original.hashCode);
      });

      test('multiple fields at once', () {
        const original = AgentCapabilities(
          canPushToRepo: true,
          canCallGitHubApi: true,
        );
        final updated = original.copyWith(
          canPushToRepo: false,
          canCallTicketing: true,
        );
        expect(updated.canPushToRepo, false);
        expect(updated.canCallGitHubApi, true);
        expect(updated.canCallTicketing, true);
        expect(updated.canAccessNetwork, true);
        // original unchanged
        expect(original.canPushToRepo, true);
      });
    });

    test('toJson returns correct map for all-true', () {
      final json = AgentCapabilities.legacyDefault.toJson();
      expect(json['canPushToRepo'], true);
      expect(json['canCallGitHubApi'], true);
      expect(json['canCallTicketing'], true);
      expect(json['canAccessNetwork'], true);
    });

    test('toJson round-trips through fromJson', () {
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: false,
        canCallTicketing: true,
        canAccessNetwork: false,
      );
      final roundTripped = AgentCapabilities.fromJson(caps.toJson());
      expect(roundTripped, caps);
    });

    test('toJsonString round-trips through fromJsonString', () {
      const caps = AgentCapabilities(
        canPushToRepo: false,
        canCallGitHubApi: true,
        canCallTicketing: false,
        canAccessNetwork: true,
      );
      final roundTripped = AgentCapabilities.fromJsonString(caps.toJsonString());
      expect(roundTripped, caps);
    });

    test('equality and hashCode', () {
      const a = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: false,
        canCallTicketing: false,
        canAccessNetwork: true,
      );
      const b = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: false,
        canCallTicketing: false,
        canAccessNetwork: true,
      );
      const c = AgentCapabilities(
        canPushToRepo: false,
        canCallGitHubApi: false,
        canCallTicketing: false,
        canAccessNetwork: true,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.hashCode, isNot(c.hashCode));
    });
  });
}
