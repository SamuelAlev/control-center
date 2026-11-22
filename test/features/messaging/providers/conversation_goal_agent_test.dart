import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/messaging/providers/conversation_goal_agent.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(String id, String name, {String? reportsTo}) => Agent(
  id: id,
  workspaceId: 'ws',
  name: name,
  title: name,
  agentMdPath: '$id.md',
  skills: AgentSkills(const []),
  reportsTo: reportsTo,
  createdAt: DateTime.utc(2026),
);

Message _from(String sender, SenderType type) => Message(
  id: 'm-$sender',
  spaceId: 'sp',
  conversationId: 'c',
  senderId: sender,
  senderType: type,
  content: 'x',
  messageType: MessageType.text,
  createdAt: DateTime.utc(2026),
);

void main() {
  final roster = [
    _agent('lead', 'Lead'),
    _agent('ada', 'Ada', reportsTo: 'lead'),
    _agent('ben', 'Ben'),
  ];

  String? pick({
    String text = '/goal ship it',
    Set<String> inSpace = const {'lead', 'ada'},
    List<Message> conversation = const [],
    String? ownerId,
  }) => resolveGoalAgentId(
    text: text,
    roster: roster,
    spaceAgentIds: inSpace,
    conversation: conversation,
    ownerId: ownerId,
  );

  test('a mentioned agent wins', () {
    expect(pick(text: '/goal @ben ship it'), 'ben');
  });

  test('else the agent that last spoke here', () {
    expect(
      pick(
        conversation: [
          _from('lead', SenderType.agent),
          _from('ada', SenderType.agent),
          _from('u-1', SenderType.user),
        ],
      ),
      'ada',
    );
  });

  test("else the conversation's owner, else the first top-level agent", () {
    expect(pick(ownerId: 'ada'), 'ada');
    expect(pick(), 'lead');
    expect(pick(inSpace: {'ada'}), 'ada');
  });

  test('no agent in the space: none', () {
    expect(pick(inSpace: const {}), isNull);
  });
}
