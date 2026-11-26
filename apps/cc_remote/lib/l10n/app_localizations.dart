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

  /// Button copying the entire verbatim shell script on an agent approval.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get copyCommand;

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

  /// Action to create a folder for organizing spaces in the current workspace.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newSpaceFolder;

  /// Label for the name field when creating or renaming a space folder.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// Action to rename a folder containing spaces.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get renameSpaceFolder;

  /// Action to delete a folder; its spaces remain unless the user explicitly chooses permanent deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get deleteSpaceFolder;

  /// Action to put a space inside a selected folder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveSpaceToFolder;

  /// Action to leave a space unfiled without deleting the space.
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get removeSpaceFromFolder;

  /// Accessible label for the menu of actions on a space folder.
  ///
  /// In en, this message translates to:
  /// **'Folder actions'**
  String get spaceFolderActions;

  /// Irreversible-deletion warning in the folder delete confirmation: choosing to permanently delete the contained spaces also removes their messages and worktrees for all users.
  ///
  /// In en, this message translates to:
  /// **'Deleting spaces permanently removes their messages and worktrees for everyone. This cannot be undone.'**
  String get deleteFolderWithSpacesWarning;

  /// Opt-in checkbox when deleting a folder: also permanently delete every space inside it.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the spaces in this folder'**
  String get deleteSpacesInFolder;

  /// Confirmation button when permanently deleting both a folder and its spaces.
  ///
  /// In en, this message translates to:
  /// **'Delete folder and spaces'**
  String get deleteFolderAndSpaces;

  /// Explains that spaces remain available without a folder if the permanent-delete option is not selected.
  ///
  /// In en, this message translates to:
  /// **'Otherwise, spaces will remain unfiled.'**
  String get keepSpacesInFolder;

  /// Button to create a space folder after entering its name.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Heading for spaces in the workspace that are not assigned to any folder.
  ///
  /// In en, this message translates to:
  /// **'Other spaces'**
  String get otherSpaces;

  /// Error notice when creating, renaming, moving, or deleting a space folder fails to save.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update folders'**
  String get folderUpdateFailed;

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

  /// Fallback display name for another member's message.
  ///
  /// In en, this message translates to:
  /// **'Teammate'**
  String get teammate;

  /// Display name for a message the server itself posted (takeover notices, delegation outcomes).
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSender;

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

  /// No description provided for @mobileConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get mobileConversations;

  /// No description provided for @mobileNewConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get mobileNewConversation;

  /// No description provided for @mobileConversationName.
  ///
  /// In en, this message translates to:
  /// **'Conversation name'**
  String get mobileConversationName;

  /// No description provided for @mobileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get mobileRename;

  /// No description provided for @mobileManageSpace.
  ///
  /// In en, this message translates to:
  /// **'Manage space'**
  String get mobileManageSpace;

  /// No description provided for @mobileArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get mobileArchived;

  /// No description provided for @mobileSearchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search all messages in this space'**
  String get mobileSearchMessages;

  /// No description provided for @mobileSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get mobileSearch;

  /// No description provided for @mobileNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get mobileNoResults;

  /// No description provided for @mobileReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get mobileReopen;

  /// No description provided for @mobileArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get mobileArchive;

  /// No description provided for @mobileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress and context'**
  String get mobileProgress;

  /// No description provided for @mobileReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark this conversation as read'**
  String get mobileReadFailed;

  /// No description provided for @mobileSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Your draft is still here.'**
  String get mobileSendFailed;

  /// Fallback for a sent attachment whose file is no longer available.
  ///
  /// In en, this message translates to:
  /// **'Attachment unavailable'**
  String get sentAttachmentUnavailable;

  /// Fallback when loading a sent attachment fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load attachment'**
  String get sentAttachmentLoadFailed;

  /// No description provided for @mobileActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get mobileActionFailed;

  /// No description provided for @mobileRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get mobileRemove;

  /// No description provided for @mobileLinkedMessage.
  ///
  /// In en, this message translates to:
  /// **'Linked message'**
  String get mobileLinkedMessage;

  /// No description provided for @mobileOlderMessages.
  ///
  /// In en, this message translates to:
  /// **'Older messages'**
  String get mobileOlderMessages;

  /// No description provided for @mobileMessageActions.
  ///
  /// In en, this message translates to:
  /// **'Message actions'**
  String get mobileMessageActions;

  /// No description provided for @mobileOpenThread.
  ///
  /// In en, this message translates to:
  /// **'Open thread'**
  String get mobileOpenThread;

  /// No description provided for @mobileCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get mobileCopyLink;

  /// No description provided for @mobileStopRun.
  ///
  /// In en, this message translates to:
  /// **'Stop run'**
  String get mobileStopRun;

  /// No description provided for @mobileStopRunConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop this agent run? Work already completed will be kept.'**
  String get mobileStopRunConfirm;

  /// No description provided for @mobileControlUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This run has finished or does not support this control.'**
  String get mobileControlUnsupported;

  /// No description provided for @mobilePauseRequested.
  ///
  /// In en, this message translates to:
  /// **'Pause requested at the next turn boundary'**
  String get mobilePauseRequested;

  /// No description provided for @mobileResumed.
  ///
  /// In en, this message translates to:
  /// **'Run resumed'**
  String get mobileResumed;

  /// No description provided for @mobileStopRequested.
  ///
  /// In en, this message translates to:
  /// **'Stop requested'**
  String get mobileStopRequested;

  /// No description provided for @mobileQueuedMessages.
  ///
  /// In en, this message translates to:
  /// **'Queued messages'**
  String get mobileQueuedMessages;

  /// No description provided for @mobilePauseRun.
  ///
  /// In en, this message translates to:
  /// **'Pause at next turn'**
  String get mobilePauseRun;

  /// No description provided for @mobileResumeRun.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mobileResumeRun;

  /// No description provided for @mobileEditQueued.
  ///
  /// In en, this message translates to:
  /// **'Edit queued message'**
  String get mobileEditQueued;

  /// No description provided for @mobileSteerNow.
  ///
  /// In en, this message translates to:
  /// **'Steer now'**
  String get mobileSteerNow;

  /// No description provided for @mobileMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get mobileMoveUp;

  /// No description provided for @mobileMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get mobileMoveDown;

  /// No description provided for @mobileQueueChanged.
  ///
  /// In en, this message translates to:
  /// **'The queue changed, or this run cannot accept live steering. Refresh and try again.'**
  String get mobileQueueChanged;

  /// No description provided for @mobileActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get mobileActivity;

  /// No description provided for @mobilePermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions and audit'**
  String get mobilePermissions;

  /// No description provided for @mobilePlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get mobilePlans;

  /// No description provided for @mobileGoals.
  ///
  /// In en, this message translates to:
  /// **'Supervised goals'**
  String get mobileGoals;

  /// No description provided for @mobileCredentials.
  ///
  /// In en, this message translates to:
  /// **'Connections and credentials'**
  String get mobileCredentials;

  /// No description provided for @mobileWorkspaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This workspace is unavailable or you no longer have access.'**
  String get mobileWorkspaceUnavailable;

  /// No description provided for @mobilePrReviewThreads.
  ///
  /// In en, this message translates to:
  /// **'Review threads'**
  String get mobilePrReviewThreads;

  /// No description provided for @mobilePrThreadsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load review threads'**
  String get mobilePrThreadsLoadFailed;

  /// No description provided for @mobilePrNoReviewThreads.
  ///
  /// In en, this message translates to:
  /// **'No inline review threads yet'**
  String get mobilePrNoReviewThreads;

  /// No description provided for @mobilePrCommentPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to comment on this repository.'**
  String get mobilePrCommentPermissionDenied;

  /// No description provided for @mobilePrPermissionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking comment permissions…'**
  String get mobilePrPermissionChecking;

  /// No description provided for @mobilePrPermissionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check comment permissions. Retry to comment.'**
  String get mobilePrPermissionLoadFailed;

  /// No description provided for @mobilePrThreadLine.
  ///
  /// In en, this message translates to:
  /// **'{side} line {line}'**
  String mobilePrThreadLine(String side, String line);

  /// No description provided for @mobilePrOriginalSide.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get mobilePrOriginalSide;

  /// Label for choosing a pull request diff line for an inline comment.
  ///
  /// In en, this message translates to:
  /// **'Choose a line to comment on'**
  String get mobilePrSelectCommentLine;

  /// No description provided for @mobilePrUpdatedSide.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get mobilePrUpdatedSide;

  /// No description provided for @mobilePrThreadResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get mobilePrThreadResolved;

  /// No description provided for @mobilePrReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get mobilePrReplyHint;

  /// No description provided for @mobilePrCommentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a comment before posting.'**
  String get mobilePrCommentRequired;

  /// No description provided for @mobilePrReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get mobilePrReply;

  /// No description provided for @mobilePrReopenThread.
  ///
  /// In en, this message translates to:
  /// **'Reopen thread'**
  String get mobilePrReopenThread;

  /// No description provided for @mobilePrResolveThread.
  ///
  /// In en, this message translates to:
  /// **'Resolve thread'**
  String get mobilePrResolveThread;

  /// No description provided for @mobilePrResolvePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Only the pull request author or someone with write access can resolve this thread.'**
  String get mobilePrResolvePermissionDenied;

  /// No description provided for @mobilePrCommentOnLine.
  ///
  /// In en, this message translates to:
  /// **'Comment on {side} line {line}'**
  String mobilePrCommentOnLine(String side, String line);

  /// No description provided for @mobilePrInlineCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write an inline comment…'**
  String get mobilePrInlineCommentHint;

  /// No description provided for @mobilePrPostInlineComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get mobilePrPostInlineComment;

  /// No description provided for @mobilePrCommentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Inline comments are unavailable for this pull request.'**
  String get mobilePrCommentUnavailable;

  /// No description provided for @mobilePrPatchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The forge did not provide a text patch for this file.'**
  String get mobilePrPatchUnavailable;

  /// No description provided for @mobilePrNoPatchForFile.
  ///
  /// In en, this message translates to:
  /// **'The patch for this file is not available.'**
  String get mobilePrNoPatchForFile;

  /// No description provided for @mobileTicketNew.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get mobileTicketNew;

  /// No description provided for @mobileTicketCreate.
  ///
  /// In en, this message translates to:
  /// **'Create ticket'**
  String get mobileTicketCreate;

  /// No description provided for @mobileTicketEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit ticket'**
  String get mobileTicketEdit;

  /// No description provided for @mobileTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get mobileTicketTitle;

  /// No description provided for @mobileTicketTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title to save this ticket.'**
  String get mobileTicketTitleRequired;

  /// No description provided for @mobileTicketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mobileTicketDescription;

  /// No description provided for @mobileTicketMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'Add details in Markdown'**
  String get mobileTicketMarkdownHint;

  /// No description provided for @mobileTicketPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get mobileTicketPriority;

  /// No description provided for @mobileTicketPriorityNone.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get mobileTicketPriorityNone;

  /// No description provided for @mobileTicketPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get mobileTicketPriorityUrgent;

  /// No description provided for @mobileTicketPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get mobileTicketPriorityHigh;

  /// No description provided for @mobileTicketPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mobileTicketPriorityMedium;

  /// No description provided for @mobileTicketPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get mobileTicketPriorityLow;

  /// No description provided for @mobileTicketLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get mobileTicketLabels;

  /// No description provided for @mobileTicketLabelsHint.
  ///
  /// In en, this message translates to:
  /// **'One label per line'**
  String get mobileTicketLabelsHint;

  /// No description provided for @mobileTicketLabelsHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter each label on a separate line.'**
  String get mobileTicketLabelsHelp;

  /// Shows the workspace's configured ticketing provider in the create form.
  ///
  /// In en, this message translates to:
  /// **'Filed in {provider}'**
  String mobileTicketWorkspaceProvider(String provider);

  /// No description provided for @mobileTicketProviderLocal.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get mobileTicketProviderLocal;

  /// No description provided for @mobileTicketUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get mobileTicketUnassigned;

  /// No description provided for @mobileTicketAssignedFilter.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get mobileTicketAssignedFilter;

  /// No description provided for @mobileTicketAgentsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load agents'**
  String get mobileTicketAgentsLoadFailed;

  /// No description provided for @mobileTicketSearch.
  ///
  /// In en, this message translates to:
  /// **'Search tickets'**
  String get mobileTicketSearch;

  /// No description provided for @mobileTicketSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Title, key, description, label or assignee'**
  String get mobileTicketSearchHint;

  /// No description provided for @mobileTicketClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear ticket search'**
  String get mobileTicketClearSearch;

  /// No description provided for @mobileTicketNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching tickets'**
  String get mobileTicketNoMatches;

  /// No description provided for @mobileTicketAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try another search or change the filters.'**
  String get mobileTicketAdjustFilters;

  /// No description provided for @mobileTicketClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get mobileTicketClearFilters;

  /// No description provided for @mobileTicketNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ticket not found'**
  String get mobileTicketNotFound;

  /// No description provided for @mobileTicketNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'This ticket may have been deleted or moved out of this workspace.'**
  String get mobileTicketNotFoundDescription;

  /// No description provided for @mobileTicketWorkspaceChanged.
  ///
  /// In en, this message translates to:
  /// **'The workspace changed. Return to the current workspace before saving.'**
  String get mobileTicketWorkspaceChanged;

  /// No description provided for @mobileTicketOpenLinkedSpace.
  ///
  /// In en, this message translates to:
  /// **'Open linked space'**
  String get mobileTicketOpenLinkedSpace;

  /// No description provided for @mobileTicketReadOnly.
  ///
  /// In en, this message translates to:
  /// **'A workspace member role is required to change tickets.'**
  String get mobileTicketReadOnly;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionTitle;

  /// No description provided for @permissionWorkspaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the workspace'**
  String get permissionWorkspaceFailed;

  /// No description provided for @permissionNoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to inspect permissions.'**
  String get permissionNoWorkspace;

  /// No description provided for @permissionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading permissions…'**
  String get permissionLoading;

  /// No description provided for @permissionScopeDescription.
  ///
  /// In en, this message translates to:
  /// **'Inspect how each action is decided at this scope. Workspace rules can be inherited by agents and spaces.'**
  String get permissionScopeDescription;

  /// No description provided for @permissionScope.
  ///
  /// In en, this message translates to:
  /// **'Policy scope'**
  String get permissionScope;

  /// No description provided for @permissionWorkspaceScope.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get permissionWorkspaceScope;

  /// No description provided for @permissionAgentScope.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get permissionAgentScope;

  /// No description provided for @permissionSpaceScope.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get permissionSpaceScope;

  /// No description provided for @permissionAgentContext.
  ///
  /// In en, this message translates to:
  /// **'Agent acting in this space'**
  String get permissionAgentContext;

  /// No description provided for @permissionNoAgentContext.
  ///
  /// In en, this message translates to:
  /// **'No agent selected'**
  String get permissionNoAgentContext;

  /// No description provided for @permissionTargetsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load scope targets'**
  String get permissionTargetsFailed;

  /// No description provided for @permissionNoTargets.
  ///
  /// In en, this message translates to:
  /// **'No targets are available at this scope.'**
  String get permissionNoTargets;

  /// No description provided for @permissionRoleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm your workspace role'**
  String get permissionRoleFailed;

  /// No description provided for @permissionMemberRequired.
  ///
  /// In en, this message translates to:
  /// **'A workspace member role is required to view policy rules.'**
  String get permissionMemberRequired;

  /// No description provided for @permissionRulesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load policy rules'**
  String get permissionRulesFailed;

  /// No description provided for @permissionAuditAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Authorization history is available to workspace admins only.'**
  String get permissionAuditAdminOnly;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionAllow;

  /// No description provided for @permissionAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask first'**
  String get permissionAsk;

  /// No description provided for @permissionDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get permissionDeny;

  /// No description provided for @permissionFileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete files'**
  String get permissionFileDelete;

  /// No description provided for @permissionFileWriteOutsideWorktree.
  ///
  /// In en, this message translates to:
  /// **'Write outside worktree'**
  String get permissionFileWriteOutsideWorktree;

  /// No description provided for @permissionGitCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit changes'**
  String get permissionGitCommit;

  /// No description provided for @permissionGitPush.
  ///
  /// In en, this message translates to:
  /// **'Push commits'**
  String get permissionGitPush;

  /// No description provided for @permissionPrCreate.
  ///
  /// In en, this message translates to:
  /// **'Create pull requests'**
  String get permissionPrCreate;

  /// No description provided for @permissionPrPublish.
  ///
  /// In en, this message translates to:
  /// **'Update or merge pull requests'**
  String get permissionPrPublish;

  /// No description provided for @permissionVendorSyncWrite.
  ///
  /// In en, this message translates to:
  /// **'Write vendor sync'**
  String get permissionVendorSyncWrite;

  /// No description provided for @permissionNetworkEgress.
  ///
  /// In en, this message translates to:
  /// **'Access network'**
  String get permissionNetworkEgress;

  /// No description provided for @permissionSecretAccess.
  ///
  /// In en, this message translates to:
  /// **'Access secrets'**
  String get permissionSecretAccess;

  /// No description provided for @permissionPackageInstall.
  ///
  /// In en, this message translates to:
  /// **'Install packages'**
  String get permissionPackageInstall;

  /// No description provided for @permissionProcessSpawn.
  ///
  /// In en, this message translates to:
  /// **'Spawn processes'**
  String get permissionProcessSpawn;

  /// No description provided for @permissionWorkspaceMutation.
  ///
  /// In en, this message translates to:
  /// **'Change workspace'**
  String get permissionWorkspaceMutation;

  /// No description provided for @permissionEnclosureControl.
  ///
  /// In en, this message translates to:
  /// **'Control enclosure'**
  String get permissionEnclosureControl;

  /// No description provided for @permissionChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the rule'**
  String get permissionChangeFailed;

  /// No description provided for @permissionEffectiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Effective for this scope without action arguments. Conditional grants below apply only to matching requests; the server makes the final decision.'**
  String get permissionEffectiveDescription;

  /// No description provided for @permissionSpaceAgentNote.
  ///
  /// In en, this message translates to:
  /// **'No agent selected. Agent-specific rules are omitted until you choose one above.'**
  String get permissionSpaceAgentNote;

  /// No description provided for @permissionScopedGrants.
  ///
  /// In en, this message translates to:
  /// **'Rules at this scope'**
  String get permissionScopedGrants;

  /// No description provided for @permissionModePreset.
  ///
  /// In en, this message translates to:
  /// **'Mode preset'**
  String get permissionModePreset;

  /// No description provided for @permissionBuiltInDefault.
  ///
  /// In en, this message translates to:
  /// **'Built-in default'**
  String get permissionBuiltInDefault;

  /// No description provided for @permissionRemembered.
  ///
  /// In en, this message translates to:
  /// **'Standing approval'**
  String get permissionRemembered;

  /// No description provided for @permissionSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get permissionSource;

  /// No description provided for @permissionSetAtThisScope.
  ///
  /// In en, this message translates to:
  /// **'{source} · set here'**
  String permissionSetAtThisScope(String source);

  /// No description provided for @permissionInheritedFrom.
  ///
  /// In en, this message translates to:
  /// **'{source} · inherited'**
  String permissionInheritedFrom(String source);

  /// No description provided for @permissionExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String permissionExpiresAt(String date);

  /// No description provided for @permissionSetHere.
  ///
  /// In en, this message translates to:
  /// **'Set a rule here'**
  String get permissionSetHere;

  /// No description provided for @permissionConfirmRevoke.
  ///
  /// In en, this message translates to:
  /// **'Confirm revoke'**
  String get permissionConfirmRevoke;

  /// No description provided for @permissionRevokeRule.
  ///
  /// In en, this message translates to:
  /// **'Revoke rule'**
  String get permissionRevokeRule;

  /// No description provided for @permissionCommandPrefix.
  ///
  /// In en, this message translates to:
  /// **'Command prefix: {prefix}'**
  String permissionCommandPrefix(String prefix);

  /// No description provided for @permissionNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get permissionNoExpiry;

  /// No description provided for @permissionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get permissionExpired;

  /// No description provided for @permissionExplicitRule.
  ///
  /// In en, this message translates to:
  /// **'Explicit rule'**
  String get permissionExplicitRule;

  /// No description provided for @permissionEnforcementAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory: ask-first rules are logged without prompting'**
  String get permissionEnforcementAdvisory;

  /// No description provided for @permissionEnforcementSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft enforcement: override requires authorization'**
  String get permissionEnforcementSoft;

  /// No description provided for @permissionEnforcementHard.
  ///
  /// In en, this message translates to:
  /// **'Hard enforcement: cannot be overridden'**
  String get permissionEnforcementHard;

  /// No description provided for @permissionPaths.
  ///
  /// In en, this message translates to:
  /// **'Paths: {paths}'**
  String permissionPaths(String paths);

  /// No description provided for @permissionRefs.
  ///
  /// In en, this message translates to:
  /// **'Git refs: {refs}'**
  String permissionRefs(String refs);

  /// No description provided for @permissionHosts.
  ///
  /// In en, this message translates to:
  /// **'Hosts: {hosts}'**
  String permissionHosts(String hosts);

  /// No description provided for @permissionCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands: {commands}'**
  String permissionCommands(String commands);

  /// Permissions screen: the tools one listed rule or standing approval is limited to. {tools} is a comma-separated list of tool names, which stay as they are.
  ///
  /// In en, this message translates to:
  /// **'Tools: {tools}'**
  String permissionTools(String tools);

  /// Permissions screen: shown on a listed standing approval when the action it approves is set to Deny. A standing approval only spares a question; it never overrides a Deny.
  ///
  /// In en, this message translates to:
  /// **'Not in effect while this action is denied'**
  String get permissionNotInEffect;

  /// No description provided for @permissionMaxCount.
  ///
  /// In en, this message translates to:
  /// **'Maximum count: {count}'**
  String permissionMaxCount(String count);

  /// No description provided for @permissionMaxCents.
  ///
  /// In en, this message translates to:
  /// **'Maximum cents: {cents}'**
  String permissionMaxCents(String cents);

  /// No description provided for @permissionAuditHeading.
  ///
  /// In en, this message translates to:
  /// **'Authorization history'**
  String get permissionAuditHeading;

  /// No description provided for @permissionAuditDescription.
  ///
  /// In en, this message translates to:
  /// **'Recent decisions recorded by the server. Only admins can inspect the log or verify its hash chain.'**
  String get permissionAuditDescription;

  /// No description provided for @permissionOnBehalfOf.
  ///
  /// In en, this message translates to:
  /// **'on behalf of {user}'**
  String permissionOnBehalfOf(String user);

  /// No description provided for @permissionPrompted.
  ///
  /// In en, this message translates to:
  /// **'Human approval requested'**
  String get permissionPrompted;

  /// No description provided for @permissionVerifyChain.
  ///
  /// In en, this message translates to:
  /// **'Verify audit chain'**
  String get permissionVerifyChain;

  /// No description provided for @permissionVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the audit chain'**
  String get permissionVerifyFailed;

  /// No description provided for @permissionChainIntact.
  ///
  /// In en, this message translates to:
  /// **'Chain intact · {count} entries checked'**
  String permissionChainIntact(String count);

  /// No description provided for @permissionChainBroken.
  ///
  /// In en, this message translates to:
  /// **'Chain broken at entry {sequence}: {reason}'**
  String permissionChainBroken(String sequence, String reason);

  /// No description provided for @permissionAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No authorization decisions recorded yet.'**
  String get permissionAuditEmpty;

  /// No description provided for @permissionAuditFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load authorization history'**
  String get permissionAuditFailed;

  /// No description provided for @mobilePlansLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans'**
  String get mobilePlansLoadFailed;

  /// No description provided for @mobilePlansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get mobilePlansEmpty;

  /// No description provided for @mobilePlansEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Plans submitted by agents will appear here for review.'**
  String get mobilePlansEmptyDescription;

  /// No description provided for @mobilePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get mobilePlanTitle;

  /// No description provided for @mobilePlanMissing.
  ///
  /// In en, this message translates to:
  /// **'This plan is no longer available in this workspace.'**
  String get mobilePlanMissing;

  /// No description provided for @mobilePlanStepCount.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String mobilePlanStepCount(int count);

  /// No description provided for @mobilePlanDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get mobilePlanDraft;

  /// No description provided for @mobilePlanProposed.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get mobilePlanProposed;

  /// No description provided for @mobilePlanApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get mobilePlanApproved;

  /// No description provided for @mobilePlanRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get mobilePlanRejected;

  /// No description provided for @mobilePlanSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Superseded'**
  String get mobilePlanSuperseded;

  /// No description provided for @mobilePlanExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get mobilePlanExecuting;

  /// No description provided for @mobilePlanSynthesizing.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing'**
  String get mobilePlanSynthesizing;

  /// No description provided for @mobilePlanCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mobilePlanCompleted;

  /// No description provided for @mobilePlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get mobilePlanFailed;

  /// No description provided for @mobilePlanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get mobilePlanCancelled;

  /// No description provided for @mobilePlanRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String mobilePlanRevision(String revision);

  /// No description provided for @mobilePlanSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get mobilePlanSteps;

  /// No description provided for @mobilePlanNoSteps.
  ///
  /// In en, this message translates to:
  /// **'No steps were submitted for this plan.'**
  String get mobilePlanNoSteps;

  /// No description provided for @mobilePlanAssumptions.
  ///
  /// In en, this message translates to:
  /// **'Clarifications'**
  String get mobilePlanAssumptions;

  /// No description provided for @mobilePlanDependsOn.
  ///
  /// In en, this message translates to:
  /// **'Depends on {keys}'**
  String mobilePlanDependsOn(String keys);

  /// No description provided for @mobilePlanStepCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated up to {cost}'**
  String mobilePlanStepCost(String cost);

  /// No description provided for @mobilePlanSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get mobilePlanSelect;

  /// No description provided for @mobilePlanSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get mobilePlanSelected;

  /// No description provided for @mobilePlanEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate cost'**
  String get mobilePlanEstimate;

  /// No description provided for @mobilePlanEstimateRequired.
  ///
  /// In en, this message translates to:
  /// **'Estimate the plan before approving execution.'**
  String get mobilePlanEstimateRequired;

  /// No description provided for @mobilePlanEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost: {low}–{high}'**
  String mobilePlanEstimatedCost(String low, String high);

  /// No description provided for @mobilePlanCostUnknown.
  ///
  /// In en, this message translates to:
  /// **'not available'**
  String get mobilePlanCostUnknown;

  /// No description provided for @mobilePlanNoHardCap.
  ///
  /// In en, this message translates to:
  /// **'no hard cap'**
  String get mobilePlanNoHardCap;

  /// No description provided for @mobilePlanExceedsBudget.
  ///
  /// In en, this message translates to:
  /// **'The estimate exceeds the configured budget. Review before approving.'**
  String get mobilePlanExceedsBudget;

  /// No description provided for @mobilePlanPartialEstimate.
  ///
  /// In en, this message translates to:
  /// **'This estimate covers the entire plan; selected steps may cost less.'**
  String get mobilePlanPartialEstimate;

  /// No description provided for @mobilePlanConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Start the entire plan?'**
  String get mobilePlanConfirmAll;

  /// No description provided for @mobilePlanConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Start selected steps?'**
  String get mobilePlanConfirmSelected;

  /// No description provided for @mobilePlanExecutionConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Approving starts execution and can incur charges. Estimated high cost: {cost}. Budget cap: {cap}.'**
  String mobilePlanExecutionConfirmation(String cost, String cap);

  /// No description provided for @mobilePlanApproveAll.
  ///
  /// In en, this message translates to:
  /// **'Approve all and run'**
  String get mobilePlanApproveAll;

  /// No description provided for @mobilePlanApproveSelected.
  ///
  /// In en, this message translates to:
  /// **'Approve selected and run'**
  String get mobilePlanApproveSelected;

  /// No description provided for @mobilePlanWiden.
  ///
  /// In en, this message translates to:
  /// **'Approve additional steps'**
  String get mobilePlanWiden;

  /// No description provided for @mobilePlanWidenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Release {count} more steps to execute? They can incur charges. Existing execution cost cap: {cap}.'**
  String mobilePlanWidenConfirm(String count, String cap);

  /// No description provided for @mobilePlanChanged.
  ///
  /// In en, this message translates to:
  /// **'The plan changed during review. Reopen the latest revision and estimate it again.'**
  String get mobilePlanChanged;

  /// No description provided for @mobilePlanReject.
  ///
  /// In en, this message translates to:
  /// **'Reject plan'**
  String get mobilePlanReject;

  /// No description provided for @mobilePlanRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject this plan? It will not execute.'**
  String get mobilePlanRejectConfirm;

  /// No description provided for @mobilePlanStop.
  ///
  /// In en, this message translates to:
  /// **'Stop execution'**
  String get mobilePlanStop;

  /// No description provided for @mobilePlanStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop this plan\'s execution? Work already completed will not be undone.'**
  String get mobilePlanStopConfirm;

  /// No description provided for @mobilePlanRunId.
  ///
  /// In en, this message translates to:
  /// **'Execution run: {runId}'**
  String mobilePlanRunId(String runId);

  /// No description provided for @mobilePlanExecutionPending.
  ///
  /// In en, this message translates to:
  /// **'Approval accepted. Waiting for the execution record…'**
  String get mobilePlanExecutionPending;

  /// No description provided for @mobilePlanProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} execution steps completed'**
  String mobilePlanProgress(String completed, String total);

  /// No description provided for @mobilePlanOpenConversation.
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get mobilePlanOpenConversation;

  /// No description provided for @mobileGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervised goals'**
  String get mobileGoalsTitle;

  /// No description provided for @mobileGoalsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load supervised goals'**
  String get mobileGoalsLoadFailed;

  /// No description provided for @mobileGoalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No supervised goals yet'**
  String get mobileGoalsEmpty;

  /// No description provided for @mobileGoalsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Start one in a space, or send /goal in a conversation.'**
  String get mobileGoalsEmptyDescription;

  /// No description provided for @mobileGoalMissing.
  ///
  /// In en, this message translates to:
  /// **'This goal is no longer available in this workspace.'**
  String get mobileGoalMissing;

  /// No description provided for @mobileGoalActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get mobileGoalActive;

  /// No description provided for @mobileGoalPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mobileGoalPaused;

  /// No description provided for @mobileGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mobileGoalCompleted;

  /// No description provided for @mobileGoalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get mobileGoalFailed;

  /// No description provided for @mobileGoalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get mobileGoalCancelled;

  /// No description provided for @mobileGoalBudgetExhausted.
  ///
  /// In en, this message translates to:
  /// **'Budget reached'**
  String get mobileGoalBudgetExhausted;

  /// No description provided for @mobileGoalFailures.
  ///
  /// In en, this message translates to:
  /// **'Consecutive failed runs: {count}'**
  String mobileGoalFailures(String count);

  /// No description provided for @mobileGoalFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'The supervisor stopped after repeated failed runs. Review the conversation for details.'**
  String get mobileGoalFailedDescription;

  /// No description provided for @mobileGoalPause.
  ///
  /// In en, this message translates to:
  /// **'Pause goal'**
  String get mobileGoalPause;

  /// No description provided for @mobileGoalResume.
  ///
  /// In en, this message translates to:
  /// **'Resume goal'**
  String get mobileGoalResume;

  /// No description provided for @mobileGoalStop.
  ///
  /// In en, this message translates to:
  /// **'Cancel goal'**
  String get mobileGoalStop;

  /// No description provided for @mobileGoalStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently cancel this supervised goal? It cannot be resumed.'**
  String get mobileGoalStopConfirm;

  /// No description provided for @mobileGoalRaiseBudget.
  ///
  /// In en, this message translates to:
  /// **'Raise budget and resume'**
  String get mobileGoalRaiseBudget;

  /// No description provided for @mobileGoalRaiseTo.
  ///
  /// In en, this message translates to:
  /// **'Raise budget to {amount} and resume'**
  String mobileGoalRaiseTo(String amount);

  /// No description provided for @mobileGoalRaiseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Increase this goal\'s cost cap from {oldCap} to {newCap} and resume spending?'**
  String mobileGoalRaiseConfirm(String oldCap, String newCap);

  /// No description provided for @mobileGoalOpenConversation.
  ///
  /// In en, this message translates to:
  /// **'Open goal conversation'**
  String get mobileGoalOpenConversation;

  /// No description provided for @mobileGoalCreate.
  ///
  /// In en, this message translates to:
  /// **'Start supervised goal'**
  String get mobileGoalCreate;

  /// No description provided for @mobileGoalChooseSpace.
  ///
  /// In en, this message translates to:
  /// **'Run in space'**
  String get mobileGoalChooseSpace;

  /// No description provided for @mobileGoalNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Create a space before starting a goal.'**
  String get mobileGoalNoSpaces;

  /// No description provided for @mobileGoalChooseAgent.
  ///
  /// In en, this message translates to:
  /// **'Run with agent'**
  String get mobileGoalChooseAgent;

  /// No description provided for @mobileGoalNoAgents.
  ///
  /// In en, this message translates to:
  /// **'Add an active agent before starting a goal.'**
  String get mobileGoalNoAgents;

  /// No description provided for @mobileGoalSelectedAgent.
  ///
  /// In en, this message translates to:
  /// **'{name} selected'**
  String mobileGoalSelectedAgent(String name);

  /// No description provided for @mobileGoalObjectiveHint.
  ///
  /// In en, this message translates to:
  /// **'What outcome should the agent pursue?'**
  String get mobileGoalObjectiveHint;

  /// No description provided for @mobileGoalBudgetUsd.
  ///
  /// In en, this message translates to:
  /// **'Cost cap (USD)'**
  String get mobileGoalBudgetUsd;

  /// No description provided for @mobileGoalCreateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a space and agent, enter an objective and set a positive cost cap in USD.'**
  String get mobileGoalCreateInvalid;

  /// No description provided for @mobileGoalCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start a supervised goal with a maximum cost of {cap}? The agent may begin immediately.'**
  String mobileGoalCreateConfirm(String cap);

  /// No description provided for @mobileGoalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server connection is not ready. Retry after reconnecting.'**
  String get mobileGoalUnavailable;

  /// No description provided for @mobileGoalConversationMissing.
  ///
  /// In en, this message translates to:
  /// **'The selected conversation is no longer available in this workspace.'**
  String get mobileGoalConversationMissing;

  /// No description provided for @mobileGoalCreateSent.
  ///
  /// In en, this message translates to:
  /// **'Goal started. Supervisor state will appear in this list.'**
  String get mobileGoalCreateSent;

  /// No description provided for @mobileGoalStartRefused.
  ///
  /// In en, this message translates to:
  /// **'No goal run started. Review the conversation for the supervisor\'s reason.'**
  String get mobileGoalStartRefused;

  /// No description provided for @mobileGoalSelectedSpace.
  ///
  /// In en, this message translates to:
  /// **'{name} selected'**
  String mobileGoalSelectedSpace(String name);

  /// No description provided for @requestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available in the active workspace.'**
  String get requestUnavailable;

  /// No description provided for @requestAlreadyResolved.
  ///
  /// In en, this message translates to:
  /// **'This request has already been resolved.'**
  String get requestAlreadyResolved;

  /// No description provided for @inboxCredentialsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Credentials blocking runs'**
  String get inboxCredentialsBlocked;

  /// No description provided for @inboxSyncFailures.
  ///
  /// In en, this message translates to:
  /// **'Failed vendor syncs'**
  String get inboxSyncFailures;

  /// No description provided for @inboxConfigureCredentials.
  ///
  /// In en, this message translates to:
  /// **'Configure credentials'**
  String get inboxConfigureCredentials;

  /// No description provided for @openTicket.
  ///
  /// In en, this message translates to:
  /// **'Open ticket'**
  String get openTicket;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear activity'**
  String get activityClearAll;

  /// No description provided for @activityClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'This hides all activity recorded so far for you on every device. New activity will still appear.'**
  String get activityClearConfirm;

  /// No description provided for @activityMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get activityMarkAllRead;

  /// No description provided for @activityMarkAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark every activity item in this workspace as read on all your devices?'**
  String get activityMarkAllConfirm;

  /// No description provided for @activityMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get activityMarkRead;

  /// No description provided for @activityMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get activityMarkUnread;

  /// No description provided for @activityDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get activityDismiss;

  /// No description provided for @activityResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get activityResolved;

  /// No description provided for @activityOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get activityOpen;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmpty;

  /// No description provided for @activityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load activity'**
  String get activityLoadFailed;

  /// No description provided for @activityAgentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Agent needs input'**
  String get activityAgentWaiting;

  /// No description provided for @activityAgentBlocked.
  ///
  /// In en, this message translates to:
  /// **'Agent action blocked'**
  String get activityAgentBlocked;

  /// No description provided for @activityMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get activityMessage;

  /// No description provided for @activityPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Pull request update'**
  String get activityPullRequest;

  /// No description provided for @activityRig.
  ///
  /// In en, this message translates to:
  /// **'Enclosure update'**
  String get activityRig;

  /// No description provided for @activityEvent.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get activityEvent;

  /// No description provided for @activityPrReady.
  ///
  /// In en, this message translates to:
  /// **'Pull request ready to merge'**
  String get activityPrReady;

  /// No description provided for @activityPrBlocked.
  ///
  /// In en, this message translates to:
  /// **'Pull request merge blocked'**
  String get activityPrBlocked;

  /// No description provided for @activityPrApproved.
  ///
  /// In en, this message translates to:
  /// **'Pull request approved'**
  String get activityPrApproved;

  /// No description provided for @activityPrChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get activityPrChanges;

  /// No description provided for @activityPrChecksFailed.
  ///
  /// In en, this message translates to:
  /// **'Pull request checks failed'**
  String get activityPrChecksFailed;

  /// No description provided for @activityPrChecksRecovered.
  ///
  /// In en, this message translates to:
  /// **'Pull request checks recovered'**
  String get activityPrChecksRecovered;

  /// No description provided for @activityPrComment.
  ///
  /// In en, this message translates to:
  /// **'Pull request comment'**
  String get activityPrComment;

  /// No description provided for @activityPrPublished.
  ///
  /// In en, this message translates to:
  /// **'Pull request published'**
  String get activityPrPublished;

  /// No description provided for @activityPrMerged.
  ///
  /// In en, this message translates to:
  /// **'Pull request merged'**
  String get activityPrMerged;

  /// No description provided for @activityPrMentioned.
  ///
  /// In en, this message translates to:
  /// **'Mentioned in a pull request'**
  String get activityPrMentioned;

  /// No description provided for @activityPrReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get activityPrReviewRequested;

  /// No description provided for @activityPrReviewStale.
  ///
  /// In en, this message translates to:
  /// **'Review needs refreshing'**
  String get activityPrReviewStale;

  /// No description provided for @activityTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned'**
  String get activityTicketAssigned;

  /// No description provided for @activityTicketChanged.
  ///
  /// In en, this message translates to:
  /// **'Ticket status changed'**
  String get activityTicketChanged;

  /// No description provided for @activityMeetingSoon.
  ///
  /// In en, this message translates to:
  /// **'Meeting starting soon'**
  String get activityMeetingSoon;

  /// No description provided for @activityCalendarExpired.
  ///
  /// In en, this message translates to:
  /// **'Calendar connection expired'**
  String get activityCalendarExpired;

  /// No description provided for @activityRigControl.
  ///
  /// In en, this message translates to:
  /// **'Enclosure control changed'**
  String get activityRigControl;

  /// No description provided for @activityRigClosed.
  ///
  /// In en, this message translates to:
  /// **'Enclosure stopped'**
  String get activityRigClosed;

  /// No description provided for @mobileSpacesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search spaces'**
  String get mobileSpacesSearch;

  /// No description provided for @mobileSpacesArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get mobileSpacesArchived;

  /// No description provided for @mobileSpacesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get mobileSpacesActive;

  /// No description provided for @mobileSpacesNew.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get mobileSpacesNew;

  /// No description provided for @mobileSpacesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage space'**
  String get mobileSpacesManage;

  /// No description provided for @mobileSpacesName.
  ///
  /// In en, this message translates to:
  /// **'Space name'**
  String get mobileSpacesName;

  /// No description provided for @mobileSpacesAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get mobileSpacesAgents;

  /// No description provided for @mobileSpacesMembers.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get mobileSpacesMembers;

  /// No description provided for @mobileSpacesRepos.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get mobileSpacesRepos;

  /// No description provided for @mobileSpacesAllRepos.
  ///
  /// In en, this message translates to:
  /// **'All linked repositories'**
  String get mobileSpacesAllRepos;

  /// No description provided for @mobileSpacesNoRepos.
  ///
  /// In en, this message translates to:
  /// **'No repositories'**
  String get mobileSpacesNoRepos;

  /// No description provided for @mobileSpacesBaseBranch.
  ///
  /// In en, this message translates to:
  /// **'Base branch (optional)'**
  String get mobileSpacesBaseBranch;

  /// No description provided for @mobileSpacesDefaultBranch.
  ///
  /// In en, this message translates to:
  /// **'Default branch'**
  String get mobileSpacesDefaultBranch;

  /// No description provided for @mobileSpacesMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mobileSpacesMode;

  /// No description provided for @mobileSpacesModeChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get mobileSpacesModeChat;

  /// No description provided for @mobileSpacesModeReview.
  ///
  /// In en, this message translates to:
  /// **'Review (read-only)'**
  String get mobileSpacesModeReview;

  /// No description provided for @mobileSpacesModePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan (read-only)'**
  String get mobileSpacesModePlan;

  /// No description provided for @mobileSpacesModeOrchestrate.
  ///
  /// In en, this message translates to:
  /// **'Orchestrate'**
  String get mobileSpacesModeOrchestrate;

  /// No description provided for @mobileSpacesAutonomy.
  ///
  /// In en, this message translates to:
  /// **'Autonomy override'**
  String get mobileSpacesAutonomy;

  /// No description provided for @mobileSpacesAutonomyInherited.
  ///
  /// In en, this message translates to:
  /// **'Inherited'**
  String get mobileSpacesAutonomyInherited;

  /// No description provided for @mobileSpacesAutonomyPropose.
  ///
  /// In en, this message translates to:
  /// **'Propose only'**
  String get mobileSpacesAutonomyPropose;

  /// No description provided for @mobileSpacesAutonomyApproval.
  ///
  /// In en, this message translates to:
  /// **'Act with approval'**
  String get mobileSpacesAutonomyApproval;

  /// No description provided for @mobileSpacesAutonomyFreely.
  ///
  /// In en, this message translates to:
  /// **'Act freely'**
  String get mobileSpacesAutonomyFreely;

  /// No description provided for @mobileSpacesAutonomyNotice.
  ///
  /// In en, this message translates to:
  /// **'An override cannot bypass action-policy prompts or denials. Only workspace admins can change it.'**
  String get mobileSpacesAutonomyNotice;

  /// No description provided for @mobileSpacesArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive space'**
  String get mobileSpacesArchive;

  /// No description provided for @mobileSpacesReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen space'**
  String get mobileSpacesReopen;

  /// No description provided for @mobileSpacesSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get mobileSpacesSave;

  /// No description provided for @mobileSpacesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create space'**
  String get mobileSpacesCreate;

  /// No description provided for @mobileSpacesOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update space'**
  String get mobileSpacesOperationFailed;

  /// No description provided for @mobileSpacesMissing.
  ///
  /// In en, this message translates to:
  /// **'Space not found in this workspace'**
  String get mobileSpacesMissing;

  /// No description provided for @mobileSpacesEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Enter a space name'**
  String get mobileSpacesEmptyName;

  /// No description provided for @mobileSpacesNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching spaces'**
  String get mobileSpacesNoMatches;

  /// No description provided for @mobileSpacesUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread agent reply'**
  String get mobileSpacesUnread;

  /// No description provided for @mobileSpacesNeedsInput.
  ///
  /// In en, this message translates to:
  /// **'Needs your input'**
  String get mobileSpacesNeedsInput;

  /// No description provided for @mobileSpacesRunning.
  ///
  /// In en, this message translates to:
  /// **'Agent running'**
  String get mobileSpacesRunning;

  /// No description provided for @mobileSpacesNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents in this workspace'**
  String get mobileSpacesNoAgents;

  /// No description provided for @mobileSpacesNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No other workspace members'**
  String get mobileSpacesNoMembers;

  /// No description provided for @mobileSpacesRepoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load repositories'**
  String get mobileSpacesRepoError;

  /// No description provided for @mobileSpacesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mobileSpacesRetry;

  /// No description provided for @mobileSpacesBranchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Choose or type a base branch when creating a space; existing space base branches cannot be changed.'**
  String get mobileSpacesBranchUnavailable;

  /// No description provided for @mobileSpacesArchivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived spaces'**
  String get mobileSpacesArchivedEmpty;

  /// No description provided for @mobileSpacesAllRepoWarning.
  ///
  /// In en, this message translates to:
  /// **'Newly linked workspace repositories will also be included in this space.'**
  String get mobileSpacesAllRepoWarning;

  /// No description provided for @mobileSpacesCreatedRetry.
  ///
  /// In en, this message translates to:
  /// **'Space created. Retry adding people, or open its management page.'**
  String get mobileSpacesCreatedRetry;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get progressConversation;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load progress'**
  String get progressLoadFailed;

  /// No description provided for @progressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable'**
  String get progressUnavailable;

  /// No description provided for @progressUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'This conversation is not in the active workspace and space. Return to its space to continue.'**
  String get progressUnavailableDescription;

  /// No description provided for @progressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update progress'**
  String get progressSaveFailed;

  /// No description provided for @progressGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get progressGoal;

  /// No description provided for @progressNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No working goal set'**
  String get progressNoGoal;

  /// No description provided for @progressSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get progressSetGoal;

  /// No description provided for @progressEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get progressEditGoal;

  /// No description provided for @progressClearGoal.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get progressClearGoal;

  /// No description provided for @progressGoalRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a goal before saving.'**
  String get progressGoalRequired;

  /// No description provided for @progressTodos.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get progressTodos;

  /// Short label for the agent task-list tool in conversation transcripts.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get transcriptToolTodos;

  /// Short label for the agent memory-search tool in conversation transcripts.
  ///
  /// In en, this message translates to:
  /// **'Search memory'**
  String get transcriptToolSearchMemory;

  /// Short label for the agent media-rendering tool in conversation transcripts.
  ///
  /// In en, this message translates to:
  /// **'Render media'**
  String get transcriptToolRenderMedia;

  /// No description provided for @progressNoTodos.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get progressNoTodos;

  /// No description provided for @progressNewTodo.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get progressNewTodo;

  /// No description provided for @progressAddTodo.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get progressAddTodo;

  /// No description provided for @progressEditTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get progressEditTodo;

  /// No description provided for @progressTodoRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a task before saving.'**
  String get progressTodoRequired;

  /// No description provided for @progressTodoNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'That task was removed. Reload the list and try again.'**
  String get progressTodoNoLongerExists;

  /// No description provided for @progressWorkspaceChanged.
  ///
  /// In en, this message translates to:
  /// **'The active workspace changed. Return to this conversation and try again.'**
  String get progressWorkspaceChanged;

  /// No description provided for @progressRemoveTodo.
  ///
  /// In en, this message translates to:
  /// **'Remove task {name}'**
  String progressRemoveTodo(String name);

  /// No description provided for @progressPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get progressPending;

  /// No description provided for @progressInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get progressInProgress;

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progressCompleted;

  /// No description provided for @progressMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move task up'**
  String get progressMoveUp;

  /// No description provided for @progressMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move task down'**
  String get progressMoveDown;

  /// No description provided for @progressRunTree.
  ///
  /// In en, this message translates to:
  /// **'Agent runs'**
  String get progressRunTree;

  /// No description provided for @progressNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs in this conversation yet'**
  String get progressNoRuns;

  /// No description provided for @progressRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get progressRunning;

  /// No description provided for @progressFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get progressFailed;

  /// No description provided for @progressUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get progressUnknown;

  /// No description provided for @progressHealthy.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get progressHealthy;

  /// No description provided for @progressBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get progressBlocked;

  /// No description provided for @progressLooping.
  ///
  /// In en, this message translates to:
  /// **'Looping'**
  String get progressLooping;

  /// No description provided for @progressStalled.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get progressStalled;

  /// No description provided for @progressDead.
  ///
  /// In en, this message translates to:
  /// **'Stopped unexpectedly'**
  String get progressDead;

  /// No description provided for @progressQuiet.
  ///
  /// In en, this message translates to:
  /// **'No output yet'**
  String get progressQuiet;

  /// No description provided for @progressCostReported.
  ///
  /// In en, this message translates to:
  /// **'Provider-reported charge'**
  String get progressCostReported;

  /// No description provided for @progressCostNotional.
  ///
  /// In en, this message translates to:
  /// **'Notional subscription list price; not a bill'**
  String get progressCostNotional;

  /// No description provided for @progressCostMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed cost sources'**
  String get progressCostMixed;

  /// No description provided for @progressCostEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get progressCostEstimated;

  /// No description provided for @progressDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String progressDurationSeconds(String seconds);

  /// No description provided for @progressRunDetails.
  ///
  /// In en, this message translates to:
  /// **'Model: {model} · Time: {duration} · Cost: {cost}'**
  String progressRunDetails(String model, String duration, String cost);

  /// No description provided for @progressStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started {time}'**
  String progressStartedAt(String time);

  /// No description provided for @progressLiveness.
  ///
  /// In en, this message translates to:
  /// **'Health: {state}'**
  String progressLiveness(String state);

  /// No description provided for @progressRunTokens.
  ///
  /// In en, this message translates to:
  /// **'Input: {input} · Output: {output} tokens'**
  String progressRunTokens(String input, String output);

  /// No description provided for @progressOutputPreviewLimited.
  ///
  /// In en, this message translates to:
  /// **'Only the first 6,000 characters of structured output are shown.'**
  String get progressOutputPreviewLimited;

  /// No description provided for @progressRetryOf.
  ///
  /// In en, this message translates to:
  /// **'Retry of run {runId}'**
  String progressRetryOf(String runId);

  /// No description provided for @progressContext.
  ///
  /// In en, this message translates to:
  /// **'Context and limits'**
  String get progressContext;

  /// No description provided for @progressNoAgent.
  ///
  /// In en, this message translates to:
  /// **'No agent to inspect'**
  String get progressNoAgent;

  /// No description provided for @progressContextReading.
  ///
  /// In en, this message translates to:
  /// **'{used} / {window} tokens'**
  String progressContextReading(String used, String window);

  /// No description provided for @progressMeasured.
  ///
  /// In en, this message translates to:
  /// **'Provider-reported context on the latest call'**
  String get progressMeasured;

  /// No description provided for @progressEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated from stored conversation and persistent context'**
  String get progressEstimated;

  /// No description provided for @progressContextUnknown.
  ///
  /// In en, this message translates to:
  /// **'Context usage not reported yet'**
  String get progressContextUnknown;

  /// No description provided for @progressContextPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of context window'**
  String progressContextPercent(String percent);

  /// No description provided for @progressMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Configured monthly agent limit: {amount}'**
  String progressMonthlyBudget(String amount);

  /// No description provided for @progressConversationTokens.
  ///
  /// In en, this message translates to:
  /// **'Stored live conversation: {tokens} estimated tokens'**
  String progressConversationTokens(String tokens);

  /// No description provided for @progressInspectionFor.
  ///
  /// In en, this message translates to:
  /// **'Persistent context for {agent} · {model}'**
  String progressInspectionFor(String agent, String model);

  /// No description provided for @progressContextSystem.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get progressContextSystem;

  /// No description provided for @progressContextRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get progressContextRules;

  /// No description provided for @progressContextSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get progressContextSkills;

  /// No description provided for @progressContextTools.
  ///
  /// In en, this message translates to:
  /// **'Tool definitions'**
  String get progressContextTools;

  /// No description provided for @progressContextMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP tools'**
  String get progressContextMcp;

  /// No description provided for @progressContextDeferred.
  ///
  /// In en, this message translates to:
  /// **'Deferred tools'**
  String get progressContextDeferred;

  /// No description provided for @progressContextSubagents.
  ///
  /// In en, this message translates to:
  /// **'Subagents'**
  String get progressContextSubagents;

  /// No description provided for @progressContextRunner.
  ///
  /// In en, this message translates to:
  /// **'External runner'**
  String get progressContextRunner;

  /// No description provided for @progressContextMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get progressContextMemory;

  /// No description provided for @progressContextHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get progressContextHistory;

  /// No description provided for @progressContextSegment.
  ///
  /// In en, this message translates to:
  /// **'{label} · {tokens} tokens'**
  String progressContextSegment(String label, String tokens);

  /// No description provided for @progressContextPart.
  ///
  /// In en, this message translates to:
  /// **'{title} · {tokens} tokens'**
  String progressContextPart(String title, String tokens);

  /// No description provided for @progressOutputs.
  ///
  /// In en, this message translates to:
  /// **'Recent outputs'**
  String get progressOutputs;

  /// No description provided for @progressNoOutputs.
  ///
  /// In en, this message translates to:
  /// **'No recent agent outputs'**
  String get progressNoOutputs;

  /// No description provided for @progressStructuredOutputsAbove.
  ///
  /// In en, this message translates to:
  /// **'Structured run outputs are shown in the agent runs above.'**
  String get progressStructuredOutputsAbove;

  /// No description provided for @progressRecentOutputsOnly.
  ///
  /// In en, this message translates to:
  /// **'Showing recent messages only. Open the conversation for older work.'**
  String get progressRecentOutputsOnly;

  /// No description provided for @progressPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get progressPlan;

  /// No description provided for @progressArtifact.
  ///
  /// In en, this message translates to:
  /// **'Artifact'**
  String get progressArtifact;

  /// No description provided for @progressResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get progressResult;

  /// No description provided for @progressHideArtifact.
  ///
  /// In en, this message translates to:
  /// **'Hide artifact'**
  String get progressHideArtifact;

  /// No description provided for @progressReadArtifact.
  ///
  /// In en, this message translates to:
  /// **'Read artifact'**
  String get progressReadArtifact;

  /// No description provided for @progressArtifactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Artifact no longer available'**
  String get progressArtifactUnavailable;

  /// No description provided for @progressArtifactPreviewLimited.
  ///
  /// In en, this message translates to:
  /// **'Showing a limited preview of this artifact.'**
  String get progressArtifactPreviewLimited;

  /// No description provided for @progressDiagramSource.
  ///
  /// In en, this message translates to:
  /// **'Diagram source'**
  String get progressDiagramSource;

  /// No description provided for @progressOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String progressOpenAttachment(String name);

  /// No description provided for @progressOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open plan'**
  String get progressOpenPlan;

  /// No description provided for @progressOpenDiff.
  ///
  /// In en, this message translates to:
  /// **'Review changed files: {label}'**
  String progressOpenDiff(String label);

  /// No description provided for @progressViewMessage.
  ///
  /// In en, this message translates to:
  /// **'View message'**
  String get progressViewMessage;

  /// No description provided for @pushTitle.
  ///
  /// In en, this message translates to:
  /// **'Background notifications'**
  String get pushTitle;

  /// No description provided for @pushIntro.
  ///
  /// In en, this message translates to:
  /// **'Get a private alert when something needs your attention, even when the app is closed. Details stay inside your encrypted connection.'**
  String get pushIntro;

  /// No description provided for @pushLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking notification settings…'**
  String get pushLoading;

  /// No description provided for @pushError.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications. Check your connection and try again.'**
  String get pushError;

  /// No description provided for @pushEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get pushEnable;

  /// No description provided for @pushDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off notifications'**
  String get pushDisable;

  /// No description provided for @pushQuiet.
  ///
  /// In en, this message translates to:
  /// **'Pause alerts on this device'**
  String get pushQuiet;

  /// No description provided for @pushCategories.
  ///
  /// In en, this message translates to:
  /// **'Notify me about'**
  String get pushCategories;

  /// No description provided for @pushCategoryAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get pushCategoryAgents;

  /// No description provided for @pushCategoryMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get pushCategoryMessages;

  /// No description provided for @pushCategoryPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get pushCategoryPullRequests;

  /// No description provided for @pushCategoryTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get pushCategoryTickets;

  /// No description provided for @pushCategoryCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get pushCategoryCalendar;

  /// No description provided for @pushCategoryMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get pushCategoryMachines;

  /// No description provided for @pushSecureOrigin.
  ///
  /// In en, this message translates to:
  /// **'Notifications require HTTPS.'**
  String get pushSecureOrigin;

  /// No description provided for @pushInstallIos.
  ///
  /// In en, this message translates to:
  /// **'On iPhone or iPad, add this app to the Home Screen and open it there to enable notifications.'**
  String get pushInstallIos;

  /// No description provided for @pushUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser does not support background notifications.'**
  String get pushUnsupported;

  /// No description provided for @pushDenied.
  ///
  /// In en, this message translates to:
  /// **'Your browser reports notifications blocked. Check this site\'s permission and your browser or device notification settings, then refresh.'**
  String get pushDenied;

  /// No description provided for @pushOsHint.
  ///
  /// In en, this message translates to:
  /// **'Your browser also needs permission to show notifications in your device\'s system settings.'**
  String get pushOsHint;

  /// No description provided for @pushServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your browser\'s push service refused the subscription. Some browsers, such as Brave, turn it off by default: look for a push messaging option in the browser\'s privacy settings, then try again.'**
  String get pushServiceUnavailable;

  /// No description provided for @pushWorkerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The notification service could not start in this browser. Reload the page and try again.'**
  String get pushWorkerUnavailable;

  /// No description provided for @pushResubscribe.
  ///
  /// In en, this message translates to:
  /// **'Reconnect notifications'**
  String get pushResubscribe;

  /// No description provided for @pushStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on for this device.'**
  String get pushStatusEnabled;

  /// No description provided for @pushStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this device.'**
  String get pushStatusDisabled;

  /// Phone credential-management screen heading.
  ///
  /// In en, this message translates to:
  /// **'Connections & credentials'**
  String get credentialsTitle;

  /// No description provided for @credentialsIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect the accounts your runs and integrations use. Secrets are stored on your server, not this phone.'**
  String get credentialsIntro;

  /// No description provided for @credentialsModelProviders.
  ///
  /// In en, this message translates to:
  /// **'Model providers'**
  String get credentialsModelProviders;

  /// No description provided for @credentialsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the server owner can add, sign in to, or remove model-provider credentials. These keys are shared across workspaces.'**
  String get credentialsOwnerOnly;

  /// No description provided for @credentialsContactOwner.
  ///
  /// In en, this message translates to:
  /// **'Ask the server owner to connect the provider needed by your blocked run.'**
  String get credentialsContactOwner;

  /// No description provided for @credentialsClaudeCode.
  ///
  /// In en, this message translates to:
  /// **'Claude Code'**
  String get credentialsClaudeCode;

  /// No description provided for @credentialsClaudeHostOnly.
  ///
  /// In en, this message translates to:
  /// **'Claude Code signs in through the CLI on the host. Ask the server owner to complete or renew the account login on the host terminal; this phone cannot run it.'**
  String get credentialsClaudeHostOnly;

  /// No description provided for @credentialsYourForgeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Your forge accounts'**
  String get credentialsYourForgeAccounts;

  /// No description provided for @credentialsYourTicketingAccount.
  ///
  /// In en, this message translates to:
  /// **'Your ticketing account'**
  String get credentialsYourTicketingAccount;

  /// No description provided for @credentialsLocalTicketsNoLogin.
  ///
  /// In en, this message translates to:
  /// **'Local tickets need no login. Connect Linear here if your workspace uses Linear.'**
  String get credentialsLocalTicketsNoLogin;

  /// No description provided for @credentialsMembershipRequired.
  ///
  /// In en, this message translates to:
  /// **'Join a workspace to manage your forge or ticketing credentials. Ask a workspace administrator for access.'**
  String get credentialsMembershipRequired;

  /// No description provided for @credentialsSwitchWorkspace.
  ///
  /// In en, this message translates to:
  /// **'This link points to another workspace. Switch to that workspace before changing credentials.'**
  String get credentialsSwitchWorkspace;

  /// No description provided for @credentialsReturnToInbox.
  ///
  /// In en, this message translates to:
  /// **'Return to Inbox to retry a blocked run once its credential is connected. The host also checks parked runs automatically.'**
  String get credentialsReturnToInbox;

  /// No description provided for @credentialsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load connections. Check the server link and retry.'**
  String get credentialsLoadFailed;

  /// No description provided for @credentialsOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change this connection. Check the server link, your access, and the credential, then try again.'**
  String get credentialsOperationFailed;

  /// No description provided for @credentialsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get credentialsConnected;

  /// No description provided for @credentialsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get credentialsNotConnected;

  /// No description provided for @credentialsSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}'**
  String credentialsSignedInAs(String username);

  /// No description provided for @credentialsAccount.
  ///
  /// In en, this message translates to:
  /// **'Connected account'**
  String get credentialsAccount;

  /// No description provided for @credentialsStoredKey.
  ///
  /// In en, this message translates to:
  /// **'Stored key'**
  String get credentialsStoredKey;

  /// No description provided for @credentialsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get credentialsActive;

  /// No description provided for @credentialsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get credentialsRemove;

  /// No description provided for @credentialsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove your saved credential? You may need to sign in again.'**
  String get credentialsRemoveConfirm;

  /// No description provided for @credentialsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get credentialsApiKey;

  /// No description provided for @credentialsApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a provider API key'**
  String get credentialsApiKeyHint;

  /// No description provided for @credentialsBrowserLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with browser'**
  String get credentialsBrowserLogin;

  /// No description provided for @credentialsSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get credentialsSignInAgain;

  /// No description provided for @credentialsWaitingForLogin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for authorization in your browser…'**
  String get credentialsWaitingForLogin;

  /// Label of the field where a person types the code the browser showed after they confirmed a sign-in (both Control Center Connect and this server's own sign-in)
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get credentialsConnectCodePrompt;

  /// Shown when the typed sign-in confirmation code is not 8 letters and digits
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a sign-in code. Codes have 8 letters and digits.'**
  String get credentialsConnectCodeMalformed;

  /// Shown when the server refuses a typed sign-in confirmation code
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match this sign-in. Check it and try again.'**
  String get credentialsSignInInvalidCode;

  /// Shown when too many wrong sign-in confirmation codes ended the attempt
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Start the sign-in again.'**
  String get credentialsSignInTooManyCodes;

  /// Shown when the sign-in provider, Connect or the server is not answering or is rate limiting
  ///
  /// In en, this message translates to:
  /// **'The sign-in service isn\'t responding right now. Wait a minute, then try again.'**
  String get credentialsSignInRetryLater;

  /// Shown when the provider refused the sign-in or granted the wrong permissions
  ///
  /// In en, this message translates to:
  /// **'The sign-in was refused. Start it again and approve every requested permission.'**
  String get credentialsSignInRefused;

  /// Shown when the sign-in worked but the server could not store the grant
  ///
  /// In en, this message translates to:
  /// **'The sign-in worked, but the server couldn\'t save it. Try again.'**
  String get credentialsSignInNotSaved;

  /// Shown on a GitHub or Linear card when the server has neither its own app nor Connect for that sign-in
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in isn\'t set up on this server yet.'**
  String credentialsSignInUnavailable(String provider);

  /// Shown when the server's own-app sign-in callback is localhost or private, so a phone cannot finish the sign-in
  ///
  /// In en, this message translates to:
  /// **'This server\'s sign-in callback isn\'t reachable securely from a phone. Sign in from the desktop app, or ask the server owner to set up a public HTTPS address.'**
  String get credentialsSignInPhoneUnreachable;

  /// No description provided for @credentialsLoginTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The login expired. Start a new sign-in attempt.'**
  String get credentialsLoginTimedOut;

  /// No description provided for @credentialsCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get credentialsCopyCode;

  /// No description provided for @credentialsDeviceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm this code on the provider\'s page. Keep this screen open while the server completes sign-in.'**
  String get credentialsDeviceCodeHint;

  /// No description provided for @credentialsPasteRedirect.
  ///
  /// In en, this message translates to:
  /// **'Authorization code or redirect URL'**
  String get credentialsPasteRedirect;

  /// No description provided for @credentialsPasteRedirectHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the code or full redirect URL from the provider'**
  String get credentialsPasteRedirectHint;

  /// No description provided for @credentialsCompleteLogin.
  ///
  /// In en, this message translates to:
  /// **'Complete sign-in'**
  String get credentialsCompleteLogin;

  /// No description provided for @credentialsUpdateToken.
  ///
  /// In en, this message translates to:
  /// **'Update token'**
  String get credentialsUpdateToken;

  /// No description provided for @credentialsAddToken.
  ///
  /// In en, this message translates to:
  /// **'Add token'**
  String get credentialsAddToken;

  /// No description provided for @credentialsPersonalToken.
  ///
  /// In en, this message translates to:
  /// **'Personal access token'**
  String get credentialsPersonalToken;

  /// No description provided for @credentialsPersonalTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a personal access token'**
  String get credentialsPersonalTokenHint;

  /// No description provided for @credentialsStopWatching.
  ///
  /// In en, this message translates to:
  /// **'Stop watching'**
  String get credentialsStopWatching;

  /// Title of the notice in a turn that failed because its Claude Code account stopped authenticating
  ///
  /// In en, this message translates to:
  /// **'Claude Code sign-in expired'**
  String get transcriptClaudeSignInExpiredTitle;

  /// Body of the notice in a turn that failed because its Claude Code account stopped authenticating
  ///
  /// In en, this message translates to:
  /// **'The run stopped because its account no longer authenticates. Sign in again, then retry the turn.'**
  String get transcriptClaudeSignInExpiredBody;

  /// Title of the notice in a turn that failed because its model provider credential stopped working
  ///
  /// In en, this message translates to:
  /// **'Provider sign-in expired'**
  String get transcriptSignInExpiredTitle;

  /// Body of the notice in a turn that failed because its model provider credential stopped working
  ///
  /// In en, this message translates to:
  /// **'The run stopped because its provider credential no longer works. Reconnect it in Settings → Providers, then retry the turn.'**
  String get transcriptSignInExpiredBody;

  /// Permission class: running commands on the host outside any sandbox, at an agent's request
  ///
  /// In en, this message translates to:
  /// **'Run commands on the host'**
  String get permissionHostExecution;

  /// Connection status: the grant expired or was revoked
  ///
  /// In en, this message translates to:
  /// **'Your {provider} sign-in has lapsed. Sign in again.'**
  String credentialsSignInLapsed(String provider);

  /// Connection status: the grant is parked because the workspace's sign-in service changed
  ///
  /// In en, this message translates to:
  /// **'Paused: this workspace\'s sign-in service changed. It works again once the service is back.'**
  String get credentialsSignInPaused;

  /// Connection status: renewing the grant failed for now; it retries on its own
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {provider} right now. Retrying.'**
  String credentialsProviderUnreachable(String provider);

  /// Credential scope: applies to the current workspace only
  ///
  /// In en, this message translates to:
  /// **'This workspace only'**
  String get credentialsScopeWorkspace;

  /// Credential scope: applies to every workspace on the server
  ///
  /// In en, this message translates to:
  /// **'All workspaces'**
  String get credentialsScopeAllWorkspaces;

  /// Confirmation before removing a credential kept for this workspace only
  ///
  /// In en, this message translates to:
  /// **'Remove your saved credential from this workspace? Other workspaces keep theirs.'**
  String get credentialsRemoveConfirmWorkspace;

  /// Confirmation before removing a credential shared by all workspaces
  ///
  /// In en, this message translates to:
  /// **'Remove your saved credential from every workspace that shares it?'**
  String get credentialsRemoveConfirmAllWorkspaces;

  /// Sign-in failure: the server no longer knows the attempt
  ///
  /// In en, this message translates to:
  /// **'The server restarted. Start the sign-in again.'**
  String get credentialsSignInServerRestarted;

  /// Notice for admins: the GitHub App is not installed on the owner of these repositories
  ///
  /// In en, this message translates to:
  /// **'Install the GitHub App on {owner} so automation can reach {names}. Tap to open GitHub.'**
  String repoAccessInstallApp(String owner, String names);

  /// Notice for members: the GitHub App is not installed on the owner of these repositories
  ///
  /// In en, this message translates to:
  /// **'The GitHub App isn\'t installed on {owner}, so automation can\'t reach {names}. Ask a workspace admin to install it.'**
  String repoAccessAskAdminInstall(String owner, String names);

  /// Notice for admins: these repositories are not selected in the GitHub App installation
  ///
  /// In en, this message translates to:
  /// **'Add {names} to the GitHub App\'s repositories. Tap to open GitHub.'**
  String repoAccessAddToApp(String names);

  /// Notice for members: these repositories are not selected in the GitHub App installation
  ///
  /// In en, this message translates to:
  /// **'The GitHub App can\'t see {names} yet. Ask a workspace admin to add them to its repositories.'**
  String repoAccessAskAdminAdd(String names);

  /// Notice: the GitHub App installation covering these repositories is suspended
  ///
  /// In en, this message translates to:
  /// **'GitHub App installation suspended. Automation for {names} is paused until an owner of the account resumes the installation on GitHub.'**
  String repoAccessSuspended(String names);

  /// Notice: the workspace's accountable person lost access to these repositories
  ///
  /// In en, this message translates to:
  /// **'The person accountable for this workspace\'s automation can no longer see {names}, so nothing runs there on their behalf.'**
  String repoAccessOwnerCannotSee(String names);

  /// Notice: the workspace's accountable person is not signed in to the forge
  ///
  /// In en, this message translates to:
  /// **'The person accountable for this workspace\'s automation isn\'t signed in to the forge, so automation for {names} waits until they sign in.'**
  String repoAccessOwnerNotSignedIn(String names);

  /// Muted notice: an access check got no answer and is retried automatically
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check access to {names}. Retrying.'**
  String repoAccessRetrying(String names);

  /// Notice: repositories hidden because the person is not signed in to that forge
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sign in to {forge} to see pull requests from 1 more repository} other{Sign in to {forge} to see pull requests from {count} more repositories}}'**
  String hiddenReposSignIn(int count, String forge);

  /// Notice: repositories hidden because the person's own forge account cannot read them
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repository is hidden because your {forge} account can\'t see it} other{{count} repositories are hidden because your {forge} account can\'t see them}}'**
  String hiddenReposNoForgeAccess(int count, String forge);

  /// Notice: repositories hidden because the person holds no grant on them in this workspace
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repository is hidden because you don\'t have access to it in this workspace} other{{count} repositories are hidden because you don\'t have access to them in this workspace}}'**
  String hiddenReposNoGrant(int count);

  /// Quiet notice while access to some repositories is still being checked
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checking your access to 1 more repository…} other{Checking your access to {count} more repositories…}}'**
  String hiddenReposChecking(int count);

  /// Label of the email field next to a Bitbucket API token
  ///
  /// In en, this message translates to:
  /// **'Atlassian account email'**
  String get credentialsAtlassianEmail;

  /// Error when the Atlassian account email for a Bitbucket token is missing or malformed
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of your Atlassian account.'**
  String get credentialsAtlassianEmailInvalid;

  /// Label of the Bitbucket API token field
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get credentialsBitbucketApiToken;

  /// Notice: GitLab/Bitbucket repositories whose background work is paused for lack of an automation token
  ///
  /// In en, this message translates to:
  /// **'No automation token can read {names}, so background work there is paused. An admin can add one in Settings → Repositories.'**
  String repoAccessAutomationTokenMissing(String names);

  /// Shown while a browser sign-in is open: the browser page (Control Center Connect's or this server's own) first asks to confirm, then shows a code to type in the field below
  ///
  /// In en, this message translates to:
  /// **'Confirm in your browser, then enter the code it shows.'**
  String get credentialsSignInConfirmInBrowser;

  /// Sign-in failure: the provider account is already held by another person on this server; one account acts for one person only
  ///
  /// In en, this message translates to:
  /// **'This account is already connected to another person on this server. Sign in with a different account.'**
  String get credentialsSignInAccountAlreadyBound;

  /// Token form error: the server could not ask the forge about the pasted token
  ///
  /// In en, this message translates to:
  /// **'{provider} could not be reached to check this token. Try again in a moment.'**
  String credentialsTokenUnreachable(String provider);

  /// Token form error: the forge refused the pasted token
  ///
  /// In en, this message translates to:
  /// **'{provider} does not accept this token. Check that you copied all of it and that it has not been revoked.'**
  String credentialsTokenRejected(String provider);

  /// Token form error: the pasted token belongs to a bot, project, group or workspace instead of the person
  ///
  /// In en, this message translates to:
  /// **'This is not a personal token. Paste a personal access token from your own {provider} account, not a project, group, workspace or bot token.'**
  String credentialsTokenWrongKind(String provider);

  /// Token form error: the pasted token lacks a permission. {scope} is the forge's own scope name; keep it as is
  ///
  /// In en, this message translates to:
  /// **'This token is missing the {scope} scope, which reviewing and commenting need. Create one that has it.'**
  String credentialsTokenNarrowScope(String scope);

  /// Token form error: the pasted token is already expired
  ///
  /// In en, this message translates to:
  /// **'This token has expired. Create a new one and paste it here.'**
  String get credentialsTokenExpired;

  /// Sign-in failure: the sign-in service is limiting requests. Must not ask the person to sign in again
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Wait a bit, then try again.'**
  String get credentialsSignInRateLimited;

  /// Sign-in failure: the person cancelled on the browser page, or declined at the provider
  ///
  /// In en, this message translates to:
  /// **'The sign-in was cancelled or declined. Start it again when you\'re ready.'**
  String get credentialsSignInCancelled;

  /// Sign-in failure: the server no longer knows this attempt
  ///
  /// In en, this message translates to:
  /// **'This sign-in is no longer open: it was cancelled, used or replaced. Start it again.'**
  String get credentialsSignInNoLongerOpen;

  /// Under noWorkspacesYet on the workspace switcher, when the signed-in person is in no workspace. The phone cannot create workspaces; 'the server owner' = the person who runs this Control Center server.
  ///
  /// In en, this message translates to:
  /// **'A workspace admin has to invite you, or the server owner can create a workspace for you.'**
  String get noWorkspacesYetHint;

  /// Pull requests notice for a workspace admin: the linked owner/name now names a different repository on the forge. The phone cannot edit links
  ///
  /// In en, this message translates to:
  /// **'{repos} now points to a different repository on {forge}. Relink it from the desktop or web app to keep using it.'**
  String repoAccessReplaced(String repos, String forge);

  /// Same notice for a member who is not an admin
  ///
  /// In en, this message translates to:
  /// **'{repos} now points to a different repository on {forge}. A workspace admin has to relink it before it can be used again.'**
  String repoAccessAskAdminRelink(String repos, String forge);

  /// Title of the notice in an agent turn when the server refused to start the run because it has no sandbox and the person is not the server owner. Guidance, not an error
  ///
  /// In en, this message translates to:
  /// **'Agents need a sandbox on this server'**
  String get runSandboxUnavailableTitle;

  /// Body of that notice. 'Owner' = the person who runs this Control Center server; 'sandbox' = the isolation agents run in
  ///
  /// In en, this message translates to:
  /// **'This server has no sandbox, so only its owner can run agents here. The owner can install the sandbox or turn sandboxing off for everyone.'**
  String get runSandboxUnavailable;

  /// Section label above the list of tool calls a code mode script made, inside the script's transcript row
  ///
  /// In en, this message translates to:
  /// **'Tool calls'**
  String get scriptToolCalls;

  /// How many tool calls a code mode script made, shown on its collapsed transcript row
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 call} other{{count} calls}}'**
  String scriptCallCount(int count);

  /// How many of a script's tool calls are still running. Joined with other counts by a middle dot
  ///
  /// In en, this message translates to:
  /// **'{count} running'**
  String scriptCallsRunning(int count);

  /// How many of a script's tool calls completed successfully. Short status word
  ///
  /// In en, this message translates to:
  /// **'{count} ok'**
  String scriptCallsOk(int count);

  /// How many of a script's tool calls ran and failed
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String scriptCallsFailed(int count);

  /// How many of a script's tool calls were refused before running (by a person, a policy or a hook)
  ///
  /// In en, this message translates to:
  /// **'{count} denied'**
  String scriptCallsDenied(int count);

  /// How many of a script's tool calls were stopped before they produced a result
  ///
  /// In en, this message translates to:
  /// **'{count} cancelled'**
  String scriptCallsCancelled(int count);

  /// How many of a script's tool calls have not been reached yet while the script runs. Joined with other counts by a middle dot
  ///
  /// In en, this message translates to:
  /// **'{count} queued'**
  String scriptCallsQueued(int count);

  /// How many of a script's tool calls were not reached and will not be (another branch was taken, or the script ended). Joined with other counts by a middle dot
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String scriptCallsSkipped(int count);

  /// Status word on a tool call a running script has not reached yet, shown where the call's duration would be
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get scriptStepQueued;

  /// Status word on a tool call, or a branch of a script, that was not reached and will not be (another branch was taken, or the script ended)
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get scriptStepSkipped;

  /// Header of a group of tool calls a script makes inside a loop (for, while). Followed by the loop's code
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get scriptGroupLoop;

  /// Header of a group of tool calls a script makes once per item of a list (array.map, forEach). Followed by the code that names the list
  ///
  /// In en, this message translates to:
  /// **'For each'**
  String get scriptGroupEach;

  /// Header of a group of tool calls a script runs at the same time (Promise.all). Followed by the code
  ///
  /// In en, this message translates to:
  /// **'In parallel'**
  String get scriptGroupParallel;

  /// Header of a group of tool calls a script makes inside a function it defined. Followed by the function's name
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get scriptGroupFunction;

  /// Button inside a long group of a script's tool calls that shows the calls hidden from the middle of the group
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 more call} other{Show {count} more calls}}'**
  String scriptCallsHidden(int count);

  /// Caption above tool calls a script made that could not be matched to a place in its code, listed after the script's structure
  ///
  /// In en, this message translates to:
  /// **'Calls not placed in the script'**
  String get scriptCallsUnplaced;

  /// Stands in for the tool's name on a not-yet-run call whose tool the script chooses while it runs
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get scriptToolComputed;

  /// Screen reader label of one step of a script: what it is (a tool name, a loop, a branch) and its state (queued, skipped, a count of calls)
  ///
  /// In en, this message translates to:
  /// **'{subject}, {state}'**
  String scriptStepSemantics(String subject, String state);

  /// Label of the collapsible section that shows the source code of a script the agent ran
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get scriptSourceLabel;

  /// Length of a script's source code, beside its collapsed section
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String scriptSourceLines(int count);

  /// Status tag: the agent's script is still running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get scriptStateRunning;

  /// Status tag: the agent's script ran to the end
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get scriptStateCompleted;

  /// Status tag: the agent's script threw an error
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get scriptStateFailed;

  /// Status tag: the agent's script hit its time limit
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get scriptStateTimedOut;

  /// Status tag: the agent's script was stopped before it finished
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get scriptStateCancelled;

  /// Status tag: the agent's script hit its memory limit
  ///
  /// In en, this message translates to:
  /// **'Out of memory'**
  String get scriptStateMemoryExceeded;

  /// Status tag: the agent's script was stopped because it wrote more output than allowed
  ///
  /// In en, this message translates to:
  /// **'Too much output'**
  String get scriptStateOutputExceeded;

  /// Status tag: the isolated environment the script runs in failed. 'Sandbox' = the isolation scripts run in
  ///
  /// In en, this message translates to:
  /// **'Sandbox error'**
  String get scriptStateSandboxError;

  /// Status tag: the server did not run the agent's script at all
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get scriptStateRefused;

  /// Quiet line on an approval request or a question: the request came from a tool call inside a script the agent wrote, not from the agent directly
  ///
  /// In en, this message translates to:
  /// **'From a script the agent is running'**
  String get scriptOriginLine;

  /// Section label on the phone's settings: code mode lets an agent write a short script that calls its tools
  ///
  /// In en, this message translates to:
  /// **'Code mode'**
  String get codeModeTitle;

  /// Tag: this server can run agents' scripts
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get codeModeAvailable;

  /// Tag: this server cannot run agents' scripts
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get codeModeUnavailable;

  /// Note when the server cannot run scripts. {reason} is the server's own explanation, in English
  ///
  /// In en, this message translates to:
  /// **'This server can\'t run scripts, so agents here call their tools one at a time. The server says: {reason}'**
  String codeModeUnavailableNote(String reason);

  /// Stands in for the server's explanation when it gave none; ends the sentence of codeModeUnavailableNote
  ///
  /// In en, this message translates to:
  /// **'no reason was given.'**
  String get codeModeNoReason;

  /// Lead-in before a raw machine kind in code style, when the phone does not know a reason the server sent
  ///
  /// In en, this message translates to:
  /// **'For a reason this version doesn\'t name:'**
  String get workKindUnknown;

  /// Lead-in before a raw refusal kind in code style, when the phone does not know why the server refused an action
  ///
  /// In en, this message translates to:
  /// **'The server refused this:'**
  String get workRefusalUnknown;

  /// Shown when an action on a goal, wake or schedule failed for a reason that is not a refusal. {error} is the technical error text, in English
  ///
  /// In en, this message translates to:
  /// **'That did not work: {error}'**
  String workActionFailed(String error);

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Held because a person stopped the run.'**
  String get wakeKindStopped;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Delivery failed three times.'**
  String get wakeKindAttempts;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent no longer exists.'**
  String get wakeKindAgentDeleted;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent is retired.'**
  String get wakeKindAgentNotDispatchable;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent is paused.'**
  String get wakeKindAgentPaused;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The person it acts for left the workspace.'**
  String get wakeKindPersonRemoved;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'A budget blocks a run.'**
  String get wakeKindBudgetBlocked;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'A person has taken over the worktree.'**
  String get wakeKindTakeOver;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'This conversation started 30 runs from wakes in the last hour.'**
  String get wakeKindRateCapConversation;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'This workspace started 300 runs from wakes in the last hour.'**
  String get wakeKindRateCapWorkspace;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent\'s live run here takes no input.'**
  String get wakeKindLiveRunNoInput;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent\'s live run here runs differently, so this starts its own run after it.'**
  String get wakeKindLiveRunOtherOptions;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The agent\'s live run here acts for someone else, so this starts its own run after it.'**
  String get wakeKindLiveRunOtherPerson;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The run could not start.'**
  String get wakeKindDispatchRefused;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'No sandbox is available for a read-only run.'**
  String get wakeKindSandboxUnavailable;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'This agent\'s backend cannot keep a run read-only.'**
  String get wakeKindReadOnlyUnavailable;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'A server restart stopped the run.'**
  String get wakeKindServerStopped;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The server restarted during a person\'s run.'**
  String get wakeKindServerRestarted;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'A check before delivery failed.'**
  String get wakeKindGuardFailed;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Waiting for the provider\'s usage limit to reset.'**
  String get wakeKindLimit;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Waiting for the run at the usage limit to end.'**
  String get wakeKindLimitRunLive;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Missed while the server was down.'**
  String get wakeKindWakeMissed;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its pipeline run ended.'**
  String get wakeKindPipelineRunEnded;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its goal ended.'**
  String get wakeKindGoalEnded;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its goal used its budget.'**
  String get wakeKindGoalBudgetExhausted;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The goal changed since this review was asked for.'**
  String get wakeKindGoalReviewStale;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its goal is paused.'**
  String get wakeKindGoalPaused;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its goal is on hold.'**
  String get wakeKindGoalHeld;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its goal was stopped.'**
  String get wakeKindGoalStopped;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'The question it answers was already settled.'**
  String get wakeKindAskSettled;

  /// Why a wake waits, is held or was not delivered, shown under the wake in a conversation's progress view. A "wake" is something that will start or continue an agent's work later
  ///
  /// In en, this message translates to:
  /// **'Its schedule ended.'**
  String get wakeKindRuleEnded;

  /// Shown when the server refused delivering, resuming or cancelling a wake
  ///
  /// In en, this message translates to:
  /// **'This wake acts for another person. Only they can deliver or resume it.'**
  String get wakeRefusalNotYours;

  /// Shown when the server refused delivering, resuming or cancelling a wake
  ///
  /// In en, this message translates to:
  /// **'This wake has already settled.'**
  String get wakeRefusalSettled;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'This agent already has an active goal.'**
  String get goalRefusalAlreadyActive;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'This goal is not waiting for review.'**
  String get goalRefusalNotInReview;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'The goal\'s evidence is incomplete.'**
  String get goalRefusalEvidenceIncomplete;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'A claim that it is done is still being checked.'**
  String get goalRefusalClaimPending;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'This goal has no segment running.'**
  String get goalRefusalNotActiveSegment;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'Only the person who started this goal can do that.'**
  String get goalRefusalNotYours;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'Pause the goal first.'**
  String get goalRefusalNotPaused;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'The goal\'s contract can\'t be read.'**
  String get goalRefusalContractInvalid;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'No agent has that name.'**
  String get goalRefusalCheckerUnknown;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'More than one agent has that name.'**
  String get goalRefusalCheckerAmbiguous;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'The checker must be another agent than the one doing the work.'**
  String get goalRefusalCheckerIsGoalAgent;

  /// Shown when the server refused an action on a goal (a long-running task an agent pursues until it is verified done)
  ///
  /// In en, this message translates to:
  /// **'This goal can\'t be read:'**
  String get goalRefusalCommandInvalid;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'The interval is too short. Pick at least one minute.'**
  String get wakeRuleRefusalIntervalTooShort;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'That time is too soon. Pick a later one.'**
  String get wakeRuleRefusalTooSoon;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'This chain of wakes has used its runs or its time.'**
  String get wakeRuleRefusalLineageEnded;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'You can\'t read what this would watch.'**
  String get wakeRuleRefusalWatchTargetUnreadable;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'Give it an end date or a number of runs.'**
  String get wakeRuleRefusalExpiryRequired;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'This conversation or agent already has as many schedules as it may.'**
  String get wakeRuleRefusalLimitReached;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'The time can\'t be read.'**
  String get wakeRuleRefusalInvalidWhen;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'The note is too long.'**
  String get wakeRuleRefusalNoteTooLong;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'The end is too far away.'**
  String get wakeRuleRefusalExpiryTooLong;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'A run, day or budget limit is out of range.'**
  String get wakeRuleRefusalLimitOutOfRange;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'Only a loop can pick its own next time.'**
  String get wakeRuleRefusalNextOutsideLoop;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'That can\'t be watched.'**
  String get wakeRuleRefusalWatchRefused;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'That schedule has already ended.'**
  String get wakeRuleRefusalRuleEnded;

  /// Shown when the server refused creating or changing a schedule (a prompt an agent runs again and again)
  ///
  /// In en, this message translates to:
  /// **'That schedule belongs to someone else.'**
  String get wakeRuleRefusalNotYours;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'It ran its one time.'**
  String get wakeRuleEndFired;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'It reached its end date.'**
  String get wakeRuleEndExpired;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'It used its runs.'**
  String get wakeRuleEndRunCap;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'It reached its cost cap.'**
  String get wakeRuleEndCostCap;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'Its goal ended.'**
  String get wakeRuleEndGoalEnded;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'It was cancelled.'**
  String get wakeRuleEndCancelled;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'Its person left the workspace.'**
  String get wakeRuleEndMemberRemoved;

  /// Why a schedule ended, on the schedules list and in a notification
  ///
  /// In en, this message translates to:
  /// **'Its stored settings could not be read.'**
  String get wakeRuleEndInvalidRow;

  /// What a running goal is doing. A goal runs in segments (one agent run each). {segment} is the current segment number
  ///
  /// In en, this message translates to:
  /// **'Working on segment {segment}. Nobody needs to act.'**
  String goalHoldWorking(int segment);

  /// A goal waits for a reply, a wake or a watched event, and nobody needs to act
  ///
  /// In en, this message translates to:
  /// **'Waiting for work it is owed. It continues by itself.'**
  String get goalHoldWaiting;

  /// A goal waits, and will continue by itself. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Waiting for work it is owed. It continues by itself at {time} at the latest.'**
  String goalHoldWaitingUntil(String time);

  /// A goal claimed completion and is being verified; nobody needs to act
  ///
  /// In en, this message translates to:
  /// **'It says it is done. The server runs its checks, then a reviewer decides.'**
  String get goalHoldVerifying;

  /// A goal waits for an AI provider usage limit to reset
  ///
  /// In en, this message translates to:
  /// **'Paused at the provider\'s usage limit. It resumes by itself after the reset.'**
  String get goalHoldLimit;

  /// A goal waits for an AI provider usage limit to reset. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Paused at the provider\'s usage limit. It resumes by itself at {time}.'**
  String goalHoldLimitUntil(String time);

  /// A goal waits for a person to answer a question or an approval in its conversation
  ///
  /// In en, this message translates to:
  /// **'Waiting for a person to answer in the conversation. It continues once someone answers.'**
  String get goalHoldPerson;

  /// A person paused the goal
  ///
  /// In en, this message translates to:
  /// **'Paused by a person. It stays paused until someone resumes it.'**
  String get goalHoldByPerson;

  /// A goal stopped and a person must decide what happens
  ///
  /// In en, this message translates to:
  /// **'Waiting for review: it cannot go on by itself. Approve it as done, resume it or cancel it.'**
  String get goalHoldNeedsReview;

  /// A goal spent its whole cost cap
  ///
  /// In en, this message translates to:
  /// **'It used its budget. Raise the budget to let it continue.'**
  String get goalHoldBudget;

  /// How often a goal has paused at a provider usage limit, against the most it may. Both are numbers
  ///
  /// In en, this message translates to:
  /// **'Usage limit pauses: {count} of {max}'**
  String goalHoldLimitParks(int count, int max);

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'No progress in its last segments.'**
  String get goalHoldDetailStalled;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'It waited 24 hours on the same work without progress.'**
  String get goalHoldDetailStalledWaiting;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'The last check failed.'**
  String get goalHoldDetailVerificationFailed;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'The checker couldn\'t tell whether it is done.'**
  String get goalHoldDetailCannotVerify;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'No sandbox is available to run its checks.'**
  String get goalHoldDetailSandboxUnavailable;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'Its checker agent is unavailable. Pick another checker, then resume.'**
  String get goalHoldDetailCheckerUnavailable;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'This check can\'t run:'**
  String get goalHoldDetailCheckBroken;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'Its wake was not delivered.'**
  String get goalHoldDetailWakeSkipped;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'Its claim that it is done waits for a check.'**
  String get goalHoldDetailClaimPending;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'A question or approval request to a person went unanswered.'**
  String get goalHoldDetailUnanswered;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'It hit usage limits too often. Look it over, then resume.'**
  String get goalHoldDetailLimitParks;

  /// Detail under a goal's hold sentence: why the goal is held. Some are followed by a command or a machine kind in code style
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer in the conversation.'**
  String get goalHoldDetailInput;

  /// How many segments (agent runs) a goal used of its cap
  ///
  /// In en, this message translates to:
  /// **'Segment {run} of {max}'**
  String goalSegments(int run, int max);

  /// How many segments (agent runs) a goal used; it has no cap
  ///
  /// In en, this message translates to:
  /// **'Segment {run}, no cap'**
  String goalSegmentsNoCap(int run);

  /// Money a goal or schedule spent against its cost cap. Both are formatted amounts
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {cap}'**
  String goalMoney(String spent, String cap);

  /// When a goal must be done by. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Deadline {time}'**
  String goalDeadline(String time);

  /// Shown when a pipeline started this goal
  ///
  /// In en, this message translates to:
  /// **'A pipeline step pursues this goal.'**
  String get goalPipelineStep;

  /// Heading above the text the goal's agent last wrote about it (shown as plain text)
  ///
  /// In en, this message translates to:
  /// **'Last summary'**
  String get goalSummaryHeading;

  /// Heading above the list of criteria that make a goal done
  ///
  /// In en, this message translates to:
  /// **'Done means'**
  String get goalDoneMeans;

  /// Heading above the commands the server runs to check whether a goal is done
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get goalChecks;

  /// Heading above what the goal's agent must not change
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get goalBoundaries;

  /// Heading above the conditions on which the agent stops and asks a person
  ///
  /// In en, this message translates to:
  /// **'Stop and ask when'**
  String get goalStopWhen;

  /// Shown when a goal has no check commands
  ///
  /// In en, this message translates to:
  /// **'No machine check. A reviewer judges from what it can read.'**
  String get goalNoMachineCheck;

  /// Label before a check that is a named task of the environment rather than a command
  ///
  /// In en, this message translates to:
  /// **'Environment task'**
  String get goalCheckEnvironment;

  /// Heading above the results of the last verification. {round} is a number, {time} a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Last check, round {round}, {time}'**
  String goalLastCheck(int round, String time);

  /// Heading above the agent's own words about why the goal is done (shown as quoted text)
  ///
  /// In en, this message translates to:
  /// **'What it claimed'**
  String get goalClaim;

  /// A check command passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get goalCheckPassed;

  /// A check command failed. {code} is its exit code
  ///
  /// In en, this message translates to:
  /// **'Failed, exit {code}'**
  String goalCheckFailed(int code);

  /// A check command ran out of time
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get goalCheckTimedOut;

  /// A check was not run again because nothing changed since it last passed
  ///
  /// In en, this message translates to:
  /// **'Not rerun: nothing changed'**
  String get goalCheckNotRerun;

  /// A check command cannot run at all
  ///
  /// In en, this message translates to:
  /// **'Cannot run'**
  String get goalCheckBroken;

  /// The reviewer found this criterion met
  ///
  /// In en, this message translates to:
  /// **'Met'**
  String get goalCriterionMet;

  /// The reviewer found this criterion not met
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get goalCriterionUnmet;

  /// The reviewer could not tell whether this criterion is met
  ///
  /// In en, this message translates to:
  /// **'Can\'t tell'**
  String get goalCriterionCannotTell;

  /// The reviewer decided the goal is done
  ///
  /// In en, this message translates to:
  /// **'Verdict: done'**
  String get goalVerdictPass;

  /// The reviewer decided the goal is not done
  ///
  /// In en, this message translates to:
  /// **'Verdict: not done'**
  String get goalVerdictFail;

  /// The reviewer could not tell whether the goal is done
  ///
  /// In en, this message translates to:
  /// **'Verdict: couldn\'t tell'**
  String get goalVerdictCannotVerify;

  /// Heading above the reviewer's concerns (shown as quoted text)
  ///
  /// In en, this message translates to:
  /// **'Concerns'**
  String get goalConcerns;

  /// Which agent reviewed the claim. {agent} is the agent's name
  ///
  /// In en, this message translates to:
  /// **'Verified by {agent}'**
  String goalVerifiedBy(String agent);

  /// The goal's own agent reviewed its claim
  ///
  /// In en, this message translates to:
  /// **'Verified by itself (no separate checker)'**
  String get goalVerifiedBySelf;

  /// A person approved completion without a passing verification
  ///
  /// In en, this message translates to:
  /// **'Closed by a person without a passing check'**
  String get goalClosedByPerson;

  /// Button: close a goal that waits for review as done
  ///
  /// In en, this message translates to:
  /// **'Approve completion'**
  String get goalApprove;

  /// Title of the confirmation before approving completion
  ///
  /// In en, this message translates to:
  /// **'Close this goal as done?'**
  String get goalApproveTitle;

  /// Body of the confirmation before approving completion
  ///
  /// In en, this message translates to:
  /// **'No check confirmed it. You close it on your own word, and the goal records that a person closed it unverified.'**
  String get goalApproveBody;

  /// Confirm button: approve completion
  ///
  /// In en, this message translates to:
  /// **'Close as done'**
  String get goalApproveConfirm;

  /// Shown instead of the resume button when the viewer did not start the goal
  ///
  /// In en, this message translates to:
  /// **'Resuming it or raising its budget belongs to whoever started it.'**
  String get goalResumeNotYours;

  /// Heading above the agents that could review the goal's claim instead of the unavailable one
  ///
  /// In en, this message translates to:
  /// **'Pick another checker'**
  String get goalChooseChecker;

  /// Shown after picking a new checker. {agent} is the agent's name
  ///
  /// In en, this message translates to:
  /// **'{agent} checks it now. Resume to verify again.'**
  String goalCheckerSet(String agent);

  /// Button on the goals screen that opens the list of schedules and watches
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get goalSchedules;

  /// Button on the goals screen: start a schedule, a prompt an agent runs again and again
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get goalRepeat;

  /// Label above the commands that must pass for a new goal to count as done
  ///
  /// In en, this message translates to:
  /// **'Checks (optional)'**
  String get goalCreateChecks;

  /// Placeholder of a check command field
  ///
  /// In en, this message translates to:
  /// **'A command that passes when the work is done'**
  String get goalCreateCheckHint;

  /// Button: add another check command field
  ///
  /// In en, this message translates to:
  /// **'Add check'**
  String get goalCreateAddCheck;

  /// Accessible label of the button that removes a check command field
  ///
  /// In en, this message translates to:
  /// **'Remove check'**
  String get goalCreateRemoveCheck;

  /// Label of the field for the most segments (agent runs) a new goal may use
  ///
  /// In en, this message translates to:
  /// **'Segment cap (optional)'**
  String get goalCreateSegmentCap;

  /// Shown when the segment cap is not a whole number
  ///
  /// In en, this message translates to:
  /// **'The segment cap is a whole number, at least 1.'**
  String get goalCreateSegmentInvalid;

  /// Title of the form that starts a schedule
  ///
  /// In en, this message translates to:
  /// **'Repeat a prompt'**
  String get scheduleCreateTitle;

  /// Label above the choices of how often a schedule runs
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get scheduleCadence;

  /// Choice: run every few minutes
  ///
  /// In en, this message translates to:
  /// **'Every N minutes'**
  String get scheduleEveryMinutes;

  /// Choice: run every few hours
  ///
  /// In en, this message translates to:
  /// **'Every N hours'**
  String get scheduleEveryHours;

  /// Choice: the agent picks the delay before its next run
  ///
  /// In en, this message translates to:
  /// **'Self-paced'**
  String get scheduleSelfPaced;

  /// Explains the self-paced choice
  ///
  /// In en, this message translates to:
  /// **'The agent picks the delay after each run, between 1 minute and 1 hour.'**
  String get scheduleSelfPacedHint;

  /// Label of the number field for how many minutes or hours between runs
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get scheduleInterval;

  /// Placeholder of the field with the prompt each run starts from
  ///
  /// In en, this message translates to:
  /// **'What should each run do?'**
  String get scheduleNote;

  /// Label of the field for the most a schedule may spend in all
  ///
  /// In en, this message translates to:
  /// **'Cost cap in USD (optional)'**
  String get scheduleCostCap;

  /// Label of the field for how many days a schedule lasts
  ///
  /// In en, this message translates to:
  /// **'Ends after N days (optional)'**
  String get scheduleExpiryDays;

  /// Shown when the schedule form is incomplete
  ///
  /// In en, this message translates to:
  /// **'Choose a space and an agent, write what each run should do, and give whole numbers of at least 1.'**
  String get scheduleCreateInvalid;

  /// Button: start the schedule
  ///
  /// In en, this message translates to:
  /// **'Start schedule'**
  String get scheduleCreateButton;

  /// Title of the confirmation before a schedule starts
  ///
  /// In en, this message translates to:
  /// **'Start this schedule?'**
  String get scheduleCreateConfirmTitle;

  /// Confirmation body for a schedule that runs every few minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It runs every minute, starting now.} other{It runs every {count} minutes, starting now.}}'**
  String scheduleCreateConfirmEveryMinutes(int count);

  /// Confirmation body for a schedule that runs every few hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It runs every hour, starting now.} other{It runs every {count} hours, starting now.}}'**
  String scheduleCreateConfirmEveryHours(int count);

  /// Confirmation body for a self-paced schedule
  ///
  /// In en, this message translates to:
  /// **'It runs now, then the agent picks when to run again.'**
  String get scheduleCreateConfirmSelfPaced;

  /// Shown after a schedule started
  ///
  /// In en, this message translates to:
  /// **'Schedule started. It is listed under Schedules.'**
  String get scheduleCreated;

  /// Title of the list of the workspace's schedules and watches
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulesTitle;

  /// Shown when the schedules list failed to load
  ///
  /// In en, this message translates to:
  /// **'Could not load schedules'**
  String get schedulesLoadFailed;

  /// Empty schedules list
  ///
  /// In en, this message translates to:
  /// **'No schedules or watches'**
  String get schedulesEmpty;

  /// Empty schedules list: how to make one
  ///
  /// In en, this message translates to:
  /// **'Repeat a prompt from the goals screen, or send /loop or /schedule in a conversation.'**
  String get schedulesEmptyDescription;

  /// Shown when a schedule opened by link no longer exists
  ///
  /// In en, this message translates to:
  /// **'This schedule is no longer available in this workspace.'**
  String get scheduleMissing;

  /// A schedule that runs at a fixed interval. {interval} is a short duration such as 30m or 2h
  ///
  /// In en, this message translates to:
  /// **'Every {interval}'**
  String scheduleEvery(String interval);

  /// A schedule whose agent picks its next time
  ///
  /// In en, this message translates to:
  /// **'Self-paced loop'**
  String get scheduleSelfPacedLoop;

  /// A schedule with a cron expression; the expression follows in code style
  ///
  /// In en, this message translates to:
  /// **'Cron schedule'**
  String get scheduleCron;

  /// A schedule that runs one time. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Once at {time}'**
  String scheduleOnce(String time);

  /// A schedule that waits for an event. {event} is one of the watch event names
  ///
  /// In en, this message translates to:
  /// **'Watch: {event}'**
  String scheduleWatch(String event);

  /// Watch event name: the checks on a pull request finished
  ///
  /// In en, this message translates to:
  /// **'pull request checks'**
  String get scheduleWatchPrChecks;

  /// Watch event name: a pull request got a review or comments
  ///
  /// In en, this message translates to:
  /// **'pull request reviews'**
  String get scheduleWatchPrReview;

  /// Watch event name: a pull request merged
  ///
  /// In en, this message translates to:
  /// **'pull request merge'**
  String get scheduleWatchPrMerged;

  /// Watch event name: the conversation's environment changed
  ///
  /// In en, this message translates to:
  /// **'environment'**
  String get scheduleWatchEnvironment;

  /// Watch event name: a ticket settled
  ///
  /// In en, this message translates to:
  /// **'ticket'**
  String get scheduleWatchTicket;

  /// Watch event name: a pipeline run settled
  ///
  /// In en, this message translates to:
  /// **'pipeline run'**
  String get scheduleWatchPipelineRun;

  /// Status of a schedule that runs
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get scheduleStatusActive;

  /// Status of a paused schedule
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get scheduleStatusPaused;

  /// Status of a schedule that ended for good
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get scheduleStatusEnded;

  /// Which agent a schedule wakes. {agent} is the agent's name
  ///
  /// In en, this message translates to:
  /// **'Wakes {agent}'**
  String scheduleWakes(String agent);

  /// When a schedule runs next. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Next run {time}'**
  String scheduleNext(String time);

  /// When a schedule last ran. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Last run {time}'**
  String scheduleLast(String time);

  /// How many runs a schedule started
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String scheduleRuns(int count);

  /// How many runs a schedule started, against its cap
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} runs'**
  String scheduleRunsOf(int count, int max);

  /// How many times a schedule skipped a run because the agent was busy or the server was down
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skipped} other{{count} skipped}}'**
  String scheduleSkipped(int count);

  /// When a schedule ends. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Ends {time}'**
  String scheduleEnds(String time);

  /// A schedule set inside a run another schedule started shares that chain's limits. {count} is a number, {time} a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Part of a chain: {count} runs left, ends {time}'**
  String scheduleChain(int count, String time);

  /// Heading above a schedule's note the agent wrote for itself (shown as quoted text, not a request)
  ///
  /// In en, this message translates to:
  /// **'The agent\'s own note, in its words:'**
  String get scheduleNoteAgent;

  /// Heading above a schedule's note a person wrote (shown as quoted text)
  ///
  /// In en, this message translates to:
  /// **'A person\'s note:'**
  String get scheduleNotePerson;

  /// Whose sign-in a schedule's runs use. {name} is a person's name
  ///
  /// In en, this message translates to:
  /// **'Acts for {name}'**
  String scheduleActsFor(String name);

  /// A schedule whose runs act for no person (an agent set it in a run nobody started)
  ///
  /// In en, this message translates to:
  /// **'Acts for no person'**
  String get scheduleActsForBot;

  /// Shown when a schedule belongs to a goal
  ///
  /// In en, this message translates to:
  /// **'It ends with its goal.'**
  String get scheduleGoalBound;

  /// Button: pause a schedule
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get schedulePause;

  /// Button: resume a paused schedule
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get scheduleResume;

  /// Button: end a schedule for good
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get scheduleDelete;

  /// Button: remove an ended schedule from the list
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get scheduleRemove;

  /// Title of the confirmation before ending a schedule
  ///
  /// In en, this message translates to:
  /// **'Delete this schedule?'**
  String get scheduleDeleteTitle;

  /// Body of the confirmation before ending a schedule
  ///
  /// In en, this message translates to:
  /// **'It stops for good. Nothing it already did is undone.'**
  String get scheduleDeleteBody;

  /// Title of the confirmation before removing an ended schedule
  ///
  /// In en, this message translates to:
  /// **'Remove this schedule?'**
  String get scheduleRemoveTitle;

  /// Body of the confirmation before removing an ended schedule
  ///
  /// In en, this message translates to:
  /// **'It disappears from the list.'**
  String get scheduleRemoveBody;

  /// Shown instead of Resume when the viewer may not resume the schedule
  ///
  /// In en, this message translates to:
  /// **'Only the person this schedule acts for can resume it.'**
  String get scheduleResumeNotYours;

  /// Shown instead of Resume on a schedule that acts for no person, to a viewer who is not an admin
  ///
  /// In en, this message translates to:
  /// **'Only a workspace admin can resume a schedule no person owns.'**
  String get scheduleResumeAdminOnly;

  /// Button: open the conversation a schedule wakes
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get scheduleOpenConversation;

  /// Heading of the section listing what will start or continue an agent's work later in this conversation
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get progressWaiting;

  /// Shown when no wake waits in this conversation
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting.'**
  String get progressNothingWaiting;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get wakeOriginGoal;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Goal check'**
  String get wakeOriginGoalCheck;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Goal review'**
  String get wakeOriginGoalReview;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get wakeOriginSchedule;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get wakeOriginWatch;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get wakeOriginReply;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get wakeOriginMessage;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Finished work'**
  String get wakeOriginWorkFinished;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Limit reset'**
  String get wakeOriginLimitReset;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get wakeOriginRecovery;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get wakeOriginAssignment;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Pipeline step'**
  String get wakeOriginPipelineStep;

  /// Label naming what raised a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Improvement review'**
  String get wakeOriginImprovementReview;

  /// Label: a wake raised by another agent's reply. {agent} is that agent's name
  ///
  /// In en, this message translates to:
  /// **'Reply from {agent}'**
  String wakeOriginReplyFrom(String agent);

  /// Label: a wake raised by another agent's message. {agent} is that agent's name
  ///
  /// In en, this message translates to:
  /// **'Message from {agent}'**
  String wakeOriginMessageFrom(String agent);

  /// Label: a wake raised by another agent finishing work. {agent} is that agent's name
  ///
  /// In en, this message translates to:
  /// **'Finished work from {agent}'**
  String wakeOriginWorkFinishedBy(String agent);

  /// Which agent a waiting wake will wake. {agent} is the agent's name
  ///
  /// In en, this message translates to:
  /// **'For {agent}'**
  String wakeFor(String agent);

  /// When a wake is due. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Due {time}'**
  String wakeDue(String time);

  /// A wake is due now
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get wakeDueNow;

  /// A wake is held until a person resumes it
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get wakeHeld;

  /// When a wake expires. {time} is a short date and clock time
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String wakeExpires(String time);

  /// How many times delivering a wake was tried
  ///
  /// In en, this message translates to:
  /// **'Attempt {attempt}'**
  String wakeAttempt(int attempt);

  /// Button: cancel a waiting wake
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wakeCancel;

  /// Button: deliver a waiting wake now instead of at its time
  ///
  /// In en, this message translates to:
  /// **'Deliver now'**
  String get wakeDeliverNow;

  /// Button: resume a held wake
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get wakeResume;

  /// Button: drop the recovery wake left after a server restart
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get wakeDismiss;

  /// Shown instead of Resume when the viewer may not resume a held wake
  ///
  /// In en, this message translates to:
  /// **'Only the person whose run this is can resume it.'**
  String get wakeResumeOnlyTheirs;

  /// Card for the wake a server restart left behind
  ///
  /// In en, this message translates to:
  /// **'The server restarted during this run. Resume to continue it, or dismiss.'**
  String get wakeRecovery;

  /// Card: an agent run waits for an AI provider's usage limit to reset. {provider} is the provider's name, {time} a clock time
  ///
  /// In en, this message translates to:
  /// **'Paused at {provider}\'s usage limit, which resets at {time}. The run waits for Resume, for up to 7 days after the reset.'**
  String limitParkTitle(String provider, String time);

  /// Card: an agent run waits for an AI provider's usage limit to reset; the provider is unknown. {time} is a clock time
  ///
  /// In en, this message translates to:
  /// **'Paused at the provider\'s usage limit, which resets at {time}. The run waits for Resume, for up to 7 days after the reset.'**
  String limitParkTitleUnnamed(String time);

  /// Button: resume the run without waiting for the reset
  ///
  /// In en, this message translates to:
  /// **'Resume now'**
  String get limitParkResumeNow;

  /// Button: stop waiting for the usage limit
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get limitParkCancel;

  /// The run waiting at a usage limit has resumed. {provider} is the provider's name
  ///
  /// In en, this message translates to:
  /// **'Resumed after {provider}\'s usage limit.'**
  String limitParkResumed(String provider);

  /// The run no longer waits at a usage limit (it was cancelled or resumed). {provider} is the provider's name
  ///
  /// In en, this message translates to:
  /// **'No longer waiting at {provider}\'s usage limit.'**
  String limitParkGone(String provider);

  /// Stands in for the provider's name in limitParkResumed and limitParkGone when the name is unknown
  ///
  /// In en, this message translates to:
  /// **'the provider'**
  String get limitParkProviderUnknown;

  /// Button above the composer when messages are held because a person stopped the run
  ///
  /// In en, this message translates to:
  /// **'Held messages'**
  String get mobileHeldMessages;

  /// Above messages that were held when a person stopped the agent's run
  ///
  /// In en, this message translates to:
  /// **'Held because the run ended before it could take them. Send yours now or remove them.'**
  String get heldSteeringTitle;

  /// Button: send every held message to the agent
  ///
  /// In en, this message translates to:
  /// **'Send held messages'**
  String get heldSteeringRelease;

  /// Activity title: a goal completed
  ///
  /// In en, this message translates to:
  /// **'Goal done'**
  String get notifGoalCompleted;

  /// Activity title: a goal failed
  ///
  /// In en, this message translates to:
  /// **'Goal failed'**
  String get notifGoalFailed;

  /// Activity title: a goal was cancelled
  ///
  /// In en, this message translates to:
  /// **'Goal cancelled'**
  String get notifGoalCancelled;

  /// Activity title: a goal spent its whole budget
  ///
  /// In en, this message translates to:
  /// **'Goal used its budget'**
  String get notifGoalBudgetExhausted;

  /// Activity title: a goal stopped and a person must decide
  ///
  /// In en, this message translates to:
  /// **'A goal waits for your review'**
  String get notifGoalNeedsReview;

  /// Activity title: a goal waits for a person's answer
  ///
  /// In en, this message translates to:
  /// **'A goal needs you'**
  String get notifGoalNeedsPerson;

  /// Activity title: a goal is held for another reason
  ///
  /// In en, this message translates to:
  /// **'A goal is on hold'**
  String get notifGoalOnHold;

  /// Activity title: a schedule ended for good
  ///
  /// In en, this message translates to:
  /// **'A schedule ended'**
  String get notifWakeRuleEnded;

  /// Activity title of the daily digest of what waits for the person
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing waits for you} other{{count} things wait for you}}'**
  String notifWaitingDigest(int count);

  /// Activity title: agents proposed improvements to review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{An improvement was proposed} other{{count} improvements were proposed}}'**
  String notifImprovementProposed(int count);

  /// Activity title: a pipeline run stopped at its cost cap
  ///
  /// In en, this message translates to:
  /// **'A pipeline run is held at its budget'**
  String get notifPipelineRunHeld;

  /// Activity body of a held pipeline run. Both are formatted amounts
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {cap}'**
  String notifPipelineRunHeldBody(String spent, String cap);

  /// Tag on an activity entry that asks the person to act
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get notifNeedsYou;

  /// Label of a digest entry: a goal waits for review
  ///
  /// In en, this message translates to:
  /// **'Goal waits for review'**
  String get notifDigestGoalReview;

  /// Label of a digest entry: a goal waits for a person
  ///
  /// In en, this message translates to:
  /// **'Goal needs a person'**
  String get notifDigestGoalPerson;

  /// Label of a digest entry: a wake is held until someone resumes it
  ///
  /// In en, this message translates to:
  /// **'Held wake'**
  String get notifDigestHeldWake;

  /// Label of a digest entry: an improvement waits for review
  ///
  /// In en, this message translates to:
  /// **'Proposed improvement'**
  String get notifDigestImprovement;

  /// Why a wake from a schedule did not run: the schedule was paused
  ///
  /// In en, this message translates to:
  /// **'Its schedule was paused.'**
  String get wakeKindRulePaused;

  /// Why a wake from a schedule was skipped: the agent was already running and the schedule is set to skip in that case
  ///
  /// In en, this message translates to:
  /// **'The agent was busy, and this schedule skips a time when it is.'**
  String get wakeKindRuleBusy;

  /// Why a wake from a watch was cancelled: it was merged into a newer wake for the same watch
  ///
  /// In en, this message translates to:
  /// **'A later event of the same watch took its place.'**
  String get wakeKindRuleFolded;

  /// Why a wake from a schedule did not run: a newer scheduled time replaced it
  ///
  /// In en, this message translates to:
  /// **'A later time of its schedule replaced it.'**
  String get wakeKindRuleSuperseded;

  /// Why a wake from a schedule started no run: the schedule is set to notify only
  ///
  /// In en, this message translates to:
  /// **'Its schedule only sends a notification, so no run started.'**
  String get wakeKindRuleNotified;

  /// Why a wake from a schedule is waiting: the provider usage limit was reached
  ///
  /// In en, this message translates to:
  /// **'Its schedule waits for the provider\'s usage limit to reset.'**
  String get wakeKindRuleLimitParked;

  /// Why a /refine command was refused: a review of this conversation ran recently
  ///
  /// In en, this message translates to:
  /// **'An improvement review ran in this conversation a short while ago. Try again later.'**
  String get improvementRefusalCooldown;

  /// Why a /refine command was refused: a review is already queued
  ///
  /// In en, this message translates to:
  /// **'An improvement review of this conversation is already waiting to run.'**
  String get improvementRefusalQueued;

  /// Why a /refine command was refused: the named agent is not in this workspace
  ///
  /// In en, this message translates to:
  /// **'That agent is not an agent of this workspace.'**
  String get improvementRefusalAgentNotFound;

  /// Why sending held messages was refused: they are held by a usage-limit pause, not by a stop
  ///
  /// In en, this message translates to:
  /// **'Messages held at a usage limit can\'t be sent by hand. They wait for the paused run to resume.'**
  String get steeringRefusalHeldByLimit;

  /// A finished usage-limit pause that someone cancelled. {provider} is the provider name, or the fallback "the provider"
  ///
  /// In en, this message translates to:
  /// **'The wait at {provider}\'s usage limit was cancelled.'**
  String limitParkCancelled(String provider);

  /// A finished usage-limit pause that ran out of time. {provider} is the provider name, or the fallback "the provider"
  ///
  /// In en, this message translates to:
  /// **'The wait at {provider}\'s usage limit expired before the run resumed.'**
  String limitParkExpired(String provider);

  /// A finished usage-limit pause whose resume was skipped; the reason follows. {provider} is the provider name, or the fallback "the provider"
  ///
  /// In en, this message translates to:
  /// **'The run did not resume after {provider}\'s usage limit.'**
  String limitParkSkipped(String provider);

  /// Heading over messages a usage-limit pause holds, when the reset time is unknown
  ///
  /// In en, this message translates to:
  /// **'Held while the run waits for the usage limit to reset. They are sent when the person it runs for resumes it.'**
  String get heldSteeringLimitTitle;

  /// Heading over messages a usage-limit pause holds. {time} is when the provider said the limit resets
  ///
  /// In en, this message translates to:
  /// **'Held until the usage limit resets at {time}. They are sent when the person it runs for resumes it.'**
  String heldSteeringLimitAt(String time);

  /// Heading over held messages that neither a stop nor a usage-limit pause holds
  ///
  /// In en, this message translates to:
  /// **'Held by the server. You can remove them.'**
  String get heldSteeringOtherTitle;

  /// Conversation row: an agent was woken to run. {agent} is the agent name; {count} is how many wakes the run delivered
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Woke {agent}} other{Woke {agent} for {count} waiting items}}'**
  String workRowWoke(int count, String agent);

  /// Conversation row: a scheduled wake was missed while the server was down. {agent} is the agent name
  ///
  /// In en, this message translates to:
  /// **'A wake for {agent} was missed while the server was down.'**
  String workRowWakeMissed(String agent);

  /// Conversation row: a wake was skipped; the reason follows. {agent} is the agent name
  ///
  /// In en, this message translates to:
  /// **'A wake for {agent} was not delivered.'**
  String workRowWakeSkipped(String agent);

  /// Conversation row: a schedule was created. {agent} is the agent name
  ///
  /// In en, this message translates to:
  /// **'Schedule set for {agent}.'**
  String workRowScheduleCreated(String agent);

  /// Conversation row: a schedule ended; the reason follows. {agent} is the agent name
  ///
  /// In en, this message translates to:
  /// **'{agent}\'s schedule ended.'**
  String workRowScheduleEnded(String agent);

  /// Conversation row heading over the note an agent left on its schedule. {agent} is the agent name
  ///
  /// In en, this message translates to:
  /// **'Schedule note from {agent}:'**
  String workRowNoteFromAgent(String agent);

  /// Conversation row heading over the note a person left on a schedule
  ///
  /// In en, this message translates to:
  /// **'Schedule note from a person:'**
  String get workRowNoteFromPerson;

  /// Conversation row: a slash command was refused; the reason follows. {command} is the command, such as /goal
  ///
  /// In en, this message translates to:
  /// **'The {command} command was refused.'**
  String workRowCommandRefusedNamed(String command);

  /// Conversation row: a slash command was refused; the reason follows
  ///
  /// In en, this message translates to:
  /// **'A command was refused.'**
  String get workRowCommandRefused;

  /// Conversation row: a person raised a pipeline run budget. {person} is their name; {from} and {to} are amounts of money
  ///
  /// In en, this message translates to:
  /// **'{person} raised the pipeline\'s spending cap from {from} to {to}.'**
  String workRowCapRaised(String person, String from, String to);

  /// Conversation row: a person raised a pipeline run budget (amounts unknown). {person} is their name
  ///
  /// In en, this message translates to:
  /// **'{person} raised the pipeline\'s spending cap.'**
  String workRowCapRaisedNoAmounts(String person);

  /// Conversation row: an accepted improvement to a skill was undone at startup; the skill name follows
  ///
  /// In en, this message translates to:
  /// **'An accepted change to this skill could not be finished, because the skill changed in the meantime. The proposal was rolled back.'**
  String get workRowApplyIncomplete;

  /// Button on a conversation row that opens the schedule it is about
  ///
  /// In en, this message translates to:
  /// **'Open schedule'**
  String get workRowOpenSchedule;

  /// Heading over held messages when none of them were written by the viewer, so the viewer cannot send them
  ///
  /// In en, this message translates to:
  /// **'Held because the run ended before it could take them. Only the person who wrote a message can send it.'**
  String get heldSteeringOthersTitle;

  /// Note above the Send held messages button when some held messages were written by other people
  ///
  /// In en, this message translates to:
  /// **'Sends only your messages. The others wait for the people who wrote them.'**
  String get heldSteeringOnlyYours;

  /// Caption under a held message someone else wrote. {name} is that person's name
  ///
  /// In en, this message translates to:
  /// **'Written by {name}'**
  String heldSteeringWrittenBy(String name);

  /// Why sending held messages was refused: every held message belongs to someone else
  ///
  /// In en, this message translates to:
  /// **'Only the person who wrote a held message can send it, and none of these are yours.'**
  String get steeringRefusalNotYours;

  /// Why queuing or sending a steering message was refused: the viewer lacks write access and the live run acts for another person
  ///
  /// In en, this message translates to:
  /// **'You need write access to this space\'s repositories to steer a run that acts for someone else.'**
  String get steeringRefusalNeedsWrite;

  /// Conversation row: a person paused a schedule. {name} is that person; {agent} is the agent the schedule wakes
  ///
  /// In en, this message translates to:
  /// **'{name} paused the schedule for {agent}.'**
  String workRowSchedulePaused(String name, String agent);

  /// Verification row label when the reviewer judged a goal with no criteria as one item: the objective itself
  ///
  /// In en, this message translates to:
  /// **'The objective as a whole'**
  String get goalVerdictObjective;

  /// Label of a digest entry: an agent asked a question or for approval and waits for an answer
  ///
  /// In en, this message translates to:
  /// **'Waits for your answer'**
  String get notifDigestRequest;
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
