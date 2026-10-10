import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/terminals_section.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/providers/agent_shell_providers.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _RecordingPort implements AgentShellProcessPort {
  final killed = <(String, String, int)>[];

  @override
  Future<List<AgentShellProcess>> list({
    required String workspaceId,
    required String spaceId,
  }) async => const [];

  @override
  Future<bool> kill({
    required String workspaceId,
    required String spaceId,
    required int pid,
  }) async {
    killed.add((workspaceId, spaceId, pid));
    return true;
  }
}

class _Terminals extends SpaceTerminalsNotifier {
  _Terminals(super.spaceId, this.initial);

  final List<TerminalMirror> initial;

  @override
  List<TerminalMirror> build() => initial;
}

AgentShellProcess _command(int pid, String command) => AgentShellProcess(
  pid: pid,
  workspaceId: 'ws-1',
  spaceId: 's-1',
  agentId: 'engineer',
  command: command,
  startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
  origin: AgentShellOrigin.cli,
);

void main() {
  const key = (workspaceId: 'ws-1', spaceId: 's-1');

  Future<({List<String> focused, List<String> killed, _RecordingPort port})>
  pump(
    WidgetTester tester, {
    List<TerminalMirror> terminals = const [],
    List<AgentShellProcess> commands = const [],
  }) async {
    final focused = <String>[];
    final killed = <String>[];
    final port = _RecordingPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spaceTerminalsProvider.overrideWith2(
            (spaceId) => _Terminals(spaceId, terminals),
          ),
          spaceAgentShellsProvider(
            key,
          ).overrideWith((ref) => Stream.value(commands)),
          agentShellProcessPortProvider.overrideWithValue(port),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: Scaffold(
              body: ListView(
                children: [
                  TerminalsSection(
                    spaceId: 's-1',
                    workspaceId: 'ws-1',
                    onFocusTerminal: focused.add,
                    onKillTerminal: killed.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (focused: focused, killed: killed, port: port);
  }

  Future<void> hover(WidgetTester tester, Finder target) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pumpAndSettle();
  }

  testWidgets('a terminal row ends its shell with the hover trash', (
    tester,
  ) async {
    final r = await pump(
      tester,
      terminals: const [
        TerminalMirror(
          session: TerminalSession(
            sessionId: 'term-1',
            spaceId: 's-1',
            workspaceId: 'ws-1',
          ),
          title: 'pnpm dev',
        ),
      ],
    );

    // At rest the row reads clean; the trash is a hover affordance.
    expect(find.byIcon(AppIcons.trash2), findsNothing);
    await hover(tester, find.text('pnpm dev'));
    expect(find.byIcon(AppIcons.trash2), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    expect(r.killed, ['term-1']);
    // The trash is its own press: ending a shell must not also focus it.
    expect(r.focused, isEmpty);
  });

  testWidgets('an agent command is listed and stopped from its row', (
    tester,
  ) async {
    final r = await pump(
      tester,
      commands: [_command(4242, 'pnpm vitest run --shard=2/10')],
    );

    expect(find.text('pnpm vitest run --shard=2/10'), findsOneWidget);
    expect(find.text('4m'), findsOneWidget);
    expect(find.text('1'), findsOneWidget, reason: 'section count');

    expect(find.byIcon(AppIcons.circleStop), findsNothing);
    await hover(tester, find.text('pnpm vitest run --shard=2/10'));
    await tester.tap(find.byIcon(AppIcons.circleStop));
    await tester.pumpAndSettle();
    expect(r.port.killed, [('ws-1', 's-1', 4242)]);
  });

  testWidgets('a multi-line command shows its first line', (tester) async {
    await pump(tester, commands: [_command(7, 'cd web\npnpm build')]);
    expect(find.text('cd web'), findsOneWidget);
  });

  testWidgets('with nothing running the section says so', (tester) async {
    await pump(tester);
    expect(find.text('No terminals open'), findsOneWidget);
  });
}
