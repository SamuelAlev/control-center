import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('myWorkspaceRoleProvider reads the session membership', () async {
    final me = IdentityMe(
      user: UserDto(id: 'u1', handle: 'sam', displayName: 'Sam'),
      deviceId: 'dev',
      isServerOwner: false,
      memberships: [
        WorkspaceMemberDto(
          id: 'm1',
          workspaceId: 'ws-1',
          userId: 'u1',
          role: 'admin',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        currentIdentityProvider.overrideWith((ref) async => me),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentIdentityProvider.future);

    expect(container.read(myWorkspaceRoleProvider('ws-1')), WorkspaceRole.admin);
    expect(container.read(myWorkspaceRoleProvider('ws-other')), isNull);
  });
}
