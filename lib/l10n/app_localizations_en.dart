// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get succeeded => 'Succeeded';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Retry #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Starting · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Following live activity';

  @override
  String get agentActivityJumpToLatest => 'Jump to latest';

  @override
  String get agentActivityLoadFailed => 'Couldn\'t load this run\'s activity';

  @override
  String get agentActivityNotRecorded =>
      'No activity was recorded for this run';

  @override
  String get agentActivityNotRecordedHint =>
      'Runs that finished before activity capture was enabled have no timeline.';

  @override
  String get agentActivityRunUnavailable => 'This run is no longer available';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagent of $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Activity capture is unavailable on the connected server';

  @override
  String get agentActivityUnsupportedHint =>
      'Restart the app so it picks up the latest server build.';

  @override
  String get agentActivityWaiting => 'Waiting for activity…';

  @override
  String get created => 'Created';

  @override
  String get dictationStart => 'Start dictation';

  @override
  String get dictationListening => 'Listening…';

  @override
  String get dictationUnavailable =>
      'Dictation needs a voice model on the server host. Set one up in voice settings.';

  @override
  String get dictationFailedToStart => 'Couldn\'t start dictation';

  @override
  String get dictationHoldToTalkTitle => 'Hold to talk';

  @override
  String get dictationHoldToTalkDescription =>
      'Hold the mic button or the shortcut to dictate and release to stop. When off, press once to start and again to stop.';

  @override
  String get focusConversation => 'Focus conversation';

  @override
  String get ideAgentActivity => 'Agent activity';

  @override
  String get keybindingPushToTalk => 'Push to talk';

  @override
  String get keybindingPushToTalkDescription =>
      'Hold or toggle voice dictation in the message composer';

  @override
  String get agentPermissions => 'Agent permissions';

  @override
  String get agentPermissionsSettingsDescription =>
      'Decide what agents can do on their own, must ask about first, or can never do — per workspace, agent, or channel.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Set a decision for each kind of effect. Rules cascade: channel overrides agent overrides workspace.';

  @override
  String get guardrailLoading => 'Loading rules…';

  @override
  String get guardrailRulesLoadFailed => 'Couldn\'t load the permission rules.';

  @override
  String get guardrailScopeWorkspace => 'Workspace';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeChannel => 'Channel';

  @override
  String get guardrailSelectAgent => 'Select an agent';

  @override
  String get guardrailSelectChannel => 'Select a channel';

  @override
  String get guardrailNoAgents => 'No agents in this workspace yet.';

  @override
  String get guardrailNoChannels => 'No channels in this workspace yet.';

  @override
  String get guardrailClassFileDelete => 'Delete a file';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Write outside the worktree';

  @override
  String get guardrailClassGitCommit => 'Create a commit';

  @override
  String get guardrailClassGitPush => 'Push to a remote';

  @override
  String get guardrailClassPrCreate => 'Open a pull request';

  @override
  String get guardrailClassPrPublish => 'Publish a review or merge';

  @override
  String get guardrailClassVendorSyncWrite => 'Write to an external tracker';

  @override
  String get guardrailClassNetworkEgress => 'Access the network';

  @override
  String get guardrailClassSecretAccess => 'Read a secret';

  @override
  String get guardrailClassPackageInstall => 'Install a package';

  @override
  String get guardrailClassProcessSpawn => 'Run a process';

  @override
  String get guardrailClassWorkspaceMutation => 'Change workspace structure';

  @override
  String get guardrailClassEnclosureControl => 'Drive an enclosure (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'This server cannot host enclosed VMs. Rigs need a hypervisor on the machine running cc_server.';

  @override
  String get rigSurfaceComputer => 'Computer';

  @override
  String get rigSurfaceBrowser => 'Browser';

  @override
  String get rigSurfaceMobile => 'Mobile';

  @override
  String get rigPhaseReady => 'Ready';

  @override
  String get rigPhaseStarting => 'Starting';

  @override
  String get rigPhaseParked => 'Parked';

  @override
  String get rigPhaseClosing => 'Closing';

  @override
  String get rigPhaseClosed => 'Closed';

  @override
  String get rigPhaseFailed => 'Failed';

  @override
  String get rigPhaseUnknown => 'Unknown';

  @override
  String get rigNotAccelerated => 'Emulated';

  @override
  String get rigTakeControl => 'Take control';

  @override
  String get rigAudioListen => 'Listen to the machine';

  @override
  String get rigAudioMute => 'Mute the machine';

  @override
  String get rigHandBack => 'Hand back';

  @override
  String get rigYouHaveControl => 'You have control';

  @override
  String get rigBackendAvailable => 'Available';

  @override
  String get rigBackendUnavailable => 'Unavailable';

  @override
  String get rigEgressNotEnforced =>
      'Network is not enclosed on this backend — it manages its own connectivity.';

  @override
  String get rigStartMachine => 'Start the machine';

  @override
  String get rigStartHint =>
      'Starts a disposable VM you and your agents share for this conversation. It is destroyed when it closes, and nothing in it touches your computer.';

  @override
  String get rigStopMachine => 'Stop the machine';

  @override
  String get rigSurfaceUnavailable =>
      'This server cannot host this kind of machine.';

  @override
  String get rigTabNeedsConversation =>
      'Open a conversation first — a machine belongs to one, so you and your agents are looking at the same screen.';

  @override
  String get rigTabComputer => 'Computer (VM)';

  @override
  String get rigTabBrowser => 'Browser (VM)';

  @override
  String get rigTabMobile => 'Phone (VM)';

  @override
  String get rigsSettingsSubtitle =>
      'What this server can boot, the base images it needs, and the machines running now';

  @override
  String get rigsCapabilitiesTitle => 'This server';

  @override
  String get rigsImagesTitle => 'Base images';

  @override
  String get rigsImagesHint =>
      'Every rig boots one of these read-only images. Each session writes to a throwaway overlay, so one rig can never change what the next one starts from.';

  @override
  String get rigsRunningTitle => 'Running now';

  @override
  String get rigsNoneRunning => 'No machines are running.';

  @override
  String get rigsCustomImagesTitle => 'Custom images (this workspace)';

  @override
  String get rigsCustomImagesHint =>
      'Point the Terminal (VM) or Browser (VM) at your own image — extend the defaults with the tools your project needs, or use any compatible one from a registry. New machines use it; running ones keep theirs. See the rigs guide for what an image must provide.';

  @override
  String get rigsCustomTerminalImageLabel => 'Terminal (VM) image';

  @override
  String get rigsCustomBrowserImageLabel => 'Browser (VM) image';

  @override
  String get rigsCustomImagePlaceholder =>
      'e.g. ghcr.io/acme/dev-shell:1.2 — leave blank for the default';

  @override
  String get rigsCustomImageInvalid =>
      'Enter a registry reference such as repo/name:tag. Local paths and archives are not allowed.';

  @override
  String get rigsCustomImageSaved =>
      'Saved. New machines boot this image; running ones keep theirs.';

  @override
  String get rigsEgressTitle => 'Browser egress (this workspace)';

  @override
  String get rigsEgressHint =>
      'Extra hosts the enclosed browser may reach — one per line: an exact host (api.example.com) or a wildcard for its subdomains (*.example.com). The product site stays allowed either way. New machines get the list; running ones keep what they booted with.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" is not a valid host entry.';
  }

  @override
  String get rigsEgressSaved =>
      'Saved. New browser machines admit these hosts; running ones keep theirs.';

  @override
  String get rigImageInstalled => 'Installed';

  @override
  String get rigImageNotDownloaded => 'Not downloaded';

  @override
  String get rigImageNotPublished => 'Not published';

  @override
  String get rigImageNotPublishedHint =>
      'No image has been published for this yet, so there is nothing to download. Import a compatible disk image to enable it.';

  @override
  String get rigImageDownload => 'Download';

  @override
  String get rigImageDownloading => 'Downloading…';

  @override
  String get rigImageImport => 'Import';

  @override
  String get rigImageImportMessage =>
      'Path to a qcow2 disk image on the server\'s filesystem. It is copied into the image store, so the file can move afterwards.';

  @override
  String get rigConnectingStream => 'Connecting to the rig';

  @override
  String get rigStreamNotAllowed => 'You do not have access to this rig.';

  @override
  String get rigStreamNotRunning => 'This rig is no longer running.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Live view needs ffmpeg on this host. Install ffmpeg and reopen the tab.';

  @override
  String get rigStreamEnded => 'The live view ended.';

  @override
  String get rigStreamFailed => 'The live view could not be opened.';

  @override
  String get rigStreamDisconnected => 'Not connected to a server.';

  @override
  String get rigClipboardUnreadable =>
      'The machine did not answer when asked for its clipboard.';

  @override
  String rigDropSendingOne(String name) {
    return 'Copying \"$name\" into the machine…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Copying $count files into the machine…';
  }

  @override
  String get rigTerminalDropSending => 'Copying into the machine…';

  @override
  String get rigTerminalPasteImage => 'Pasted image saved in the machine';

  @override
  String get rigPortsTitle => 'Forwarded ports';

  @override
  String get rigPortsTooltip => 'Ports open inside this machine';

  @override
  String get rigPortsEmpty =>
      'Nothing is listening yet. Start a server in the terminal — a dev server on port 3000 shows up here.';

  @override
  String get rigPortsAdd => 'Add port';

  @override
  String get rigPortsAddHint => 'Guest port to forward (e.g. 3000)';

  @override
  String get rigPortsAutoForward => 'Auto-forward ports';

  @override
  String get rigPortsCopyUrl => 'Copy local URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Copied $url';
  }

  @override
  String get rigPortsStopForward => 'Stop forwarding';

  @override
  String get rigPortsExposeLan => 'Share on local network';

  @override
  String get rigPortsLanPrivate => 'Local only';

  @override
  String get rigPortsLanShared => 'On the network';

  @override
  String get rigPortsSetDomain => 'Set a browser domain (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domain for the Browser (VM), e.g. myapp.test — reachable there, not on the host';

  @override
  String get rigPortsProcessUnknown => 'unknown process';

  @override
  String get rigPortsInactive => 'not listening';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count base images still to download',
      one: '1 base image still to download',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Allow';

  @override
  String get guardrailDecisionPrompt => 'Ask first';

  @override
  String get guardrailDecisionDeny => 'Deny';

  @override
  String get guardrailSourceThisScope => 'This scope';

  @override
  String get guardrailSourceDefault => 'Built-in default';

  @override
  String get guardrailSourcePreset => 'Mode preset';

  @override
  String get guardrailSourceInherited => 'Inherited';

  @override
  String get guardrailClearToInherited => 'Clear to inherited';

  @override
  String get guardrailWhatIf => 'What if?';

  @override
  String get guardrailWhatIfDescription =>
      'See how the current rules would resolve an action, using the same logic the agents run against.';

  @override
  String get guardrailProbeActionLabel => 'Action';

  @override
  String get guardrailProbeCommandLabel => 'Command (optional)';

  @override
  String get guardrailProbeCommandHint => 'e.g. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (optional)';

  @override
  String get guardrailProbeChannelLabel => 'Channel (optional)';

  @override
  String get guardrailProbeNone => 'None';

  @override
  String get guardrailProbeModeLabel => 'Mode';

  @override
  String get guardrailProbeResult => 'Result';

  @override
  String get guardrailProbeSource => 'Source:';

  @override
  String get guardrailAdapterMatrix => 'Where rules are enforced';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Honest reference: where each effect is actually caught, per agent runner. This documents reality, not a guarantee — effects a runner performs out of band can\'t be intercepted.';

  @override
  String get guardrailEffectColumn => 'Effect';

  @override
  String get guardrailAdapterHarness => 'Built-in harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Sandbox floor';

  @override
  String get guardrailEnforcementPolicyGate => 'Policy gate';

  @override
  String get guardrailEnforcementSandbox => 'Sandbox only';

  @override
  String get guardrailEnforcementNone => 'Not enforceable';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'The permission decision is checked before the effect runs and can block it.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Only the sandbox constrains it; the permission rule isn\'t consulted.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'The decision is advisory only — it can\'t be intercepted here.';

  @override
  String get obsStatCost => 'cost';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegated';
  }

  @override
  String get obsStatDuration => 'duration';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'tools';

  @override
  String get openAgentActivity => 'Open activity';

  @override
  String get orgChart => 'Org chart';

  @override
  String get orgChartEmpty => 'No agents yet';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get serverConnection => 'Server connection';

  @override
  String get serverConnectionMode => 'Mode';

  @override
  String get serverModeLocal => 'Run in this app';

  @override
  String get serverModeLocalDescription =>
      'Control Center runs its own server on this machine and owns your data locally.';

  @override
  String get serverModeRemote => 'Connect to a remote instance';

  @override
  String get serverModeRemoteDescription =>
      'Connect to a Control Center server running elsewhere. Your data lives on that server.';

  @override
  String get serverRemoteUrl => 'Server URL';

  @override
  String get serverRemoteDeviceId => 'Device id';

  @override
  String get serverRemotePairingKey => 'Pairing key';

  @override
  String get serverRemotePairingKeyHint =>
      'Paste the pairing key from the remote server';

  @override
  String get serverSetupInviteCode => 'Invite code';

  @override
  String get serverSetupInviteCodeHint =>
      'Paste a one-time invite code (leave empty to use a pairing key)';

  @override
  String get serverDiscoveryTooltip => 'Find servers on your network';

  @override
  String get serverDiscoveryTitle => 'Servers on your network';

  @override
  String get serverDiscoverySearching => 'Searching for servers…';

  @override
  String get serverDiscoveryEmpty =>
      'No servers found. Check that the server is running and that this device can reach it, then search again.';

  @override
  String get serverDiscoveryRefresh => 'Search again';

  @override
  String get serverListActive => 'Active';

  @override
  String get serverListSwitch => 'Switch';

  @override
  String get serverListAddTitle => 'Add server';

  @override
  String get serverListRemoveActiveHint =>
      'Switch to another server before removing this one.';

  @override
  String get serverSwitchFailedTitle => 'Could not switch server';

  @override
  String get serverListInsecureBadge => 'Insecure';

  @override
  String get connectionPathLocal => 'Local';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Shutting down';

  @override
  String get shutdownSubtitle => 'Closing the local server';

  @override
  String get shutdownServiceApprovals => 'Approvals';

  @override
  String get shutdownServiceBackgroundJobs => 'Background jobs';

  @override
  String get shutdownServiceScheduler => 'Job scheduler';

  @override
  String get shutdownServiceCalendar => 'Calendar sync';

  @override
  String get shutdownServiceWeather => 'Weather';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Meetings';

  @override
  String get shutdownServiceVoiceModels => 'Voice models';

  @override
  String get shutdownServiceNetworking => 'Networking';

  @override
  String get shutdownServicePresence => 'Presence';

  @override
  String get shutdownServiceDataSync => 'Data sync';

  @override
  String get shutdownServiceDeviceRelay => 'Device relay';

  @override
  String get shutdownServiceMcpConnections => 'MCP connections';

  @override
  String get shutdownServiceCodeEditors => 'Code editors';

  @override
  String get serverSharingTitle => 'Share this server';

  @override
  String get serverSharingDescription =>
      'Make this server reachable from your other devices. Nothing is exposed publicly unless you turn on a tunnel below. Pairing invites embed the server\'s current addresses automatically — create them under workspace settings.';

  @override
  String get serverSharingUnavailable =>
      'Sharing controls are not available on this server.';

  @override
  String get serverSharingMdnsLabel => 'LAN discovery';

  @override
  String get serverSharingMdnsOn =>
      'Advertising this server on your local network (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Not advertising on your local network (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Turning on a tunnel makes this server reachable from the internet. Public exposure is opt-in and off by default.';

  @override
  String get serverSharingProviderOff => 'Off';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Public URL';

  @override
  String get serverSharingTunnelStarting => 'Starting the tunnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Tunnel error: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'The tunnel is up. Reach it at your configured DNS hostname.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Relayed this month: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Active relay sessions: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Couldn\'t update sharing';

  @override
  String get serverConnectionRestartHint =>
      'Restart Control Center to apply connection changes.';

  @override
  String get serverConnectionReloadHint =>
      'Reload to reconnect with these changes.';

  @override
  String get pairNewClient => 'Pair a new client';

  @override
  String get pairClientNameHint => 'Label this client (e.g. Work laptop)';

  @override
  String get pairClientTypeWeb => 'Web browser';

  @override
  String get pairClientTypeDesktop => 'Desktop app';

  @override
  String get pairClientTypePhone => 'Phone';

  @override
  String get pairAction => 'Pair';

  @override
  String get revoke => 'Revoke';

  @override
  String get pairCredentialsIntro =>
      'Connect the new client with these details, or open the link in it.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Scan this QR code with your phone\'s camera to pair it.';

  @override
  String get pairServerUnreachableTitle => 'Not reachable';

  @override
  String get pairServerUnreachable =>
      'Other devices can\'t reach this server directly, so a new client can\'t connect. Set the server\'s public URL to pair more clients.';

  @override
  String get serverSetupTitle => 'How should Control Center run?';

  @override
  String get serverSetupSubtitle =>
      'Control Center needs a server that owns your data. Run one inside this app, or connect to an instance running elsewhere.';

  @override
  String get serverSetupRunLocal => 'Run in this app';

  @override
  String get serverSetupConnect => 'Connect';

  @override
  String get serverSetupInvalidUrl =>
      'Enter a valid ws:// or wss:// server URL.';

  @override
  String get serverSetupCouldNotConnect => 'Could not connect';

  @override
  String get serverSetupErrorUnreachable =>
      'We couldn\'t reach the server. Check that it\'s running and that this device can reach it (same network or relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'The server\'s identity doesn\'t match the one saved on this device. If the server was reinstalled or reset, remove the saved server and pair again.';

  @override
  String get serverSetupErrorAuthRejected =>
      'The server rejected this device. Check that the pairing key and device id match what the server issued.';

  @override
  String get serverSetupErrorInviteRejected =>
      'That invite code is invalid or has expired. Ask for a fresh one.';

  @override
  String get serverSetupErrorGeneric =>
      'Something went wrong while connecting. Expand the technical details below for more information.';

  @override
  String get serverSetupErrorDetails => 'Technical details';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '1 more',
    );
    return '$_temp0';
  }

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Connect Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sync your Google Calendar to see events here and get alerts before meetings start.';

  @override
  String get calendarDisconnect => 'Disconnect';

  @override
  String get calendarReconnect => 'Reconnect';

  @override
  String get calendarEmptyNoEvents => 'No events in this range';

  @override
  String get calendarStartRecording => 'Start recording';

  @override
  String get calendarStartRecordingAndLink => 'Start recording & link';

  @override
  String get calendarJoinMeet => 'Join meeting';

  @override
  String get calendarFromCalendar => 'From calendar';

  @override
  String get calendarLinkedMeeting => 'Linked meeting';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarAllDay => 'All day';

  @override
  String calendarWeekNumber(int number) {
    return 'Week $number';
  }

  @override
  String get calendarPreviousPeriod => 'Previous';

  @override
  String get calendarNextPeriod => 'Next';

  @override
  String calendarLastSynced(String time) {
    return 'Synced $time';
  }

  @override
  String get calendarNeverSynced => 'Not synced yet';

  @override
  String get calendarSyncing => 'Syncing…';

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarSectionCalendars => 'Calendars';

  @override
  String get calendarShow => 'Show';

  @override
  String get calendarHide => 'Hide';

  @override
  String get calendarRsvpGoing => 'Going?';

  @override
  String get calendarRsvpYes => 'Yes';

  @override
  String get calendarRsvpNo => 'No';

  @override
  String get calendarRsvpMaybe => 'Maybe';

  @override
  String get calendarRsvpFailed => 'Couldn\'t update your response';

  @override
  String get calendarAddAccount => 'Add calendar account';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Connect a Google account to sync events into this workspace.';

  @override
  String get calendarNotConnected => 'No Google account connected';

  @override
  String get calendarConnecting => 'Connecting…';

  @override
  String get calendarSyncNow => 'Sync now';

  @override
  String get calendarNoWorkspace => 'Select a workspace to view its calendar';

  @override
  String get calendarConnectError => 'Couldn\'t connect Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Enter the Google OAuth device-code client ID and secret for your project. The server runs the connection and sync — your browser never holds the tokens.';

  @override
  String get calendarConnectApproveInstruction =>
      'Open the verification page on any device, sign in and enter this code:';

  @override
  String get calendarConnectOpenPage => 'Open verification page';

  @override
  String get calendarConnectWaiting => 'Waiting for approval…';

  @override
  String get calendarConnectDenied =>
      'Authorization was denied. Please try again.';

  @override
  String get calendarConnectExpired => 'The code expired. Please try again.';

  @override
  String get calendarNotConfigured =>
      'Google Calendar isn\'t configured. Set GOOGLE_OAUTH_CLIENT_ID to connect an account.';

  @override
  String get notificationMeetingStartsSoon => 'Meeting starting soon';

  @override
  String get notifyMeetingStartsSoon =>
      'When a calendar meeting is about to start';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendar disconnected';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconnect $email to resume syncing';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconnect your calendar to resume syncing';

  @override
  String get notifyCalendarAuthExpired =>
      'When a calendar account needs to be reconnected';

  @override
  String get notificationRigStatusChanged => 'Enclosure updates';

  @override
  String get notifyRigStatusChanged =>
      'When an enclosure is taken over, reclaimed or fails';

  @override
  String get notificationRigTakenOver => 'Enclosure taken over';

  @override
  String get notificationRigTakenOverBody =>
      'A person is driving the machine; the agent can watch but not act.';

  @override
  String get notificationRigReleased => 'Enclosure control released';

  @override
  String get notificationRigReleasedBody => 'The agent has the machine back.';

  @override
  String get notificationRigReclaimed => 'Enclosure reclaimed';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'It sat idle, so the machine was closed to free memory.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'It reached its time limit and was closed.';

  @override
  String get notificationRigFailed => 'Enclosure failed';

  @override
  String get notificationRigFailedBody =>
      'The hypervisor died underneath it. Re-open the machine to continue.';

  @override
  String get calendarAlertLeadTime => 'Alert lead time';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'How long before a meeting to alert you';

  @override
  String calendarConnectedAs(String email) {
    return 'Connected as $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count attendees';
  }

  @override
  String get calendarEventLabel => 'Event';

  @override
  String get calendarRecurring => 'Recurring event';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizer';

  @override
  String get calendarYou => 'You';

  @override
  String get calendarShowFewer => 'Show fewer';

  @override
  String get calendarRsvpAwaiting => 'Awaiting';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'See all $count participants';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count yes';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count no';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count maybe';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count awaiting';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutes';
  }

  @override
  String get openInEditorPrompt => 'Open in which editor?';

  @override
  String get ideNotInstalled => 'Not installed';

  @override
  String openInIde(String editor) {
    return 'Open in $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Couldn\'t open $editor: $error';
  }

  @override
  String get profileSearchHint => 'Search pull requests…';

  @override
  String get profileClickToLoad => 'Click to load';

  @override
  String get byAuthorPrefix => 'by';

  @override
  String get stopAgentRun => 'Stop run';

  @override
  String get stopAgentRunConfirm => 'Stop this run? Work in progress is lost.';

  @override
  String get youLabel => 'you';

  @override
  String get readyToMerge => 'Ready to merge';

  @override
  String get inProgress => 'In progress';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get drafts => 'Drafts';

  @override
  String get allOpenPrs => 'All open PRs';

  @override
  String showAllCount(int count) {
    return 'Show all $count';
  }

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortLargest => 'Largest';

  @override
  String get prFilterTooltip => 'Filter';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active filters',
      one: '1 active filter',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Add filter…';

  @override
  String get prFilterFieldHint => 'Filter…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Author';

  @override
  String get prFilterCategoryReviewer => 'Reviewers';

  @override
  String get prFilterCategoryContent => 'Content';

  @override
  String get prFilterCategoryRepoOwner => 'Repository owner';

  @override
  String get prFilterCategoryRepoName => 'Repository name';

  @override
  String get prFilterCategoryOpenedDate => 'Opened date';

  @override
  String get prFilterCategoryUpdatedDate => 'Updated date';

  @override
  String get prFilterQuickToReview => 'Quick to review';

  @override
  String get prFilterClearAll => 'Clear filters';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count options not matching any pull requests',
      one: '1 option not matching any pull requests',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Title or body contains…';

  @override
  String get prFilterNoOptions => 'No matching options';

  @override
  String get prFilterChipIs => 'is';

  @override
  String get prFilterChipIsAnyOf => 'is any of';

  @override
  String get prFilterChipContains => 'contains';

  @override
  String get prFilterChipSince => 'since';

  @override
  String get prFilterAddFilterButton => 'Add filter';

  @override
  String prFilterClearCategory(String category) {
    return 'Clear $category filter';
  }

  @override
  String get prFilterCurrentUser => 'Current user';

  @override
  String get prStatusDraft => 'Draft';

  @override
  String get prStatusOpen => 'Open';

  @override
  String get prStatusInReview => 'In review';

  @override
  String get prStatusChangesRequested => 'Changes requested';

  @override
  String get prStatusApproved => 'Approved';

  @override
  String get prStatusMerged => 'Merged';

  @override
  String get prStatusClosed => 'Closed';

  @override
  String get prDateWindowDay => '1 day ago';

  @override
  String get prDateWindowThreeDays => '3 days ago';

  @override
  String get prDateWindowWeek => '1 week ago';

  @override
  String get prDateWindowMonth => '1 month ago';

  @override
  String get prDateWindowThreeMonths => '3 months ago';

  @override
  String get prDateWindowSixMonths => '6 months ago';

  @override
  String get prDateWindowYear => '1 year ago';

  @override
  String get prDisplayOptions => 'Display options';

  @override
  String get prDisplayGrouping => 'Grouping';

  @override
  String get prDisplayOrdering => 'Ordering';

  @override
  String get prDisplayShowDrafts => 'Show drafts';

  @override
  String get prDisplayMergedWindow => 'Merged window';

  @override
  String get prDisplayMergedWindowDay => 'Past day';

  @override
  String get prDisplayMergedWindowWeek => 'Past week';

  @override
  String get prDisplayMergedWindowMonth => 'Past month';

  @override
  String get prDisplayProperties => 'Display properties';

  @override
  String get prGroupingRepository => 'Repository';

  @override
  String get prGroupingAuthor => 'Author';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'No grouping';

  @override
  String get prPropertyRepository => 'Repository';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Updated';

  @override
  String get prPropertyAuthor => 'Author';

  @override
  String get prPropertyChecks => 'Checks';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Comments';

  @override
  String get prGroupUnknownAuthor => 'Unknown author';

  @override
  String get keybindingOpenFilterMenu => 'Open filter menu';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Open the pull request filter menu';

  @override
  String get selectAction => 'Select';

  @override
  String mergeCountReady(int count) {
    return 'Merge $count ready';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Summary';

  @override
  String get openFullDiff => 'Open full diff';

  @override
  String get viewFiles => 'View files';

  @override
  String get checksLabel => 'Checks';

  @override
  String get commentsLabel => 'Comments';

  @override
  String get keybindingSelectPr => 'Select PR';

  @override
  String get keybindingMergePr => 'Merge PR';

  @override
  String get keybindingPeekPr => 'Peek PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Toggle selection of the focused pull request';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Merge the focused pull request if it\'s ready';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Expand or collapse the focused pull request\'s peek panel';

  @override
  String get kbMove => 'move';

  @override
  String get kbTabs => 'tabs';

  @override
  String get kbSearch => 'search';

  @override
  String get kbViewed => 'viewed';

  @override
  String get kbCollapse => 'collapse';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSettingsDescription => 'Theme, language and typography.';

  @override
  String get notificationsSettingsDescription =>
      'Choose which agent and workspace events notify you.';

  @override
  String get integrationsSettingsDescription =>
      'Connect GitHub, ticketing and the MCP server.';

  @override
  String get advanced => 'Advanced';

  @override
  String get advancedSettingsDescription =>
      'Branch naming, semantic search, server connection, system behavior and logging.';

  @override
  String get agentRegistry => 'Agent registry';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupAgents => 'Agents';

  @override
  String get settingsGroupResources => 'Resources';

  @override
  String get settingsGroupWorkspace => 'Workspace';

  @override
  String get settingsGroupSystem => 'System';

  @override
  String get settingsGroupIntegrations => 'Integrations';

  @override
  String get accounts => 'Accounts';

  @override
  String get accountsSettingsDescription =>
      'GitHub, ticketing, calendar and chat accounts.';

  @override
  String get mcpServers => 'MCP servers';

  @override
  String get mcpServersSettingsDescription =>
      'Built-in MCP server and external MCP servers.';

  @override
  String get remoteControlAndDevices => 'Remote control & devices';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Pair phones and configure the remote-control server.';

  @override
  String get voiceAndMeetings => 'Voice & meetings';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'The speech and diarization models this server hosts.';

  @override
  String get securityAndPrivacy => 'Security & privacy';

  @override
  String get securityAndPrivacySettingsDescription =>
      'Sandboxing, command rules and privacy.';

  @override
  String get filterSettingsHint => 'Filter settings';

  @override
  String get needsSetupLabel => 'Needs setup';

  @override
  String noSettingsMatch(String query) {
    return 'No settings match \"$query\"';
  }

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get filterChannelsHint => 'Filter channels';

  @override
  String noChannelsMatch(String query) {
    return 'No channels match \"$query\"';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get sendDiffContentTitle => 'Send diff content to AI adapter';

  @override
  String get diffSharingOnSubtitle =>
      'Raw diff lines are included in agent prompts for deeper review.';

  @override
  String get diffSharingOffSubtitle =>
      'Agents use only structured metadata (file paths, line numbers, PR description); no raw code leaves the app.';

  @override
  String get errorReportingTitle => 'Share crash reports';

  @override
  String get errorReportingOnSubtitle =>
      'Crash, error and performance diagnostics are sent to help fix bugs (release builds only).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostics are off. No crash or error reports are sent.';

  @override
  String get onboardingDiagnosticsTitle => 'Help improve Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Send crash, error and performance diagnostics so we can fix problems faster (release builds only). You can change this any time in Settings → Privacy.';

  @override
  String get blocked => 'Blocked';

  @override
  String get idle => 'Idle';

  @override
  String get noRunsYet => 'No runs yet';

  @override
  String runsInLastSixMonths(String count) {
    return '$count runs in the last 6 months';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Active $duration ago';
  }

  @override
  String get reportsToNobody => 'No manager';

  @override
  String get copyPath => 'Copy path';

  @override
  String get copyRelativePath => 'Copy relative path';

  @override
  String get pathCopied => 'Path copied to clipboard';

  @override
  String get editAgent => 'Edit agent';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get import => 'Import';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agent definitions found',
      one: '1 agent definition found',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'No new agents to import';

  @override
  String get noAgentsToDiscoverHint =>
      'Agent definitions in this workspace are already imported.';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Name';

  @override
  String get noMatchingAgents => 'No agents match your filter';

  @override
  String get selectAnAgentHint =>
      'Choose an agent to see its status, activity and details.';

  @override
  String watchVideoOn(String provider) {
    return 'Watch video on $provider';
  }

  @override
  String get branchTemplate => 'Branch name template';

  @override
  String get branchTemplateDescription =>
      'Pattern for the branch created when a ticket is started in an isolated worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Example: $example';
  }

  @override
  String get deletePipelineRun => 'Delete pipeline run';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Delete this run of \"$template\"? This cannot be undone.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Error deleting pipeline run: $error';
  }

  @override
  String get deleteTicket => 'Delete ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Error deleting ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Delete \"$name\"? Linked repositories on disk are not touched.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Error deleting workspace: $error';
  }

  @override
  String get indexCode => 'Index code';

  @override
  String get indexing => 'Indexing…';

  @override
  String get indexNoGrammars => 'Code grammars not installed';

  @override
  String get indexFailed => 'Indexing failed';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symbols indexed';
  }

  @override
  String get nodeConfigAdvanced => 'Advanced';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'How to merge when this output key already has a value';

  @override
  String get nodeConfigTimeoutMs => 'Timeout (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Retry attempts';

  @override
  String get nodeConfigContinueOnFail => 'Continue if this step fails';

  @override
  String get nodeConfigTeamId => 'Team ID';

  @override
  String get nodeConfigDispatchMode => 'Dispatch mode';

  @override
  String get nodeConfigOutputSchema => 'Output schema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema the step output must satisfy';

  @override
  String get diffLineDisplay => 'Long lines in diffs';

  @override
  String get diffLineDisplayDescription =>
      'Wrap long lines or scroll them horizontally';

  @override
  String get diffLineWrap => 'Wrap';

  @override
  String get diffLineScroll => 'Scroll horizontally';

  @override
  String get actions => 'Actions';

  @override
  String get activate => 'Activate';

  @override
  String get activity => 'Activity';

  @override
  String get activityLabel => 'ACTIVITY';

  @override
  String get activitySearchHint => 'Search activity';

  @override
  String get activityNoMatches => 'No activity matches your filters';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end of $total';
  }

  @override
  String get activityPreviousPage => 'Previous page';

  @override
  String get activityNextPage => 'Next page';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Clear filter';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Country $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Saved the workspace logo';

  @override
  String activityVerbCreated(String target) {
    return 'Created $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Updated $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Deleted $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Added $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Removed $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Invited $target';
  }

  @override
  String activityVerbRevoked(String target) {
    return 'Revoked $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Changed $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Started $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Stopped $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Wrote $target';
  }

  @override
  String get activityTargetAgent => 'agent';

  @override
  String get activityTargetTicket => 'ticket';

  @override
  String get activityTargetWorkspace => 'workspace';

  @override
  String get activityTargetRepository => 'repository';

  @override
  String get activityTargetMember => 'member';

  @override
  String get activityTargetInvite => 'invite';

  @override
  String get activityTargetChannel => 'channel';

  @override
  String get activityTargetMessage => 'message';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'file';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'template';

  @override
  String get activityTargetProvider => 'provider';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'skill';

  @override
  String get activityTargetTodo => 'to-do';

  @override
  String get activityTargetMeeting => 'meeting';

  @override
  String get activityTargetProject => 'project';

  @override
  String get activityTargetTeam => 'team';

  @override
  String get activityTargetDevice => 'device';

  @override
  String get activityTargetPreference => 'preference';

  @override
  String get activityTargetBudget => 'budget';

  @override
  String activityVerbApproved(String target) {
    return 'Approved $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Archived $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Assigned $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Backed up $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Cancelled $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Cleared $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Closed $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Committed $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Compacted $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Completed $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Connected $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Continued $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Disconnected $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Dispatched $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Drained $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Enrolled $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Estimated $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Imported $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Installed $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Killed $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Marked $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Merged $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Opened $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Paused $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Polled $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Prepared $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Processed $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Published $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Refined $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Refreshed $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Registered $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Renamed $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Reordered $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Responded to $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Restored $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Resumed $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Retried $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Reverted $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Reviewed $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Ran $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Selected $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Sent $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Staged $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Steered $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Submitted $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Synced $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Toggled $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Uninstalled $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Unstaged $target';
  }

  @override
  String get activityTargetActionPolicy => 'action policy';

  @override
  String get activityTargetGoalRun => 'goal run';

  @override
  String get activityTargetRunLog => 'run log';

  @override
  String get activityTargetWorkingMemory => 'working memory';

  @override
  String get activityTargetRoutingPolicy => 'routing policy';

  @override
  String get activityTargetAutonomy => 'autonomy';

  @override
  String get activityTargetCalendar => 'calendar';

  @override
  String get activityTargetChecker => 'checker';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'confirmation';

  @override
  String get activityTargetTunnel => 'tunnel';

  @override
  String get activityTargetConversation => 'conversation';

  @override
  String get activityTargetCredentials => 'credentials';

  @override
  String get activityTargetDictation => 'dictation';

  @override
  String get activityTargetAgentRun => 'agent run';

  @override
  String get activityTargetEvalSuite => 'eval suite';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'MCP server';

  @override
  String get activityTargetMemoryAccessGrant => 'memory access grant';

  @override
  String get activityTargetMemoryDomain => 'memory domain';

  @override
  String get activityTargetMemoryFact => 'memory fact';

  @override
  String get activityTargetMemoryPolicy => 'memory policy';

  @override
  String get activityTargetFeed => 'feed';

  @override
  String get activityTargetNote => 'note';

  @override
  String get activityTargetOrchestration => 'orchestration';

  @override
  String get activityTargetPipelineRun => 'pipeline run';

  @override
  String get activityTargetPipelineTrigger => 'pipeline trigger';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'review';

  @override
  String get activityTargetProcess => 'process';

  @override
  String get activityTargetProviderPolicy => 'provider policy';

  @override
  String get activityTargetReaction => 'reaction';

  @override
  String get activityTargetReviewChannel => 'review channel';

  @override
  String get activityTargetReviewStudio => 'review studio';

  @override
  String get activityTargetServerData => 'server data';

  @override
  String get activityTargetSoundscape => 'soundscape';

  @override
  String get activityTargetSession => 'session';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'ticket link';

  @override
  String get activityTargetTicketSync => 'ticket sync';

  @override
  String get activityTargetProfile => 'profile';

  @override
  String get activityTargetVoiceProfile => 'voice profile';

  @override
  String get activityTargetWeather => 'weather forecast';

  @override
  String get activityTargetWorkProduct => 'work product';

  @override
  String get activityChangedMemberRole => 'Changed a member\'s role';

  @override
  String get activityChangedMemberRepoAccess =>
      'Changed a member\'s repository access';

  @override
  String get activityUpdatedGitHubToken => 'Updated the GitHub token';

  @override
  String get activityRefreshedWeather => 'Refreshed the weather forecast';

  @override
  String get activitySetWeatherLocation => 'Set the weather location';

  @override
  String get activityClearedWeatherLocation => 'Cleared the weather location';

  @override
  String get activityMarkedAllArticlesRead => 'Marked all articles as read';

  @override
  String get activityMarkedArticleRead => 'Marked an article as read';

  @override
  String get activityUpdatedSavedArticle => 'Updated a saved article';

  @override
  String get activityTookOverSession => 'Took over the session';

  @override
  String get activityHandedBackSession => 'Handed back the session';

  @override
  String get activityCommittedAndPushed => 'Committed and pushed';

  @override
  String get activityBackedUpServer => 'Backed up the server data';

  @override
  String get activityMarkedChannelRead => 'Marked the channel as read';

  @override
  String get activityRespondedToInvitation =>
      'Responded to the event invitation';

  @override
  String get activityStartedCalendarConnect =>
      'Started the calendar connection';

  @override
  String get activityDisconnectedCalendar => 'Disconnected the calendar';

  @override
  String get activityMarkedFileViewed => 'Marked a file as viewed';

  @override
  String get activityRespondedToApproval => 'Responded to an approval request';

  @override
  String get activityChangedTunnel => 'Changed the tunnel setting';

  @override
  String get activitySentMessageToAgent => 'Sent a message to the agent';

  @override
  String get activityOpenedReviewChannel => 'Opened the review channel';

  @override
  String get activityOpenedMainConversation => 'Opened the main conversation';

  @override
  String get activityStartedRecording => 'Started the recording';

  @override
  String get activityStoppedRecording => 'Stopped the recording';

  @override
  String get activityToggledMcpServer => 'Toggled the MCP server';

  @override
  String get activityUpdatedMcpToken => 'Updated the MCP token';

  @override
  String get activitySavedApiKey => 'Saved an API key';

  @override
  String get activityRemovedProviderCredential =>
      'Removed a provider credential';

  @override
  String get activityUpdatedLinkedRepos => 'Updated the linked repositories';

  @override
  String get activityUnlinkedRepo => 'Unlinked a repository';

  @override
  String get activityUpdatedActionItem => 'Updated an action item';

  @override
  String adRulesCount(int count) {
    return '$count ad rules';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapters';

  @override
  String get adaptersAutoDetected =>
      'Auto-detected agent runners available on this machine. Install any missing CLI tools to enable additional runners.';

  @override
  String get add => 'Add';

  @override
  String get addAComment => 'Add a comment';

  @override
  String get addAReaction => 'Add a reaction';

  @override
  String get addASuggestion => 'Add a suggestion';

  @override
  String get addAgent => 'Add agent';

  @override
  String get addAgents => 'Add agents';

  @override
  String get addAgentsToEnable =>
      'Add agents to enable multi-agent orchestration';

  @override
  String get addEmoji => 'Add emoji';

  @override
  String get addFeed => 'Add feed';

  @override
  String get addressBarHint => 'Enter a URL';

  @override
  String get addFromFile => 'Add from file';

  @override
  String get addGif => 'Add GIF';

  @override
  String get addGithubRepoPrompt =>
      'Add at least one GitHub repository to see pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Add a local checkout to start targeting it from this workspace.';

  @override
  String get addRepository => 'Add repository';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add # repositories',
      one: 'Add repository',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Browse the folders on the machine running the server and select the git checkouts to register.';

  @override
  String get selectThisFolder => 'Select this folder';

  @override
  String get deselectThisFolder => 'Deselect this folder';

  @override
  String get goUp => 'Up';

  @override
  String get noSubfoldersHere => 'No subfolders here';

  @override
  String get notAGitRepository => 'This folder isn\'t a git repository.';

  @override
  String get addToken => 'Add token';

  @override
  String get addWorkspace => 'Add workspace';

  @override
  String get addWorkspaceEllipsis => 'Add workspace…';

  @override
  String get added => 'Added';

  @override
  String get addingEllipsis => 'Adding…';

  @override
  String get advancedLabel => 'Advanced';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Agent MD path';

  @override
  String get agentName => 'Agent name';

  @override
  String get agentTitle => 'Agent title';

  @override
  String get agentUpdated => 'Agent updated.';

  @override
  String get agents => 'Agents';

  @override
  String agentsCount(int count, num plural) {
    return 'Agents ($count)';
  }

  @override
  String get agentsMentionSection => 'Agents';

  @override
  String get usersMentionSection => 'People';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Meetings';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Meeting';

  @override
  String get aiReview => 'AI review';

  @override
  String get all => 'All';

  @override
  String get allAgentsAlreadyInChannel =>
      'All agents are already in this channel.';

  @override
  String get allCommits => 'All commits';

  @override
  String get allSessionsReset => 'All sandbox sessions reset.';

  @override
  String get allSources => 'All sources';

  @override
  String get allow => 'Allow';

  @override
  String get allowGitPush => 'Allow git push';

  @override
  String get allowGithubApi => 'Allow GitHub API calls';

  @override
  String get allowNetwork => 'Allow general network access';

  @override
  String get apiKeys => 'API keys';

  @override
  String get appFont => 'App font';

  @override
  String get appLogLevelDebugDescription =>
      'Adds detailed traces - for development.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Only unexpected errors and exceptions.';

  @override
  String get appLogLevelErrorLabel => 'Error';

  @override
  String get appLogLevelInfoDescription =>
      'Adds lifecycle and status messages.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'No console output at all.';

  @override
  String get appLogLevelNoneLabel => 'None';

  @override
  String get appLogLevelVerboseDescription =>
      'Everything. Extremely noisy - use for debugging only.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Adds warnings and recoverable issues.';

  @override
  String get appLogLevelWarningLabel => 'Warning';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Appearance & language';

  @override
  String get apply => 'Apply';

  @override
  String get approve => 'Approve';

  @override
  String get agentApprovalRequired => 'Approval required';

  @override
  String get approveAndCompact => 'Approve and compact context';

  @override
  String get approveAndExecute => 'Approve and execute';

  @override
  String get approveAndHire => 'Approve & hire';

  @override
  String get approved => 'Approved';

  @override
  String get articlesSubscribed => 'Articles across your subscribed feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Ask AI review';

  @override
  String get askAiReviewDescription => 'Ask AI to review this PR';

  @override
  String get askAnything =>
      'Ask anything… (@ to mention agents, / for commands)';

  @override
  String get assignees => 'Assignees';

  @override
  String get attachFiles => 'Attach files';

  @override
  String get attachImage => 'Attach image';

  @override
  String get attachedAgents => 'Attached agents';

  @override
  String get audioInput => 'Audio input';

  @override
  String get authentication => 'Authentication';

  @override
  String get authenticationToken => 'Authentication token';

  @override
  String authoredByLabel(String role) {
    return 'By: $role';
  }

  @override
  String get authorsLabel => 'Authors';

  @override
  String authorsWithCount(int count) {
    return 'Authors · $count';
  }

  @override
  String get autoRecommended => 'Auto (recommended)';

  @override
  String get available => 'Available';

  @override
  String get awaitingYourApproval => 'Awaiting your approval';

  @override
  String get awaitingYourReview => 'Awaiting your review';

  @override
  String get back => 'Back';

  @override
  String get backLabel => 'Back';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription => 'Block ads, trackers & cookie banners';

  @override
  String get blockAdsTrackers => 'Block ads, trackers & cookie banners';

  @override
  String get blocking => 'Blocking';

  @override
  String get bookmarkLabel => 'Bookmark';

  @override
  String get briefDescription => 'Brief description';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Bundled defaults — never updated';

  @override
  String get cached => 'Cached';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelEdit => 'Cancel edit';

  @override
  String get categoryCreation => 'Creation';

  @override
  String get categoryDeletion => 'Category deletion';

  @override
  String get categoryEditing => 'Editing';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Category view';

  @override
  String get change => 'Change';

  @override
  String get changesRequested => 'Changes requested';

  @override
  String get changesSummary => 'Changes summary';

  @override
  String get channelsMentionSection => 'Channels';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checking => 'Checking';

  @override
  String get checkingEllipsis => 'Checking…';

  @override
  String get checkingGhCli => 'Checking gh CLI…';

  @override
  String get chooseAppFont => 'Choose app font';

  @override
  String get chooseCodeFont => 'Choose code font';

  @override
  String get chooseRunner => 'Choose your agent runner.';

  @override
  String get clear => 'Clear';

  @override
  String get clickToRetry => 'Click to retry';

  @override
  String get close => 'Close';

  @override
  String get closeEsc => 'Close (Esc)';

  @override
  String get closeKeyboardHint => 'Close';

  @override
  String get closePanel => 'Close panel';

  @override
  String get closeReader => 'Close reader';

  @override
  String get closed => 'Closed';

  @override
  String get codeFont => 'Code font';

  @override
  String get codeFontLigatures => 'Code font ligatures';

  @override
  String get codeFontLigaturesDescription =>
      'Render programming ligatures (=>, !=, ->) as combined glyphs in code and diffs';

  @override
  String get collapse => 'Collapse';

  @override
  String get commandPalette => 'Command palette';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Conversation compacted. Earlier history was folded into a summary.';

  @override
  String get compactNothing =>
      'Nothing to compact yet. The conversation is still short.';

  @override
  String get compactBusy =>
      'An agent is still working. Compact when the turn finishes.';

  @override
  String get compactUnavailable => 'Compaction is unavailable on this server.';

  @override
  String get commandsMentionSection => 'Commands';

  @override
  String get comment => 'Comment';

  @override
  String get commentOnFile => 'Comment on this file';

  @override
  String get commentOnThisFile => 'Comment on this file';

  @override
  String get commentSelected => 'Comment selected';

  @override
  String get commented => 'Commented';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Showing latest $loaded of $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Cloning repository';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'This PR changes $fileCount files, which exceeds GitHub\'s API limit. Cloning the repository locally…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'This PR exceeds GitHub\'s API file limit. Cloning the repository locally…';

  @override
  String get prCloneProgressFetchingTitle => 'Fetching PR refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Fetching the base branch and PR head ref…';

  @override
  String get prCloneProgressComputingTitle => 'Computing diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Running git diff locally…';

  @override
  String get prCloneProgressErrorTitle => 'Failed to load diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'An error occurred while cloning or computing the diff. Please try refreshing.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Still working… $elapsed elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confidence: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configure agent identities, prompts, skills and view runs.';

  @override
  String get configureDefaultRunners =>
      'Configure which adapter and model are used for new channels and title generation.';

  @override
  String get configuredLabel => 'Configured.';

  @override
  String get confirmedBy => 'Confirmed by';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentBlockingDescription =>
      'Block ads, trackers and cookie banners';

  @override
  String get contentHint => 'What should be remembered';

  @override
  String get contentLabel => 'Content';

  @override
  String get contentMarkdown => 'Content (Markdown)';

  @override
  String get contextWindowSize => 'Context window size';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get conversationMode => 'Mode';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie rules';
  }

  @override
  String get copied => 'Copied!';

  @override
  String get copy => 'Copy';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get copyBaseBranchTooltip => 'Copy base branch name';

  @override
  String get copyHeadBranchTooltip => 'Copy head branch name';

  @override
  String get couldNotCheckGhCli => 'Could not check gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'Could not list devices: $error';
  }

  @override
  String get create => 'Create';

  @override
  String get createFirstAgent => 'Create your first agent to get started.';

  @override
  String get createOrSelectWorkspace =>
      'Create or select a workspace before adding repositories.';

  @override
  String get createPr => 'Create PR';

  @override
  String get createPullRequest => 'Create pull request';

  @override
  String get createdByMe => 'Created by me';

  @override
  String createdLabel(String date) {
    return 'Created: $date';
  }

  @override
  String get currentParticipants => 'Current participants';

  @override
  String get customCapabilitiesDescription => 'Custom capabilities description';

  @override
  String get customSystemPrompt => 'Custom system prompt for this agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deactivate';

  @override
  String get defaultCapabilities => 'Default capabilities · new channels';

  @override
  String get defaultChat => 'Default chat';

  @override
  String defaultPortHint(int port) {
    return 'Default: $port.';
  }

  @override
  String get defaultRunners => 'Default runners';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAgent => 'Delete agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get deleteChannel => 'Delete channel';

  @override
  String deleteConfirmName(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteConversation => 'Delete channel';

  @override
  String get deleteConversationConfirm =>
      'Delete this channel? All messages will be lost.';

  @override
  String get deleteFact => 'Delete fact';

  @override
  String get deleteFeedBody =>
      'This removes the feed and all its cached articles. Bookmarked articles from this feed will also be removed.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteNamedConversation(String name) {
    return 'Delete \"$name\"? All messages will be lost.';
  }

  @override
  String get deletePolicy => 'Delete policy';

  @override
  String get deletePolicyConfirm =>
      'Delete this policy? This cannot be undone.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Delete \"$topic\"? This cannot be undone.';
  }

  @override
  String get deleteWorkspace => 'Delete workspace';

  @override
  String get deny => 'Deny';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get detailsLabel => 'Details';

  @override
  String detectedBackend(String label) {
    return 'Detected: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Detected runners ($count)';
  }

  @override
  String get detectingAdapters => 'Detecting adapters…';

  @override
  String get detectingGhCli => 'Detecting gh CLI…';

  @override
  String get detectingInputDevices => 'Detecting input devices…';

  @override
  String detectionFailed(String error) {
    return 'Detection failed: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff failed: $message';
  }

  @override
  String get disabled => 'Disabled';

  @override
  String get discover => 'Discover';

  @override
  String get discoverAgents => 'Discover agents';

  @override
  String get discoverAgentsDescription =>
      'Agent discovery scans workspace paths for AGENTS.md and TEAM.md files, parsing them into the agent registry.\n\nConfigure a workspace first, then use this feature to auto-populate agents.';

  @override
  String get dismissed => 'Dismissed';

  @override
  String get domainHint => 'e.g. api-performance';

  @override
  String get domainLabel => 'Domain';

  @override
  String get download => 'Download';

  @override
  String get downloadingLabel => 'Downloading';

  @override
  String downloadingModel(int pct) {
    return 'Downloading model… $pct%';
  }

  @override
  String get draft => 'Draft';

  @override
  String get draftLabel => 'Draft';

  @override
  String get edit => 'Edit';

  @override
  String get edited => 'edited';

  @override
  String get editMessage => 'Edit message';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deleteMessageConfirm =>
      'Delete this message? This can\'t be undone.';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get searchInConversation => 'Search in conversation';

  @override
  String get searchMessagesHint => 'Search messages…';

  @override
  String get noMessagesFound => 'No messages found';

  @override
  String get editFact => 'Edit fact';

  @override
  String get editPolicy => 'Edit policy';

  @override
  String get editSuggestedCodeHint => 'Edit suggested code…';

  @override
  String get editSuggestion => 'Edit suggestion';

  @override
  String get editTheSuggestedCodeHint => 'Edit the suggested code…';

  @override
  String get egArchitect => 'e.g. architect';

  @override
  String get egControlCenter => 'e.g. control-center';

  @override
  String get egPlatform => 'e.g. macOS';

  @override
  String get egSamuelAlev => 'e.g. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'e.g. Software Architect';

  @override
  String get egTheVerge => 'e.g. The Verge';

  @override
  String get egTokenLimit => 'e.g. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get embeddingInstalled =>
      'Local embedding model installed. Hybrid search is enabled.';

  @override
  String get embeddingModel => 'Embedding model (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Not installed. Search falls back to keyword-only until enabled.';

  @override
  String get embeddingRedownloadBody =>
      'The existing model files will be deleted and downloaded again. Semantic search will be unavailable until the download completes.';

  @override
  String get embeddingRemoveBody =>
      'Semantic search will be disabled until you reinstall it. You can install it again at any time.';

  @override
  String get speakerDiarization => 'Speaker diarization';

  @override
  String get diarizationModel => 'Diarization model';

  @override
  String get diarizationInstalled =>
      'Installed — names individual speakers in meeting transcripts';

  @override
  String get diarizationNotInstalled =>
      'Not installed — meeting speakers won\'t be separated';

  @override
  String diarizationInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Re-download diarization model';

  @override
  String get diarizationRedownloadBody =>
      'This removes the current diarization models and downloads them again.';

  @override
  String get removeDiarizationModel => 'Remove diarization model';

  @override
  String get diarizationRemoveBody =>
      'This deletes the on-device diarization models. Meeting transcripts already produced are unaffected.';

  @override
  String get enableMcpServer => 'Enable MCP server';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableSandboxing => 'Enable sandboxing';

  @override
  String get enabled => 'Enabled';

  @override
  String enterToken(String name) {
    return 'Enter $name Token';
  }

  @override
  String get enterTokenToAuth => 'Enter a token to require authentication';

  @override
  String errorCreatingAgent(String error) {
    return 'Error creating agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Error deleting agent: $error';
  }

  @override
  String get errorLoadingAgents => 'Error loading agents';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get errored => 'Errored';

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get expand => 'Expand';

  @override
  String get extractingLabel => 'Extracting';

  @override
  String extractingModel(int pct) {
    return 'Extracting model… $pct%';
  }

  @override
  String get fact => 'Fact';

  @override
  String factCount(int count) {
    return '$count fact';
  }

  @override
  String factCountPlural(int count) {
    return '$count facts';
  }

  @override
  String get facts => 'Facts';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount facts · $policyCount policies';
  }

  @override
  String get failed => 'Failed';

  @override
  String failedToDispatch(String error) {
    return 'Failed to dispatch: $error';
  }

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String failedToLoadAgents(String error) {
    return 'Failed to load agents: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Failed to load feeds: $error';
  }

  @override
  String get failedToLoadGifs => 'Failed to load GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Failed to load logs: $error';
  }

  @override
  String get failedToLoadRepos => 'Failed to load repositories';

  @override
  String get failedToLoadWorkspaces => 'Failed to load workspaces';

  @override
  String failedToStartAiReview(String error) {
    return 'Failed to start AI review: $error';
  }

  @override
  String get failedToStartMicTest => 'Failed to start mic test.';

  @override
  String failedToSubmitReview(String error) {
    return 'Failed to submit review: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Failed to upload $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Failed: $error';
  }

  @override
  String get failure => 'Failure';

  @override
  String get feedAlreadyExists => 'A feed with this URL already exists.';

  @override
  String get feedUrl => 'Feed URL';

  @override
  String get feedUrlExample => 'e.g. https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'A feed with this URL already exists.';

  @override
  String get feedUrlLabel => 'Feed URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

  @override
  String get filesChanged => 'Files changed';

  @override
  String filesCount(int count) {
    return '$count file(s)';
  }

  @override
  String get filesMentionSection => 'Files';

  @override
  String get filterAgents => 'Filter agents...';

  @override
  String get filterAgentsPlaceholder => 'Filter agents…';

  @override
  String get filterFilesHint => 'Filter files…';

  @override
  String get filterLists => 'Filter lists';

  @override
  String get filterSkillsPlaceholder => 'Filter skills…';

  @override
  String get finish => 'Finish';

  @override
  String get fix => 'Fix';

  @override
  String get fixSelected => 'Fix selected';

  @override
  String get forward => 'Forward';

  @override
  String get gatesGithubPatPush =>
      'Gates GitHub PAT injection. Required for the agent to push.';

  @override
  String get general => 'General';

  @override
  String get generalSettingsDescription =>
      'Appearance, typography, integrations and MCP server.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI is authenticated and ready, but a personal access token is set below and will be used instead. Clear the PAT to use gh CLI auth.';

  @override
  String get ghCliInstalledAuth =>
      'Installed. Run `gh auth login`, then tap Refresh.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI not installed — install from cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI not installed';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'GitHub CLI integration';

  @override
  String get githubCliReady => 'GitHub CLI is authenticated and ready.';

  @override
  String get githubLink => 'GitHub link';

  @override
  String get githubPersonalAccessToken => 'GitHub personal access token';

  @override
  String get claudeStatusFetchFailed => 'Couldn\'t reach status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Open status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Couldn\'t reach githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub is reporting problems';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub status: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub status: $status. Pull request data may be stale or incomplete until it recovers.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Open githubstatus.com';

  @override
  String get githubStatusRefresh => 'Refresh';

  @override
  String githubStatusUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Couldn\'t reach status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Open status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => 'Couldn\'t reach status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Open status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Maintenance';

  @override
  String get serviceStatusMajorIssues => 'Major issues';

  @override
  String get serviceStatusMinorIssues => 'Minor issues';

  @override
  String get serviceStatusOperational => 'Operational';

  @override
  String get serviceStatusOutage => 'Outage';

  @override
  String get serviceStatusTitle => 'Service status';

  @override
  String get serviceStatusUnknown => 'Unknown';

  @override
  String lastChecked(String time) {
    return 'Checked $time';
  }

  @override
  String get lastCheckedRecently => 'Checked recently';

  @override
  String get githubToken => 'GitHub token';

  @override
  String get giveYourWorkAHome => 'Give your work a home.';

  @override
  String get goBack => 'Go back';

  @override
  String get goForward => 'Go forward';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get hideContainerTerminal => 'Hide container terminal';

  @override
  String get hideConversationChanges => 'Hide changes';

  @override
  String get showConversationChanges => 'Show changes';

  @override
  String get noConversationChanges =>
      'No uncommitted changes in this channel yet.';

  @override
  String get conversationChangesTitle => 'Changes';

  @override
  String get high => 'High';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Images';

  @override
  String get inactive => 'Inactive';

  @override
  String get install => 'Install';

  @override
  String get installGhCliBody =>
      'Install gh from https://cli.github.com/ and run `gh auth login`, then tap Refresh.';

  @override
  String get installRequired => 'Installation required';

  @override
  String get installedNotSignedIn => 'Installed - not signed in';

  @override
  String installedVersion(String version) {
    return 'Installed $version';
  }

  @override
  String get integrations => 'Integrations';

  @override
  String get invite => 'Invite';

  @override
  String get inviteAgent => 'Invite agent';

  @override
  String get isolateAgentExecution => 'Isolate agent execution.';

  @override
  String get justNow => 'Just now';

  @override
  String get keepSandboxing => 'Keep sandboxing';

  @override
  String get keybindingAdapters => 'Adapters';

  @override
  String get keybindingAddARepositoryDescription => 'Add a repository';

  @override
  String get keybindingAddRepository => 'Add repository';

  @override
  String get keybindingAgents => 'Agents';

  @override
  String get keybindingApprove => 'Approve';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Approve the peer review';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Bookmark or unbookmark the selected article';

  @override
  String get keybindingCommandPalette => 'Command palette';

  @override
  String get keybindingConversationTab => 'Overview tab';

  @override
  String get keybindingCreateANewAgentDescription => 'Create a new agent';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Create a new workspace';

  @override
  String get keybindingDeleteAgent => 'Delete agent';

  @override
  String get keybindingDeleteChannel => 'Delete channel';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Delete the selected agent';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Delete the selected channel';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Delete the selected workspace';

  @override
  String get keybindingDeleteWorkspace => 'Delete workspace';

  @override
  String get keybindingFilesChangedTab => 'Diff tab';

  @override
  String get keybindingFocusSearch => 'Focus search';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Focus the pull request search field';

  @override
  String get keybindingGeneral => 'General';

  @override
  String get keybindingGoToAgents => 'Go to Agents';

  @override
  String get keybindingGoToInbox => 'Go to Inbox';

  @override
  String get keybindingGoToMemory => 'Go to Memory';

  @override
  String get keybindingGoToNewsfeed => 'Go to Newsfeed';

  @override
  String get keybindingGoToPipelines => 'Go to Pipelines';

  @override
  String get keybindingGoToPullRequests => 'Go to Pull Requests';

  @override
  String get keybindingGoToTickets => 'Go to Tickets';

  @override
  String get keybindingKeybindings => 'Keybindings';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Navigate to the agents registry';

  @override
  String get keybindingNavigateToTheInboxDescription => 'Navigate to the inbox';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Navigate to the memory knowledge base';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Navigate to the newsfeed';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Navigate to the pipelines list';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Navigate to the pull request list';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Navigate to the tickets board';

  @override
  String get keybindingNewAgent => 'New agent';

  @override
  String get keybindingNewWorkspace => 'New workspace';

  @override
  String get keybindingNextArticle => 'Next article';

  @override
  String get keybindingNextChannel => 'Next channel';

  @override
  String get keybindingNextPr => 'Next PR';

  @override
  String get keybindingNextWorkspace => 'Next workspace';

  @override
  String get keybindingOpenArticle => 'Open article';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Open or close the workspace switcher popup in the sidebar';

  @override
  String get keybindingOpenPr => 'Open PR';

  @override
  String get keybindingOpenSettings => 'Open settings';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Open the Adapters settings page';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Open the Agents settings page';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Open the application settings';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Open the command palette';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Open the General settings page';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Open the Keybindings settings page';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Open the Repositories settings page';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Open the selected article';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Open the selected pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Open the selected workspace';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Open the Skills settings page';

  @override
  String get keybindingOpenWorkspace => 'Open workspace';

  @override
  String get keybindingPreviousArticle => 'Previous article';

  @override
  String get keybindingPreviousChannel => 'Previous channel';

  @override
  String get keybindingPreviousPr => 'Previous PR';

  @override
  String get keybindingPreviousWorkspace => 'Previous workspace';

  @override
  String get keybindingRefresh => 'Refresh';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Refresh all feeds';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Refresh the pull request list';

  @override
  String get keybindingRemoveRepository => 'Remove repository';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Remove the selected repository';

  @override
  String get keybindingRepositories => 'Repositories';

  @override
  String get keybindingRequestChanges => 'Request changes';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Request changes on the peer review';

  @override
  String get keybindingRescanForAdaptersDescription => 'Rescan for adapters';

  @override
  String get keybindingSearchInDiff => 'Search in diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Search within the diff view';

  @override
  String get keybindingToggleViewed => 'Toggle viewed';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Mark the focused file as viewed or unviewed';

  @override
  String get keybindingToggleCollapse => 'Toggle collapse';

  @override
  String get keybindingShowFileList => 'Show file list';

  @override
  String get keybindingShowFileListDescription =>
      'Switch the diff sidebar back to the file tree';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Collapse or expand the focused file';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Select the next article';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Select the next channel';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Select the next pull request';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Select the previous article';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Select the previous channel';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Select the previous pull request';

  @override
  String get keybindingSendMessage => 'Send message';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Send the current message';

  @override
  String get keybindingSkills => 'Skills';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Switch between light and dark mode';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Switch to the overview tab';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Switch to the eighth workspace';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Switch to the fifth workspace';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Switch to the diff tab';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Switch to the first workspace';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Switch to the fourth workspace';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Switch to the next workspace';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Switch to the ninth workspace';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Switch to the previous workspace';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Switch to the second workspace';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Switch to the seventh workspace';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Switch to the sixth workspace';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Switch to the third workspace';

  @override
  String get keybindingToggleBookmark => 'Toggle bookmark';

  @override
  String get keybindingToggleTheme => 'Toggle theme';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Toggle workspace switcher';

  @override
  String get keybindingWorkspace1 => 'Workspace 1';

  @override
  String get keybindingWorkspace2 => 'Workspace 2';

  @override
  String get keybindingWorkspace3 => 'Workspace 3';

  @override
  String get keybindingWorkspace4 => 'Workspace 4';

  @override
  String get keybindingWorkspace5 => 'Workspace 5';

  @override
  String get keybindingWorkspace6 => 'Workspace 6';

  @override
  String get keybindingWorkspace7 => 'Workspace 7';

  @override
  String get keybindingWorkspace8 => 'Workspace 8';

  @override
  String get keybindingWorkspace9 => 'Workspace 9';

  @override
  String get keybindings => 'Keybindings';

  @override
  String get keybindingsDescription =>
      'All keyboard shortcuts. Shortcuts are fixed and cannot be reassigned.';

  @override
  String get killRunning => 'Kill running';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY not configured';

  @override
  String get klipyNotConfiguredHint =>
      'Pass --dart-define=KLIPY_APP_KEY=...\nor set it in .env before running.';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'System';

  @override
  String get latestLabel => 'Latest';

  @override
  String get leaveACommentEllipsis => 'Leave a comment…';

  @override
  String get legendLabel => 'Legend';

  @override
  String get lessLabel => 'Less';

  @override
  String get letsPluginTools => 'Let\'s plug in your tools.';

  @override
  String get level => 'Level';

  @override
  String get loadingAgents => 'Loading agents…';

  @override
  String get loadingModels => 'Loading models…';

  @override
  String get loadingProviders => 'Loading providers…';

  @override
  String get logLevel => 'Log level';

  @override
  String get logs => 'Logs';

  @override
  String get low => 'Low';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get manageParticipants => 'Manage participants';

  @override
  String get createTicketFromConversation => 'Create ticket from channel';

  @override
  String get manageWorkspaces => 'Manage workspaces';

  @override
  String get reorderWorkspace => 'Reorder workspace';

  @override
  String get masterToggle => 'Master toggle';

  @override
  String get matchOsAppearance =>
      'Match your OS appearance or pick a fixed mode.';

  @override
  String get mcpActiveAccepting =>
      'MCP server is active and accepting connections.';

  @override
  String get mcpAuthToken => 'MCP authentication token';

  @override
  String get mcpAuthentication => 'Authentication';

  @override
  String get mcpAutoStartDescription =>
      'When off, the server stays stopped until you start it.';

  @override
  String mcpDefaultPort(int port) {
    return 'Default: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Listening on 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Listening on port $port, shared with cc_server.';
  }

  @override
  String get mcpNotAvailableOnServer =>
      'MCP server control is not available on the connected server.';

  @override
  String get modelManagedOnServer =>
      'This model runs on the server host and is managed there.';

  @override
  String get mcpNotRunning =>
      'Server is not running. Start it to enable MCP connections.';

  @override
  String get mcpRestartPortChanges =>
      'Server must be restarted to apply port changes.';

  @override
  String get mcpServer => 'MCP server';

  @override
  String get mcpServerStopped => 'Server is stopped';

  @override
  String get mcpStatus => 'Status';

  @override
  String get medium => 'Medium';

  @override
  String get memoryDataHint =>
      'Facts and policies will appear here as agents work.';

  @override
  String get memoryLabel => 'Memory';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Merged';

  @override
  String get messagePlaceholder => 'Message… (@ to mention, / for commands)';

  @override
  String get navConversations => 'Channels';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Modified';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String get more => 'More';

  @override
  String get moreLabel => 'More';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Name';

  @override
  String get nameAndTitleRequired => 'Name and title are required.';

  @override
  String get nameAndUrlRequired => 'Name and URL required';

  @override
  String get nameLabel => 'Name';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Native sandbox is available on $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Native sandbox installation required';

  @override
  String get navObservability => 'Observability';

  @override
  String get navSaved => 'Saved';

  @override
  String get navSettings => 'Settings';

  @override
  String get navigateLabel => 'Navigate';

  @override
  String networkBlockCount(int count) {
    return '$count network blocks';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newAgent => 'New agent';

  @override
  String get newCommitsPushed =>
      'New commits were pushed — click to reload the diff';

  @override
  String get newFact => 'New fact';

  @override
  String get newLabel => 'New';

  @override
  String get newPolicy => 'New policy';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Manage your subscribed feeds and reader preferences.';

  @override
  String get newsfeedSettingsTitle => 'Newsfeed settings';

  @override
  String get nextMatch => 'Next match (↵)';

  @override
  String get noAccessGrants => 'No access grants configured';

  @override
  String get noActiveWorkspace => 'No active workspace or repo selected.';

  @override
  String get noActiveWorkspaceCreate => 'No active workspace';

  @override
  String get noActiveWorkspaceGithub =>
      'No active workspace with a GitHub repo.';

  @override
  String get noAgentAssigned => 'No agent assigned';

  @override
  String get noAgentProcessesRunning => 'No agent processes running';

  @override
  String get noAgents => 'No agents';

  @override
  String get noAgentsDiscovered => 'No agents discovered';

  @override
  String get noAgentsDiscoveredHint =>
      'Click \"Discover\" to scan for AGENTS.md files or \"Add Agent\" to configure one manually';

  @override
  String get noAgentsRegisteredYet => 'No agents registered yet';

  @override
  String get noArticlesYet => 'No articles yet';

  @override
  String get noArticlesYetBody => 'Articles from your feeds will appear here.';

  @override
  String get noData => 'No data';

  @override
  String get noDomains => 'No domains yet';

  @override
  String get noExecutionLogsYet => 'No execution logs yet';

  @override
  String get noFacts => 'No facts yet';

  @override
  String get noFeedsYet => 'No feeds yet';

  @override
  String get noFileAnchor => 'No file anchor — cannot post inline comment.';

  @override
  String get noFileChangesInScope => 'No file changes in this scope';

  @override
  String get noGifsFound => 'No GIFs found';

  @override
  String get noInputDevicesDetected =>
      'No input devices detected — using system default.';

  @override
  String get noMatchingFiles => 'No matching files';

  @override
  String get noMatchingGoogleFonts => 'No matching Google Fonts.';

  @override
  String get noMemoryData => 'No memory data yet';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noModelsAdvertised => 'No models advertised by this adapter.';

  @override
  String get noOpenPullRequests => 'No open pull requests';

  @override
  String get noPolicies => 'No policies yet';

  @override
  String get noReposInWorkspaceYet => 'No repositories in this workspace yet';

  @override
  String get noRunnersDetected =>
      'No runners detected yet. Refresh to scan again.';

  @override
  String get noSavedArticles => 'No saved articles';

  @override
  String get noSavedArticlesBody => 'Articles you save will appear here.';

  @override
  String noShortcutsMatch(String query) {
    return 'No shortcuts match \"$query\"';
  }

  @override
  String get noSystemFonts => 'No system fonts detected.';

  @override
  String get noTokenSet => 'No token set — access is unrestricted.';

  @override
  String get noTokenSetUnrestricted => 'No token set — access is unrestricted.';

  @override
  String get noTokenUnrestricted => 'No token — access is unrestricted';

  @override
  String get noWorkingMemory => 'No working memory notes yet.';

  @override
  String get noneAllRoles => 'None (all roles)';

  @override
  String get notAvailable => 'Not available';

  @override
  String get notConfiguredLabel => 'Not configured.';

  @override
  String get notDetected => 'Not detected';

  @override
  String get notFoundLabel => 'Not found';

  @override
  String get notes => 'Notes';

  @override
  String get notificationAgentFinished => 'Agent finished';

  @override
  String get notificationPrMentioned => 'Mentioned in pull request';

  @override
  String get notificationNewMessages => 'New messages';

  @override
  String get notificationPrMerged => 'PR merged';

  @override
  String get notificationPrPublished => 'PR published';

  @override
  String get notificationReviewRequested => 'Review requested';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyAgentRunCompleted => 'Notify when an agent completes a run.';

  @override
  String get notifyPrMentioned =>
      'Notify when you\'re mentioned in a pull request.';

  @override
  String get notifyNewMessages =>
      'Notify on new agent messages in other channels.';

  @override
  String get notifyPrMerged => 'Notify when a pull request is merged.';

  @override
  String get notifyPrPublished =>
      'Notify when an agent publishes a pull request.';

  @override
  String get notifyReviewRequested =>
      'Notify when your review is requested on a pull request.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center can use Linux containers to isolate agent execution.';

  @override
  String get onboardingMacosDescription =>
      'Control Center uses native sandbox on macOS to isolate agent execution.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox is not available on this platform. Agent execution will be without isolation.';

  @override
  String get openApplicationSettings => 'Open application settings';

  @override
  String get openArticlesBrowserFallback => 'Open article in browser';

  @override
  String get openArticlesInApp => 'Open articles in app';

  @override
  String get openContainerTerminal => 'Open container terminal';

  @override
  String get openFolder => 'Open folder';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get openLabel => 'Open';

  @override
  String get openOnGithub => 'Open on GitHub';

  @override
  String get openStatus => 'Open';

  @override
  String get optionalPersonaDescription => 'Optional persona description';

  @override
  String get otherLabel => 'Other';

  @override
  String get ownerOrganization => 'Owner / Organization';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Parsing diff…';

  @override
  String get passed => 'Passed';

  @override
  String get pasteTokenHere => 'Paste token here';

  @override
  String get pasteValueHere => 'Paste value here';

  @override
  String get patNotNeededGhCli => 'Not needed — gh CLI is signed in.';

  @override
  String get patOverridesGhCli => 'Configured — overrides gh CLI.';

  @override
  String get pathLabel => 'Path';

  @override
  String get pendingApproval => 'Pending your approval';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (optional)';

  @override
  String get personalAccessTokenOptional => 'Personal access token (optional)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Policies';

  @override
  String get policiesHint =>
      'Policies will appear here once agents promote facts.';

  @override
  String get policy => 'Policy';

  @override
  String get popular => 'Popular';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Posting…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'PR description in markdown...';

  @override
  String get prDraftCreated => 'PR draft created';

  @override
  String get prMergedBody => 'A pull request was merged';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR title';

  @override
  String get previewLabel => 'Preview';

  @override
  String get previousArticle => 'Previous article';

  @override
  String get previousChannel => 'Previous channel';

  @override
  String get previousMatch => 'Previous match (⇧↵)';

  @override
  String get previousPr => 'Previous PR';

  @override
  String get previousWorkspace => 'Previous workspace';

  @override
  String get priorityReviewsDescription =>
      'Priority reviews and repository overview.';

  @override
  String get proposeToCreateDomain => 'Propose a fact or policy to create one.';

  @override
  String get prsCreated => 'PRs created';

  @override
  String get prsMerged => 'PRs merged';

  @override
  String get publishToGithub => 'Publish to GitHub';

  @override
  String get published => 'Published';

  @override
  String get pullRequestApproved => 'Pull request approved';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get queued => 'Queued';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata =>
      'Lets the agent read PRs, issues and repo metadata.';

  @override
  String get readerPreferences => 'Reader preferences';

  @override
  String get reasoningEffort => 'Reasoning effort';

  @override
  String get recommendLabel => 'RECOMMEND';

  @override
  String recordingFromDevice(String device) {
    return 'Recording from $device.';
  }

  @override
  String get redownload => 'Redownload';

  @override
  String get redownloadEmbeddingModel => 'Redownload the embedding model?';

  @override
  String get redownloadVoiceModel => 'Redownload the voice model?';

  @override
  String get refinePlan => 'Refine plan';

  @override
  String get refiningPlan => 'Refining plan…';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshAll => 'Refresh all';

  @override
  String get refreshAllFeeds => 'Refresh all feeds';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get refreshPrData => 'Refresh PR data';

  @override
  String get reject => 'Reject';

  @override
  String get rejected => 'Rejected';

  @override
  String get reload => 'Reload';

  @override
  String get remove => 'Remove';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get removeEmbeddingModel => 'Remove the embedding model?';

  @override
  String get removeLogo => 'Remove logo';

  @override
  String get removeRepoFromWorkspace => 'Remove repository from workspace?';

  @override
  String get removeRepository => 'Remove repository';

  @override
  String get removeRepositoryConfirm => 'Remove repository from workspace?';

  @override
  String get removeVoiceModel => 'Remove the voice model?';

  @override
  String get removed => 'Removed';

  @override
  String get renamed => 'Renamed';

  @override
  String get reopen => 'Reopen';

  @override
  String get resolve => 'Resolve';

  @override
  String get replyEllipsis => 'Reply…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name will be removed from this workspace. The local files on disk are not touched.';
  }

  @override
  String get reportsTo => 'Reports to';

  @override
  String get reportsToOptional => 'Reports to (optional)';

  @override
  String reposCount(int count) {
    return 'Repositories ($count)';
  }

  @override
  String get reposDescription => 'The local checkouts this workspace targets.';

  @override
  String get repositories => 'Repositories';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositories',
      one: '1 repository',
    );
    return 'Couldn\'t add $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositories added',
      one: 'Repository added',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Repositories settings';

  @override
  String get repositoryName => 'Repository name';

  @override
  String get requestChanges => 'Request changes';

  @override
  String get requested => 'Requested';

  @override
  String get requestedChanges => 'Requested changes';

  @override
  String get requiredIfGhCliUnavailable =>
      'Required if gh CLI is not available';

  @override
  String requiredRoleLabel(String role) {
    return 'Required role: $role';
  }

  @override
  String get requiredRoleOptional => 'Required role (optional)';

  @override
  String get requirements => 'Requirements';

  @override
  String get reset => 'Reset';

  @override
  String get resetAllSandboxes => 'Reset all sandboxes';

  @override
  String get resolved => 'Resolved';

  @override
  String get restartServerToApply => 'Restart the server to apply changes.';

  @override
  String get enclosedTerminalTitle => 'Enclosed terminal';

  @override
  String get enclosedTerminalStart => 'Open the shell';

  @override
  String get enclosedTerminalStartHint =>
      'This shell runs inside this conversation’s disposable VM. It boots when you open it, not when the app starts.';

  @override
  String get terminalStreamReconnecting => 'stream interrupted — reconnecting…';

  @override
  String get terminalStreamError => 'stream error:';

  @override
  String get terminalShellExited => 'shell exited';

  @override
  String get restartShell => 'Restart shell';

  @override
  String get retry => 'Retry';

  @override
  String get review => 'Review';

  @override
  String get reviewChanges => 'Review changes';

  @override
  String get reviewedByMe => 'Reviewed by me';

  @override
  String get reviewers => 'Reviewers';

  @override
  String get reviewersActive => 'Reviewers active';

  @override
  String get roleLabel => 'Role';

  @override
  String get ruleHint => 'The policy rule (markdown supported)';

  @override
  String get ruleLabel => 'Rule';

  @override
  String get runCompleted => 'Run completed';

  @override
  String get runGhAuthLoginBody =>
      'Run `gh auth login` in your terminal, then tap Refresh.';

  @override
  String get running => 'Running';

  @override
  String get runningLabel => 'running';

  @override
  String get runs => 'Runs';

  @override
  String get runsLabel => 'Runs';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Enclosed VM';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Native sandbox on Linux/WSL2 uses bubblewrap. Install with:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Native sandbox is built in on macOS - uses Apple Seatbelt (`sandbox-exec`). No install required.';

  @override
  String get sandboxPermissions => 'Sandbox permissions';

  @override
  String get sandboxUnsupported =>
      'Native sandbox is not supported on this platform yet. Falls back to \"No isolation\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Run agents inside an OS-level sandbox so they can\'t touch your home folder, SSH keys, or tokens you haven\'t granted.';

  @override
  String get sandboxingDisabledDescription =>
      'Agents run directly on the host with full env - not recommended.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'All agent invocations route through $backend.';
  }

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get adapterArguments => 'Extra arguments';

  @override
  String get adapterArgumentsHint => 'Additional CLI flags (e.g. --yolo)';

  @override
  String get addVariable => 'Add variable';

  @override
  String get environmentVariables => 'Environment variables';

  @override
  String get environmentVariablesDescription =>
      'Custom environment variables passed to this adapter (e.g. API keys). Stored in the keychain.';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get variableKey => 'Key';

  @override
  String get variableValue => 'Value';

  @override
  String get savedArticlesDescription => 'Articles you bookmarked.';

  @override
  String get savedLabel => 'Saved';

  @override
  String get savingChanges => 'Saving changes…';

  @override
  String get savingEllipsis => 'Saving…';

  @override
  String get scopeDiffToCommits =>
      'Scope diff to commits — Shift-click for range';

  @override
  String get searchAgents => 'Search agents';

  @override
  String get searchAuthors => 'Search authors…';

  @override
  String get searchPullRequestsHint => 'Search… e.g. author:@user';

  @override
  String get noPrsMatchSearch => 'No matching pull requests';

  @override
  String get noPrsMatchSearchHint =>
      'No open PRs match your search. Try different terms or clear the search.';

  @override
  String get searchAuthorsPlaceholder => 'Search authors…';

  @override
  String get searchFactsHint => 'Search facts...';

  @override
  String get searchFonts => 'Search fonts…';

  @override
  String get searchGifs => 'Search GIFs';

  @override
  String get searchGifsHint => 'Search GIFs...';

  @override
  String get searchInDiff => 'Search in diff';

  @override
  String get searchInDiffHint => 'Search in diff…';

  @override
  String get searchOrTypeModel => 'Search or type a model name…';

  @override
  String get searchPlaceholder => 'Search…';

  @override
  String get searchShortcuts => 'Search shortcuts…';

  @override
  String get shortcutUnavailableInBrowser => 'Unavailable in the browser';

  @override
  String get searching => 'Searching…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds ago',
      one: '1 second ago',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Select adapter';

  @override
  String get selectAdapterFirst => 'Select an adapter first';

  @override
  String get selectAgentToReportTo => 'Select agent to report to…';

  @override
  String get selectAnAgent => 'Select an agent';

  @override
  String get selectConversation => 'Select a channel';

  @override
  String get selectEffortLevel => 'Select effort level';

  @override
  String get selectLabel => 'Select';

  @override
  String get selectRunner => 'Select a runner';

  @override
  String get semanticSearch => 'Semantic search';

  @override
  String get send => 'Send';

  @override
  String get sendFirstMessage => 'Send the first message';

  @override
  String get sendMessage => 'Send message';

  @override
  String sentFindingsToAgent(int count) {
    return 'Sent $count finding(s) to agent.';
  }

  @override
  String get serverRunning => 'Server running';

  @override
  String get serverStopped => 'Server stopped';

  @override
  String setGithubLinkDescription(String name) {
    return 'Set the GitHub owner and repository name for $name. This is used to resolve PR and issue references like #123 in markdown content.';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get setToken => 'Set token';

  @override
  String get settingsGeneralDescription =>
      'Appearance, typography, integrations and MCP server.';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription => 'Choose the app language.';

  @override
  String get sharedSecretToken => 'Shared secret token';

  @override
  String get shortTask => 'Short task';

  @override
  String get showNativeNotifications =>
      'Show native macOS notifications for events.';

  @override
  String get showSuperseded => 'Show superseded';

  @override
  String get signInWithGhAuth =>
      'Sign in with gh auth login or add a token in Settings > API keys';

  @override
  String get signedIn => 'Signed in.';

  @override
  String signedInAs(String username) {
    return 'Signed in as $username.';
  }

  @override
  String get skillEditor => 'Skill editor';

  @override
  String get skillNameRequired => 'Skill name is required.';

  @override
  String skillSaved(String name) {
    return 'Skill \"$name\" saved.';
  }

  @override
  String get skillBrowseDisclaimer =>
      'The skills.sh registry is untrusted. The author, install count and verified-publisher flag are provenance evidence only — the scan verdict below is the real safety signal.';

  @override
  String get skillBrowseNoResults => 'No skills matched your search.';

  @override
  String get skillBrowsePrompt =>
      'Search the skills.sh registry to install a skill.';

  @override
  String get skillBrowseSearchHint => 'Search skills.sh…';

  @override
  String get skillFindingLine => 'line';

  @override
  String get skillInstallAnywayOverride =>
      'I understand the risk — install anyway';

  @override
  String skillInstallCount(int count) {
    return '$count installs';
  }

  @override
  String skillInstalled(String slug) {
    return 'Skill \"$slug\" installed.';
  }

  @override
  String get skillPreviewCapabilities => 'Capabilities';

  @override
  String get skillPreviewFindings => 'Findings';

  @override
  String get skillPreviewGuardedActions => 'Guarded actions';

  @override
  String get skillPreviewLlmReviewed => 'LLM-reviewed';

  @override
  String get skillPreviewNoCapabilities => 'No capabilities declared.';

  @override
  String get skillPreviewNoFindings => 'No findings.';

  @override
  String get skillPreviewScanning => 'Scanning skill…';

  @override
  String get skillPreviewVerdictLabel => 'Scan verdict';

  @override
  String get skillPreviewVerdictPass => 'Passed';

  @override
  String get skillPreviewVerdictQuarantine => 'Quarantined';

  @override
  String get skillPreviewVerdictWarn => 'Warning';

  @override
  String get skillQuarantineWarning =>
      'This skill was quarantined by the scanner. Installing it runs code on your machine. Only continue if you trust the source and have reviewed the findings.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Quarantined and detached from agents: $agents';
  }

  @override
  String get skillNotScanned => 'Not scanned';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manual';

  @override
  String get skillOriginRegistry => 'Registry';

  @override
  String get skillOriginRuntimeLocal => 'Runtime local';

  @override
  String get skillRulesStale => 'Scan outdated';

  @override
  String get skillSaveAnywayOverride => 'I understand the risk — save anyway';

  @override
  String get skillSaveBlockedBody =>
      'The content was blocked before anything was written.';

  @override
  String get skillSaveBlockedTitle => 'Save blocked by the scan gate';

  @override
  String get skillScanAction => 'Scan';

  @override
  String get skillScanAll => 'Scan all';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass passed · $warn warnings · $quarantine quarantined';
  }

  @override
  String get skillStateDrifted => 'Modified since install';

  @override
  String get skillStateUnmanaged => 'Unmanaged';

  @override
  String get skillSeverityBlocked => 'Blocked';

  @override
  String get skillSeverityWarn => 'Warning';

  @override
  String get skillVerifiedPublisher => 'Verified publisher';

  @override
  String get skillsBrowseTab => 'Browse';

  @override
  String get skillsInstalledTab => 'Installed';

  @override
  String get skills => 'Skills';

  @override
  String get skillsColon => 'Skills:';

  @override
  String get skillsCommaSeparated => 'Skills (comma separated)';

  @override
  String get skillsLabel => 'SKILLS';

  @override
  String get skipAcceptRisk => 'Skip — I accept the risk';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get skipSandboxing => 'Skip sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Are you sure you want to skip sandboxing? This allows agents to execute code on your system without isolation.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String sourceCount(int count) {
    return '$count source';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count sources';
  }

  @override
  String get sourceFacts => 'Source facts:';

  @override
  String get splitDiff => 'Split (side-by-side) diff';

  @override
  String get startDmWithAgent => 'Start a channel with an agent';

  @override
  String get startLabel => 'Start';

  @override
  String get startOnAppLaunch => 'Start on app launch';

  @override
  String get startServerToAccept =>
      'Start the server to accept MCP connections.';

  @override
  String get statusLabel => 'Status';

  @override
  String stepConnect(int number) {
    return 'Step $number · Connect';
  }

  @override
  String get stop => 'Stop';

  @override
  String get stopped => 'Stopped';

  @override
  String get streaks => 'Streaks';

  @override
  String get strictIdentityCheck => 'Strict identity check';

  @override
  String get success => 'Success';

  @override
  String get successLabel => 'Success';

  @override
  String get suggestAChange => 'Suggest a change';

  @override
  String get suggestAChangeEllipsis => 'Suggest a change…';

  @override
  String get suggestLabel => 'SUGGEST';

  @override
  String get superseded => 'Superseded';

  @override
  String get synced => 'Synced';

  @override
  String get systemDefault => 'System default';

  @override
  String get systemFonts => 'System fonts';

  @override
  String get systemPrompt => 'System prompt';

  @override
  String get systemPromptLabel => 'System prompt';

  @override
  String get talkToControlCenter => 'Talk to Control Center.';

  @override
  String get tapBadgeDescription => 'Tap a badge to see how to level up';

  @override
  String get taskMentionSection => 'Task';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'This cannot be undone.';

  @override
  String get thisConversation => 'This channel';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleDescription => 'Description';

  @override
  String get titleLabel => 'Title';

  @override
  String get todayLabel => 'Today';

  @override
  String get toggleBookmark => 'Toggle bookmark';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get toggleWorkspaceSwitcher => 'Toggle workspace switcher';

  @override
  String get tokenConfigured => 'Configured — clients must present this token.';

  @override
  String get tokenConfiguredClients =>
      'Configured — clients must present this token.';

  @override
  String tokenName(String name) {
    return '$name Token';
  }

  @override
  String get topic => 'Topic';

  @override
  String get topicHint => 'e.g. Tech Stack, Design System';

  @override
  String get totalRuns => 'Total runs';

  @override
  String trackingParamsCount(int count) {
    return '$count tracking params';
  }

  @override
  String get typeCommandOrSearch => 'Type a command or search…';

  @override
  String get typography => 'Typography';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get unifiedDiff => 'Unified diff';

  @override
  String get unknownAuthor => 'Unknown';

  @override
  String get unnamedAgent => 'Unnamed agent';

  @override
  String get updateKey => 'Update key';

  @override
  String get updateLabel => 'Update';

  @override
  String get updateToken => 'Update token';

  @override
  String updatedDaysAgo(int count) {
    return 'Updated ${count}d ago';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Updated ${count}h ago';
  }

  @override
  String get updatedJustNow => 'Updated just now';

  @override
  String updatedMinutesAgo(int count) {
    return 'Updated ${count}min ago';
  }

  @override
  String get useSandbox => 'Use sandbox';

  @override
  String get useWorkspaceDefault => 'Use workspace default';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Leave empty to use the default app User-Agent. Some sites block non-browser User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Using the system default microphone.';

  @override
  String get viewAll => 'View all';

  @override
  String get viewLabel => 'View';

  @override
  String get viewLog => 'View log';

  @override
  String get viewLogs => 'View logs';

  @override
  String voiceInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Not installed. Downloads ~200 MB once; runs fully on-device.';

  @override
  String get voiceModelNotInstalledLabel => 'Voice model not installed.';

  @override
  String get voiceRedownloadBody =>
      'The existing model files will be deleted and the ~200 MB archive downloaded again. Voice transcription will be unavailable until the download completes.';

  @override
  String get voiceRemoveBody =>
      'Voice transcription will be disabled until you reinstall it. You can install it again at any time.';

  @override
  String get voiceTranscription => 'Voice transcription';

  @override
  String get meetingVad => 'Speech detection (Silero VAD)';

  @override
  String get meetingVadDescription =>
      'A learned voice-activity model that skips silence so the transcriber decodes only speech. Falls back to an energy threshold when not installed.';

  @override
  String get meetingVadInstalled =>
      'Installed. Gating transcription on detected speech.';

  @override
  String get meetingVadNotInstalled =>
      'Not installed — using the energy-threshold fallback.';

  @override
  String get meetingModelIncluded => 'Included';

  @override
  String get weakIsolationDescription =>
      'Weak isolation - namespace boundary only, no kernel boundary.';

  @override
  String get whenOffNoDefaultRoute =>
      'When off, the sandbox boots without a default route.';

  @override
  String get whenOffServerStaysStopped =>
      'When off, the server stays stopped until you start it.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installed. Used by the composer mic button.';

  @override
  String get speechModel => 'Speech model';

  @override
  String get speechModelHint =>
      'Used for meeting transcription and the composer mic.';

  @override
  String get voiceModelInstalled =>
      'Installed. Powers meeting transcription and the composer mic button.';

  @override
  String get meetingMicSilentWarning =>
      'Your mic may be muted — the others are talking but nothing is reaching your microphone.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Recording and transcription stay on this machine. The summary is written by an agent, so if it uses a cloud model your transcript and notes are sent to that provider.';

  @override
  String get meetingTemplates => 'Meeting note templates';

  @override
  String get meetingTemplatesHint =>
      'Shape the AI summary for a kind of meeting. The active template applies to new and re-run summaries.';

  @override
  String get meetingTemplateActive => 'Active template';

  @override
  String get meetingTemplateAdd => 'Add template';

  @override
  String get meetingTemplateNewTitle => 'New template';

  @override
  String get meetingTemplateEditTitle => 'Edit template';

  @override
  String get meetingTemplateNameLabel => 'Name';

  @override
  String get meetingTemplateNameHint => 'e.g. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Instructions';

  @override
  String get meetingTemplateInstructionsHint =>
      'How should the AI structure and emphasize these notes?';

  @override
  String get workingMemory => 'Working memory';

  @override
  String get workspaceName => 'Workspace name';

  @override
  String get workspaceNotesScratchpad => 'Workspace notes & scratchpad';

  @override
  String get workspaceScopedSkills =>
      'Workspace-scoped skill files attached to agents.';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get writeLabel => 'Write';

  @override
  String get writePrivateNotes => 'Write private notes, observations, plans...';

  @override
  String get writeSkillContent => 'Write your skill content here (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get focusModeStart => 'Start focus session';

  @override
  String get focusModeConfigTitle => 'Start focus session';

  @override
  String get focusModeGoalLabel => 'Goal';

  @override
  String get focusModeGoalHint => 'What are you working on?';

  @override
  String get focusModeDurationLabel => 'Duration';

  @override
  String get focusModeBlockNotifications => 'Block notifications';

  @override
  String get focusModeStartButton => 'Start';

  @override
  String get focusModeEndSession => 'End session';

  @override
  String get focusModeExpand => 'Expand app';

  @override
  String get focusModeFloat => 'Minimize to bar';

  @override
  String get focusModeActiveTooltip => 'Focus mode active — tap to end';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get acceptAndResolve => 'Accept & resolve';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'You\'ve been reviewing for ${minutes}m — research suggests review quality can dip past 60 min. Consider a break.';
  }

  @override
  String get notificationSound => 'Notification sound';

  @override
  String get notificationSoundDescription =>
      'Sound played when a notification is shown.';

  @override
  String get notificationSoundNone => 'None';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Test';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'View profile';

  @override
  String get clearAllFilters => '× Clear all';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Across $countString repos',
      one: 'Across 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'No PRs by @$login in this workspace';
  }

  @override
  String get usersLabel => 'Users';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get stackedPullRequests => 'Stacked pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'Part of a stack ($position of $total)';
  }

  @override
  String get createStack => 'Create stack';

  @override
  String get createStackDialogTitle => 'Create pull request stack';

  @override
  String createStackDialogBody(int count) {
    return 'These $count pull requests will be stacked, from the bottom up:';
  }

  @override
  String get createStackInvalidSelection =>
      'Select at least two pull requests from the same repository to create a stack';

  @override
  String get createStackNotAChain =>
      'The selected pull requests don\'t form a chain: each pull request\'s base branch must be the previous one\'s head branch';

  @override
  String get createStackAlreadyStacked =>
      'One or more selected pull requests are already in a stack';

  @override
  String get stackCreated => 'Stack created';

  @override
  String get stackCreationFailed => 'Couldn\'t create the stack';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get checksFailing => 'Checks failing';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Trusted sites';

  @override
  String get trustedSitesEmpty =>
      'No trusted sites. Add a domain to disable blocking on it.';

  @override
  String get addTrustedSite => 'Add trusted site';

  @override
  String get removeTrustedSite => 'Remove';

  @override
  String get disableBlockingForThisSite => 'Disable blocking on this site';

  @override
  String get enableBlockingForThisSite => 'Enable blocking on this site';

  @override
  String get enterDomainHint => 'e.g. example.com';

  @override
  String get invalidDomain => 'Enter a valid domain (e.g. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Page load timed out. Reload or open in browser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Run pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Run pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Pick a pipeline and fill in its inputs to start a run.';

  @override
  String get pipelineRunNoInputsBadge => 'No inputs';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inputs',
      one: '1 input',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'This pipeline takes no inputs.';

  @override
  String get pipelineRunSubmit => 'Run pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Could not start the run.';

  @override
  String pipelineRunStarted(String name) {
    return 'Started $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'No pipelines ready to run';

  @override
  String get pipelineRunEmptyHint =>
      'Enable a pipeline and turn on manual run in its editor to launch it here.';

  @override
  String get pipelineRunManageTemplates => 'Manage pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Manual run';

  @override
  String get pipelineRunSettingsAllow => 'Allow manual run';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Show this pipeline on the run page so it can be started by hand.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Inputs';

  @override
  String get pipelineRunSettingsAddInput => 'Add input';

  @override
  String get pipelineRunSettingsNoInputs => 'No inputs yet.';

  @override
  String get pipelineInputEditTitle => 'Input field';

  @override
  String get pipelineInputKeyLabel => 'Key';

  @override
  String get pipelineInputKeyHelp =>
      'State key the value is stored under (e.g. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Options (comma-separated)';

  @override
  String get pipelineInputDefaultLabel => 'Default value';

  @override
  String get pipelineInputPlaceholderLabel => 'Placeholder';

  @override
  String get pipelineInputHelpLabel => 'Help text';

  @override
  String get pipelineInputRequiredLabel => 'Required';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Multi-line text';

  @override
  String get pipelineInputTypeNumber => 'Number';

  @override
  String get pipelineInputTypeBoolean => 'Toggle';

  @override
  String get pipelineInputTypeSelect => 'Select';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint => 'Click \'Run pipeline\' to start one.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Select a workspace to view its pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Failed to load pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Failed to start pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed of $total steps';
  }

  @override
  String get pipelineWaterfallTimeline => 'Timeline';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Active $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'idle $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Time excluded from the active total: the run was stopped or waiting between steps.';

  @override
  String get pipelineStepStarted => 'Started';

  @override
  String get pipelineStepFinished => 'Finished';

  @override
  String get pipelineStepDurationLabel => 'Duration';

  @override
  String get pipelineStepBranch => 'Branch';

  @override
  String get pipelineStepViewConversation => 'View channel';

  @override
  String get pipelineStepError => 'Error';

  @override
  String get pipelineStepInput => 'Input';

  @override
  String get pipelineStepOutput => 'Output';

  @override
  String get pipelineStepNotExecuted => 'Not yet executed';

  @override
  String get pipelineRunViewTimeline => 'Timeline';

  @override
  String get pipelineRunViewGraph => 'Graph';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Failed at $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineRunTriggerAuto => 'Automatic';

  @override
  String get pipelineStepSkippedReason => 'Skipped';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Duration';

  @override
  String get pipelineRunColumnStarted => 'Started';

  @override
  String get pipelineRunFilterAll => 'All';

  @override
  String get pipelineRunFilterEmpty => 'No runs match this filter';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automations';

  @override
  String get automationsSubtitle =>
      'Auto-start pipelines when domain events fire';

  @override
  String get automationsNoTriggers => 'No triggers configured for this event.';

  @override
  String get automationsAddTrigger => 'Add trigger';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'No tickets';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsManageSubtitle =>
      'Group agents into teams and route assigned work through a leader.';

  @override
  String get teamsLoadError => 'Couldn\'t load teams';

  @override
  String get teamsEmptyTitle => 'No teams yet';

  @override
  String get teamsEmptyDescription =>
      'Group agents into teams so work assigned to a team routes through a leader who delegates.';

  @override
  String get teamCreateTitle => 'New team';

  @override
  String get teamEditTitle => 'Edit team';

  @override
  String get teamNameLabel => 'Team name';

  @override
  String get teamNameHint => 'e.g. Frontend';

  @override
  String get teamDescriptionLabel => 'Description';

  @override
  String get teamDescriptionHint => 'What this team is responsible for';

  @override
  String get teamLeaderLabel => 'Leader';

  @override
  String get teamLeaderHelp =>
      'The coordinator that receives team-assigned work and delegates to the best-suited member.';

  @override
  String get teamNoLeader => 'No leader';

  @override
  String get teamInstructionsLabel => 'Operating instructions';

  @override
  String get teamInstructionsHelp =>
      'Appended to the leader\'s briefing — team conventions, escalation rules, tone.';

  @override
  String get teamInstructionsHint => 'Optional';

  @override
  String get teamSaved => 'Team saved';

  @override
  String get teamMembersError => 'Couldn\'t load members';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Add member';

  @override
  String get teamAddMemberTitle => 'Add members';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count',
      one: 'Add 1',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Every agent is already on this team.';

  @override
  String get teamRemoveMember => 'Remove from team';

  @override
  String get teamLeaderBadge => 'Leader';

  @override
  String get teamUnknownAgent => 'Unknown agent';

  @override
  String get teamMembersEmpty => 'No members yet';

  @override
  String get teamMembersEmptyDescription =>
      'Add agents so the leader has people to delegate to.';

  @override
  String get teamSelectPrompt => 'Select a team';

  @override
  String get teamSelectPromptDescription =>
      'Choose a team from the list, or create a new one.';

  @override
  String get teamDeleteTitle => 'Delete team?';

  @override
  String teamDeleteBody(String name) {
    return '$name will be deleted. Its agents are not affected.';
  }

  @override
  String get teamHasLeaderTooltip => 'Has a leader';

  @override
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

  @override
  String get pipelineTemplatesNav => 'Pipeline templates';

  @override
  String get pipelineTemplatesTitle => 'Pipeline templates';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-drop editor for the pipelines that orchestrate your agents.';

  @override
  String get pipelineTemplatesNew => 'New template';

  @override
  String get pipelineTemplatesEmpty =>
      'No pipeline templates yet. Create one to get started.';

  @override
  String get pipelineTemplateIdLabel => 'Template ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Built-in';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Delete template?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Delete pipeline template $name? This cannot be undone.';
  }

  @override
  String get pipelineTemplateSaved => 'Pipeline template saved';

  @override
  String get pipelineTemplateEditorTitle => 'Edit pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Drag node types from the sidebar onto the canvas, then wire them together.';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get nodeLibraryTitle => 'Node library';

  @override
  String get nodeLibraryHint => 'Drag any entry onto the canvas to add a node.';

  @override
  String get editorDragHint => 'Drag from the library, click a node to edit';

  @override
  String get editorEmptyCanvas => 'Drag a node from the library to start.';

  @override
  String get nodeConfigTitle => 'Node config';

  @override
  String get nodeConfigKind => 'Kind';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Pick an agent…';

  @override
  String get nodeConfigInputKeys => 'Input keys (comma-separated)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State keys this node consumes. Used for placeholder substitution in the prompt.';

  @override
  String get nodeConfigRepos => 'Repositories to clone';

  @override
  String get nodeConfigReposHelp =>
      'Repos cloned and code-indexed when this node starts its conversation. Selecting every repo clones all of them (the default).';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Dynamic entries kept: $entries';
  }

  @override
  String get nodeConfigOutputKey => 'Output key';

  @override
  String get nodeConfigPrompt => 'Prompt template';

  @override
  String get nodeConfigPromptHelp =>
      'Use double-brace placeholders to pull values from state at runtime.';

  @override
  String get nodeConfigScript => 'Bash script';

  @override
  String get nodeConfigScriptHelp =>
      'Runs with bash -c. GITHUB_TOKEN is set. Placeholders are substituted before execution.';

  @override
  String get nodeConfigTriggers => 'Triggers from';

  @override
  String get nodeConfigNoUpstream => 'No other nodes to connect from.';

  @override
  String get nodeConfigRouteKeys => 'Route keys';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Route key from $source';
  }

  @override
  String get conditionSectionTitle => 'Condition';

  @override
  String get conditionMode => 'Mode';

  @override
  String get conditionModeFilesAny => 'File(s) exist — any';

  @override
  String get conditionModeFilesAll => 'Files exist — all';

  @override
  String get conditionModeComparison => 'Comparison';

  @override
  String get conditionModeSwitch => 'Switch';

  @override
  String get conditionFilePaths => 'File paths';

  @override
  String get conditionFilePathsAnyHelp =>
      'One path per line, relative to the base directory. Routes true when any exists.';

  @override
  String get conditionFilePathsAllHelp =>
      'One path per line, relative to the base directory. Routes true only when all exist.';

  @override
  String get conditionBaseKey => 'Base directory key';

  @override
  String get conditionBaseKeyHelp =>
      'State key holding the directory paths resolve against (default repoLocalPath).';

  @override
  String get conditionRecursive => 'Search subdirectories';

  @override
  String get conditionNegate => 'Invert: route true when missing';

  @override
  String get conditionLeft => 'Left value';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Right value';

  @override
  String get conditionSwitchKey => 'Switch on state key';

  @override
  String get conditionCases => 'Cases (comma-separated)';

  @override
  String get conditionCasesHelp =>
      'Route keys to match against the value, in order.';

  @override
  String get conditionDefaultCase => 'Default case';

  @override
  String get triggerPanelTitle => 'Triggers';

  @override
  String get triggerPanelHelp => 'What starts this pipeline.';

  @override
  String get triggerManualHelp => 'Show on the run page and start by hand.';

  @override
  String get triggerSectionAutomatic => 'Automatic triggers';

  @override
  String get triggerAddButton => 'Add trigger';

  @override
  String get triggerNoneYet => 'No automatic triggers yet.';

  @override
  String get triggerAddDialogTitle => 'Add trigger';

  @override
  String get triggerKindLabel => 'Trigger type';

  @override
  String get triggerKindEvent => 'On an event';

  @override
  String get triggerKindSchedule => 'On a schedule';

  @override
  String get triggerIntervalLabel => 'Run every (seconds)';

  @override
  String get triggerKindWebhook => 'Via a webhook';

  @override
  String get triggerScheduleExprLabel => 'Schedule (cron or every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Timezone (optional)';

  @override
  String get triggerCatchUpLabel => 'On missed runs';

  @override
  String get triggerCatchUpRunOnce => 'Run once';

  @override
  String get triggerCatchUpSkip => 'Skip';

  @override
  String get syncHealthTitle => 'Sync health';

  @override
  String get syncHealthNoConfigs => 'No sync connections yet';

  @override
  String get syncHealthNeverSynced => 'Never synced';

  @override
  String get syncOutcomeOk => 'Synced';

  @override
  String get syncOutcomeFailed => 'Failed';

  @override
  String get syncOutcomeSkipped => 'Skipped';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count consecutive failures';
  }

  @override
  String get triggerWebhookHelp =>
      'A signed webhook URL is generated. External systems POST to it to start this pipeline.';

  @override
  String get triggerEventFieldLabel => 'Event';

  @override
  String get triggerNoMoreEvents => 'All available events are already wired.';

  @override
  String get triggerMatchStatusLabel => 'Only when the status is';

  @override
  String get triggerSummaryNone => 'No triggers';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Every ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Manual run';

  @override
  String get triggerEventSchedule => 'Schedule';

  @override
  String get triggerEventPrStatusChanged => 'PR status changed';

  @override
  String get triggerEventExternalPr => 'External PR opened';

  @override
  String get triggerEventPrPublished => 'PR published';

  @override
  String get triggerEventPrMerged => 'PR merged';

  @override
  String get triggerEventRepoAdded => 'Repository added';

  @override
  String get triggerEventMessageReceived => 'Message received';

  @override
  String get triggerEventTicketCompleted => 'Ticket completed';

  @override
  String get triggerEventTicketFailed => 'Ticket failed';

  @override
  String get triggerEventTicketCancelled => 'Ticket cancelled';

  @override
  String get triggerEventBudgetCrossed => 'Budget threshold crossed';

  @override
  String get automationsManagedHint =>
      'Triggers are configured per pipeline in its editor. Toggle them on or off here.';

  @override
  String get automationsEditInPipeline => 'Edit in pipeline';

  @override
  String get nodeLibrarySearchHint => 'Search nodes';

  @override
  String get nodeLibraryNoMatches => 'No matching nodes';

  @override
  String get nodeCategoryFlow => 'Flow & logic';

  @override
  String get nodeCategoryPr => 'PR review';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Messaging';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'off';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'No repositories in this workspace yet.';

  @override
  String get allowTicketingApi => 'Allow ticketing API calls';

  @override
  String get ticketingApiKey => 'Ticketing API key';

  @override
  String get ticketingApiKeySubtitle =>
      'Injects the ticketing provider API key into the sandbox.';

  @override
  String get ticketingProvider => 'Ticketing provider';

  @override
  String get connectGitHubAndTicketing =>
      'Connect GitHub so Control Center can read your pull requests, issues and reviews. Optionally connect a ticketing provider. Nothing leaves this machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket assigned';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'New ticket';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get assignTicket => 'Assign ticket';

  @override
  String get addCollaborator => 'Add collaborator';

  @override
  String get noCollaborators => 'No collaborators yet';

  @override
  String get linkedPullRequests => 'Linked pull requests';

  @override
  String get noLinkedPullRequests => 'No linked pull requests yet';

  @override
  String get ticketActivity => 'Activity';

  @override
  String get ticketDispatchHint => '@mention an agent to dispatch them…';

  @override
  String get stopAgent => 'Stop agent';

  @override
  String get removeQueuedMessage => 'Remove queued message';

  @override
  String get ticketProperties => 'Properties';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketTabActivity => 'Activity';

  @override
  String get ticketTabChanges => 'Changes';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt => 'Select a ticket to view its details';

  @override
  String get ticketNoChanges => 'No changes in the linked repositories yet';

  @override
  String get ticketTerminalNoAgent => 'Assign an agent to open a terminal';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'To do';

  @override
  String get ticketStatusInProgress => 'In progress';

  @override
  String get ticketStatusInReview => 'In review';

  @override
  String get ticketStatusDone => 'Done';

  @override
  String get ticketStatusBlocked => 'Blocked';

  @override
  String get ticketStatusFailed => 'Failed';

  @override
  String get ticketStatusCancelled => 'Cancelled';

  @override
  String get notificationTicketAssigned => 'Ticket assigned';

  @override
  String get notificationTicketStatusChanged => 'Ticket status changed';

  @override
  String get notificationTicketCollaboratorAdded => 'Collaborator added';

  @override
  String get priority => 'Priority';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Assignee';

  @override
  String get labels => 'Labels';

  @override
  String get noLabelsYet => 'No labels yet';

  @override
  String get clearLabels => 'Clear labels';

  @override
  String get pipelineStepAgentActivity => 'Agent activity';

  @override
  String get runStatusCompleted => 'Completed';

  @override
  String get runStatusQueued => 'Queued';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketPriorityNone => 'None';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'High';

  @override
  String get ticketPriorityMedium => 'Medium';

  @override
  String get ticketPriorityLow => 'Low';

  @override
  String get ticketViewList => 'List';

  @override
  String get ticketViewBoard => 'Board';

  @override
  String get ticketTitlePlaceholder => 'Issue title';

  @override
  String get ticketDescriptionPlaceholder => 'Add description…';

  @override
  String get createMore => 'Create more';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get bulkDeleteTitle => 'Delete tickets';

  @override
  String bulkDeleteMessage(int count) {
    return 'Delete $count selected tickets? This can\'t be undone.';
  }

  @override
  String get assignTo => 'Assign to…';

  @override
  String get sectionMembers => 'Members';

  @override
  String get sectionAgents => 'Agents';

  @override
  String get sidebarGroupWorkspace => 'Workspace';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get toggleThemeLabel => 'Toggle theme';

  @override
  String get teamsNav => 'Teams';

  @override
  String get noWorkspace => 'No workspace';

  @override
  String get selectWorkspace => 'Select a workspace';

  @override
  String get allAgentsIdle => 'All agents idle';

  @override
  String get statWorkspaces => 'Workspaces';

  @override
  String get statAgents => 'Agents';

  @override
  String get statRunning => 'Running';

  @override
  String get activeAgentsTitle => 'Active agents';

  @override
  String get noAgentProcessesSubtitle =>
      'Agent activity will appear here when a run starts.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Running · $count';
  }

  @override
  String get noneLabel => 'None';

  @override
  String get navMemory => 'Memory';

  @override
  String get memoryTabFacts => 'Facts';

  @override
  String get memoryTabPolicies => 'Policies';

  @override
  String get memoryTabGraph => 'Knowledge graph';

  @override
  String get memoryNoWorkspace => 'Select a workspace to view its memory.';

  @override
  String get topStory => 'Top story';

  @override
  String get searchArticles => 'Search articles';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterSaved => 'Saved';

  @override
  String get saveArticle => 'Save article';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get filterBySource => 'Filter by source';

  @override
  String get viewAsList => 'List view';

  @override
  String get viewAsGrid => 'Grid view';

  @override
  String get noMatchingArticles => 'No matching articles';

  @override
  String get noMatchingArticlesBody =>
      'Try a different search or source filter.';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get allCaughtUpBody => 'No unread articles — check back later.';

  @override
  String get openArticlesInAppDescription =>
      'Open links in the built-in reader instead of your default browser.';

  @override
  String get blockAdsTrackersDescription =>
      'Strip ads, trackers and cookie banners from articles you open in the reader.';

  @override
  String get agentQuestionHeader => 'Question for you';

  @override
  String get agentQuestionAnsweredLabel => 'Answered';

  @override
  String get agentQuestionSubmit => 'Submit answer';

  @override
  String get agentQuestionFreeformHint => 'Type your answer…';

  @override
  String get agentQuestionAnswerLabel => 'Your answer';

  @override
  String get reviewRequested => 'Review requested';

  @override
  String get loadMorePrs => 'Load more';

  @override
  String get loadingMorePrs => 'Loading more…';

  @override
  String get noPrsMatchFilters =>
      'No pull requests match the filters in this repo';

  @override
  String get connectGitHubToLoadPrs => 'Connect GitHub to load pull requests';

  @override
  String get noRepositoriesConfigured => 'No repositories configured';

  @override
  String get noAuthors => 'No authors';

  @override
  String openedAgo(String age) {
    return 'Opened $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author opened this pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author opened this pull request with $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor requested review from $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor removed the review request for $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor requested review from $requested and removed the review request for $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author committed';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author pushed $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author approved these changes';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author requested changes';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count code comments',
      one: '1 code comment',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author reviewed';
  }

  @override
  String get prTimelineSomeone => 'Someone';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Updated $age';
  }

  @override
  String get checksPassing => 'Checks passing';

  @override
  String get checksRunning => 'Checks running';

  @override
  String get needsYourReview => 'Needs your review';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions lines';
  }

  @override
  String get checks => 'Checks';

  @override
  String get noReviewersAssigned => 'No reviewers assigned';

  @override
  String get noAssignees => 'No assignees';

  @override
  String get noChecksYet => 'No checks have run yet';

  @override
  String checksFailingCount(int count) {
    return '$count failing';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get backToPullRequests => 'Back to pull requests';

  @override
  String get pullRequestNotFound => 'Pull request not found';

  @override
  String get pullRequestNotFoundBody =>
      'It may have been merged, closed, or moved.';

  @override
  String get couldntLoadPullRequest => 'Couldn\'t load this pull request';

  @override
  String get showDetails => 'Show details';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Loading pull request #$number…';
  }

  @override
  String get noDescriptionProvided => 'No description provided.';

  @override
  String get factsHint => 'Facts will appear here as your agents learn.';

  @override
  String get noFactsMatch => 'No facts match your search';

  @override
  String get memoryLoadError => 'Couldn\'t load memory';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortConfidence => 'Confidence';

  @override
  String get confidenceTooltip =>
      'How sure agents are that this fact is true, from 0 to 100%.';

  @override
  String get supersededTooltip => 'A newer fact has replaced this one.';

  @override
  String get domain => 'Domain';

  @override
  String get fitToView => 'Fit to view';

  @override
  String get project => 'Project';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get noProject => 'No project';

  @override
  String get allTickets => 'All tickets';

  @override
  String get projectNamePlaceholder => 'Project name';

  @override
  String get projectDescriptionPlaceholder => 'Description (optional)';

  @override
  String get projectColorLabel => 'Color';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get projectTicketsEmpty => 'No tickets in this project yet';

  @override
  String get createProject => 'Create project';

  @override
  String projectProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Delete \"$name\"? Its tickets are kept and removed from the project.';
  }

  @override
  String get projectStatusActive => 'Active';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get markProjectCompleted => 'Mark completed';

  @override
  String get markProjectActive => 'Mark active';

  @override
  String get archiveProject => 'Archive';

  @override
  String get restoreProject => 'Restore';

  @override
  String get relations => 'Relations';

  @override
  String get relateTo => 'Relate to';

  @override
  String get relationSubIssueOf => 'Sub-issue of…';

  @override
  String get relationParentOf => 'Parent of…';

  @override
  String get relationBlockedBy => 'Blocked by…';

  @override
  String get relationBlocking => 'Blocking…';

  @override
  String get relationRelatedTo => 'Related to…';

  @override
  String get relationDuplicateOf => 'Duplicate of…';

  @override
  String get relationGroupParent => 'Parent';

  @override
  String get relationGroupSubIssues => 'Sub-issues';

  @override
  String get relationGroupBlockedBy => 'Blocked by';

  @override
  String get relationGroupBlocking => 'Blocking';

  @override
  String get relationGroupRelated => 'Related';

  @override
  String get relationGroupDuplicateOf => 'Duplicate of';

  @override
  String get relationGroupDuplicatedBy => 'Duplicated by';

  @override
  String get copyId => 'Copy ID';

  @override
  String get ticketIdCopied => 'Copied ticket ID';

  @override
  String get selectTicket => 'Select a ticket';

  @override
  String get searchTicketsHint => 'Search tickets…';

  @override
  String get noMatchingTickets => 'No tickets match';

  @override
  String get addToProject => 'Add to project';

  @override
  String get clearAll => 'Clear all';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents running',
      one: '1 agent running',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count blocked';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count needs you';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repos',
      one: '1 repo',
    );
    return '$_temp0 awaiting your review across $_temp1';
  }

  @override
  String get staleLabel => 'Stale';

  @override
  String stepsProgress(int done, int total) {
    return '$done of $total steps';
  }

  @override
  String workspaceEyebrow(String name) {
    return '$name workspace';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get workspaceSettings => 'Workspace settings';

  @override
  String get manageWorkspacesSubtitle =>
      'Rename a workspace and change its mark — pick one on the left to edit it.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workspaces',
      one: '1 workspace',
      zero: 'No workspaces',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repos',
      one: '1 repo',
      zero: 'No repos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agents',
      one: '1 agent',
      zero: '0 agents',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identity';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get failedToSaveLogo =>
      'Failed to save the logo image. Make sure the app can read the selected file.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG or GIF up to 2 MB. Otherwise we\'ll use the workspace initial.';

  @override
  String get workspaceNameFieldHelp =>
      'Shown in the switcher, the breadcrumb and on every screen.';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteThisWorkspace => 'Delete this workspace';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Permanently removes $name, its repository connections, agents and memory. This can\'t be undone.';
  }

  @override
  String get discard => 'Discard';

  @override
  String discardChangesQuestion(String name) {
    return 'Discard unsaved changes to $name?';
  }

  @override
  String get workspaceUpdated => 'Workspace updated';

  @override
  String get editTitle => 'Edit title';

  @override
  String get editDescription => 'Edit description';

  @override
  String get addDescription => 'Add a description';

  @override
  String get prTitlePlaceholder => 'Title';

  @override
  String get prBodyPlaceholder => 'Leave a description';

  @override
  String get write => 'Write';

  @override
  String get overview => 'Overview';

  @override
  String get filesTabShort => 'Files';

  @override
  String get noFilesChanged => 'No files changed';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Preview';

  @override
  String get outdated => 'Outdated';

  @override
  String get outdatedComments => 'Outdated comments';

  @override
  String outdatedCountLabel(int count) {
    return '$count outdated';
  }

  @override
  String get prTemplateLabel => 'Template';

  @override
  String get prTemplateDefault => 'Default';

  @override
  String get addReviewers => 'Add reviewers';

  @override
  String get addAssignees => 'Add assignees';

  @override
  String get searchUsers => 'Search people…';

  @override
  String get searchReviewers => 'Search people and teams…';

  @override
  String get usersSectionLabel => 'People';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get suggestedReviewers => 'Suggested reviewers';

  @override
  String get noMatchingUsers => 'No matching people';

  @override
  String get noMatchingReviewers => 'No matches';

  @override
  String addCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Required by code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Bold';

  @override
  String get markdownItalic => 'Italic';

  @override
  String get markdownHeading => 'Heading';

  @override
  String get markdownBulletList => 'Bulleted list';

  @override
  String get markdownChecklist => 'Checklist';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Quote';

  @override
  String failedToUpdateTitle(String error) {
    return 'Couldn\'t update title: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Couldn\'t update description: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Couldn\'t update reviewers: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Couldn\'t update assignees: $error';
  }

  @override
  String get discardChangesConfirm => 'Discard your changes?';

  @override
  String get newPr => 'New PR';

  @override
  String get openPullRequest => 'Open a pull request';

  @override
  String get composePrSubtitle =>
      'From a branch you\'ve pushed — no agents or tickets involved';

  @override
  String get createAsDraft => 'Create as draft';

  @override
  String get composePrNoRepo => 'No GitHub repository selected';

  @override
  String get composePrNoRepoHint =>
      'Select a workspace with a GitHub-linked repository to open a pull request.';

  @override
  String get composePrPickBranches =>
      'Pick a base and compare branch to preview the changes.';

  @override
  String get composePrNothingToCompare =>
      'There are no changes between these branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Compare';

  @override
  String get selectBranch => 'Select a branch';

  @override
  String get navMeetings => 'Meetings';

  @override
  String get meetingsNoWorkspace => 'Select a workspace to see meetings.';

  @override
  String get meetingsEmpty => 'No meetings yet';

  @override
  String get meetingsEmptyHint =>
      'Record your first meeting — audio stays on this device and the agent turns it into notes, decisions and action items.';

  @override
  String get meetingsStartRecording => 'Start recording';

  @override
  String get meetingsStopRecording => 'Stop recording';

  @override
  String get meetingsProcessing => 'Summarizing…';

  @override
  String get meetingEnhancedNotes => 'Enhanced notes';

  @override
  String get meetingYourNotes => 'Your notes';

  @override
  String get meetingNotesHint =>
      'Jot quick notes — the agent expands them after the meeting.';

  @override
  String get meetingTranscriptTitle => 'Transcript';

  @override
  String get meetingNoTranscriptYet =>
      'The transcript appears here as people speak.';

  @override
  String get meetingSpeakerMe => 'You';

  @override
  String get meetingSpeakerThem => 'Them';

  @override
  String get meetingStatusRecording => 'Recording';

  @override
  String get meetingStatusProcessing => 'Processing';

  @override
  String get meetingStatusDone => 'Done';

  @override
  String get meetingStatusFailed => 'Failed';

  @override
  String get keybindingGoToMeetings => 'Go to meetings';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Navigate to the meetings list';

  @override
  String get meetingsSubtitle =>
      'Local meeting capture. We tap the meeting audio and your mic, transcribe on-device and let an agent turn your sparse notes into decisions and action items — no bot ever joins the call.';

  @override
  String get meetingsRecordMeeting => 'Record meeting';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processing now',
      one: '1 processing now',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'This week';

  @override
  String get meetingsStatThisWeekUnit => 'meetings captured';

  @override
  String get meetingsStatRecorded => 'Recorded';

  @override
  String get meetingsStatRecordedUnit => 'transcribed locally';

  @override
  String get meetingsStatOpen => 'Open';

  @override
  String get meetingsStatOpenUnit => 'action items pending';

  @override
  String get meetingsStatLogged => 'Logged';

  @override
  String get meetingsStatLoggedUnit => 'decisions extracted';

  @override
  String get meetingsCaptureTitle =>
      'Driver-free system-audio capture is armed.';

  @override
  String get meetingsCaptureBody =>
      'Control Center taps the speaker output of whatever app you are in — Slack Huddle, Meet, Zoom, Tuple — plus your microphone and decodes both streams on this device.';

  @override
  String get meetingsCapturePermission => 'Permission granted';

  @override
  String get meetingsCaptureOnDevice => '100% on-device';

  @override
  String get meetingsCaptureNoBot => 'No bot joins';

  @override
  String get meetingsScopeAll => 'All meetings';

  @override
  String get meetingsFilterAll => 'All';

  @override
  String get meetingsFilterDone => 'Done';

  @override
  String get meetingsFilterProcessing => 'Processing';

  @override
  String get meetingsSearchHint => 'Filter by title, person, app…';

  @override
  String get meetingsBucketToday => 'Today';

  @override
  String get meetingsBucketYesterday => 'Yesterday';

  @override
  String get meetingsBucketEarlierThisWeek => 'Earlier this week';

  @override
  String get meetingsBucketLastWeek => 'Last week';

  @override
  String get meetingsBucketOlder => 'Older';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisions',
      one: '1 decision',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total action items';
  }

  @override
  String get meetingsEnhancedPill => 'enhanced';

  @override
  String get meetingsTranscribing => 'transcribing & summarizing…';

  @override
  String get meetingsOpenAction => 'Open';

  @override
  String get meetingsStopProcessing => 'Stop';

  @override
  String get meetingsStillTranscribing =>
      'Still transcribing — the summary appears when it finishes.';

  @override
  String get meetingsNoMatch => 'No meetings match';

  @override
  String get meetingsNoMatchHint => 'Try a different filter or search term.';

  @override
  String get meetingBackAllMeetings => 'All meetings';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Re-run summary';

  @override
  String get meetingExport => 'Export';

  @override
  String get meetingAugmentingBanner =>
      'Augmenting your notes from the transcript — extracting decisions and action items…';

  @override
  String get meetingTabNotes => 'Notes';

  @override
  String get meetingTabTranscript => 'Transcript';

  @override
  String get meetingTabActionItems => 'Action items';

  @override
  String get meetingTabDecisions => 'Decisions';

  @override
  String get meetingNotesEnhancedToggle => 'Enhanced';

  @override
  String get meetingNotesYoursToggle => 'Your notes';

  @override
  String get meetingEnhancedByAgent => 'Enhanced by agent · from transcript';

  @override
  String get meetingEnhancedPending =>
      'The agent is still working on this summary.';

  @override
  String get meetingNotesEmpty => 'No enhanced notes yet.';

  @override
  String get meetingNotesSavedLocally => 'Saved locally';

  @override
  String get meetingNotesSaving => 'Saving…';

  @override
  String get meetingViewFullTranscript => 'View full transcript';

  @override
  String get meetingTranscriptSearchHint => 'Search the transcript…';

  @override
  String get meetingSpeakerEveryone => 'Everyone';

  @override
  String get meetingSpeakerOthers => 'Others';

  @override
  String get meetingTranscriptEmpty => 'No transcript yet.';

  @override
  String get meetingActionItemsEmpty => 'No action items extracted.';

  @override
  String get meetingActionItemFrom => 'from this meeting';

  @override
  String get meetingCreateTicket => 'Create ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key created and dispatched.';
  }

  @override
  String get meetingTicketFailed => 'Couldn\'t create the ticket.';

  @override
  String get meetingDecisionsEmpty => 'No decisions logged.';

  @override
  String get meetingEditTitle => 'Edit title';

  @override
  String get meetingTitleLabel => 'Title';

  @override
  String get meetingAddActionItem => 'Add action item';

  @override
  String get meetingEditActionItem => 'Edit action item';

  @override
  String get meetingDeleteActionItem => 'Delete action item';

  @override
  String get meetingActionItemContentLabel => 'Action item';

  @override
  String get meetingActionItemContentHint => 'What needs to happen?';

  @override
  String get meetingActionItemOwnerLabel => 'Owner';

  @override
  String get meetingActionItemOwnerHint => 'Who\'s responsible? (optional)';

  @override
  String get meetingAddDecision => 'Add decision';

  @override
  String get meetingEditDecision => 'Edit decision';

  @override
  String get meetingDeleteDecision => 'Delete decision';

  @override
  String get meetingDecisionContentLabel => 'Decision';

  @override
  String get meetingDecisionContentHint => 'What was decided?';

  @override
  String get meetingReRunStarted =>
      'Re-running the summarizer on the transcript…';

  @override
  String get meetingReRunDone => 'Summary refreshed.';

  @override
  String get meetingReRunNoTranscript =>
      'There\'s no transcript to summarize yet.';

  @override
  String get meetingExportCopied =>
      'Notes copied to the clipboard as Markdown.';

  @override
  String get meetingExportSaved => 'Meeting exported.';

  @override
  String meetingExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get meetingExportNothing => 'There\'s nothing to export yet.';

  @override
  String get meetingPlaybackPlay => 'Play';

  @override
  String get meetingPlaybackPause => 'Pause';

  @override
  String get meetingPlaybackUnavailable =>
      'Audio playback is unavailable on this device.';

  @override
  String get meetingDetectedTitle => 'Meeting detected';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Looks like \"$label\" is happening. Record it?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Looks like a meeting is happening. Record it?';

  @override
  String get meetingDetectedRecord => 'Record';

  @override
  String get meetingDetectedDismiss => 'Dismiss';

  @override
  String get meetingAutoStopTitle => 'This meeting looks over. Stop recording?';

  @override
  String get meetingAutoStopStop => 'Stop';

  @override
  String get meetingAutoStopKeep => 'Keep recording';

  @override
  String get meetingAutoDetect => 'Auto-detect meetings';

  @override
  String get meetingAutoDetectDescription =>
      'Watch the calendar and conferencing apps and offer to record when a meeting starts.';

  @override
  String get meetingsRecordingCrumb => 'Recording…';

  @override
  String get meetingRecordTitleHint => 'Meeting title';

  @override
  String get meetingRecordTappingLabel => 'Tapping:';

  @override
  String get meetingRecordMic => 'Mic';

  @override
  String get meetingRecordSystemAudio => 'System audio';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Resume';

  @override
  String get meetingRecordStop => 'Stop & summarize';

  @override
  String get meetingRecordYourNotes => 'Your notes';

  @override
  String get meetingRecordNotesTagline =>
      'jot sparsely — the agent fills the rest';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Type while you listen. A few fragments is enough — after you stop, the agent expands them using the transcript.';

  @override
  String get meetingRecordLiveTranscript => 'Live transcript';

  @override
  String get meetingRecordDecoding => 'decoding on-device';

  @override
  String get meetingRecordListening =>
      'Listening… speech appears here within a second or two, tagged You / Others.';

  @override
  String get meetingRecordPausedHint =>
      'Paused — audio is ignored until you resume.';

  @override
  String get meetingRecordNotActive => 'No active recording.';

  @override
  String get meetingHudRecording => 'recording';

  @override
  String get meetingHudPaused => 'paused';

  @override
  String get meetingHudOpen => 'Open';

  @override
  String get meetingHudStop => 'Stop';

  @override
  String get meetingToolbarPopOut => 'Pop out';

  @override
  String get meetingToolbarHoldToStop => 'Hold to stop recording';

  @override
  String get meetingToolbarSemanticLabel => 'Meeting recording toolbar';

  @override
  String get orchestrate => 'Orchestrate';

  @override
  String get orchestrationUnavailable => 'Orchestration unavailable';

  @override
  String get orchestrationApprove => 'Approve plan';

  @override
  String get orchestrationReject => 'Reject';

  @override
  String get orchestrationCancel => 'Cancel orchestration';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count roles — $hires new hires';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sub-tickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Estimated cost: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sub-tickets done';
  }

  @override
  String get orchestrationStatusProposed => 'Proposed';

  @override
  String get orchestrationStatusApproved => 'Approved';

  @override
  String get orchestrationStatusExecuting => 'Executing';

  @override
  String get orchestrationStatusSynthesizing => 'Synthesizing';

  @override
  String get orchestrationStatusCompleted => 'Completed';

  @override
  String get orchestrationStatusFailed => 'Failed';

  @override
  String get orchestrationStatusCancelled => 'Cancelled';

  @override
  String get messageFailed => 'Run failed';

  @override
  String get turnLimitReached =>
      'Stopped at the turn limit — reply to continue';

  @override
  String get retried => 'Retried';

  @override
  String replyingTo(String name) {
    return 'replying to $name';
  }

  @override
  String get recentRuns => 'Recent runs';

  @override
  String get runIdCopied => 'Run id copied';

  @override
  String get copyRunId => 'Copy run id';

  @override
  String get copyLogPath => 'Copy log path';

  @override
  String get silenceTimeoutLabel => 'Silence timeout (minutes)';

  @override
  String get silenceTimeoutHint =>
      'e.g. 15 — terminate a run after this long with no output';

  @override
  String get ticketOutput => 'Output';

  @override
  String missingRequiredField(String field) {
    return 'Missing required field: $field';
  }

  @override
  String get capabilityJsonMode => 'JSON mode';

  @override
  String get capabilityModelSelection => 'Model selection';

  @override
  String get transcriptThinking => 'Thinking…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Thought for $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Making edits…';

  @override
  String get transcriptStatusReadingFiles => 'Reading files…';

  @override
  String get transcriptStatusSearching => 'Searching codebase…';

  @override
  String get transcriptStatusRunningCommands => 'Running commands…';

  @override
  String get transcriptStatusResponding => 'Responding…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Running $tool…';
  }

  @override
  String get transcriptInput => 'Input';

  @override
  String get transcriptOutput => 'Output';

  @override
  String get transcriptShowMore => 'Show more';

  @override
  String get transcriptShowLess => 'Show less';

  @override
  String get transcriptErrorLabel => 'Error';

  @override
  String get transcriptInterrupted => 'Interrupted';

  @override
  String get transcriptSandboxBlocked => 'Sandbox blocked an action';

  @override
  String get transcriptOutputTruncated => 'Output truncated';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Show full output (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Show all $count lines';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Showing first $count lines';
  }

  @override
  String get transcriptGrepNoMatches => 'No matches';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches matches',
      one: '1 match',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds additions, $dels deletions';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Person $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Rename speaker';

  @override
  String get meetingRenameSpeakerTitle => 'Rename speaker';

  @override
  String get meetingSpeakerNameLabel => 'Name';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'From this meeting\'s invitees';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Apply to all blocks from this speaker';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'When off, only the selected line is renamed.';

  @override
  String get meetingLinkEvent => 'Link to event';

  @override
  String get meetingChangeEvent => 'Change event';

  @override
  String get meetingLinkEventTitle => 'Link to a calendar event';

  @override
  String get meetingLinkEventSearchHint => 'Search events';

  @override
  String get meetingLinkEventEmpty => 'No nearby calendar events';

  @override
  String get meetingUnlinkEvent => 'Remove link';

  @override
  String get calendarLinkExistingMeeting => 'Link to existing meeting';

  @override
  String get calendarLinkMeetingTitle => 'Link a meeting';

  @override
  String get calendarLinkMeetingSearchHint => 'Search meetings';

  @override
  String get calendarLinkMeetingEmpty => 'No meetings to link';

  @override
  String get meetingRenameSpeakerFailed => 'Couldn\'t rename the speaker';

  @override
  String get calendarLinkUpdateFailed => 'Couldn\'t update the calendar link';

  @override
  String get rename => 'Rename';

  @override
  String get notNow => 'Not now';

  @override
  String get meetingSaveVoiceProfileTitle => 'Save voice profile?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Recognize $name automatically in future meetings by saving their voiceprint.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Saved voice profile for $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Couldn\'t save the voice profile';

  @override
  String get voiceProfilesSection => 'Voice profiles';

  @override
  String get voiceProfilesDescription =>
      'Saved voices are recognized automatically in future meetings.';

  @override
  String get voiceProfilesEmpty =>
      'No saved voices yet. Name a speaker in a meeting transcript, then choose \"Save voice profile\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Rename voice profile';

  @override
  String get deleteVoiceProfileTitle => 'Delete voice profile?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Stop recognizing $name? Their saved voiceprint is removed. Names already applied in past meetings are kept.';
  }

  @override
  String get remoteControl => 'Remote control';

  @override
  String get remoteControlListening => 'Listening for devices';

  @override
  String get remoteControlListenerStopped => 'Listener stopped';

  @override
  String get remoteControlStartToAccept =>
      'Start the listener to accept phone connections.';

  @override
  String get remoteControlStartOnLaunch => 'Start on app launch';

  @override
  String get remoteControlWhenOffStaysStopped =>
      'When off, the listener stays stopped until you start it.';

  @override
  String get remoteControlRestartToApply =>
      'Restart the listener to apply changes.';

  @override
  String get remoteControlSignalingUrl => 'Signaling broker URL';

  @override
  String get remoteControlSignalingHint =>
      'wss:// broker that relays the pairing handshake only.';

  @override
  String get remoteControlStunServers => 'STUN servers';

  @override
  String get remoteControlStunHint =>
      'Comma-separated STUN URLs. No TURN by design.';

  @override
  String get remoteControlPwaHost => 'Phone app host';

  @override
  String get remoteControlPwaHostHint =>
      'Where the phone web app is hosted; encoded into the pairing QR.';

  @override
  String get remoteControlNotConfigured =>
      'Add a signaling URL and phone app host to enable pairing.';

  @override
  String get remoteControlPairDevice => 'Pair a device';

  @override
  String get remoteControlScanQr => 'Scan this code with your phone camera.';

  @override
  String get remoteControlAllWorkspacesWarning =>
      'This device will be able to access every workspace on this Mac.';

  @override
  String get remoteControlCopyLink => 'Copy link';

  @override
  String get remoteControlWantsToConnect => 'Wants to connect';

  @override
  String get remoteControlApproveDevice => 'Approve device';

  @override
  String get remoteControlDeviceConnected =>
      'Device connected — approve it to finish pairing.';

  @override
  String remoteControlQrExpiresIn(int minutes) {
    return 'Expires in $minutes min';
  }

  @override
  String get remoteControlPairedDevices => 'Paired devices';

  @override
  String get remoteControlNoPairedDevices => 'No paired devices yet.';

  @override
  String get remoteControlPending => 'Pending confirmation';

  @override
  String get remoteControlActive => 'Active';

  @override
  String get remoteControlRevoked => 'Revoked';

  @override
  String get remoteControlRevoke => 'Revoke';

  @override
  String get remoteControlConfirmDevice => 'Confirm device';

  @override
  String get remoteControlRevokeConfirm =>
      'Revoke this device? It will be disconnected immediately.';

  @override
  String get devicesSettingsDescription =>
      'Pair and manage the phones that can remote-control this app.';

  @override
  String get connectedLabel => 'Connected';

  @override
  String get ideTabGeneral => 'General';

  @override
  String get ideTabExplorer => 'Explorer';

  @override
  String get ideTabSourceControl => 'Source control';

  @override
  String get ideTabPullRequests => 'Pull requests';

  @override
  String get generalSectionTodos => 'Todos';

  @override
  String get generalSectionGoals => 'Goals';

  @override
  String get goalRunStatusActive => 'Active';

  @override
  String get goalRunStatusPaused => 'Paused';

  @override
  String get goalRunStatusCompleted => 'Completed';

  @override
  String get goalRunStatusFailed => 'Failed';

  @override
  String get goalRunStatusCancelled => 'Cancelled';

  @override
  String get goalRunStatusBudgetExhausted => 'Budget exhausted';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Run $run of $max · $cost of $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Run $run · $cost of $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Due $deadline';
  }

  @override
  String get goalRunPause => 'Pause goal';

  @override
  String get goalRunResume => 'Resume goal';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Resume · raise cap to $cap';
  }

  @override
  String get goalRunStop => 'Stop goal';

  @override
  String get generalSectionPlan => 'Plan';

  @override
  String get generalSectionAgents => 'Agents';

  @override
  String get generalSectionTerminals => 'Terminals';

  @override
  String get generalTodosEmpty => 'No todos yet';

  @override
  String get generalAgentsEmpty => 'No agents running';

  @override
  String get generalTerminalsEmpty => 'No terminals open';

  @override
  String get pauseAgent => 'Pause agent';

  @override
  String get resumeAgent => 'Resume agent';

  @override
  String get agentCannotPause =>
      'This agent can\'t be paused — stop it instead.';

  @override
  String get goalClear => 'Clear goal';

  @override
  String get undoLabelGoalClear => 'clear goal';

  @override
  String get todoStatusPending => 'Not started';

  @override
  String get todoStatusInProgress => 'In progress';

  @override
  String get todoStatusCompleted => 'Done';

  @override
  String get reorderTodo => 'Reorder todo';

  @override
  String get focusAgentRun => 'Focus agent run';

  @override
  String get focusTerminal => 'Focus terminal';

  @override
  String get todoEditorTitle => 'Edit todos';

  @override
  String get todoEditorHint =>
      'One item per line. Use - [ ] for pending, - [~] for in progress, - [x] for done.';

  @override
  String get todoNeedsText => 'Add some text after the command';

  @override
  String get todoNotFound => 'No matching todo';

  @override
  String get todoCleared => 'Cleared the todo list';

  @override
  String get todoNothingToCopy => 'Nothing to copy';

  @override
  String todoAdded(String content) {
    return 'Added \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Started \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Completed \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Removed \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'Copied $count items';
  }

  @override
  String todoImported(int count) {
    return 'Imported $count items';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Unknown todo command \"$name\"';
  }

  @override
  String generalAgentTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideNewTerminal => 'New terminal';

  @override
  String get ideNewVmTerminal => 'New terminal (VM)';

  @override
  String get ideOpenChat => 'Open chat';

  @override
  String get ideCloseTab => 'Close tab';

  @override
  String get ideSplitEditor => 'Split editor';

  @override
  String get ideSplitRight => 'Split right';

  @override
  String get ideSplitDown => 'Split down';

  @override
  String get ideSplitLeft => 'Split left';

  @override
  String get ideSplitUp => 'Split up';

  @override
  String get ideCloseGroup => 'Close group';

  @override
  String get ideCloseOthers => 'Close others';

  @override
  String get ideCloseToRight => 'Close to the right';

  @override
  String get ideCloseSaved => 'Close saved';

  @override
  String get ideCloseAll => 'Close all';

  @override
  String get ideSplit => 'Split';

  @override
  String get ideToggleSidebar => 'Toggle sidebar';

  @override
  String get ideNewTab => 'Open editor';

  @override
  String get ideReviewCode => 'Review code';

  @override
  String get ideReviewNoChanges => 'No changes to review';

  @override
  String get ideRevert => 'Revert';

  @override
  String get ideRevertConfirmTitle => 'Revert changes';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Revert $_temp0 to HEAD? This discards working-tree changes.';
  }

  @override
  String get ideRevertConfirmAction => 'Revert';

  @override
  String get ideRevertConfirmCancel => 'Cancel';

  @override
  String get ideRevertUntracked => 'Untracked files can\'t be reverted';

  @override
  String get ideRevertFailed =>
      'Couldn\'t revert the files. The conversation worktree may be unavailable.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0 couldn\'t be reverted (untracked).';
  }

  @override
  String get ideViewSource => 'View source';

  @override
  String get ideSearchMatchCase => 'Match case';

  @override
  String get ideSearchWholeWord => 'Whole word';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Search filters';

  @override
  String get ideSearchFilesToInclude => 'Files to include';

  @override
  String get ideSearchFilesToExclude => 'Files to exclude';

  @override
  String get ideNoOpenTabs => 'No open tabs — use + to open';

  @override
  String get ideBrowserAddressHint => 'Enter address or search';

  @override
  String get ideSimpleWebBrowser => 'Simple web browser';

  @override
  String get ideWebBrowser => 'Web browser';

  @override
  String get ideBrowserEnterUrl =>
      'Enter a URL in the address bar to start browsing';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Save changes to $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Your changes will be lost if you don\'t save them.';

  @override
  String get ideDontSave => 'Don\'t save';

  @override
  String get editorAutoSave => 'Auto save';

  @override
  String get editorAutoSaveDescription =>
      'Automatically save changes in the embedded editor.';

  @override
  String get editorAutoSaveOff => 'Off';

  @override
  String get editorAutoSaveAfterDelay => 'After a delay';

  @override
  String get editorAutoSaveOnFocusChange => 'On focus change';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server is not available on this server';

  @override
  String get ideCodeServerUnavailableHint =>
      'Install code-server (coder/code-server) on the server host, then reopen the editor.';

  @override
  String get ideCodeServerInstalling => 'Preparing editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Open editor in browser';

  @override
  String get ideCodeServerError => 'Couldn\'t open the editor';

  @override
  String get paneSuspendedCaption =>
      'Suspended to save resources — it reloads when focused';

  @override
  String get ideFileSearchFailed => 'Couldn\'t search files';

  @override
  String get ideSearchFilename => 'Filename';

  @override
  String get ideSearchContent => 'Content';

  @override
  String get ideSearchInFiles => 'Search in files';

  @override
  String get ideNoContentMatches => 'No matches';

  @override
  String get ideSourceControlCreatePr => 'Create pull request';

  @override
  String get ideSourceControlNoChanges => 'No changes';

  @override
  String ideSourceControlChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changed',
      one: '1 changed',
    );
    return '$_temp0';
  }

  @override
  String get ideConnectGithub => 'Connect GitHub to view pull requests';

  @override
  String get ideNoConversationPr => 'No pull request for this channel';

  @override
  String get ideFileLoading => 'Loading…';

  @override
  String get ideFileBinary => 'Binary file';

  @override
  String get mcpExternalServers => 'External MCP servers';

  @override
  String get mcpExternalServersDescription =>
      'Connect to external MCP servers (GitHub, Sentry, Postgres, browser automation). Servers you configured for Claude, Cursor, VS Code and other tools are auto-discovered.';

  @override
  String get mcpApprovalMode => 'Tool approval';

  @override
  String get mcpApprovalModeDescription =>
      'Which tool actions run without asking. Reads are always allowed; higher tiers prompt.';

  @override
  String get mcpApprovalAlwaysAsk => 'Always ask';

  @override
  String get mcpApprovalWrite => 'Auto-approve writes';

  @override
  String get mcpApprovalYolo => 'Auto-approve all';

  @override
  String get mcpNoExternalServers => 'No external MCP servers discovered.';

  @override
  String get mcpAuthorize => 'Authorize';

  @override
  String get mcpReconnect => 'Reconnect';

  @override
  String get mcpExternalConnectionsNote =>
      'External MCP servers run on the agent server (shared by desktop and web). Authorizing OAuth servers is only available on the desktop.';

  @override
  String mcpToolsSummary(int count) {
    return '$count tools';
  }

  @override
  String get mcpStatusConnected => 'Connected';

  @override
  String get mcpStatusConnecting => 'Connecting…';

  @override
  String get mcpStatusNeedsAuth => 'Needs authorization';

  @override
  String get mcpStatusFailed => 'Failed';

  @override
  String get mcpStatusCircuitOpen => 'Paused';

  @override
  String get mcpStatusDisabled => 'Disabled';

  @override
  String get providersAndModels => 'Providers & models';

  @override
  String get providersAndModelsDescription =>
      'List every provider the built-in agent can use — set an API key or log in with your browser, see each connected provider\'s models and pricing and govern which providers this workspace may use.';

  @override
  String modelsCountFromProviders(int count, int providers) {
    return '$count models across $providers providers';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sync complete — $applied applied, $failed failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get toggleDetails => 'Toggle details';

  @override
  String get denied => 'Denied';

  @override
  String get allowed => 'Allowed';

  @override
  String allowProviderSemantic(String provider) {
    return 'Allow $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Enabled via $key';
  }

  @override
  String enabledViaAccount(String service) {
    return 'Enabled via $service';
  }

  @override
  String get enabledLabel => 'Enabled';

  @override
  String get disabledLabel => 'Disabled';

  @override
  String disabledSetEnvHint(String keys) {
    return 'Disabled — set $keys or log in';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens context';
  }

  @override
  String get capabilityTools => 'Tools';

  @override
  String get capabilityVision => 'Vision';

  @override
  String get capabilityReasoning => 'Reasoning';

  @override
  String get statusDeprecated => 'Deprecated';

  @override
  String get usageAndCost => 'Usage & cost';

  @override
  String get usageAndCostDescription =>
      'Spend across your agents over the last 7 days, from observed run costs.';

  @override
  String get noUsageYet => 'No usage recorded yet.';

  @override
  String get spentThisWeek => 'spent this week';

  @override
  String get subscriptionUsage => 'Subscription usage';

  @override
  String get subscriptionUsageUnavailable => 'Unavailable';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Partially available';

  @override
  String resetsIn(String duration) {
    return 'Resets in $duration';
  }

  @override
  String get feedbackHelpful => 'This was helpful';

  @override
  String get feedbackNotHelpful => 'This wasn\'t helpful';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Review';

  @override
  String get modeOrchestrate => 'Orchestrate';

  @override
  String get commandRules => 'Command rules';

  @override
  String get commandRulesDescription =>
      'How Control Center decides which shell commands an agent may run, by channel mode.';

  @override
  String get scopeGlobal => 'Always';

  @override
  String get ruleDenied => 'Denied';

  @override
  String get ruleAsk => 'Ask first';

  @override
  String get editorTheme => 'Editor theme';

  @override
  String get editorThemeDescription =>
      'Import a VS Code color theme so the embedded diff and editor match your IDE.';

  @override
  String get editorThemePasteHint =>
      'Paste the contents of a VS Code color-theme JSON file';

  @override
  String get editorThemeImported => 'Theme imported';

  @override
  String get editorThemeInvalid =>
      'That doesn\'t look like a valid VS Code theme';

  @override
  String get importTheme => 'Import theme';

  @override
  String get clearTheme => 'Clear theme';

  @override
  String get openInDiffViewer => 'Open in diff viewer';

  @override
  String get shellCommand => 'Command';

  @override
  String get shellOutput => 'Output';

  @override
  String get planReadyToImplement => 'Ready to implement?';

  @override
  String get planContinueHere => 'Continue here';

  @override
  String get planContinueHereDescription =>
      'Implement the plan in this session';

  @override
  String get planStartNewSession => 'Start new session';

  @override
  String get planStartNewSessionDescription =>
      'Implement in a fresh session with a clean context';

  @override
  String get revertToHere => 'Revert to here';

  @override
  String get revertConfirmBody =>
      'Hide the messages after this point and roll back the agent\'s file changes to this turn? You can undo this.';

  @override
  String get revert => 'Revert';

  @override
  String get revertedToHere => 'Reverted to here';

  @override
  String get nothingToRevert => 'Nothing to revert';

  @override
  String get undoRevert => 'Undo revert';

  @override
  String get revertUndone => 'Revert undone';

  @override
  String get systemBehavior => 'System behavior';

  @override
  String get keepAwakeTitle => 'Keep computer awake while agents run';

  @override
  String get keepAwakeOnSubtitle =>
      'The computer won\'t sleep while an agent is working';

  @override
  String get keepAwakeOffSubtitle =>
      'The computer may sleep even while an agent is working';

  @override
  String get syncEngineSectionTitle => 'Sync engine';

  @override
  String get syncEngineDescription =>
      'Tickets, messaging and notes update live via small incremental changes instead of full snapshots. Turning a toggle off falls that store back to full-snapshot mode — reload the app for the change to take effect.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Messaging';

  @override
  String get syncEngineNotesTitle => 'Notes';

  @override
  String get syncEngineOnSubtitle => 'Live delta sync is active';

  @override
  String get syncEngineOffSubtitle => 'Using full-snapshot sync';

  @override
  String get channels => 'Channels';

  @override
  String get channelsHomeDescription =>
      'Pick a channel from the list, or start a new one.';

  @override
  String get noChannelsYet => 'No channels yet';

  @override
  String get newChannel => 'New channel';

  @override
  String get channelName => 'Channel name';

  @override
  String get channelReposHint => 'Repos to include';

  @override
  String get ideSourceControl => 'Source control';

  @override
  String get stagedChanges => 'Staged changes';

  @override
  String get changes => 'Changes';

  @override
  String get stageFile => 'Stage';

  @override
  String get unstageFile => 'Unstage';

  @override
  String get stageAll => 'Stage all changes';

  @override
  String get unstageAll => 'Unstage all';

  @override
  String get stageChangesToCommit => 'Stage changes to commit';

  @override
  String get syncToPrHead => 'Pull latest PR commits';

  @override
  String get syncedToPrHead => 'Synced to the latest PR commits';

  @override
  String get syncPrHeadDirty => 'Commit or discard your changes before syncing';

  @override
  String get syncPrHeadFailed => 'Couldn\'t sync to the PR head';

  @override
  String get channelLabel => 'Channel';

  @override
  String get keybindingNewChannel => 'New channel';

  @override
  String get keybindingCreateANewChannelDescription => 'Create a new channel';

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get streaming => 'Streaming';

  @override
  String get newMessages => 'New';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get messageTooFarBack => 'Message is too far back to reach';

  @override
  String newMessagesCount(int count) {
    return '$count new';
  }

  @override
  String get agentResponding => 'Agent responding';

  @override
  String get agentFinished => 'Agent finished';

  @override
  String get harnessConnectProviderForModels =>
      'Connect a provider to see models.';

  @override
  String get providerSignOut => 'Sign out';

  @override
  String get providerWaitingForDeviceCode =>
      'Waiting for you to confirm the code in your browser…';

  @override
  String get providerDeviceCodeHint =>
      'Check this code matches the one shown in your browser, then approve.';

  @override
  String get providerPlanUsageLoading => 'Checking plan usage…';

  @override
  String get providerPlanUsageUnavailable => 'This plan didn\'t report usage.';

  @override
  String providerSignOutConfirmTitle(String provider) {
    return 'Sign out of $provider?';
  }

  @override
  String providerSignOutConfirmBody(String provider) {
    return 'Agents using $provider models stop working until you sign in again, which needs the full browser login.';
  }

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Remove the $provider API key?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'The stored key is deleted and cannot be shown again. Agents using $provider models stop working until you paste a new one.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Remove $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'The provider and its stored key are deleted. Agents pinned to its models stop working.';
  }

  @override
  String get providerApiKeyHint => 'Paste an API key';

  @override
  String get providerApiKeyStoredHint => 'Paste another API key to add it';

  @override
  String get providerAddAnotherAccount => 'Add another account';

  @override
  String get providerActiveBadge => 'Active';

  @override
  String get providerOauthAccountFallback => 'OAuth account';

  @override
  String get providerApiKeyFallback => 'API key';

  @override
  String get providerRemoveCredentialConfirmTitle => 'Remove this credential?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Sign out of this account?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agents using $provider fall back to its other keys and accounts. With none left, they stop until you add one.';
  }

  @override
  String get providerBaseUrlHint => 'Base URL (optional)';

  @override
  String get customProviders => 'Custom providers';

  @override
  String get customProvidersDescription =>
      'Any OpenAI- or Anthropic-compatible endpoint — Ollama, LM Studio, vLLM, or a private deployment — with an optional API key.';

  @override
  String get addProvider => 'Add provider';

  @override
  String get noCustomProviders => 'No custom providers yet.';

  @override
  String get providerNameLabel => 'Name';

  @override
  String get apiTypeLabel => 'API type';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'API key (optional)';

  @override
  String get dialectOpenAiCompatible => 'OpenAI compatible';

  @override
  String get dialectAnthropicCompatible => 'Anthropic compatible';

  @override
  String get removeProviderTooltip => 'Remove provider';

  @override
  String get providerLogInWithBrowser => 'Log in with browser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Log in to $provider';
  }

  @override
  String get providerLabel => 'Provider';

  @override
  String get selectProviderToLogin => 'Select a provider to log in';

  @override
  String providerLoginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Waiting for you to authorize in the browser…';

  @override
  String get providerPasteCodeHint => 'Or paste the code from your browser';

  @override
  String get providerCompleteLogin => 'Complete';

  @override
  String get providerConnectedApiKey => 'Connected via API key';

  @override
  String get providerConnectedOauth => 'Connected';

  @override
  String providerConnectedAccount(String account) {
    return 'Connected · $account';
  }

  @override
  String get providerLocalReady => 'Local · ready';

  @override
  String get providerNotConnected => 'Not connected';

  @override
  String get preparingWorkspace => 'Preparing workspace…';

  @override
  String provisioningCloningRepo(String repo) {
    return 'Cloning $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checking out pull request in $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Setting up agent $agent…';
  }

  @override
  String get workspacePrepFailed => 'Workspace setup failed';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count message(s) will send when ready';
  }

  @override
  String get membersNav => 'Members';

  @override
  String get membersSettingsDescription =>
      'People with access to this workspace: roster, invites and audit trail';

  @override
  String get memberRosterLabel => 'Member roster';

  @override
  String get memberRepoAccessAction => 'Repo access';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Repo access for $name';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleGuest => 'Guest';

  @override
  String get removeMemberTitle => 'Remove member';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this workspace? They immediately lose access.';
  }

  @override
  String get unknownUserLabel => 'Unknown user';

  @override
  String get inviteMember => 'Invite member';

  @override
  String get inviteRepoAccessHeader => 'Repository access';

  @override
  String get inviteRepoAccessExplainer =>
      'Only the repositories you check are shared with the invitee, at the level you choose. Everything else stays hidden.';

  @override
  String get grantLevelRead => 'Read';

  @override
  String get grantLevelReview => 'Review';

  @override
  String get grantLevelWrite => 'Write';

  @override
  String get inviteExpiryLabel => 'Expires in';

  @override
  String get expiryOneDay => '1 day';

  @override
  String get expirySevenDays => '7 days';

  @override
  String get expiryThirtyDays => '30 days';

  @override
  String get createInviteAction => 'Create invite';

  @override
  String get inviteOneTimeCodeLabel => 'One-time code';

  @override
  String get inviteCodeShownOnce =>
      'This code is shown only once — copy it now.';

  @override
  String get inviteLinkLabel => 'Invite link';

  @override
  String get inviteRedeemHint =>
      'Share the code with the invitee; they redeem it against your server URL.';

  @override
  String get inviteScanQr => 'Or scan to redeem';

  @override
  String get inviteLoopbackWarningTitle => 'Invite points at a local address';

  @override
  String get inviteLoopbackWarningBody =>
      'Collaborators on other machines won\'t be able to reach this server. Start a tunnel (Settings → Integrations → Share this server) or bind to your network so off-host users can connect.';

  @override
  String get inviteStatusOpen => 'Open';

  @override
  String get inviteStatusUsed => 'Used';

  @override
  String get inviteStatusRevoked => 'Revoked';

  @override
  String get inviteStatusExpired => 'Expired';

  @override
  String inviteCreatedTime(String time) {
    return 'Created $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'expires $date';
  }

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get couldNotLoadMembers => 'Couldn\'t load members';

  @override
  String get couldNotLoadInvites => 'Couldn\'t load invites';

  @override
  String get couldNotLoadActivity => 'Couldn\'t load activity';

  @override
  String get yourDevices => 'Your devices';

  @override
  String get yourDevicesDescription =>
      'Clients paired to your account on this server.';

  @override
  String get noOwnDevices => 'No devices are paired to your account yet';

  @override
  String get renameDeviceTitle => 'Rename device';

  @override
  String get revokeDeviceTitle => 'Revoke device';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Revoke $label? It is disconnected immediately and can no longer reach this server.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Paired $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Last seen $time';
  }

  @override
  String get deviceNeverSeen => 'Never connected';

  @override
  String get profileSectionLabel => 'Profile';

  @override
  String get profileSectionDescription =>
      'How you appear to teammates and in git commit authorship.';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Git author name';

  @override
  String get gitAuthorEmailLabel => 'Git author email';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Idle';

  @override
  String get presenceTyping => 'Typing…';

  @override
  String get presenceAgentThinking => 'Thinking';

  @override
  String get presenceAgentRunning => 'Running';

  @override
  String get presenceAgentBlocked => 'Blocked';

  @override
  String get presenceAgentDone => 'Done';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Who\'s online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Turn on do not disturb';

  @override
  String get dndTooltipOff => 'Turn off do not disturb';

  @override
  String get startPresenting => 'Start presenting';

  @override
  String get stopPresenting => 'Stop presenting';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name is presenting';
  }

  @override
  String get spotlightLeave => 'Leave';

  @override
  String typingIndicator(String name) {
    return '$name is typing…';
  }

  @override
  String get ideTabNotes => 'Notes';

  @override
  String get ideSidebarAllViews => 'All views';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'All views ($count hidden)';
  }

  @override
  String get ideSidebarPinView => 'Pin to sidebar';

  @override
  String get ideSidebarUnpinView => 'Unpin from sidebar';

  @override
  String get notesEmptyHint =>
      'Add a note for anyone who picks up this conversation…';

  @override
  String get notesEditTooltip => 'Edit note';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Updated by $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name is editing';
  }

  @override
  String get notesSaveFailed => 'Couldn\'t save the note';

  @override
  String get reactionAddTooltip => 'Add reaction';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'React with $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomy';

  @override
  String get autonomyProposeOnly => 'Propose only';

  @override
  String get autonomyActWithApproval => 'Act with approval';

  @override
  String get autonomyActFreely => 'Act freely';

  @override
  String get autonomyDefaultOption => 'Default';

  @override
  String get checkerLabel => 'Checker';

  @override
  String get checkerNone => 'None';

  @override
  String get checkerCaption =>
      'The checker reviews other agents\' completed runs.';

  @override
  String get takeoverTooltip => 'Take over the worktree';

  @override
  String get takeoverBannerSelf =>
      'You have taken over this conversation\'s worktree';

  @override
  String takeoverBannerOther(String name) {
    return '$name has taken over this conversation\'s worktree';
  }

  @override
  String get handBackButton => 'Hand back';

  @override
  String get handBackDialogTitle => 'Hand back the worktree';

  @override
  String get handBackDialogNoteHint => 'Optional note for the agent…';

  @override
  String takeoverFailed(String message) {
    return 'Couldn\'t take over: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Couldn\'t hand back: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Plans';

  @override
  String get plansSubtitle => 'Active plans, plan documents and playbooks';

  @override
  String get plansActiveSection => 'Active plans';

  @override
  String get plansDocumentsSection => 'Plan documents';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'No active plans yet.';

  @override
  String get plansNoDocuments => 'No plan documents yet.';

  @override
  String get plansNoPlaybooks => 'No playbooks yet.';

  @override
  String get planNotFound => 'Plan not found.';

  @override
  String get planOpenInStudio => 'Open';

  @override
  String get planNodeTitle => 'Title';

  @override
  String get planNodeDescription => 'Description';

  @override
  String get planNodeDescriptionHint => 'What this step should do…';

  @override
  String get planNodeApplyDescription => 'Apply';

  @override
  String get planNodeRole => 'Role';

  @override
  String get planNodeDependencies => 'Depends on';

  @override
  String get planNodeDependenciesHint => 'Add a dependency';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dependencies',
      one: '1 dependency',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'No dependencies, so this runs as soon as the plan starts';

  @override
  String get planNodeOutputSchema => 'Output schema (JSON)';

  @override
  String get planNodeEstimate => 'Estimate';

  @override
  String get planNodeProvenance => 'Provenance';

  @override
  String get planNodeAlreadyExecuted =>
      'Already executed — editing forks the plan from here.';

  @override
  String get planNewNodeTitle => 'New step';

  @override
  String get planEstimateNoHistory => 'No history yet';

  @override
  String get planEstimateBlastUnknown => 'Blast radius: unknown';

  @override
  String get planEstimatePartial => 'partial';

  @override
  String get planEstimateAction => 'Estimate';

  @override
  String planEstimateDuration(String range) {
    return 'Duration $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Blast radius: $files files, $symbols symbols';
  }

  @override
  String get planApprove => 'Approve plan';

  @override
  String get planApproveSelectedNodes => 'Approve selected';

  @override
  String get planReject => 'Reject';

  @override
  String get planCancel => 'Cancel run';

  @override
  String get planContinueNode => 'Continue node';

  @override
  String get planTotalNotEstimated => 'Not estimated yet';

  @override
  String get planBudgetExceeded => 'over budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'budget ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versions';

  @override
  String get planNoRevisions => 'No revisions yet.';

  @override
  String get planDiffIdentical => 'No changes.';

  @override
  String get planDiffGoalChanged => 'Goal changed';

  @override
  String get planDiffBudgetChanged => 'Budget changed';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Changes from v$fromRev to v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Added $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Removed $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Changed $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Edge added: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Edge removed: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Role added: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Role removed: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Role reassigned: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan replanned: you approved v$approved, it is now v$current. Review the diff before it continues.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Actual cost: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Run';

  @override
  String get planPlaybookDelete => 'Delete playbook';

  @override
  String get planPlaybookProposed =>
      'Plan proposed — approve it in Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Anchor ticket';

  @override
  String get planPlaybookPickTicket => 'Pick a ticket…';

  @override
  String get planPlaybookProposeRun => 'Propose plan';

  @override
  String get planPlaybookRepoHint => 'A repository id';

  @override
  String get planPlaybookAgentHint => 'An agent id';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Run $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count params';
  }

  @override
  String get reviewStudioTitle => 'Review studio';

  @override
  String get reviewStudioWalkthrough => 'Walkthrough';

  @override
  String get reviewStudioContract => 'API contract';

  @override
  String get reviewStudioVisual => 'Visual diff';

  @override
  String get reviewStudioBlastRadius => 'Blast radius';

  @override
  String get reviewStudioRecompute => 'Recompute';

  @override
  String get reviewStudioCohortsHeader => 'Cohorts';

  @override
  String get reviewStudioNoCohorts =>
      'No cohorts yet — run analysis to group this PR by meaning.';

  @override
  String get reviewStudioGroupedByPath => 'Grouped by path (repo not indexed)';

  @override
  String get reviewStudioIndexRepo => 'Index repo';

  @override
  String reviewStudioFilesCount(int count) {
    return '$count files';
  }

  @override
  String get reviewStudioFilesInCohort => 'Files in this cohort';

  @override
  String get reviewStudioSelectCohort => 'Select a cohort to see its summary.';

  @override
  String get reviewStudioSummaryEmpty => 'No summary for this cohort yet.';

  @override
  String get reviewStudioNoAxes => 'No review axes have run yet.';

  @override
  String get reviewAxisCorrectness => 'Correctness';

  @override
  String get reviewAxisSecurity => 'Security';

  @override
  String get reviewAxisTestGap => 'Test gaps';

  @override
  String get reviewAxisPerformance => 'Performance';

  @override
  String get reviewAxisVisual => 'Visual';

  @override
  String get reviewAxisApiContract => 'API contract';

  @override
  String get reviewAxisPass => 'Pass';

  @override
  String get reviewAxisWarn => 'Warn';

  @override
  String get reviewAxisFail => 'Fail';

  @override
  String get reviewAxisPartial => 'Partial';

  @override
  String get reviewAxisUnavailable => 'Unavailable';

  @override
  String get reviewStudioVerdictShip => 'Ship';

  @override
  String get reviewStudioVerdictHold => 'Hold';

  @override
  String get reviewStudioVerdictBlock => 'Block';

  @override
  String get reviewStudioVerdictClear => 'No axis blocks the merge.';

  @override
  String reviewStudioBlockingAxes(String axes) {
    return '$axes block the merge';
  }

  @override
  String get reviewStudioNoContractChanges =>
      'No API contract changes in this PR.';

  @override
  String get reviewStudioBreaking => 'Breaking';

  @override
  String reviewStudioBreakingCount(int count) {
    return '$count breaking';
  }

  @override
  String get reviewStudioDerivedContract => 'Derived (advisory)';

  @override
  String get reviewStudioApprove => 'Approve';

  @override
  String get reviewStudioReject => 'Reject';

  @override
  String get reviewStudioApproved => 'Approved';

  @override
  String get reviewStudioRejected => 'Rejected';

  @override
  String get reviewStudioNoVisualChanges => 'No visual changes detected.';

  @override
  String get reviewStudioVisualUnavailable => 'Visual diff unavailable';

  @override
  String get reviewStudioApproveChange => 'Approve intended change';

  @override
  String reviewStudioChangedRegion(String percent) {
    return '$percent% changed';
  }

  @override
  String get reviewStudioRenderedOnHost => 'Rendered on host';

  @override
  String get reviewStudioVisualAdded => 'Added';

  @override
  String get reviewStudioVisualChanged => 'Changed';

  @override
  String get reviewStudioVisualRemoved => 'Removed';

  @override
  String get reviewStudioVisualApproved => 'Approved';

  @override
  String get reviewStudioVisualUnchanged => 'Unchanged';

  @override
  String get reviewStudioSelectFileForBlast =>
      'Select a changed file to see its blast radius.';

  @override
  String get reviewStudioNotIndexed =>
      'Repo not indexed — blast radius unavailable.';

  @override
  String reviewStudioAffectedCount(int count) {
    return '$count symbols affected';
  }

  @override
  String get reviewStudioDirectCallers => 'Direct callers';

  @override
  String reviewStudioTransitiveAt(int depth) {
    return 'Transitive (hop $depth)';
  }

  @override
  String get recentLabel => 'Recent';

  @override
  String get cheatSheetTitle => 'Keyboard shortcuts';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'This screen';

  @override
  String get cheatSheetReservedInBrowser => 'Browser reserved';

  @override
  String get keybindingCheatSheet => 'Keyboard shortcuts';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Show the keyboard shortcut cheat-sheet for the current screen';

  @override
  String get runPlaybookLabel => 'Run playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Undo';

  @override
  String get keybindingRedo => 'Redo';

  @override
  String get keybindingUndoLastActionDescription =>
      'Undo your last reversible action';

  @override
  String get keybindingRedoLastActionDescription =>
      'Redo the last undone action';

  @override
  String get undone => 'Undone';

  @override
  String get redone => 'Redone';

  @override
  String get undoFailed => 'Couldn\'t undo';

  @override
  String get undoLabelTicketEdit => 'ticket edit';

  @override
  String get undoLabelMessageEdit => 'message edit';

  @override
  String get undoLabelTodoStatus => 'todo status';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxReview => 'Review';

  @override
  String get inboxOpen => 'Open';

  @override
  String get inboxAllCaughtUp => 'You\'re all caught up';

  @override
  String get inboxGitHubDownTitle => 'GitHub might be down';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub is reporting $status, so pull requests may be missing from this list rather than actually done.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Couldn\'t confirm your GitHub account';

  @override
  String get inboxGitHubIdentityBody =>
      'The inbox is sorted by who you are on GitHub. Until that loads it stays empty, even when pull requests are waiting for you.';

  @override
  String get inboxSeverityBlocking => 'Blocked';

  @override
  String get inboxSeverityWaiting => 'Waiting';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Sync failed';

  @override
  String get inboxNeedsYourAttention => 'Needs your attention';

  @override
  String get inboxSectionNeedsYourReview => 'Needs your review';

  @override
  String get inboxSectionReturnedToYou => 'Returned to you';

  @override
  String get inboxSectionApproved => 'Approved';

  @override
  String get inboxSectionDrafts => 'Drafts';

  @override
  String get inboxSectionWaitingForReviewers => 'Waiting for reviewers';

  @override
  String get inboxSectionMergingAndMerged => 'Merging and recently merged';

  @override
  String get inboxSectionWaitingForAuthor => 'Waiting for author';

  @override
  String get inboxColumnTitle => 'Title';

  @override
  String get inboxColumnChanges => 'Changes';

  @override
  String get inboxColumnUpdated => 'Updated';

  @override
  String get inboxReviewApproved => 'Approved';

  @override
  String get inboxReviewChangesRequested => 'Changes requested';

  @override
  String get inboxHeroSubtitle =>
      'Every pull request that involves you, sorted by what happens next.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests need your review',
      one: '1 pull request needs your review',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count returned to you',
      one: '1 returned to you',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'That change didn\'t save and was reverted';

  @override
  String get offlinePendingLabel => 'pending';

  @override
  String get offlineSyncingLabel => 'syncing';

  @override
  String get copyLinkLabel => 'Copy link to this page';

  @override
  String get fleetTabLabel => 'Fleet';

  @override
  String get evalsTabLabel => 'Evals';

  @override
  String get agentsSectionLabel => 'Agents';

  @override
  String get fleetWorkersTitle => 'Workers';

  @override
  String get fleetWorkersSubtitle => 'Machines available to run jobs';

  @override
  String get fleetJobsTitle => 'Jobs';

  @override
  String get fleetJobsSubtitle => 'Work distributed across the fleet';

  @override
  String get fleetNoWorkers =>
      'No workers yet — a second machine running `cc_worker --server <url>` joins the fleet.';

  @override
  String get fleetNoJobs => 'No jobs.';

  @override
  String get fleetError => 'Couldn\'t load the fleet';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cores',
      one: '1 core',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'No heartbeat yet';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Last error: $error';
  }

  @override
  String get fleetDrain => 'Drain';

  @override
  String get fleetResume => 'Resume';

  @override
  String get fleetRevoke => 'Revoke';

  @override
  String get fleetRemove => 'Remove';

  @override
  String get fleetRevokeTitle => 'Revoke worker?';

  @override
  String fleetRevokeBody(String name) {
    return 'Revoke $name? Its session ends and any active jobs are reassigned.';
  }

  @override
  String get fleetRemoveTitle => 'Remove worker?';

  @override
  String fleetRemoveBody(String name) {
    return 'Remove $name from the fleet? This deletes its record.';
  }

  @override
  String get fleetActionFailed => 'Action failed';

  @override
  String get fleetJobUnassigned => 'Unassigned';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max attempts';
  }

  @override
  String get fleetPlacementReasons => 'Placement decisions';

  @override
  String get fleetNoPlacements => 'No placement decisions yet.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Draining';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Incompatible';

  @override
  String get fleetStatusRevoked => 'Revoked';

  @override
  String get fleetJobStatusQueued => 'Queued';

  @override
  String get fleetJobStatusRunning => 'Running';

  @override
  String get fleetJobStatusSucceeded => 'Succeeded';

  @override
  String get fleetJobStatusFailed => 'Failed';

  @override
  String get fleetJobStatusCancelled => 'Cancelled';

  @override
  String get evalsNoSuites => 'No eval suites yet.';

  @override
  String get evalsError => 'Couldn\'t load evals';

  @override
  String get evalsStarterBadge => 'Starter';

  @override
  String evalsDefaultBatch(int count) {
    return 'Default batch of $count';
  }

  @override
  String get evalsRecentRuns => 'Recent runs';

  @override
  String get evalsNoRuns => 'No runs yet.';

  @override
  String get evalsPassRate => 'Pass rate';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'by $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval finished — $rate passed';
  }

  @override
  String get evalsRunFailed => 'Couldn\'t run the suite';

  @override
  String get evalsRun => 'Run';

  @override
  String get evalsStatusQueued => 'Queued';

  @override
  String get evalsStatusRunning => 'Running';

  @override
  String get evalsStatusPassed => 'Passed';

  @override
  String get evalsStatusFailed => 'Failed';

  @override
  String get bannerMeetingJoin => 'Join';

  @override
  String get bannerMeetingRecordAndLink => 'Record & link';

  @override
  String get bannerCalendarReconnect => 'Reconnect';

  @override
  String get bannerView => 'View';

  @override
  String get soundscapeTitle => 'Soundscapes';

  @override
  String get soundscapePlay => 'Play';

  @override
  String get soundscapePause => 'Pause';

  @override
  String get soundscapeMoodLabel => 'Mood';

  @override
  String get soundscapeMoodFocus => 'Focus';

  @override
  String get soundscapeMoodRelax => 'Relax';

  @override
  String get soundscapeMoodSleep => 'Sleep';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Tune';

  @override
  String get soundscapeTuneMellow => 'Mellow';

  @override
  String get soundscapeTuneBright => 'Bright';

  @override
  String get soundscapeTuneEnergetic => 'Energetic';

  @override
  String get soundscapeTuneSpacy => 'Spacy';

  @override
  String get soundscapeTuneResetHint => 'Double-tap to reset';

  @override
  String get soundscapeSceneLabel => 'Now playing';

  @override
  String get soundscapeSceneLoading => 'Tuning the ambience…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Location';

  @override
  String get soundscapeLocationDetecting => 'Detecting location…';

  @override
  String get soundscapeLocationAutoNote =>
      'Location is detected automatically from this workspace.';

  @override
  String get soundscapeRefreshWeather => 'Refresh weather';

  @override
  String get soundscapeAutoStartLabel => 'Start with focus mode';

  @override
  String get soundscapeAutoStartDescription =>
      'Play a soundscape automatically when you start a focus session.';

  @override
  String get soundscapeReturnToApp => 'Return to app';

  @override
  String get soundscapePopOut => 'Pop out player';

  @override
  String get newParenthesis => 'New parenthesis';

  @override
  String get parenthesisTitleHint => 'e.g. quick fix';

  @override
  String get discussion => 'Discussion';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Saving…';

  @override
  String get saved => 'Saved';

  @override
  String get saveFailed => 'Couldn\'t save';

  @override
  String get commitAndPush => 'Commit & push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit & sync';

  @override
  String get committed => 'Committed';

  @override
  String get commitAmended => 'Commit amended';

  @override
  String get commitFailed => 'Commit failed';

  @override
  String get moreCommitActions => 'More commit actions';

  @override
  String get sourceControl => 'Source control';

  @override
  String fixFindingTitle(String location) {
    return 'Fix: $location';
  }

  @override
  String get reviewSplitLayout => 'Review split';

  @override
  String get openInEditor => 'Open in editor';

  @override
  String uncommittedChanges(int count) {
    return '$count uncommitted changes';
  }

  @override
  String get commitMessageHint => 'Commit message';

  @override
  String get pushedToPr => 'Pushed to the PR';

  @override
  String get pushFailed => 'Push failed';

  @override
  String get openAtPrHead => 'Open at PR head';

  @override
  String get reviewFindings => 'Findings';

  @override
  String get treeLabel => 'Tree';

  @override
  String get toggleFileTree => 'Show or hide the file tree';

  @override
  String get diffViewSettings => 'Diff view settings';

  @override
  String get splitViewLabel => 'Split';

  @override
  String get unifiedViewLabel => 'Unified';

  @override
  String get wrapLines => 'Wrap lines';

  @override
  String get shiftClickSelectRange => 'Shift-click to select a range';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Small PR — $files, ~$minutes min to review';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Medium PR — $files, block ~$minutes min to review';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Large PR — $files, consider splitting before review';
  }

  @override
  String get searchInFiles => 'Search in files';

  @override
  String get showFileList => 'Show file list';

  @override
  String get searchInFilesHintField => 'Search in files…';

  @override
  String get searchInFilesHint => 'Search across the pull request\'s files';

  @override
  String get searchNoResults => 'No results found';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Discard $_temp0 to HEAD? This cannot be undone.';
  }

  @override
  String get discardAll => 'Discard all';

  @override
  String get discardFailed => 'Failed to discard changes';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Discarded $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted files',
      one: '1 file',
    );
    return 'Discarded $_temp0; $skipped skipped (untracked)';
  }

  @override
  String get prWorktreeUnavailable => 'Workspace not ready';

  @override
  String get prWorktreeUnavailableHint =>
      'Preparing the pull request\'s files failed. Reopen the pull request to try again.';

  @override
  String get timestampRelativeLabel => 'Relative';

  @override
  String get timestampRawLabel => 'Timestamp';

  @override
  String get copyTimestamp => 'Copy timestamp';

  @override
  String get copiedTimestamp => 'Copied timestamp';

  @override
  String get previewDeployment => 'Preview deployment';

  @override
  String previewDeploymentTab(String site) {
    return 'Preview: $site';
  }

  @override
  String get askForReview => 'Ask for review…';

  @override
  String get closePrsConfirmTitle => 'Close pull requests?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Close $count pull requests?',
      one: 'Close 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Closed $count pull requests',
      one: 'Closed 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assigned $count pull requests',
      one: 'Assigned 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Requested review on $count pull requests',
      one: 'Requested review on 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions failed',
      one: '1 action failed',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'View source';

  @override
  String get diagramHideSource => 'Hide source';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Diagram preview unavailable ($reason)';
  }

  @override
  String get planUnavailable => 'Plan unavailable';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Approve and run';

  @override
  String get planStatusDraft => 'Draft';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan approved';

  @override
  String get planStatusRejected => 'Plan rejected';

  @override
  String get planStatusSuperseded => 'Plan superseded';

  @override
  String planRevisionLabel(int revision) {
    return 'Revision $revision';
  }

  @override
  String get adapterEnforcementTitle => 'What this adapter enforces';

  @override
  String get enforcementFiltersToolSurface => 'Control Center picks the tools';

  @override
  String get enforcementInterceptsToolCalls =>
      'Every call is gated before it runs';

  @override
  String get enforcementObservesCompletionContract =>
      'The run is held to its deliverable';

  @override
  String get enforcementNativeToolsInterceptable =>
      'The runner\'s own tools are visible';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'In-process tools are sandboxed';

  @override
  String get enforcementYes => 'Yes';

  @override
  String get enforcementNo => 'No';

  @override
  String get adapterEnforcementCaveats => 'Caveats';

  @override
  String get enforcementSummaryModesEnforced => 'Modes enforced';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modes not enforced';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caveats',
      one: '1 caveat',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Read-only modes are not structural: Control Center cannot remove this runner\'s own tools.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'No pre-execution gate: only MCP tool calls pass through Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'The runner\'s own file and shell tools never reach Control Center; the OS sandbox is the only floor under them.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'In-process file tools run outside the sandbox, so the tool surface is the only filesystem boundary.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center cannot nudge or fail a run that ends without producing its deliverable.';

  @override
  String get modeDegraded => 'Degraded';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$mode mode on $adapter relies on the sandbox only; the agent\'s own file tools are not intercepted.';
  }

  @override
  String get artifactUnavailable => 'Artifact unavailable';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisions';
  }

  @override
  String get artifactShowMore => 'Show more';

  @override
  String get artifactShowLess => 'Show less';

  @override
  String get artifactCopy => 'Copy';

  @override
  String get artifactCopied => 'Artifact copied';

  @override
  String get artifactsTabLabel => 'Artifacts';

  @override
  String get artifactsEmptyTitle => 'No artifacts yet';

  @override
  String get artifactsEmptyBody =>
      'When an agent publishes a table, chart, or diagram here, it appears in this list.';

  @override
  String get artifactRevisionPickerLabel => 'Revision';

  @override
  String get artifactRestoreRevision => 'Restore this revision';

  @override
  String get artifactOpenInTab => 'Open in tab';

  @override
  String get artifactTitleFallback => 'Artifact';

  @override
  String get providerGenerationLabel => 'Generation defaults';

  @override
  String get providerGenerationHint =>
      'Leave a field empty to use the endpoint\'s own default. Models publish their own output ceilings and sampling recipes; serving one at other values can degrade it.';

  @override
  String get providerMaxTokensLabel => 'Max output tokens';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Generation defaults saved';

  @override
  String get providerGenerationInvalid =>
      'Check the values: max output tokens and top-k must be positive, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Overridden';

  @override
  String get channelFlyoutNeedsInput => 'Needs input';

  @override
  String get channelFlyoutPreparing => 'Preparing';

  @override
  String get channelFlyoutSetupFailed => 'Setup failed';

  @override
  String get channelFlyoutNeverRun => 'No agent has run here yet';

  @override
  String channelFlyoutContextUsage(String used, String percent) {
    return 'Context window $used used, $percent full';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subagents',
      one: '1 subagent',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'not pushed';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” only exists in this conversation';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub has never seen this branch, so a pull request cannot use it yet. Publishing pushes the commits already in the worktree — uncommitted changes are left alone.';

  @override
  String get publishBranch => 'Publish branch';

  @override
  String branchPublished(String branch) {
    return 'Published “$branch” to origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch published. $count uncommitted change(s) were not included.';
  }

  @override
  String get composePrLoadingBranches => 'Loading branches from GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Could not load branches from GitHub. Type a branch name, or check the GitHub connection.';

  @override
  String get composePrSubtitleFromChannel =>
      'From this conversation’s branch — publish it first if GitHub hasn’t seen it';

  @override
  String get obsTabInsights => 'Insights';

  @override
  String get obsTabLive => 'Live';

  @override
  String get obsTabQuality => 'Quality';

  @override
  String get obsScreenSubtitle =>
      'Live agent control, cost attribution, quotas and quality signals';

  @override
  String get obsRangeLast24h => 'Last 24 hours';

  @override
  String get obsRangeLast7d => 'Last 7 days';

  @override
  String get obsRangeLast30d => 'Last 30 days';

  @override
  String get obsRangeAll => 'All time';

  @override
  String get obsAddFilter => 'Add filter';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Role';

  @override
  String get obsKpiTotalRuns => 'Total runs';

  @override
  String get obsKpiTotalCost => 'Total cost';

  @override
  String get obsKpiErrorRate => 'Error rate';

  @override
  String get obsKpiCacheRate => 'Cache rate';

  @override
  String get obsKpiTokensPerSec => 'Tokens / sec';

  @override
  String get obsKpiAvgLatency => 'Avg latency';

  @override
  String get obsKpiTtft => 'Time to first token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs previous period';
  }

  @override
  String get obsChartActivity => 'Activity';

  @override
  String get obsChartCost => 'Cost over time';

  @override
  String get obsLegendRuns => 'Runs';

  @override
  String get obsLegendErrors => 'Errors';

  @override
  String get obsAgentsTitle => 'Agents';

  @override
  String obsShowAllAgents(int count) {
    return 'Show all $count agents';
  }

  @override
  String get obsShowFewerAgents => 'Show fewer';

  @override
  String get obsRunsTitle => 'Runs';

  @override
  String get obsNoRunsInRange => 'No runs in this range';

  @override
  String get obsColTime => 'Time';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Duration';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Cost';

  @override
  String get obsColErrors => 'Errors';

  @override
  String get obsColRuns => 'Runs';

  @override
  String get obsColAvgLatency => 'Avg latency';

  @override
  String get obsColLastActive => 'Last active';

  @override
  String get obsStatusPending => 'Pending';

  @override
  String get obsStatusRunning => 'Running';

  @override
  String get obsStatusCompleted => 'Completed';

  @override
  String get obsStatusError => 'Error';

  @override
  String get obsRosterLoadError => 'Couldn\'t load the agent roster.';

  @override
  String get obsRosterEmpty => 'No agents yet';

  @override
  String get obsRosterEmptyDescription =>
      'Dispatch an agent and it will appear here live — status, current tool, tokens, cost.';

  @override
  String get obsKillAgent => 'Kill agent';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Cost by role';

  @override
  String get obsCostByRoleSubtitle =>
      'Where this workspace spends, by agent role';

  @override
  String get obsRoleMain => 'Main';

  @override
  String get obsRoleSubagents => 'Subagents';

  @override
  String get obsRoleAdvisor => 'Advisor';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Main: $main · subagents: $sub · advisor: $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Token model (5 axes)';

  @override
  String get obsTokenModelSubtitle =>
      'Every token this workspace has spent, by axis';

  @override
  String get obsAxisInput => 'Input';

  @override
  String get obsAxisOutput => 'Output';

  @override
  String get obsAxisReasoning => 'Reasoning';

  @override
  String get obsAxisCacheRead => 'Cache read';

  @override
  String get obsAxisCacheWrite => 'Cache write';

  @override
  String get obsTotalTokens => 'Total tokens';

  @override
  String get obsCacheDiscountNote =>
      'Cache-read tokens are billed at a discount, so they cost far less than the same volume of fresh input.';

  @override
  String get obsByModelTitle => 'By model';

  @override
  String get obsByModelSubtitle => 'Token and cost usage per model';

  @override
  String get obsNoModelUsage => 'No model usage recorded yet.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String obsTokensSuffix(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get obsPerRunTitle => 'Per-run';

  @override
  String get obsPerRunSubtitle => 'Typical token cost of a single run';

  @override
  String get obsMedianRunTokens => 'Median run tokens';

  @override
  String get obsMedianRunTokensSub => 'Midpoint across all runs';

  @override
  String get obsRunsInWorkspace => 'In this workspace';

  @override
  String get obsCostShare => 'Cost share';

  @override
  String get obsQuotaConfiguredLimits => 'Configured limits';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Usage against the ceilings you set, worst status first.';

  @override
  String get obsQuotaAddLimit => 'Add limit';

  @override
  String get obsQuotaNoLimits =>
      'No quota limits configured yet — add one to track usage against a ceiling.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Remove $title limit';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Resets in $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Usage windows';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Observed usage across all providers, no ceiling applied.';

  @override
  String get obsQuotaNoUsage => 'No usage recorded yet.';

  @override
  String get obsQuotaTokensUsed => 'Tokens used';

  @override
  String get obsQuotaRequests => 'Requests';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'requests';

  @override
  String get obsQuotaUnitCost => 'cost';

  @override
  String get obsQuotaAddLimitTitle => 'Add quota limit';

  @override
  String get obsQuotaProviderLabel => 'Provider';

  @override
  String get obsQuotaWindowLabel => 'Window';

  @override
  String get obsQuotaUnitLabel => 'Unit';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limit ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'In US cents (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Warning';

  @override
  String get obsQuotaStatusExhausted => 'Exhausted';

  @override
  String get obsQuotaStatusUnknown => 'Unknown';

  @override
  String get obsGoalNoActiveTitle => 'No active goal';

  @override
  String get obsGoalNoActiveBody =>
      'Set a goal to give the agents an objective and an optional token budget. As runs complete, the budget fills and the agents are nudged to wrap up once it is nearly spent.';

  @override
  String get obsGoalSetGoal => 'Set a goal';

  @override
  String get obsGoalTokenBudget => 'Token budget';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens left';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (no budget set)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokens used';

  @override
  String get obsGoalElapsed => 'Elapsed';

  @override
  String get obsGoalWrapUp => 'Wrap up';

  @override
  String get obsGoalClear => 'Clear goal';

  @override
  String get obsGoalFallbackTitle => 'Goal';

  @override
  String get obsGoalSubtitle => 'Goal Mode budget';

  @override
  String get obsGoalStatusActive => 'Active';

  @override
  String get obsGoalStatusPaused => 'Paused';

  @override
  String get obsGoalStatusBudgetLimited => 'Budget limited';

  @override
  String get obsGoalStatusComplete => 'Complete';

  @override
  String get obsGoalStatusDropped => 'Dropped';

  @override
  String get obsGoalObjectiveLabel => 'Objective';

  @override
  String get obsGoalBudgetLabel => 'Token budget (optional)';

  @override
  String get obsGoalSetAction => 'Set goal';

  @override
  String get obsBenchmarkCaption =>
      'A scored view of recent agent runs — pass/fail, reward and spend-per-task.';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Success %';

  @override
  String get obsBenchmarkPassed => 'Passed';

  @override
  String get obsBenchmarkFailed => 'Failed';

  @override
  String get obsBenchmarkErrors => 'Errors';

  @override
  String get obsBenchmarkSpend => 'Spend';

  @override
  String get obsBenchmarkCostPerTask => 'Cost / task';

  @override
  String get obsBenchmarkTrials => 'Trials';

  @override
  String get obsBenchmarkNoTrials => 'No runs to score yet.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'And $count more',
      one: 'And 1 more',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Pass';

  @override
  String get obsBenchmarkTrialFail => 'Fail';

  @override
  String get obsBenchmarkTrialError => 'Error';

  @override
  String get obsBenchmarkTrialRunning => 'Running';

  @override
  String get obsBenchmarkReward => 'Reward';

  @override
  String get obsBenchmarkReport => 'Report';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copy markdown';

  @override
  String get obsBenchmarkCopied => 'Report copied to clipboard';

  @override
  String get obsBehaviorCaption =>
      'These are frustration signals parsed from your own messages — a read on conversation health, not a score for the agents. Computed locally; nothing leaves this device.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Messages analyzed';

  @override
  String get obsBehaviorTotalSignals => 'Total signals';

  @override
  String get obsBehaviorYelling => 'Yelling';

  @override
  String get obsBehaviorProfanity => 'Profanity';

  @override
  String get obsBehaviorAnguish => 'Anguish';

  @override
  String get obsBehaviorNegation => 'Negation';

  @override
  String get obsBehaviorRepetition => 'Repetition';

  @override
  String get obsBehaviorBlame => 'Blame';

  @override
  String get obsBehaviorConversationsTitle => 'Most-frustrated conversations';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ranked by signal density across your messages.';

  @override
  String get obsBehaviorNoSignals =>
      'No frustration signals detected — smooth sailing.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count messages analyzed';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signals';
  }

  @override
  String get obsAgentStatusIdle => 'Idle';

  @override
  String get obsAgentStatusParked => 'Parked';

  @override
  String get obsAgentStatusAborted => 'Aborted';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit => 'No checks have run on this commit.';

  @override
  String get ciCdChecks => 'CI/CD checks';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Running — $count jobs',
      one: 'Running — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All checks passed — $count jobs',
      one: 'All checks passed — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Completed — $count jobs',
      one: 'Completed — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobs',
      one: '1 job',
    );
    return '$failed of $_temp0 failed';
  }

  @override
  String checksFailingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failing',
      one: '1 failing',
    );
    return '$_temp0';
  }

  @override
  String get checkCompletedSuccessfully => 'Completed successfully';

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending => 'Logs will appear here when the job finishes.';

  @override
  String get jobLogsUnavailable => 'Logs aren\'t available for this job.';

  @override
  String get noLogsForStep => 'No logs captured for this step.';

  @override
  String get jobLogsTruncated =>
      'Log truncated — showing the most recent output.';

  @override
  String get fullLog => 'Full log';

  @override
  String get copyLogs => 'Copy logs';

  @override
  String get resizeGraph => 'Drag to resize the graph';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Started $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Completed $time';
  }

  @override
  String get chatBridgesTitle => 'Chat bridges';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Mention the bot in $provider to put an agent on something, or file tickets with $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Connect $provider';
  }

  @override
  String get chatDisconnectProvider => 'Disconnect';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName in $teamName';
  }

  @override
  String get chatStateLive => 'Live';

  @override
  String get chatStateConnecting => 'Connecting…';

  @override
  String get chatStateError => 'Connection error';

  @override
  String get chatNotConnected => 'Not connected';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Live streaming is off for this $provider app — replies arrive as one message.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Only an admin can connect $provider for this workspace.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Create a $provider app, then paste its credentials here. Control Center connects out to $provider, so this server needs no public address.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Open $provider console';
  }

  @override
  String get chatOpenSetupGuide => 'Setup guide';

  @override
  String get chatFieldBotToken => 'Bot token';

  @override
  String get chatFieldAppToken => 'App-level token';

  @override
  String get chatFieldConfigRefreshToken => 'App configuration token';

  @override
  String chatFieldOptional(String label) {
    return '$label (optional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Link my $provider account';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Link your $provider account so messages you send there are attributed to you.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Linked to $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Link your $provider account';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Send this command to the bot in $provider. It works once and expires in 15 minutes.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Your $provider account is now linked — messages you send there are attributed to you.';
  }

  @override
  String get chatLinkedAccounts => 'Linked accounts';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'No one has linked their $provider account yet.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked accounts',
      one: '1 linked account',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · matched by email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · linked with a code';
  }

  @override
  String get chatUnlink => 'Unlink';

  @override
  String get chatCustomizeBot => 'Customize bot';

  @override
  String get chatCustomizeBotDescription =>
      'Rename the bot, change what it says about itself, or rename the slash command.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center needs an app configuration token to edit the bot. Reconnect and include one.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Create the $provider app';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center can create the $provider app for you, with the right permissions and events already set. You will finish in $provider, then paste the credentials here.';
  }

  @override
  String get chatCreateApp => 'Create app';

  @override
  String get chatCreateAppCta => 'Create app for me';

  @override
  String get chatAppNameLabel => 'App name';

  @override
  String get chatBotDisplayNameLabel => 'Bot name (what members type after @)';

  @override
  String get chatDescriptionLabel => 'Short description';

  @override
  String get chatAgentDescriptionLabel => 'What the bot says it can do';

  @override
  String get chatCommandLabel => 'Slash command';

  @override
  String get chatDirectMessages => 'Direct messages';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Lets members chat with the bot in a DM. May need a paid $provider plan.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider created the app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'A few steps are left and only $provider can do them:';
  }

  @override
  String get chatStepAppToken => 'Generate an app-level token';

  @override
  String get chatStepInstall => 'Install the app';

  @override
  String get chatOpenAppSettings => 'Open app settings';

  @override
  String get chatContinueToCredentials => 'Paste the credentials';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot updated in $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider changed the app\'s permissions. Reinstall the app for them to take effect.';
  }

  @override
  String get chatReinstallApp => 'Reinstall app';

  @override
  String chatIconNotEditable(String provider) {
    return 'The bot\'s icon can only be changed in $provider\'s own app settings.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'You can also create it in $provider yourself — no token needed. The settings above travel with the link.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Create in $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider opened in your browser with this configuration pre-filled. Create the app there, then finish these steps and come back with the tokens.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider does not report which app it created, so customizing the bot from here needs an app configuration token later.';
  }

  @override
  String get chatStepCreateApp =>
      'Create the app from the pre-filled configuration';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Pick a workspace in $provider and confirm.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, with the connections:write scope.';

  @override
  String get chatStepInstallHint =>
      'Install app → copy the bot user OAuth token.';

  @override
  String get calendarUseBuiltinApp => 'Use Control Center\'s Google app';

  @override
  String get calendarUseBuiltinAppHint =>
      'Approve with your Google account. Nothing to set up in Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Use my own Google Cloud client';

  @override
  String get calendarUseOwnClientHint =>
      'Enter an OAuth client from your own Google Cloud project.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutAppVersion => 'App version';

  @override
  String get aboutServerVersion => 'Connected server';

  @override
  String get aboutRpcCatalog => 'RPC catalog';

  @override
  String get aboutServerUnknown => 'Not reported';

  @override
  String get serverStaleTitle => 'The bundled server is older than this app';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'The running cc_server is $serverVersion while this app is $appVersion. Restart the app so it picks up the latest bundled server build; in development, rebuild it with `dart build cli` in apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Check for updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String get updateDeferredBusy =>
      'An update is ready but a meeting is recording — it will prompt after it ends.';

  @override
  String get updateOpenedReleasesPage =>
      'Opened the releases page in your browser.';

  @override
  String get updateCheckFailed => 'Update check failed';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version is available.';
  }

  @override
  String get updateBannerTitle => 'A new Control Center is available';

  @override
  String get updateBannerRefresh => 'Refresh';

  @override
  String get updateBlockedRecording =>
      'Refreshing is paused while a meeting is recording — it will reload when it ends.';

  @override
  String get settingsScopeYou => 'You';

  @override
  String get settingsScopeWorkspace => 'Workspace';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profile & identity';

  @override
  String get settingsYourDevices => 'Your devices';

  @override
  String get settingsWorkspaceGeneral => 'General';

  @override
  String get settingsServerConnection => 'Connection & status';

  @override
  String get settingsModelProviders => 'Model providers';

  @override
  String get settingsVoiceModels => 'Voice & meeting models';

  @override
  String get settingsDiagnostics => 'Diagnostics & privacy';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsScopeBadgeYou => 'YOU';

  @override
  String get settingsScopeBadgeDevice => 'THIS DEVICE';

  @override
  String get settingsScopeBadgeWorkspace => 'WORKSPACE';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Your name, email and the git identity stamped on commits made for you.';

  @override
  String get settingsServerConnectionDescription =>
      'Which server this client talks to, and how this server is shared (mDNS, tunnels, relay).';

  @override
  String get settingsAboutDescription => 'Build identity and updates.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolation, indexing, syncing, logging and crash reporting for this install.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identity, policy and conventions shared by everyone in this workspace.';

  @override
  String get settingsWorkspacePolicyLabel => 'Workspace policy';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Applies to every member and every agent in this workspace.';

  @override
  String get settingsSecretGlobsLabel => 'Secret path exclusions';

  @override
  String get settingsSecretGlobsHelp =>
      'One glob per line. These paths are hidden from viewers and guests on code-bearing surfaces, on top of the built-in defaults.';

  @override
  String get settingsReviewConcurrencyLabel => 'Review fan-out';

  @override
  String get settingsReviewConcurrencyHelp =>
      'How many reviewers are dispatched in parallel when no explicit count is given.';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Only workspace admins can change these.';

  @override
  String get chatMyAccountsTitle => 'Linked chat accounts';

  @override
  String get settingsServerSso => 'Single sign-on';

  @override
  String get settingsServerSsoDescription =>
      'SAML and OpenID Connect login with user provisioning';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabled => 'Enable this connection';

  @override
  String get ssoEnabledDescription => 'Users can sign in with this provider';

  @override
  String get ssoEnabledDescriptionOn => 'Sign-in is live for this provider';

  @override
  String get ssoIdpMetadataLabel => 'IdP metadata XML';

  @override
  String get ssoIdpMetadataHint => 'paste the IdP\'s EntityDescriptor XML';

  @override
  String get ssoSpEntityIdLabel =>
      'SP entity ID (optional, derived from the server URL)';

  @override
  String get ssoEmailAttributeLabel => 'Email attribute';

  @override
  String get ssoDisplayNameAttributeLabel => 'Display name attribute';

  @override
  String get ssoGroupsAttributeLabel => 'Groups attribute';

  @override
  String get ssoClockSkewLabel => 'Clock skew (seconds)';

  @override
  String get ssoIssuerLabel => 'Issuer URL';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Groups claim';

  @override
  String get ssoDefaultRoleLabel =>
      'Default role (member, admin, viewer, guest)';

  @override
  String get ssoRoleMapLabel => 'Group to role map (JSON)';

  @override
  String get ssoAutoMemberLabel =>
      'Add users to every workspace on first login';

  @override
  String get ssoAutoMemberDescription =>
      'Turn off to require an invite per workspace';

  @override
  String get ssoAllowJitLabel => 'Provision unknown users on first login';

  @override
  String get ssoAllowJitDescription =>
      'Turn off to reject users without an existing account';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Accept unsolicited (IdP-initiated) sign-in';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Strictly for IdP portals that launch apps directly';

  @override
  String get ssoWantResponseSignedLabel => 'Require a signed response envelope';

  @override
  String get ssoWantResponseSignedDescription =>
      'Assertion signatures are always required';

  @override
  String get ssoSaveButton => 'Save';

  @override
  String get ssoTestConnectionButton => 'Test connection';

  @override
  String get ssoTestConnectionOk => 'Connection works:';

  @override
  String get ssoCopySpMetadata => 'Copy SP metadata';

  @override
  String get ssoCopySpMetadataDone => 'SP metadata copied to the clipboard';

  @override
  String get ssoSavedToast => 'Single sign-on settings saved';

  @override
  String get ssoUnavailable =>
      'This server does not expose single sign-on settings. Update the server binary and try again.';

  @override
  String get ssoScimCardTitle => 'User provisioning (SCIM)';

  @override
  String get ssoScimDescription =>
      'Point your identity provider\'s SCIM connector at the endpoint below with a bearer token. Deprovisioning revokes sessions and workspace access within seconds. The server must be reachable by the IdP (tunnel or public URL).';

  @override
  String get ssoScimEndpoint => 'SCIM endpoint';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Set the server\'s public URL or enable a tunnel first';

  @override
  String get ssoScimRegenerate => 'Regenerate token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Generate a new SCIM bearer token? The previous token stops working immediately.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'A token is configured';

  @override
  String get ssoScimTokenAbsent => 'No token yet — generate one to enable SCIM';

  @override
  String get ssoScimTokenOnce => 'SCIM token (shown once)';

  @override
  String ssoSignInWith(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get ssoProbeFailed => 'Could not reach that server for single sign-on';

  @override
  String get ssoOpensBrowser => 'Opens your browser to finish signing in';

  @override
  String get ssoWaitingForBrowser =>
      'Waiting for your browser to finish signing in…';

  @override
  String get ssoBrowserOpenFailed =>
      'Could not open your browser for single sign-on';

  @override
  String get ssoUseManualPairing =>
      'Sign in with an invite or pairing key instead';

  @override
  String get ssoHideManualPairing => 'Hide manual pairing';

  @override
  String get ssoClientIdHint => 'Public (PKCE) client — no secret needed';

  @override
  String get ssoClientSecretLabel => 'Client secret (optional)';

  @override
  String get ssoClientSecretHintUnset =>
      'Only needed for confidential IdP clients';

  @override
  String get ssoClientSecretHintSet =>
      'A secret is stored — leave blank to keep it';

  @override
  String get ssoPairingToggle =>
      'Allow manual pairing (invite codes and pairing keys)';

  @override
  String get ssoPairingToggleDescription =>
      'Turn off to make joining single sign-on only — new devices arrive through SSO logins; existing devices keep working';

  @override
  String get ssoPairConfirmTitle => 'Connect to server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'A sign-in credential for $server arrived, but no sign-in was started from this app. Connect to this server?';
  }

  @override
  String get ssoPairConfirmConnect => 'Connect';

  @override
  String get ssoPairConfirmCancel => 'Ignore';

  @override
  String get forgeConnections => 'Code hosting';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get notConnected => 'Not connected';

  @override
  String get checkingConnection => 'Checking connection…';

  @override
  String get fromEnvironment => 'from the environment';

  @override
  String get fromGhCli => 'from the gh CLI';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge token';
  }

  @override
  String get connectAForge => 'Connect a code host to load pull requests';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Microphone, dictation, meeting detection and soundscape output.';

  @override
  String get voiceInputMicrophoneSection => 'Microphone';

  @override
  String get voiceInputBehaviorSection => 'Dictation and meetings';

  @override
  String get soundscapeOutputSection => 'Soundscape output';

  @override
  String get soundscapeOutputDevice => 'Output device';

  @override
  String get soundscapeOutputDefaultHint =>
      'Ambient audio plays through the system default output.';

  @override
  String get soundscapeOutputGone =>
      'The selected output device is no longer connected — the system default is used until you pick another.';

  @override
  String get reviewHubOverview => 'Overview';

  @override
  String get reviewHubAreas => 'Areas';

  @override
  String get reviewHubImpact => 'Impact';

  @override
  String get reviewHubProvisional => 'Provisional';

  @override
  String get reviewHubAiSummary => 'AI summary';

  @override
  String get reviewHubRisks => 'Risks';

  @override
  String reviewHubAreaFindingsCount(int count) {
    return '$count findings';
  }

  @override
  String reviewHubRepoWideCount(int count) {
    return '+$count repository-wide';
  }

  @override
  String get reviewHubIntroBody =>
      'Agents analyze the diff, map the change areas and reach a consensus verdict.';

  @override
  String get reviewHubStarted => 'Review started';

  @override
  String get reviewHubAlreadyRunning =>
      'A review is already running for this pull request';

  @override
  String get reviewHubAutoPublish => 'Auto-publish';

  @override
  String get reviewHubAutoPublishTooltip =>
      'Automatically publish completed reviews to GitHub';

  @override
  String get reviewHubChangedSymbols => 'Changed symbols';

  @override
  String get reviewHubReadingOrder => 'Reading order';

  @override
  String get reviewHubReadingOrderHint =>
      'Foundations first, then their consumers, then the tests';

  @override
  String get reviewHubOpenInDiff => 'Open in diff';

  @override
  String reviewHubLayerPosition(int index, int total) {
    return 'Step $index of $total';
  }

  @override
  String get reviewHubNoReadingOrder =>
      'No reading order computed for this area';

  @override
  String get reviewHubSymbolsFromBase => 'From base index';

  @override
  String get reviewHubSymbolsFromBaseTooltip =>
      'The pull request worktree is not indexed yet, so these line ranges come from the base branch and may be slightly off.';

  @override
  String reviewHubSymbolLines(int count) {
    return '$count lines';
  }

  @override
  String get reviewHubImpactGraph => 'Graph';

  @override
  String get reviewHubImpactList => 'List';

  @override
  String get reviewHubImpactChanged => 'Changed in this PR';

  @override
  String reviewHubImpactHops(int hops) {
    return '$hops hop(s) away';
  }

  @override
  String reviewHubImpactMore(int count, String file) {
    return '$count more in $file';
  }

  @override
  String get reviewHubRisk => 'Risk';

  @override
  String get reviewHubRiskLow => 'Low';

  @override
  String get reviewHubRiskModerate => 'Moderate';

  @override
  String get reviewHubRiskHigh => 'High';

  @override
  String get reviewHubRiskFactors => 'What drives this score';

  @override
  String get reviewHubOrderByRisk => 'Order by risk';

  @override
  String get reviewHubFactorLinesChanged => 'Lines changed';

  @override
  String get reviewHubFactorFileCount => 'Files';

  @override
  String get reviewHubFactorImpact => 'Dependents';

  @override
  String get reviewHubFactorBlockingFindings => 'Blocking findings';

  @override
  String get reviewHubFactorCriticalPath => 'Critical-path files';

  @override
  String get reviewHubFactorContractBreaking => 'Breaking API changes';

  @override
  String get reviewHubFactorVisualChange => 'Visual change';

  @override
  String get reviewHubFactorDependencyChurn => 'Dependency changes';

  @override
  String get reviewHubFactorNoCoveringTests => 'No covering tests';

  @override
  String get reviewHubStaticRule => 'Static rule';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Found by a deterministic rule ($rule) on a line this pull request adds — not by a reviewer agent.';
  }

  @override
  String get reviewHubCiSignals => 'CI signals';

  @override
  String get reviewHubCiAllPassing => 'All checks are passing';

  @override
  String get reviewHubCiLogsNotPublished => 'Logs not published yet';

  @override
  String get reviewHubCiFailingTests => 'Failing tests';

  @override
  String reviewHubCiTouchesFile(String file) {
    return 'Points at $file';
  }

  @override
  String get reviewHubCiUnavailable =>
      'This forge does not expose per-job CI detail';

  @override
  String reviewHubCoveringTests(int count) {
    return 'Covered by $count test file(s)';
  }

  @override
  String get reviewHubNoCoveringTests => 'No test file references this area';

  @override
  String get reviewHubCoverageUnknown =>
      'Test coverage could not be determined (repository not indexed)';

  @override
  String get reviewHubDependencies => 'Dependencies';

  @override
  String get reviewHubDepsAdded => 'Added';

  @override
  String get reviewHubDepsRemoved => 'Removed';

  @override
  String get reviewHubDepsUpgraded => 'Changed version';

  @override
  String get reviewHubDepsMajorBump => 'Major';

  @override
  String get reviewHubDepsBestEffort =>
      'This lockfile format is parsed best-effort — verify before relying on it';

  @override
  String get reviewHubDepsNone => 'No dependency changed';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Since last review: $resolved resolved · $added new · $open still open';
  }

  @override
  String get reviewHubBadgeNew => 'New';

  @override
  String get reviewHubBadgeStillOpen => 'Still open';

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Previously reviewed at $sha';
  }

  @override
  String get reviewHubAskArea => 'Ask about this area';

  @override
  String get reviewHubAskPlaceholder => 'e.g. why does this need a new column?';

  @override
  String get reviewHubAskSubmit => 'Ask';

  @override
  String get reviewHubAskSent =>
      'Question sent — the answer will appear in the conversation';

  @override
  String get reviewHubAskNoAgent =>
      'No agent is available to answer in this workspace';

  @override
  String get reviewHubQuestions => 'Questions';

  @override
  String get reviewHubFixAllInArea => 'Fix all open findings in this area';

  @override
  String get reviewHubLearnings => 'Learnings';

  @override
  String get reviewHubGuidelines => 'Review guidelines';

  @override
  String get reviewHubSuppressions => 'Dismissed patterns';

  @override
  String get reviewHubAddGuideline => 'Add guideline';

  @override
  String get reviewHubGuidelineGlobHint =>
      'Path glob (optional), e.g. lib/api/**';

  @override
  String get reviewHubGuidelineTextHint => 'What reviewers should check';

  @override
  String reviewHubStatsSummary(int made, int addressed) {
    return '$made findings made · $addressed addressed';
  }

  @override
  String get reviewHubNoLearnings =>
      'Nothing learned yet — dismiss a finding or add a guideline';

  @override
  String get webConnectTitle => 'Connect to Control Center';

  @override
  String get webConnectSubtitle =>
      'Dial a running cc-server over WebSocket. Your key stays on this device.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Device id';

  @override
  String get webConnectPairingKeyLabel => 'Pairing key';

  @override
  String get webConnectPairingKeyHint => 'paste the PSK';

  @override
  String get webConnectStayConnected => 'Stay connected on this device';

  @override
  String get webConnectStayConnectedDetail =>
      'Stay connected on this device (stores your key in this browser)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Failed to create workspace: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'committed $relative';
  }

  @override
  String get selectAgents => 'Select agents';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }
}
