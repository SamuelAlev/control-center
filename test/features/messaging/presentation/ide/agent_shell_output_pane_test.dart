import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_shell_output.dart';
import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_shell_output_pane.dart';
import 'package:control_center/features/sandboxing/providers/agent_shell_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _OutputPort implements AgentShellProcessPort {
  final reads = <(String, String, String)>[];
  final pending = <Completer<AgentShellOutput>>[];
  int kills = 0;

  @override
  Future<List<AgentShellProcess>> list({
    required String workspaceId,
    required String spaceId,
  }) async => const [];

  @override
  Future<AgentShellOutput> readOutput({
    required String workspaceId,
    required String spaceId,
    required String outputId,
  }) {
    reads.add((workspaceId, spaceId, outputId));
    final call = Completer<AgentShellOutput>();
    pending.add(call);
    return call.future;
  }

  @override
  Future<bool> kill({
    required String workspaceId,
    required String spaceId,
    required int pid,
  }) async {
    kills++;
    return true;
  }
}

void main() {
  Future<void> pumpPane(WidgetTester tester, _OutputPort port) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [agentShellProcessPortProvider.overrideWithValue(port)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SizedBox(
                height: 280,
                child: AgentShellOutputPane(
                  workspaceId: 'ws-1',
                  spaceId: 's-1',
                  outputId: 'out-1',
                  command: 'echo ready',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('reads a scoped output only while mounted, once at a time', (
    tester,
  ) async {
    final port = _OutputPort();
    await pumpPane(tester, port);
    expect(port.reads, [('ws-1', 's-1', 'out-1')]);
    expect(find.byType(CcSpinner), findsOneWidget);
    port.pending[0].complete(
      const AgentShellOutput(
        output: 'first',
        state: AgentShellOutputState.running,
      ),
    );
    await tester.pump();
    expect(find.text('first'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(port.reads.length, 2);
    await tester.pump(const Duration(seconds: 12));
    expect(port.reads.length, 2, reason: 'in-flight reads never overlap');
    await tester.pumpWidget(const SizedBox.shrink());
    port.pending[1].complete(
      const AgentShellOutput(
        output: 'after close',
        state: AgentShellOutputState.running,
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(port.reads.length, 2, reason: 'closing cancels the next poll');
    expect(port.kills, 0);
  });

  testWidgets('retains output on error, retries, and stops after exit', (
    tester,
  ) async {
    final port = _OutputPort();
    await pumpPane(tester, port);
    port.pending[0].complete(
      const AgentShellOutput(
        output: 'known tail',
        state: AgentShellOutputState.running,
        truncated: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    port.pending[1].completeError(StateError('link lost'));
    await tester.pump();
    expect(find.text('known tail'), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    expect(port.reads.length, 2);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(port.reads.length, 3);
    port.pending[2].complete(
      const AgentShellOutput(
        output: 'final tail',
        state: AgentShellOutputState.exited,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('final tail'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(port.reads.length, 3, reason: 'an exited stream is final');
    expect(port.kills, 0);
  });

  testWidgets('manual scrolling pauses follow until jump to latest', (
    tester,
  ) async {
    final port = _OutputPort();
    await pumpPane(tester, port);
    final longOutput = List.generate(120, (i) => 'line $i').join('\n');
    port.pending[0].complete(
      AgentShellOutput(
        output: longOutput,
        state: AgentShellOutputState.running,
      ),
    );
    await tester.pump();
    await tester.pump();
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(scroll.offset, scroll.position.maxScrollExtent);
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    port.pending[1].complete(
      AgentShellOutput(
        output: '$longOutput\nnew output',
        state: AgentShellOutputState.running,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, 0);
    await tester.tap(find.text('Jump to latest'));
    await tester.pump();
    expect(scroll.offset, scroll.position.maxScrollExtent);
  });
}
