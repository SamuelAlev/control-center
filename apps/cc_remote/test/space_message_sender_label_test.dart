import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/messaging/space_message_sender.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

MessageDto _row({required String senderType, required String senderId}) =>
    MessageDto(
      id: 'm',
      content: 'hello',
      senderId: senderId,
      senderType: senderType,
      messageType: 'text',
    );

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  final users = {
    'u1': UserDto(id: 'u1', handle: 'ada', displayName: 'Ada'),
    'u3': UserDto(id: 'u3', handle: 'grace', displayName: ''),
  };

  String label(MessageDto m, {String? agentName}) => spaceMessageSenderLabel(
    m,
    users: users,
    agentName: agentName,
    l10n: l10n,
  );

  test('a system row is labelled as the system, never as an agent', () {
    expect(label(_row(senderType: 'system', senderId: 'system')), 'System');
  });

  test('teammates and agents keep their own names', () {
    expect(label(_row(senderType: 'user', senderId: 'u1')), 'Ada');
    expect(label(_row(senderType: 'user', senderId: 'u2')), l10n.teammate);
    expect(
      label(
        _row(senderType: 'agent', senderId: 'a1'),
        agentName: 'Reviewer',
      ),
      'Reviewer',
    );
  });

  test('a teammate is told apart by username', () {
    // Named by display name, the username rides beside it.
    final ada = _row(senderType: 'user', senderId: 'u1');
    expect(spaceMessageSenderHandle(ada, users: users), 'ada');
    // Without a display name the username IS the label, not repeated.
    final grace = _row(senderType: 'user', senderId: 'u3');
    expect(label(grace), '@grace');
    expect(spaceMessageSenderHandle(grace, users: users), isNull);
    // Agents and unknown people carry none.
    expect(
      spaceMessageSenderHandle(
        _row(senderType: 'agent', senderId: 'a1'),
        users: users,
      ),
      isNull,
    );
    expect(
      spaceMessageSenderHandle(
        _row(senderType: 'user', senderId: 'u2'),
        users: users,
      ),
      isNull,
    );
  });
}
