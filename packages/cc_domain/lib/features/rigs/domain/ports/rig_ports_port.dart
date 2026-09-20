/// Port visibility + forwarding for enclosed rigs and host-shell terminals:
/// what is listening inside a Terminal (VM) or this space's host-shell, and
/// every address each port answers on.
///
/// A SEPARATE port from [RigPort](rig_port.dart) on purpose: driving a
/// machine and plumbing its network are different capabilities, hosts wire
/// them independently, and the `rig.*Port*` / `terminal.*Port*` RPC ops
/// exist only when this one is present.
///
/// Wire-shaped (maps, not entities), following `RigPort.imageStatuses`: the
/// client renders a panel, and the snapshot's concrete types live with the
/// forwarding mechanism in `cc_infra` — which the domain must not reach for.
///
/// Every method takes a required `workspaceId`, and a rig or session in
/// another workspace (or, for terminal ops, a session whose space is not
/// the caller's) reads as absent (null / false), never as forbidden.
abstract interface class RigPortsPort {
  /// Live snapshots for [rigId], current value first.
  Stream<Map<String, dynamic>> watchPorts(String workspaceId, String rigId);

  /// Live snapshots for a host-shell [sessionId] in [spaceId].
  ///
  /// A session whose stored space is not [spaceId] reads as absent.
  Stream<Map<String, dynamic>> watchTerminalPorts(
    String workspaceId,
    String sessionId, {
    required String spaceId,
  });

  /// Turns auto-forwarding of newly discovered guest ports on or off.
  /// False when the rig is not a live exec rig in [workspaceId].
  Future<bool> setPortsAutoForward(
    String workspaceId,
    String rigId, {
    required bool enabled,
  });

  /// Turns auto-forwarding on or off for a host-shell session.
  Future<bool> setTerminalPortsAutoForward(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required bool enabled,
  });

  /// Forwards [guestPort] by hand. A manual forward survives its guest
  /// process dying (it reports itself inactive instead of vanishing).
  ///
  /// [hostPort] remaps a host-shell listener onto a different loopback
  /// port. Ignored for exec rigs.
  Future<bool> addPortForward(
    String workspaceId,
    String rigId,
    int guestPort, {
    int? hostPort,
  });

  /// Forwards [guestPort] by hand on a host-shell session.
  Future<bool> addTerminalPortForward(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
    int? hostPort,
  });

  /// Removes [guestPort]'s forward. Removing an auto-forward suppresses it
  /// until the guest port disappears, so it does not respawn on the next
  /// discovery poll.
  Future<bool> removePortForward(
    String workspaceId,
    String rigId,
    int guestPort,
  );

  /// Removes a host-shell forward.
  Future<bool> removeTerminalPortForward(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
  });

  /// Exposes (or unexposes) [guestPort] on the LAN as an OS-assigned port.
  /// Loopback-only is the default; exposure is always a deliberate act.
  Future<bool> setPortLanExposed(
    String workspaceId,
    String rigId,
    int guestPort, {
    required bool exposed,
  });

  /// Exposes (or unexposes) a host-shell port on the LAN.
  Future<bool> setTerminalPortLanExposed(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
    required bool exposed,
  });

  /// Assigns (or clears, with null) a dev domain (`myapp.test`) routed to
  /// [guestPort] inside the conversation's Browser (VM).
  ///
  /// Throws [ArgumentError] on a malformed domain or one already routed
  /// elsewhere.
  Future<bool> setPortDomain(
    String workspaceId,
    String rigId,
    int guestPort,
    String? domain,
  );

  /// Assigns (or clears) a dev domain on a host-shell session.
  Future<bool> setTerminalPortDomain(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
    String? domain,
  });
}
