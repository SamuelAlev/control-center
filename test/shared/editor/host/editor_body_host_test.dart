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
}
