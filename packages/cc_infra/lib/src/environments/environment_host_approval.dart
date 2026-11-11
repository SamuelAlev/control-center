import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';

/// Who may currently approve a definition that runs on the host: the server
/// owner's user id, or null when none is recorded (then nobody can).
typedef EnvironmentServerOwner = Future<String?> Function();

/// A definition that runs something on the server itself, which the current
/// server owner has not approved, was about to run.
///
/// An [AuthException] for RPC, which forwards its code as `data.kind`
/// ([environmentHostUnapprovedKind]), and an [EnvironmentDriverException] for
/// the service's own paths, so a start or restart nobody asked for records it
/// as the environment's error the way any other refusal is recorded.
class EnvironmentHostUnapprovedException extends AuthException
    implements EnvironmentDriverException {
  /// Creates an [EnvironmentHostUnapprovedException].
  const EnvironmentHostUnapprovedException()
    : super(
        'This environment runs on the server itself and the server owner has '
        'not approved it. The owner approves it by saving it in the '
        'environment settings.',
        code: environmentHostUnapprovedKind,
      );

  @override
  EnvironmentError get error =>
      EnvironmentError(code: environmentHostUnapprovedKind, message: message);

  @override
  String toString() => message;
}
