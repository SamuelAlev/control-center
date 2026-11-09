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

  String label(MessageDto m, {String? agentName}) => spaceMessageSenderLabel(
    m,
    userNames: const {'u1': 'Ada'},
    agentName: agentName,
    l10n: l10n,
  );

  test('a system row is labelled as the system, never as an agent', () {
    expect(label(_row(senderType: 'system', senderId: 'system')), 'System');
  });

  test(
    'a notice an older server wrote as agent from system reads the same',
    () {
      expect(
        label(
          _row(senderType: 'agent', senderId: 'system'),
          agentName: 'Bot',
        ),
        'System',
      );
    },
  );

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
}
