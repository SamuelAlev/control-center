// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get settings => 'Settings';

  @override
  String get refresh => 'Refresh';

  @override
  String get approve => 'Approve';

  @override
  String get deny => 'Deny';

  @override
  String get continueLabel => 'Continue';

  @override
  String get agentQuestionHeader => 'Question for you';

  @override
  String get agentQuestionAnsweredLabel => 'Answered';

  @override
  String get agentQuestionSkip => 'Skip';

  @override
  String get agentQuestionSkippedLabel => 'Skipped';

  @override
  String get agentQuestionFreeformHint => 'Type your answer…';

  @override
  String get agentApprovalRequired => 'Approval required';

  @override
  String get approveAndRemember => 'Approve for 8 hours';

  @override
  String get decline => 'Decline';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Send';

  @override
  String get close => 'Close';

  @override
  String get expand => 'Expand';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get scanQrPrompt =>
      'Scan the QR code from your Mac to pair this phone.';

  @override
  String get scanQrHelp =>
      'Open your camera and point it at the QR shown in Control Center on your Mac. This phone connects directly to your Mac over a private link.';

  @override
  String get connectingToMac => 'Connecting to your Mac…';

  @override
  String get connectingDetail => 'Establishing a secure, direct link.';

  @override
  String get identityChangedTitle => 'Server identity changed';

  @override
  String get identityChangedBody =>
      'This server no longer matches the identity saved when you paired. That can mean the server was reinstalled — or that something is intercepting the connection. To stay safe, this device will not connect. Remove the pairing, then scan a fresh QR code from your Mac to pair again.';

  @override
  String get removePairing => 'Remove pairing';

  @override
  String get couldntConnect => 'Couldn\'t connect';

  @override
  String get pendingPairingTitle => 'Connect to this server?';

  @override
  String get pendingPairingBody =>
      'A link asked Control Center to pair with this server. Only continue if you started it yourself.';

  @override
  String get connect => 'Connect';

  @override
  String get failureNotPaired => 'Not paired — scan the QR code from your Mac';

  @override
  String get failureUnreachable =>
      'Couldn\'t reach your server on any path — check it\'s running, or try the same network';

  @override
  String get failureIdentityChanged =>
      'The server\'s identity changed — if it was reinstalled, re-pair this device';

  @override
  String get failureAuthRejected =>
      'The server rejected this device — re-pair it from your Mac';

  @override
  String get failureUnknown => 'Couldn\'t connect — tap to retry';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identity mismatch';

  @override
  String get statusNotPaired => 'Not paired';

  @override
  String get statusConfirmPairing => 'Confirm pairing';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get identityMismatchBanner =>
      'Server identity changed — connection stopped. Re-pair this device to continue.';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabNews => 'News';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count waiting';
  }

  @override
  String get updateAvailable => 'A new Control Center is available';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get device => 'Device';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Tap again to disconnect this device from your Mac';

  @override
  String get disconnectDevice => 'Disconnect this device';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get chooseWorkspace => 'Choose workspace';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get workspacesLoadFailed => 'Couldn\'t load workspaces';

  @override
  String get noWorkspacesYet => 'No workspaces yet';

  @override
  String selectWorkspace(String name) {
    return 'Select $name';
  }

  @override
  String get inboxLoadFailed => 'Couldn\'t load your inbox';

  @override
  String get allCaughtUp => 'You’re all caught up';

  @override
  String get inboxNoForgeAccount =>
      'No forge account is connected on the server, so pull requests can’t be attributed to you yet.';

  @override
  String get inboxNothingWaiting =>
      'Nothing is blocked and no pull request is waiting on you.';

  @override
  String get blocked => 'Blocked';

  @override
  String get sectionNeedsYourReview => 'Needs your review';

  @override
  String get sectionReturnedToYou => 'Returned to you';

  @override
  String get sectionApprovedAndReady => 'Approved and ready';

  @override
  String get sectionYourDrafts => 'Your drafts';

  @override
  String get sectionWaitingForReviewers => 'Waiting for reviewers';

  @override
  String get sectionMergingAndMerged => 'Merging and recently merged';

  @override
  String get sectionWaitingForAuthor => 'Waiting for author';

  @override
  String waitingAgo(String ago) {
    return 'waiting $ago';
  }

  @override
  String get openConversation => 'Open the conversation';

  @override
  String get calendarLoadFailed => 'Couldn\'t load your calendar';

  @override
  String get nothingScheduled => 'Nothing scheduled';

  @override
  String get calendarEmptyDescription =>
      'Events from your connected calendars appear here.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sync calendars now';

  @override
  String get event => 'Event';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get eventNotFoundDescription =>
      'It may be outside the agenda window, or removed upstream.';

  @override
  String get joinMeeting => 'Join meeting';

  @override
  String get join => 'Join';

  @override
  String attendeesCount(int count) {
    return 'Attendees ($count)';
  }

  @override
  String get details => 'Details';

  @override
  String get allDay => 'All day';

  @override
  String get happeningNow => 'Happening now';

  @override
  String inDuration(String duration) {
    return 'In $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'accepted';

  @override
  String get attendeeDeclined => 'declined';

  @override
  String get attendeeMaybe => 'maybe';

  @override
  String get attendeeNoReply => 'no reply';

  @override
  String get organizer => 'organizer';

  @override
  String get calendarNoAccounts =>
      'No calendar is connected for this workspace. Connect one from the desktop app — the sign-in stores its token on the server.';

  @override
  String get calendarReauthNeeded =>
      'A calendar account needs to be reconnected — what you see below may be out of date. Reconnect it from the desktop app.';

  @override
  String get spacesLoadFailed => 'Couldn\'t load spaces';

  @override
  String get noSpaces => 'No spaces';

  @override
  String get spacesEmptyDescription => 'Spaces in this workspace appear here.';

  @override
  String get thread => 'Thread';

  @override
  String get agentWorking => 'Agent is working';

  @override
  String get messagesLoadFailed => 'Couldn\'t load messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesDescription =>
      'Send a message to start the conversation.';

  @override
  String get agentResponding => 'Agent responding';

  @override
  String get agentFinished => 'Agent finished';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names are too large to send from here.',
      one: '$names is too large to send from here.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names are too large to send over the relay from here.',
      one: '$names is too large to send over the relay from here.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Couldn\'t upload the attachment. Try again.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments couldn\'t be uploaded and were left out.',
      one: '1 attachment couldn\'t be uploaded and was left out.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Teammate';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Attach a file';

  @override
  String get messageHint => 'Message';

  @override
  String removeAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get articlesLoadFailed => 'Couldn\'t load articles';

  @override
  String get noArticles => 'No articles';

  @override
  String get articlesEmptyDescription =>
      'New articles appear here as feeds update.';

  @override
  String get unread => 'Unread';

  @override
  String get allFeeds => 'All feeds';

  @override
  String get save => 'Save';

  @override
  String get unsave => 'Unsave';

  @override
  String get readFullArticle => 'Read full article';

  @override
  String get ticketsLoadFailed => 'Couldn\'t load tickets';

  @override
  String get noTickets => 'No tickets';

  @override
  String get ticketsEmptyDescription =>
      'Tickets in this workspace appear here.';

  @override
  String get all => 'All';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Couldn\'t load ticket';

  @override
  String assignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Assign';

  @override
  String get reassign => 'Reassign';

  @override
  String get noAgents => 'No agents';

  @override
  String get noAgentsDescription => 'Assign an agent from this workspace.';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusDone => 'Done';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Needs me';

  @override
  String get lensMine => 'Mine';

  @override
  String get prsLoadFailed => 'Couldn\'t load pull requests';

  @override
  String get noOpenPullRequests => 'No open pull requests';

  @override
  String get nothingWaitingOnReview => 'Nothing waiting on your review';

  @override
  String get noOwnOpenPullRequests => 'You have no open pull requests';

  @override
  String get nothingBlocked => 'Nothing blocked';

  @override
  String get prsEmptyDescription =>
      'Pull requests across this workspace’s repos appear here.';

  @override
  String get refreshPullRequests => 'Refresh pull requests';

  @override
  String get noForgeConnected =>
      'No forge is connected on the server, so no pull requests can be fetched. Connect one from the desktop app.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repos could not be read.',
      one: '1 repo could not be read.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Not readable: $names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub App installation suspended';

  @override
  String installationSuspendedBody(String names) {
    return 'Showing last known data for $names. Resume the installation on GitHub, or connect a token.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App installation suspended. Showing last known data for $names. Resume the installation on GitHub, or connect a token.';
  }

  @override
  String get draft => 'Draft';

  @override
  String get merged => 'Merged';

  @override
  String get closed => 'Closed';

  @override
  String get open => 'Open';

  @override
  String get approved => 'Approved';

  @override
  String get changesRequested => 'Changes requested';

  @override
  String get reviewRequired => 'Review required';

  @override
  String get checksPassing => 'Checks passing';

  @override
  String get checksFailing => 'Checks failing';

  @override
  String get checksRunning => 'Checks running';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Couldn\'t load this pull request';

  @override
  String get openOnForge => 'Open on the forge';

  @override
  String get requestChangesNeedsComment =>
      'Add a comment explaining what needs changing.';

  @override
  String get conversation => 'Conversation';

  @override
  String get files => 'Files';

  @override
  String get checks => 'Checks';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflicts';

  @override
  String get reviewers => 'Reviewers';

  @override
  String get noDescriptionNoComments => 'No description and no comments yet.';

  @override
  String get noChangedFiles => 'No changed files.';

  @override
  String get noChecksReported => 'No checks reported for the head commit.';

  @override
  String get reviewCommentHint => 'Leave a review comment…';

  @override
  String get comment => 'Comment';

  @override
  String get commentPosted => 'Comment posted';

  @override
  String get request => 'Request';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — no actions available.';
  }

  @override
  String get reviewApproved => 'approved';

  @override
  String get reviewRequestedChanges => 'requested changes';

  @override
  String get reviewCommented => 'reviewed';

  @override
  String get reviewPending => 'pending';

  @override
  String get unknownAuthor => 'unknown';

  @override
  String hideDiffFor(String file) {
    return 'Hide the diff for $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Show the diff for $file';
  }

  @override
  String get checkRunning => 'running';

  @override
  String get checkPassed => 'passed';

  @override
  String get checkFailed => 'failed';

  @override
  String get checkCancelled => 'cancelled';

  @override
  String get checkSkipped => 'skipped';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'No text diff for this file — it is binary, or too large for the forge to return one.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show the remaining $count lines',
      one: 'Show the remaining line',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unchanged lines',
      one: '1 unchanged line',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get streaming => 'Streaming';

  @override
  String get working => 'Working';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get now => 'now';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get organizer => 'organiser';
}
