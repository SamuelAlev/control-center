import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pt'),
  ];

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @serverConnection.
  ///
  /// In en, this message translates to:
  /// **'Server connection'**
  String get serverConnection;

  /// No description provided for @serverConnectionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get serverConnectionMode;

  /// No description provided for @serverModeLocal.
  ///
  /// In en, this message translates to:
  /// **'Run in this app'**
  String get serverModeLocal;

  /// No description provided for @serverModeLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Control Center runs its own server on this machine and owns your data locally.'**
  String get serverModeLocalDescription;

  /// No description provided for @serverModeRemote.
  ///
  /// In en, this message translates to:
  /// **'Connect to a remote instance'**
  String get serverModeRemote;

  /// No description provided for @serverModeRemoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Control Center server running elsewhere. Your data lives on that server.'**
  String get serverModeRemoteDescription;

  /// No description provided for @serverRemoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverRemoteUrl;

  /// No description provided for @serverRemoteDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device id'**
  String get serverRemoteDeviceId;

  /// No description provided for @serverRemotePairingKey.
  ///
  /// In en, this message translates to:
  /// **'Pairing key'**
  String get serverRemotePairingKey;

  /// No description provided for @serverRemotePairingKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the pairing key from the remote server'**
  String get serverRemotePairingKeyHint;

  /// No description provided for @serverConnectionRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Restart Control Center to apply connection changes.'**
  String get serverConnectionRestartHint;

  /// No description provided for @serverConnectionReloadHint.
  ///
  /// In en, this message translates to:
  /// **'Reload to reconnect with these changes.'**
  String get serverConnectionReloadHint;

  /// No description provided for @pairedClients.
  ///
  /// In en, this message translates to:
  /// **'Paired clients'**
  String get pairedClients;

  /// No description provided for @pairedClientsDescription.
  ///
  /// In en, this message translates to:
  /// **'Apps and devices paired with this server. Pair another to connect a second browser, a desktop app, or a phone.'**
  String get pairedClientsDescription;

  /// No description provided for @pairNewClient.
  ///
  /// In en, this message translates to:
  /// **'Pair a new client'**
  String get pairNewClient;

  /// No description provided for @pairClientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Label this client (e.g. Work laptop)'**
  String get pairClientNameHint;

  /// No description provided for @pairClientTypeWeb.
  ///
  /// In en, this message translates to:
  /// **'Web browser'**
  String get pairClientTypeWeb;

  /// No description provided for @pairClientTypeDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop app'**
  String get pairClientTypeDesktop;

  /// No description provided for @pairClientTypePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get pairClientTypePhone;

  /// No description provided for @pairAction.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairAction;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @pairCredentialsIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect the new client with these details, or open the link in it.'**
  String get pairCredentialsIntro;

  /// No description provided for @pairLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get pairLinkLabel;

  /// No description provided for @pairScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code with your phone\'s camera to pair it.'**
  String get pairScanQr;

  /// No description provided for @pairServerUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not reachable'**
  String get pairServerUnreachableTitle;

  /// No description provided for @pairServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Other devices can\'t reach this server directly, so a new client can\'t connect. Set the server\'s public URL to pair more clients.'**
  String get pairServerUnreachable;

  /// No description provided for @noPairedClients.
  ///
  /// In en, this message translates to:
  /// **'No paired clients yet.'**
  String get noPairedClients;

  /// No description provided for @serverSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'How should Control Center run?'**
  String get serverSetupTitle;

  /// No description provided for @serverSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control Center needs a server that owns your data. Run one inside this app, or connect to an instance running elsewhere.'**
  String get serverSetupSubtitle;

  /// No description provided for @serverSetupRunLocal.
  ///
  /// In en, this message translates to:
  /// **'Run in this app'**
  String get serverSetupRunLocal;

  /// No description provided for @serverSetupConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get serverSetupConnect;

  /// No description provided for @serverSetupInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid ws:// or wss:// server URL.'**
  String get serverSetupInvalidUrl;

  /// No description provided for @serverSetupCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get serverSetupCouldNotConnect;

  /// No description provided for @calendarViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarViewMonth;

  /// No description provided for @calendarViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarViewWeek;

  /// No description provided for @calendarViewAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calendarViewAgenda;

  /// No description provided for @calendarConnectGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar'**
  String get calendarConnectGoogle;

  /// No description provided for @calendarConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync your Google Calendar to see events here and get alerts before meetings start.'**
  String get calendarConnectDescription;

  /// No description provided for @calendarDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get calendarDisconnect;

  /// No description provided for @calendarReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get calendarReconnect;

  /// No description provided for @calendarEmptyNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events in this range'**
  String get calendarEmptyNoEvents;

  /// No description provided for @calendarStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get calendarStartRecording;

  /// No description provided for @calendarStartRecordingAndLink.
  ///
  /// In en, this message translates to:
  /// **'Start recording & link'**
  String get calendarStartRecordingAndLink;

  /// No description provided for @calendarJoinMeet.
  ///
  /// In en, this message translates to:
  /// **'Join meeting'**
  String get calendarJoinMeet;

  /// No description provided for @calendarFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'From calendar'**
  String get calendarFromCalendar;

  /// No description provided for @calendarLinkedMeeting.
  ///
  /// In en, this message translates to:
  /// **'Linked meeting'**
  String get calendarLinkedMeeting;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarWeekNumber.
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String calendarWeekNumber(int number);

  /// No description provided for @calendarPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get calendarPreviousPeriod;

  /// No description provided for @calendarNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get calendarNextPeriod;

  /// No description provided for @calendarLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String calendarLastSynced(String time);

  /// No description provided for @calendarNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get calendarNeverSynced;

  /// No description provided for @calendarSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get calendarSyncing;

  /// No description provided for @calendarViewDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarViewDay;

  /// No description provided for @calendarSectionCalendars.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get calendarSectionCalendars;

  /// No description provided for @calendarShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get calendarShow;

  /// No description provided for @calendarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get calendarHide;

  /// No description provided for @calendarRsvpGoing.
  ///
  /// In en, this message translates to:
  /// **'Going?'**
  String get calendarRsvpGoing;

  /// No description provided for @calendarRsvpYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get calendarRsvpYes;

  /// No description provided for @calendarRsvpNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get calendarRsvpNo;

  /// No description provided for @calendarRsvpMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get calendarRsvpMaybe;

  /// No description provided for @calendarRsvpFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your response'**
  String get calendarRsvpFailed;

  /// No description provided for @calendarAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add calendar account'**
  String get calendarAddAccount;

  /// No description provided for @calendarSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get calendarSettingsTitle;

  /// No description provided for @calendarSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect a Google account to sync events into this workspace.'**
  String get calendarSettingsDescription;

  /// No description provided for @calendarNotConnected.
  ///
  /// In en, this message translates to:
  /// **'No Google account connected'**
  String get calendarNotConnected;

  /// No description provided for @calendarConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get calendarConnecting;

  /// No description provided for @calendarSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get calendarSyncNow;

  /// No description provided for @calendarNoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to view its calendar'**
  String get calendarNoWorkspace;

  /// No description provided for @calendarConnectError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect Google Calendar'**
  String get calendarConnectError;

  /// No description provided for @calendarClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get calendarClientIdLabel;

  /// No description provided for @calendarClientSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get calendarClientSecretLabel;

  /// No description provided for @calendarConnectCredsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the Google OAuth device-code client ID and secret for your project. The server runs the connection and sync — your browser never holds the tokens.'**
  String get calendarConnectCredsHint;

  /// No description provided for @calendarConnectApproveInstruction.
  ///
  /// In en, this message translates to:
  /// **'Open the verification page on any device, sign in, and enter this code:'**
  String get calendarConnectApproveInstruction;

  /// No description provided for @calendarConnectOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open verification page'**
  String get calendarConnectOpenPage;

  /// No description provided for @calendarConnectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval…'**
  String get calendarConnectWaiting;

  /// No description provided for @calendarConnectDenied.
  ///
  /// In en, this message translates to:
  /// **'Authorization was denied. Please try again.'**
  String get calendarConnectDenied;

  /// No description provided for @calendarConnectExpired.
  ///
  /// In en, this message translates to:
  /// **'The code expired. Please try again.'**
  String get calendarConnectExpired;

  /// No description provided for @calendarNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar isn\'t configured. Set GOOGLE_OAUTH_CLIENT_ID to connect an account.'**
  String get calendarNotConfigured;

  /// No description provided for @notificationMeetingStartsSoon.
  ///
  /// In en, this message translates to:
  /// **'Meeting starting soon'**
  String get notificationMeetingStartsSoon;

  /// No description provided for @notifyMeetingStartsSoon.
  ///
  /// In en, this message translates to:
  /// **'When a calendar meeting is about to start'**
  String get notifyMeetingStartsSoon;

  /// No description provided for @notificationCalendarAuthExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar disconnected'**
  String get notificationCalendarAuthExpiredTitle;

  /// No description provided for @notificationCalendarAuthExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Reconnect {email} to resume syncing'**
  String notificationCalendarAuthExpiredBody(String email);

  /// No description provided for @notificationCalendarAuthExpiredBodyNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Reconnect your calendar to resume syncing'**
  String get notificationCalendarAuthExpiredBodyNoEmail;

  /// No description provided for @notifyCalendarAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'When a calendar account needs to be reconnected'**
  String get notifyCalendarAuthExpired;

  /// No description provided for @calendarAlertLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Alert lead time'**
  String get calendarAlertLeadTime;

  /// No description provided for @calendarAlertLeadTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long before a meeting to alert you'**
  String get calendarAlertLeadTimeSubtitle;

  /// No description provided for @calendarConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {email}'**
  String calendarConnectedAs(String email);

  /// No description provided for @calendarAttendeesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attendees'**
  String calendarAttendeesCount(int count);

  /// No description provided for @calendarEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calendarEventLabel;

  /// No description provided for @calendarRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring event'**
  String get calendarRecurring;

  /// No description provided for @calendarGoogleMeet.
  ///
  /// In en, this message translates to:
  /// **'Google Meet'**
  String get calendarGoogleMeet;

  /// No description provided for @calendarOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get calendarOrganizer;

  /// No description provided for @calendarYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get calendarYou;

  /// No description provided for @calendarShowFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get calendarShowFewer;

  /// No description provided for @calendarRsvpAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting'**
  String get calendarRsvpAwaiting;

  /// No description provided for @calendarParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String calendarParticipantsCount(int count);

  /// No description provided for @calendarSeeAllParticipants.
  ///
  /// In en, this message translates to:
  /// **'See all {count} participants'**
  String calendarSeeAllParticipants(int count);

  /// No description provided for @calendarRsvpCountYes.
  ///
  /// In en, this message translates to:
  /// **'{count} yes'**
  String calendarRsvpCountYes(int count);

  /// No description provided for @calendarRsvpCountNo.
  ///
  /// In en, this message translates to:
  /// **'{count} no'**
  String calendarRsvpCountNo(int count);

  /// No description provided for @calendarRsvpCountMaybe.
  ///
  /// In en, this message translates to:
  /// **'{count} maybe'**
  String calendarRsvpCountMaybe(int count);

  /// No description provided for @calendarRsvpCountAwaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting'**
  String calendarRsvpCountAwaiting(int count);

  /// No description provided for @calendarLeadMinutesOption.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String calendarLeadMinutesOption(int count);

  /// No description provided for @openInEditorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Open in which editor?'**
  String get openInEditorPrompt;

  /// No description provided for @ideNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get ideNotInstalled;

  /// No description provided for @openInIde.
  ///
  /// In en, this message translates to:
  /// **'Open in {editor}'**
  String openInIde(String editor);

  /// No description provided for @failedToOpenInIde.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {editor}: {error}'**
  String failedToOpenInIde(String editor, String error);

  /// No description provided for @profileSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search pull requests…'**
  String get profileSearchHint;

  /// No description provided for @profileClickToLoad.
  ///
  /// In en, this message translates to:
  /// **'Click to load'**
  String get profileClickToLoad;

  /// No description provided for @profileStateOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Currently open'**
  String get profileStateOpenHint;

  /// No description provided for @profileStateMergedHint.
  ///
  /// In en, this message translates to:
  /// **'Merged history'**
  String get profileStateMergedHint;

  /// No description provided for @profileStateClosedHint.
  ///
  /// In en, this message translates to:
  /// **'Closed, not merged'**
  String get profileStateClosedHint;

  /// No description provided for @profileNoPrsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No pull requests for the selected states'**
  String get profileNoPrsForFilter;

  /// No description provided for @byAuthorPrefix.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get byAuthorPrefix;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get youLabel;

  /// No description provided for @readyToMerge.
  ///
  /// In en, this message translates to:
  /// **'Ready to merge'**
  String get readyToMerge;

  /// No description provided for @laneReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Checks green'**
  String get laneReadyHint;

  /// No description provided for @laneReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you'**
  String get laneReviewHint;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @laneInProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Open · being worked'**
  String get laneInProgressHint;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @laneAttentionHint.
  ///
  /// In en, this message translates to:
  /// **'Failing or stale'**
  String get laneAttentionHint;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @laneDraftsHint.
  ///
  /// In en, this message translates to:
  /// **'Not opened yet'**
  String get laneDraftsHint;

  /// No description provided for @allOpenPrs.
  ///
  /// In en, this message translates to:
  /// **'All open PRs'**
  String get allOpenPrs;

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String showAllCount(int count);

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get sortLargest;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectAction;

  /// No description provided for @mergeCountReady.
  ///
  /// In en, this message translates to:
  /// **'Merge {count} ready'**
  String mergeCountReady(int count);

  /// No description provided for @countSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String countSelected(int count);

  /// No description provided for @mergeReadyAction.
  ///
  /// In en, this message translates to:
  /// **'Merge ready'**
  String get mergeReadyAction;

  /// No description provided for @nothingInLane.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this lane'**
  String get nothingInLane;

  /// No description provided for @nothingInLaneHint.
  ///
  /// In en, this message translates to:
  /// **'Pick another lane above, or show all open PRs.'**
  String get nothingInLaneHint;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @openFullDiff.
  ///
  /// In en, this message translates to:
  /// **'Open full diff'**
  String get openFullDiff;

  /// No description provided for @viewFiles.
  ///
  /// In en, this message translates to:
  /// **'View files'**
  String get viewFiles;

  /// No description provided for @checksLabel.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checksLabel;

  /// No description provided for @commentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsLabel;

  /// No description provided for @mergeReadyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge ready pull requests?'**
  String get mergeReadyConfirmTitle;

  /// No description provided for @mergeReadyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Squash-merge 1 ready pull request? This can\'t be undone.} other{Squash-merge {count} ready pull requests? This can\'t be undone.}}'**
  String mergeReadyConfirmBody(int count);

  /// No description provided for @mergedCountPrs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Merged 1 pull request} other{Merged {count} pull requests}}'**
  String mergedCountPrs(int count);

  /// No description provided for @keybindingSelectPr.
  ///
  /// In en, this message translates to:
  /// **'Select PR'**
  String get keybindingSelectPr;

  /// No description provided for @keybindingMergePr.
  ///
  /// In en, this message translates to:
  /// **'Merge PR'**
  String get keybindingMergePr;

  /// No description provided for @keybindingPeekPr.
  ///
  /// In en, this message translates to:
  /// **'Peek PR'**
  String get keybindingPeekPr;

  /// No description provided for @keybindingToggleSelectionOfTheFocusedPullRequestDescription.
  ///
  /// In en, this message translates to:
  /// **'Toggle selection of the focused pull request'**
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription;

  /// No description provided for @keybindingMergeTheFocusedPullRequestDescription.
  ///
  /// In en, this message translates to:
  /// **'Merge the focused pull request if it\'s ready'**
  String get keybindingMergeTheFocusedPullRequestDescription;

  /// No description provided for @keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription.
  ///
  /// In en, this message translates to:
  /// **'Expand or collapse the focused pull request\'s peek panel'**
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription;

  /// No description provided for @kbMove.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get kbMove;

  /// No description provided for @kbSelect.
  ///
  /// In en, this message translates to:
  /// **'select'**
  String get kbSelect;

  /// No description provided for @kbMerge.
  ///
  /// In en, this message translates to:
  /// **'merge'**
  String get kbMerge;

  /// No description provided for @kbOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get kbOpen;

  /// No description provided for @kbPeek.
  ///
  /// In en, this message translates to:
  /// **'peek'**
  String get kbPeek;

  /// No description provided for @kbTabs.
  ///
  /// In en, this message translates to:
  /// **'tabs'**
  String get kbTabs;

  /// No description provided for @kbSearch.
  ///
  /// In en, this message translates to:
  /// **'search'**
  String get kbSearch;

  /// No description provided for @kbViewed.
  ///
  /// In en, this message translates to:
  /// **'viewed'**
  String get kbViewed;

  /// No description provided for @kbCollapse.
  ///
  /// In en, this message translates to:
  /// **'collapse'**
  String get kbCollapse;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, and typography.'**
  String get appearanceSettingsDescription;

  /// No description provided for @notificationsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which agent and workspace events notify you.'**
  String get notificationsSettingsDescription;

  /// No description provided for @integrationsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub, ticketing, and the MCP server.'**
  String get integrationsSettingsDescription;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @advancedSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Branch naming, voice, semantic search, privacy, and logging.'**
  String get advancedSettingsDescription;

  /// No description provided for @agentRegistry.
  ///
  /// In en, this message translates to:
  /// **'Agent registry'**
  String get agentRegistry;

  /// No description provided for @settingsGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGroupGeneral;

  /// No description provided for @settingsGroupAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get settingsGroupAgents;

  /// No description provided for @settingsGroupResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get settingsGroupResources;

  /// No description provided for @filterSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter settings'**
  String get filterSettingsHint;

  /// No description provided for @needsSetupLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get needsSetupLabel;

  /// No description provided for @noSettingsMatch.
  ///
  /// In en, this message translates to:
  /// **'No settings match \"{query}\"'**
  String noSettingsMatch(String query);

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @sendDiffContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Send diff content to AI adapter'**
  String get sendDiffContentTitle;

  /// No description provided for @diffSharingOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw diff lines are included in agent prompts for deeper review.'**
  String get diffSharingOnSubtitle;

  /// No description provided for @diffSharingOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agents use only structured metadata (file paths, line numbers, PR description); no raw code leaves the app.'**
  String get diffSharingOffSubtitle;

  /// No description provided for @errorReportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share crash reports'**
  String get errorReportingTitle;

  /// No description provided for @errorReportingOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Crash, error, and performance diagnostics are sent to help fix bugs (release builds only).'**
  String get errorReportingOnSubtitle;

  /// No description provided for @errorReportingOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics are off. No crash or error reports are sent.'**
  String get errorReportingOffSubtitle;

  /// No description provided for @onboardingDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve Control Center'**
  String get onboardingDiagnosticsTitle;

  /// No description provided for @onboardingDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send crash, error, and performance diagnostics so we can fix problems faster (release builds only). You can change this any time in Settings → Privacy.'**
  String get onboardingDiagnosticsSubtitle;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @noRunsYet.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get noRunsYet;

  /// Total agent runs in the last six months
  ///
  /// In en, this message translates to:
  /// **'{count} runs in the last 6 months'**
  String runsInLastSixMonths(String count);

  /// Relative time since an agent was last active
  ///
  /// In en, this message translates to:
  /// **'Active {duration} ago'**
  String lastActiveAgo(String duration);

  /// No description provided for @reportsToNobody.
  ///
  /// In en, this message translates to:
  /// **'No manager'**
  String get reportsToNobody;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// No description provided for @pathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied to clipboard'**
  String get pathCopied;

  /// No description provided for @editAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit agent'**
  String get editAgent;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Count of importable agent definitions found on disk
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent definition found} other{{count} agent definitions found}}'**
  String discoverAgentsFound(int count);

  /// No description provided for @noAgentsToDiscover.
  ///
  /// In en, this message translates to:
  /// **'No new agents to import'**
  String get noAgentsToDiscover;

  /// No description provided for @noAgentsToDiscoverHint.
  ///
  /// In en, this message translates to:
  /// **'Agent definitions in this workspace are already imported.'**
  String get noAgentsToDiscoverHint;

  /// No description provided for @sortByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortByStatus;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @noMatchingAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents match your filter'**
  String get noMatchingAgents;

  /// No description provided for @selectAnAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an agent to see its status, activity, and details.'**
  String get selectAnAgentHint;

  /// Fallback label for an embedded video that can't render inline; tapping opens the provider's site in the browser.
  ///
  /// In en, this message translates to:
  /// **'Watch video on {provider}'**
  String watchVideoOn(String provider);

  /// No description provided for @branchTemplate.
  ///
  /// In en, this message translates to:
  /// **'Branch name template'**
  String get branchTemplate;

  /// No description provided for @branchTemplateDescription.
  ///
  /// In en, this message translates to:
  /// **'Pattern for the branch created when a ticket is started in an isolated worktree.'**
  String get branchTemplateDescription;

  /// No description provided for @branchTemplatePreview.
  ///
  /// In en, this message translates to:
  /// **'Example: {example}'**
  String branchTemplatePreview(String example);

  /// Title/label for deleting a pipeline run
  ///
  /// In en, this message translates to:
  /// **'Delete pipeline run'**
  String get deletePipelineRun;

  /// Confirmation body when deleting a pipeline run
  ///
  /// In en, this message translates to:
  /// **'Delete this run of \"{template}\"? This cannot be undone.'**
  String deletePipelineRunConfirm(String template);

  /// Error shown when deleting a pipeline run fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting pipeline run: {error}'**
  String errorDeletingPipelineRun(String error);

  /// Title/label for deleting a ticket
  ///
  /// In en, this message translates to:
  /// **'Delete ticket'**
  String get deleteTicket;

  /// Confirmation body when deleting a ticket
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String deleteTicketConfirm(String title);

  /// Error shown when deleting a ticket fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting ticket: {error}'**
  String errorDeletingTicket(String error);

  /// Confirmation body when deleting a workspace
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Linked repositories on disk are not touched.'**
  String deleteWorkspaceConfirm(String name);

  /// Error shown when deleting a workspace fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting workspace: {error}'**
  String errorDeletingWorkspace(String error);

  /// No description provided for @indexCode.
  ///
  /// In en, this message translates to:
  /// **'Index code'**
  String get indexCode;

  /// No description provided for @indexing.
  ///
  /// In en, this message translates to:
  /// **'Indexing…'**
  String get indexing;

  /// No description provided for @indexNoGrammars.
  ///
  /// In en, this message translates to:
  /// **'Code grammars not installed'**
  String get indexNoGrammars;

  /// No description provided for @indexFailed.
  ///
  /// In en, this message translates to:
  /// **'Indexing failed'**
  String get indexFailed;

  /// Tooltip shown after code indexing completes
  ///
  /// In en, this message translates to:
  /// **'{count} symbols indexed'**
  String indexedSymbolsCount(int count);

  /// No description provided for @nodeConfigAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get nodeConfigAdvanced;

  /// No description provided for @nodeConfigReducer.
  ///
  /// In en, this message translates to:
  /// **'Reducer'**
  String get nodeConfigReducer;

  /// No description provided for @nodeConfigReducerHelp.
  ///
  /// In en, this message translates to:
  /// **'How to merge when this output key already has a value'**
  String get nodeConfigReducerHelp;

  /// No description provided for @nodeConfigTimeoutMs.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get nodeConfigTimeoutMs;

  /// No description provided for @nodeConfigRetryAttempts.
  ///
  /// In en, this message translates to:
  /// **'Retry attempts'**
  String get nodeConfigRetryAttempts;

  /// No description provided for @nodeConfigContinueOnFail.
  ///
  /// In en, this message translates to:
  /// **'Continue if this step fails'**
  String get nodeConfigContinueOnFail;

  /// No description provided for @nodeConfigTeamId.
  ///
  /// In en, this message translates to:
  /// **'Team ID'**
  String get nodeConfigTeamId;

  /// No description provided for @nodeConfigDispatchMode.
  ///
  /// In en, this message translates to:
  /// **'Dispatch mode'**
  String get nodeConfigDispatchMode;

  /// No description provided for @nodeConfigOutputSchema.
  ///
  /// In en, this message translates to:
  /// **'Output schema (JSON)'**
  String get nodeConfigOutputSchema;

  /// No description provided for @nodeConfigOutputSchemaHelp.
  ///
  /// In en, this message translates to:
  /// **'JSON Schema the step output must satisfy'**
  String get nodeConfigOutputSchemaHelp;

  /// Settings label for the diff long-line overflow mode
  ///
  /// In en, this message translates to:
  /// **'Long lines in diffs'**
  String get diffLineDisplay;

  /// Settings subtitle for the diff long-line overflow mode
  ///
  /// In en, this message translates to:
  /// **'Wrap long lines or scroll them horizontally'**
  String get diffLineDisplayDescription;

  /// Diff overflow mode option: wrap long lines
  ///
  /// In en, this message translates to:
  /// **'Wrap'**
  String get diffLineWrap;

  /// Diff overflow mode option: scroll long lines horizontally
  ///
  /// In en, this message translates to:
  /// **'Scroll horizontally'**
  String get diffLineScroll;

  /// Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Button to activate a policy
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// Activity
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get activityLabel;

  /// Locale string for adRulesCount
  ///
  /// In en, this message translates to:
  /// **'{count} ad rules'**
  String adRulesCount(int count);

  /// Adapter
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get adapter;

  /// No description provided for @adapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get adapterLabel;

  /// Adapters
  ///
  /// In en, this message translates to:
  /// **'Adapters'**
  String get adapters;

  /// No description provided for @adaptersAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected agent runners available on this machine. Install any missing CLI tools to enable additional runners.'**
  String get adaptersAutoDetected;

  /// Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Add a comment
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addAComment;

  /// Add a reaction
  ///
  /// In en, this message translates to:
  /// **'Add a reaction'**
  String get addAReaction;

  /// Add a suggestion
  ///
  /// In en, this message translates to:
  /// **'Add a suggestion'**
  String get addASuggestion;

  /// Add agent
  ///
  /// In en, this message translates to:
  /// **'Add agent'**
  String get addAgent;

  /// Add agents
  ///
  /// In en, this message translates to:
  /// **'Add agents'**
  String get addAgents;

  /// No description provided for @addAgentsToEnable.
  ///
  /// In en, this message translates to:
  /// **'Add agents to enable multi-agent orchestration'**
  String get addAgentsToEnable;

  /// Add emoji
  ///
  /// In en, this message translates to:
  /// **'Add emoji'**
  String get addEmoji;

  /// Add feed
  ///
  /// In en, this message translates to:
  /// **'Add feed'**
  String get addFeed;

  /// Add from file
  ///
  /// In en, this message translates to:
  /// **'Add from file'**
  String get addFromFile;

  /// Add GIF
  ///
  /// In en, this message translates to:
  /// **'Add GIF'**
  String get addGif;

  /// No description provided for @addGithubRepoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add at least one GitHub repository to see pull requests'**
  String get addGithubRepoPrompt;

  /// Add a local checkout to start targeting it from this workspace.
  ///
  /// In en, this message translates to:
  /// **'Add a local checkout to start targeting it from this workspace.'**
  String get addLocalCheckoutDescription;

  /// Add repository
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get addRepository;

  /// Intro text for the web add-repo folder browser
  ///
  /// In en, this message translates to:
  /// **'Browse the folders on the machine running the server and choose a git checkout to register.'**
  String get addRepoBrowseIntro;

  /// Button that registers the folder the user has navigated into
  ///
  /// In en, this message translates to:
  /// **'Add this folder'**
  String get addThisFolder;

  /// Button that navigates to the parent directory
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get goUp;

  /// Shown when the browsed directory has no subfolders
  ///
  /// In en, this message translates to:
  /// **'No subfolders here'**
  String get noSubfoldersHere;

  /// Hint shown when the current folder cannot be registered as a repo
  ///
  /// In en, this message translates to:
  /// **'This folder isn\'t a git repository.'**
  String get notAGitRepository;

  /// Add token
  ///
  /// In en, this message translates to:
  /// **'Add token'**
  String get addToken;

  /// Add workspace
  ///
  /// In en, this message translates to:
  /// **'Add workspace'**
  String get addWorkspace;

  /// Add workspace…
  ///
  /// In en, this message translates to:
  /// **'Add workspace…'**
  String get addWorkspaceEllipsis;

  /// Added
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// Locale string for addingEllipsis
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get addingEllipsis;

  /// No description provided for @advancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedLabel;

  /// Agent
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// Agent count label
  ///
  /// In en, this message translates to:
  /// **'{count} agent{plural, plural, =1{} other{s}}'**
  String agentCount(int count, int plural);

  /// Agent MD Path
  ///
  /// In en, this message translates to:
  /// **'Agent MD path'**
  String get agentMdPath;

  /// Agent name
  ///
  /// In en, this message translates to:
  /// **'Agent name'**
  String get agentName;

  /// Agent title
  ///
  /// In en, this message translates to:
  /// **'Agent title'**
  String get agentTitle;

  /// Agent updated.
  ///
  /// In en, this message translates to:
  /// **'Agent updated.'**
  String get agentUpdated;

  /// Agents
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// Locale string for agentsCount
  ///
  /// In en, this message translates to:
  /// **'Agents ({count})'**
  String agentsCount(int count, num plural);

  /// No description provided for @agentsLabel.
  ///
  /// In en, this message translates to:
  /// **'AGENTS'**
  String get agentsLabel;

  /// No description provided for @agentsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsMentionSection;

  /// No description provided for @ticketsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsMentionSection;

  /// No description provided for @pullRequestsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get pullRequestsMentionSection;

  /// No description provided for @meetingsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get meetingsMentionSection;

  /// No description provided for @entityRefTicketFallback.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get entityRefTicketFallback;

  /// No description provided for @entityRefPrFallback.
  ///
  /// In en, this message translates to:
  /// **'Pull request'**
  String get entityRefPrFallback;

  /// No description provided for @entityRefMeetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get entityRefMeetingFallback;

  /// AI Review
  ///
  /// In en, this message translates to:
  /// **'AI review'**
  String get aiReview;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// All agents are already in this channel.
  ///
  /// In en, this message translates to:
  /// **'All agents are already in this channel.'**
  String get allAgentsAlreadyInChannel;

  /// Agents roster header
  ///
  /// In en, this message translates to:
  /// **'All agents · {count}'**
  String allAgentsCount(int count);

  /// All commits
  ///
  /// In en, this message translates to:
  /// **'All commits'**
  String get allCommits;

  /// No description provided for @allSessionsReset.
  ///
  /// In en, this message translates to:
  /// **'All sandbox sessions reset.'**
  String get allSessionsReset;

  /// Locale string for allSources
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @allStarBadge.
  ///
  /// In en, this message translates to:
  /// **'All-Star'**
  String get allStarBadge;

  /// No description provided for @allTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTimeLabel;

  /// Allow
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Allow git push
  ///
  /// In en, this message translates to:
  /// **'Allow git push'**
  String get allowGitPush;

  /// Allow GitHub API calls
  ///
  /// In en, this message translates to:
  /// **'Allow GitHub API calls'**
  String get allowGithubApi;

  /// Allow general network access
  ///
  /// In en, this message translates to:
  /// **'Allow general network access'**
  String get allowNetwork;

  /// API Keys
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get apiKeys;

  /// App font
  ///
  /// In en, this message translates to:
  /// **'App font'**
  String get appFont;

  /// Description for the debug app log level
  ///
  /// In en, this message translates to:
  /// **'Adds detailed traces - for development.'**
  String get appLogLevelDebugDescription;

  /// Label for the debug app log level
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get appLogLevelDebugLabel;

  /// Description for the error app log level
  ///
  /// In en, this message translates to:
  /// **'Only unexpected errors and exceptions.'**
  String get appLogLevelErrorDescription;

  /// Label for the error app log level
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get appLogLevelErrorLabel;

  /// Description for the info app log level
  ///
  /// In en, this message translates to:
  /// **'Adds lifecycle and status messages.'**
  String get appLogLevelInfoDescription;

  /// Label for the info app log level
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get appLogLevelInfoLabel;

  /// Description for the none app log level
  ///
  /// In en, this message translates to:
  /// **'No console output at all.'**
  String get appLogLevelNoneDescription;

  /// Label for the none app log level
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get appLogLevelNoneLabel;

  /// Description for the verbose app log level
  ///
  /// In en, this message translates to:
  /// **'Everything. Extremely noisy - use for debugging only.'**
  String get appLogLevelVerboseDescription;

  /// Label for the verbose app log level
  ///
  /// In en, this message translates to:
  /// **'Verbose'**
  String get appLogLevelVerboseLabel;

  /// Description for the warning app log level
  ///
  /// In en, this message translates to:
  /// **'Adds warnings and recoverable issues.'**
  String get appLogLevelWarningDescription;

  /// Label for the warning app log level
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get appLogLevelWarningLabel;

  /// Control Center
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get appTitle;

  /// No description provided for @appearanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get appearanceLanguage;

  /// Apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Approve
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// Approve and compact context
  ///
  /// In en, this message translates to:
  /// **'Approve and compact context'**
  String get approveAndCompact;

  /// Approve and execute
  ///
  /// In en, this message translates to:
  /// **'Approve and execute'**
  String get approveAndExecute;

  /// Approve & hire
  ///
  /// In en, this message translates to:
  /// **'Approve & hire'**
  String get approveAndHire;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @articlesSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Articles across your subscribed feeds.'**
  String get articlesSubscribed;

  /// Short label for the Ask AI review action (used in PR header overflow menu)
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAi;

  /// Ask AI Review
  ///
  /// In en, this message translates to:
  /// **'Ask AI review'**
  String get askAiReview;

  /// Ask AI to review this PR
  ///
  /// In en, this message translates to:
  /// **'Ask AI to review this PR'**
  String get askAiReviewDescription;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything… (@ to mention agents, / for commands)'**
  String get askAnything;

  /// No description provided for @assignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get assignees;

  /// Attach files
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get attachFiles;

  /// Attach image
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @attachedAgents.
  ///
  /// In en, this message translates to:
  /// **'Attached agents'**
  String get attachedAgents;

  /// Audio input
  ///
  /// In en, this message translates to:
  /// **'Audio input'**
  String get audioInput;

  /// Authentication
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// Authentication token
  ///
  /// In en, this message translates to:
  /// **'Authentication token'**
  String get authenticationToken;

  /// Authored by role label
  ///
  /// In en, this message translates to:
  /// **'By: {role}'**
  String authoredByLabel(String role);

  /// No description provided for @authorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get authorsLabel;

  /// Authors filter with count
  ///
  /// In en, this message translates to:
  /// **'Authors · {count}'**
  String authorsWithCount(int count);

  /// No description provided for @autoRecommended.
  ///
  /// In en, this message translates to:
  /// **'Auto (recommended)'**
  String get autoRecommended;

  /// Available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Avg duration
  ///
  /// In en, this message translates to:
  /// **'Avg duration'**
  String get avgDuration;

  /// No description provided for @awaitingYourApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your approval'**
  String get awaitingYourApproval;

  /// Awaiting your review
  ///
  /// In en, this message translates to:
  /// **'Awaiting your review'**
  String get awaitingYourReview;

  /// Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Backend
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backend;

  /// Block ads, trackers & cookie banners
  ///
  /// In en, this message translates to:
  /// **'Block ads, trackers & cookie banners'**
  String get blockAdsDescription;

  /// No description provided for @blockAdsTrackers.
  ///
  /// In en, this message translates to:
  /// **'Block ads, trackers & cookie banners'**
  String get blockAdsTrackers;

  /// Blocking
  ///
  /// In en, this message translates to:
  /// **'Blocking'**
  String get blocking;

  /// No description provided for @blockingLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocking'**
  String get blockingLabel;

  /// No description provided for @bookmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmarkLabel;

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief description'**
  String get briefDescription;

  /// No description provided for @bugLabel.
  ///
  /// In en, this message translates to:
  /// **'BUG'**
  String get bugLabel;

  /// Locale string for bundledDefaultsNeverUpdated
  ///
  /// In en, this message translates to:
  /// **'Bundled defaults — never updated'**
  String get bundledDefaultsNeverUpdated;

  /// Cached
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cached;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Tooltip to cancel editing a suggestion
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get cancelEdit;

  /// No description provided for @categoryCreation.
  ///
  /// In en, this message translates to:
  /// **'Creation'**
  String get categoryCreation;

  /// Locale string for categoryDeletion
  ///
  /// In en, this message translates to:
  /// **'Category deletion'**
  String get categoryDeletion;

  /// No description provided for @categoryEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get categoryEditing;

  /// No description provided for @categoryNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get categoryNavigation;

  /// No description provided for @categorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get categorySystem;

  /// Locale string for categoryView
  ///
  /// In en, this message translates to:
  /// **'Category view'**
  String get categoryView;

  /// No description provided for @centurionBadge.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get centurionBadge;

  /// Change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Changes requested
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get changesRequested;

  /// Changes summary
  ///
  /// In en, this message translates to:
  /// **'Changes summary'**
  String get changesSummary;

  /// No description provided for @channelsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channelsMentionSection;

  /// Check for updates
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// Checking
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @checkingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingEllipsis;

  /// No description provided for @checkingGhCli.
  ///
  /// In en, this message translates to:
  /// **'Checking gh CLI…'**
  String get checkingGhCli;

  /// No description provided for @chooseAppFont.
  ///
  /// In en, this message translates to:
  /// **'Choose app font'**
  String get chooseAppFont;

  /// No description provided for @chooseCodeFont.
  ///
  /// In en, this message translates to:
  /// **'Choose code font'**
  String get chooseCodeFont;

  /// Choose your agent runner.
  ///
  /// In en, this message translates to:
  /// **'Choose your agent runner.'**
  String get chooseRunner;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Tooltip for retry button when posting fails
  ///
  /// In en, this message translates to:
  /// **'Click to retry'**
  String get clickToRetry;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Close (Esc)
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get closeEsc;

  /// Locale string for closeKeyboardHint
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeKeyboardHint;

  /// Close panel
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get closePanel;

  /// Close reader
  ///
  /// In en, this message translates to:
  /// **'Close reader'**
  String get closeReader;

  /// Close thread
  ///
  /// In en, this message translates to:
  /// **'Close thread'**
  String get closeThread;

  /// Closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// Code font
  ///
  /// In en, this message translates to:
  /// **'Code font'**
  String get codeFont;

  /// No description provided for @codeFontLigatures.
  ///
  /// In en, this message translates to:
  /// **'Code font ligatures'**
  String get codeFontLigatures;

  /// No description provided for @codeFontLigaturesDescription.
  ///
  /// In en, this message translates to:
  /// **'Render programming ligatures (=>, !=, ->) as combined glyphs in code and diffs'**
  String get codeFontLigaturesDescription;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Command palette
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get commandPalette;

  /// Category header for org member command palette items
  ///
  /// In en, this message translates to:
  /// **'Organization members'**
  String get commandPaletteOrgMembers;

  /// Command palette item to browse all team members
  ///
  /// In en, this message translates to:
  /// **'Browse team'**
  String get commandPaletteBrowseTeam;

  /// Description for the Browse team command palette item
  ///
  /// In en, this message translates to:
  /// **'View all organization members'**
  String get commandPaletteBrowseTeamDesc;

  /// No description provided for @commandsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commandsMentionSection;

  /// Comment
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Comment on this file
  ///
  /// In en, this message translates to:
  /// **'Comment on this file'**
  String get commentOnFile;

  /// No description provided for @commentOnThisFile.
  ///
  /// In en, this message translates to:
  /// **'Comment on this file'**
  String get commentOnThisFile;

  /// Comment selected
  ///
  /// In en, this message translates to:
  /// **'Comment selected'**
  String get commentSelected;

  /// No description provided for @commented.
  ///
  /// In en, this message translates to:
  /// **'Commented'**
  String get commented;

  /// Commits
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get commits;

  /// Truncation notice in the commits tab when not all commits are loaded
  ///
  /// In en, this message translates to:
  /// **'Showing latest {loaded} of {total} commits'**
  String commitsShowingLatest(int loaded, int total);

  /// Title shown while cloning a large PR repository
  ///
  /// In en, this message translates to:
  /// **'Cloning repository'**
  String get prCloneProgressCloningTitle;

  /// Subtitle shown while cloning a large PR repository
  ///
  /// In en, this message translates to:
  /// **'This PR changes {fileCount} files, which exceeds GitHub\'s API limit. Cloning the repository locally…'**
  String prCloneProgressCloningSubtitle(int fileCount);

  /// Subtitle shown while cloning when file count is unknown
  ///
  /// In en, this message translates to:
  /// **'This PR exceeds GitHub\'s API file limit. Cloning the repository locally…'**
  String get prCloneProgressCloningSubtitleNoCount;

  /// Title shown while fetching PR refs for a large PR
  ///
  /// In en, this message translates to:
  /// **'Fetching PR refs'**
  String get prCloneProgressFetchingTitle;

  /// Subtitle shown while fetching PR refs
  ///
  /// In en, this message translates to:
  /// **'Fetching the base branch and PR head ref…'**
  String get prCloneProgressFetchingSubtitle;

  /// Title shown while computing the diff locally
  ///
  /// In en, this message translates to:
  /// **'Computing diff'**
  String get prCloneProgressComputingTitle;

  /// Subtitle shown while computing diff locally
  ///
  /// In en, this message translates to:
  /// **'Running git diff locally…'**
  String get prCloneProgressComputingSubtitle;

  /// Title shown when the local clone/diff pipeline fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load diff'**
  String get prCloneProgressErrorTitle;

  /// Subtitle shown when the local clone pipeline fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred while cloning or computing the diff. Please try refreshing.'**
  String get prCloneProgressErrorSubtitle;

  /// Reassurance line with elapsed time shown while a large PR clone runs
  ///
  /// In en, this message translates to:
  /// **'Still working… {elapsed} elapsed'**
  String prCloneProgressElapsed(String elapsed);

  /// Confidence percentage label
  ///
  /// In en, this message translates to:
  /// **'Confidence: {percent}%'**
  String confidenceLabel(int percent);

  /// No description provided for @configureAgentIdentities.
  ///
  /// In en, this message translates to:
  /// **'Configure agent identities, prompts, skills, and view runs.'**
  String get configureAgentIdentities;

  /// No description provided for @configureDefaultRunners.
  ///
  /// In en, this message translates to:
  /// **'Configure which adapter and model are used for new conversations and title generation.'**
  String get configureDefaultRunners;

  /// No description provided for @configuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Configured.'**
  String get configuredLabel;

  /// Label showing who confirmed a review
  ///
  /// In en, this message translates to:
  /// **'Confirmed by'**
  String get confirmedBy;

  /// No description provided for @consensus.
  ///
  /// In en, this message translates to:
  /// **'Consensus'**
  String get consensus;

  /// Description of the content blocking feature
  ///
  /// In en, this message translates to:
  /// **'Block ads, trackers and cookie banners'**
  String get contentBlockingDescription;

  /// Hint text for fact content field
  ///
  /// In en, this message translates to:
  /// **'What should be remembered'**
  String get contentHint;

  /// Label for fact content field
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @contentMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Content (Markdown)'**
  String get contentMarkdown;

  /// Locale string for contextWindowSize
  ///
  /// In en, this message translates to:
  /// **'Context window size'**
  String get contextWindowSize;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Conversation mode
  ///
  /// In en, this message translates to:
  /// **'Conversation mode'**
  String get conversationMode;

  /// No description provided for @convertToGroup.
  ///
  /// In en, this message translates to:
  /// **'Convert to group?'**
  String get convertToGroup;

  /// Adding another agent turns this into a group conversation.
  ///
  /// In en, this message translates to:
  /// **'Adding another agent turns this into a group conversation.'**
  String get convertToGroupBody;

  /// Locale string for cookieRulesCount
  ///
  /// In en, this message translates to:
  /// **'{count} cookie rules'**
  String cookieRulesCount(int count);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyBaseBranchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy base branch name'**
  String get copyBaseBranchTooltip;

  /// No description provided for @copyHeadBranchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy head branch name'**
  String get copyHeadBranchTooltip;

  /// No description provided for @couldNotCheckGhCli.
  ///
  /// In en, this message translates to:
  /// **'Could not check gh CLI.'**
  String get couldNotCheckGhCli;

  /// Could not list devices error
  ///
  /// In en, this message translates to:
  /// **'Could not list devices: {error}'**
  String couldNotListDevices(String error);

  /// Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Create your first agent to get started.
  ///
  /// In en, this message translates to:
  /// **'Create your first agent to get started.'**
  String get createFirstAgent;

  /// No description provided for @createOrSelectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create or select a workspace before adding repositories.'**
  String get createOrSelectWorkspace;

  /// Create PR
  ///
  /// In en, this message translates to:
  /// **'Create PR'**
  String get createPr;

  /// No description provided for @createPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Create pull request'**
  String get createPullRequest;

  /// Created by me
  ///
  /// In en, this message translates to:
  /// **'Created by me'**
  String get createdByMe;

  /// Created date label with value
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdLabel(String date);

  /// Current participants
  ///
  /// In en, this message translates to:
  /// **'Current participants'**
  String get currentParticipants;

  /// Locale string for customCapabilitiesDescription
  ///
  /// In en, this message translates to:
  /// **'Custom capabilities description'**
  String get customCapabilitiesDescription;

  /// No description provided for @customSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Custom system prompt for this agent...'**
  String get customSystemPrompt;

  /// Relative time: days ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// Button to deactivate a policy
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// Default capabilities · new conversations
  ///
  /// In en, this message translates to:
  /// **'Default capabilities · new conversations'**
  String get defaultCapabilities;

  /// Default chat
  ///
  /// In en, this message translates to:
  /// **'Default chat'**
  String get defaultChat;

  /// Default port label
  ///
  /// In en, this message translates to:
  /// **'Default: {port}.'**
  String defaultPort(int port);

  /// Default port number hint
  ///
  /// In en, this message translates to:
  /// **'Default: {port}.'**
  String defaultPortHint(int port);

  /// Default runners
  ///
  /// In en, this message translates to:
  /// **'Default runners'**
  String get defaultRunners;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Delete agent
  ///
  /// In en, this message translates to:
  /// **'Delete agent'**
  String get deleteAgent;

  /// Delete agent confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteAgentConfirm(String name);

  /// Delete channel
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get deleteChannel;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConfirmName(String name);

  /// Delete conversation
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation? All messages will be lost.'**
  String get deleteConversationConfirm;

  /// Delete fact
  ///
  /// In en, this message translates to:
  /// **'Delete fact'**
  String get deleteFact;

  /// No description provided for @deleteFeedBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the feed and all its cached articles. Bookmarked articles from this feed will also be removed.'**
  String get deleteFeedBody;

  /// Delete feed confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteFeedConfirm(String name);

  /// Delete "{name}"? All messages will be lost.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? All messages will be lost.'**
  String deleteNamedConversation(String name);

  /// Delete policy
  ///
  /// In en, this message translates to:
  /// **'Delete policy'**
  String get deletePolicy;

  /// Delete this policy? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete this policy? This cannot be undone.'**
  String get deletePolicyConfirm;

  /// Delete fact confirmation with topic name
  ///
  /// In en, this message translates to:
  /// **'Delete \"{topic}\"? This cannot be undone.'**
  String deleteTopicConfirm(String topic);

  /// Delete workspace
  ///
  /// In en, this message translates to:
  /// **'Delete workspace'**
  String get deleteWorkspace;

  /// Deny
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// Detected sandboxing backend
  ///
  /// In en, this message translates to:
  /// **'Detected: {label}'**
  String detectedBackend(String label);

  /// Section label showing count of detected runners
  ///
  /// In en, this message translates to:
  /// **'Detected runners ({count})'**
  String detectedRunners(int count);

  /// No description provided for @detectingAdapters.
  ///
  /// In en, this message translates to:
  /// **'Detecting adapters…'**
  String get detectingAdapters;

  /// No description provided for @detectingGhCli.
  ///
  /// In en, this message translates to:
  /// **'Detecting gh CLI…'**
  String get detectingGhCli;

  /// Detecting input devices…
  ///
  /// In en, this message translates to:
  /// **'Detecting input devices…'**
  String get detectingInputDevices;

  /// Sandboxing detection failure
  ///
  /// In en, this message translates to:
  /// **'Detection failed: {error}'**
  String detectionFailed(String error);

  /// Diff rendering error
  ///
  /// In en, this message translates to:
  /// **'Diff failed: {message}'**
  String diffFailed(String message);

  /// Worker pool
  ///
  /// In en, this message translates to:
  /// **'Worker pool'**
  String get diffWorkerPool;

  /// Direct message
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get directMessage;

  /// Direct messages
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get directMessages;

  /// Status label for disabled state
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Discover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Discover agents
  ///
  /// In en, this message translates to:
  /// **'Discover agents'**
  String get discoverAgents;

  /// Description of the agent discovery feature
  ///
  /// In en, this message translates to:
  /// **'Agent discovery scans workspace paths for AGENTS.md and TEAM.md files, parsing them into the agent registry.\n\nConfigure a workspace first, then use this feature to auto-populate agents.'**
  String get discoverAgentsDescription;

  /// No description provided for @dismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get dismissed;

  /// Hint text for domain field in fact edit
  ///
  /// In en, this message translates to:
  /// **'e.g. api-performance'**
  String get domainHint;

  /// Domain
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domainLabel;

  /// Download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadingLabel;

  /// Downloading progress for embedding model
  ///
  /// In en, this message translates to:
  /// **'Downloading model… {pct}%'**
  String downloadingModel(int pct);

  /// Draft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @draftLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftLabel;

  /// Earn tiers as you use the control center
  ///
  /// In en, this message translates to:
  /// **'Earn tiers as you use the control center'**
  String get earnTiersDescription;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Dialog title for editing a fact
  ///
  /// In en, this message translates to:
  /// **'Edit fact'**
  String get editFact;

  /// Dialog title for editing a policy
  ///
  /// In en, this message translates to:
  /// **'Edit policy'**
  String get editPolicy;

  /// Placeholder text in the suggested code editor
  ///
  /// In en, this message translates to:
  /// **'Edit suggested code…'**
  String get editSuggestedCodeHint;

  /// Tooltip to start editing a suggestion
  ///
  /// In en, this message translates to:
  /// **'Edit suggestion'**
  String get editSuggestion;

  /// Placeholder text in the fast diff suggestion code editor
  ///
  /// In en, this message translates to:
  /// **'Edit the suggested code…'**
  String get editTheSuggestedCodeHint;

  /// No description provided for @egArchitect.
  ///
  /// In en, this message translates to:
  /// **'e.g. architect'**
  String get egArchitect;

  /// e.g. control-center
  ///
  /// In en, this message translates to:
  /// **'e.g. control-center'**
  String get egControlCenter;

  /// Locale string for egPlatform
  ///
  /// In en, this message translates to:
  /// **'e.g. macOS'**
  String get egPlatform;

  /// e.g. SamuelAlev
  ///
  /// In en, this message translates to:
  /// **'e.g. SamuelAlev'**
  String get egSamuelAlev;

  /// No description provided for @egSoftwareArchitect.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Architect'**
  String get egSoftwareArchitect;

  /// No description provided for @egTheVerge.
  ///
  /// In en, this message translates to:
  /// **'e.g. The Verge'**
  String get egTheVerge;

  /// Locale string for egTokenLimit
  ///
  /// In en, this message translates to:
  /// **'e.g. 128000'**
  String get egTokenLimit;

  /// Embedding model install failure
  ///
  /// In en, this message translates to:
  /// **'Install failed: {error}'**
  String embeddingInstallFailed(String error);

  /// No description provided for @embeddingInstalled.
  ///
  /// In en, this message translates to:
  /// **'Local embedding model installed. Hybrid search is enabled.'**
  String get embeddingInstalled;

  /// Embedding model (ONNX)
  ///
  /// In en, this message translates to:
  /// **'Embedding model (ONNX)'**
  String get embeddingModel;

  /// No description provided for @embeddingNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed. Search falls back to keyword-only until enabled.'**
  String get embeddingNotInstalled;

  /// No description provided for @embeddingRedownloadBody.
  ///
  /// In en, this message translates to:
  /// **'The existing model files will be deleted and downloaded again. Semantic search will be unavailable until the download completes.'**
  String get embeddingRedownloadBody;

  /// No description provided for @embeddingRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Semantic search will be disabled until you reinstall it. You can install it again at any time.'**
  String get embeddingRemoveBody;

  /// No description provided for @speakerDiarization.
  ///
  /// In en, this message translates to:
  /// **'Speaker diarization'**
  String get speakerDiarization;

  /// No description provided for @diarizationModel.
  ///
  /// In en, this message translates to:
  /// **'Diarization model'**
  String get diarizationModel;

  /// No description provided for @diarizationInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed — names individual speakers in meeting transcripts'**
  String get diarizationInstalled;

  /// No description provided for @diarizationNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed — meeting speakers won\'t be separated'**
  String get diarizationNotInstalled;

  /// Diarization model install failure
  ///
  /// In en, this message translates to:
  /// **'Install failed: {error}'**
  String diarizationInstallFailed(String error);

  /// No description provided for @redownloadDiarizationModel.
  ///
  /// In en, this message translates to:
  /// **'Re-download diarization model'**
  String get redownloadDiarizationModel;

  /// No description provided for @diarizationRedownloadBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the current diarization models and downloads them again.'**
  String get diarizationRedownloadBody;

  /// No description provided for @removeDiarizationModel.
  ///
  /// In en, this message translates to:
  /// **'Remove diarization model'**
  String get removeDiarizationModel;

  /// No description provided for @diarizationRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the on-device diarization models. Meeting transcripts already produced are unaffected.'**
  String get diarizationRemoveBody;

  /// No description provided for @onboardingDiarizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaker diarization (optional)'**
  String get onboardingDiarizationTitle;

  /// No description provided for @onboardingDiarizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download to label individual speakers (Person 1, Person 2…) in meeting notes. You can add this later in settings.'**
  String get onboardingDiarizationSubtitle;

  /// Enable MCP Server
  ///
  /// In en, this message translates to:
  /// **'Enable MCP server'**
  String get enableMcpServer;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// Enable sandboxing
  ///
  /// In en, this message translates to:
  /// **'Enable sandboxing'**
  String get enableSandboxing;

  /// Status label for enabled state
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Token dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter {name} Token'**
  String enterToken(String name);

  /// No description provided for @enterTokenToAuth.
  ///
  /// In en, this message translates to:
  /// **'Enter a token to require authentication'**
  String get enterTokenToAuth;

  /// Error creating a new agent
  ///
  /// In en, this message translates to:
  /// **'Error creating agent: {error}'**
  String errorCreatingAgent(String error);

  /// Error deleting an agent
  ///
  /// In en, this message translates to:
  /// **'Error deleting agent: {error}'**
  String errorDeletingAgent(String error);

  /// Error message when agents fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading agents'**
  String get errorLoadingAgents;

  /// Error message with detail
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(String error);

  /// Errored
  ///
  /// In en, this message translates to:
  /// **'Errored'**
  String get errored;

  /// No description provided for @erroredLabel.
  ///
  /// In en, this message translates to:
  /// **'Errored'**
  String get erroredLabel;

  /// Exit selection
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get exitSelection;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @extractingLabel.
  ///
  /// In en, this message translates to:
  /// **'Extracting'**
  String get extractingLabel;

  /// Extraction progress for voice model
  ///
  /// In en, this message translates to:
  /// **'Extracting model… {pct}%'**
  String extractingModel(int pct);

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get fact;

  /// Single fact count in topic node
  ///
  /// In en, this message translates to:
  /// **'{count} fact'**
  String factCount(int count);

  /// Plural fact count in topic node
  ///
  /// In en, this message translates to:
  /// **'{count} facts'**
  String factCountPlural(int count);

  /// Facts
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get facts;

  /// Fact and policy count in domain node
  ///
  /// In en, this message translates to:
  /// **'{factCount} facts · {policyCount} policies'**
  String factsPoliciesCount(int factCount, int policyCount);

  /// Failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Error dispatching findings
  ///
  /// In en, this message translates to:
  /// **'Failed to dispatch: {error}'**
  String failedToDispatch(String error);

  /// Failed to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// Error loading agents list
  ///
  /// In en, this message translates to:
  /// **'Failed to load agents: {error}'**
  String failedToLoadAgents(String error);

  /// Error loading newsfeed
  ///
  /// In en, this message translates to:
  /// **'Failed to load feeds: {error}'**
  String failedToLoadFeeds(String error);

  /// Error message when GIF loading fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load GIFs'**
  String get failedToLoadGifs;

  /// Error loading agent logs
  ///
  /// In en, this message translates to:
  /// **'Failed to load logs: {error}'**
  String failedToLoadLogs(String error);

  /// No description provided for @failedToLoadRepos.
  ///
  /// In en, this message translates to:
  /// **'Failed to load repositories'**
  String get failedToLoadRepos;

  /// No description provided for @failedToLoadWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Failed to load workspaces'**
  String get failedToLoadWorkspaces;

  /// Error starting AI review
  ///
  /// In en, this message translates to:
  /// **'Failed to start AI review: {error}'**
  String failedToStartAiReview(String error);

  /// Failed to start mic test.
  ///
  /// In en, this message translates to:
  /// **'Failed to start mic test.'**
  String get failedToStartMicTest;

  /// Error submitting review
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review: {error}'**
  String failedToSubmitReview(String error);

  /// Error uploading file
  ///
  /// In en, this message translates to:
  /// **'Failed to upload {name}: {error}'**
  String failedToUpload(String name, String error);

  /// Generic error with details
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithError(String error);

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @feedAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A feed with this URL already exists.'**
  String get feedAlreadyExists;

  /// No description provided for @feedUrl.
  ///
  /// In en, this message translates to:
  /// **'Feed URL'**
  String get feedUrl;

  /// Locale string for feedUrlExample
  ///
  /// In en, this message translates to:
  /// **'e.g. https://example.com/feed.xml'**
  String get feedUrlExample;

  /// A feed with this URL already exists.
  ///
  /// In en, this message translates to:
  /// **'A feed with this URL already exists.'**
  String get feedUrlExists;

  /// No description provided for @feedUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed URL'**
  String get feedUrlLabel;

  /// Locale string for feedsCount
  ///
  /// In en, this message translates to:
  /// **'Feeds ({count})'**
  String feedsCount(int count);

  /// No description provided for @feedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feedsLabel;

  /// No description provided for @filesChanged.
  ///
  /// In en, this message translates to:
  /// **'Files changed'**
  String get filesChanged;

  /// Locale string for filesCount
  ///
  /// In en, this message translates to:
  /// **'{count} file(s)'**
  String filesCount(int count);

  /// No description provided for @filesMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesMentionSection;

  /// No description provided for @filterAgents.
  ///
  /// In en, this message translates to:
  /// **'Filter agents...'**
  String get filterAgents;

  /// No description provided for @filterAgentsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Filter agents…'**
  String get filterAgentsPlaceholder;

  /// Placeholder text in the file filter field
  ///
  /// In en, this message translates to:
  /// **'Filter files…'**
  String get filterFilesHint;

  /// No description provided for @filterLists.
  ///
  /// In en, this message translates to:
  /// **'Filter lists'**
  String get filterLists;

  /// No description provided for @filterSkillsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Filter skills…'**
  String get filterSkillsPlaceholder;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @firstReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'First review'**
  String get firstReviewBadge;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @fixSelected.
  ///
  /// In en, this message translates to:
  /// **'Fix selected'**
  String get fixSelected;

  /// No description provided for @flawlessBadge.
  ///
  /// In en, this message translates to:
  /// **'Flawless'**
  String get flawlessBadge;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @gatesGithubPatPush.
  ///
  /// In en, this message translates to:
  /// **'Gates GitHub PAT injection. Required for the agent to push.'**
  String get gatesGithubPatPush;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generalSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Appearance, typography, integrations, and MCP server.'**
  String get generalSettingsDescription;

  /// GitHub CLI is authenticated and ready, but a personal access token is set below and will be used instead. Clear the PAT to use gh CLI auth.
  ///
  /// In en, this message translates to:
  /// **'GitHub CLI is authenticated and ready, but a personal access token is set below and will be used instead. Clear the PAT to use gh CLI auth.'**
  String get ghCliAuthButPatOverrideBody;

  /// No description provided for @ghCliInstalledAuth.
  ///
  /// In en, this message translates to:
  /// **'Installed. Run `gh auth login`, then tap Refresh.'**
  String get ghCliInstalledAuth;

  /// No description provided for @ghCliNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'gh CLI not installed — install from cli.github.com.'**
  String get ghCliNotInstalled;

  /// gh CLI not installed
  ///
  /// In en, this message translates to:
  /// **'gh CLI not installed'**
  String get ghCliNotInstalledLabel;

  /// No description provided for @githubCli.
  ///
  /// In en, this message translates to:
  /// **'GitHub CLI'**
  String get githubCli;

  /// No description provided for @githubCliIntegration.
  ///
  /// In en, this message translates to:
  /// **'GitHub CLI integration'**
  String get githubCliIntegration;

  /// No description provided for @githubCliReady.
  ///
  /// In en, this message translates to:
  /// **'GitHub CLI is authenticated and ready.'**
  String get githubCliReady;

  /// No description provided for @githubLink.
  ///
  /// In en, this message translates to:
  /// **'GitHub link'**
  String get githubLink;

  /// No description provided for @githubPersonalAccessToken.
  ///
  /// In en, this message translates to:
  /// **'GitHub personal access token'**
  String get githubPersonalAccessToken;

  /// GitHub status: every component is healthy
  ///
  /// In en, this message translates to:
  /// **'All systems operational'**
  String get githubStatusAllOperational;

  /// Header for the list of GitHub components in the status flyout
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get githubStatusComponents;

  /// Shown in the GitHub status flyout when the fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach githubstatus.com'**
  String get githubStatusFetchFailed;

  /// Header above the active GitHub incidents list
  ///
  /// In en, this message translates to:
  /// **'Active incidents'**
  String get githubStatusIncidents;

  /// Button label to open githubstatus.com in the browser
  ///
  /// In en, this message translates to:
  /// **'Open githubstatus.com'**
  String get githubStatusOpenInBrowser;

  /// Button label to refresh the GitHub status
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get githubStatusRefresh;

  /// Title of the GitHub status indicator and flyout
  ///
  /// In en, this message translates to:
  /// **'GitHub status'**
  String get githubStatusTitle;

  /// Relative time the GitHub status was last refreshed
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String githubStatusUpdated(String time);

  /// Relative time a screen's data was last refreshed
  ///
  /// In en, this message translates to:
  /// **'Checked {time}'**
  String lastChecked(String time);

  /// Freshness label shown when data was checked less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Checked recently'**
  String get lastCheckedRecently;

  /// No description provided for @githubToken.
  ///
  /// In en, this message translates to:
  /// **'GitHub token'**
  String get githubToken;

  /// No description provided for @giveAgentsAMemory.
  ///
  /// In en, this message translates to:
  /// **'Give agents a memory.'**
  String get giveAgentsAMemory;

  /// No description provided for @giveYourWorkAHome.
  ///
  /// In en, this message translates to:
  /// **'Give your work a home.'**
  String get giveYourWorkAHome;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @goForward.
  ///
  /// In en, this message translates to:
  /// **'Go forward'**
  String get goForward;

  /// No description provided for @googleFonts.
  ///
  /// In en, this message translates to:
  /// **'Google fonts'**
  String get googleFonts;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// Group name
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// Hide container terminal
  ///
  /// In en, this message translates to:
  /// **'Hide container terminal'**
  String get hideContainerTerminal;

  /// Tooltip to close the conversation changes (diff) panel
  ///
  /// In en, this message translates to:
  /// **'Hide changes'**
  String get hideConversationChanges;

  /// Tooltip to open the conversation changes (diff) panel
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get showConversationChanges;

  /// Empty-state message when a conversation has no uncommitted changes
  ///
  /// In en, this message translates to:
  /// **'No uncommitted changes in this conversation yet.'**
  String get noConversationChanges;

  /// Title for the conversation changes (diff) side panel
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get conversationChangesTitle;

  /// Locale string for high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @hotStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'Hot streak'**
  String get hotStreakBadge;

  /// Relative time: hours ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @idleStatus.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idleStatus;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// Locale string for inFlightLabel
  ///
  /// In en, this message translates to:
  /// **'In flight'**
  String get inFlightLabel;

  /// Label for inactive policies
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Install gh from https://cli.github.com/ and run `gh auth login`, then tap Refresh.
  ///
  /// In en, this message translates to:
  /// **'Install gh from https://cli.github.com/ and run `gh auth login`, then tap Refresh.'**
  String get installGhCliBody;

  /// Locale string for installRequired
  ///
  /// In en, this message translates to:
  /// **'Installation required'**
  String get installRequired;

  /// Installed - not signed in
  ///
  /// In en, this message translates to:
  /// **'Installed - not signed in'**
  String get installedNotSignedIn;

  /// Installed version label
  ///
  /// In en, this message translates to:
  /// **'Installed {version}'**
  String installedVersion(String version);

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// Invite agent
  ///
  /// In en, this message translates to:
  /// **'Invite agent'**
  String get inviteAgent;

  /// No description provided for @isolateAgentExecution.
  ///
  /// In en, this message translates to:
  /// **'Isolate agent execution.'**
  String get isolateAgentExecution;

  /// Locale string for jobCount
  ///
  /// In en, this message translates to:
  /// **'{count} job{count, plural, =1{} other{s}}'**
  String jobCount(int count);

  /// Relative time: less than a few seconds ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @keepMessages.
  ///
  /// In en, this message translates to:
  /// **'Keep messages'**
  String get keepMessages;

  /// No description provided for @keepSandboxing.
  ///
  /// In en, this message translates to:
  /// **'Keep sandboxing'**
  String get keepSandboxing;

  /// Locale string for keybindingAdapters
  ///
  /// In en, this message translates to:
  /// **'Adapters'**
  String get keybindingAdapters;

  /// Locale string for keybindingAddARepositoryDescription
  ///
  /// In en, this message translates to:
  /// **'Add a repository'**
  String get keybindingAddARepositoryDescription;

  /// Locale string for keybindingAddRepository
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get keybindingAddRepository;

  /// Locale string for keybindingAgents
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get keybindingAgents;

  /// Locale string for keybindingApprove
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get keybindingApprove;

  /// Locale string for keybindingApproveThePeerReviewDescription
  ///
  /// In en, this message translates to:
  /// **'Approve the peer review'**
  String get keybindingApproveThePeerReviewDescription;

  /// Locale string for keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Bookmark or unbookmark the selected article'**
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription;

  /// Locale string for keybindingCommandPalette
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get keybindingCommandPalette;

  /// Locale string for keybindingConversationTab
  ///
  /// In en, this message translates to:
  /// **'Conversation tab'**
  String get keybindingConversationTab;

  /// Locale string for keybindingCreateANewAgentDescription
  ///
  /// In en, this message translates to:
  /// **'Create a new agent'**
  String get keybindingCreateANewAgentDescription;

  /// Locale string for keybindingCreateANewGroupChannelDescription
  ///
  /// In en, this message translates to:
  /// **'Create a new group channel'**
  String get keybindingCreateANewGroupChannelDescription;

  /// Locale string for keybindingCreateANewWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Create a new workspace'**
  String get keybindingCreateANewWorkspaceDescription;

  /// Locale string for keybindingDeleteAgent
  ///
  /// In en, this message translates to:
  /// **'Delete agent'**
  String get keybindingDeleteAgent;

  /// Locale string for keybindingDeleteChannel
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get keybindingDeleteChannel;

  /// Locale string for keybindingDeleteTheSelectedAgentDescription
  ///
  /// In en, this message translates to:
  /// **'Delete the selected agent'**
  String get keybindingDeleteTheSelectedAgentDescription;

  /// Locale string for keybindingDeleteTheSelectedChannelDescription
  ///
  /// In en, this message translates to:
  /// **'Delete the selected channel'**
  String get keybindingDeleteTheSelectedChannelDescription;

  /// Locale string for keybindingDeleteTheSelectedWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Delete the selected workspace'**
  String get keybindingDeleteTheSelectedWorkspaceDescription;

  /// Locale string for keybindingDeleteWorkspace
  ///
  /// In en, this message translates to:
  /// **'Delete workspace'**
  String get keybindingDeleteWorkspace;

  /// Locale string for keybindingFilesChangedTab
  ///
  /// In en, this message translates to:
  /// **'Files changed tab'**
  String get keybindingFilesChangedTab;

  /// Locale string for keybindingFocusSearch
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get keybindingFocusSearch;

  /// Locale string for keybindingFocusThePullRequestSearchFieldDescription
  ///
  /// In en, this message translates to:
  /// **'Focus the pull request search field'**
  String get keybindingFocusThePullRequestSearchFieldDescription;

  /// Locale string for keybindingGeneral
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get keybindingGeneral;

  /// Locale string for keybindingGoToAgents
  ///
  /// In en, this message translates to:
  /// **'Go to Agents'**
  String get keybindingGoToAgents;

  /// Locale string for keybindingGoToAnalytics
  ///
  /// In en, this message translates to:
  /// **'Go to Analytics'**
  String get keybindingGoToAnalytics;

  /// Locale string for keybindingGoToDashboard
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get keybindingGoToDashboard;

  /// Locale string for keybindingGoToMemory
  ///
  /// In en, this message translates to:
  /// **'Go to Memory'**
  String get keybindingGoToMemory;

  /// Locale string for keybindingGoToNewsfeed
  ///
  /// In en, this message translates to:
  /// **'Go to Newsfeed'**
  String get keybindingGoToNewsfeed;

  /// Locale string for keybindingGoToPipelines
  ///
  /// In en, this message translates to:
  /// **'Go to Pipelines'**
  String get keybindingGoToPipelines;

  /// Locale string for keybindingGoToPullRequests
  ///
  /// In en, this message translates to:
  /// **'Go to Pull Requests'**
  String get keybindingGoToPullRequests;

  /// Locale string for keybindingGoToTickets
  ///
  /// In en, this message translates to:
  /// **'Go to Tickets'**
  String get keybindingGoToTickets;

  /// Locale string for keybindingKeybindings
  ///
  /// In en, this message translates to:
  /// **'Keybindings'**
  String get keybindingKeybindings;

  /// Locale string for keybindingNavigateToTheAgentsRegistryDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the agents registry'**
  String get keybindingNavigateToTheAgentsRegistryDescription;

  /// Locale string for keybindingNavigateToTheAnalyticsDashboardDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the analytics dashboard'**
  String get keybindingNavigateToTheAnalyticsDashboardDescription;

  /// Locale string for keybindingNavigateToTheGlobalDashboardDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the global dashboard'**
  String get keybindingNavigateToTheGlobalDashboardDescription;

  /// Locale string for keybindingNavigateToTheMemoryDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the memory knowledge base'**
  String get keybindingNavigateToTheMemoryDescription;

  /// Locale string for keybindingNavigateToTheNewsfeedDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the newsfeed'**
  String get keybindingNavigateToTheNewsfeedDescription;

  /// Locale string for keybindingNavigateToThePipelinesListDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the pipelines list'**
  String get keybindingNavigateToThePipelinesListDescription;

  /// Locale string for keybindingNavigateToThePullRequestListDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the pull request list'**
  String get keybindingNavigateToThePullRequestListDescription;

  /// Locale string for keybindingNavigateToTheTicketsBoardDescription
  ///
  /// In en, this message translates to:
  /// **'Navigate to the tickets board'**
  String get keybindingNavigateToTheTicketsBoardDescription;

  /// Locale string for keybindingNewAgent
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get keybindingNewAgent;

  /// Locale string for keybindingNewDirectMessage
  ///
  /// In en, this message translates to:
  /// **'New direct message'**
  String get keybindingNewDirectMessage;

  /// Locale string for keybindingNewGroup
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get keybindingNewGroup;

  /// Locale string for keybindingNewWorkspace
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get keybindingNewWorkspace;

  /// Locale string for keybindingNextArticle
  ///
  /// In en, this message translates to:
  /// **'Next article'**
  String get keybindingNextArticle;

  /// Locale string for keybindingNextChannel
  ///
  /// In en, this message translates to:
  /// **'Next channel'**
  String get keybindingNextChannel;

  /// Locale string for keybindingNextPr
  ///
  /// In en, this message translates to:
  /// **'Next PR'**
  String get keybindingNextPr;

  /// Locale string for keybindingNextWorkspace
  ///
  /// In en, this message translates to:
  /// **'Next workspace'**
  String get keybindingNextWorkspace;

  /// Locale string for keybindingOpenArticle
  ///
  /// In en, this message translates to:
  /// **'Open article'**
  String get keybindingOpenArticle;

  /// Locale string for keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription
  ///
  /// In en, this message translates to:
  /// **'Open or close the workspace switcher popup in the sidebar'**
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription;

  /// Locale string for keybindingOpenPr
  ///
  /// In en, this message translates to:
  /// **'Open PR'**
  String get keybindingOpenPr;

  /// Locale string for keybindingOpenSettings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get keybindingOpenSettings;

  /// Locale string for keybindingOpenTheAdaptersSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the Adapters settings page'**
  String get keybindingOpenTheAdaptersSettingsPageDescription;

  /// Locale string for keybindingOpenTheAgentsSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the Agents settings page'**
  String get keybindingOpenTheAgentsSettingsPageDescription;

  /// Locale string for keybindingOpenTheApplicationSettingsDescription
  ///
  /// In en, this message translates to:
  /// **'Open the application settings'**
  String get keybindingOpenTheApplicationSettingsDescription;

  /// Locale string for keybindingOpenTheCommandPaletteDescription
  ///
  /// In en, this message translates to:
  /// **'Open the command palette'**
  String get keybindingOpenTheCommandPaletteDescription;

  /// Locale string for keybindingOpenTheGeneralSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the General settings page'**
  String get keybindingOpenTheGeneralSettingsPageDescription;

  /// Locale string for keybindingOpenTheKeybindingsSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the Keybindings settings page'**
  String get keybindingOpenTheKeybindingsSettingsPageDescription;

  /// Locale string for keybindingOpenTheRepositoriesSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the Repositories settings page'**
  String get keybindingOpenTheRepositoriesSettingsPageDescription;

  /// Locale string for keybindingOpenTheSelectedArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Open the selected article'**
  String get keybindingOpenTheSelectedArticleDescription;

  /// Locale string for keybindingOpenTheSelectedPullRequestDescription
  ///
  /// In en, this message translates to:
  /// **'Open the selected pull request'**
  String get keybindingOpenTheSelectedPullRequestDescription;

  /// Locale string for keybindingOpenTheSelectedWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Open the selected workspace'**
  String get keybindingOpenTheSelectedWorkspaceDescription;

  /// Locale string for keybindingOpenTheSkillsSettingsPageDescription
  ///
  /// In en, this message translates to:
  /// **'Open the Skills settings page'**
  String get keybindingOpenTheSkillsSettingsPageDescription;

  /// Locale string for keybindingOpenWorkspace
  ///
  /// In en, this message translates to:
  /// **'Open workspace'**
  String get keybindingOpenWorkspace;

  /// Locale string for keybindingPreviousArticle
  ///
  /// In en, this message translates to:
  /// **'Previous article'**
  String get keybindingPreviousArticle;

  /// Locale string for keybindingPreviousChannel
  ///
  /// In en, this message translates to:
  /// **'Previous channel'**
  String get keybindingPreviousChannel;

  /// Locale string for keybindingPreviousPr
  ///
  /// In en, this message translates to:
  /// **'Previous PR'**
  String get keybindingPreviousPr;

  /// Locale string for keybindingPreviousWorkspace
  ///
  /// In en, this message translates to:
  /// **'Previous workspace'**
  String get keybindingPreviousWorkspace;

  /// Locale string for keybindingRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get keybindingRefresh;

  /// Locale string for keybindingRefreshAllFeedsDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh all feeds'**
  String get keybindingRefreshAllFeedsDescription;

  /// Locale string for keybindingRefreshAnalyticsDataDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh analytics data'**
  String get keybindingRefreshAnalyticsDataDescription;

  /// Locale string for keybindingRefreshDashboardDataDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh dashboard data'**
  String get keybindingRefreshDashboardDataDescription;

  /// Locale string for keybindingRefreshThePullRequestListDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh the pull request list'**
  String get keybindingRefreshThePullRequestListDescription;

  /// Locale string for keybindingRemoveRepository
  ///
  /// In en, this message translates to:
  /// **'Remove repository'**
  String get keybindingRemoveRepository;

  /// Locale string for keybindingRemoveTheSelectedRepositoryDescription
  ///
  /// In en, this message translates to:
  /// **'Remove the selected repository'**
  String get keybindingRemoveTheSelectedRepositoryDescription;

  /// Locale string for keybindingRepositories
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get keybindingRepositories;

  /// Locale string for keybindingRequestChanges
  ///
  /// In en, this message translates to:
  /// **'Request changes'**
  String get keybindingRequestChanges;

  /// Locale string for keybindingRequestChangesOnThePeerReviewDescription
  ///
  /// In en, this message translates to:
  /// **'Request changes on the peer review'**
  String get keybindingRequestChangesOnThePeerReviewDescription;

  /// Locale string for keybindingRescanForAdaptersDescription
  ///
  /// In en, this message translates to:
  /// **'Rescan for adapters'**
  String get keybindingRescanForAdaptersDescription;

  /// Locale string for keybindingSearchInDiff
  ///
  /// In en, this message translates to:
  /// **'Search in diff'**
  String get keybindingSearchInDiff;

  /// Locale string for keybindingSearchWithinTheDiffViewDescription
  ///
  /// In en, this message translates to:
  /// **'Search within the diff view'**
  String get keybindingSearchWithinTheDiffViewDescription;

  /// Locale string for keybindingToggleViewed
  ///
  /// In en, this message translates to:
  /// **'Toggle viewed'**
  String get keybindingToggleViewed;

  /// Locale string for keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription
  ///
  /// In en, this message translates to:
  /// **'Mark the focused file as viewed or unviewed'**
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription;

  /// Locale string for keybindingToggleCollapse
  ///
  /// In en, this message translates to:
  /// **'Toggle collapse'**
  String get keybindingToggleCollapse;

  /// Locale string for keybindingCollapseOrExpandTheFocusedFileDescription
  ///
  /// In en, this message translates to:
  /// **'Collapse or expand the focused file'**
  String get keybindingCollapseOrExpandTheFocusedFileDescription;

  /// Locale string for keybindingSelectTheNextArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Select the next article'**
  String get keybindingSelectTheNextArticleDescription;

  /// Locale string for keybindingSelectTheNextChannelDescription
  ///
  /// In en, this message translates to:
  /// **'Select the next channel'**
  String get keybindingSelectTheNextChannelDescription;

  /// Locale string for keybindingSelectTheNextPullRequestDescription
  ///
  /// In en, this message translates to:
  /// **'Select the next pull request'**
  String get keybindingSelectTheNextPullRequestDescription;

  /// Locale string for keybindingSelectThePreviousArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Select the previous article'**
  String get keybindingSelectThePreviousArticleDescription;

  /// Locale string for keybindingSelectThePreviousChannelDescription
  ///
  /// In en, this message translates to:
  /// **'Select the previous channel'**
  String get keybindingSelectThePreviousChannelDescription;

  /// Locale string for keybindingSelectThePreviousPullRequestDescription
  ///
  /// In en, this message translates to:
  /// **'Select the previous pull request'**
  String get keybindingSelectThePreviousPullRequestDescription;

  /// Locale string for keybindingSendMessage
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get keybindingSendMessage;

  /// Locale string for keybindingSendTheCurrentMessageDescription
  ///
  /// In en, this message translates to:
  /// **'Send the current message'**
  String get keybindingSendTheCurrentMessageDescription;

  /// Locale string for keybindingSkills
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get keybindingSkills;

  /// Locale string for keybindingStartANewDirectMessageDescription
  ///
  /// In en, this message translates to:
  /// **'Start a new direct message'**
  String get keybindingStartANewDirectMessageDescription;

  /// Locale string for keybindingSwitchBetweenLightAndDarkModeDescription
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark mode'**
  String get keybindingSwitchBetweenLightAndDarkModeDescription;

  /// Locale string for keybindingSwitchToTheConversationTabDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the conversation tab'**
  String get keybindingSwitchToTheConversationTabDescription;

  /// Locale string for keybindingSwitchToTheEighthWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the eighth workspace'**
  String get keybindingSwitchToTheEighthWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheFifthWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the fifth workspace'**
  String get keybindingSwitchToTheFifthWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheFilesChangedTabDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the files changed tab'**
  String get keybindingSwitchToTheFilesChangedTabDescription;

  /// Locale string for keybindingSwitchToTheFirstWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the first workspace'**
  String get keybindingSwitchToTheFirstWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheFourthWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the fourth workspace'**
  String get keybindingSwitchToTheFourthWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheNextWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the next workspace'**
  String get keybindingSwitchToTheNextWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheNinthWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the ninth workspace'**
  String get keybindingSwitchToTheNinthWorkspaceDescription;

  /// Locale string for keybindingSwitchToThePreviousWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the previous workspace'**
  String get keybindingSwitchToThePreviousWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheSecondWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the second workspace'**
  String get keybindingSwitchToTheSecondWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheSeventhWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the seventh workspace'**
  String get keybindingSwitchToTheSeventhWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheSixthWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the sixth workspace'**
  String get keybindingSwitchToTheSixthWorkspaceDescription;

  /// Locale string for keybindingSwitchToTheThirdWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Switch to the third workspace'**
  String get keybindingSwitchToTheThirdWorkspaceDescription;

  /// Locale string for keybindingToggleBookmark
  ///
  /// In en, this message translates to:
  /// **'Toggle bookmark'**
  String get keybindingToggleBookmark;

  /// Locale string for keybindingToggleTheme
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get keybindingToggleTheme;

  /// Locale string for keybindingToggleWorkspaceSwitcher
  ///
  /// In en, this message translates to:
  /// **'Toggle workspace switcher'**
  String get keybindingToggleWorkspaceSwitcher;

  /// Locale string for keybindingWorkspace1
  ///
  /// In en, this message translates to:
  /// **'Workspace 1'**
  String get keybindingWorkspace1;

  /// Locale string for keybindingWorkspace2
  ///
  /// In en, this message translates to:
  /// **'Workspace 2'**
  String get keybindingWorkspace2;

  /// Locale string for keybindingWorkspace3
  ///
  /// In en, this message translates to:
  /// **'Workspace 3'**
  String get keybindingWorkspace3;

  /// Locale string for keybindingWorkspace4
  ///
  /// In en, this message translates to:
  /// **'Workspace 4'**
  String get keybindingWorkspace4;

  /// Locale string for keybindingWorkspace5
  ///
  /// In en, this message translates to:
  /// **'Workspace 5'**
  String get keybindingWorkspace5;

  /// Locale string for keybindingWorkspace6
  ///
  /// In en, this message translates to:
  /// **'Workspace 6'**
  String get keybindingWorkspace6;

  /// Locale string for keybindingWorkspace7
  ///
  /// In en, this message translates to:
  /// **'Workspace 7'**
  String get keybindingWorkspace7;

  /// Locale string for keybindingWorkspace8
  ///
  /// In en, this message translates to:
  /// **'Workspace 8'**
  String get keybindingWorkspace8;

  /// Locale string for keybindingWorkspace9
  ///
  /// In en, this message translates to:
  /// **'Workspace 9'**
  String get keybindingWorkspace9;

  /// No description provided for @keybindings.
  ///
  /// In en, this message translates to:
  /// **'Keybindings'**
  String get keybindings;

  /// All keyboard shortcuts. Shortcuts are fixed and cannot be reassigned.
  ///
  /// In en, this message translates to:
  /// **'All keyboard shortcuts. Shortcuts are fixed and cannot be reassigned.'**
  String get keybindingsDescription;

  /// No description provided for @killRunning.
  ///
  /// In en, this message translates to:
  /// **'Kill running'**
  String get killRunning;

  /// Title when Klipy API key is missing
  ///
  /// In en, this message translates to:
  /// **'KLIPY_APP_KEY not configured'**
  String get klipyNotConfigured;

  /// Instructions for configuring Klipy API key
  ///
  /// In en, this message translates to:
  /// **'Pass --dart-define=KLIPY_APP_KEY=...\nor set it in .env before running.'**
  String get klipyNotConfiguredHint;

  /// Dutch language option
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Italian language option
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// Portuguese language option
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Option to use the system locale
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Last N months label for heatmap
  ///
  /// In en, this message translates to:
  /// **'Last {count} months'**
  String lastMonths(int count);

  /// No description provided for @latestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestLabel;

  /// No description provided for @leaderboardLabel.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get leaderboardLabel;

  /// No description provided for @leaderboardLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardLabelShort;

  /// Placeholder text in the comment composer
  ///
  /// In en, this message translates to:
  /// **'Leave a comment…'**
  String get leaveACommentEllipsis;

  /// Legend heading in knowledge graph
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legendLabel;

  /// No description provided for @lessLabel.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get lessLabel;

  /// No description provided for @letsPluginTools.
  ///
  /// In en, this message translates to:
  /// **'Let\'s plug in your tools.'**
  String get letsPluginTools;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Achievement level
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @loadingAgents.
  ///
  /// In en, this message translates to:
  /// **'Loading agents…'**
  String get loadingAgents;

  /// No description provided for @loadingModels.
  ///
  /// In en, this message translates to:
  /// **'Loading models…'**
  String get loadingModels;

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get logLevel;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// Locale string for low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @manageParticipants.
  ///
  /// In en, this message translates to:
  /// **'Manage participants'**
  String get manageParticipants;

  /// No description provided for @createTicketFromConversation.
  ///
  /// In en, this message translates to:
  /// **'Create ticket from conversation'**
  String get createTicketFromConversation;

  /// No description provided for @manageWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Manage workspaces'**
  String get manageWorkspaces;

  /// No description provided for @masterToggle.
  ///
  /// In en, this message translates to:
  /// **'Master toggle'**
  String get masterToggle;

  /// No description provided for @matchOsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Match your OS appearance or pick a fixed mode.'**
  String get matchOsAppearance;

  /// No description provided for @mcpActiveAccepting.
  ///
  /// In en, this message translates to:
  /// **'MCP server is active and accepting connections.'**
  String get mcpActiveAccepting;

  /// No description provided for @mcpAuthToken.
  ///
  /// In en, this message translates to:
  /// **'MCP authentication token'**
  String get mcpAuthToken;

  /// No description provided for @mcpAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get mcpAuthentication;

  /// When off, the server stays stopped until you start it.
  ///
  /// In en, this message translates to:
  /// **'When off, the server stays stopped until you start it.'**
  String get mcpAutoStartDescription;

  /// Default port number hint
  ///
  /// In en, this message translates to:
  /// **'Default: {port}'**
  String mcpDefaultPort(int port);

  /// MCP server status when running
  ///
  /// In en, this message translates to:
  /// **'Listening on 127.0.0.1:{port}'**
  String mcpListeningOn(int port);

  /// MCP server listening status with port
  ///
  /// In en, this message translates to:
  /// **'Listening on 127.0.0.1:{port}.'**
  String mcpListeningOnPort(int port);

  /// No description provided for @mcpNotAvailableOnServer.
  ///
  /// In en, this message translates to:
  /// **'MCP server control is not available on the connected server.'**
  String get mcpNotAvailableOnServer;

  /// Placeholder shown in a model settings section (embedding/diarization/voice) when the connected server does not host an on-device model, so install/uninstall isn't available from this client.
  ///
  /// In en, this message translates to:
  /// **'This model runs on the server host and is managed there.'**
  String get modelManagedOnServer;

  /// No description provided for @mcpNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Server is not running. Start it to enable MCP connections.'**
  String get mcpNotRunning;

  /// No description provided for @mcpRestartPortChanges.
  ///
  /// In en, this message translates to:
  /// **'Server must be restarted to apply port changes.'**
  String get mcpRestartPortChanges;

  /// No description provided for @mcpServer.
  ///
  /// In en, this message translates to:
  /// **'MCP server'**
  String get mcpServer;

  /// No description provided for @mcpServerStopped.
  ///
  /// In en, this message translates to:
  /// **'Server is stopped'**
  String get mcpServerStopped;

  /// No description provided for @mcpStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get mcpStatus;

  /// Locale string for medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// Hint text for empty knowledge graph
  ///
  /// In en, this message translates to:
  /// **'Facts and policies will appear here as agents work.'**
  String get memoryDataHint;

  /// No description provided for @memoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryLabel;

  /// Short label for the merge pull request action button
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @mergeMasterBadge.
  ///
  /// In en, this message translates to:
  /// **'Merge master'**
  String get mergeMasterBadge;

  /// No description provided for @merged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get merged;

  /// No description provided for @messagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message… (@ to mention, / for commands)'**
  String get messagePlaceholder;

  /// No description provided for @navConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get navConversations;

  /// Microphone permission denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get microphonePermissionDenied;

  /// Relative time: minutes ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// Relative time: months ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String monthsAgo(int count);

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// No description provided for @mozillaUserAgent.
  ///
  /// In en, this message translates to:
  /// **'Mozilla/5.0 …'**
  String get mozillaUserAgent;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameAndTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and title are required.'**
  String get nameAndTitleRequired;

  /// Locale string for nameAndUrlRequired
  ///
  /// In en, this message translates to:
  /// **'Name and URL required'**
  String get nameAndUrlRequired;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Locale string for nativeSandboxAvailable
  ///
  /// In en, this message translates to:
  /// **'Native sandbox is available on {platform}.'**
  String nativeSandboxAvailable(String platform);

  /// Locale string for nativeSandboxNeedsInstall
  ///
  /// In en, this message translates to:
  /// **'Native sandbox installation required'**
  String get nativeSandboxNeedsInstall;

  /// Analytics
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// Dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Saved
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Locale string for navigateLabel
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigateLabel;

  /// Locale string for networkBlockCount
  ///
  /// In en, this message translates to:
  /// **'{count} network blocks'**
  String networkBlockCount(int count);

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @newAgent.
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get newAgent;

  /// No description provided for @newCommitsPushed.
  ///
  /// In en, this message translates to:
  /// **'New commits were pushed — click to reload the diff'**
  String get newCommitsPushed;

  /// Dialog title for creating a new fact
  ///
  /// In en, this message translates to:
  /// **'New fact'**
  String get newFact;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// Dialog title for creating a new policy
  ///
  /// In en, this message translates to:
  /// **'New policy'**
  String get newPolicy;

  /// New PR to review
  ///
  /// In en, this message translates to:
  /// **'New PR to review'**
  String get newPrToReview;

  /// No description provided for @newsfeed.
  ///
  /// In en, this message translates to:
  /// **'Newsfeed'**
  String get newsfeed;

  /// Label for the newsfeed section
  ///
  /// In en, this message translates to:
  /// **'Newsfeed'**
  String get newsfeedLabel;

  /// No description provided for @newsfeedSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscribed feeds and reader preferences.'**
  String get newsfeedSettingsDescription;

  /// No description provided for @newsfeedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Newsfeed settings'**
  String get newsfeedSettingsTitle;

  /// No description provided for @nextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match (↵)'**
  String get nextMatch;

  /// Empty state for access matrix when no grants
  ///
  /// In en, this message translates to:
  /// **'No access grants configured'**
  String get noAccessGrants;

  /// No description provided for @noActiveWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No active workspace or repo selected.'**
  String get noActiveWorkspace;

  /// No description provided for @noActiveWorkspaceCreate.
  ///
  /// In en, this message translates to:
  /// **'No active workspace'**
  String get noActiveWorkspaceCreate;

  /// No description provided for @noActiveWorkspaceGithub.
  ///
  /// In en, this message translates to:
  /// **'No active workspace with a GitHub repo.'**
  String get noActiveWorkspaceGithub;

  /// Locale string for noAgentAssigned
  ///
  /// In en, this message translates to:
  /// **'No agent assigned'**
  String get noAgentAssigned;

  /// No description provided for @noAgentProcessesRunning.
  ///
  /// In en, this message translates to:
  /// **'No agent processes running'**
  String get noAgentProcessesRunning;

  /// No description provided for @noAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents'**
  String get noAgents;

  /// No description provided for @noAgentsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No agents configured'**
  String get noAgentsConfigured;

  /// Message when no agents have been discovered
  ///
  /// In en, this message translates to:
  /// **'No agents discovered'**
  String get noAgentsDiscovered;

  /// Hint text for when no agents are discovered
  ///
  /// In en, this message translates to:
  /// **'Click \"Discover\" to scan for AGENTS.md files or \"Add Agent\" to configure one manually'**
  String get noAgentsDiscoveredHint;

  /// No description provided for @noAgentsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No agents match your search'**
  String get noAgentsMatchSearch;

  /// No description provided for @noAgentsRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'No agents registered yet'**
  String get noAgentsRegisteredYet;

  /// Locale string for noArticlesYet
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get noArticlesYet;

  /// Empty state body for newsfeed articles
  ///
  /// In en, this message translates to:
  /// **'Articles from your feeds will appear here.'**
  String get noArticlesYetBody;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noDirectMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No direct messages yet'**
  String get noDirectMessagesYet;

  /// Empty state for access matrix when no domains
  ///
  /// In en, this message translates to:
  /// **'No domains yet'**
  String get noDomains;

  /// No execution logs yet
  ///
  /// In en, this message translates to:
  /// **'No execution logs yet'**
  String get noExecutionLogsYet;

  /// Empty state for facts tab
  ///
  /// In en, this message translates to:
  /// **'No facts yet'**
  String get noFacts;

  /// Locale string for noFeedsYet
  ///
  /// In en, this message translates to:
  /// **'No feeds yet'**
  String get noFeedsYet;

  /// No description provided for @noFileAnchor.
  ///
  /// In en, this message translates to:
  /// **'No file anchor — cannot post inline comment.'**
  String get noFileAnchor;

  /// Empty state when no file changes exist in the selected scope
  ///
  /// In en, this message translates to:
  /// **'No file changes in this scope'**
  String get noFileChangesInScope;

  /// Empty state when no GIFs match the search
  ///
  /// In en, this message translates to:
  /// **'No GIFs found'**
  String get noGifsFound;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No input devices detected — using system default.
  ///
  /// In en, this message translates to:
  /// **'No input devices detected — using system default.'**
  String get noInputDevicesDetected;

  /// Empty state when no files match the filter
  ///
  /// In en, this message translates to:
  /// **'No matching files'**
  String get noMatchingFiles;

  /// No description provided for @noMatchingGoogleFonts.
  ///
  /// In en, this message translates to:
  /// **'No matching Google Fonts.'**
  String get noMatchingGoogleFonts;

  /// Empty state for knowledge graph
  ///
  /// In en, this message translates to:
  /// **'No memory data yet'**
  String get noMemoryData;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noModelsAdvertised.
  ///
  /// In en, this message translates to:
  /// **'No models advertised by this adapter.'**
  String get noModelsAdvertised;

  /// No description provided for @noOpenPullRequests.
  ///
  /// In en, this message translates to:
  /// **'No open pull requests'**
  String get noOpenPullRequests;

  /// Empty state for policies tab
  ///
  /// In en, this message translates to:
  /// **'No policies yet'**
  String get noPolicies;

  /// No repositories in this workspace yet
  ///
  /// In en, this message translates to:
  /// **'No repositories in this workspace yet'**
  String get noReposInWorkspaceYet;

  /// No description provided for @noRunnersDetected.
  ///
  /// In en, this message translates to:
  /// **'No runners detected yet. Refresh to scan again.'**
  String get noRunnersDetected;

  /// Locale string for noSavedArticles
  ///
  /// In en, this message translates to:
  /// **'No saved articles'**
  String get noSavedArticles;

  /// Empty state body for saved articles
  ///
  /// In en, this message translates to:
  /// **'Articles you save will appear here.'**
  String get noSavedArticlesBody;

  /// Empty state in keybindings search
  ///
  /// In en, this message translates to:
  /// **'No shortcuts match \"{query}\"'**
  String noShortcutsMatch(String query);

  /// No description provided for @noSystemFonts.
  ///
  /// In en, this message translates to:
  /// **'No system fonts detected.'**
  String get noSystemFonts;

  /// No token set — access is unrestricted.
  ///
  /// In en, this message translates to:
  /// **'No token set — access is unrestricted.'**
  String get noTokenSet;

  /// No description provided for @noTokenSetUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'No token set — access is unrestricted.'**
  String get noTokenSetUnrestricted;

  /// No description provided for @noTokenUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'No token — access is unrestricted'**
  String get noTokenUnrestricted;

  /// Empty state for agent working memory
  ///
  /// In en, this message translates to:
  /// **'No working memory notes yet.'**
  String get noWorkingMemory;

  /// No description provided for @noneAllRoles.
  ///
  /// In en, this message translates to:
  /// **'None (all roles)'**
  String get noneAllRoles;

  /// Not available status label
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @notConfiguredLabel.
  ///
  /// In en, this message translates to:
  /// **'Not configured.'**
  String get notConfiguredLabel;

  /// Not detected status label
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get notDetected;

  /// Locale string for notEarnedYet
  ///
  /// In en, this message translates to:
  /// **'Not earned yet'**
  String get notEarnedYet;

  /// Not found status label
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFoundLabel;

  /// Locale string for notYetSpawned
  ///
  /// In en, this message translates to:
  /// **'Not yet spawned'**
  String get notYetSpawned;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notificationAgentFinished.
  ///
  /// In en, this message translates to:
  /// **'Agent finished'**
  String get notificationAgentFinished;

  /// No description provided for @notificationExternalPr.
  ///
  /// In en, this message translates to:
  /// **'External PRs'**
  String get notificationExternalPr;

  /// No description provided for @notificationNewMessages.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get notificationNewMessages;

  /// No description provided for @notificationPrMerged.
  ///
  /// In en, this message translates to:
  /// **'PR merged'**
  String get notificationPrMerged;

  /// No description provided for @notificationPrPublished.
  ///
  /// In en, this message translates to:
  /// **'PR published'**
  String get notificationPrPublished;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifyAgentRunCompleted.
  ///
  /// In en, this message translates to:
  /// **'Notify when an agent completes a run.'**
  String get notifyAgentRunCompleted;

  /// No description provided for @notifyExternalPr.
  ///
  /// In en, this message translates to:
  /// **'Notify when a new PR is detected from polling.'**
  String get notifyExternalPr;

  /// No description provided for @notifyNewMessages.
  ///
  /// In en, this message translates to:
  /// **'Notify on new agent messages in other channels.'**
  String get notifyNewMessages;

  /// No description provided for @notifyPrMerged.
  ///
  /// In en, this message translates to:
  /// **'Notify when a pull request is merged.'**
  String get notifyPrMerged;

  /// No description provided for @notifyPrPublished.
  ///
  /// In en, this message translates to:
  /// **'Notify when an agent publishes a pull request.'**
  String get notifyPrPublished;

  /// Locale string for onboardingLinuxDescription
  ///
  /// In en, this message translates to:
  /// **'Control Center can use Linux containers to isolate agent execution.'**
  String get onboardingLinuxDescription;

  /// Locale string for onboardingMacosDescription
  ///
  /// In en, this message translates to:
  /// **'Control Center uses native sandbox on macOS to isolate agent execution.'**
  String get onboardingMacosDescription;

  /// Locale string for onboardingUnsupportedDescription
  ///
  /// In en, this message translates to:
  /// **'Sandbox is not available on this platform. Agent execution will be without isolation.'**
  String get onboardingUnsupportedDescription;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @openApplicationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open application settings'**
  String get openApplicationSettings;

  /// Fallback action to open an article in the external browser
  ///
  /// In en, this message translates to:
  /// **'Open article in browser'**
  String get openArticlesBrowserFallback;

  /// No description provided for @openArticlesInApp.
  ///
  /// In en, this message translates to:
  /// **'Open articles in app'**
  String get openArticlesInApp;

  /// Open container terminal
  ///
  /// In en, this message translates to:
  /// **'Open container terminal'**
  String get openContainerTerminal;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @openOnGithub.
  ///
  /// In en, this message translates to:
  /// **'Open on GitHub'**
  String get openOnGithub;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// Optional persona description
  ///
  /// In en, this message translates to:
  /// **'Optional persona description'**
  String get optionalPersonaDescription;

  /// No description provided for @otherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLabel;

  /// Owner / Organization
  ///
  /// In en, this message translates to:
  /// **'Owner / Organization'**
  String get ownerOrganization;

  /// No description provided for @p0.
  ///
  /// In en, this message translates to:
  /// **'P0'**
  String get p0;

  /// No description provided for @p1.
  ///
  /// In en, this message translates to:
  /// **'P1'**
  String get p1;

  /// No description provided for @p2.
  ///
  /// In en, this message translates to:
  /// **'P2'**
  String get p2;

  /// No description provided for @p3.
  ///
  /// In en, this message translates to:
  /// **'P3'**
  String get p3;

  /// Parsing diff…
  ///
  /// In en, this message translates to:
  /// **'Parsing diff…'**
  String get parsingDiff;

  /// Passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// Paste token here
  ///
  /// In en, this message translates to:
  /// **'Paste token here'**
  String get pasteTokenHere;

  /// Paste value here
  ///
  /// In en, this message translates to:
  /// **'Paste value here'**
  String get pasteValueHere;

  /// No description provided for @patNotNeededGhCli.
  ///
  /// In en, this message translates to:
  /// **'Not needed — gh CLI is signed in.'**
  String get patNotNeededGhCli;

  /// No description provided for @patOverridesGhCli.
  ///
  /// In en, this message translates to:
  /// **'Configured — overrides gh CLI.'**
  String get patOverridesGhCli;

  /// Path
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathLabel;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending your approval'**
  String get pendingApproval;

  /// No description provided for @perfectionistBadge.
  ///
  /// In en, this message translates to:
  /// **'Perfectionist'**
  String get perfectionistBadge;

  /// Locale string for persona
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get persona;

  /// Persona label with colon
  ///
  /// In en, this message translates to:
  /// **'Persona:'**
  String get personaColon;

  /// Persona (optional)
  ///
  /// In en, this message translates to:
  /// **'Persona (optional)'**
  String get personaOptional;

  /// Personal access token (optional)
  ///
  /// In en, this message translates to:
  /// **'Personal access token (optional)'**
  String get personalAccessTokenOptional;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// Policies
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policies;

  /// Hint text for empty policies tab
  ///
  /// In en, this message translates to:
  /// **'Policies will appear here once agents promote facts.'**
  String get policiesHint;

  /// Policy
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get policy;

  /// Popular
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// Port
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// Badge text while a comment is being posted
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get postingEllipsis;

  /// No description provided for @prCommits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get prCommits;

  /// No description provided for @prDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'PR description in markdown...'**
  String get prDescriptionPlaceholder;

  /// PR draft created
  ///
  /// In en, this message translates to:
  /// **'PR draft created'**
  String get prDraftCreated;

  /// No description provided for @prMachineBadge.
  ///
  /// In en, this message translates to:
  /// **'PR machine'**
  String get prMachineBadge;

  /// A pull request was merged
  ///
  /// In en, this message translates to:
  /// **'A pull request was merged'**
  String get prMergedBody;

  /// Tooltip on the overflow menu button in the PR detail header
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get prMoreActions;

  /// PR title
  ///
  /// In en, this message translates to:
  /// **'PR title'**
  String get prTitle;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// Previous article
  ///
  /// In en, this message translates to:
  /// **'Previous article'**
  String get previousArticle;

  /// Previous channel
  ///
  /// In en, this message translates to:
  /// **'Previous channel'**
  String get previousChannel;

  /// Previous match (⇧↵)
  ///
  /// In en, this message translates to:
  /// **'Previous match (⇧↵)'**
  String get previousMatch;

  /// Previous PR
  ///
  /// In en, this message translates to:
  /// **'Previous PR'**
  String get previousPr;

  /// Previous workspace
  ///
  /// In en, this message translates to:
  /// **'Previous workspace'**
  String get previousWorkspace;

  /// Priority reviews
  ///
  /// In en, this message translates to:
  /// **'Priority reviews'**
  String get priorityReviews;

  /// No description provided for @priorityReviewsDescription.
  ///
  /// In en, this message translates to:
  /// **'Priority reviews and repository overview.'**
  String get priorityReviewsDescription;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// Hint text when no domains in access matrix
  ///
  /// In en, this message translates to:
  /// **'Propose a fact or policy to create one.'**
  String get proposeToCreateDomain;

  /// PRs created
  ///
  /// In en, this message translates to:
  /// **'PRs created'**
  String get prsCreated;

  /// No description provided for @prsCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'PRs created'**
  String get prsCreatedLabel;

  /// PRs merged
  ///
  /// In en, this message translates to:
  /// **'PRs merged'**
  String get prsMerged;

  /// Publish to GitHub
  ///
  /// In en, this message translates to:
  /// **'Publish to GitHub'**
  String get publishToGithub;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// Pull request approved
  ///
  /// In en, this message translates to:
  /// **'Pull request approved'**
  String get pullRequestApproved;

  /// Pull requests
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get pullRequests;

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get questionLabel;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get react;

  /// No description provided for @readPrsIssuesMetadata.
  ///
  /// In en, this message translates to:
  /// **'Lets the agent read PRs, issues, and repo metadata.'**
  String get readPrsIssuesMetadata;

  /// Reader preferences
  ///
  /// In en, this message translates to:
  /// **'Reader preferences'**
  String get readerPreferences;

  /// Locale string for reasoningEffort
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort'**
  String get reasoningEffort;

  /// No description provided for @recommendLabel.
  ///
  /// In en, this message translates to:
  /// **'RECOMMEND'**
  String get recommendLabel;

  /// Recording from a specific device
  ///
  /// In en, this message translates to:
  /// **'Recording from {device}.'**
  String recordingFromDevice(String device);

  /// Redownload
  ///
  /// In en, this message translates to:
  /// **'Redownload'**
  String get redownload;

  /// No description provided for @redownloadEmbeddingModel.
  ///
  /// In en, this message translates to:
  /// **'Redownload the embedding model?'**
  String get redownloadEmbeddingModel;

  /// No description provided for @redownloadVoiceModel.
  ///
  /// In en, this message translates to:
  /// **'Redownload the voice model?'**
  String get redownloadVoiceModel;

  /// Refine plan
  ///
  /// In en, this message translates to:
  /// **'Refine plan'**
  String get refinePlan;

  /// No description provided for @refiningPlan.
  ///
  /// In en, this message translates to:
  /// **'Refining plan…'**
  String get refiningPlan;

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Refresh all
  ///
  /// In en, this message translates to:
  /// **'Refresh all'**
  String get refreshAll;

  /// Refresh all feeds
  ///
  /// In en, this message translates to:
  /// **'Refresh all feeds'**
  String get refreshAllFeeds;

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// Refresh PR data
  ///
  /// In en, this message translates to:
  /// **'Refresh PR data'**
  String get refreshPrData;

  /// Reject
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Reload
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @removeEmbeddingModel.
  ///
  /// In en, this message translates to:
  /// **'Remove the embedding model?'**
  String get removeEmbeddingModel;

  /// Remove logo
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get removeLogo;

  /// No description provided for @removeRepoFromWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Remove repository from workspace?'**
  String get removeRepoFromWorkspace;

  /// Remove repository
  ///
  /// In en, this message translates to:
  /// **'Remove repository'**
  String get removeRepository;

  /// Remove repository from workspace?
  ///
  /// In en, this message translates to:
  /// **'Remove repository from workspace?'**
  String get removeRepositoryConfirm;

  /// No description provided for @removeVoiceModel.
  ///
  /// In en, this message translates to:
  /// **'Remove the voice model?'**
  String get removeVoiceModel;

  /// Removed
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// Renamed
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get renamed;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// Reply…
  ///
  /// In en, this message translates to:
  /// **'Reply…'**
  String get replyEllipsis;

  /// Confirmation body for removing a repo
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this workspace. The local files on disk are not touched.'**
  String repoRemovedFromWorkspace(String name);

  /// No description provided for @reportsTo.
  ///
  /// In en, this message translates to:
  /// **'Reports to'**
  String get reportsTo;

  /// No description provided for @reportsToOptional.
  ///
  /// In en, this message translates to:
  /// **'Reports to (optional)'**
  String get reportsToOptional;

  /// Section label with repo count
  ///
  /// In en, this message translates to:
  /// **'Repositories ({count})'**
  String reposCount(int count);

  /// The local checkouts this workspace targets.
  ///
  /// In en, this message translates to:
  /// **'The local checkouts this workspace targets.'**
  String get reposDescription;

  /// Repositories
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get repositories;

  /// Repositories settings
  ///
  /// In en, this message translates to:
  /// **'Repositories settings'**
  String get repositoriesSettings;

  /// Repository name
  ///
  /// In en, this message translates to:
  /// **'Repository name'**
  String get repositoryName;

  /// Request changes
  ///
  /// In en, this message translates to:
  /// **'Request changes'**
  String get requestChanges;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @requestedChanges.
  ///
  /// In en, this message translates to:
  /// **'Requested changes'**
  String get requestedChanges;

  /// Required if gh CLI is not available
  ///
  /// In en, this message translates to:
  /// **'Required if gh CLI is not available'**
  String get requiredIfGhCliUnavailable;

  /// Required role label with value
  ///
  /// In en, this message translates to:
  /// **'Required role: {role}'**
  String requiredRoleLabel(String role);

  /// Label for required role dropdown in policy edit
  ///
  /// In en, this message translates to:
  /// **'Required role (optional)'**
  String get requiredRoleOptional;

  /// Requirements
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Reset all sandboxes
  ///
  /// In en, this message translates to:
  /// **'Reset all sandboxes'**
  String get resetAllSandboxes;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// Restart the server to apply changes.
  ///
  /// In en, this message translates to:
  /// **'Restart the server to apply changes.'**
  String get restartServerToApply;

  /// Restart shell
  ///
  /// In en, this message translates to:
  /// **'Restart shell'**
  String get restartShell;

  /// No description provided for @restartToApply.
  ///
  /// In en, this message translates to:
  /// **'Restart the server to apply changes.'**
  String get restartToApply;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewChanges.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get reviewChanges;

  /// Reviewed by me
  ///
  /// In en, this message translates to:
  /// **'Reviewed by me'**
  String get reviewedByMe;

  /// No description provided for @reviewers.
  ///
  /// In en, this message translates to:
  /// **'Reviewers'**
  String get reviewers;

  /// No description provided for @reviewersActive.
  ///
  /// In en, this message translates to:
  /// **'Reviewers active'**
  String get reviewersActive;

  /// Reviews
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsLabel;

  /// Table header for role column in access matrix
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Hint text for policy rule field
  ///
  /// In en, this message translates to:
  /// **'The policy rule (markdown supported)'**
  String get ruleHint;

  /// Label for policy rule field
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get ruleLabel;

  /// Run completed
  ///
  /// In en, this message translates to:
  /// **'Run completed'**
  String get runCompleted;

  /// Run `gh auth login` in your terminal, then tap Refresh.
  ///
  /// In en, this message translates to:
  /// **'Run `gh auth login` in your terminal, then tap Refresh.'**
  String get runGhAuthLoginBody;

  /// Running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// running label
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get runningLabel;

  /// No description provided for @runningStatus.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runningStatus;

  /// Runs
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runs;

  /// No description provided for @runsAcrossAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Runs across all agents'**
  String get runsAcrossAllAgents;

  /// Runs label
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runsLabel;

  /// Label for the native sandbox backend
  ///
  /// In en, this message translates to:
  /// **'Native sandbox'**
  String get sandboxBackendNativeLabel;

  /// Label for the no isolation sandbox backend
  ///
  /// In en, this message translates to:
  /// **'No isolation'**
  String get sandboxBackendNoneLabel;

  /// Native sandbox on Linux/WSL2 uses bubblewrap. Install with package manager.
  ///
  /// In en, this message translates to:
  /// **'Native sandbox on Linux/WSL2 uses bubblewrap. Install with:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch'**
  String get sandboxLinuxInstall;

  /// Native sandbox is built in on macOS - uses Apple Seatbelt (`sandbox-exec`). No install required.
  ///
  /// In en, this message translates to:
  /// **'Native sandbox is built in on macOS - uses Apple Seatbelt (`sandbox-exec`). No install required.'**
  String get sandboxMacosBuiltIn;

  /// Locale string for sandboxPermissions
  ///
  /// In en, this message translates to:
  /// **'Sandbox permissions'**
  String get sandboxPermissions;

  /// Native sandbox is not supported on this platform yet. Falls back to No isolation.
  ///
  /// In en, this message translates to:
  /// **'Native sandbox is not supported on this platform yet. Falls back to \"No isolation\".'**
  String get sandboxUnsupported;

  /// Sandboxing
  ///
  /// In en, this message translates to:
  /// **'Sandboxing'**
  String get sandboxing;

  /// Run agents inside an OS-level sandbox so they can't touch your home folder, SSH keys, or tokens you haven't granted.
  ///
  /// In en, this message translates to:
  /// **'Run agents inside an OS-level sandbox so they can\'t touch your home folder, SSH keys, or tokens you haven\'t granted.'**
  String get sandboxingDescription;

  /// Agents run directly on the host with full env - not recommended.
  ///
  /// In en, this message translates to:
  /// **'Agents run directly on the host with full env - not recommended.'**
  String get sandboxingDisabledDescription;

  /// All agent invocations route through a backend.
  ///
  /// In en, this message translates to:
  /// **'All agent invocations route through {backend}.'**
  String sandboxingEnabledDescription(String backend);

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Locale string for saveChanges
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Extra CLI flags appended to an adapter launch
  ///
  /// In en, this message translates to:
  /// **'Extra arguments'**
  String get adapterArguments;

  /// Hint for the adapter extra-arguments field
  ///
  /// In en, this message translates to:
  /// **'Additional CLI flags (e.g. --yolo)'**
  String get adapterArgumentsHint;

  /// Add an environment variable row
  ///
  /// In en, this message translates to:
  /// **'Add variable'**
  String get addVariable;

  /// Per-adapter environment variables editor title
  ///
  /// In en, this message translates to:
  /// **'Environment variables'**
  String get environmentVariables;

  /// Per-adapter environment variables editor description
  ///
  /// In en, this message translates to:
  /// **'Custom environment variables passed to this adapter (e.g. API keys). Stored in the keychain.'**
  String get environmentVariablesDescription;

  /// Reset the adapter arguments to the default
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// Environment variable key label
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get variableKey;

  /// Environment variable value label
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get variableValue;

  /// No description provided for @savedArticlesDescription.
  ///
  /// In en, this message translates to:
  /// **'Articles you bookmarked.'**
  String get savedArticlesDescription;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// Locale string for savingChanges
  ///
  /// In en, this message translates to:
  /// **'Saving changes…'**
  String get savingChanges;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingEllipsis;

  /// No description provided for @scopeDiffToCommits.
  ///
  /// In en, this message translates to:
  /// **'Scope diff to commits — Shift-click for range'**
  String get scopeDiffToCommits;

  /// Search agents
  ///
  /// In en, this message translates to:
  /// **'Search agents'**
  String get searchAgents;

  /// No description provided for @searchAuthors.
  ///
  /// In en, this message translates to:
  /// **'Search authors…'**
  String get searchAuthors;

  /// PR queue search field / empty-search state
  ///
  /// In en, this message translates to:
  /// **'Search… e.g. author:@user'**
  String get searchPullRequestsHint;

  /// PR queue search field / empty-search state
  ///
  /// In en, this message translates to:
  /// **'No matching pull requests'**
  String get noPrsMatchSearch;

  /// PR queue search field / empty-search state
  ///
  /// In en, this message translates to:
  /// **'No open PRs match your search. Try different terms or clear the search.'**
  String get noPrsMatchSearchHint;

  /// No description provided for @searchAuthorsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search authors…'**
  String get searchAuthorsPlaceholder;

  /// Search field hint in facts tab
  ///
  /// In en, this message translates to:
  /// **'Search facts...'**
  String get searchFactsHint;

  /// Search fonts…
  ///
  /// In en, this message translates to:
  /// **'Search fonts…'**
  String get searchFonts;

  /// Title of the GIF search picker
  ///
  /// In en, this message translates to:
  /// **'Search GIFs'**
  String get searchGifs;

  /// Placeholder text in the GIF search field
  ///
  /// In en, this message translates to:
  /// **'Search GIFs...'**
  String get searchGifsHint;

  /// Search in diff
  ///
  /// In en, this message translates to:
  /// **'Search in diff'**
  String get searchInDiff;

  /// Placeholder text in the diff search field
  ///
  /// In en, this message translates to:
  /// **'Search in diff…'**
  String get searchInDiffHint;

  /// No description provided for @searchOrTypeModel.
  ///
  /// In en, this message translates to:
  /// **'Search or type a model name…'**
  String get searchOrTypeModel;

  /// Locale string for searchPlaceholder
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchPlaceholder;

  /// Search shortcuts…
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts…'**
  String get searchShortcuts;

  /// Locale string for searching
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searching;

  /// Relative time: seconds ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second ago} other{{count} seconds ago}}'**
  String secondsAgo(int count);

  /// Select adapter
  ///
  /// In en, this message translates to:
  /// **'Select adapter'**
  String get selectAdapter;

  /// No description provided for @selectAdapterFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an adapter first'**
  String get selectAdapterFirst;

  /// No description provided for @selectAgentToReportTo.
  ///
  /// In en, this message translates to:
  /// **'Select agent to report to…'**
  String get selectAgentToReportTo;

  /// Select an agent
  ///
  /// In en, this message translates to:
  /// **'Select an agent'**
  String get selectAnAgent;

  /// Select a conversation
  ///
  /// In en, this message translates to:
  /// **'Select a conversation'**
  String get selectConversation;

  /// No description provided for @selectEffortLevel.
  ///
  /// In en, this message translates to:
  /// **'Select effort level'**
  String get selectEffortLevel;

  /// Select
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLabel;

  /// Select a runner
  ///
  /// In en, this message translates to:
  /// **'Select a runner'**
  String get selectRunner;

  /// Semantic search
  ///
  /// In en, this message translates to:
  /// **'Semantic search'**
  String get semanticSearch;

  /// Send
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send the first message'**
  String get sendFirstMessage;

  /// Send message
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Confirmation after sending findings to agent
  ///
  /// In en, this message translates to:
  /// **'Sent {count} finding(s) to agent.'**
  String sentFindingsToAgent(int count);

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Server running'**
  String get serverRunning;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Server stopped'**
  String get serverStopped;

  /// Set the GitHub owner and repository name for {name}. This is used to resolve PR and issue references like #123 in markdown content.
  ///
  /// In en, this message translates to:
  /// **'Set the GitHub owner and repository name for {name}. This is used to resolve PR and issue references like #123 in markdown content.'**
  String setGithubLinkDescription(String name);

  /// Generic set button label
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// Button to set an auth token
  ///
  /// In en, this message translates to:
  /// **'Set token'**
  String get setToken;

  /// Appearance, typography, integrations, and MCP server.
  ///
  /// In en, this message translates to:
  /// **'Appearance, typography, integrations, and MCP server.'**
  String get settingsGeneralDescription;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// Label for the language setting row
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Subtitle for the language setting row
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get settingsLanguageDescription;

  /// No description provided for @sharedSecretToken.
  ///
  /// In en, this message translates to:
  /// **'Shared secret token'**
  String get sharedSecretToken;

  /// No description provided for @sharpshooterBadge.
  ///
  /// In en, this message translates to:
  /// **'Sharpshooter'**
  String get sharpshooterBadge;

  /// Short task
  ///
  /// In en, this message translates to:
  /// **'Short task'**
  String get shortTask;

  /// No description provided for @showNativeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show native macOS notifications for events.'**
  String get showNativeNotifications;

  /// Checkbox label to show superseded facts
  ///
  /// In en, this message translates to:
  /// **'Show superseded'**
  String get showSuperseded;

  /// No description provided for @signInWithGhAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in with gh auth login or add a token in Settings > API keys'**
  String get signInWithGhAuth;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get signedIn;

  /// GitHub CLI signed in as user
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}.'**
  String signedInAs(String username);

  /// Skill editor
  ///
  /// In en, this message translates to:
  /// **'Skill editor'**
  String get skillEditor;

  /// Skill name is required.
  ///
  /// In en, this message translates to:
  /// **'Skill name is required.'**
  String get skillNameRequired;

  /// Confirmation snackbar after saving a skill
  ///
  /// In en, this message translates to:
  /// **'Skill \"{name}\" saved.'**
  String skillSaved(String name);

  /// Skills
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// Skills label with colon
  ///
  /// In en, this message translates to:
  /// **'Skills:'**
  String get skillsColon;

  /// Skills (comma separated)
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get skillsCommaSeparated;

  /// No description provided for @skillsLabel.
  ///
  /// In en, this message translates to:
  /// **'SKILLS'**
  String get skillsLabel;

  /// Skip — I accept the risk
  ///
  /// In en, this message translates to:
  /// **'Skip — I accept the risk'**
  String get skipAcceptRisk;

  /// Skip for now
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Skip sandboxing
  ///
  /// In en, this message translates to:
  /// **'Skip sandboxing'**
  String get skipSandboxing;

  /// Dialog body asking if the user wants to skip sandboxing
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip sandboxing? This allows agents to execute code on your system without isolation.'**
  String get skipSandboxingDialogContent;

  /// Something went wrong
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Locale string for sourceCount
  ///
  /// In en, this message translates to:
  /// **'{count} source'**
  String sourceCount(int count);

  /// Locale string for sourceCountPlural
  ///
  /// In en, this message translates to:
  /// **'{count} sources'**
  String sourceCountPlural(int count);

  /// Label for source fact IDs in policy detail
  ///
  /// In en, this message translates to:
  /// **'Source facts:'**
  String get sourceFacts;

  /// Split (side-by-side) diff
  ///
  /// In en, this message translates to:
  /// **'Split (side-by-side) diff'**
  String get splitDiff;

  /// Locale string for startDmWithAgent
  ///
  /// In en, this message translates to:
  /// **'Start DM with agent'**
  String get startDmWithAgent;

  /// Start fresh
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get startFresh;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// Start on app launch
  ///
  /// In en, this message translates to:
  /// **'Start on app launch'**
  String get startOnAppLaunch;

  /// No description provided for @startServerToAccept.
  ///
  /// In en, this message translates to:
  /// **'Start the server to accept MCP connections.'**
  String get startServerToAccept;

  /// Stats
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Onboarding step header
  ///
  /// In en, this message translates to:
  /// **'Step {number} · Connect'**
  String stepConnect(int number);

  /// Stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Status label for stopped state
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// Streaks
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaks;

  /// No description provided for @streaksLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaksLabel;

  /// Locale string for strictIdentityCheck
  ///
  /// In en, this message translates to:
  /// **'Strict identity check'**
  String get strictIdentityCheck;

  /// Success
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @successLabel.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successLabel;

  /// No description provided for @successLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successLabelShort;

  /// Success rate
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get successRate;

  /// Header label for the suggestion composer
  ///
  /// In en, this message translates to:
  /// **'Suggest a change'**
  String get suggestAChange;

  /// Placeholder text in the suggestion composer
  ///
  /// In en, this message translates to:
  /// **'Suggest a change…'**
  String get suggestAChangeEllipsis;

  /// No description provided for @suggestLabel.
  ///
  /// In en, this message translates to:
  /// **'SUGGEST'**
  String get suggestLabel;

  /// Label for superseded facts
  ///
  /// In en, this message translates to:
  /// **'Superseded'**
  String get superseded;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// System default option label
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// System fonts
  ///
  /// In en, this message translates to:
  /// **'System fonts'**
  String get systemFonts;

  /// System prompt
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get systemPrompt;

  /// No description provided for @systemPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get systemPromptLabel;

  /// Talk to Control Center.
  ///
  /// In en, this message translates to:
  /// **'Talk to Control Center.'**
  String get talkToControlCenter;

  /// Tap a badge to see how to level up
  ///
  /// In en, this message translates to:
  /// **'Tap a badge to see how to level up'**
  String get tapBadgeDescription;

  /// No description provided for @tapBadgeToLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Tap a badge to see how to level up'**
  String get tapBadgeToLevelUp;

  /// No description provided for @taskMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskMentionSection;

  /// Generic test button label
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testLabel;

  /// Theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Locale string for themeDark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Locale string for themeLight
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Locale string for themeSystem
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get thisCannotBeUndone;

  /// this conversation
  ///
  /// In en, this message translates to:
  /// **'This conversation'**
  String get thisConversation;

  /// No description provided for @threadLabel.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get threadLabel;

  /// Throughput
  ///
  /// In en, this message translates to:
  /// **'Throughput'**
  String get throughput;

  /// No description provided for @ticketLabel.
  ///
  /// In en, this message translates to:
  /// **'TICKET'**
  String get ticketLabel;

  /// Locale string for tierLabel
  ///
  /// In en, this message translates to:
  /// **'{tier} tier'**
  String tierLabel(String tier);

  /// No description provided for @titleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get titleDescription;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// Toggle bookmark
  ///
  /// In en, this message translates to:
  /// **'Toggle bookmark'**
  String get toggleBookmark;

  /// Toggle theme
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

  /// Toggle workspace switcher
  ///
  /// In en, this message translates to:
  /// **'Toggle workspace switcher'**
  String get toggleWorkspaceSwitcher;

  /// Configured — clients must present this token.
  ///
  /// In en, this message translates to:
  /// **'Configured — clients must present this token.'**
  String get tokenConfigured;

  /// No description provided for @tokenConfiguredClients.
  ///
  /// In en, this message translates to:
  /// **'Configured — clients must present this token.'**
  String get tokenConfiguredClients;

  /// Token field label
  ///
  /// In en, this message translates to:
  /// **'{name} Token'**
  String tokenName(String name);

  /// No description provided for @topPerformerLabel.
  ///
  /// In en, this message translates to:
  /// **'TOP PERFORMER'**
  String get topPerformerLabel;

  /// No description provided for @topPerformersDescription.
  ///
  /// In en, this message translates to:
  /// **'Top performers, throughput, and workspace health.'**
  String get topPerformersDescription;

  /// Topic
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// Hint text for topic field in fact edit
  ///
  /// In en, this message translates to:
  /// **'e.g. Tech Stack, Design System'**
  String get topicHint;

  /// Total runs
  ///
  /// In en, this message translates to:
  /// **'Total runs'**
  String get totalRuns;

  /// No description provided for @totalRunsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total runs'**
  String get totalRunsLabel;

  /// Locale string for trackingParamsCount
  ///
  /// In en, this message translates to:
  /// **'{count} tracking params'**
  String trackingParamsCount(int count);

  /// Type a command or search…
  ///
  /// In en, this message translates to:
  /// **'Type a command or search…'**
  String get typeCommandOrSearch;

  /// Typography
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get typography;

  /// Unavailable
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// An unexpected error occurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// Unified diff
  ///
  /// In en, this message translates to:
  /// **'Unified diff'**
  String get unifiedDiff;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownAuthor;

  /// Unnamed agent
  ///
  /// In en, this message translates to:
  /// **'Unnamed agent'**
  String get unnamedAgent;

  /// Update key
  ///
  /// In en, this message translates to:
  /// **'Update key'**
  String get updateKey;

  /// Generic update button label
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// Update token
  ///
  /// In en, this message translates to:
  /// **'Update token'**
  String get updateToken;

  /// Locale string for updatedDaysAgo
  ///
  /// In en, this message translates to:
  /// **'Updated {count}d ago'**
  String updatedDaysAgo(int count);

  /// Locale string for updatedHoursAgo
  ///
  /// In en, this message translates to:
  /// **'Updated {count}h ago'**
  String updatedHoursAgo(int count);

  /// Locale string for updatedJustNow
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get updatedJustNow;

  /// Locale string for updatedMinutesAgo
  ///
  /// In en, this message translates to:
  /// **'Updated {count}min ago'**
  String updatedMinutesAgo(int count);

  /// Locale string for useSandbox
  ///
  /// In en, this message translates to:
  /// **'Use sandbox'**
  String get useSandbox;

  /// Locale string for useWorkspaceDefault
  ///
  /// In en, this message translates to:
  /// **'Use workspace default'**
  String get useWorkspaceDefault;

  /// User-Agent
  ///
  /// In en, this message translates to:
  /// **'User-Agent'**
  String get userAgent;

  /// No description provided for @userAgentDescription.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the default app User-Agent. Some sites block non-browser User-Agents.'**
  String get userAgentDescription;

  /// Using the system default microphone.
  ///
  /// In en, this message translates to:
  /// **'Using the system default microphone.'**
  String get usingSystemDefaultMicrophone;

  /// View all
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// View log
  ///
  /// In en, this message translates to:
  /// **'View log'**
  String get viewLog;

  /// View logs
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// Voice model install failure
  ///
  /// In en, this message translates to:
  /// **'Install failed: {error}'**
  String voiceInstallFailed(String error);

  /// No description provided for @voiceModelNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed. Downloads ~200 MB once; runs fully on-device.'**
  String get voiceModelNotInstalled;

  /// No description provided for @voiceModelNotInstalledLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice model not installed.'**
  String get voiceModelNotInstalledLabel;

  /// No description provided for @voiceRedownloadBody.
  ///
  /// In en, this message translates to:
  /// **'The existing model files will be deleted and the ~200 MB archive downloaded again. Voice transcription will be unavailable until the download completes.'**
  String get voiceRedownloadBody;

  /// Voice transcription will be disabled until you reinstall it. You can install it again at any time.
  ///
  /// In en, this message translates to:
  /// **'Voice transcription will be disabled until you reinstall it. You can install it again at any time.'**
  String get voiceRemoveBody;

  /// Voice transcription
  ///
  /// In en, this message translates to:
  /// **'Voice transcription'**
  String get voiceTranscription;

  /// No description provided for @meetingVad.
  ///
  /// In en, this message translates to:
  /// **'Speech detection (Silero VAD)'**
  String get meetingVad;

  /// No description provided for @meetingVadDescription.
  ///
  /// In en, this message translates to:
  /// **'A learned voice-activity model that skips silence so the transcriber decodes only speech. Falls back to an energy threshold when not installed.'**
  String get meetingVadDescription;

  /// No description provided for @meetingVadInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed. Gating transcription on detected speech.'**
  String get meetingVadInstalled;

  /// No description provided for @meetingVadNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed — using the energy-threshold fallback.'**
  String get meetingVadNotInstalled;

  /// No description provided for @meetingModelIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get meetingModelIncluded;

  /// Weak isolation - namespace boundary only, no kernel boundary.
  ///
  /// In en, this message translates to:
  /// **'Weak isolation - namespace boundary only, no kernel boundary.'**
  String get weakIsolationDescription;

  /// No description provided for @whenOffNoDefaultRoute.
  ///
  /// In en, this message translates to:
  /// **'When off, the sandbox boots without a default route.'**
  String get whenOffNoDefaultRoute;

  /// No description provided for @whenOffServerStaysStopped.
  ///
  /// In en, this message translates to:
  /// **'When off, the server stays stopped until you start it.'**
  String get whenOffServerStaysStopped;

  /// No description provided for @whisperBaseEn.
  ///
  /// In en, this message translates to:
  /// **'Whisper base.en (sherpa-onnx)'**
  String get whisperBaseEn;

  /// No description provided for @whisperInstalled.
  ///
  /// In en, this message translates to:
  /// **'Whisper base.en installed. Used by the composer mic button.'**
  String get whisperInstalled;

  /// Label for the ASR model picker in settings.
  ///
  /// In en, this message translates to:
  /// **'Speech model'**
  String get speechModel;

  /// Subtitle under the speech model picker.
  ///
  /// In en, this message translates to:
  /// **'Used for meeting transcription and the composer mic.'**
  String get speechModelHint;

  /// Subtitle shown when a voice model is installed.
  ///
  /// In en, this message translates to:
  /// **'Installed. Powers meeting transcription and the composer mic button.'**
  String get voiceModelInstalled;

  /// Warning shown during recording when the mic is silent while the system audio is active.
  ///
  /// In en, this message translates to:
  /// **'Your mic may be muted — the others are talking but nothing is reaching your microphone.'**
  String get meetingMicSilentWarning;

  /// No description provided for @meetingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Meeting note templates'**
  String get meetingTemplates;

  /// No description provided for @meetingTemplatesHint.
  ///
  /// In en, this message translates to:
  /// **'Shape the AI summary for a kind of meeting. The active template applies to new and re-run summaries.'**
  String get meetingTemplatesHint;

  /// No description provided for @meetingTemplateActive.
  ///
  /// In en, this message translates to:
  /// **'Active template'**
  String get meetingTemplateActive;

  /// No description provided for @meetingTemplateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get meetingTemplateAdd;

  /// No description provided for @meetingTemplateNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get meetingTemplateNewTitle;

  /// No description provided for @meetingTemplateEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get meetingTemplateEditTitle;

  /// No description provided for @meetingTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get meetingTemplateNameLabel;

  /// No description provided for @meetingTemplateNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sprint review'**
  String get meetingTemplateNameHint;

  /// No description provided for @meetingTemplateInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get meetingTemplateInstructionsLabel;

  /// No description provided for @meetingTemplateInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'How should the AI structure and emphasize these notes?'**
  String get meetingTemplateInstructionsHint;

  /// Locale string for workerLabel
  ///
  /// In en, this message translates to:
  /// **'Worker {index}'**
  String workerLabel(int index);

  /// Locale string for workersCount
  ///
  /// In en, this message translates to:
  /// **'{count} workers'**
  String workersCount(int count);

  /// Working memory
  ///
  /// In en, this message translates to:
  /// **'Working memory'**
  String get workingMemory;

  /// Workspace name
  ///
  /// In en, this message translates to:
  /// **'Workspace name'**
  String get workspaceName;

  /// No description provided for @workspaceNotesScratchpad.
  ///
  /// In en, this message translates to:
  /// **'Workspace notes & scratchpad'**
  String get workspaceNotesScratchpad;

  /// No description provided for @workspacePulse.
  ///
  /// In en, this message translates to:
  /// **'Workspace pulse'**
  String get workspacePulse;

  /// No description provided for @workspaceScopedSkills.
  ///
  /// In en, this message translates to:
  /// **'Workspace-scoped skill files attached to agents.'**
  String get workspaceScopedSkills;

  /// Workspaces
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @writeLabel.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get writeLabel;

  /// No description provided for @writePrivateNotes.
  ///
  /// In en, this message translates to:
  /// **'Write private notes, observations, plans...'**
  String get writePrivateNotes;

  /// No description provided for @writeSkillContent.
  ///
  /// In en, this message translates to:
  /// **'Write your skill content here (Markdown)…'**
  String get writeSkillContent;

  /// XP
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// Relative time: years ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String yearsAgo(int count);

  /// Relative time: exactly yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @yourAchievements.
  ///
  /// In en, this message translates to:
  /// **'Your achievements'**
  String get yourAchievements;

  /// Button label to open focus mode config dialog
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get focusModeStart;

  /// Title of the focus mode configuration dialog
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get focusModeConfigTitle;

  /// Label for the focus session goal field
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get focusModeGoalLabel;

  /// Placeholder hint for the goal text field
  ///
  /// In en, this message translates to:
  /// **'What are you working on?'**
  String get focusModeGoalHint;

  /// Label for the session duration selector
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get focusModeDurationLabel;

  /// Toggle label for blocking notifications during focus
  ///
  /// In en, this message translates to:
  /// **'Block notifications'**
  String get focusModeBlockNotifications;

  /// Confirm button in focus mode config dialog
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get focusModeStartButton;

  /// Tooltip/button to end the current focus session
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get focusModeEndSession;

  /// Tooltip to expand from compact focus bar back to full app
  ///
  /// In en, this message translates to:
  /// **'Expand app'**
  String get focusModeExpand;

  /// Tooltip to minimize app to compact focus bar
  ///
  /// In en, this message translates to:
  /// **'Minimize to bar'**
  String get focusModeFloat;

  /// Tooltip on the focus mode chip in title bar
  ///
  /// In en, this message translates to:
  /// **'Focus mode active — tap to end'**
  String get focusModeActiveTooltip;

  /// Button label to dismiss a banner or notice
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Button label to accept a code suggestion and resolve its thread
  ///
  /// In en, this message translates to:
  /// **'Accept & resolve'**
  String get acceptAndResolve;

  /// Warning shown when a PR review session exceeds 60 minutes
  ///
  /// In en, this message translates to:
  /// **'You\'ve been reviewing for {minutes}m — research suggests review quality can dip past 60 min. Consider a break.'**
  String reviewFatigueWarning(int minutes);

  /// Label for the notification sound setting
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSound;

  /// Description for the notification sound setting
  ///
  /// In en, this message translates to:
  /// **'Sound played when a notification is shown.'**
  String get notificationSoundDescription;

  /// No notification sound option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get notificationSoundNone;

  /// Ping notification sound option
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get notificationSoundPing;

  /// Chime notification sound option
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get notificationSoundChime;

  /// Pop notification sound option
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get notificationSoundPop;

  /// Ding notification sound option
  ///
  /// In en, this message translates to:
  /// **'Ding'**
  String get notificationSoundDing;

  /// Whoosh notification sound option
  ///
  /// In en, this message translates to:
  /// **'Whoosh'**
  String get notificationSoundWhoosh;

  /// Migros soft notification sound option
  ///
  /// In en, this message translates to:
  /// **'Migros (soft)'**
  String get notificationSoundMigrosSoft;

  /// Migros hard notification sound option
  ///
  /// In en, this message translates to:
  /// **'Migros (hard)'**
  String get notificationSoundMigrosHard;

  /// SBB notification sound option
  ///
  /// In en, this message translates to:
  /// **'SBB'**
  String get notificationSoundSbb;

  /// CFF notification sound option
  ///
  /// In en, this message translates to:
  /// **'CFF'**
  String get notificationSoundCff;

  /// FFS notification sound option
  ///
  /// In en, this message translates to:
  /// **'FFS'**
  String get notificationSoundFfs;

  /// Post notification sound option
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get notificationSoundPost;

  /// Button to preview the selected notification sound
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get notificationSoundTest;

  /// Label for the notification sound volume slider
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get notificationVolume;

  /// Link to open a user's full profile page
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// Button to clear all active PR list filters
  ///
  /// In en, this message translates to:
  /// **'× Clear all'**
  String get clearAllFilters;

  /// Summary label showing how many repos the filters cover
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Across 1 repo} other{Across {count} repos}}'**
  String acrossNRepos(num count);

  /// Short label for pull requests used in filter summary
  ///
  /// In en, this message translates to:
  /// **'PRs'**
  String get pullRequestsLabel;

  /// Empty state on user profile screen when the user has no PRs in the current workspace
  ///
  /// In en, this message translates to:
  /// **'No PRs by @{login} in this workspace'**
  String noPrsByUserInWorkspace(String login);

  /// Breadcrumb label for the users section
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersLabel;

  /// Button label to merge a pull request
  ///
  /// In en, this message translates to:
  /// **'Merge pull request'**
  String get mergePullRequest;

  /// Button label to force-merge a pull request despite failing checks or pending reviews
  ///
  /// In en, this message translates to:
  /// **'Force merge pull request'**
  String get forceMergePullRequest;

  /// Button label to close a pull request
  ///
  /// In en, this message translates to:
  /// **'Close pull request'**
  String get closePullRequest;

  /// Confirmation dialog for closing a pull request
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close this pull request?'**
  String get closePullRequestConfirm;

  /// Merge method: squash all commits into one
  ///
  /// In en, this message translates to:
  /// **'Squash and merge'**
  String get squashAndMerge;

  /// Merge method: create a merge commit
  ///
  /// In en, this message translates to:
  /// **'Create a merge commit'**
  String get createMergeCommit;

  /// Merge method: rebase commits onto the base branch
  ///
  /// In en, this message translates to:
  /// **'Rebase and merge'**
  String get rebaseAndMerge;

  /// Label for the commit title field in the merge flyout
  ///
  /// In en, this message translates to:
  /// **'Commit title'**
  String get commitTitle;

  /// Label for the commit description field in the merge flyout
  ///
  /// In en, this message translates to:
  /// **'Commit description'**
  String get commitDescription;

  /// Success message after merging a pull request
  ///
  /// In en, this message translates to:
  /// **'Pull request merged'**
  String get pullRequestMerged;

  /// Success message after closing a pull request
  ///
  /// In en, this message translates to:
  /// **'Pull request closed'**
  String get pullRequestClosed;

  /// Error message when merging a pull request fails
  ///
  /// In en, this message translates to:
  /// **'Failed to merge: {error}'**
  String failedToMergePr(String error);

  /// Error message when closing a pull request fails
  ///
  /// In en, this message translates to:
  /// **'Failed to close: {error}'**
  String failedToClosePr(String error);

  /// Warning that CI checks are not all passing
  ///
  /// In en, this message translates to:
  /// **'Checks failing'**
  String get checksFailing;

  /// Warning that not all reviewers have approved
  ///
  /// In en, this message translates to:
  /// **'Some reviews are pending'**
  String get reviewsPending;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Section header for the per-domain content-blocker allowlist
  ///
  /// In en, this message translates to:
  /// **'Trusted sites'**
  String get trustedSitesSectionTitle;

  /// Empty-state copy when no domains are on the per-domain allowlist
  ///
  /// In en, this message translates to:
  /// **'No trusted sites. Add a domain to disable blocking on it.'**
  String get trustedSitesEmpty;

  /// Button label to add a domain to the per-domain allowlist
  ///
  /// In en, this message translates to:
  /// **'Add trusted site'**
  String get addTrustedSite;

  /// Tooltip on the per-domain allowlist row delete button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTrustedSite;

  /// Tooltip on the article reader shield button when blocking is currently on
  ///
  /// In en, this message translates to:
  /// **'Disable blocking on this site'**
  String get disableBlockingForThisSite;

  /// Tooltip on the article reader shield button when blocking is currently off for this site
  ///
  /// In en, this message translates to:
  /// **'Enable blocking on this site'**
  String get enableBlockingForThisSite;

  /// Placeholder text in the add-trusted-site domain input
  ///
  /// In en, this message translates to:
  /// **'e.g. example.com'**
  String get enterDomainHint;

  /// Validation message when the add-trusted-site domain input is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid domain (e.g. example.com)'**
  String get invalidDomain;

  /// Banner shown in the article reader when page load exceeds the 15s timeout
  ///
  /// In en, this message translates to:
  /// **'Page load timed out. Reload or open in browser.'**
  String get pageLoadTimedOut;

  /// Title for the pipelines screen
  ///
  /// In en, this message translates to:
  /// **'Pipelines'**
  String get pipelinesScreenTitle;

  /// Subtitle for the pipelines screen
  ///
  /// In en, this message translates to:
  /// **'Declarative multi-step agent workflows'**
  String get pipelinesScreenSubtitle;

  /// Button text to run the hello demo pipeline
  ///
  /// In en, this message translates to:
  /// **'Run hello pipeline'**
  String get pipelinesRunHello;

  /// Button on the pipelines screen that opens the manual run launcher
  ///
  /// In en, this message translates to:
  /// **'Run pipeline'**
  String get pipelinesRunPipeline;

  /// Title of the manual run launcher screen
  ///
  /// In en, this message translates to:
  /// **'Run pipeline'**
  String get pipelineRunLauncherTitle;

  /// Subtitle of the manual run launcher screen
  ///
  /// In en, this message translates to:
  /// **'Pick a pipeline and fill in its inputs to start a run.'**
  String get pipelineRunSubtitle;

  /// Badge shown on a pipeline in the run picker that declares no inputs
  ///
  /// In en, this message translates to:
  /// **'No inputs'**
  String get pipelineRunNoInputsBadge;

  /// Count of inputs a pipeline declares, shown in the run picker
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 input} other{{count} inputs}}'**
  String pipelineRunInputsCount(int count);

  /// Shown in the run form when the selected pipeline declares no inputs
  ///
  /// In en, this message translates to:
  /// **'This pipeline takes no inputs.'**
  String get pipelineRunNoInputs;

  /// Submit button on the manual run form
  ///
  /// In en, this message translates to:
  /// **'Run pipeline'**
  String get pipelineRunSubmit;

  /// Shown when starting a manual run returns no run (e.g. the pipeline is disabled)
  ///
  /// In en, this message translates to:
  /// **'Could not start the run.'**
  String get pipelineRunCouldNotStart;

  /// Confirmation snackbar after a manual run is started
  ///
  /// In en, this message translates to:
  /// **'Started {name}'**
  String pipelineRunStarted(String name);

  /// Empty state title on the manual run launcher
  ///
  /// In en, this message translates to:
  /// **'No pipelines ready to run'**
  String get pipelineRunEmptyTitle;

  /// Empty state hint on the manual run launcher
  ///
  /// In en, this message translates to:
  /// **'Enable a pipeline and turn on manual run in its editor to launch it here.'**
  String get pipelineRunEmptyHint;

  /// Button on the run launcher empty state that opens pipeline template settings
  ///
  /// In en, this message translates to:
  /// **'Manage pipelines'**
  String get pipelineRunManageTemplates;

  /// Title of the manual-run settings dialog and its editor button
  ///
  /// In en, this message translates to:
  /// **'Manual run'**
  String get pipelineRunSettingsTitle;

  /// Toggle label: whether the template can be started from the run page
  ///
  /// In en, this message translates to:
  /// **'Allow manual run'**
  String get pipelineRunSettingsAllow;

  /// Help text under the allow-manual-run toggle
  ///
  /// In en, this message translates to:
  /// **'Show this pipeline on the run page so it can be started by hand.'**
  String get pipelineRunSettingsAllowHelp;

  /// Section heading for the input fields list in run settings
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get pipelineRunSettingsInputsTitle;

  /// Button to add a new input field in run settings
  ///
  /// In en, this message translates to:
  /// **'Add input'**
  String get pipelineRunSettingsAddInput;

  /// Shown when a template has no declared inputs in run settings
  ///
  /// In en, this message translates to:
  /// **'No inputs yet.'**
  String get pipelineRunSettingsNoInputs;

  /// Title of the single input-field editor dialog
  ///
  /// In en, this message translates to:
  /// **'Input field'**
  String get pipelineInputEditTitle;

  /// Label for the input field's state key
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get pipelineInputKeyLabel;

  /// Help text for the input field's state key
  ///
  /// In en, this message translates to:
  /// **'State key the value is stored under (e.g. repoFullName).'**
  String get pipelineInputKeyHelp;

  /// Label for the input field's display label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get pipelineInputLabelLabel;

  /// Label for the input field's type selector
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pipelineInputTypeLabel;

  /// Label for the select input's options field
  ///
  /// In en, this message translates to:
  /// **'Options (comma-separated)'**
  String get pipelineInputOptionsLabel;

  /// Label for the input field's default value
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get pipelineInputDefaultLabel;

  /// Label for the input field's placeholder hint
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get pipelineInputPlaceholderLabel;

  /// Label for the input field's help text
  ///
  /// In en, this message translates to:
  /// **'Help text'**
  String get pipelineInputHelpLabel;

  /// Label for the input field's required toggle
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get pipelineInputRequiredLabel;

  /// Input type: single-line text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get pipelineInputTypeText;

  /// Input type: multi-line text
  ///
  /// In en, this message translates to:
  /// **'Multi-line text'**
  String get pipelineInputTypeMultiline;

  /// Input type: number
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get pipelineInputTypeNumber;

  /// Input type: boolean toggle
  ///
  /// In en, this message translates to:
  /// **'Toggle'**
  String get pipelineInputTypeBoolean;

  /// Input type: select from options
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get pipelineInputTypeSelect;

  /// Empty state message when no pipelines have been run
  ///
  /// In en, this message translates to:
  /// **'No pipeline runs yet'**
  String get pipelinesEmpty;

  /// Hint text in the empty pipelines state
  ///
  /// In en, this message translates to:
  /// **'Click \'Run pipeline\' to start one.'**
  String get pipelinesEmptyHint;

  /// Placeholder when no pipeline run is selected
  ///
  /// In en, this message translates to:
  /// **'Select a pipeline run to view steps'**
  String get pipelinesSelectRun;

  /// Placeholder when a pipeline run has no steps
  ///
  /// In en, this message translates to:
  /// **'No steps recorded yet'**
  String get pipelinesNoSteps;

  /// Shown on the pipelines screen when no workspace is active
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to view its pipelines'**
  String get pipelinesNoActiveWorkspace;

  /// Error state on the pipelines screen
  ///
  /// In en, this message translates to:
  /// **'Failed to load pipelines: {error}'**
  String pipelinesLoadError(String error);

  /// Snackbar when starting a pipeline fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start pipeline: {error}'**
  String pipelinesRunFailed(String error);

  /// Pipeline status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pipelineStatusPending;

  /// Pipeline status: running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get pipelineStatusRunning;

  /// Pipeline status: suspended
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get pipelineStatusSuspended;

  /// Pipeline status: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pipelineStatusCompleted;

  /// Pipeline status: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get pipelineStatusFailed;

  /// Pipeline status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pipelineStatusCancelled;

  /// Pipeline status: skipped
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get pipelineStatusSkipped;

  /// Duration of a pipeline run in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String pipelineRunDuration(int seconds);

  /// Duration of a pipeline step in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String pipelineStepDuration(int seconds);

  /// Run header progress: completed vs total steps
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} steps'**
  String pipelineRunStepProgress(int completed, int total);

  /// Step detail label: when the step started
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get pipelineStepStarted;

  /// Step detail label: when the step finished
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get pipelineStepFinished;

  /// Step detail label: run duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get pipelineStepDurationLabel;

  /// Step detail label: parallel branch index
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get pipelineStepBranch;

  /// Button opening the hidden pipeline-spawned conversation from the step detail
  ///
  /// In en, this message translates to:
  /// **'View conversation'**
  String get pipelineStepViewConversation;

  /// Step detail section header: error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get pipelineStepError;

  /// Step detail section header: input payload
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get pipelineStepInput;

  /// Step detail section header: output payload
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get pipelineStepOutput;

  /// Step detail placeholder when the step has not run yet
  ///
  /// In en, this message translates to:
  /// **'Not yet executed'**
  String get pipelineStepNotExecuted;

  /// Run detail view toggle: stacked step timeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get pipelineRunViewTimeline;

  /// Run detail view toggle: node graph canvas
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get pipelineRunViewGraph;

  /// Run header summary naming the step where the run failed
  ///
  /// In en, this message translates to:
  /// **'Failed at {step}'**
  String pipelineRunFailedAtStep(String step);

  /// Run was started by hand from the run launcher
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get pipelineRunTriggerManual;

  /// Run was started automatically by a domain event trigger
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get pipelineRunTriggerAuto;

  /// Step detail callout header for a non-fatal skip reason
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get pipelineStepSkippedReason;

  /// Runs rail filter showing every run
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pipelineRunFilterAll;

  /// Shown in the runs rail when the active status filter matches no runs
  ///
  /// In en, this message translates to:
  /// **'No runs match this filter'**
  String get pipelineRunFilterEmpty;

  /// Relative time for an event within the last minute
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String relativeMinutesAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String relativeHoursAgo(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String relativeDaysAgo(int count);

  /// Title for the automations settings screen
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get automationsTitle;

  /// Subtitle for the automations settings screen
  ///
  /// In en, this message translates to:
  /// **'Auto-start pipelines when domain events fire'**
  String get automationsSubtitle;

  /// Empty state for an event section with no triggers
  ///
  /// In en, this message translates to:
  /// **'No triggers configured for this event.'**
  String get automationsNoTriggers;

  /// Button to add a new automation trigger
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get automationsAddTrigger;

  /// Title for the tasks screen
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Ticket status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get taskStatusPending;

  /// Ticket status: in progress
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// Ticket status: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// Ticket status: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get taskStatusFailed;

  /// Ticket status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// Empty state for tasks list
  ///
  /// In en, this message translates to:
  /// **'No tickets'**
  String get tasksNoTasks;

  /// Title for the teams settings screen
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsTitle;

  /// Empty state for teams list
  ///
  /// In en, this message translates to:
  /// **'No teams configured'**
  String get teamsNoTeams;

  /// Button to add a new team
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get teamsAddTeam;

  /// Title for the pipeline run detail screen
  ///
  /// In en, this message translates to:
  /// **'Pipeline run'**
  String get pipelineRunTitle;

  /// Message when pipeline run ID is invalid
  ///
  /// In en, this message translates to:
  /// **'Pipeline run not found'**
  String get pipelineNotFound;

  /// Sidebar entry for the pipeline templates settings screen
  ///
  /// In en, this message translates to:
  /// **'Pipeline templates'**
  String get pipelineTemplatesNav;

  /// Title of the pipeline templates settings screen
  ///
  /// In en, this message translates to:
  /// **'Pipeline templates'**
  String get pipelineTemplatesTitle;

  /// Subtitle of the pipeline templates settings screen
  ///
  /// In en, this message translates to:
  /// **'Drag-and-drop editor for the pipelines that orchestrate your agents.'**
  String get pipelineTemplatesSubtitle;

  /// Button label to create a new pipeline template
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get pipelineTemplatesNew;

  /// Empty state for the pipeline templates list
  ///
  /// In en, this message translates to:
  /// **'No pipeline templates yet. Create one to get started.'**
  String get pipelineTemplatesEmpty;

  /// Field label for entering a new template ID
  ///
  /// In en, this message translates to:
  /// **'Template ID'**
  String get pipelineTemplateIdLabel;

  /// Badge shown next to built-in templates
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get pipelineTemplateBuiltInBadge;

  /// Confirmation dialog title for deleting a template
  ///
  /// In en, this message translates to:
  /// **'Delete template?'**
  String get pipelineTemplateDeleteConfirmTitle;

  /// Confirmation dialog body for deleting a template
  ///
  /// In en, this message translates to:
  /// **'Delete pipeline template {name}? This cannot be undone.'**
  String pipelineTemplateDeleteConfirmBody(String name);

  /// Toast shown after saving a template
  ///
  /// In en, this message translates to:
  /// **'Pipeline template saved'**
  String get pipelineTemplateSaved;

  /// Title of the pipeline template editor screen
  ///
  /// In en, this message translates to:
  /// **'Edit pipeline'**
  String get pipelineTemplateEditorTitle;

  /// Subtitle of the editor screen
  ///
  /// In en, this message translates to:
  /// **'Drag node types from the sidebar onto the canvas, then wire them together.'**
  String get pipelineTemplateEditorSubtitle;

  /// Indicator that the editor has unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// Sidebar header for the node library
  ///
  /// In en, this message translates to:
  /// **'Node library'**
  String get nodeLibraryTitle;

  /// Hint shown under the node library header
  ///
  /// In en, this message translates to:
  /// **'Drag any entry onto the canvas to add a node.'**
  String get nodeLibraryHint;

  /// Legend hint shown on the editor canvas
  ///
  /// In en, this message translates to:
  /// **'Drag from the library, click a node to edit'**
  String get editorDragHint;

  /// Empty state for the editor canvas
  ///
  /// In en, this message translates to:
  /// **'Drag a node from the library to start.'**
  String get editorEmptyCanvas;

  /// Header for the node configuration panel
  ///
  /// In en, this message translates to:
  /// **'Node config'**
  String get nodeConfigTitle;

  /// Form label for the node kind dropdown
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get nodeConfigKind;

  /// Form label for the node display label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get nodeConfigLabel;

  /// Form label for the agent picker
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get nodeConfigAgent;

  /// Hint text in the agent picker
  ///
  /// In en, this message translates to:
  /// **'Pick an agent…'**
  String get nodeConfigAgentHint;

  /// Form label for the input keys field
  ///
  /// In en, this message translates to:
  /// **'Input keys (comma-separated)'**
  String get nodeConfigInputKeys;

  /// Helper text for the input keys field
  ///
  /// In en, this message translates to:
  /// **'State keys this node consumes. Used for placeholder substitution in the prompt.'**
  String get nodeConfigInputKeysHelp;

  /// Form label for the output key field
  ///
  /// In en, this message translates to:
  /// **'Output key'**
  String get nodeConfigOutputKey;

  /// Form label for the prompt template field
  ///
  /// In en, this message translates to:
  /// **'Prompt template'**
  String get nodeConfigPrompt;

  /// Helper text for the prompt field
  ///
  /// In en, this message translates to:
  /// **'Use double-brace placeholders to pull values from state at runtime.'**
  String get nodeConfigPromptHelp;

  /// Form label for the bash script field
  ///
  /// In en, this message translates to:
  /// **'Bash script'**
  String get nodeConfigScript;

  /// Helper text for the bash script field
  ///
  /// In en, this message translates to:
  /// **'Runs with bash -c. GITHUB_TOKEN is set. Placeholders are substituted before execution.'**
  String get nodeConfigScriptHelp;

  /// Section header for selecting upstream triggers
  ///
  /// In en, this message translates to:
  /// **'Triggers from'**
  String get nodeConfigTriggers;

  /// Shown when there are no candidate upstream nodes
  ///
  /// In en, this message translates to:
  /// **'No other nodes to connect from.'**
  String get nodeConfigNoUpstream;

  /// Header for the per-edge route-key fields below the trigger chips
  ///
  /// In en, this message translates to:
  /// **'Route keys'**
  String get nodeConfigRouteKeys;

  /// Label for the route key an edge listens for from an upstream router
  ///
  /// In en, this message translates to:
  /// **'Route key from {source}'**
  String nodeConfigRouteKeyFrom(String source);

  /// No description provided for @conditionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionSectionTitle;

  /// No description provided for @conditionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get conditionMode;

  /// No description provided for @conditionModeFilesAny.
  ///
  /// In en, this message translates to:
  /// **'File(s) exist — any'**
  String get conditionModeFilesAny;

  /// No description provided for @conditionModeFilesAll.
  ///
  /// In en, this message translates to:
  /// **'Files exist — all'**
  String get conditionModeFilesAll;

  /// No description provided for @conditionModeComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get conditionModeComparison;

  /// No description provided for @conditionModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get conditionModeSwitch;

  /// No description provided for @conditionFilePaths.
  ///
  /// In en, this message translates to:
  /// **'File paths'**
  String get conditionFilePaths;

  /// No description provided for @conditionFilePathsAnyHelp.
  ///
  /// In en, this message translates to:
  /// **'One path per line, relative to the base directory. Routes true when any exists.'**
  String get conditionFilePathsAnyHelp;

  /// No description provided for @conditionFilePathsAllHelp.
  ///
  /// In en, this message translates to:
  /// **'One path per line, relative to the base directory. Routes true only when all exist.'**
  String get conditionFilePathsAllHelp;

  /// No description provided for @conditionBaseKey.
  ///
  /// In en, this message translates to:
  /// **'Base directory key'**
  String get conditionBaseKey;

  /// No description provided for @conditionBaseKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'State key holding the directory paths resolve against (default repoLocalPath).'**
  String get conditionBaseKeyHelp;

  /// No description provided for @conditionRecursive.
  ///
  /// In en, this message translates to:
  /// **'Search subdirectories'**
  String get conditionRecursive;

  /// No description provided for @conditionNegate.
  ///
  /// In en, this message translates to:
  /// **'Invert: route true when missing'**
  String get conditionNegate;

  /// No description provided for @conditionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left value'**
  String get conditionLeft;

  /// No description provided for @conditionOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get conditionOperator;

  /// No description provided for @conditionRight.
  ///
  /// In en, this message translates to:
  /// **'Right value'**
  String get conditionRight;

  /// No description provided for @conditionSwitchKey.
  ///
  /// In en, this message translates to:
  /// **'Switch on state key'**
  String get conditionSwitchKey;

  /// No description provided for @conditionCases.
  ///
  /// In en, this message translates to:
  /// **'Cases (comma-separated)'**
  String get conditionCases;

  /// No description provided for @conditionCasesHelp.
  ///
  /// In en, this message translates to:
  /// **'Route keys to match against the value, in order.'**
  String get conditionCasesHelp;

  /// No description provided for @conditionDefaultCase.
  ///
  /// In en, this message translates to:
  /// **'Default case'**
  String get conditionDefaultCase;

  /// No description provided for @triggerPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get triggerPanelTitle;

  /// No description provided for @triggerPanelHelp.
  ///
  /// In en, this message translates to:
  /// **'What starts this pipeline.'**
  String get triggerPanelHelp;

  /// No description provided for @triggerManualHelp.
  ///
  /// In en, this message translates to:
  /// **'Show on the run page and start by hand.'**
  String get triggerManualHelp;

  /// No description provided for @triggerSectionAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic triggers'**
  String get triggerSectionAutomatic;

  /// No description provided for @triggerAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get triggerAddButton;

  /// No description provided for @triggerNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No automatic triggers yet.'**
  String get triggerNoneYet;

  /// No description provided for @triggerAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get triggerAddDialogTitle;

  /// No description provided for @triggerKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Trigger type'**
  String get triggerKindLabel;

  /// No description provided for @triggerKindEvent.
  ///
  /// In en, this message translates to:
  /// **'On an event'**
  String get triggerKindEvent;

  /// No description provided for @triggerKindSchedule.
  ///
  /// In en, this message translates to:
  /// **'On a schedule'**
  String get triggerKindSchedule;

  /// No description provided for @triggerIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Run every (seconds)'**
  String get triggerIntervalLabel;

  /// No description provided for @triggerEventFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get triggerEventFieldLabel;

  /// No description provided for @triggerNoMoreEvents.
  ///
  /// In en, this message translates to:
  /// **'All available events are already wired.'**
  String get triggerNoMoreEvents;

  /// No description provided for @triggerMatchStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Only when the status is'**
  String get triggerMatchStatusLabel;

  /// No description provided for @triggerSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'No triggers'**
  String get triggerSummaryNone;

  /// No description provided for @triggerEverySeconds.
  ///
  /// In en, this message translates to:
  /// **'Every {seconds}s'**
  String triggerEverySeconds(int seconds);

  /// No description provided for @triggerEventManual.
  ///
  /// In en, this message translates to:
  /// **'Manual run'**
  String get triggerEventManual;

  /// No description provided for @triggerEventSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get triggerEventSchedule;

  /// No description provided for @triggerEventPrStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'PR status changed'**
  String get triggerEventPrStatusChanged;

  /// No description provided for @triggerEventExternalPr.
  ///
  /// In en, this message translates to:
  /// **'External PR opened'**
  String get triggerEventExternalPr;

  /// No description provided for @triggerEventPrPublished.
  ///
  /// In en, this message translates to:
  /// **'PR published'**
  String get triggerEventPrPublished;

  /// No description provided for @triggerEventPrMerged.
  ///
  /// In en, this message translates to:
  /// **'PR merged'**
  String get triggerEventPrMerged;

  /// No description provided for @triggerEventRepoAdded.
  ///
  /// In en, this message translates to:
  /// **'Repository added'**
  String get triggerEventRepoAdded;

  /// No description provided for @triggerEventMessageReceived.
  ///
  /// In en, this message translates to:
  /// **'Message received'**
  String get triggerEventMessageReceived;

  /// No description provided for @triggerEventTicketCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ticket completed'**
  String get triggerEventTicketCompleted;

  /// No description provided for @triggerEventTicketFailed.
  ///
  /// In en, this message translates to:
  /// **'Ticket failed'**
  String get triggerEventTicketFailed;

  /// No description provided for @triggerEventTicketCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ticket cancelled'**
  String get triggerEventTicketCancelled;

  /// No description provided for @triggerEventBudgetCrossed.
  ///
  /// In en, this message translates to:
  /// **'Budget threshold crossed'**
  String get triggerEventBudgetCrossed;

  /// No description provided for @automationsManagedHint.
  ///
  /// In en, this message translates to:
  /// **'Triggers are configured per pipeline in its editor. Toggle them on or off here.'**
  String get automationsManagedHint;

  /// No description provided for @automationsEditInPipeline.
  ///
  /// In en, this message translates to:
  /// **'Edit in pipeline'**
  String get automationsEditInPipeline;

  /// No description provided for @nodeLibrarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search nodes'**
  String get nodeLibrarySearchHint;

  /// No description provided for @nodeLibraryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching nodes'**
  String get nodeLibraryNoMatches;

  /// No description provided for @nodeCategoryFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow & logic'**
  String get nodeCategoryFlow;

  /// No description provided for @nodeCategoryPr.
  ///
  /// In en, this message translates to:
  /// **'PR review'**
  String get nodeCategoryPr;

  /// No description provided for @nodeCategoryAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get nodeCategoryAgents;

  /// No description provided for @nodeCategoryMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get nodeCategoryMessaging;

  /// No description provided for @nodeCategoryCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get nodeCategoryCode;

  /// No description provided for @nodeCategoryDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get nodeCategoryDemo;

  /// No description provided for @triggerDisabledTag.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get triggerDisabledTag;

  /// No description provided for @pipelineInputTypeRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get pipelineInputTypeRepo;

  /// No description provided for @pipelineRunNoRepos.
  ///
  /// In en, this message translates to:
  /// **'No repositories in this workspace yet.'**
  String get pipelineRunNoRepos;

  /// No description provided for @allowTicketingApi.
  ///
  /// In en, this message translates to:
  /// **'Allow ticketing API calls'**
  String get allowTicketingApi;

  /// No description provided for @ticketingApiKey.
  ///
  /// In en, this message translates to:
  /// **'Ticketing API key'**
  String get ticketingApiKey;

  /// No description provided for @ticketingApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Injects the ticketing provider API key into the sandbox.'**
  String get ticketingApiKeySubtitle;

  /// No description provided for @ticketingProvider.
  ///
  /// In en, this message translates to:
  /// **'Ticketing provider'**
  String get ticketingProvider;

  /// No description provided for @connectGitHubAndTicketing.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub so Control Center can read your pull requests, issues, and reviews. Optionally connect a ticketing provider. Nothing leaves this machine.'**
  String get connectGitHubAndTicketing;

  /// No description provided for @triggerEventTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned'**
  String get triggerEventTicketAssigned;

  /// No description provided for @navTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get navTickets;

  /// No description provided for @ticketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsTitle;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get newTicket;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// No description provided for @assignTicket.
  ///
  /// In en, this message translates to:
  /// **'Assign ticket'**
  String get assignTicket;

  /// No description provided for @addCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Add collaborator'**
  String get addCollaborator;

  /// No description provided for @noCollaborators.
  ///
  /// In en, this message translates to:
  /// **'No collaborators yet'**
  String get noCollaborators;

  /// No description provided for @linkedPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Linked pull requests'**
  String get linkedPullRequests;

  /// No description provided for @noLinkedPullRequests.
  ///
  /// In en, this message translates to:
  /// **'No linked pull requests yet'**
  String get noLinkedPullRequests;

  /// No description provided for @ticketActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get ticketActivity;

  /// No description provided for @ticketDispatchHint.
  ///
  /// In en, this message translates to:
  /// **'@mention an agent to dispatch them…'**
  String get ticketDispatchHint;

  /// No description provided for @stopAgent.
  ///
  /// In en, this message translates to:
  /// **'Stop agent'**
  String get stopAgent;

  /// No description provided for @removeQueuedMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove queued message'**
  String get removeQueuedMessage;

  /// No description provided for @ticketProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get ticketProperties;

  /// No description provided for @ticketTabIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get ticketTabIssue;

  /// No description provided for @ticketTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get ticketTabActivity;

  /// No description provided for @ticketTabChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get ticketTabChanges;

  /// No description provided for @ticketTabTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get ticketTabTerminal;

  /// No description provided for @ticketSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket to view its details'**
  String get ticketSelectPrompt;

  /// No description provided for @ticketNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes in the linked repositories yet'**
  String get ticketNoChanges;

  /// No description provided for @ticketTerminalNoAgent.
  ///
  /// In en, this message translates to:
  /// **'Assign an agent to open a terminal'**
  String get ticketTerminalNoAgent;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @ticketStatusBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get ticketStatusBacklog;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get ticketStatusInReview;

  /// No description provided for @ticketStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get ticketStatusDone;

  /// No description provided for @ticketStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get ticketStatusBlocked;

  /// No description provided for @ticketStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ticketStatusFailed;

  /// No description provided for @ticketStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ticketStatusCancelled;

  /// No description provided for @notificationTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned'**
  String get notificationTicketAssigned;

  /// No description provided for @notificationTicketStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Ticket status changed'**
  String get notificationTicketStatusChanged;

  /// No description provided for @notificationTicketCollaboratorAdded.
  ///
  /// In en, this message translates to:
  /// **'Collaborator added'**
  String get notificationTicketCollaboratorAdded;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @ticketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ticketDescription;

  /// No description provided for @ticketPriorityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get ticketPriorityNone;

  /// No description provided for @ticketPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get ticketPriorityUrgent;

  /// No description provided for @ticketPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get ticketPriorityHigh;

  /// No description provided for @ticketPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get ticketPriorityMedium;

  /// No description provided for @ticketPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get ticketPriorityLow;

  /// No description provided for @ticketViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get ticketViewList;

  /// No description provided for @ticketViewBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get ticketViewBoard;

  /// No description provided for @ticketTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Issue title'**
  String get ticketTitlePlaceholder;

  /// No description provided for @ticketDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add description…'**
  String get ticketDescriptionPlaceholder;

  /// No description provided for @createMore.
  ///
  /// In en, this message translates to:
  /// **'Create more'**
  String get createMore;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @bulkDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tickets'**
  String get bulkDeleteTitle;

  /// No description provided for @bulkDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected tickets? This can\'t be undone.'**
  String bulkDeleteMessage(int count);

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to…'**
  String get assignTo;

  /// No description provided for @sectionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get sectionMembers;

  /// No description provided for @sectionAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get sectionAgents;

  /// No description provided for @sidebarGroupWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get sidebarGroupWork;

  /// No description provided for @sidebarGroupTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get sidebarGroupTeam;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @toggleThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleThemeLabel;

  /// No description provided for @teamsNav.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsNav;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Grüezi'**
  String get dashboardGreeting;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what your agents are working on.'**
  String get dashboardSubtitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivityTitle;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get noRecentActivity;

  /// No description provided for @noRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agent runs, pull requests, and messages will appear here.'**
  String get noRecentActivitySubtitle;

  /// No description provided for @noWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No workspace'**
  String get noWorkspace;

  /// No description provided for @allAgentsIdle.
  ///
  /// In en, this message translates to:
  /// **'All agents idle'**
  String get allAgentsIdle;

  /// No description provided for @statWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get statWorkspaces;

  /// No description provided for @statAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get statAgents;

  /// No description provided for @statRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statRunning;

  /// No description provided for @activeAgentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active agents'**
  String get activeAgentsTitle;

  /// No description provided for @noAgentProcessesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agent activity will appear here when a run starts.'**
  String get noAgentProcessesSubtitle;

  /// No description provided for @agentIdShort.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String agentIdShort(String id);

  /// No description provided for @runningProcessesLabel.
  ///
  /// In en, this message translates to:
  /// **'Running · {count}'**
  String runningProcessesLabel(int count);

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @sidebarGroupKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get sidebarGroupKnowledge;

  /// No description provided for @navMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get navMemory;

  /// No description provided for @memoryTabFacts.
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get memoryTabFacts;

  /// No description provided for @memoryTabPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get memoryTabPolicies;

  /// No description provided for @memoryTabGraph.
  ///
  /// In en, this message translates to:
  /// **'Knowledge graph'**
  String get memoryTabGraph;

  /// No description provided for @memoryNoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to view its memory.'**
  String get memoryNoWorkspace;

  /// No description provided for @topStory.
  ///
  /// In en, this message translates to:
  /// **'Top story'**
  String get topStory;

  /// No description provided for @searchArticles.
  ///
  /// In en, this message translates to:
  /// **'Search articles'**
  String get searchArticles;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get filterSaved;

  /// No description provided for @saveArticle.
  ///
  /// In en, this message translates to:
  /// **'Save article'**
  String get saveArticle;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @filterBySource.
  ///
  /// In en, this message translates to:
  /// **'Filter by source'**
  String get filterBySource;

  /// No description provided for @viewAsList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewAsList;

  /// No description provided for @viewAsGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get viewAsGrid;

  /// No description provided for @noMatchingArticles.
  ///
  /// In en, this message translates to:
  /// **'No matching articles'**
  String get noMatchingArticles;

  /// No description provided for @noMatchingArticlesBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or source filter.'**
  String get noMatchingArticlesBody;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @allCaughtUpBody.
  ///
  /// In en, this message translates to:
  /// **'No unread articles — check back later.'**
  String get allCaughtUpBody;

  /// No description provided for @openArticlesInAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Open links in the built-in reader instead of your default browser.'**
  String get openArticlesInAppDescription;

  /// No description provided for @blockAdsTrackersDescription.
  ///
  /// In en, this message translates to:
  /// **'Strip ads, trackers and cookie banners from articles you open in the reader.'**
  String get blockAdsTrackersDescription;

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

  /// No description provided for @agentQuestionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get agentQuestionSubmit;

  /// No description provided for @agentQuestionFreeformHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer…'**
  String get agentQuestionFreeformHint;

  /// No description provided for @agentQuestionAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get agentQuestionAnswerLabel;

  /// No description provided for @reviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get reviewRequested;

  /// No description provided for @loadMorePrs.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMorePrs;

  /// No description provided for @loadingMorePrs.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get loadingMorePrs;

  /// No description provided for @noPrsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No pull requests match the filters in this repo'**
  String get noPrsMatchFilters;

  /// No description provided for @connectGitHubToLoadPrs.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub to load pull requests'**
  String get connectGitHubToLoadPrs;

  /// No description provided for @noRepositoriesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No repositories configured'**
  String get noRepositoriesConfigured;

  /// No description provided for @noAuthors.
  ///
  /// In en, this message translates to:
  /// **'No authors'**
  String get noAuthors;

  /// No description provided for @noAuthorMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noAuthorMatches;

  /// Relative-time suffix for when a PR was opened
  ///
  /// In en, this message translates to:
  /// **'Opened {age}'**
  String openedAgo(String age);

  /// Relative-time suffix on a PR row
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String updatedAgo(String age);

  /// No description provided for @checksPassing.
  ///
  /// In en, this message translates to:
  /// **'Checks passing'**
  String get checksPassing;

  /// No description provided for @checksRunning.
  ///
  /// In en, this message translates to:
  /// **'Checks running'**
  String get checksRunning;

  /// No description provided for @needsYourReview.
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get needsYourReview;

  /// Tooltip summarizing a PR's added/removed line counts
  ///
  /// In en, this message translates to:
  /// **'+{additions} −{deletions} lines'**
  String diffSummary(int additions, int deletions);

  /// No description provided for @checks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checks;

  /// No description provided for @noReviewersAssigned.
  ///
  /// In en, this message translates to:
  /// **'No reviewers assigned'**
  String get noReviewersAssigned;

  /// No description provided for @noAssignees.
  ///
  /// In en, this message translates to:
  /// **'No assignees'**
  String get noAssignees;

  /// No description provided for @noChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No checks have run yet'**
  String get noChecksYet;

  /// Sidebar checks summary: number of failing checks
  ///
  /// In en, this message translates to:
  /// **'{count} failing'**
  String checksFailingCount(int count);

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @backToPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Back to pull requests'**
  String get backToPullRequests;

  /// No description provided for @pullRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pull request not found'**
  String get pullRequestNotFound;

  /// No description provided for @pullRequestNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been merged, closed, or moved.'**
  String get pullRequestNotFoundBody;

  /// No description provided for @couldntLoadPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this pull request'**
  String get couldntLoadPullRequest;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// Loading message for the PR detail screen
  ///
  /// In en, this message translates to:
  /// **'Loading pull request #{number}…'**
  String loadingPullRequestNumber(int number);

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @factsHint.
  ///
  /// In en, this message translates to:
  /// **'Facts will appear here as your agents learn.'**
  String get factsHint;

  /// No description provided for @noFactsMatch.
  ///
  /// In en, this message translates to:
  /// **'No facts match your search'**
  String get noFactsMatch;

  /// No description provided for @memoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load memory'**
  String get memoryLoadError;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @sortConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get sortConfidence;

  /// No description provided for @confidenceTooltip.
  ///
  /// In en, this message translates to:
  /// **'How sure agents are that this fact is true, from 0 to 100%.'**
  String get confidenceTooltip;

  /// No description provided for @supersededTooltip.
  ///
  /// In en, this message translates to:
  /// **'A newer fact has replaced this one.'**
  String get supersededTooltip;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @fitToView.
  ///
  /// In en, this message translates to:
  /// **'Fit to view'**
  String get fitToView;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @allTickets.
  ///
  /// In en, this message translates to:
  /// **'All tickets'**
  String get allTickets;

  /// No description provided for @projectNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNamePlaceholder;

  /// No description provided for @projectDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get projectDescriptionPlaceholder;

  /// No description provided for @projectColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get projectColorLabel;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @projectTicketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tickets in this project yet'**
  String get projectTicketsEmpty;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String projectProgress(int done, int total);

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Its tickets are kept and removed from the project.'**
  String deleteProjectConfirm(String name);

  /// No description provided for @projectStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectStatusActive;

  /// No description provided for @projectStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectStatusCompleted;

  /// No description provided for @projectStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectStatusArchived;

  /// No description provided for @markProjectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markProjectCompleted;

  /// No description provided for @markProjectActive.
  ///
  /// In en, this message translates to:
  /// **'Mark active'**
  String get markProjectActive;

  /// No description provided for @archiveProject.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveProject;

  /// No description provided for @restoreProject.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreProject;

  /// No description provided for @relations.
  ///
  /// In en, this message translates to:
  /// **'Relations'**
  String get relations;

  /// No description provided for @relateTo.
  ///
  /// In en, this message translates to:
  /// **'Relate to'**
  String get relateTo;

  /// No description provided for @relationSubIssueOf.
  ///
  /// In en, this message translates to:
  /// **'Sub-issue of…'**
  String get relationSubIssueOf;

  /// No description provided for @relationParentOf.
  ///
  /// In en, this message translates to:
  /// **'Parent of…'**
  String get relationParentOf;

  /// No description provided for @relationBlockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by…'**
  String get relationBlockedBy;

  /// No description provided for @relationBlocking.
  ///
  /// In en, this message translates to:
  /// **'Blocking…'**
  String get relationBlocking;

  /// No description provided for @relationRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Related to…'**
  String get relationRelatedTo;

  /// No description provided for @relationDuplicateOf.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of…'**
  String get relationDuplicateOf;

  /// No description provided for @relationGroupParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get relationGroupParent;

  /// No description provided for @relationGroupSubIssues.
  ///
  /// In en, this message translates to:
  /// **'Sub-issues'**
  String get relationGroupSubIssues;

  /// No description provided for @relationGroupBlockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by'**
  String get relationGroupBlockedBy;

  /// No description provided for @relationGroupBlocking.
  ///
  /// In en, this message translates to:
  /// **'Blocking'**
  String get relationGroupBlocking;

  /// No description provided for @relationGroupRelated.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get relationGroupRelated;

  /// No description provided for @relationGroupDuplicateOf.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of'**
  String get relationGroupDuplicateOf;

  /// No description provided for @relationGroupDuplicatedBy.
  ///
  /// In en, this message translates to:
  /// **'Duplicated by'**
  String get relationGroupDuplicatedBy;

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @ticketIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied ticket ID'**
  String get ticketIdCopied;

  /// No description provided for @selectTicket.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket'**
  String get selectTicket;

  /// No description provided for @searchTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Search tickets…'**
  String get searchTicketsHint;

  /// No description provided for @noMatchingTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets match'**
  String get noMatchingTickets;

  /// No description provided for @addToProject.
  ///
  /// In en, this message translates to:
  /// **'Add to project'**
  String get addToProject;

  /// No description provided for @activeFleet.
  ///
  /// In en, this message translates to:
  /// **'Active fleet'**
  String get activeFleet;

  /// No description provided for @agentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent} other{{count} agents}}'**
  String agentsCountLabel(int count);

  /// No description provided for @blockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedStatus;

  /// No description provided for @failedStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedStatus;

  /// No description provided for @neverRunStatus.
  ///
  /// In en, this message translates to:
  /// **'Never run'**
  String get neverRunStatus;

  /// No description provided for @noActiveRun.
  ///
  /// In en, this message translates to:
  /// **'No active run'**
  String get noActiveRun;

  /// No description provided for @allPullRequests.
  ///
  /// In en, this message translates to:
  /// **'All pull requests'**
  String get allPullRequests;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @needsYouNow.
  ///
  /// In en, this message translates to:
  /// **'Needs you now'**
  String get needsYouNow;

  /// No description provided for @pipelinesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pipelines'**
  String get pipelinesSectionTitle;

  /// No description provided for @allRuns.
  ///
  /// In en, this message translates to:
  /// **'All runs'**
  String get allRuns;

  /// No description provided for @triage.
  ///
  /// In en, this message translates to:
  /// **'Triage'**
  String get triage;

  /// No description provided for @agentsRunningCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent running} other{{count} agents running}}'**
  String agentsRunningCount(int count);

  /// No description provided for @blockedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} blocked'**
  String blockedCountLabel(int count);

  /// No description provided for @needsYouCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} needs you'**
  String needsYouCountLabel(int count);

  /// No description provided for @reviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{prs, plural, =1{1 PR} other{{prs} PRs}} awaiting your review across {repos, plural, =1{1 repo} other{{repos} repos}}'**
  String reviewSummary(int prs, int repos);

  /// No description provided for @reviewsAwaitingYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}} awaiting you'**
  String reviewsAwaitingYou(int count);

  /// No description provided for @reviewsOverTwoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 over 2 days old} other{{count} over 2 days old}}'**
  String reviewsOverTwoDays(int count);

  /// No description provided for @agentBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is blocked'**
  String agentBlockedTitle(String name);

  /// No description provided for @agentBlockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting on your confirmation'**
  String get agentBlockedSubtitle;

  /// No description provided for @pipelineFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pipeline failed'**
  String get pipelineFailedTitle;

  /// No description provided for @prStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'PR {number} stale'**
  String prStaleTitle(String number);

  /// No description provided for @prStaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get prStaleSubtitle;

  /// No description provided for @reviewRequestedBadge.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get reviewRequestedBadge;

  /// No description provided for @draftBadge.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftBadge;

  /// No description provided for @staleLabel.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get staleLabel;

  /// No description provided for @stepsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps'**
  String stepsProgress(int done, int total);

  /// No description provided for @allCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews, blocks, or failures need you right now.'**
  String get allCaughtUpSubtitle;

  /// No description provided for @dashboardGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Grüezi, {name}'**
  String dashboardGreetingNamed(String name);

  /// No description provided for @workspaceEyebrow.
  ///
  /// In en, this message translates to:
  /// **'{name} workspace'**
  String workspaceEyebrow(String name);

  /// No description provided for @pipelineTriggerNode.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get pipelineTriggerNode;

  /// No description provided for @priorityReviewsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open PRs that request your review and have been waiting more than 24 hours.'**
  String get priorityReviewsTooltip;

  /// Eyebrow label on the manage-workspaces page
  ///
  /// In en, this message translates to:
  /// **'Workspace settings'**
  String get workspaceSettings;

  /// Subtitle under the manage-workspaces title
  ///
  /// In en, this message translates to:
  /// **'Rename a workspace and change its mark — pick one on the left to edit it.'**
  String get manageWorkspacesSubtitle;

  /// Count of workspaces shown in the page eyebrow
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workspaces} =1{1 workspace} other{{count} workspaces}}'**
  String workspaceCount(int count);

  /// Workspace list row subtitle: repository and agent counts
  ///
  /// In en, this message translates to:
  /// **'{repos, plural, =0{No repos} =1{1 repo} other{{repos} repos}} · {agents, plural, =0{0 agents} =1{1 agent} other{{agents} agents}}'**
  String workspaceReposAgents(int repos, int agents);

  /// Identity panel title on the manage-workspaces page
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// Button to upload a workspace logo image
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// Helper text under the workspace logo editor
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG or GIF up to 2 MB. Otherwise we\'ll use the workspace initial.'**
  String get workspaceLogoHint;

  /// Helper text under the workspace name field
  ///
  /// In en, this message translates to:
  /// **'Shown in the switcher, the breadcrumb and on every screen.'**
  String get workspaceNameFieldHelp;

  /// Title of the destructive-actions panel
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// Label of the delete-workspace danger row
  ///
  /// In en, this message translates to:
  /// **'Delete this workspace'**
  String get deleteThisWorkspace;

  /// Description in the delete-workspace danger row
  ///
  /// In en, this message translates to:
  /// **'Permanently removes {name}, its repository connections, agents and memory. This can\'t be undone.'**
  String deleteWorkspaceLongDescription(String name);

  /// Button to discard unsaved workspace edits
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Confirmation when switching away from an edited workspace
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes to {name}?'**
  String discardChangesQuestion(String name);

  /// Toast shown after saving workspace edits
  ///
  /// In en, this message translates to:
  /// **'Workspace updated'**
  String get workspaceUpdated;

  /// Tooltip/label for editing the PR title
  ///
  /// In en, this message translates to:
  /// **'Edit title'**
  String get editTitle;

  /// Label for editing the PR description
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get editDescription;

  /// Label for the action that opens the editor to add a PR description when none exists yet
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get addDescription;

  /// Placeholder for the PR title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get prTitlePlaceholder;

  /// Placeholder for the PR body editor
  ///
  /// In en, this message translates to:
  /// **'Leave a description'**
  String get prBodyPlaceholder;

  /// Write tab label in the markdown editor
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get write;

  /// Label for the source-diff segment of a file's diff/preview toggle in the PR diff viewer
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get diff;

  /// Preview tab label in the markdown editor
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Label for the pull request template picker on the compose screen
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get prTemplateLabel;

  /// Label for the repository's single default pull request template
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get prTemplateDefault;

  /// Button to add reviewers to a PR
  ///
  /// In en, this message translates to:
  /// **'Add reviewers'**
  String get addReviewers;

  /// Button to add assignees to a PR
  ///
  /// In en, this message translates to:
  /// **'Add assignees'**
  String get addAssignees;

  /// Search hint in the assignee picker
  ///
  /// In en, this message translates to:
  /// **'Search people…'**
  String get searchUsers;

  /// Search hint in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'Search people and teams…'**
  String get searchReviewers;

  /// Section header for users in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get usersSectionLabel;

  /// Section header for teams in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsSectionLabel;

  /// Empty state in the assignee picker
  ///
  /// In en, this message translates to:
  /// **'No matching people'**
  String get noMatchingUsers;

  /// Empty state in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatchingReviewers;

  /// Confirm button with selected count
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String addCount(int count);

  /// Tooltip on the code-owner shield
  ///
  /// In en, this message translates to:
  /// **'Required by code owners'**
  String get requiredByCodeOwners;

  /// Caption: a team member reviewed on behalf of the team
  ///
  /// In en, this message translates to:
  /// **'via {login}'**
  String reviewedOnBehalfOf(String login);

  /// Generic label for a team reviewer
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// Markdown toolbar button: bold
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get markdownBold;

  /// Markdown toolbar button: italic
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get markdownItalic;

  /// Markdown toolbar button: heading
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get markdownHeading;

  /// Markdown toolbar button: bulleted list
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get markdownBulletList;

  /// Markdown toolbar button: checklist
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get markdownChecklist;

  /// Markdown toolbar button: code
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get markdownCode;

  /// Markdown toolbar button: link
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get markdownLink;

  /// Markdown toolbar button: quote
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get markdownQuote;

  /// Error when updating the PR title fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update title: {error}'**
  String failedToUpdateTitle(String error);

  /// Error when updating the PR description fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update description: {error}'**
  String failedToUpdateDescription(String error);

  /// Error when updating reviewers fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update reviewers: {error}'**
  String failedToUpdateReviewers(String error);

  /// Error when updating assignees fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update assignees: {error}'**
  String failedToUpdateAssignees(String error);

  /// Confirmation prompt when discarding unsaved edits
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardChangesConfirm;

  /// No description provided for @newPr.
  ///
  /// In en, this message translates to:
  /// **'New PR'**
  String get newPr;

  /// No description provided for @openPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Open a pull request'**
  String get openPullRequest;

  /// No description provided for @composePrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From a branch you\'ve pushed — no agents or tickets involved'**
  String get composePrSubtitle;

  /// No description provided for @createAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Create as draft'**
  String get createAsDraft;

  /// No description provided for @composePrNoRepo.
  ///
  /// In en, this message translates to:
  /// **'No GitHub repository selected'**
  String get composePrNoRepo;

  /// No description provided for @composePrNoRepoHint.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace with a GitHub-linked repository to open a pull request.'**
  String get composePrNoRepoHint;

  /// No description provided for @composePrPickBranches.
  ///
  /// In en, this message translates to:
  /// **'Pick a base and compare branch to preview the changes.'**
  String get composePrPickBranches;

  /// No description provided for @composePrNothingToCompare.
  ///
  /// In en, this message translates to:
  /// **'There are no changes between these branches.'**
  String get composePrNothingToCompare;

  /// No description provided for @repository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get repository;

  /// No description provided for @baseBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseBranchLabel;

  /// No description provided for @compareBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareBranchLabel;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get selectBranch;

  /// No description provided for @navMeetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get navMeetings;

  /// No description provided for @meetingsNoWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to see meetings.'**
  String get meetingsNoWorkspace;

  /// No description provided for @meetingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meetings yet. Start a recording to capture one.'**
  String get meetingsEmpty;

  /// No description provided for @meetingsStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get meetingsStartRecording;

  /// No description provided for @meetingsStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get meetingsStopRecording;

  /// No description provided for @meetingsProcessing.
  ///
  /// In en, this message translates to:
  /// **'Summarizing…'**
  String get meetingsProcessing;

  /// No description provided for @meetingEnhancedNotes.
  ///
  /// In en, this message translates to:
  /// **'Enhanced notes'**
  String get meetingEnhancedNotes;

  /// No description provided for @meetingYourNotes.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get meetingYourNotes;

  /// No description provided for @meetingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Jot quick notes — the agent expands them after the meeting.'**
  String get meetingNotesHint;

  /// No description provided for @meetingTranscriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get meetingTranscriptTitle;

  /// No description provided for @meetingNoTranscriptYet.
  ///
  /// In en, this message translates to:
  /// **'The transcript appears here as people speak.'**
  String get meetingNoTranscriptYet;

  /// No description provided for @meetingSpeakerMe.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get meetingSpeakerMe;

  /// No description provided for @meetingSpeakerThem.
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get meetingSpeakerThem;

  /// No description provided for @meetingStatusRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get meetingStatusRecording;

  /// No description provided for @meetingStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get meetingStatusProcessing;

  /// No description provided for @meetingStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get meetingStatusDone;

  /// No description provided for @meetingStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get meetingStatusFailed;

  /// No description provided for @keybindingGoToMeetings.
  ///
  /// In en, this message translates to:
  /// **'Go to meetings'**
  String get keybindingGoToMeetings;

  /// No description provided for @keybindingNavigateToTheMeetingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the meetings list'**
  String get keybindingNavigateToTheMeetingsDescription;

  /// No description provided for @meetingsOverlineKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get meetingsOverlineKnowledge;

  /// No description provided for @meetingsOverlineEngine.
  ///
  /// In en, this message translates to:
  /// **'On-device speech recognition'**
  String get meetingsOverlineEngine;

  /// No description provided for @meetingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local meeting capture. We tap the meeting audio and your mic, transcribe on-device, and let an agent turn your sparse notes into decisions and action items — no bot ever joins the call.'**
  String get meetingsSubtitle;

  /// No description provided for @meetingsRecordMeeting.
  ///
  /// In en, this message translates to:
  /// **'Record meeting'**
  String get meetingsRecordMeeting;

  /// No description provided for @meetingsProcessingNow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 processing now} other{{count} processing now}}'**
  String meetingsProcessingNow(int count);

  /// No description provided for @meetingsStatThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get meetingsStatThisWeek;

  /// No description provided for @meetingsStatThisWeekUnit.
  ///
  /// In en, this message translates to:
  /// **'meetings captured'**
  String get meetingsStatThisWeekUnit;

  /// No description provided for @meetingsStatRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get meetingsStatRecorded;

  /// No description provided for @meetingsStatRecordedUnit.
  ///
  /// In en, this message translates to:
  /// **'transcribed locally'**
  String get meetingsStatRecordedUnit;

  /// No description provided for @meetingsStatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get meetingsStatOpen;

  /// No description provided for @meetingsStatOpenUnit.
  ///
  /// In en, this message translates to:
  /// **'action items pending'**
  String get meetingsStatOpenUnit;

  /// No description provided for @meetingsStatLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get meetingsStatLogged;

  /// No description provided for @meetingsStatLoggedUnit.
  ///
  /// In en, this message translates to:
  /// **'decisions extracted'**
  String get meetingsStatLoggedUnit;

  /// No description provided for @meetingsCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver-free system-audio capture is armed.'**
  String get meetingsCaptureTitle;

  /// No description provided for @meetingsCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Control Center taps the speaker output of whatever app you are in — Slack Huddle, Meet, Zoom, Tuple — plus your microphone, and decodes both streams on this device.'**
  String get meetingsCaptureBody;

  /// No description provided for @meetingsCapturePermission.
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get meetingsCapturePermission;

  /// No description provided for @meetingsCaptureOnDevice.
  ///
  /// In en, this message translates to:
  /// **'100% on-device'**
  String get meetingsCaptureOnDevice;

  /// No description provided for @meetingsCaptureNoBot.
  ///
  /// In en, this message translates to:
  /// **'No bot joins'**
  String get meetingsCaptureNoBot;

  /// No description provided for @meetingsScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All meetings'**
  String get meetingsScopeAll;

  /// No description provided for @meetingsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get meetingsFilterAll;

  /// No description provided for @meetingsFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get meetingsFilterDone;

  /// No description provided for @meetingsFilterProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get meetingsFilterProcessing;

  /// No description provided for @meetingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by title, person, app…'**
  String get meetingsSearchHint;

  /// No description provided for @meetingsBucketToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get meetingsBucketToday;

  /// No description provided for @meetingsBucketYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get meetingsBucketYesterday;

  /// No description provided for @meetingsBucketEarlierThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Earlier this week'**
  String get meetingsBucketEarlierThisWeek;

  /// No description provided for @meetingsBucketLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get meetingsBucketLastWeek;

  /// No description provided for @meetingsBucketOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get meetingsBucketOlder;

  /// No description provided for @meetingsDecisionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 decision} other{{count} decisions}}'**
  String meetingsDecisionsCount(int count);

  /// No description provided for @meetingsActionItemsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} action items'**
  String meetingsActionItemsProgress(int done, int total);

  /// No description provided for @meetingsEnhancedPill.
  ///
  /// In en, this message translates to:
  /// **'enhanced'**
  String get meetingsEnhancedPill;

  /// No description provided for @meetingsTranscribing.
  ///
  /// In en, this message translates to:
  /// **'transcribing & summarizing…'**
  String get meetingsTranscribing;

  /// No description provided for @meetingsOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get meetingsOpenAction;

  /// No description provided for @meetingsStopProcessing.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get meetingsStopProcessing;

  /// No description provided for @meetingsStillTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Still transcribing — the summary appears when it finishes.'**
  String get meetingsStillTranscribing;

  /// No description provided for @meetingsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No meetings match'**
  String get meetingsNoMatch;

  /// No description provided for @meetingsNoMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term.'**
  String get meetingsNoMatchHint;

  /// No description provided for @meetingBackAllMeetings.
  ///
  /// In en, this message translates to:
  /// **'All meetings'**
  String get meetingBackAllMeetings;

  /// No description provided for @meetingPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String meetingPeopleCount(int count);

  /// No description provided for @meetingReRunSummary.
  ///
  /// In en, this message translates to:
  /// **'Re-run summary'**
  String get meetingReRunSummary;

  /// No description provided for @meetingExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get meetingExport;

  /// No description provided for @meetingAugmentingBanner.
  ///
  /// In en, this message translates to:
  /// **'Augmenting your notes from the transcript — extracting decisions and action items…'**
  String get meetingAugmentingBanner;

  /// No description provided for @meetingTabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get meetingTabNotes;

  /// No description provided for @meetingTabTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get meetingTabTranscript;

  /// No description provided for @meetingTabActionItems.
  ///
  /// In en, this message translates to:
  /// **'Action items'**
  String get meetingTabActionItems;

  /// No description provided for @meetingTabDecisions.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get meetingTabDecisions;

  /// No description provided for @meetingNotesEnhancedToggle.
  ///
  /// In en, this message translates to:
  /// **'Enhanced'**
  String get meetingNotesEnhancedToggle;

  /// No description provided for @meetingNotesYoursToggle.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get meetingNotesYoursToggle;

  /// No description provided for @meetingEnhancedByAgent.
  ///
  /// In en, this message translates to:
  /// **'Enhanced by agent · from transcript'**
  String get meetingEnhancedByAgent;

  /// No description provided for @meetingEnhancedPending.
  ///
  /// In en, this message translates to:
  /// **'The agent is still working on this summary.'**
  String get meetingEnhancedPending;

  /// No description provided for @meetingNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No enhanced notes yet.'**
  String get meetingNotesEmpty;

  /// No description provided for @meetingNotesSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get meetingNotesSavedLocally;

  /// No description provided for @meetingNotesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get meetingNotesSaving;

  /// No description provided for @meetingViewFullTranscript.
  ///
  /// In en, this message translates to:
  /// **'View full transcript'**
  String get meetingViewFullTranscript;

  /// No description provided for @meetingTranscriptSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the transcript…'**
  String get meetingTranscriptSearchHint;

  /// No description provided for @meetingSpeakerEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get meetingSpeakerEveryone;

  /// No description provided for @meetingSpeakerOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get meetingSpeakerOthers;

  /// No description provided for @meetingTranscriptEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transcript yet.'**
  String get meetingTranscriptEmpty;

  /// No description provided for @meetingActionItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No action items extracted.'**
  String get meetingActionItemsEmpty;

  /// No description provided for @meetingActionItemFrom.
  ///
  /// In en, this message translates to:
  /// **'from this meeting'**
  String get meetingActionItemFrom;

  /// No description provided for @meetingCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Create ticket'**
  String get meetingCreateTicket;

  /// No description provided for @meetingTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket {key} created and dispatched.'**
  String meetingTicketCreated(String key);

  /// No description provided for @meetingTicketFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the ticket.'**
  String get meetingTicketFailed;

  /// No description provided for @meetingDecisionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No decisions logged.'**
  String get meetingDecisionsEmpty;

  /// No description provided for @meetingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit title'**
  String get meetingEditTitle;

  /// No description provided for @meetingTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get meetingTitleLabel;

  /// No description provided for @meetingAddActionItem.
  ///
  /// In en, this message translates to:
  /// **'Add action item'**
  String get meetingAddActionItem;

  /// No description provided for @meetingEditActionItem.
  ///
  /// In en, this message translates to:
  /// **'Edit action item'**
  String get meetingEditActionItem;

  /// No description provided for @meetingDeleteActionItem.
  ///
  /// In en, this message translates to:
  /// **'Delete action item'**
  String get meetingDeleteActionItem;

  /// No description provided for @meetingActionItemContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Action item'**
  String get meetingActionItemContentLabel;

  /// No description provided for @meetingActionItemContentHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to happen?'**
  String get meetingActionItemContentHint;

  /// No description provided for @meetingActionItemOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get meetingActionItemOwnerLabel;

  /// No description provided for @meetingActionItemOwnerHint.
  ///
  /// In en, this message translates to:
  /// **'Who\'s responsible? (optional)'**
  String get meetingActionItemOwnerHint;

  /// No description provided for @meetingAddDecision.
  ///
  /// In en, this message translates to:
  /// **'Add decision'**
  String get meetingAddDecision;

  /// No description provided for @meetingEditDecision.
  ///
  /// In en, this message translates to:
  /// **'Edit decision'**
  String get meetingEditDecision;

  /// No description provided for @meetingDeleteDecision.
  ///
  /// In en, this message translates to:
  /// **'Delete decision'**
  String get meetingDeleteDecision;

  /// No description provided for @meetingDecisionContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get meetingDecisionContentLabel;

  /// No description provided for @meetingDecisionContentHint.
  ///
  /// In en, this message translates to:
  /// **'What was decided?'**
  String get meetingDecisionContentHint;

  /// No description provided for @meetingReRunStarted.
  ///
  /// In en, this message translates to:
  /// **'Re-running the summarizer on the transcript…'**
  String get meetingReRunStarted;

  /// No description provided for @meetingReRunDone.
  ///
  /// In en, this message translates to:
  /// **'Summary refreshed.'**
  String get meetingReRunDone;

  /// No description provided for @meetingReRunNoTranscript.
  ///
  /// In en, this message translates to:
  /// **'There\'s no transcript to summarize yet.'**
  String get meetingReRunNoTranscript;

  /// No description provided for @meetingExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Notes copied to the clipboard as Markdown.'**
  String get meetingExportCopied;

  /// No description provided for @meetingExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Meeting exported.'**
  String get meetingExportSaved;

  /// No description provided for @meetingExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String meetingExportFailed(String error);

  /// No description provided for @meetingExportNothing.
  ///
  /// In en, this message translates to:
  /// **'There\'s nothing to export yet.'**
  String get meetingExportNothing;

  /// No description provided for @meetingPlaybackPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get meetingPlaybackPlay;

  /// No description provided for @meetingPlaybackPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get meetingPlaybackPause;

  /// No description provided for @meetingPlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio playback is unavailable on this device.'**
  String get meetingPlaybackUnavailable;

  /// No description provided for @meetingDetectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting detected'**
  String get meetingDetectedTitle;

  /// No description provided for @meetingDetectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looks like \"{label}\" is happening. Record it?'**
  String meetingDetectedSubtitle(String label);

  /// No description provided for @meetingDetectedSubtitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Looks like a meeting is happening. Record it?'**
  String get meetingDetectedSubtitleGeneric;

  /// No description provided for @meetingDetectedRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get meetingDetectedRecord;

  /// No description provided for @meetingDetectedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get meetingDetectedDismiss;

  /// No description provided for @meetingAutoStopTitle.
  ///
  /// In en, this message translates to:
  /// **'This meeting looks over. Stop recording?'**
  String get meetingAutoStopTitle;

  /// No description provided for @meetingAutoStopStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get meetingAutoStopStop;

  /// No description provided for @meetingAutoStopKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep recording'**
  String get meetingAutoStopKeep;

  /// No description provided for @meetingAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect meetings'**
  String get meetingAutoDetect;

  /// No description provided for @meetingAutoDetectDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch the calendar and conferencing apps, and offer to record when a meeting starts.'**
  String get meetingAutoDetectDescription;

  /// No description provided for @meetingsRecordingCrumb.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get meetingsRecordingCrumb;

  /// No description provided for @meetingRecordTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting title'**
  String get meetingRecordTitleHint;

  /// No description provided for @meetingRecordTappingLabel.
  ///
  /// In en, this message translates to:
  /// **'Tapping:'**
  String get meetingRecordTappingLabel;

  /// No description provided for @meetingRecordMic.
  ///
  /// In en, this message translates to:
  /// **'Mic'**
  String get meetingRecordMic;

  /// No description provided for @meetingRecordSystemAudio.
  ///
  /// In en, this message translates to:
  /// **'System audio'**
  String get meetingRecordSystemAudio;

  /// No description provided for @meetingRecordPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get meetingRecordPause;

  /// No description provided for @meetingRecordResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get meetingRecordResume;

  /// No description provided for @meetingRecordStop.
  ///
  /// In en, this message translates to:
  /// **'Stop & summarize'**
  String get meetingRecordStop;

  /// No description provided for @meetingRecordYourNotes.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get meetingRecordYourNotes;

  /// No description provided for @meetingRecordNotesTagline.
  ///
  /// In en, this message translates to:
  /// **'jot sparsely — the agent fills the rest'**
  String get meetingRecordNotesTagline;

  /// No description provided for @meetingRecordNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type while you listen. A few fragments is enough — after you stop, the agent expands them using the transcript.'**
  String get meetingRecordNotesPlaceholder;

  /// No description provided for @meetingRecordLiveTranscript.
  ///
  /// In en, this message translates to:
  /// **'Live transcript'**
  String get meetingRecordLiveTranscript;

  /// No description provided for @meetingRecordDecoding.
  ///
  /// In en, this message translates to:
  /// **'decoding on-device'**
  String get meetingRecordDecoding;

  /// No description provided for @meetingRecordListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… speech appears here within a second or two, tagged You / Others.'**
  String get meetingRecordListening;

  /// No description provided for @meetingRecordPausedHint.
  ///
  /// In en, this message translates to:
  /// **'Paused — audio is ignored until you resume.'**
  String get meetingRecordPausedHint;

  /// No description provided for @meetingRecordNotActive.
  ///
  /// In en, this message translates to:
  /// **'No active recording.'**
  String get meetingRecordNotActive;

  /// No description provided for @meetingHudRecording.
  ///
  /// In en, this message translates to:
  /// **'recording'**
  String get meetingHudRecording;

  /// No description provided for @meetingHudPaused.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get meetingHudPaused;

  /// No description provided for @meetingHudOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get meetingHudOpen;

  /// No description provided for @meetingHudStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get meetingHudStop;

  /// No description provided for @meetingToolbarPopOut.
  ///
  /// In en, this message translates to:
  /// **'Pop out'**
  String get meetingToolbarPopOut;

  /// No description provided for @meetingToolbarHoldToStop.
  ///
  /// In en, this message translates to:
  /// **'Hold to stop recording'**
  String get meetingToolbarHoldToStop;

  /// No description provided for @meetingToolbarSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting recording toolbar'**
  String get meetingToolbarSemanticLabel;

  /// No description provided for @orchestrate.
  ///
  /// In en, this message translates to:
  /// **'Orchestrate'**
  String get orchestrate;

  /// No description provided for @orchestrationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Orchestration unavailable'**
  String get orchestrationUnavailable;

  /// No description provided for @orchestrationApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve plan'**
  String get orchestrationApprove;

  /// No description provided for @orchestrationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get orchestrationReject;

  /// No description provided for @orchestrationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel orchestration'**
  String get orchestrationCancel;

  /// No description provided for @orchestrationRolesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} roles — {hires} new hires'**
  String orchestrationRolesSummary(int count, int hires);

  /// No description provided for @orchestrationSubTicketsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} sub-tickets'**
  String orchestrationSubTicketsSummary(int count);

  /// No description provided for @orchestrationEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost: \${amount}'**
  String orchestrationEstimatedCost(String amount);

  /// No description provided for @orchestrationProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} sub-tickets done'**
  String orchestrationProgress(int done, int total);

  /// No description provided for @orchestrationStatusProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get orchestrationStatusProposed;

  /// No description provided for @orchestrationStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get orchestrationStatusApproved;

  /// No description provided for @orchestrationStatusExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get orchestrationStatusExecuting;

  /// No description provided for @orchestrationStatusSynthesizing.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing'**
  String get orchestrationStatusSynthesizing;

  /// No description provided for @orchestrationStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orchestrationStatusCompleted;

  /// No description provided for @orchestrationStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get orchestrationStatusFailed;

  /// No description provided for @orchestrationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orchestrationStatusCancelled;

  /// No description provided for @messageFailed.
  ///
  /// In en, this message translates to:
  /// **'Run failed'**
  String get messageFailed;

  /// No description provided for @retried.
  ///
  /// In en, this message translates to:
  /// **'Retried'**
  String get retried;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @recentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get recentRuns;

  /// No description provided for @runIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Run id copied'**
  String get runIdCopied;

  /// No description provided for @copyRunId.
  ///
  /// In en, this message translates to:
  /// **'Copy run id'**
  String get copyRunId;

  /// No description provided for @copyLogPath.
  ///
  /// In en, this message translates to:
  /// **'Copy log path'**
  String get copyLogPath;

  /// No description provided for @silenceTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Silence timeout (minutes)'**
  String get silenceTimeoutLabel;

  /// No description provided for @silenceTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 15 — terminate a run after this long with no output'**
  String get silenceTimeoutHint;

  /// No description provided for @ticketOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get ticketOutput;

  /// No description provided for @missingRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Missing required field: {field}'**
  String missingRequiredField(String field);

  /// No description provided for @capabilityJsonMode.
  ///
  /// In en, this message translates to:
  /// **'JSON mode'**
  String get capabilityJsonMode;

  /// No description provided for @capabilityModelSelection.
  ///
  /// In en, this message translates to:
  /// **'Model selection'**
  String get capabilityModelSelection;

  /// No description provided for @transcriptThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get transcriptThinking;

  /// No description provided for @transcriptThoughtFor.
  ///
  /// In en, this message translates to:
  /// **'Thought for {duration}'**
  String transcriptThoughtFor(String duration);

  /// No description provided for @transcriptStatusMakingEdits.
  ///
  /// In en, this message translates to:
  /// **'Making edits…'**
  String get transcriptStatusMakingEdits;

  /// No description provided for @transcriptStatusReadingFiles.
  ///
  /// In en, this message translates to:
  /// **'Reading files…'**
  String get transcriptStatusReadingFiles;

  /// No description provided for @transcriptStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching codebase…'**
  String get transcriptStatusSearching;

  /// No description provided for @transcriptStatusRunningCommands.
  ///
  /// In en, this message translates to:
  /// **'Running commands…'**
  String get transcriptStatusRunningCommands;

  /// No description provided for @transcriptStatusResponding.
  ///
  /// In en, this message translates to:
  /// **'Responding…'**
  String get transcriptStatusResponding;

  /// No description provided for @transcriptStatusRunningTool.
  ///
  /// In en, this message translates to:
  /// **'Running {tool}…'**
  String transcriptStatusRunningTool(String tool);

  /// No description provided for @transcriptInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get transcriptInput;

  /// No description provided for @transcriptOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get transcriptOutput;

  /// No description provided for @transcriptShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get transcriptShowMore;

  /// No description provided for @transcriptShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get transcriptShowLess;

  /// No description provided for @transcriptErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get transcriptErrorLabel;

  /// No description provided for @transcriptInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get transcriptInterrupted;

  /// No description provided for @transcriptSandboxBlocked.
  ///
  /// In en, this message translates to:
  /// **'Sandbox blocked an action'**
  String get transcriptSandboxBlocked;

  /// No description provided for @transcriptOutputTruncated.
  ///
  /// In en, this message translates to:
  /// **'Output truncated'**
  String get transcriptOutputTruncated;

  /// No description provided for @transcriptDiffStats.
  ///
  /// In en, this message translates to:
  /// **'{adds} additions, {dels} deletions'**
  String transcriptDiffStats(int adds, int dels);

  /// No description provided for @meetingSpeakerPerson.
  ///
  /// In en, this message translates to:
  /// **'Person {number}'**
  String meetingSpeakerPerson(int number);

  /// No description provided for @meetingRenameSpeakerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename speaker'**
  String get meetingRenameSpeakerTooltip;

  /// No description provided for @meetingRenameSpeakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename speaker'**
  String get meetingRenameSpeakerTitle;

  /// No description provided for @meetingSpeakerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get meetingSpeakerNameLabel;

  /// No description provided for @meetingSpeakerSuggestFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'From this meeting\'s invitees'**
  String get meetingSpeakerSuggestFromCalendar;

  /// No description provided for @meetingRenameSpeakerApplyAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all blocks from this speaker'**
  String get meetingRenameSpeakerApplyAll;

  /// No description provided for @meetingRenameSpeakerScopeHint.
  ///
  /// In en, this message translates to:
  /// **'When off, only the selected line is renamed.'**
  String get meetingRenameSpeakerScopeHint;

  /// No description provided for @meetingLinkEvent.
  ///
  /// In en, this message translates to:
  /// **'Link to event'**
  String get meetingLinkEvent;

  /// No description provided for @meetingChangeEvent.
  ///
  /// In en, this message translates to:
  /// **'Change event'**
  String get meetingChangeEvent;

  /// No description provided for @meetingLinkEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Link to a calendar event'**
  String get meetingLinkEventTitle;

  /// No description provided for @meetingLinkEventSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get meetingLinkEventSearchHint;

  /// No description provided for @meetingLinkEventEmpty.
  ///
  /// In en, this message translates to:
  /// **'No nearby calendar events'**
  String get meetingLinkEventEmpty;

  /// No description provided for @meetingUnlinkEvent.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get meetingUnlinkEvent;

  /// No description provided for @calendarLinkExistingMeeting.
  ///
  /// In en, this message translates to:
  /// **'Link to existing meeting'**
  String get calendarLinkExistingMeeting;

  /// No description provided for @calendarLinkMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a meeting'**
  String get calendarLinkMeetingTitle;

  /// No description provided for @calendarLinkMeetingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search meetings'**
  String get calendarLinkMeetingSearchHint;

  /// No description provided for @calendarLinkMeetingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meetings to link'**
  String get calendarLinkMeetingEmpty;

  /// No description provided for @meetingRenameSpeakerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename the speaker'**
  String get meetingRenameSpeakerFailed;

  /// No description provided for @calendarLinkUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the calendar link'**
  String get calendarLinkUpdateFailed;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @meetingSaveVoiceProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Save voice profile?'**
  String get meetingSaveVoiceProfileTitle;

  /// Body of the save-voice-profile prompt after renaming a speaker
  ///
  /// In en, this message translates to:
  /// **'Recognize {name} automatically in future meetings by saving their voiceprint.'**
  String meetingSaveVoiceProfileBody(String name);

  /// Toast shown after a voice profile is saved
  ///
  /// In en, this message translates to:
  /// **'Saved voice profile for {name}'**
  String meetingVoiceProfileSaved(String name);

  /// No description provided for @meetingVoiceProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the voice profile'**
  String get meetingVoiceProfileSaveFailed;

  /// No description provided for @voiceProfilesSection.
  ///
  /// In en, this message translates to:
  /// **'Voice profiles'**
  String get voiceProfilesSection;

  /// No description provided for @voiceProfilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Saved voices are recognized automatically in future meetings.'**
  String get voiceProfilesDescription;

  /// No description provided for @voiceProfilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved voices yet. Name a speaker in a meeting transcript, then choose \"Save voice profile\".'**
  String get voiceProfilesEmpty;

  /// How many voice samples have been enrolled for a profile
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sample} other{{count} samples}}'**
  String voiceProfileSamples(int count);

  /// No description provided for @renameVoiceProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename voice profile'**
  String get renameVoiceProfileTitle;

  /// No description provided for @deleteVoiceProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete voice profile?'**
  String get deleteVoiceProfileTitle;

  /// Body of the delete-voice-profile confirmation
  ///
  /// In en, this message translates to:
  /// **'Stop recognizing {name}? Their saved voiceprint is removed. Names already applied in past meetings are kept.'**
  String deleteVoiceProfileBody(String name);

  /// No description provided for @remoteControl.
  ///
  /// In en, this message translates to:
  /// **'Remote control'**
  String get remoteControl;

  /// No description provided for @remoteControlListening.
  ///
  /// In en, this message translates to:
  /// **'Listening for devices'**
  String get remoteControlListening;

  /// No description provided for @remoteControlListenerStopped.
  ///
  /// In en, this message translates to:
  /// **'Listener stopped'**
  String get remoteControlListenerStopped;

  /// No description provided for @remoteControlStartToAccept.
  ///
  /// In en, this message translates to:
  /// **'Start the listener to accept phone connections.'**
  String get remoteControlStartToAccept;

  /// No description provided for @remoteControlStartOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Start on app launch'**
  String get remoteControlStartOnLaunch;

  /// No description provided for @remoteControlWhenOffStaysStopped.
  ///
  /// In en, this message translates to:
  /// **'When off, the listener stays stopped until you start it.'**
  String get remoteControlWhenOffStaysStopped;

  /// No description provided for @remoteControlRestartToApply.
  ///
  /// In en, this message translates to:
  /// **'Restart the listener to apply changes.'**
  String get remoteControlRestartToApply;

  /// No description provided for @remoteControlSignalingUrl.
  ///
  /// In en, this message translates to:
  /// **'Signaling broker URL'**
  String get remoteControlSignalingUrl;

  /// No description provided for @remoteControlSignalingHint.
  ///
  /// In en, this message translates to:
  /// **'wss:// broker that relays the pairing handshake only.'**
  String get remoteControlSignalingHint;

  /// No description provided for @remoteControlStunServers.
  ///
  /// In en, this message translates to:
  /// **'STUN servers'**
  String get remoteControlStunServers;

  /// No description provided for @remoteControlStunHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated STUN URLs. No TURN by design.'**
  String get remoteControlStunHint;

  /// No description provided for @remoteControlPwaHost.
  ///
  /// In en, this message translates to:
  /// **'Phone app host'**
  String get remoteControlPwaHost;

  /// No description provided for @remoteControlPwaHostHint.
  ///
  /// In en, this message translates to:
  /// **'Where the phone web app is hosted; encoded into the pairing QR.'**
  String get remoteControlPwaHostHint;

  /// No description provided for @remoteControlNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Add a signaling URL and phone app host to enable pairing.'**
  String get remoteControlNotConfigured;

  /// No description provided for @remoteControlPairDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get remoteControlPairDevice;

  /// No description provided for @remoteControlScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with your phone camera.'**
  String get remoteControlScanQr;

  /// No description provided for @remoteControlAllWorkspacesWarning.
  ///
  /// In en, this message translates to:
  /// **'This device will be able to access every workspace on this Mac.'**
  String get remoteControlAllWorkspacesWarning;

  /// No description provided for @remoteControlCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get remoteControlCopyLink;

  /// No description provided for @remoteControlWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect'**
  String get remoteControlWantsToConnect;

  /// No description provided for @remoteControlApproveDevice.
  ///
  /// In en, this message translates to:
  /// **'Approve device'**
  String get remoteControlApproveDevice;

  /// No description provided for @remoteControlDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device connected — approve it to finish pairing.'**
  String get remoteControlDeviceConnected;

  /// Pairing QR expiry countdown
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes} min'**
  String remoteControlQrExpiresIn(int minutes);

  /// No description provided for @remoteControlPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get remoteControlPairedDevices;

  /// No description provided for @remoteControlNoPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired devices yet.'**
  String get remoteControlNoPairedDevices;

  /// No description provided for @remoteControlPending.
  ///
  /// In en, this message translates to:
  /// **'Pending confirmation'**
  String get remoteControlPending;

  /// No description provided for @remoteControlActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get remoteControlActive;

  /// No description provided for @remoteControlRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get remoteControlRevoked;

  /// No description provided for @remoteControlRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get remoteControlRevoke;

  /// No description provided for @remoteControlConfirmDevice.
  ///
  /// In en, this message translates to:
  /// **'Confirm device'**
  String get remoteControlConfirmDevice;

  /// No description provided for @remoteControlRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke this device? It will be disconnected immediately.'**
  String get remoteControlRevokeConfirm;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @devicesSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Pair and manage the phones that can remote-control this app.'**
  String get devicesSettingsDescription;

  /// No description provided for @connectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedLabel;

  /// No description provided for @ideTabExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get ideTabExplorer;

  /// No description provided for @ideTabSourceControl.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ideTabSourceControl;

  /// No description provided for @ideTabPullRequests.
  ///
  /// In en, this message translates to:
  /// **'PRs'**
  String get ideTabPullRequests;

  /// No description provided for @ideNewTerminal.
  ///
  /// In en, this message translates to:
  /// **'New terminal'**
  String get ideNewTerminal;

  /// No description provided for @ideOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get ideOpenChat;

  /// No description provided for @ideCloseTab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get ideCloseTab;

  /// No description provided for @ideSplitEditor.
  ///
  /// In en, this message translates to:
  /// **'Split editor'**
  String get ideSplitEditor;

  /// No description provided for @ideCloseGroup.
  ///
  /// In en, this message translates to:
  /// **'Close group'**
  String get ideCloseGroup;

  /// No description provided for @ideNoOpenTabs.
  ///
  /// In en, this message translates to:
  /// **'No open tabs — use + to open'**
  String get ideNoOpenTabs;

  /// No description provided for @ideBrowserAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter address or search'**
  String get ideBrowserAddressHint;

  /// No description provided for @ideSimpleWebBrowser.
  ///
  /// In en, this message translates to:
  /// **'Simple web browser'**
  String get ideSimpleWebBrowser;

  /// No description provided for @ideWebBrowser.
  ///
  /// In en, this message translates to:
  /// **'Web browser'**
  String get ideWebBrowser;

  /// No description provided for @ideBrowserEnterUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a URL in the address bar to start browsing'**
  String get ideBrowserEnterUrl;

  /// No description provided for @ideFileSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search files'**
  String get ideFileSearchFailed;

  /// No description provided for @ideSourceControlCreatePr.
  ///
  /// In en, this message translates to:
  /// **'Create pull request'**
  String get ideSourceControlCreatePr;

  /// No description provided for @ideSourceControlNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get ideSourceControlNoChanges;

  /// No description provided for @ideSourceControlChangedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 changed} other{{count} changed}}'**
  String ideSourceControlChangedFiles(int count);

  /// No description provided for @ideConnectGithub.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub to view pull requests'**
  String get ideConnectGithub;

  /// No description provided for @ideNoConversationPr.
  ///
  /// In en, this message translates to:
  /// **'No pull request for this conversation'**
  String get ideNoConversationPr;

  /// No description provided for @ideFileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get ideFileLoading;

  /// No description provided for @ideFileBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary file'**
  String get ideFileBinary;

  /// No description provided for @mcpExternalServers.
  ///
  /// In en, this message translates to:
  /// **'External MCP servers'**
  String get mcpExternalServers;

  /// No description provided for @mcpExternalServersDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to external MCP servers (GitHub, Sentry, Postgres, browser automation). Servers you configured for Claude, Cursor, VS Code and other tools are auto-discovered.'**
  String get mcpExternalServersDescription;

  /// No description provided for @mcpApprovalMode.
  ///
  /// In en, this message translates to:
  /// **'Tool approval'**
  String get mcpApprovalMode;

  /// No description provided for @mcpApprovalModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Which tool actions run without asking. Reads are always allowed; higher tiers prompt.'**
  String get mcpApprovalModeDescription;

  /// No description provided for @mcpApprovalAlwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask'**
  String get mcpApprovalAlwaysAsk;

  /// No description provided for @mcpApprovalWrite.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve writes'**
  String get mcpApprovalWrite;

  /// No description provided for @mcpApprovalYolo.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve all'**
  String get mcpApprovalYolo;

  /// No description provided for @mcpNoExternalServers.
  ///
  /// In en, this message translates to:
  /// **'No external MCP servers discovered.'**
  String get mcpNoExternalServers;

  /// No description provided for @mcpAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get mcpAuthorize;

  /// No description provided for @mcpReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get mcpReconnect;

  /// No description provided for @mcpExternalConnectionsNote.
  ///
  /// In en, this message translates to:
  /// **'External MCP servers run on the agent server (shared by desktop and web). Authorizing OAuth servers is only available on the desktop.'**
  String get mcpExternalConnectionsNote;

  /// No description provided for @mcpToolsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} tools'**
  String mcpToolsSummary(int count);

  /// No description provided for @mcpStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get mcpStatusConnected;

  /// No description provided for @mcpStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get mcpStatusConnecting;

  /// No description provided for @mcpStatusNeedsAuth.
  ///
  /// In en, this message translates to:
  /// **'Needs authorization'**
  String get mcpStatusNeedsAuth;

  /// No description provided for @mcpStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get mcpStatusFailed;

  /// No description provided for @mcpStatusCircuitOpen.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mcpStatusCircuitOpen;

  /// No description provided for @mcpStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get mcpStatusDisabled;
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
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
