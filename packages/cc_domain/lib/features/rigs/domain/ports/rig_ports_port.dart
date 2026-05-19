/// Port visibility + forwarding for enclosed rigs: what is listening inside
/// the Terminal (VM), and every address each port answers on.
///
/// A SEPARATE port from [RigPort](rig_port.dart) on purpose: driving a
/// machine and plumbing its network are different capabilities, hosts wire
/// them independently, and the `rig.*Port*` RPC ops exist only when this one
/// is present.
///
/// Wire-shaped (maps, not entities), following `RigPort.imageStatuses`: the
/// client renders a panel, and the snapshot's concrete types live with the
/// forwarding mechanism in `cc_infra` — which the domain must not reach for.
///
/// Every method takes a required `workspaceId`, and a rig in another
/// workspace reads as absent (null / false), never as forbidden.
abstract interface class RigPortsPort {
  /// The forwarded-ports snapshot for [rigId], or null when it is not a live
  /// exec (terminal) rig in [workspaceId].
  ///
  /// Shape: `{rig_id, auto_forward, ports: [{guest_port, host_port,
  /// lan_port?, origin, domain?, process?, active}]}`.
  Map<String, dynamic>? portsFor(String workspaceId, String rigId);

  /// Live snapshots for [rigId], current value first.
  Stream<Map<String, dynamic>> watchPorts(String workspaceId, String rigId);

  /// Turns auto-forwarding of newly discovered guest ports on or off.
  /// False when the rig is not a live exec rig in [workspaceId].
  Future<bool> setPortsAutoForward(
    String workspaceId,
    String rigId, {
    required bool enabled,
  });

  /// Forwards [guestPort] by hand. A manual forward survives its guest
  /// process dying (it reports itself inactive instead of vanishing).
  Future<bool> addPortForward(String workspaceId, String rigId, int guestPort);

  /// Removes [guestPort]'s forward. Removing an auto-forward suppresses it
  /// until the guest port disappears, so it does not respawn on the next
  /// discovery poll.
  Future<bool> removePortForward(
    String workspaceId,
    String rigId,
    int guestPort,
  );

  /// Exposes (or unexposes) [guestPort] on the LAN as an OS-assigned port.
  /// Loopback-only is the default; exposure is always a deliberate act.
  Future<bool> setPortLanExposed(
    String workspaceId,
    String rigId,
    int guestPort, {
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
}
