import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/tab_close_guard.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

class _Host implements TabCloseHost {
  _Host(this.context, this.ref);

  @override
  final BuildContext context;

  @override
  final WidgetRef ref;

  @override
  bool mounted = true;

  final kept = <EditorTab>[];

  @override
  String? get closeGuardWorkspaceId => 'ws';

  @override
  String? get closeGuardSpaceId => 'space';

  @override
  String? get closeGuardStandingConversationId => null;

  @override
  bool isTabDirty(EditorTab tab) => false;

  @override
  TerminalSessionController? terminalFor(EditorTab tab) => null;

  @override
  void keepShell(EditorTab tab) => kept.add(tab);

  @override
  String terminalLabel(EditorTab tab, AppLocalizations l10n) => tab.label;

  @override
  String chatLabel(EditorTab tab, AppLocalizations l10n) => tab.label;
}

void main() {
  Future<_Host> pumpHost(WidgetTester tester) async {
    late _Host host;
    await tester.pumpWidget(
      testWrap(
        Consumer(
          builder: (context, ref, _) {
            host = _Host(context, ref);
            return const SizedBox();
          },
        ),
      ),
    );
    return host;
  }

  testWidgets('a tab with no live work and no unsaved file closes at once', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    final guard = TabCloseGuard(host);

    expect(
      await guard.confirmClose(
        const EditorTab(kind: MessagingTabKinds.browser, label: 'Docs'),
      ),
      isTrue,
    );
    // An idle shell (no attached controller) closes without a prompt and is
    // not kept.
    expect(
      await guard.confirmClose(
        const EditorTab(kind: MessagingTabKinds.terminal, label: 'zsh'),
      ),
      isTrue,
    );
    expect(host.kept, isEmpty);
  });

  testWidgets('an IDE that unmounted while asking closes nothing', (
    tester,
  ) async {
    final host = await pumpHost(tester)
      ..mounted = false;

    expect(
      await TabCloseGuard(host).confirmClose(
        const EditorTab(kind: MessagingTabKinds.browser, label: 'Docs'),
      ),
      isFalse,
    );
  });
}
