import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:test/test.dart';

/// The descriptor is the whole reason adding a provider is a server-only change:
/// it is simultaneously the UI's field list, the wire contract, and the single
/// validation chokepoint for a connect attempt. These tests pin the third role,
/// because that is the one a caller can get wrong silently.
void main() {
  const descriptor = ChatProviderDescriptor(
    provider: ChatProvider.slack,
    credentialFields: [
      ChatCredentialField(
        id: 'botToken',
        label: 'Bot token',
        expectedPrefix: 'xoxb-',
        prefixError: 'A bot token starts with `xoxb-`.',
      ),
      ChatCredentialField(id: 'appToken', label: 'App token'),
      ChatCredentialField(
        id: 'configRefreshToken',
        label: 'Config token',
        required: false,
      ),
    ],
    managementCredentialField: 'configRefreshToken',
    commandName: 'cc',
  );

  group('validate', () {
    test('trims and keeps every declared field that was given', () {
      final clean = descriptor.validate({
        'botToken': '  xoxb-1  ',
        'appToken': 'xapp-1',
        'configRefreshToken': 'xoxe-1',
      });

      expect(clean, {
        'botToken': 'xoxb-1',
        'appToken': 'xapp-1',
        'configRefreshToken': 'xoxe-1',
      });
    });

    test('drops a field the provider never declared', () {
      final clean = descriptor.validate({
        'botToken': 'xoxb-1',
        'appToken': 'xapp-1',
        'somebodyElsesSecret': 'nope',
      });

      // A client cannot smuggle an extra secret into the credentials file by
      // inventing a key, which matters because that file is what the adapter
      // authenticates with.
      expect(clean.keys, isNot(contains('somebodyElsesSecret')));
    });

    test('an omitted optional field is absent, not empty', () {
      final clean = descriptor.validate({
        'botToken': 'xoxb-1',
        'appToken': 'xapp-1',
      });

      // Storing '' would read as "the app is manageable" to anything that only
      // checks for the key's presence.
      expect(clean.containsKey('configRefreshToken'), isFalse);
    });

    test('a blank optional field is treated as omitted', () {
      final clean = descriptor.validate({
        'botToken': 'xoxb-1',
        'appToken': 'xapp-1',
        'configRefreshToken': '   ',
      });

      expect(clean.containsKey('configRefreshToken'), isFalse);
    });

    test('a missing required field names the box', () {
      expect(
        () => descriptor.validate({'botToken': 'xoxb-1'}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('App token'),
          ),
        ),
      );
    });

    test('a malformed value reports the provider’s own sentence', () {
      expect(
        () => descriptor.validate({'botToken': 'oops', 'appToken': 'xapp-1'}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            // The rule lives on the descriptor, so the client pre-check and the
            // server refusal say the same thing rather than diverging.
            'A bot token starts with `xoxb-`.',
          ),
        ),
      );
    });

    test('a field with no prefix rule accepts anything non-empty', () {
      expect(
        descriptor.validate({'botToken': 'xoxb-1', 'appToken': 'whatever'}),
        containsPair('appToken', 'whatever'),
      );
    });
  });

  group('shape', () {
    test('names the field that manages the provider-side app', () {
      // The guided-setup dialog collects exactly this box, without knowing which
      // provider it is rendering.
      expect(descriptor.managementField?.id, 'configRefreshToken');
      expect(descriptor.managementField?.required, isFalse);
    });

    test('has no management field when the provider declares none', () {
      const bare = ChatProviderDescriptor(
        provider: ChatProvider.slack,
        credentialFields: [
          ChatCredentialField(id: 'botToken', label: 'Bot token'),
        ],
      );

      expect(bare.managementField, isNull);
    });

    test('spells the link command the provider’s way', () {
      expect(descriptor.linkCommand('AB12CD'), '/cc link AB12CD');
    });

    test('a provider offers no setup path it has not declared', () {
      // Every setup affordance defaults off, so a newly-added provider renders a
      // connect form and nothing else rather than a button that dead-ends.
      expect(descriptor.supportsSetupLink, isFalse);
      expect(descriptor.supportsGuidedSetup, isFalse);
      expect(descriptor.supportsBotCustomization, isFalse);
    });

    test('round-trips through the wire, rules included', () {
      final wire = ChatProviderDescriptor.fromJson(
        const ChatProviderDescriptor(
          provider: ChatProvider.slack,
          credentialFields: [
            ChatCredentialField(id: 'botToken', label: 'Bot token'),
          ],
          supportsSetupLink: true,
        ).toJson(),
      );

      // The client decides whether to show "create it in Slack for me" from this
      // flag alone, so losing it on the wire silently removes the option.
      expect(wire.supportsSetupLink, isTrue);
    });

    test('round-trips the fields and their rules', () {
      final wire = ChatProviderDescriptor.fromJson(descriptor.toJson());

      expect(wire.provider, ChatProvider.slack);
      expect(wire.displayName, 'Slack');
      expect(wire.managementCredentialField, 'configRefreshToken');
      expect(wire.credentialFields.map((f) => f.id), [
        'botToken',
        'appToken',
        'configRefreshToken',
      ]);
      // The prefix rule has to survive the trip or the client cannot pre-check a
      // paste with the same sentence the server will use.
      expect(
        () => wire.validate({'botToken': 'oops', 'appToken': 'x'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
