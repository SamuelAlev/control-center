import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('cs'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('es', 'MX'),
    Locale('fa'),
    Locale('fr'),
    Locale('fr', 'CA'),
    Locale('he'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nb'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'PT'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'HK'),
    Locale('zh', 'TW'),
  ];

  /// The product name, used as the app/window title and on the pairing screen.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get appTitle;

  /// Semantic label for the back arrow in detail-screen headers.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button on the connection-failed banner that retries the connection.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button on the failed connect screen that retries the connection.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Settings screen title and the semantic label of the gear button in the header.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Button on the update banner that reloads the PWA to the new deploy.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Button approving a blocked agent action or a pull request review.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// Button denying a blocked agent action (inbox approval card).
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @agentQuestionHeader.
  ///
  /// In en, this message translates to:
  /// **'Question for you'**
  String get agentQuestionHeader;

  /// No description provided for @agentQuestionAnsweredLabel.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get agentQuestionAnsweredLabel;

  /// No description provided for @agentQuestionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get agentQuestionSkip;

  /// No description provided for @agentQuestionSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get agentQuestionSkippedLabel;

  /// No description provided for @agentQuestionFreeformHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer…'**
  String get agentQuestionFreeformHint;

  /// No description provided for @agentApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get agentApprovalRequired;

  /// No description provided for @approveAndRemember.
  ///
  /// In en, this message translates to:
  /// **'Approve for 8 hours'**
  String get approveAndRemember;

  /// Button declining a pending agent confirmation in a conversation.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Second-tap confirmation on the disconnect-device button.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Button sending the composed message.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Image viewer: closes the fullscreen viewer.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Image viewer: opens an embedded image fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Image viewer zoom-in control.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// Image viewer zoom-out control.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// Image viewer zoom-reset control.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoom;

  /// Connect screen: primary instruction when the phone is not paired.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code from Control Center to pair this phone.'**
  String get scanQrPrompt;

  /// Connect screen: secondary help text under the pairing instruction.
  ///
  /// In en, this message translates to:
  /// **'Open your camera and point it at the QR shown in Control Center. This phone connects directly over a private link.'**
  String get scanQrHelp;

  /// Connect screen: title while the phone resolves a path and authenticates.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Control Center…'**
  String get connectingToMac;

  /// Connect screen: subtitle while connecting.
  ///
  /// In en, this message translates to:
  /// **'Establishing a secure, direct link.'**
  String get connectingDetail;

  /// Connect screen: title of the terminal identity-mismatch stop.
  ///
  /// In en, this message translates to:
  /// **'Server identity changed'**
  String get identityChangedTitle;

  /// Connect screen: explanation of the identity-mismatch stop and the way forward.
  ///
  /// In en, this message translates to:
  /// **'This server no longer matches the identity saved when you paired. That can mean the server was reinstalled — or that something is intercepting the connection. To stay safe, this device will not connect. Remove the pairing, then scan a fresh QR code from Control Center to pair again.'**
  String get identityChangedBody;

  /// Button that forgets the stored pairing (identity-mismatch recovery).
  ///
  /// In en, this message translates to:
  /// **'Remove pairing'**
  String get removePairing;

  /// Connect screen: title after repeated connection failures.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get couldntConnect;

  /// Connect screen: title of the confirm gate for a link-delivered pairing offer.
  ///
  /// In en, this message translates to:
  /// **'Connect to this server?'**
  String get pendingPairingTitle;

  /// Connect screen: explanation of the pairing confirm gate.
  ///
  /// In en, this message translates to:
  /// **'A link asked Control Center to pair with this server. Only continue if you started it yourself.'**
  String get pendingPairingBody;

  /// Button confirming a pending pairing offer.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Connection-failure reason: no pairing record exists.
  ///
  /// In en, this message translates to:
  /// **'Not paired — scan the QR code from Control Center'**
  String get failureNotPaired;

  /// Connection-failure reason: no connection path reached the server.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach your server on any path — check it\'s running, or try the same network'**
  String get failureUnreachable;

  /// Connection-failure reason: the server's identity no longer matches the pinned fingerprint.
  ///
  /// In en, this message translates to:
  /// **'The server\'s identity changed — if it was reinstalled, re-pair this device'**
  String get failureIdentityChanged;

  /// Connection-failure reason: the device credential was rejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this device — re-pair it from Control Center'**
  String get failureAuthRejected;

  /// Connection-failure reason: fallback when the cause is unknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect — tap to retry'**
  String get failureUnknown;

  /// Connection chip: a path is live and authenticated.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// Connection chip: resolving the best path or reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// Connection chip: repeated connect failures.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// Connection chip: the server's identity no longer matches the pinned fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Identity mismatch'**
  String get statusIdentityMismatch;

  /// Connection chip: no pairing record.
  ///
  /// In en, this message translates to:
  /// **'Not paired'**
  String get statusNotPaired;

  /// Connection chip: a pairing offer is awaiting explicit confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm pairing'**
  String get statusConfirmPairing;

  /// Fallback text of the connection-failed banner when no reason is known.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// Shell banner for a mid-session identity mismatch.
  ///
  /// In en, this message translates to:
  /// **'Server identity changed — connection stopped. Re-pair this device to continue.'**
  String get identityMismatchBanner;

  /// Bottom tab label: the unified inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get tabInbox;

  /// Bottom tab label: tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tabTickets;

  /// Bottom tab label: messaging spaces.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// Bottom tab label: pull requests.
  ///
  /// In en, this message translates to:
  /// **'PRs'**
  String get tabPrs;

  /// Bottom tab label: the calendar agenda.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// Bottom tab label: the newsfeed.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tabNews;

  /// Accessible name of a tab whose badge shows items waiting, e.g. 'Inbox, 3 waiting'.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} waiting'**
  String tabWaitingCount(String label, int count);

  /// Banner shown when a newer deploy of the PWA is live at the origin.
  ///
  /// In en, this message translates to:
  /// **'A new Control Center is available'**
  String get updateAvailable;

  /// Settings section header for the theme choice.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings section header for the language choice.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Settings section header for device management (disconnect).
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// Theme option: follow the platform brightness.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: light appearance.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: dark appearance.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Language option: follow the platform locale.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Armed state of the disconnect card, asking for a confirming second tap.
  ///
  /// In en, this message translates to:
  /// **'Tap again to disconnect this device from Control Center'**
  String get disconnectTapAgain;

  /// Label of the disconnect-device card.
  ///
  /// In en, this message translates to:
  /// **'Disconnect this device'**
  String get disconnectDevice;

  /// First-tap label of the disconnect button.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Header button label while no workspace is resolved yet.
  ///
  /// In en, this message translates to:
  /// **'Choose workspace'**
  String get chooseWorkspace;

  /// Workspace picker screen title.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// Error state of the workspace picker.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load workspaces'**
  String get workspacesLoadFailed;

  /// Empty state of the workspace picker.
  ///
  /// In en, this message translates to:
  /// **'No workspaces yet'**
  String get noWorkspacesYet;

  /// Accessible name of a workspace row in the picker.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String selectWorkspace(String name);

  /// Error state of the inbox tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your inbox'**
  String get inboxLoadFailed;

  /// Inbox empty-state title.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get allCaughtUp;

  /// Inbox empty-state description when no forge account is connected.
  ///
  /// In en, this message translates to:
  /// **'No forge account is connected on the server, so pull requests can’t be attributed to you yet.'**
  String get inboxNoForgeAccount;

  /// Inbox empty-state description when the inbox is genuinely empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is blocked and no pull request is waiting on you.'**
  String get inboxNothingWaiting;

  /// Label of the blocked-agents inbox section and the blocked PR lens.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// Inbox PR section: review requests naming the operator.
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get sectionNeedsYourReview;

  /// Inbox PR section: PRs returned to the operator with changes requested.
  ///
  /// In en, this message translates to:
  /// **'Returned to you'**
  String get sectionReturnedToYou;

  /// Inbox PR section: approved PRs ready to merge.
  ///
  /// In en, this message translates to:
  /// **'Approved and ready'**
  String get sectionApprovedAndReady;

  /// Inbox PR section: the operator's draft PRs.
  ///
  /// In en, this message translates to:
  /// **'Your drafts'**
  String get sectionYourDrafts;

  /// Inbox PR section: PRs awaiting other reviewers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reviewers'**
  String get sectionWaitingForReviewers;

  /// Inbox PR section: PRs merging or recently merged.
  ///
  /// In en, this message translates to:
  /// **'Merging and recently merged'**
  String get sectionMergingAndMerged;

  /// Inbox PR section: PRs waiting on their author.
  ///
  /// In en, this message translates to:
  /// **'Waiting for author'**
  String get sectionWaitingForAuthor;

  /// How long an approval request has been waiting, e.g. 'waiting 4m'. {ago} is a compact time-since label.
  ///
  /// In en, this message translates to:
  /// **'waiting {ago}'**
  String waitingAgo(String ago);

  /// Button on an approval card opening the space the request came from.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get openConversation;

  /// Error state of the calendar tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your calendar'**
  String get calendarLoadFailed;

  /// Calendar empty-state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get nothingScheduled;

  /// Calendar empty-state description.
  ///
  /// In en, this message translates to:
  /// **'Events from your connected calendars appear here.'**
  String get calendarEmptyDescription;

  /// Calendar tab toolbar title.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// Semantic label of the calendar refresh button.
  ///
  /// In en, this message translates to:
  /// **'Sync calendars now'**
  String get syncCalendarsNow;

  /// Fallback title of the event detail header while the event resolves.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// Event detail: the event is not in the agenda window.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventNotFound;

  /// Event detail: why an event may not be found.
  ///
  /// In en, this message translates to:
  /// **'It may be outside the agenda window, or removed upstream.'**
  String get eventNotFoundDescription;

  /// Button opening the event's meeting link.
  ///
  /// In en, this message translates to:
  /// **'Join meeting'**
  String get joinMeeting;

  /// Compact join button on the up-next card.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Event detail: attendees section header with count.
  ///
  /// In en, this message translates to:
  /// **'Attendees ({count})'**
  String attendeesCount(int count);

  /// Event detail: description section header.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Label for an all-day event.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// Up-next card lead while the meeting is live.
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get happeningNow;

  /// Up-next card lead: countdown to the next meeting, e.g. 'In 45m'. {duration} is a compact duration.
  ///
  /// In en, this message translates to:
  /// **'In {duration}'**
  String inDuration(String duration);

  /// Event detail: time range with duration, e.g. '14:00 – 15:00 · 1h'.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · {duration}'**
  String eventTimeRange(String start, String end, String duration);

  /// Accessible name of the up-next card, e.g. 'In 45m: design sync'.
  ///
  /// In en, this message translates to:
  /// **'{lead}: {title}'**
  String upNextSemantic(String lead, String title);

  /// Attendee response status: accepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get attendeeAccepted;

  /// Attendee response status: declined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get attendeeDeclined;

  /// Attendee response status: tentative.
  ///
  /// In en, this message translates to:
  /// **'maybe'**
  String get attendeeMaybe;

  /// Attendee response status: no answer yet.
  ///
  /// In en, this message translates to:
  /// **'no reply'**
  String get attendeeNoReply;

  /// Badge marking the event organizer in the attendee list.
  ///
  /// In en, this message translates to:
  /// **'organizer'**
  String get organizer;

  /// Notice when no calendar account is connected.
  ///
  /// In en, this message translates to:
  /// **'No calendar is connected for this workspace. Connect one from the desktop app — the sign-in stores its token on the server.'**
  String get calendarNoAccounts;

  /// Notice when a calendar account's credential expired.
  ///
  /// In en, this message translates to:
  /// **'A calendar account needs to be reconnected — what you see below may be out of date. Reconnect it from the desktop app.'**
  String get calendarReauthNeeded;

  /// Error state of the messaging tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load spaces'**
  String get spacesLoadFailed;

  /// Messaging empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No spaces'**
  String get noSpaces;

  /// Messaging empty-state description.
  ///
  /// In en, this message translates to:
  /// **'Spaces in this workspace appear here.'**
  String get spacesEmptyDescription;

  /// Conversation screen header title.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get thread;

  /// Banner above a conversation while an agent run is active.
  ///
  /// In en, this message translates to:
  /// **'Agent is working'**
  String get agentWorking;

  /// Error state of a conversation.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get messagesLoadFailed;

  /// Conversation empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Conversation empty-state description.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation.'**
  String get noMessagesDescription;

  /// Screen-reader announcement when an agent turn starts streaming.
  ///
  /// In en, this message translates to:
  /// **'Agent responding'**
  String get agentResponding;

  /// Screen-reader announcement when an agent turn completes with no answer text.
  ///
  /// In en, this message translates to:
  /// **'Agent finished'**
  String get agentFinished;

  /// Composer error: the named files exceed the upload ceiling of this connection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} is too large to send from here.} other{{names} are too large to send from here.}}'**
  String attachmentsTooLarge(int count, String names);

  /// Composer error: the named files exceed the (lower) relay upload ceiling.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} is too large to send over the relay from here.} other{{names} are too large to send over the relay from here.}}'**
  String attachmentsTooLargeRelay(int count, String names);

  /// Composer error: no attachment survived the upload and there was no text.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the attachment. Try again.'**
  String get attachmentUploadFailed;

  /// Composer notice: some attachments failed to upload and were omitted from the sent message.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment couldn\'t be uploaded and was left out.} other{{count} attachments couldn\'t be uploaded and were left out.}}'**
  String attachmentsLeftOut(int count);

  /// Fallback display name for another member's message.
  ///
  /// In en, this message translates to:
  /// **'Teammate'**
  String get teammate;

  /// Fallback display name for an agent message.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// Semantic label of the composer's attach button.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get attachFile;

  /// Hint text of the message composer.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// Semantic label of the remove button on a pending attachment chip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeAttachment(String name);

  /// Error state of the newsfeed tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load articles'**
  String get articlesLoadFailed;

  /// Newsfeed empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No articles'**
  String get noArticles;

  /// Newsfeed empty-state description.
  ///
  /// In en, this message translates to:
  /// **'New articles appear here as feeds update.'**
  String get articlesEmptyDescription;

  /// Newsfeed filter chip: unread articles only.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// Newsfeed filter chip: articles from every feed.
  ///
  /// In en, this message translates to:
  /// **'All feeds'**
  String get allFeeds;

  /// Semantic label of the bookmark button (article not yet saved).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Semantic label of the bookmark button (article already saved).
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get unsave;

  /// Button opening the article's source URL in the browser.
  ///
  /// In en, this message translates to:
  /// **'Read full article'**
  String get readFullArticle;

  /// Error state of the tickets tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tickets'**
  String get ticketsLoadFailed;

  /// Tickets empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No tickets'**
  String get noTickets;

  /// Tickets empty-state description.
  ///
  /// In en, this message translates to:
  /// **'Tickets in this workspace appear here.'**
  String get ticketsEmptyDescription;

  /// Filter chip matching everything (tickets, pull requests).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Fallback title of the ticket detail header while the ticket resolves.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticket;

  /// Error state of the ticket detail screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load ticket'**
  String get ticketLoadFailed;

  /// Badge naming the ticket's assignee.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedTo(String name);

  /// Button opening the ticket's URL in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// Ticket detail: status section header.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Button assigning an agent to an unassigned ticket.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// Button reassigning an already-assigned ticket.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// Agent chooser empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No agents'**
  String get noAgents;

  /// Agent chooser empty-state description.
  ///
  /// In en, this message translates to:
  /// **'Assign an agent from this workspace.'**
  String get noAgentsDescription;

  /// Ticket status: open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// Ticket status: in progress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// Ticket status: blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// Ticket status: in review.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get statusInReview;

  /// Ticket status: done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Ticket status: backlog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get statusBacklog;

  /// PR filter lens: PRs whose review request names the operator.
  ///
  /// In en, this message translates to:
  /// **'Needs me'**
  String get lensNeedsMe;

  /// PR filter lens: the operator's own open PRs.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get lensMine;

  /// Error state of the PR tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load pull requests'**
  String get prsLoadFailed;

  /// PR empty state for the 'all' lens.
  ///
  /// In en, this message translates to:
  /// **'No open pull requests'**
  String get noOpenPullRequests;

  /// PR empty state for the 'needs me' lens.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting on your review'**
  String get nothingWaitingOnReview;

  /// PR empty state for the 'mine' lens.
  ///
  /// In en, this message translates to:
  /// **'You have no open pull requests'**
  String get noOwnOpenPullRequests;

  /// PR empty state for the 'blocked' lens.
  ///
  /// In en, this message translates to:
  /// **'Nothing blocked'**
  String get nothingBlocked;

  /// PR empty-state description on the 'all' lens.
  ///
  /// In en, this message translates to:
  /// **'Pull requests across this workspace’s repos appear here.'**
  String get prsEmptyDescription;

  /// Semantic label of the PR refresh button.
  ///
  /// In en, this message translates to:
  /// **'Refresh pull requests'**
  String get refreshPullRequests;

  /// Notice when the server has no forge credential to poll with.
  ///
  /// In en, this message translates to:
  /// **'No forge is connected on the server, so no pull requests can be fetched. Connect one from the desktop app.'**
  String get noForgeConnected;

  /// Notice when repos were unreadable and their names are unknown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repo could not be read.} other{{count} repos could not be read.}}'**
  String reposUnreadable(int count);

  /// Notice naming the repos the poller could not read.
  ///
  /// In en, this message translates to:
  /// **'Not readable: {names}'**
  String reposNotReadable(String names);

  /// Title when the GitHub App installation is suspended and lists are cached.
  ///
  /// In en, this message translates to:
  /// **'GitHub App installation suspended'**
  String get installationSuspendedTitle;

  /// Empty-inbox body when the GitHub App installation is suspended.
  ///
  /// In en, this message translates to:
  /// **'Showing last known data for {names}. Resume the installation on GitHub, or connect a token.'**
  String installationSuspendedBody(String names);

  /// Inline notice on inbox and PR list when the GitHub App installation is suspended.
  ///
  /// In en, this message translates to:
  /// **'GitHub App installation suspended. Showing last known data for {names}. Resume the installation on GitHub, or connect a token.'**
  String installationSuspendedNotice(String names);

  /// PR lifecycle: a draft pull request.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// PR lifecycle: merged. Also the success notice after merging.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get merged;

  /// PR lifecycle: closed without merging.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// PR lifecycle: open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// PR review decision badge; also the success notice after approving.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// PR review decision badge; also the success notice after requesting changes.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get changesRequested;

  /// PR review decision badge: a review is still required.
  ///
  /// In en, this message translates to:
  /// **'Review required'**
  String get reviewRequired;

  /// PR badge: CI checks are passing.
  ///
  /// In en, this message translates to:
  /// **'Checks passing'**
  String get checksPassing;

  /// PR badge: CI checks are failing.
  ///
  /// In en, this message translates to:
  /// **'Checks failing'**
  String get checksFailing;

  /// PR badge: CI checks are still running.
  ///
  /// In en, this message translates to:
  /// **'Checks running'**
  String get checksRunning;

  /// Accessible name of a PR row: its title and lifecycle word.
  ///
  /// In en, this message translates to:
  /// **'{title}, {status}'**
  String prSemanticLabel(String title, String status);

  /// Fallback title of the PR detail header while the repo name resolves.
  ///
  /// In en, this message translates to:
  /// **'Pull request'**
  String get pullRequest;

  /// Error state of the PR detail screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this pull request'**
  String get prLoadFailed;

  /// Semantic label of the button opening the PR on GitHub/GitLab.
  ///
  /// In en, this message translates to:
  /// **'Open on the forge'**
  String get openOnForge;

  /// Validation error: a request-changes review needs a body.
  ///
  /// In en, this message translates to:
  /// **'Add a comment explaining what needs changing.'**
  String get requestChangesNeedsComment;

  /// PR detail tab: description, reviews and comments.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversation;

  /// PR detail tab: changed files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// PR detail tab: CI check runs.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checks;

  /// A tab label with its item count, e.g. 'Files (12)'.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String labelWithCount(String label, int count);

  /// Badge: how many files the PR changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// Badge: how many commits the PR carries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 commit} other{{count} commits}}'**
  String commitsCount(int count);

  /// Badge: the PR has merge conflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get conflicts;

  /// Label introducing the PR's reviewer list.
  ///
  /// In en, this message translates to:
  /// **'Reviewers'**
  String get reviewers;

  /// Conversation tab empty state.
  ///
  /// In en, this message translates to:
  /// **'No description and no comments yet.'**
  String get noDescriptionNoComments;

  /// Files tab empty state.
  ///
  /// In en, this message translates to:
  /// **'No changed files.'**
  String get noChangedFiles;

  /// Checks tab empty state.
  ///
  /// In en, this message translates to:
  /// **'No checks reported for the head commit.'**
  String get noChecksReported;

  /// Hint text of the review comment composer.
  ///
  /// In en, this message translates to:
  /// **'Leave a review comment…'**
  String get reviewCommentHint;

  /// Button submitting a comment-only review.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Success notice after posting a review comment.
  ///
  /// In en, this message translates to:
  /// **'Comment posted'**
  String get commentPosted;

  /// Button submitting a request-changes review.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// Button squash-merging the PR.
  ///
  /// In en, this message translates to:
  /// **'Squash and merge'**
  String get squashAndMerge;

  /// Footer when the PR is not open, e.g. 'Merged — no actions available.'.
  ///
  /// In en, this message translates to:
  /// **'{status} — no actions available.'**
  String noActionsAvailable(String status);

  /// Timeline badge: this review approved the PR.
  ///
  /// In en, this message translates to:
  /// **'approved'**
  String get reviewApproved;

  /// Timeline badge: this review requested changes.
  ///
  /// In en, this message translates to:
  /// **'requested changes'**
  String get reviewRequestedChanges;

  /// Timeline badge: this review only commented.
  ///
  /// In en, this message translates to:
  /// **'reviewed'**
  String get reviewCommented;

  /// Timeline badge: this review is still pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get reviewPending;

  /// Fallback author name on a conversation bubble.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknownAuthor;

  /// Accessible name of an expanded file tile.
  ///
  /// In en, this message translates to:
  /// **'Hide the diff for {file}'**
  String hideDiffFor(String file);

  /// Accessible name of a collapsed file tile.
  ///
  /// In en, this message translates to:
  /// **'Show the diff for {file}'**
  String showDiffFor(String file);

  /// CI check state: still running.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get checkRunning;

  /// CI check state: succeeded.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get checkPassed;

  /// CI check state: failed, timed out or needs action.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get checkFailed;

  /// CI check state: cancelled or stale.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get checkCancelled;

  /// CI check state: skipped or neutral.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get checkSkipped;

  /// A check state with its elapsed time, e.g. 'passed · 4m'.
  ///
  /// In en, this message translates to:
  /// **'{label} · {duration}'**
  String labelWithDuration(String label, String duration);

  /// Accessible name of a check row: its name and state word.
  ///
  /// In en, this message translates to:
  /// **'{name}, {state}'**
  String checkSemanticLabel(String name, String state);

  /// Shown when a file has no textual patch.
  ///
  /// In en, this message translates to:
  /// **'No text diff for this file — it is binary, or too large for the forge to return one.'**
  String get noTextDiff;

  /// Button lifting the diff row budget.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show the remaining line} other{Show the remaining {count} lines}}'**
  String showRemainingLines(int count);

  /// Marker for the elided stretch between two diff hunks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unchanged line} other{{count} unchanged lines}}'**
  String unchangedLines(int count);

  /// Pill re-engaging follow mode and snapping to the newest message.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// Pill label while an agent turn streams below the fold.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get streaming;

  /// Transcript footer while the agent turn is still streaming.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get working;

  /// Transcript tool call: the inputs section label.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// Transcript tool call: the outputs section label.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// Compact time-since label for under a minute ago.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// Compact time-since label in minutes, e.g. '4m'.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String agoMinutes(int count);

  /// Compact time-since label in hours, e.g. '3h'.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String agoHours(int count);

  /// Compact time-since label in days, e.g. '6d'.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String agoDays(int count);

  /// Calendar day heading for the current day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Calendar day heading for the next day.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Calendar day heading for the previous day.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Compact duration in minutes, e.g. '45m'.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String durationMinutes(int count);

  /// Compact duration in whole hours, e.g. '2h'.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String durationHours(int count);

  /// Compact duration in hours and minutes, e.g. '1h 30m'.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'cs',
    'de',
    'el',
    'en',
    'es',
    'fa',
    'fr',
    'he',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'nb',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'sv',
    'th',
    'tr',
    'uk',
    'ur',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case 'MX':
            return AppLocalizationsEsMx();
        }
        break;
      }
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'CA':
            return AppLocalizationsFrCa();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'HK':
            return AppLocalizationsZhHk();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
