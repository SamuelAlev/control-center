import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/model_routing/domain/entities/credential_account.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

/// Fills small value-type coverage gaps: the equality/hashCode/toString of
/// [CredentialAccount]/[AccountBlockState], [MessageCursor] and the
/// [estimateHarnessBlock] content-block cases (text, thinking, image).
void main() {
  group('CredentialAccount', () {
    test('equality + hashCode by (id, providerId)', () {
      const a = CredentialAccount(
        id: 'a1',
        providerId: 'anthropic',
        label: 'Personal',
        email: 'e@x.com',
        isApiKey: true,
        priorityBoost: true,
        order: 5,
      );
      const b = CredentialAccount(id: 'a1', providerId: 'anthropic');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const CredentialAccount(id: 'a1', providerId: 'openai')));
      expect(
        a,
        isNot(const CredentialAccount(id: 'other', providerId: 'anthropic')),
      );
    });

    test('accountKey prefers email then id; toString', () {
      expect(
        const CredentialAccount(
          id: 'i',
          providerId: 'p',
          email: 'e@x.com',
        ).accountKey,
        'e@x.com',
      );
      expect(const CredentialAccount(id: 'i', providerId: 'p').accountKey, 'i');
      expect(
        const CredentialAccount(id: 'i', providerId: 'p').toString(),
        'CredentialAccount(p/i)',
      );
    });
  });

  group('AccountBlockState', () {
    test('isActiveAt + equality + hashCode', () {
      final until = DateTime(2026, 1, 2);
      final a = AccountBlockState(
        accountId: 'a',
        blockedUntil: until,
        scope: 'claude',
      );
      final b = AccountBlockState(
        accountId: 'a',
        blockedUntil: until,
        scope: 'claude',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isActiveAt(DateTime(2026, 1, 1)), isTrue);
      expect(a.isActiveAt(DateTime(2026, 1, 3)), isFalse);
      expect(a, isNot(AccountBlockState(accountId: 'a', blockedUntil: until)));
    });
  });

  group('MessageCursor', () {
    test('equality + hashCode', () {
      const a = MessageCursor(createdAtMs: 100, rowid: 5);
      const b = MessageCursor(createdAtMs: 100, rowid: 5);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const MessageCursor(createdAtMs: 100, rowid: 6)));
    });

    test('decode rejects a JSON list payload', () {
      // A base64url-encoded JSON array decodes to a List, not a Map → null.
      final token = base64Url.encode(utf8.encode('[1,2,3]'));
      expect(MessageCursor.decode(token), isNull);
    });
  });

  group('estimateHarnessBlock / estimateHarnessMessage', () {
    test('estimates text, thinking and image blocks', () {
      const est = TokenEstimator.instance;
      final textTokens = estimateHarnessBlock(
        const HarnessTextBlock('hello world'),
        estimator: est,
      );
      expect(textTokens, est.estimate('hello world'));

      final thinkTokens = estimateHarnessBlock(
        const HarnessThinkingBlock('reasoning here'),
        estimator: est,
      );
      expect(thinkTokens, est.estimate('reasoning here'));

      // Images are a flat ~1200 token allowance regardless of bytes.
      expect(
        estimateHarnessBlock(
          const HarnessImageBlock(data: 'base64==', mediaType: 'image/png'),
        ),
        1200,
      );
    });

    test('estimateHarnessMessage sums blocks + framing', () {
      const msg = HarnessMessage(
        role: HarnessRole.user,
        content: [
          HarnessTextBlock('abc'),
          HarnessToolUseBlock(id: 'tc1', name: 'grep', input: {'q': 'foo'}),
        ],
      );
      const est = TokenEstimator.instance;
      expect(
        estimateHarnessMessage(msg),
        4 +
            est.estimate('abc') +
            est.estimate('grep ${jsonEncode({'q': 'foo'})}'),
      );
    });

    test('estimateHarnessHistory sums a list', () {
      const history = [
        HarnessMessage(
          role: HarnessRole.user,
          content: [HarnessTextBlock('x')],
        ),
        HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessTextBlock('y')],
        ),
      ];
      const est = TokenEstimator.instance;
      expect(
        estimateHarnessHistory(history),
        (4 + est.estimate('x')) + (4 + est.estimate('y')),
      );
    });
  });
}
