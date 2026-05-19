import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';

/// A booted enclosure, hypervisor-agnostic.
///
/// `RigService` drives machines through this interface; which hypervisor
/// produced one is visible only where the concrete type selects a mechanism
/// (teardown, park, worktree carrier). A new backend implements this rather
/// than growing `RigService` a parallel machine map.
abstract interface class RigMachine {
  /// The rig this machine serves.
  String get rigId;

  /// A process whose exit means "the machine is gone".
  ///
  /// For QEMU it IS the hypervisor. For smolvm it is a held `machine exec`
  /// sentinel: the CLI spawns the VMM detached, so the service holds a
  /// connection whose drop reports the machine's death with the same
  /// immediacy as a hypervisor exit.
  Process get process;

  /// The guest's current display size.
  RigDisplaySize get display;
  set display(RigDisplaySize value);

  /// Whether the machine is parked.
  bool get parked;
  set parked(bool value);

  /// The per-rig secret the guest presents to the credential broker.
  String get guestSecret;
}
