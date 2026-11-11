import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_access_gate.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

const _workspace = 'ws-1';
const _space = 'space-1';
const _content = 'the space itself';

Space _listed(String id) => Space(
  id: id,
  workspaceId: _workspace,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Answers the one probe the gate makes for a space the list lacks.
class _Conversations extends Fake implements ConversationRepository {
  _Conversations(this.refusal);

  final Object? refusal;
  int probes = 0;

  @override
  Stream<List<Conversation>> watchForSpace({
    required String workspaceId,
    required String spaceId,
  }) {
    probes++;
    final refusal = this.refusal;
    return refusal == null
        ? Stream.value(const <Conversation>[])
        : Stream.error(refusal);
  }
}

Future<_Conversations> _pump(
  WidgetTester tester, {
  required List<Space> listed,
  Object? refusal,
  TextDirection? textDirection,
}) async {
  final conversations = _Conversations(refusal);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceSpacesProvider(
          _workspace,
        ).overrideWith((ref) => Stream.value(listed)),
        conversationRepositoryProvider.overrideWithValue(conversations),
      ],
      child: testWrap(
        const SpaceAccessGate(
          workspaceId: _workspace,
          spaceId: _space,
          child: Text(_content),
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return conversations;
}

/// A space id held from elsewhere (a link, a notification, the last space
/// opened) that the person's list lacks is asked once and, when refused,
/// says why in place of the space, never a spinner or the raw error.
void main() {
  testWidgets('a listed space opens without asking', (tester) async {
    final conversations = await _pump(tester, listed: [_listed(_space)]);
    expect(find.text(_content), findsOneWidget);
    expect(conversations.probes, 0);
  });

  testWidgets('a forge refusal names the forge, never the server sentence', (
    tester,
  ) async {
    await _pump(
      tester,
      listed: const [],
      refusal: RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'forge refused the read',
        {'kind': 'forge_cannot_read', 'forge': 'github'},
      ),
    );
    expect(find.text(_content), findsNothing);
    expect(
      find.text("Your GitHub account can't read a repository this space uses."),
      findsOneWidget,
    );
    expect(find.textContaining('forge refused'), findsNothing);
  });

  testWidgets('a missing read grant says who can grant it', (tester) async {
    await _pump(
      tester,
      listed: const [],
      refusal: RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'No read access to this repo',
        {'kind': 'repo_grant_required', 'level': 'read'},
      ),
      textDirection: TextDirection.rtl,
    );
    expect(
      find.text(
        "You don't have read access to a repository this space uses. A "
        'workspace admin can grant it.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('No read access'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an uncoded refusal gets the generic copy, not the grant one', (
    tester,
  ) async {
    await _pump(
      tester,
      listed: const [],
      refusal: RemoteRpcException(RpcErrorCodes.unauthorized, 'nope'),
    );
    expect(find.text("This space couldn't be opened."), findsOneWidget);
    expect(find.textContaining('read access'), findsNothing);
    expect(find.text('nope'), findsNothing);
  });

  testWidgets('an unlisted space that opens after all shows the space', (
    tester,
  ) async {
    final conversations = await _pump(tester, listed: const []);
    expect(find.text(_content), findsOneWidget);
    expect(conversations.probes, 1);
  });
}
