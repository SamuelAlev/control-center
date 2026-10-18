import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_body_host.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const background = Color(0x00000000);

  test('stable hidden tab reuses its content widget', () {
    final host = EditorBodyHost(isWebviewKind: (_) => false);
    const tab = EditorTab(kind: 'chat', label: 'Chat');
    var builds = 0;

    Widget buildContent() {
      builds++;
      return const SizedBox();
    }

    host.wrap(
      tab,
      isVisible: false,
      background: background,
      buildContent: buildContent,
    );
    expect(builds, 0, reason: 'an unseen tab must stay lazy');

    host.wrap(
      tab,
      isVisible: true,
      background: background,
      buildContent: buildContent,
    );
    expect(builds, 1);

    host.wrap(
      tab,
      isVisible: false,
      background: background,
      buildContent: buildContent,
    );
    expect(builds, 2, reason: 'the outgoing body receives its hidden state');

    host.wrap(
      tab,
      isVisible: false,
      background: background,
      buildContent: buildContent,
    );
    expect(
      builds,
      2,
      reason: 'unrelated tab switches must not rebuild a stable hidden body',
    );
  });

  test('visible tab rebuilds and a revealed tab refreshes', () {
    final host = EditorBodyHost(isWebviewKind: (_) => false);
    const tab = EditorTab(kind: 'diff', label: 'Diff');
    var builds = 0;

    Widget buildContent() {
      builds++;
      return const SizedBox();
    }

    for (final isVisible in [true, true, false, false, true]) {
      host.wrap(
        tab,
        isVisible: isVisible,
        background: background,
        buildContent: buildContent,
      );
    }

    expect(
      builds,
      4,
      reason: 'visible content stays current and refreshes when revealed',
    );
  });

  group('adoptBodies', () {
    // Not const: a restored layout decodes fresh EditorTab instances.
    EditorTab chat(String dedupKey) =>
        EditorTab(kind: 'chat', label: 'Chat', dedupKey: dedupKey);

    Future<int> mountsAcrossSwap(
      WidgetTester tester, {
      required EditorTab seed,
      required EditorTab restored,
    }) async {
      final host = EditorBodyHost(isWebviewKind: (_) => false);
      var mounts = 0;
      Widget body(EditorTab tab) => Directionality(
        textDirection: TextDirection.ltr,
        child: host.wrap(
          tab,
          isVisible: true,
          background: background,
          buildContent: () => _MountCounter(onMount: () => mounts++),
        ),
      );

      await tester.pumpWidget(body(seed));
      host
        ..adoptBodies(outgoing: [seed], incoming: [restored])
        ..reconcile([restored]);
      await tester.pumpWidget(body(restored));
      return mounts;
    }

    testWidgets('a restored tab keeps the seed tab\'s built body', (
      tester,
    ) async {
      final mounts = await mountsAcrossSwap(
        tester,
        seed: chat('chat:space'),
        restored: chat('chat:space'),
      );
      expect(mounts, 1, reason: 'the same tab must not build its body twice');
    });

    testWidgets('a different tab builds its own body', (tester) async {
      final mounts = await mountsAcrossSwap(
        tester,
        seed: chat('chat:space'),
        restored: chat('chat:other'),
      );
      expect(mounts, 2);
    });
  });
}

class _MountCounter extends StatefulWidget {
  const _MountCounter({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
