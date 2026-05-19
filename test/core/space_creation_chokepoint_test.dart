import 'dart:io';

import 'package:test/test.dart';

/// Writing a space row and announcing it are ONE operation.
///
/// A space is born `provisioning`, and the checkout that clears that state is
/// driven off `SpaceCreated` by the background provisioner. A creation that
/// skips the event leaves a room parked behind its "preparing workspace" gate
/// forever — the composer refuses to send, no worktree lands on disk, and
/// nothing later notices, because the only signal provisioning was due is the
/// event nobody published.
///
/// Four independent call sites had hand-rolled the pair (the in-process
/// messaging service, the `messaging.createSpace` RPC op, the PR-review space
/// resolver and the agent-DM tool), each with a comment saying it mirrored the
/// others. That is not an invariant, it is a convention — and a fifth caller
/// would not have failed a single test.
///
/// So there is exactly one announcer, `SpaceFactory`, and this pins it.
void main() {
  test('only SpaceFactory announces a created space', () {
    final projectRoot = Directory.current.path;

    // The event's own declaration, and the one chokepoint that announces.
    const eventDeclaration =
        'packages/cc_domain/lib/core/domain/events/messaging_events.dart';
    const chokepoint =
        'packages/cc_domain/lib/features/messaging/domain/services/'
        'space_factory.dart';
    const allowed = {eventDeclaration, chokepoint};

    String basename(Directory d) => d.path.split(Platform.pathSeparator).last;

    final roots = <String>[
      'lib',
      for (final group in const ['packages', 'apps'])
        if (Directory('$projectRoot/$group').existsSync())
          for (final entry in Directory(
            '$projectRoot/$group',
          ).listSync().whereType<Directory>())
            '$group/${basename(entry)}/lib',
    ];

    final offenders = <String>[];
    var scanned = 0;
    for (final root in roots) {
      final dir = Directory('$projectRoot/$root');
      if (!dir.existsSync()) {
        continue;
      }
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) {
          continue;
        }
        final rel = file.path.substring(projectRoot.length + 1);
        scanned++;
        if (allowed.contains(rel)) {
          continue;
        }
        // Strip line comments so prose mentioning the event never trips this.
        final body = file.readAsStringSync().replaceAll(
          RegExp('//[^\n]*'),
          '',
        );
        if (body.contains('SpaceCreated(')) {
          offenders.add(rel);
        }
      }
    }

    expect(
      scanned,
      greaterThan(100),
      reason: 'Scanned almost nothing — re-aim this guard at the source roots.',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'These files publish SpaceCreated themselves instead of creating the '
          'space through SpaceFactory:\n${offenders.join('\n')}\n\n'
          'Creating a space and announcing it must stay one operation — a row '
          'written without the event never provisions its checkout. Call '
          'SpaceFactory.create (it takes a `beforeAnnounce` hook for rows a '
          'listener will immediately go looking for, like a PR association).',
    );
  });
}
