import 'package:control_center/features/sandboxing/data/runtime/linux_sandbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider that resolves whether the current environment is WSL2.
final isWsl2Provider = Provider<bool>((ref) => LinuxSandbox.isWsl2());
