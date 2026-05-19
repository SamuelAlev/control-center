import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkspacePanel stores label, icon, and builder', () {
    final panel = WorkspacePanel(
      label: 'Test Panel',
      icon: Icons.code,
      builder: (id) => const Text('content'),
    );

    expect(panel.label, 'Test Panel');
    expect(panel.icon, Icons.code);
    expect(panel.builder, isA<Widget Function(String)>());
  });

  test('builder returns widget for given workspaceId', () {
    final panel = WorkspacePanel(
      label: 'Panel',
      icon: Icons.star,
      builder: (id) => Text('Workspace: $id'),
    );

    final widget = panel.builder('ws-123');
    expect(widget, isA<Text>());
    expect((widget as Text).data, 'Workspace: ws-123');
  });

  test('equality works', () {
    final a = WorkspacePanel(
      label: 'A',
      icon: Icons.star,
      builder: (_) => const SizedBox(),
    );
    final b = WorkspacePanel(
      label: 'A',
      icon: Icons.star,
      builder: (_) => const SizedBox(),
    );
    expect(a.label, b.label);
    expect(a.icon, b.icon);
  });
}
