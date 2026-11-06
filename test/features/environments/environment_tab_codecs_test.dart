import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_layout_codec.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a logs tab restores with what it needs to reattach', () {
    expect(
      messagingLayoutCodec.restorableKinds,
      contains(MessagingTabKinds.environmentLogs),
    );
    expect(prLayoutCodec.restorableKinds, contains(PrTabKinds.environmentLogs));
    expect(
      messagingLayoutCodec.requiredStringArgs[MessagingTabKinds
          .environmentLogs],
      ['workspaceId', 'spaceId', 'target'],
    );
  });

  test('a preparation log never comes back after a restart', () {
    // It lives in the server's memory and matters while the preparation does.
    expect(
      messagingLayoutCodec.restorableKinds,
      isNot(contains(MessagingTabKinds.provisioningLogs)),
    );
    expect(
      prLayoutCodec.restorableKinds,
      isNot(contains(PrTabKinds.provisioningLogs)),
    );
  });

  test('a typed command never comes back with a restored terminal', () {
    expect(messagingLayoutCodec.transientArgs, contains('initialInput'));
    expect(prLayoutCodec.transientArgs, contains('initialInput'));
  });

  test('the environment preview stays non-restorable', () {
    expect(prLayoutCodec.restorableKinds, isNot(contains(PrTabKinds.preview)));
  });
}
