import 'package:control_center/features/sandboxing/data/runtime/linux_sandbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isWsl2Provider = Provider<bool>((ref) => LinuxSandbox.isWsl2());
