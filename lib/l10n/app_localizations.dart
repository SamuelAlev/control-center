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
    Locale('en'),
    Locale('ar'),
    Locale('cs'),
    Locale('de'),
    Locale('el'),
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

  /// Toast when "Stop and send" on a queued steering card was refused or failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send that now: {error}'**
  String steeringForceSendFailed(String error);

  /// Shown under a question form when the server refused the answer (already answered elsewhere or the agent stopped waiting).
  ///
  /// In en, this message translates to:
  /// **'Your answer wasn\'t delivered. It may already be answered, or the agent stopped waiting.'**
  String get questionAnswerNotDelivered;

  /// Run status: the run finished successfully (green status dot)
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get succeeded;

  /// Sidebar run-tree label for a tracked retry run that has no summary yet
  ///
  /// In en, this message translates to:
  /// **'Retry #{number} · {time}'**
  String agentRunRetryLabel(int number, String time);

  /// Sidebar run-tree label for a just-dispatched run that has no summary yet
  ///
  /// In en, this message translates to:
  /// **'Starting · {time}'**
  String agentRunStarting(String time);

  /// No description provided for @agentActivityFollowingLive.
  ///
  /// In en, this message translates to:
  /// **'Following live activity'**
  String get agentActivityFollowingLive;

  /// No description provided for @agentActivityJumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get agentActivityJumpToLatest;

  /// No description provided for @agentActivityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this run\'s activity'**
  String get agentActivityLoadFailed;

  /// No description provided for @agentActivityNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'No activity was recorded for this run'**
  String get agentActivityNotRecorded;

  /// No description provided for @agentActivityNotRecordedHint.
  ///
  /// In en, this message translates to:
  /// **'Runs that finished before activity capture was enabled have no timeline.'**
  String get agentActivityNotRecordedHint;

  /// No description provided for @agentActivityRunUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This run is no longer available'**
  String get agentActivityRunUnavailable;

  /// No description provided for @agentActivitySubagentOf.
  ///
  /// In en, this message translates to:
  /// **'Subagent of {agent}'**
  String agentActivitySubagentOf(String agent);

  /// No description provided for @agentActivityUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Activity capture is unavailable on the connected server'**
  String get agentActivityUnsupported;

  /// No description provided for @agentActivityUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Restart the app so it picks up the latest server build.'**
  String get agentActivityUnsupportedHint;

  /// No description provided for @agentActivityWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for activity…'**
  String get agentActivityWaiting;

  /// File-change status: the agent created the file
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @dictationStart.
  ///
  /// In en, this message translates to:
  /// **'Start dictation'**
  String get dictationStart;

  /// No description provided for @dictationListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get dictationListening;

  /// No description provided for @dictationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dictation needs a voice model on the server host. Set one up in voice settings.'**
  String get dictationUnavailable;

  /// No description provided for @dictationFailedToStart.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start dictation'**
  String get dictationFailedToStart;

  /// No description provided for @dictationHoldToTalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get dictationHoldToTalkTitle;

  /// No description provided for @dictationHoldToTalkDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold the mic button or the shortcut to dictate and release to stop. When off, press once to start and again to stop.'**
  String get dictationHoldToTalkDescription;

  /// No description provided for @focusConversation.
  ///
  /// In en, this message translates to:
  /// **'Focus conversation'**
  String get focusConversation;

  /// No description provided for @ideAgentActivity.
  ///
  /// In en, this message translates to:
  /// **'Agent activity'**
  String get ideAgentActivity;

  /// No description provided for @keybindingPushToTalk.
  ///
  /// In en, this message translates to:
  /// **'Push to talk'**
  String get keybindingPushToTalk;

  /// No description provided for @agentPermissions.
  ///
  /// In en, this message translates to:
  /// **'Agent permissions'**
  String get agentPermissions;

  /// No description provided for @agentPermissionsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Decide what agents can do on their own, must ask about first, or can never do — per workspace, agent, or space.'**
  String get agentPermissionsSettingsDescription;

  /// No description provided for @agentPermissionsMatrixDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a decision for each kind of effect. Rules cascade: space overrides agent overrides workspace overrides mode preset. The most specific rule wins.'**
  String get agentPermissionsMatrixDescription;

  /// No description provided for @guardrailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading rules…'**
  String get guardrailLoading;

  /// No description provided for @guardrailRulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the permission rules.'**
  String get guardrailRulesLoadFailed;

  /// No description provided for @guardrailScopeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get guardrailScopeWorkspace;

  /// No description provided for @guardrailScopeAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get guardrailScopeAgent;

  /// No description provided for @guardrailScopeSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get guardrailScopeSpace;

  /// No description provided for @guardrailSelectAgent.
  ///
  /// In en, this message translates to:
  /// **'Select an agent'**
  String get guardrailSelectAgent;

  /// No description provided for @guardrailSelectSpace.
  ///
  /// In en, this message translates to:
  /// **'Select a space'**
  String get guardrailSelectSpace;

  /// No description provided for @guardrailNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents in this workspace yet.'**
  String get guardrailNoAgents;

  /// No description provided for @guardrailNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'No spaces in this workspace yet.'**
  String get guardrailNoSpaces;

  /// No description provided for @guardrailClassFileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete a file'**
  String get guardrailClassFileDelete;

  /// No description provided for @guardrailClassFileWriteOutsideWorktree.
  ///
  /// In en, this message translates to:
  /// **'Write outside the worktree'**
  String get guardrailClassFileWriteOutsideWorktree;

  /// No description provided for @guardrailClassGitCommit.
  ///
  /// In en, this message translates to:
  /// **'Create a commit'**
  String get guardrailClassGitCommit;

  /// No description provided for @guardrailClassGitPush.
  ///
  /// In en, this message translates to:
  /// **'Push to a remote'**
  String get guardrailClassGitPush;

  /// No description provided for @guardrailClassPrCreate.
  ///
  /// In en, this message translates to:
  /// **'Open a pull request'**
  String get guardrailClassPrCreate;

  /// No description provided for @guardrailClassPrPublish.
  ///
  /// In en, this message translates to:
  /// **'Update or merge a pull request'**
  String get guardrailClassPrPublish;

  /// No description provided for @guardrailClassVendorSyncWrite.
  ///
  /// In en, this message translates to:
  /// **'Write to an external tracker'**
  String get guardrailClassVendorSyncWrite;

  /// No description provided for @guardrailClassNetworkEgress.
  ///
  /// In en, this message translates to:
  /// **'Access the network'**
  String get guardrailClassNetworkEgress;

  /// No description provided for @guardrailClassSecretAccess.
  ///
  /// In en, this message translates to:
  /// **'Read a secret'**
  String get guardrailClassSecretAccess;

  /// No description provided for @guardrailClassPackageInstall.
  ///
  /// In en, this message translates to:
  /// **'Install a package'**
  String get guardrailClassPackageInstall;

  /// No description provided for @guardrailClassProcessSpawn.
  ///
  /// In en, this message translates to:
  /// **'Run a process'**
  String get guardrailClassProcessSpawn;

  /// No description provided for @guardrailClassWorkspaceMutation.
  ///
  /// In en, this message translates to:
  /// **'Change workspace structure'**
  String get guardrailClassWorkspaceMutation;

  /// No description provided for @guardrailClassEnclosureControl.
  ///
  /// In en, this message translates to:
  /// **'Drive an enclosure (rig)'**
  String get guardrailClassEnclosureControl;

  /// No description provided for @navRigs.
  ///
  /// In en, this message translates to:
  /// **'Rigs'**
  String get navRigs;

  /// No description provided for @rigsUnsupportedServer.
  ///
  /// In en, this message translates to:
  /// **'This server cannot host any rig surfaces. Check the host requirements for the machine you want to use.'**
  String get rigsUnsupportedServer;

  /// No description provided for @rigSurfaceComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get rigSurfaceComputer;

  /// No description provided for @rigSurfaceBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get rigSurfaceBrowser;

  /// No description provided for @rigSurfaceAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get rigSurfaceAndroid;

  /// No description provided for @rigSurfaceIosSimulator.
  ///
  /// In en, this message translates to:
  /// **'iOS Simulator'**
  String get rigSurfaceIosSimulator;

  /// No description provided for @rigSurfaceAppWindow.
  ///
  /// In en, this message translates to:
  /// **'App window'**
  String get rigSurfaceAppWindow;

  /// Browser rig surface name, by engine.
  ///
  /// In en, this message translates to:
  /// **'{engine}'**
  String rigSurfaceBrowserEngine(String engine);

  /// Hint under the start button of a browser rig tab.
  ///
  /// In en, this message translates to:
  /// **'A disposable {engine}, isolated from your machine. Open another engine to compare the same page side by side.'**
  String rigBrowserEngineHint(String engine);

  /// No description provided for @rigPhaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get rigPhaseReady;

  /// No description provided for @rigPhaseStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get rigPhaseStarting;

  /// No description provided for @rigPhaseParked.
  ///
  /// In en, this message translates to:
  /// **'Parked'**
  String get rigPhaseParked;

  /// No description provided for @rigPhaseClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get rigPhaseClosing;

  /// No description provided for @rigPhaseClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get rigPhaseClosed;

  /// No description provided for @rigPhaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get rigPhaseFailed;

  /// No description provided for @rigPhaseUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get rigPhaseUnknown;

  /// No description provided for @rigNotAccelerated.
  ///
  /// In en, this message translates to:
  /// **'Emulated'**
  String get rigNotAccelerated;

  /// No description provided for @rigAudioListen.
  ///
  /// In en, this message translates to:
  /// **'Listen to the machine'**
  String get rigAudioListen;

  /// No description provided for @rigAudioMute.
  ///
  /// In en, this message translates to:
  /// **'Mute the machine'**
  String get rigAudioMute;

  /// No description provided for @rigYouHaveControl.
  ///
  /// In en, this message translates to:
  /// **'You have control'**
  String get rigYouHaveControl;

  /// No description provided for @rigBackendAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get rigBackendAvailable;

  /// No description provided for @rigBackendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get rigBackendUnavailable;

  /// No description provided for @rigEgressNotEnforced.
  ///
  /// In en, this message translates to:
  /// **'Network is not enclosed on this backend — it manages its own connectivity.'**
  String get rigEgressNotEnforced;

  /// No description provided for @rigStartMachine.
  ///
  /// In en, this message translates to:
  /// **'Start the machine'**
  String get rigStartMachine;

  /// No description provided for @rigStartHint.
  ///
  /// In en, this message translates to:
  /// **'Starts a disposable VM you and your agents share for this conversation. It is destroyed when it closes, and nothing in it touches your computer.'**
  String get rigStartHint;

  /// No description provided for @rigStartAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'Connects to an Android emulator already running on the server. Network access is not enclosed.'**
  String get rigStartAndroidHint;

  /// No description provided for @rigStartIosHint.
  ///
  /// In en, this message translates to:
  /// **'Creates a disposable iOS Simulator on a macOS server. It is deleted when the rig closes; network access is not enclosed.'**
  String get rigStartIosHint;

  /// Disclosure label on a rig start screen that hides a failed boot's stdout/stderr dump.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get rigTechnicalDetails;

  /// No description provided for @rigStopMachine.
  ///
  /// In en, this message translates to:
  /// **'Stop the machine'**
  String get rigStopMachine;

  /// Toolbar button that sends the device Home key / opens the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get rigHomeButton;

  /// No description provided for @rigRotateClockwise.
  ///
  /// In en, this message translates to:
  /// **'Rotate clockwise'**
  String get rigRotateClockwise;

  /// No description provided for @rigRotateCounterclockwise.
  ///
  /// In en, this message translates to:
  /// **'Rotate counterclockwise'**
  String get rigRotateCounterclockwise;

  /// No description provided for @rigTakeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Take a screenshot'**
  String get rigTakeScreenshot;

  /// No description provided for @rigScreenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved'**
  String get rigScreenshotSaved;

  /// Toast when a simulator screenshot could not be written.
  ///
  /// In en, this message translates to:
  /// **'Could not save the screenshot: {error}'**
  String rigScreenshotSaveFailed(String error);

  /// No description provided for @rigSurfaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server cannot host this kind of machine.'**
  String get rigSurfaceUnavailable;

  /// No description provided for @rigTabNeedsConversation.
  ///
  /// In en, this message translates to:
  /// **'Open a conversation first — a machine belongs to one, so you and your agents are looking at the same screen.'**
  String get rigTabNeedsConversation;

  /// Heading over the tool rows of the editor's [+] menu.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get ideMenuSectionTools;

  /// Heading over the machine rows of the editor's [+] menu. It is what lets those rows drop their '(VM)' suffix.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get ideMenuSectionMachines;

  /// Heading over the rows of the editor's [+] menu that bring back a closed view.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get ideMenuSectionReopen;

  /// Placeholder in the editor [+] menu's search field.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get ideMenuSearchHint;

  /// Shown in the editor [+] menu when a search matches no row.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get ideMenuNoMatches;

  /// Desktop rig, named inside the [+] menu's MACHINES group — no '(VM)' suffix because the heading already says it. The TAB keeps rigTabComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get rigMenuComputer;

  /// Browser rig with no named engine, inside the [+] menu's MACHINES group. The TAB keeps rigTabBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get rigMenuBrowser;

  /// Android rig, inside the [+] menu's MACHINES group. The TAB keeps rigTabMobile.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get rigMenuAndroid;

  /// No description provided for @rigMenuIosSimulator.
  ///
  /// In en, this message translates to:
  /// **'iOS Simulator'**
  String get rigMenuIosSimulator;

  /// Names one of several identical machines in a conversation, e.g. "WebKit 2". Only the frame is translated; the label and the suffix are supplied.
  ///
  /// In en, this message translates to:
  /// **'{label} {suffix}'**
  String rigLabelNumbered(String label, String suffix);

  /// Title of the prompt shown when closing a tab whose machine, shell or agent is still working.
  ///
  /// In en, this message translates to:
  /// **'Close {name}?'**
  String ideCloseKeepTitle(String name);

  /// Body of the close prompt for a rig (browser/computer/phone) tab.
  ///
  /// In en, this message translates to:
  /// **'The machine keeps running in the background — reopen it any time from the sidebar. Shut it down instead to free its memory now.'**
  String get ideCloseKeepBodyMachine;

  /// Body of the close prompt for a terminal tab running a command.
  ///
  /// In en, this message translates to:
  /// **'The command keeps running in the background — reopen the shell any time from the sidebar. End it instead to stop what it is doing now.'**
  String get ideCloseKeepBodyShell;

  /// Body of the close prompt for a conversation tab with a live agent run.
  ///
  /// In en, this message translates to:
  /// **'The agent keeps working in the background — reopen the conversation any time from the sidebar. Stop it instead to end the run now.'**
  String get ideCloseKeepBodyAgent;

  /// Close-prompt action: close the tab and leave the work running.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get ideCloseKeepRunning;

  /// Close-prompt action: shut the enclosed machine down.
  ///
  /// In en, this message translates to:
  /// **'Shut down'**
  String get ideCloseShutDownMachine;

  /// Close-prompt action: end the shell session.
  ///
  /// In en, this message translates to:
  /// **'End shell'**
  String get ideCloseEndShell;

  /// Close-prompt action: stop the running agent.
  ///
  /// In en, this message translates to:
  /// **'Stop agent'**
  String get ideCloseStopAgent;

  /// No description provided for @rigsSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What this server can boot, the base images it needs, and the machines running now'**
  String get rigsSettingsSubtitle;

  /// No description provided for @rigsCapabilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'This server'**
  String get rigsCapabilitiesTitle;

  /// No description provided for @rigInstallIosAutomation.
  ///
  /// In en, this message translates to:
  /// **'Install iOS automation bridge'**
  String get rigInstallIosAutomation;

  /// No description provided for @rigInstallingIosAutomation.
  ///
  /// In en, this message translates to:
  /// **'Installing iOS automation bridge…'**
  String get rigInstallingIosAutomation;

  /// No description provided for @rigIosAutomationInstalled.
  ///
  /// In en, this message translates to:
  /// **'iOS automation bridge installed'**
  String get rigIosAutomationInstalled;

  /// No description provided for @rigsImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Base images'**
  String get rigsImagesTitle;

  /// No description provided for @rigsImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Every rig boots one of these read-only images. Each session writes to a throwaway overlay, so one rig can never change what the next one starts from.'**
  String get rigsImagesHint;

  /// No description provided for @rigsRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get rigsRunningTitle;

  /// No description provided for @rigsNoneRunning.
  ///
  /// In en, this message translates to:
  /// **'No machines are running.'**
  String get rigsNoneRunning;

  /// No description provided for @rigsCustomImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom images (this workspace)'**
  String get rigsCustomImagesTitle;

  /// No description provided for @rigsCustomImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Point the Terminal (VM) or Browser (VM) at your own image — extend the defaults with the tools your project needs, or use any compatible one from a registry. New machines use it; running ones keep theirs. See the rigs guide for what an image must provide.'**
  String get rigsCustomImagesHint;

  /// No description provided for @rigsCustomTerminalImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Terminal (VM) image'**
  String get rigsCustomTerminalImageLabel;

  /// No description provided for @rigsCustomBrowserImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Browser (VM) image'**
  String get rigsCustomBrowserImageLabel;

  /// No description provided for @rigsCustomImagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. ghcr.io/acme/dev-shell:1.2 — leave blank for the default'**
  String get rigsCustomImagePlaceholder;

  /// No description provided for @rigsCustomImageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a registry reference such as repo/name:tag. Local paths and archives are not allowed.'**
  String get rigsCustomImageInvalid;

  /// No description provided for @rigsCustomImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. New machines boot this image; running ones keep theirs.'**
  String get rigsCustomImageSaved;

  /// No description provided for @rigsEgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Browser egress (this workspace)'**
  String get rigsEgressTitle;

  /// No description provided for @rigsEgressHint.
  ///
  /// In en, this message translates to:
  /// **'Extra hosts the enclosed browser may reach — one per line: an exact host (api.example.com) or a wildcard for its subdomains (*.example.com). The product site stays allowed either way. New machines get the list; running ones keep what they booted with.'**
  String get rigsEgressHint;

  /// Shown when a browser egress host entry is invalid
  ///
  /// In en, this message translates to:
  /// **'\"{host}\" is not a valid host entry.'**
  String rigsEgressInvalid(String host);

  /// No description provided for @rigsEgressSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. New browser machines admit these hosts; running ones keep theirs.'**
  String get rigsEgressSaved;

  /// No description provided for @rigImageInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get rigImageInstalled;

  /// No description provided for @rigImageNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get rigImageNotDownloaded;

  /// No description provided for @rigImageNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get rigImageNotPublished;

  /// No description provided for @rigImageNotPublishedHint.
  ///
  /// In en, this message translates to:
  /// **'No image has been published for this yet, so there is nothing to download. Import a compatible disk image to enable it.'**
  String get rigImageNotPublishedHint;

  /// No description provided for @rigImageDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get rigImageDownload;

  /// No description provided for @rigImageDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get rigImageDownloading;

  /// No description provided for @rigImageImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get rigImageImport;

  /// No description provided for @rigImageImportMessage.
  ///
  /// In en, this message translates to:
  /// **'Path to a qcow2 disk image on the server\'s filesystem. It is copied into the image store, so the file can move afterwards.'**
  String get rigImageImportMessage;

  /// No description provided for @rigConnectingStream.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the rig'**
  String get rigConnectingStream;

  /// No description provided for @rigStreamNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this rig.'**
  String get rigStreamNotAllowed;

  /// No description provided for @rigStreamNotRunning.
  ///
  /// In en, this message translates to:
  /// **'This rig is no longer running.'**
  String get rigStreamNotRunning;

  /// No description provided for @rigStreamNeedsFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'Live view needs ffmpeg on this host. Install ffmpeg and reopen the tab.'**
  String get rigStreamNeedsFfmpeg;

  /// No description provided for @rigStreamNeedsScreenCapture.
  ///
  /// In en, this message translates to:
  /// **'Live view needs Screen Recording. Grant it to Control Center in System Settings and reopen the tab.'**
  String get rigStreamNeedsScreenCapture;

  /// No description provided for @rigStreamEnded.
  ///
  /// In en, this message translates to:
  /// **'The live view ended.'**
  String get rigStreamEnded;

  /// No description provided for @rigStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'The live view could not be opened.'**
  String get rigStreamFailed;

  /// No description provided for @rigStreamDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to a server.'**
  String get rigStreamDisconnected;

  /// Toast shown while a single dropped file is copied into a rig
  ///
  /// In en, this message translates to:
  /// **'Copying \"{name}\" into the machine…'**
  String rigDropSendingOne(String name);

  /// Toast shown while several dropped files are copied into a rig
  ///
  /// In en, this message translates to:
  /// **'Copying {count} files into the machine…'**
  String rigDropSendingMany(int count);

  /// No description provided for @rigTerminalDropSending.
  ///
  /// In en, this message translates to:
  /// **'Copying into the machine…'**
  String get rigTerminalDropSending;

  /// No description provided for @rigTerminalPasteImage.
  ///
  /// In en, this message translates to:
  /// **'Pasted image saved in the machine'**
  String get rigTerminalPasteImage;

  /// No description provided for @rigPortsTitle.
  ///
  /// In en, this message translates to:
  /// **'Forwarded ports'**
  String get rigPortsTitle;

  /// No description provided for @rigPortsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ports open inside this machine'**
  String get rigPortsTooltip;

  /// No description provided for @rigPortsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is listening yet. Start a server in the terminal — a dev server on port 3000 shows up here.'**
  String get rigPortsEmpty;

  /// No description provided for @rigPortsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add port'**
  String get rigPortsAdd;

  /// No description provided for @rigPortsAddHint.
  ///
  /// In en, this message translates to:
  /// **'Guest port to forward (e.g. 3000)'**
  String get rigPortsAddHint;

  /// No description provided for @rigPortsAutoForward.
  ///
  /// In en, this message translates to:
  /// **'Auto-forward ports'**
  String get rigPortsAutoForward;

  /// No description provided for @rigPortsCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy local URL'**
  String get rigPortsCopyUrl;

  /// Toast confirming a forwarded-port URL was copied
  ///
  /// In en, this message translates to:
  /// **'Copied {url}'**
  String rigPortsCopiedUrl(String url);

  /// No description provided for @rigPortsStopForward.
  ///
  /// In en, this message translates to:
  /// **'Stop forwarding'**
  String get rigPortsStopForward;

  /// No description provided for @rigPortsExposeLan.
  ///
  /// In en, this message translates to:
  /// **'Share on local network'**
  String get rigPortsExposeLan;

  /// No description provided for @rigPortsLanPrivate.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get rigPortsLanPrivate;

  /// No description provided for @rigPortsLanShared.
  ///
  /// In en, this message translates to:
  /// **'On the network'**
  String get rigPortsLanShared;

  /// No description provided for @rigPortsSetDomain.
  ///
  /// In en, this message translates to:
  /// **'Set a browser domain (.test)'**
  String get rigPortsSetDomain;

  /// No description provided for @rigPortsDomainHint.
  ///
  /// In en, this message translates to:
  /// **'Domain for the Browser (VM), e.g. myapp.test — reachable there, not on the host'**
  String get rigPortsDomainHint;

  /// No description provided for @rigPortsProcessUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown process'**
  String get rigPortsProcessUnknown;

  /// No description provided for @rigPortsInactive.
  ///
  /// In en, this message translates to:
  /// **'not listening'**
  String get rigPortsInactive;

  /// No description provided for @rigPortsTooltipHost.
  ///
  /// In en, this message translates to:
  /// **'Ports open in this terminal'**
  String get rigPortsTooltipHost;

  /// No description provided for @rigPortsEmptyHost.
  ///
  /// In en, this message translates to:
  /// **'Nothing is listening in this terminal yet. Start a server and it shows up here.'**
  String get rigPortsEmptyHost;

  /// No description provided for @rigPortsAddHintHost.
  ///
  /// In en, this message translates to:
  /// **'Port to map (e.g. 5173)'**
  String get rigPortsAddHintHost;

  /// No description provided for @rigPortsLocalPortHint.
  ///
  /// In en, this message translates to:
  /// **'Local port (optional)'**
  String get rigPortsLocalPortHint;

  /// Desktop loopback address for a forwarded port
  ///
  /// In en, this message translates to:
  /// **'localhost:{port}'**
  String rigPortsDestDesktop(int port);

  /// Browser (VM) loopback address for a forwarded port
  ///
  /// In en, this message translates to:
  /// **'localhost:{port} in the browser (VM)'**
  String rigPortsDestBrowser(int port);

  /// No description provided for @rigPortsDestBrowserUnreachable.
  ///
  /// In en, this message translates to:
  /// **'browser (VM) not attached'**
  String get rigPortsDestBrowserUnreachable;

  /// Android loopback address for a forwarded port
  ///
  /// In en, this message translates to:
  /// **'localhost:{port} on Android'**
  String rigPortsDestAndroid(int port);

  /// No description provided for @rigPortsDestAndroidUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Android not attached'**
  String get rigPortsDestAndroidUnreachable;

  /// Count of base images still needing download for a rig backend
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 base image still to download} other{{count} base images still to download}}'**
  String rigImagesMissing(int count);

  /// No description provided for @guardrailDecisionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get guardrailDecisionAllow;

  /// No description provided for @guardrailDecisionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask first'**
  String get guardrailDecisionPrompt;

  /// No description provided for @guardrailDecisionDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get guardrailDecisionDeny;

  /// No description provided for @guardrailSourceThisScope.
  ///
  /// In en, this message translates to:
  /// **'This scope'**
  String get guardrailSourceThisScope;

  /// No description provided for @guardrailSourceDefault.
  ///
  /// In en, this message translates to:
  /// **'Built-in default'**
  String get guardrailSourceDefault;

  /// No description provided for @guardrailSourcePreset.
  ///
  /// In en, this message translates to:
  /// **'Mode preset'**
  String get guardrailSourcePreset;

  /// No description provided for @guardrailSourceInherited.
  ///
  /// In en, this message translates to:
  /// **'Inherited'**
  String get guardrailSourceInherited;

  /// No description provided for @guardrailClearToInherited.
  ///
  /// In en, this message translates to:
  /// **'Clear to inherited'**
  String get guardrailClearToInherited;

  /// No description provided for @guardrailWhatIf.
  ///
  /// In en, this message translates to:
  /// **'What if?'**
  String get guardrailWhatIf;

  /// No description provided for @guardrailWhatIfDescription.
  ///
  /// In en, this message translates to:
  /// **'See how the current rules would resolve an action, using the same logic the agents run against.'**
  String get guardrailWhatIfDescription;

  /// No description provided for @guardrailProbeActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get guardrailProbeActionLabel;

  /// No description provided for @guardrailProbeCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command (optional)'**
  String get guardrailProbeCommandLabel;

  /// No description provided for @guardrailProbeCommandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. git push origin main'**
  String get guardrailProbeCommandHint;

  /// No description provided for @guardrailProbeAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent (optional)'**
  String get guardrailProbeAgentLabel;

  /// No description provided for @guardrailProbeSpaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Space (optional)'**
  String get guardrailProbeSpaceLabel;

  /// No description provided for @guardrailProbeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get guardrailProbeNone;

  /// No description provided for @guardrailProbeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get guardrailProbeModeLabel;

  /// No description provided for @guardrailProbeResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get guardrailProbeResult;

  /// No description provided for @guardrailProbeSource.
  ///
  /// In en, this message translates to:
  /// **'Source:'**
  String get guardrailProbeSource;

  /// No description provided for @guardrailAdapterMatrix.
  ///
  /// In en, this message translates to:
  /// **'Where rules are enforced'**
  String get guardrailAdapterMatrix;

  /// No description provided for @guardrailAdapterMatrixDescription.
  ///
  /// In en, this message translates to:
  /// **'Honest reference: where each effect is actually caught, per agent runner. This documents reality, not a guarantee — effects a runner performs out of band can\'t be intercepted.'**
  String get guardrailAdapterMatrixDescription;

  /// No description provided for @guardrailEffectColumn.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get guardrailEffectColumn;

  /// No description provided for @guardrailAdapterHarness.
  ///
  /// In en, this message translates to:
  /// **'Built-in harness'**
  String get guardrailAdapterHarness;

  /// No description provided for @guardrailAdapterClaudeCli.
  ///
  /// In en, this message translates to:
  /// **'Claude CLI'**
  String get guardrailAdapterClaudeCli;

  /// No description provided for @guardrailAdapterMcpHttp.
  ///
  /// In en, this message translates to:
  /// **'MCP (HTTP)'**
  String get guardrailAdapterMcpHttp;

  /// No description provided for @guardrailAdapterSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox floor'**
  String get guardrailAdapterSandbox;

  /// No description provided for @guardrailEnforcementPolicyGate.
  ///
  /// In en, this message translates to:
  /// **'Policy gate'**
  String get guardrailEnforcementPolicyGate;

  /// No description provided for @guardrailEnforcementSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox only'**
  String get guardrailEnforcementSandbox;

  /// No description provided for @guardrailEnforcementNone.
  ///
  /// In en, this message translates to:
  /// **'Not enforceable'**
  String get guardrailEnforcementNone;

  /// No description provided for @guardrailEnforcementPolicyGateHelp.
  ///
  /// In en, this message translates to:
  /// **'The permission decision is checked before the effect runs and can block it.'**
  String get guardrailEnforcementPolicyGateHelp;

  /// No description provided for @guardrailEnforcementSandboxHelp.
  ///
  /// In en, this message translates to:
  /// **'Only the sandbox constrains it; the permission rule isn\'t consulted.'**
  String get guardrailEnforcementSandboxHelp;

  /// No description provided for @guardrailEnforcementNoneHelp.
  ///
  /// In en, this message translates to:
  /// **'The decision is advisory only — it can\'t be intercepted here.'**
  String get guardrailEnforcementNoneHelp;

  /// No description provided for @obsStatCost.
  ///
  /// In en, this message translates to:
  /// **'cost'**
  String get obsStatCost;

  /// No description provided for @obsStatDelegatedCost.
  ///
  /// In en, this message translates to:
  /// **'+{amount} delegated'**
  String obsStatDelegatedCost(String amount);

  /// No description provided for @obsStatDuration.
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get obsStatDuration;

  /// No description provided for @obsStatTokens.
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get obsStatTokens;

  /// No description provided for @obsStatTools.
  ///
  /// In en, this message translates to:
  /// **'tools'**
  String get obsStatTools;

  /// No description provided for @openAgentActivity.
  ///
  /// In en, this message translates to:
  /// **'Open activity'**
  String get openAgentActivity;

  /// No description provided for @orgChart.
  ///
  /// In en, this message translates to:
  /// **'Org chart'**
  String get orgChart;

  /// No description provided for @orgChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agents yet'**
  String get orgChartEmpty;

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

  /// No description provided for @serverSetupInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get serverSetupInviteCode;

  /// No description provided for @serverSetupInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a one-time invite code (leave empty to use a pairing key)'**
  String get serverSetupInviteCodeHint;

  /// No description provided for @serverDiscoveryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find servers on your network'**
  String get serverDiscoveryTooltip;

  /// No description provided for @serverDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers on your network'**
  String get serverDiscoveryTitle;

  /// No description provided for @serverDiscoverySearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for servers…'**
  String get serverDiscoverySearching;

  /// No description provided for @serverDiscoveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No servers found. Check that the server is running and that this device can reach it, then search again.'**
  String get serverDiscoveryEmpty;

  /// No description provided for @serverDiscoveryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get serverDiscoveryRefresh;

  /// No description provided for @serverListActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get serverListActive;

  /// No description provided for @serverListSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get serverListSwitch;

  /// No description provided for @serverListAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get serverListAddTitle;

  /// No description provided for @serverListRemoveActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Switch to another server before removing this one.'**
  String get serverListRemoveActiveHint;

  /// No description provided for @serverSwitchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not switch server'**
  String get serverSwitchFailedTitle;

  /// No description provided for @serverListInsecureBadge.
  ///
  /// In en, this message translates to:
  /// **'Insecure'**
  String get serverListInsecureBadge;

  /// No description provided for @connectionPathLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get connectionPathLocal;

  /// No description provided for @connectionPathLan.
  ///
  /// In en, this message translates to:
  /// **'LAN'**
  String get connectionPathLan;

  /// No description provided for @connectionPathTailnet.
  ///
  /// In en, this message translates to:
  /// **'Tailnet'**
  String get connectionPathTailnet;

  /// No description provided for @shutdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Shutting down'**
  String get shutdownTitle;

  /// No description provided for @shutdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Closing the local server'**
  String get shutdownSubtitle;

  /// No description provided for @shutdownServiceApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get shutdownServiceApprovals;

  /// No description provided for @shutdownServiceBackgroundJobs.
  ///
  /// In en, this message translates to:
  /// **'Background jobs'**
  String get shutdownServiceBackgroundJobs;

  /// No description provided for @shutdownServiceScheduler.
  ///
  /// In en, this message translates to:
  /// **'Job scheduler'**
  String get shutdownServiceScheduler;

  /// No description provided for @shutdownServiceCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync'**
  String get shutdownServiceCalendar;

  /// No description provided for @shutdownServiceWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get shutdownServiceWeather;

  /// No description provided for @shutdownServiceSoundscape.
  ///
  /// In en, this message translates to:
  /// **'Soundscape'**
  String get shutdownServiceSoundscape;

  /// No description provided for @shutdownServiceMeetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get shutdownServiceMeetings;

  /// No description provided for @shutdownServiceVoiceModels.
  ///
  /// In en, this message translates to:
  /// **'Voice models'**
  String get shutdownServiceVoiceModels;

  /// No description provided for @shutdownServiceNetworking.
  ///
  /// In en, this message translates to:
  /// **'Networking'**
  String get shutdownServiceNetworking;

  /// No description provided for @shutdownServicePresence.
  ///
  /// In en, this message translates to:
  /// **'Presence'**
  String get shutdownServicePresence;

  /// No description provided for @shutdownServiceDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data sync'**
  String get shutdownServiceDataSync;

  /// No description provided for @shutdownServiceDeviceRelay.
  ///
  /// In en, this message translates to:
  /// **'Device relay'**
  String get shutdownServiceDeviceRelay;

  /// No description provided for @shutdownServiceMcpConnections.
  ///
  /// In en, this message translates to:
  /// **'MCP connections'**
  String get shutdownServiceMcpConnections;

  /// No description provided for @shutdownServiceCodeEditors.
  ///
  /// In en, this message translates to:
  /// **'Code editors'**
  String get shutdownServiceCodeEditors;

  /// No description provided for @serverSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this server'**
  String get serverSharingTitle;

  /// No description provided for @serverSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Make this server reachable from your other devices. Nothing is exposed publicly unless you turn on a tunnel below. Pairing invites embed the server\'s current addresses automatically — create them under workspace settings.'**
  String get serverSharingDescription;

  /// No description provided for @serverSharingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing controls are not available on this server.'**
  String get serverSharingUnavailable;

  /// No description provided for @serverSharingMdnsLabel.
  ///
  /// In en, this message translates to:
  /// **'LAN discovery'**
  String get serverSharingMdnsLabel;

  /// No description provided for @serverSharingMdnsOn.
  ///
  /// In en, this message translates to:
  /// **'Advertising this server on your local network (mDNS)'**
  String get serverSharingMdnsOn;

  /// No description provided for @serverSharingMdnsOff.
  ///
  /// In en, this message translates to:
  /// **'Not advertising on your local network (mDNS)'**
  String get serverSharingMdnsOff;

  /// No description provided for @serverSharingTunnelLabel.
  ///
  /// In en, this message translates to:
  /// **'Tunnel'**
  String get serverSharingTunnelLabel;

  /// No description provided for @serverSharingTunnelHelper.
  ///
  /// In en, this message translates to:
  /// **'Turning on a tunnel makes this server reachable from the internet. Public exposure is opt-in and off by default.'**
  String get serverSharingTunnelHelper;

  /// No description provided for @serverSharingProviderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get serverSharingProviderOff;

  /// No description provided for @serverSharingProviderCloudflared.
  ///
  /// In en, this message translates to:
  /// **'Cloudflared'**
  String get serverSharingProviderCloudflared;

  /// No description provided for @serverSharingProviderNgrok.
  ///
  /// In en, this message translates to:
  /// **'ngrok'**
  String get serverSharingProviderNgrok;

  /// No description provided for @serverSharingProviderTailscale.
  ///
  /// In en, this message translates to:
  /// **'Tailscale'**
  String get serverSharingProviderTailscale;

  /// No description provided for @serverSharingPublicUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Public URL'**
  String get serverSharingPublicUrlLabel;

  /// No description provided for @serverSharingTunnelStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the tunnel…'**
  String get serverSharingTunnelStarting;

  /// No description provided for @serverSharingTunnelError.
  ///
  /// In en, this message translates to:
  /// **'Tunnel error: {error}'**
  String serverSharingTunnelError(String error);

  /// No description provided for @serverSharingTunnelUpNoUrl.
  ///
  /// In en, this message translates to:
  /// **'The tunnel is up. Reach it at your configured DNS hostname.'**
  String get serverSharingTunnelUpNoUrl;

  /// No description provided for @serverSharingRelayLabel.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get serverSharingRelayLabel;

  /// No description provided for @serverSharingRelayUsage.
  ///
  /// In en, this message translates to:
  /// **'Relayed this month: {amount}'**
  String serverSharingRelayUsage(String amount);

  /// No description provided for @serverSharingRelaySessions.
  ///
  /// In en, this message translates to:
  /// **'Active relay sessions: {count}'**
  String serverSharingRelaySessions(int count);

  /// No description provided for @serverSharingUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update sharing'**
  String get serverSharingUpdateFailedTitle;

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

  /// No description provided for @serverSetupErrorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Check that it\'s running and that this device can reach it (same network or relay).'**
  String get serverSetupErrorUnreachable;

  /// No description provided for @serverSetupErrorIdentityMismatch.
  ///
  /// In en, this message translates to:
  /// **'The server\'s identity doesn\'t match the one saved on this device. If the server was reinstalled or reset, remove the saved server and pair again.'**
  String get serverSetupErrorIdentityMismatch;

  /// No description provided for @serverSetupErrorAuthRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this device. Check that the pairing key and device id match what the server issued.'**
  String get serverSetupErrorAuthRejected;

  /// No description provided for @serverSetupErrorInviteRejected.
  ///
  /// In en, this message translates to:
  /// **'That invite code is invalid or has expired. Ask for a fresh one.'**
  String get serverSetupErrorInviteRejected;

  /// No description provided for @serverSetupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while connecting. Expand the technical details below for more information.'**
  String get serverSetupErrorGeneric;

  /// No description provided for @serverSetupErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get serverSetupErrorDetails;

  /// No description provided for @serverActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Server activity'**
  String get serverActivityTitle;

  /// No description provided for @serverActivityStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting local server…'**
  String get serverActivityStarting;

  /// No description provided for @serverActivityConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server…'**
  String get serverActivityConnecting;

  /// No description provided for @serverActivityStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Server could not start'**
  String get serverActivityStartFailed;

  /// No description provided for @serverActivityDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get serverActivityDownloadFailed;

  /// No description provided for @serverActivityStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not read model status'**
  String get serverActivityStatusUnavailable;

  /// No description provided for @serverActivityPreparingModel.
  ///
  /// In en, this message translates to:
  /// **'Preparing model…'**
  String get serverActivityPreparingModel;

  /// No description provided for @serverActivityPortInUse.
  ///
  /// In en, this message translates to:
  /// **'The server port is already in use. Stop the other process or choose a different port on the server.'**
  String get serverActivityPortInUse;

  /// No description provided for @serverActivityStartFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check the technical details, then try again from server setup.'**
  String get serverActivityStartFailedHint;

  /// Month-cell overflow button: how many events are hidden
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more} other{{count} more}}'**
  String calendarMoreEvents(int count);

  /// Timeline-gutter label beside the week view's all-day events strip. Kept short: the gutter is only as wide as an hour label, so a longer wording ellipsizes (the full wording is on the tooltip).
  ///
  /// In en, this message translates to:
  /// **'All-day'**
  String get calendarAllDayGutter;

  /// Collapsed all-day strip: how many all-day events a day holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String calendarAllDayEventCount(int count);

  /// Tooltip on the control that folds the all-day strip down to one row
  ///
  /// In en, this message translates to:
  /// **'Collapse all-day events'**
  String get calendarCollapseAllDay;

  /// Tooltip on the control that unfolds the collapsed all-day strip
  ///
  /// In en, this message translates to:
  /// **'Expand all-day events'**
  String get calendarExpandAllDay;

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

  /// No description provided for @calendarNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// No description provided for @calendarComposerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get calendarComposerTitleHint;

  /// No description provided for @calendarComposerStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get calendarComposerStarts;

  /// No description provided for @calendarComposerEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get calendarComposerEnds;

  /// No description provided for @calendarComposerDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get calendarComposerDate;

  /// No description provided for @calendarComposerEndDate.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get calendarComposerEndDate;

  /// No description provided for @calendarComposerGuestsHint.
  ///
  /// In en, this message translates to:
  /// **'Add guests by email'**
  String get calendarComposerGuestsHint;

  /// No description provided for @calendarComposerMeet.
  ///
  /// In en, this message translates to:
  /// **'Add a Google Meet link'**
  String get calendarComposerMeet;

  /// No description provided for @calendarComposerLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Add a location'**
  String get calendarComposerLocationHint;

  /// No description provided for @calendarComposerDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get calendarComposerDescriptionHint;

  /// No description provided for @calendarComposerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarComposerCalendar;

  /// No description provided for @calendarComposerTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title to save the event'**
  String get calendarComposerTitleRequired;

  /// No description provided for @calendarComposerInvalidGuests.
  ///
  /// In en, this message translates to:
  /// **'One of the guest emails isn\'t valid'**
  String get calendarComposerInvalidGuests;

  /// No description provided for @calendarComposerEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The event has to end after it starts'**
  String get calendarComposerEndBeforeStart;

  /// No description provided for @calendarComposerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the event. Try again.'**
  String get calendarComposerSaveFailed;

  /// No description provided for @calendarComposerGuestsNotified.
  ///
  /// In en, this message translates to:
  /// **'Guests get an email invitation from Google.'**
  String get calendarComposerGuestsNotified;

  /// No description provided for @calendarDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get calendarDeleteEvent;

  /// No description provided for @calendarDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String calendarDeleteConfirmTitle(String title);

  /// No description provided for @calendarDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from Google Calendar.'**
  String get calendarDeleteConfirmBody;

  /// No description provided for @calendarDeleteConfirmGuests.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from Google Calendar, and every guest is told it\'s cancelled.'**
  String get calendarDeleteConfirmGuests;

  /// No description provided for @calendarDeleteConfirmInvite.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from your calendar only. The organizer and other guests keep it.'**
  String get calendarDeleteConfirmInvite;

  /// No description provided for @calendarDeleteConfirmRecurring.
  ///
  /// In en, this message translates to:
  /// **'Only this occurrence is deleted; the rest of the series stays.'**
  String get calendarDeleteConfirmRecurring;

  /// No description provided for @calendarDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the event. Try again.'**
  String get calendarDeleteFailed;

  /// Toast when dragging a calendar event to a new time fails; the tile returns to its old slot
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move the event. It\'s back where it was.'**
  String get calendarMoveFailed;

  /// No description provided for @activityCreatedCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Created a calendar event'**
  String get activityCreatedCalendarEvent;

  /// Audit-trail sentence for calendar.moveEvent
  ///
  /// In en, this message translates to:
  /// **'Moved a calendar event'**
  String get activityMovedCalendarEvent;

  /// No description provided for @activityDeletedCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Deleted a calendar event'**
  String get activityDeletedCalendarEvent;

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
  /// **'Connect a Google account to sync events into this workspace. These calendars are yours here.'**
  String get calendarSettingsDescription;

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

  /// No description provided for @notificationRigStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Enclosure updates'**
  String get notificationRigStatusChanged;

  /// No description provided for @notifyRigStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'When an enclosure is taken over, reclaimed or fails'**
  String get notifyRigStatusChanged;

  /// No description provided for @notificationRigTakenOver.
  ///
  /// In en, this message translates to:
  /// **'Enclosure taken over'**
  String get notificationRigTakenOver;

  /// No description provided for @notificationRigTakenOverBody.
  ///
  /// In en, this message translates to:
  /// **'A person is driving the machine; the agent can watch but not act.'**
  String get notificationRigTakenOverBody;

  /// No description provided for @notificationRigReleased.
  ///
  /// In en, this message translates to:
  /// **'Enclosure control released'**
  String get notificationRigReleased;

  /// No description provided for @notificationRigReleasedBody.
  ///
  /// In en, this message translates to:
  /// **'The agent has the machine back.'**
  String get notificationRigReleasedBody;

  /// No description provided for @notificationRigReclaimed.
  ///
  /// In en, this message translates to:
  /// **'Enclosure reclaimed'**
  String get notificationRigReclaimed;

  /// No description provided for @notificationRigReclaimedBodyIdle.
  ///
  /// In en, this message translates to:
  /// **'It sat idle, so the machine was closed to free memory.'**
  String get notificationRigReclaimedBodyIdle;

  /// No description provided for @notificationRigReclaimedBodyTtl.
  ///
  /// In en, this message translates to:
  /// **'It reached its time limit and was closed.'**
  String get notificationRigReclaimedBodyTtl;

  /// No description provided for @notificationRigFailed.
  ///
  /// In en, this message translates to:
  /// **'Enclosure failed'**
  String get notificationRigFailed;

  /// No description provided for @notificationRigFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The hypervisor died underneath it. Re-open the machine to continue.'**
  String get notificationRigFailedBody;

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

  /// No description provided for @stopAgentRun.
  ///
  /// In en, this message translates to:
  /// **'Stop run'**
  String get stopAgentRun;

  /// No description provided for @stopAgentRunConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop this run? Work in progress is lost.'**
  String get stopAgentRunConfirm;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

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

  /// No description provided for @prFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get prFilterTooltip;

  /// No description provided for @prFilterActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active filter} other{{count} active filters}}'**
  String prFilterActiveCount(int count);

  /// No description provided for @prFilterAddFilter.
  ///
  /// In en, this message translates to:
  /// **'Add filter…'**
  String get prFilterAddFilter;

  /// No description provided for @prFilterFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Filter…'**
  String get prFilterFieldHint;

  /// No description provided for @prFilterCategoryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get prFilterCategoryStatus;

  /// No description provided for @prFilterCategoryAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get prFilterCategoryAuthor;

  /// No description provided for @prFilterCategoryReviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewers'**
  String get prFilterCategoryReviewer;

  /// No description provided for @prFilterCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get prFilterCategoryContent;

  /// No description provided for @prFilterCategoryRepoOwner.
  ///
  /// In en, this message translates to:
  /// **'Repository owner'**
  String get prFilterCategoryRepoOwner;

  /// No description provided for @prFilterCategoryRepoName.
  ///
  /// In en, this message translates to:
  /// **'Repository name'**
  String get prFilterCategoryRepoName;

  /// No description provided for @prFilterCategoryOpenedDate.
  ///
  /// In en, this message translates to:
  /// **'Opened date'**
  String get prFilterCategoryOpenedDate;

  /// No description provided for @prFilterCategoryUpdatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated date'**
  String get prFilterCategoryUpdatedDate;

  /// No description provided for @prFilterQuickToReview.
  ///
  /// In en, this message translates to:
  /// **'Quick to review'**
  String get prFilterQuickToReview;

  /// No description provided for @prFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get prFilterClearAll;

  /// No description provided for @prFilterMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pull request} other{{count} pull requests}}'**
  String prFilterMatchCount(int count);

  /// No description provided for @prFilterHiddenOptions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 option not matching any pull requests} other{{count} options not matching any pull requests}}'**
  String prFilterHiddenOptions(int count);

  /// No description provided for @prFilterContentHint.
  ///
  /// In en, this message translates to:
  /// **'Title or body contains…'**
  String get prFilterContentHint;

  /// No description provided for @prFilterNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No matching options'**
  String get prFilterNoOptions;

  /// No description provided for @prFilterChipIs.
  ///
  /// In en, this message translates to:
  /// **'is'**
  String get prFilterChipIs;

  /// No description provided for @prFilterChipIsAnyOf.
  ///
  /// In en, this message translates to:
  /// **'is any of'**
  String get prFilterChipIsAnyOf;

  /// No description provided for @prFilterChipContains.
  ///
  /// In en, this message translates to:
  /// **'contains'**
  String get prFilterChipContains;

  /// No description provided for @prFilterChipSince.
  ///
  /// In en, this message translates to:
  /// **'since'**
  String get prFilterChipSince;

  /// No description provided for @prFilterAddFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get prFilterAddFilterButton;

  /// No description provided for @prFilterClearCategory.
  ///
  /// In en, this message translates to:
  /// **'Clear {category} filter'**
  String prFilterClearCategory(String category);

  /// No description provided for @prFilterCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'Current user'**
  String get prFilterCurrentUser;

  /// No description provided for @prStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get prStatusDraft;

  /// No description provided for @prStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get prStatusOpen;

  /// No description provided for @prStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get prStatusInReview;

  /// No description provided for @prStatusChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get prStatusChangesRequested;

  /// No description provided for @prStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prStatusApproved;

  /// No description provided for @prStatusMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get prStatusMerged;

  /// No description provided for @prStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get prStatusClosed;

  /// No description provided for @prDateWindowDay.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get prDateWindowDay;

  /// No description provided for @prDateWindowThreeDays.
  ///
  /// In en, this message translates to:
  /// **'3 days ago'**
  String get prDateWindowThreeDays;

  /// No description provided for @prDateWindowWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get prDateWindowWeek;

  /// No description provided for @prDateWindowMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month ago'**
  String get prDateWindowMonth;

  /// No description provided for @prDateWindowThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months ago'**
  String get prDateWindowThreeMonths;

  /// No description provided for @prDateWindowSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months ago'**
  String get prDateWindowSixMonths;

  /// No description provided for @prDateWindowYear.
  ///
  /// In en, this message translates to:
  /// **'1 year ago'**
  String get prDateWindowYear;

  /// No description provided for @prDisplayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display options'**
  String get prDisplayOptions;

  /// No description provided for @prDisplayGrouping.
  ///
  /// In en, this message translates to:
  /// **'Grouping'**
  String get prDisplayGrouping;

  /// No description provided for @prDisplayOrdering.
  ///
  /// In en, this message translates to:
  /// **'Ordering'**
  String get prDisplayOrdering;

  /// No description provided for @prDisplayShowDrafts.
  ///
  /// In en, this message translates to:
  /// **'Show drafts'**
  String get prDisplayShowDrafts;

  /// No description provided for @prDisplayMergedWindow.
  ///
  /// In en, this message translates to:
  /// **'Merged window'**
  String get prDisplayMergedWindow;

  /// No description provided for @prDisplayMergedWindowDay.
  ///
  /// In en, this message translates to:
  /// **'Past day'**
  String get prDisplayMergedWindowDay;

  /// No description provided for @prDisplayMergedWindowWeek.
  ///
  /// In en, this message translates to:
  /// **'Past week'**
  String get prDisplayMergedWindowWeek;

  /// No description provided for @prDisplayMergedWindowMonth.
  ///
  /// In en, this message translates to:
  /// **'Past month'**
  String get prDisplayMergedWindowMonth;

  /// No description provided for @prDisplayProperties.
  ///
  /// In en, this message translates to:
  /// **'Display properties'**
  String get prDisplayProperties;

  /// No description provided for @prGroupingRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get prGroupingRepository;

  /// No description provided for @prGroupingAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get prGroupingAuthor;

  /// No description provided for @prGroupingStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get prGroupingStatus;

  /// No description provided for @prGroupingNone.
  ///
  /// In en, this message translates to:
  /// **'No grouping'**
  String get prGroupingNone;

  /// No description provided for @prPropertyRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get prPropertyRepository;

  /// No description provided for @prPropertyId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get prPropertyId;

  /// No description provided for @prPropertyBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get prPropertyBranch;

  /// No description provided for @prPropertyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get prPropertyUpdated;

  /// No description provided for @prPropertyAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get prPropertyAuthor;

  /// No description provided for @prPropertyChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get prPropertyChecks;

  /// No description provided for @prPropertyDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get prPropertyDiff;

  /// No description provided for @prPropertyComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get prPropertyComments;

  /// No description provided for @keybindingOpenFilterMenu.
  ///
  /// In en, this message translates to:
  /// **'Open filter menu'**
  String get keybindingOpenFilterMenu;

  /// No description provided for @countSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String countSelected(int count);

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @kbMove.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get kbMove;

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
  /// **'Theme, language and typography.'**
  String get appearanceSettingsDescription;

  /// No description provided for @notificationsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which agent and workspace events notify you.'**
  String get notificationsSettingsDescription;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @mcpServers.
  ///
  /// In en, this message translates to:
  /// **'MCP servers'**
  String get mcpServers;

  /// No description provided for @mcpServersSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Built-in MCP server and external MCP servers.'**
  String get mcpServersSettingsDescription;

  /// No description provided for @remoteControlAndDevices.
  ///
  /// In en, this message translates to:
  /// **'Remote control & devices'**
  String get remoteControlAndDevices;

  /// No description provided for @remoteControlAndDevicesSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Pair phones and configure the remote-control server.'**
  String get remoteControlAndDevicesSettingsDescription;

  /// No description provided for @voiceAndMeetingsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'The speech and diarization models this server hosts.'**
  String get voiceAndMeetingsSettingsDescription;

  /// No description provided for @needsSetupLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get needsSetupLabel;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @filterSpacesHint.
  ///
  /// In en, this message translates to:
  /// **'Filter spaces'**
  String get filterSpacesHint;

  /// No description provided for @noSpacesMatch.
  ///
  /// In en, this message translates to:
  /// **'No spaces match \"{query}\"'**
  String noSpacesMatch(String query);

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
  /// **'Crash, error and performance diagnostics are sent to help fix bugs (release builds only).'**
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
  /// **'Send crash, error and performance diagnostics so we can fix problems faster (release builds only). You can change this any time in Settings → Privacy.'**
  String get onboardingDiagnosticsSubtitle;

  /// No description provided for @usageAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share usage analytics'**
  String get usageAnalyticsTitle;

  /// No description provided for @usageAnalyticsOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pseudonymous usage events (screens, actions, counts) are sent from every client of this server, release builds only. Never names, message content, file paths or email addresses.'**
  String get usageAnalyticsOnSubtitle;

  /// No description provided for @usageAnalyticsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics are off. No client of this server sends usage events.'**
  String get usageAnalyticsOffSubtitle;

  /// No description provided for @usageAnalyticsManagedOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pseudonymous usage events are sent from this server\'s clients. Only the server operator can change this.'**
  String get usageAnalyticsManagedOnSubtitle;

  /// No description provided for @usageAnalyticsManagedOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics are off on this server. Only the server operator can change this.'**
  String get usageAnalyticsManagedOffSubtitle;

  /// No description provided for @onboardingUsageAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send pseudonymous usage events from every client of this server so we learn which features help (release builds only). Never names, message content, file paths or email addresses. You can change this any time in Settings → Privacy.'**
  String get onboardingUsageAnalyticsSubtitle;

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

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// No description provided for @copyRelativePath.
  ///
  /// In en, this message translates to:
  /// **'Copy relative path'**
  String get copyRelativePath;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @noMatchingAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents match your filter'**
  String get noMatchingAgents;

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

  /// Retention age in days for a workspace backup pruning node
  ///
  /// In en, this message translates to:
  /// **'Delete backups older than (days)'**
  String get nodeConfigBackupRetentionDays;

  /// Safety and validation hint under a backup retention node
  ///
  /// In en, this message translates to:
  /// **'Only backups from this workspace are deleted. Enter a positive number of days.'**
  String get nodeConfigBackupRetentionDaysHelp;

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

  /// No description provided for @activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search activity'**
  String get activitySearchHint;

  /// No description provided for @activityNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No activity matches your filters'**
  String get activityNoMatches;

  /// No description provided for @activityPageRange.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end} of {total}'**
  String activityPageRange(int start, int end, int total);

  /// No description provided for @activityPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get activityPreviousPage;

  /// No description provided for @activityNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get activityNextPage;

  /// No description provided for @activityNetworkLocal.
  ///
  /// In en, this message translates to:
  /// **'Localhost'**
  String get activityNetworkLocal;

  /// No description provided for @activityClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get activityClearFilter;

  /// No description provided for @activityFilterIp.
  ///
  /// In en, this message translates to:
  /// **'IP {ip}'**
  String activityFilterIp(String ip);

  /// No description provided for @activityFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country {country}'**
  String activityFilterCountry(String country);

  /// No description provided for @activitySavedWorkspaceLogo.
  ///
  /// In en, this message translates to:
  /// **'Saved the workspace logo'**
  String get activitySavedWorkspaceLogo;

  /// No description provided for @activityVerbCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {target}'**
  String activityVerbCreated(String target);

  /// No description provided for @activityVerbUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {target}'**
  String activityVerbUpdated(String target);

  /// No description provided for @activityVerbDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {target}'**
  String activityVerbDeleted(String target);

  /// No description provided for @activityVerbAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {target}'**
  String activityVerbAdded(String target);

  /// No description provided for @activityVerbRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {target}'**
  String activityVerbRemoved(String target);

  /// No description provided for @activityVerbInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited {target}'**
  String activityVerbInvited(String target);

  /// No description provided for @activityVerbChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed {target}'**
  String activityVerbChanged(String target);

  /// No description provided for @activityVerbStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {target}'**
  String activityVerbStarted(String target);

  /// No description provided for @activityVerbStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped {target}'**
  String activityVerbStopped(String target);

  /// No description provided for @activityVerbWrote.
  ///
  /// In en, this message translates to:
  /// **'Wrote {target}'**
  String activityVerbWrote(String target);

  /// No description provided for @activityTargetAgent.
  ///
  /// In en, this message translates to:
  /// **'agent'**
  String get activityTargetAgent;

  /// No description provided for @activityTargetTicket.
  ///
  /// In en, this message translates to:
  /// **'ticket'**
  String get activityTargetTicket;

  /// No description provided for @activityTargetWorkspace.
  ///
  /// In en, this message translates to:
  /// **'workspace'**
  String get activityTargetWorkspace;

  /// No description provided for @activityTargetRepository.
  ///
  /// In en, this message translates to:
  /// **'repository'**
  String get activityTargetRepository;

  /// No description provided for @activityTargetMember.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get activityTargetMember;

  /// No description provided for @activityTargetInvite.
  ///
  /// In en, this message translates to:
  /// **'invite'**
  String get activityTargetInvite;

  /// No description provided for @activityTargetSpace.
  ///
  /// In en, this message translates to:
  /// **'space'**
  String get activityTargetSpace;

  /// No description provided for @activityTargetMessage.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get activityTargetMessage;

  /// No description provided for @activityTargetCache.
  ///
  /// In en, this message translates to:
  /// **'cache'**
  String get activityTargetCache;

  /// No description provided for @activityTargetFile.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get activityTargetFile;

  /// No description provided for @activityTargetPipeline.
  ///
  /// In en, this message translates to:
  /// **'pipeline'**
  String get activityTargetPipeline;

  /// No description provided for @activityTargetTemplate.
  ///
  /// In en, this message translates to:
  /// **'template'**
  String get activityTargetTemplate;

  /// No description provided for @activityTargetProvider.
  ///
  /// In en, this message translates to:
  /// **'provider'**
  String get activityTargetProvider;

  /// No description provided for @activityTargetModel.
  ///
  /// In en, this message translates to:
  /// **'model'**
  String get activityTargetModel;

  /// No description provided for @activityTargetSkill.
  ///
  /// In en, this message translates to:
  /// **'skill'**
  String get activityTargetSkill;

  /// No description provided for @activityTargetTodo.
  ///
  /// In en, this message translates to:
  /// **'to-do'**
  String get activityTargetTodo;

  /// No description provided for @activityTargetMeeting.
  ///
  /// In en, this message translates to:
  /// **'meeting'**
  String get activityTargetMeeting;

  /// No description provided for @activityTargetProject.
  ///
  /// In en, this message translates to:
  /// **'project'**
  String get activityTargetProject;

  /// No description provided for @activityTargetTeam.
  ///
  /// In en, this message translates to:
  /// **'team'**
  String get activityTargetTeam;

  /// No description provided for @activityTargetDevice.
  ///
  /// In en, this message translates to:
  /// **'device'**
  String get activityTargetDevice;

  /// No description provided for @activityTargetPreference.
  ///
  /// In en, this message translates to:
  /// **'preference'**
  String get activityTargetPreference;

  /// No description provided for @activityTargetBudget.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get activityTargetBudget;

  /// No description provided for @activityVerbApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved {target}'**
  String activityVerbApproved(String target);

  /// No description provided for @activityVerbArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived {target}'**
  String activityVerbArchived(String target);

  /// No description provided for @activityVerbAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned {target}'**
  String activityVerbAssigned(String target);

  /// No description provided for @activityVerbBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backed up {target}'**
  String activityVerbBackedUp(String target);

  /// No description provided for @activityVerbCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {target}'**
  String activityVerbCancelled(String target);

  /// No description provided for @activityVerbCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared {target}'**
  String activityVerbCleared(String target);

  /// No description provided for @activityVerbClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed {target}'**
  String activityVerbClosed(String target);

  /// No description provided for @activityVerbCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed {target}'**
  String activityVerbCommitted(String target);

  /// No description provided for @activityVerbCompacted.
  ///
  /// In en, this message translates to:
  /// **'Compacted {target}'**
  String activityVerbCompacted(String target);

  /// No description provided for @activityVerbCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {target}'**
  String activityVerbCompleted(String target);

  /// No description provided for @activityVerbConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected {target}'**
  String activityVerbConnected(String target);

  /// No description provided for @activityVerbContinued.
  ///
  /// In en, this message translates to:
  /// **'Continued {target}'**
  String activityVerbContinued(String target);

  /// No description provided for @activityVerbDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected {target}'**
  String activityVerbDisconnected(String target);

  /// No description provided for @activityVerbDispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched {target}'**
  String activityVerbDispatched(String target);

  /// No description provided for @activityVerbDrained.
  ///
  /// In en, this message translates to:
  /// **'Drained {target}'**
  String activityVerbDrained(String target);

  /// No description provided for @activityVerbEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled {target}'**
  String activityVerbEnrolled(String target);

  /// No description provided for @activityVerbEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated {target}'**
  String activityVerbEstimated(String target);

  /// No description provided for @activityVerbImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {target}'**
  String activityVerbImported(String target);

  /// No description provided for @activityVerbInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {target}'**
  String activityVerbInstalled(String target);

  /// No description provided for @activityVerbKilled.
  ///
  /// In en, this message translates to:
  /// **'Killed {target}'**
  String activityVerbKilled(String target);

  /// No description provided for @activityVerbMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked {target}'**
  String activityVerbMarked(String target);

  /// No description provided for @activityVerbMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged {target}'**
  String activityVerbMerged(String target);

  /// No description provided for @activityVerbOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened {target}'**
  String activityVerbOpened(String target);

  /// No description provided for @activityVerbPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused {target}'**
  String activityVerbPaused(String target);

  /// No description provided for @activityVerbPolled.
  ///
  /// In en, this message translates to:
  /// **'Polled {target}'**
  String activityVerbPolled(String target);

  /// No description provided for @activityVerbPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared {target}'**
  String activityVerbPrepared(String target);

  /// No description provided for @activityVerbProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed {target}'**
  String activityVerbProcessed(String target);

  /// No description provided for @activityVerbPublished.
  ///
  /// In en, this message translates to:
  /// **'Published {target}'**
  String activityVerbPublished(String target);

  /// No description provided for @activityVerbRefined.
  ///
  /// In en, this message translates to:
  /// **'Refined {target}'**
  String activityVerbRefined(String target);

  /// No description provided for @activityVerbRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed {target}'**
  String activityVerbRefreshed(String target);

  /// No description provided for @activityVerbRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered {target}'**
  String activityVerbRegistered(String target);

  /// No description provided for @activityVerbRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed {target}'**
  String activityVerbRenamed(String target);

  /// No description provided for @activityVerbReordered.
  ///
  /// In en, this message translates to:
  /// **'Reordered {target}'**
  String activityVerbReordered(String target);

  /// No description provided for @activityVerbResponded.
  ///
  /// In en, this message translates to:
  /// **'Responded to {target}'**
  String activityVerbResponded(String target);

  /// No description provided for @activityVerbRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {target}'**
  String activityVerbRestored(String target);

  /// No description provided for @activityVerbResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed {target}'**
  String activityVerbResumed(String target);

  /// No description provided for @activityVerbRetried.
  ///
  /// In en, this message translates to:
  /// **'Retried {target}'**
  String activityVerbRetried(String target);

  /// No description provided for @activityVerbReverted.
  ///
  /// In en, this message translates to:
  /// **'Reverted {target}'**
  String activityVerbReverted(String target);

  /// No description provided for @activityVerbReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {target}'**
  String activityVerbReviewed(String target);

  /// No description provided for @activityVerbRan.
  ///
  /// In en, this message translates to:
  /// **'Ran {target}'**
  String activityVerbRan(String target);

  /// No description provided for @activityVerbSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected {target}'**
  String activityVerbSelected(String target);

  /// No description provided for @activityVerbSent.
  ///
  /// In en, this message translates to:
  /// **'Sent {target}'**
  String activityVerbSent(String target);

  /// No description provided for @activityVerbStaged.
  ///
  /// In en, this message translates to:
  /// **'Staged {target}'**
  String activityVerbStaged(String target);

  /// No description provided for @activityVerbSteered.
  ///
  /// In en, this message translates to:
  /// **'Steered {target}'**
  String activityVerbSteered(String target);

  /// No description provided for @activityVerbSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {target}'**
  String activityVerbSubmitted(String target);

  /// No description provided for @activityVerbSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced {target}'**
  String activityVerbSynced(String target);

  /// No description provided for @activityVerbToggled.
  ///
  /// In en, this message translates to:
  /// **'Toggled {target}'**
  String activityVerbToggled(String target);

  /// No description provided for @activityVerbUninstalled.
  ///
  /// In en, this message translates to:
  /// **'Uninstalled {target}'**
  String activityVerbUninstalled(String target);

  /// No description provided for @activityVerbUnstaged.
  ///
  /// In en, this message translates to:
  /// **'Unstaged {target}'**
  String activityVerbUnstaged(String target);

  /// No description provided for @activityTargetActionPolicy.
  ///
  /// In en, this message translates to:
  /// **'action policy'**
  String get activityTargetActionPolicy;

  /// No description provided for @activityTargetGoalRun.
  ///
  /// In en, this message translates to:
  /// **'goal run'**
  String get activityTargetGoalRun;

  /// No description provided for @activityTargetRunLog.
  ///
  /// In en, this message translates to:
  /// **'run log'**
  String get activityTargetRunLog;

  /// No description provided for @activityTargetWorkingMemory.
  ///
  /// In en, this message translates to:
  /// **'working memory'**
  String get activityTargetWorkingMemory;

  /// No description provided for @activityTargetRoutingPolicy.
  ///
  /// In en, this message translates to:
  /// **'routing policy'**
  String get activityTargetRoutingPolicy;

  /// No description provided for @activityTargetAutonomy.
  ///
  /// In en, this message translates to:
  /// **'autonomy'**
  String get activityTargetAutonomy;

  /// No description provided for @activityTargetCalendar.
  ///
  /// In en, this message translates to:
  /// **'calendar'**
  String get activityTargetCalendar;

  /// No description provided for @activityTargetChecker.
  ///
  /// In en, this message translates to:
  /// **'checker'**
  String get activityTargetChecker;

  /// No description provided for @activityTargetEditor.
  ///
  /// In en, this message translates to:
  /// **'editor'**
  String get activityTargetEditor;

  /// No description provided for @activityTargetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'confirmation'**
  String get activityTargetConfirmation;

  /// No description provided for @activityTargetTunnel.
  ///
  /// In en, this message translates to:
  /// **'tunnel'**
  String get activityTargetTunnel;

  /// No description provided for @activityTargetConversation.
  ///
  /// In en, this message translates to:
  /// **'conversation'**
  String get activityTargetConversation;

  /// No description provided for @activityTargetCredentials.
  ///
  /// In en, this message translates to:
  /// **'credentials'**
  String get activityTargetCredentials;

  /// No description provided for @activityTargetDictation.
  ///
  /// In en, this message translates to:
  /// **'dictation'**
  String get activityTargetDictation;

  /// No description provided for @activityTargetAgentRun.
  ///
  /// In en, this message translates to:
  /// **'agent run'**
  String get activityTargetAgentRun;

  /// No description provided for @activityTargetEvalSuite.
  ///
  /// In en, this message translates to:
  /// **'eval suite'**
  String get activityTargetEvalSuite;

  /// No description provided for @activityTargetWorker.
  ///
  /// In en, this message translates to:
  /// **'worker'**
  String get activityTargetWorker;

  /// No description provided for @activityTargetWorktree.
  ///
  /// In en, this message translates to:
  /// **'worktree'**
  String get activityTargetWorktree;

  /// No description provided for @activityTargetMcpServer.
  ///
  /// In en, this message translates to:
  /// **'MCP server'**
  String get activityTargetMcpServer;

  /// No description provided for @activityTargetMemoryAccessGrant.
  ///
  /// In en, this message translates to:
  /// **'memory access grant'**
  String get activityTargetMemoryAccessGrant;

  /// No description provided for @activityTargetMemoryDomain.
  ///
  /// In en, this message translates to:
  /// **'memory domain'**
  String get activityTargetMemoryDomain;

  /// No description provided for @activityTargetMemoryFact.
  ///
  /// In en, this message translates to:
  /// **'memory fact'**
  String get activityTargetMemoryFact;

  /// No description provided for @activityTargetMemoryPolicy.
  ///
  /// In en, this message translates to:
  /// **'memory policy'**
  String get activityTargetMemoryPolicy;

  /// No description provided for @activityTargetFeed.
  ///
  /// In en, this message translates to:
  /// **'feed'**
  String get activityTargetFeed;

  /// No description provided for @activityTargetNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get activityTargetNote;

  /// No description provided for @activityTargetOrchestration.
  ///
  /// In en, this message translates to:
  /// **'orchestration'**
  String get activityTargetOrchestration;

  /// No description provided for @activityTargetPipelineRun.
  ///
  /// In en, this message translates to:
  /// **'pipeline run'**
  String get activityTargetPipelineRun;

  /// No description provided for @activityTargetPipelineTrigger.
  ///
  /// In en, this message translates to:
  /// **'pipeline trigger'**
  String get activityTargetPipelineTrigger;

  /// No description provided for @activityTargetPlan.
  ///
  /// In en, this message translates to:
  /// **'plan'**
  String get activityTargetPlan;

  /// No description provided for @activityTargetPlaybook.
  ///
  /// In en, this message translates to:
  /// **'playbook'**
  String get activityTargetPlaybook;

  /// No description provided for @activityTargetPullRequest.
  ///
  /// In en, this message translates to:
  /// **'pull request'**
  String get activityTargetPullRequest;

  /// No description provided for @activityTargetReview.
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get activityTargetReview;

  /// No description provided for @activityTargetProcess.
  ///
  /// In en, this message translates to:
  /// **'process'**
  String get activityTargetProcess;

  /// No description provided for @activityTargetProviderPolicy.
  ///
  /// In en, this message translates to:
  /// **'provider policy'**
  String get activityTargetProviderPolicy;

  /// No description provided for @activityTargetReaction.
  ///
  /// In en, this message translates to:
  /// **'reaction'**
  String get activityTargetReaction;

  /// No description provided for @activityTargetReviewSpace.
  ///
  /// In en, this message translates to:
  /// **'review space'**
  String get activityTargetReviewSpace;

  /// No description provided for @activityTargetReviewStudio.
  ///
  /// In en, this message translates to:
  /// **'review studio'**
  String get activityTargetReviewStudio;

  /// No description provided for @activityTargetServerData.
  ///
  /// In en, this message translates to:
  /// **'server data'**
  String get activityTargetServerData;

  /// No description provided for @activityTargetSoundscape.
  ///
  /// In en, this message translates to:
  /// **'soundscape'**
  String get activityTargetSoundscape;

  /// No description provided for @activityTargetSession.
  ///
  /// In en, this message translates to:
  /// **'session'**
  String get activityTargetSession;

  /// No description provided for @activityTargetTerminal.
  ///
  /// In en, this message translates to:
  /// **'terminal'**
  String get activityTargetTerminal;

  /// No description provided for @activityTargetTicketLink.
  ///
  /// In en, this message translates to:
  /// **'ticket link'**
  String get activityTargetTicketLink;

  /// No description provided for @activityTargetTicketSync.
  ///
  /// In en, this message translates to:
  /// **'ticket sync'**
  String get activityTargetTicketSync;

  /// No description provided for @activityTargetProfile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get activityTargetProfile;

  /// No description provided for @activityTargetVoiceProfile.
  ///
  /// In en, this message translates to:
  /// **'voice profile'**
  String get activityTargetVoiceProfile;

  /// No description provided for @activityTargetWeather.
  ///
  /// In en, this message translates to:
  /// **'weather forecast'**
  String get activityTargetWeather;

  /// No description provided for @activityTargetWorkProduct.
  ///
  /// In en, this message translates to:
  /// **'work product'**
  String get activityTargetWorkProduct;

  /// No description provided for @activityChangedMemberRole.
  ///
  /// In en, this message translates to:
  /// **'Changed a member\'s role'**
  String get activityChangedMemberRole;

  /// No description provided for @activityChangedMemberRepoAccess.
  ///
  /// In en, this message translates to:
  /// **'Changed a member\'s repository access'**
  String get activityChangedMemberRepoAccess;

  /// No description provided for @activityRefreshedWeather.
  ///
  /// In en, this message translates to:
  /// **'Refreshed the weather forecast'**
  String get activityRefreshedWeather;

  /// No description provided for @activitySetWeatherLocation.
  ///
  /// In en, this message translates to:
  /// **'Set the weather location'**
  String get activitySetWeatherLocation;

  /// No description provided for @activityClearedWeatherLocation.
  ///
  /// In en, this message translates to:
  /// **'Cleared the weather location'**
  String get activityClearedWeatherLocation;

  /// No description provided for @activityMarkedAllArticlesRead.
  ///
  /// In en, this message translates to:
  /// **'Marked all articles as read'**
  String get activityMarkedAllArticlesRead;

  /// No description provided for @activityMarkedArticleRead.
  ///
  /// In en, this message translates to:
  /// **'Marked an article as read'**
  String get activityMarkedArticleRead;

  /// No description provided for @activityUpdatedSavedArticle.
  ///
  /// In en, this message translates to:
  /// **'Updated a saved article'**
  String get activityUpdatedSavedArticle;

  /// No description provided for @activityTookOverSession.
  ///
  /// In en, this message translates to:
  /// **'Took over the session'**
  String get activityTookOverSession;

  /// No description provided for @activityHandedBackSession.
  ///
  /// In en, this message translates to:
  /// **'Handed back the session'**
  String get activityHandedBackSession;

  /// No description provided for @activityCommittedAndPushed.
  ///
  /// In en, this message translates to:
  /// **'Committed and pushed'**
  String get activityCommittedAndPushed;

  /// No description provided for @activityBackedUpServer.
  ///
  /// In en, this message translates to:
  /// **'Backed up the server data'**
  String get activityBackedUpServer;

  /// No description provided for @activityMarkedSpaceRead.
  ///
  /// In en, this message translates to:
  /// **'Marked the space as read'**
  String get activityMarkedSpaceRead;

  /// No description provided for @activityRespondedToInvitation.
  ///
  /// In en, this message translates to:
  /// **'Responded to the event invitation'**
  String get activityRespondedToInvitation;

  /// No description provided for @activityDisconnectedCalendar.
  ///
  /// In en, this message translates to:
  /// **'Disconnected the calendar'**
  String get activityDisconnectedCalendar;

  /// No description provided for @activityMarkedFileViewed.
  ///
  /// In en, this message translates to:
  /// **'Marked a file as viewed'**
  String get activityMarkedFileViewed;

  /// No description provided for @activityRespondedToApproval.
  ///
  /// In en, this message translates to:
  /// **'Responded to an approval request'**
  String get activityRespondedToApproval;

  /// No description provided for @activityChangedTunnel.
  ///
  /// In en, this message translates to:
  /// **'Changed the tunnel setting'**
  String get activityChangedTunnel;

  /// No description provided for @activitySentMessageToAgent.
  ///
  /// In en, this message translates to:
  /// **'Sent a message to the agent'**
  String get activitySentMessageToAgent;

  /// No description provided for @activityOpenedReviewSpace.
  ///
  /// In en, this message translates to:
  /// **'Opened the review space'**
  String get activityOpenedReviewSpace;

  /// No description provided for @activityOpenedStandingConversation.
  ///
  /// In en, this message translates to:
  /// **'Opened the standing conversation'**
  String get activityOpenedStandingConversation;

  /// No description provided for @activityStartedRecording.
  ///
  /// In en, this message translates to:
  /// **'Started the recording'**
  String get activityStartedRecording;

  /// No description provided for @activityStoppedRecording.
  ///
  /// In en, this message translates to:
  /// **'Stopped the recording'**
  String get activityStoppedRecording;

  /// No description provided for @activityToggledMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Toggled the MCP server'**
  String get activityToggledMcpServer;

  /// No description provided for @activitySavedApiKey.
  ///
  /// In en, this message translates to:
  /// **'Saved an API key'**
  String get activitySavedApiKey;

  /// No description provided for @activityRemovedProviderCredential.
  ///
  /// In en, this message translates to:
  /// **'Removed a provider credential'**
  String get activityRemovedProviderCredential;

  /// No description provided for @activityUpdatedLinkedRepos.
  ///
  /// In en, this message translates to:
  /// **'Updated the linked repositories'**
  String get activityUpdatedLinkedRepos;

  /// No description provided for @activityUnlinkedRepo.
  ///
  /// In en, this message translates to:
  /// **'Unlinked a repository'**
  String get activityUnlinkedRepo;

  /// No description provided for @activityUpdatedActionItem.
  ///
  /// In en, this message translates to:
  /// **'Updated an action item'**
  String get activityUpdatedActionItem;

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

  /// Add agents
  ///
  /// In en, this message translates to:
  /// **'Add agents'**
  String get addAgents;

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

  /// Hint shown in the reader's address field while it is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a URL'**
  String get addressBarHint;

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

  /// Button that registers the selected folders, with the selection count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Add repository} other {Add {count} repositories}}'**
  String addSelectedRepositories(int count);

  /// Intro text for the add-repo folder browser
  ///
  /// In en, this message translates to:
  /// **'Browse the folders on the machine running the server and select the git checkouts to register.'**
  String get addRepoBrowseIntro;

  /// Button that adds the currently browsed folder to the selection
  ///
  /// In en, this message translates to:
  /// **'Select this folder'**
  String get selectThisFolder;

  /// Button that removes the currently browsed folder from the selection
  ///
  /// In en, this message translates to:
  /// **'Deselect this folder'**
  String get deselectThisFolder;

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

  /// Sidebar label for how many conversations a space holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}}'**
  String conversationCount(int count);

  /// Agent count label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent} other{{count} agents}}'**
  String agentCount(int count);

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

  /// No description provided for @agentsMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsMentionSection;

  /// No description provided for @usersMentionSection.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get usersMentionSection;

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

  /// All agents are already in this space.
  ///
  /// In en, this message translates to:
  /// **'All agents are already in this space.'**
  String get allAgentsAlreadyInSpace;

  /// All commits
  ///
  /// In en, this message translates to:
  /// **'All commits'**
  String get allCommits;

  /// Locale string for allSources
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// Allow
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

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

  /// No description provided for @agentApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get agentApprovalRequired;

  /// Counter above the stacked approval deck when more agent actions are queued behind the one being decided
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more waiting} other{{count} more waiting}}'**
  String agentApprovalsMoreWaiting(int count);

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @articleNoun.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get articleNoun;

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

  /// Ask AI to review this PR
  ///
  /// In en, this message translates to:
  /// **'Ask AI to review this PR'**
  String get askAiReviewDescription;

  /// No description provided for @assignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get assignees;

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

  /// Audio output
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get audioOutput;

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

  /// No description provided for @categoryNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get categoryNavigation;

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

  /// No description provided for @spacesMentionSection.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get spacesMentionSection;

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

  /// Close reader
  ///
  /// In en, this message translates to:
  /// **'Close reader'**
  String get closeReader;

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

  /// Toast shown after /compact folded older history into a summary
  ///
  /// In en, this message translates to:
  /// **'Conversation compacted. Earlier history was folded into a summary.'**
  String get compactDone;

  /// Toast shown when /compact had nothing old enough to fold
  ///
  /// In en, this message translates to:
  /// **'Nothing to compact yet. The conversation is still short.'**
  String get compactNothing;

  /// Toast shown when /compact was refused because a turn is in flight
  ///
  /// In en, this message translates to:
  /// **'An agent is still working. Compact when the turn finishes.'**
  String get compactBusy;

  /// Toast shown when the server cannot compact the conversation
  ///
  /// In en, this message translates to:
  /// **'Compaction is unavailable on this server.'**
  String get compactUnavailable;

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

  /// No description provided for @commentOnThisFile.
  ///
  /// In en, this message translates to:
  /// **'Comment on this file'**
  String get commentOnThisFile;

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
  /// **'Configure agent identities, prompts, skills and view runs.'**
  String get configureAgentIdentities;

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

  /// Preset chip that restores the selected model's context window
  ///
  /// In en, this message translates to:
  /// **'Model · {size}'**
  String modelContextChip(String size);

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Conversation mode
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get conversationMode;

  /// Locale string for cookieRulesCount
  ///
  /// In en, this message translates to:
  /// **'{count} cookie rules'**
  String cookieRulesCount(int count);

  /// Instruction above the field of a destructive-action dialog. {value} is shown as a copyable chip holding the exact text to type.
  ///
  /// In en, this message translates to:
  /// **'Type {value} to confirm.'**
  String typeToConfirmPrompt(String value);

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

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

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

  /// No description provided for @createOrSelectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create or select a workspace before adding repositories.'**
  String get createOrSelectWorkspace;

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

  /// Delete space
  ///
  /// In en, this message translates to:
  /// **'Delete space'**
  String get deleteSpace;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConfirmName(String name);

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

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Detected sandboxing backend
  ///
  /// In en, this message translates to:
  /// **'Detected: {label}'**
  String detectedBackend(String label);

  /// Section label for the runner CLIs found on this machine
  ///
  /// In en, this message translates to:
  /// **'Detected runners'**
  String get detectedRunners;

  /// No description provided for @detectingAdapters.
  ///
  /// In en, this message translates to:
  /// **'Detecting adapters…'**
  String get detectingAdapters;

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

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Marker shown next to a message that has been edited
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// Banner shown in the composer while a sent message is loaded back into it for editing
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// Choice when sending an edited earlier message: hide everything after it and roll the agent's files back
  ///
  /// In en, this message translates to:
  /// **'Revert to there'**
  String get revertToThere;

  /// Choice when sending an edited earlier message: keep the conversation and send the text as a new message
  ///
  /// In en, this message translates to:
  /// **'Send as a new message'**
  String get sendAsNewMessage;

  /// Body of the dialog shown when sending a message that was loaded back into the composer
  ///
  /// In en, this message translates to:
  /// **'Revert hides the messages after this one and rolls the agent\'s files back. You can undo that. Sending as a new message leaves the conversation as it is.'**
  String get editMessageChoiceBody;

  /// Title of the dialog confirming deletion of a chat message
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// Body of the delete-message confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete this message? This can\'t be undone.'**
  String get deleteMessageConfirm;

  /// Placeholder shown in place of a deleted message
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// Title/tooltip for the in-conversation message search
  ///
  /// In en, this message translates to:
  /// **'Search in conversation'**
  String get searchInConversation;

  /// Placeholder in the in-conversation message search field
  ///
  /// In en, this message translates to:
  /// **'Search messages…'**
  String get searchMessagesHint;

  /// Empty-state shown when an in-conversation search has no matches
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get noMessagesFound;

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
  /// **'e.g. Platform'**
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

  /// Error message with detail
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

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

  /// Locale string for feedUrlExample
  ///
  /// In en, this message translates to:
  /// **'e.g. https://example.com/feed.xml'**
  String get feedUrlExample;

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

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @githubLink.
  ///
  /// In en, this message translates to:
  /// **'GitHub link'**
  String get githubLink;

  /// Shown in the service status flyout when the Claude status fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach status.claude.com'**
  String get claudeStatusFetchFailed;

  /// Button label to open status.claude.com in the browser
  ///
  /// In en, this message translates to:
  /// **'Open status.claude.com'**
  String get claudeStatusOpenInBrowser;

  /// Shown in the service status flyout when the GitHub status fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach githubstatus.com'**
  String get githubStatusFetchFailed;

  /// No description provided for @githubDegradedTitle.
  ///
  /// In en, this message translates to:
  /// **'GitHub is reporting problems'**
  String get githubDegradedTitle;

  /// Compact GitHub status line appended to a caveat message
  ///
  /// In en, this message translates to:
  /// **'GitHub status: {status}.'**
  String githubDegradedStatusLine(String status);

  /// Body of the degraded-GitHub banner on the inbox and pull request queue
  ///
  /// In en, this message translates to:
  /// **'GitHub status: {status}. Pull request data may be stale or incomplete until it recovers.'**
  String githubDegradedBody(String status);

  /// Button label to open githubstatus.com in the browser
  ///
  /// In en, this message translates to:
  /// **'Open githubstatus.com'**
  String get githubStatusOpenInBrowser;

  /// Button label to refresh the service statuses
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get githubStatusRefresh;

  /// Relative time the GitHub status was last refreshed
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String githubStatusUpdated(String time);

  /// Shown in the service status flyout when the Kimi (Moonshot AI) status fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach status.moonshot.cn'**
  String get kimiStatusFetchFailed;

  /// Button label to open status.moonshot.cn in the browser
  ///
  /// In en, this message translates to:
  /// **'Open status.moonshot.cn'**
  String get kimiStatusOpenInBrowser;

  /// Shown in the service status flyout when the OpenAI (Codex) status fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach status.openai.com'**
  String get openaiStatusFetchFailed;

  /// Button label to open status.openai.com in the browser
  ///
  /// In en, this message translates to:
  /// **'Open status.openai.com'**
  String get openaiStatusOpenInBrowser;

  /// Service status word: maintenance in progress
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get serviceStatusMaintenance;

  /// Service status word: major issues / partial outage
  ///
  /// In en, this message translates to:
  /// **'Major issues'**
  String get serviceStatusMajorIssues;

  /// Service status word: minor issues / degraded
  ///
  /// In en, this message translates to:
  /// **'Minor issues'**
  String get serviceStatusMinorIssues;

  /// Service status word: all systems operational
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get serviceStatusOperational;

  /// Service status word: critical outage
  ///
  /// In en, this message translates to:
  /// **'Outage'**
  String get serviceStatusOutage;

  /// Last circle of the overlapping service-logo stack on the sidebar service status entry, counting the faulty services whose logos did not fit (e.g. "3+")
  ///
  /// In en, this message translates to:
  /// **'{count}+'**
  String serviceStatusOverflowCount(int count);

  /// Title of the service status flyout (GitHub, Claude, Codex, Kimi)
  ///
  /// In en, this message translates to:
  /// **'Service status'**
  String get serviceStatusTitle;

  /// Service status word: status could not be determined
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get serviceStatusUnknown;

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

  /// Locale string for high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Relative time: hours ago with ICU plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// Compact sidebar age: under a minute
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get sidebarAgeNow;

  /// Compact sidebar age in minutes
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String sidebarAgeMinutes(int count);

  /// Compact sidebar age in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String sidebarAgeHours(int count);

  /// Compact sidebar age in days
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String sidebarAgeDays(int count);

  /// Compact sidebar age in months
  ///
  /// In en, this message translates to:
  /// **'{count}mo'**
  String sidebarAgeMonths(int count);

  /// Compact sidebar age in years
  ///
  /// In en, this message translates to:
  /// **'{count}y'**
  String sidebarAgeYears(int count);

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

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

  /// Installed version label
  ///
  /// In en, this message translates to:
  /// **'Installed {version}'**
  String installedVersion(String version);

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

  /// Relative time: less than a few seconds ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @keepSandboxing.
  ///
  /// In en, this message translates to:
  /// **'Keep sandboxing'**
  String get keepSandboxing;

  /// Locale string for keybindingAddRepository
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get keybindingAddRepository;

  /// Locale string for keybindingCommandPalette
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get keybindingCommandPalette;

  /// Locale string for keybindingFocusSearch
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get keybindingFocusSearch;

  /// Locale string for keybindingNewAgent
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get keybindingNewAgent;

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

  /// Locale string for keybindingNextSpace
  ///
  /// In en, this message translates to:
  /// **'Next space'**
  String get keybindingNextSpace;

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

  /// Locale string for keybindingPreviousSpace
  ///
  /// In en, this message translates to:
  /// **'Previous space'**
  String get keybindingPreviousSpace;

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

  /// Locale string for keybindingSendMessage
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get keybindingSendMessage;

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

  /// No description provided for @killRunning.
  ///
  /// In en, this message translates to:
  /// **'Kill running'**
  String get killRunning;

  /// Option to use the system locale
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

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

  /// No description provided for @loadingProviders.
  ///
  /// In en, this message translates to:
  /// **'Loading providers…'**
  String get loadingProviders;

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

  /// No description provided for @manageWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Manage workspaces'**
  String get manageWorkspaces;

  /// No description provided for @reorderWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Reorder workspace'**
  String get reorderWorkspace;

  /// No description provided for @matchOsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Match your OS appearance or pick a fixed mode.'**
  String get matchOsAppearance;

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

  /// No description provided for @mcpServer.
  ///
  /// In en, this message translates to:
  /// **'MCP server'**
  String get mcpServer;

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
  /// **'Spaces'**
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

  /// No description provided for @navObservability.
  ///
  /// In en, this message translates to:
  /// **'Observability'**
  String get navObservability;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Sidebar row that leaves the settings navigation and returns to the page settings was opened from
  ///
  /// In en, this message translates to:
  /// **'Exit settings'**
  String get exitSettings;

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

  /// Dialog title for creating a new policy
  ///
  /// In en, this message translates to:
  /// **'New policy'**
  String get newPolicy;

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

  /// No description provided for @noAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents'**
  String get noAgents;

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

  /// No description provided for @noSystemFonts.
  ///
  /// In en, this message translates to:
  /// **'No system fonts detected.'**
  String get noSystemFonts;

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

  /// Not found status label
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFoundLabel;

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

  /// No description provided for @notificationPrMentioned.
  ///
  /// In en, this message translates to:
  /// **'Mentioned in pull request'**
  String get notificationPrMentioned;

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

  /// No description provided for @notificationReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get notificationReviewRequested;

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

  /// No description provided for @notifyPrMentioned.
  ///
  /// In en, this message translates to:
  /// **'Notify when you\'re mentioned in a pull request.'**
  String get notifyPrMentioned;

  /// No description provided for @notifyNewMessages.
  ///
  /// In en, this message translates to:
  /// **'Notify when you\'re mentioned in a space.'**
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

  /// No description provided for @notifyReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Notify when your review is requested on a pull request.'**
  String get notifyReviewRequested;

  /// No description provided for @notificationReviewStale.
  ///
  /// In en, this message translates to:
  /// **'Review out of date'**
  String get notificationReviewStale;

  /// No description provided for @notifyReviewStale.
  ///
  /// In en, this message translates to:
  /// **'When new commits land on a pull request you already reviewed'**
  String get notifyReviewStale;

  /// No description provided for @notificationPrMergeReadiness.
  ///
  /// In en, this message translates to:
  /// **'Ready to merge'**
  String get notificationPrMergeReadiness;

  /// No description provided for @notifyPrMergeReadiness.
  ///
  /// In en, this message translates to:
  /// **'Notify when a pull request you authored becomes mergeable, or stops being.'**
  String get notifyPrMergeReadiness;

  /// No description provided for @notificationPrReviewDecision.
  ///
  /// In en, this message translates to:
  /// **'Review decisions'**
  String get notificationPrReviewDecision;

  /// No description provided for @notifyPrReviewDecision.
  ///
  /// In en, this message translates to:
  /// **'Notify when a reviewer approves, requests changes or has an approval dismissed.'**
  String get notifyPrReviewDecision;

  /// No description provided for @notificationPrChecksStatus.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get notificationPrChecksStatus;

  /// No description provided for @notifyPrChecksStatus.
  ///
  /// In en, this message translates to:
  /// **'Notify when CI fails on a pull request you authored, and when it recovers.'**
  String get notifyPrChecksStatus;

  /// No description provided for @notificationPrThreadActivity.
  ///
  /// In en, this message translates to:
  /// **'Review threads'**
  String get notificationPrThreadActivity;

  /// No description provided for @notifyPrThreadActivity.
  ///
  /// In en, this message translates to:
  /// **'Notify when someone replies in or resolves a thread you\'re in.'**
  String get notifyPrThreadActivity;

  /// No description provided for @notificationPrReadyToMerge.
  ///
  /// In en, this message translates to:
  /// **'Ready to merge'**
  String get notificationPrReadyToMerge;

  /// No description provided for @notificationPrReadyToMergeBody.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} has everything it needs.'**
  String notificationPrReadyToMergeBody(String prTitle);

  /// No description provided for @notificationPrMergeBlocked.
  ///
  /// In en, this message translates to:
  /// **'No longer mergeable'**
  String get notificationPrMergeBlocked;

  /// No description provided for @notificationPrMergeBlockedBodyConflicts.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} conflicts with the base branch.'**
  String notificationPrMergeBlockedBodyConflicts(String prTitle);

  /// No description provided for @notificationPrMergeBlockedBodyBehind.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} is behind the base branch.'**
  String notificationPrMergeBlockedBodyBehind(String prTitle);

  /// No description provided for @notificationPrMergeBlockedBodyReviews.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} is waiting on a required review.'**
  String notificationPrMergeBlockedBodyReviews(String prTitle);

  /// No description provided for @notificationPrMergeBlockedBodyChanges.
  ///
  /// In en, this message translates to:
  /// **'A reviewer requested changes on {prTitle}.'**
  String notificationPrMergeBlockedBodyChanges(String prTitle);

  /// No description provided for @notificationPrMergeBlockedBodyChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks are failing on {prTitle}.'**
  String notificationPrMergeBlockedBodyChecks(String prTitle);

  /// No description provided for @notificationPrMergeBlockedBodyOther.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} can no longer be merged.'**
  String notificationPrMergeBlockedBodyOther(String prTitle);

  /// No description provided for @notificationPrApproved.
  ///
  /// In en, this message translates to:
  /// **'Pull request approved'**
  String get notificationPrApproved;

  /// No description provided for @notificationPrApprovedBodyBy.
  ///
  /// In en, this message translates to:
  /// **'{login} approved {prTitle}'**
  String notificationPrApprovedBodyBy(String login, String prTitle);

  /// No description provided for @notificationPrApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} was approved'**
  String notificationPrApprovedBody(String prTitle);

  /// No description provided for @notificationPrReviewersRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no reviewers left} =1{1 reviewer still to respond} other{{count} reviewers still to respond}}'**
  String notificationPrReviewersRemaining(int count);

  /// No description provided for @notificationPrChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get notificationPrChangesRequested;

  /// No description provided for @notificationPrChangesRequestedBodyBy.
  ///
  /// In en, this message translates to:
  /// **'{login} requested changes on {prTitle}'**
  String notificationPrChangesRequestedBodyBy(String login, String prTitle);

  /// No description provided for @notificationPrChangesRequestedBody.
  ///
  /// In en, this message translates to:
  /// **'Changes were requested on {prTitle}'**
  String notificationPrChangesRequestedBody(String prTitle);

  /// No description provided for @notificationPrReviewDismissed.
  ///
  /// In en, this message translates to:
  /// **'Approval dismissed'**
  String get notificationPrReviewDismissed;

  /// No description provided for @notificationPrReviewDismissedBody.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} needs review again.'**
  String notificationPrReviewDismissedBody(String prTitle);

  /// No description provided for @notificationPrChecksFailed.
  ///
  /// In en, this message translates to:
  /// **'Checks failed'**
  String get notificationPrChecksFailed;

  /// No description provided for @notificationPrChecksFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{checkName} failed on {prTitle}'**
  String notificationPrChecksFailedBody(String checkName, String prTitle);

  /// No description provided for @notificationPrChecksFailedBodyUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Checks are failing on {prTitle}'**
  String notificationPrChecksFailedBodyUnnamed(String prTitle);

  /// No description provided for @notificationPrChecksRecovered.
  ///
  /// In en, this message translates to:
  /// **'Checks passing'**
  String get notificationPrChecksRecovered;

  /// No description provided for @notificationPrChecksRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'{prTitle} is green again.'**
  String notificationPrChecksRecoveredBody(String prTitle);

  /// No description provided for @notificationPrMentionedInCommentBody.
  ///
  /// In en, this message translates to:
  /// **'{login} mentioned you in {location}'**
  String notificationPrMentionedInCommentBody(String login, String location);

  /// No description provided for @notificationPrThreadReplied.
  ///
  /// In en, this message translates to:
  /// **'New reply'**
  String get notificationPrThreadReplied;

  /// No description provided for @notificationPrThreadRepliedBody.
  ///
  /// In en, this message translates to:
  /// **'{login} replied in {location}'**
  String notificationPrThreadRepliedBody(String login, String location);

  /// No description provided for @notificationPrThreadResolved.
  ///
  /// In en, this message translates to:
  /// **'Thread resolved'**
  String get notificationPrThreadResolved;

  /// No description provided for @notificationPrThreadResolvedBody.
  ///
  /// In en, this message translates to:
  /// **'Your thread in {location} was resolved.'**
  String notificationPrThreadResolvedBody(String location);

  /// No description provided for @notificationGroupAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get notificationGroupAgents;

  /// No description provided for @notificationGroupPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get notificationGroupPullRequests;

  /// No description provided for @notificationGroupMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationGroupMessages;

  /// No description provided for @notificationGroupTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get notificationGroupTickets;

  /// No description provided for @notificationGroupCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get notificationGroupCalendar;

  /// No description provided for @notificationGroupMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get notificationGroupMachines;

  /// No description provided for @notificationSectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notificationSectionSound;

  /// No description provided for @notificationSectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get notificationSectionSchedule;

  /// No description provided for @notificationSectionEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notificationSectionEvents;

  /// No description provided for @notificationsMutedRepos.
  ///
  /// In en, this message translates to:
  /// **'Muted repositories'**
  String get notificationsMutedRepos;

  /// No description provided for @notificationsMutedReposCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No repositories muted} =1{1 repository muted} other{{count} repositories muted}}'**
  String notificationsMutedReposCount(int count);

  /// No description provided for @notificationsMuteRepo.
  ///
  /// In en, this message translates to:
  /// **'Mute this repository'**
  String get notificationsMuteRepo;

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

  /// No description provided for @openArticlesInApp.
  ///
  /// In en, this message translates to:
  /// **'Open articles in app'**
  String get openArticlesInApp;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @openedInYourBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opened in your browser.'**
  String get openedInYourBrowser;

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

  /// Passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// Paste value here
  ///
  /// In en, this message translates to:
  /// **'Paste value here'**
  String get pasteValueHere;

  /// Locale string for persona
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get persona;

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

  /// Placeholder in the review submission comment box
  ///
  /// In en, this message translates to:
  /// **'Simply click approve, or if you\'re feeling spicy add a comment or reaction…'**
  String get reviewCommentHint;

  /// Empty state in the markdown preview tab of a comment composer
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview'**
  String get nothingToPreview;

  /// Previous match (⇧↵)
  ///
  /// In en, this message translates to:
  /// **'Previous match (⇧↵)'**
  String get previousMatch;

  /// No description provided for @priorityReviewsDescription.
  ///
  /// In en, this message translates to:
  /// **'Priority reviews and repository overview.'**
  String get priorityReviewsDescription;

  /// PRs created
  ///
  /// In en, this message translates to:
  /// **'PRs created'**
  String get prsCreated;

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

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

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

  /// Badge on a repo row the server's forge credential cannot access
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get repoNoAccessBadge;

  /// No description provided for @reportsTo.
  ///
  /// In en, this message translates to:
  /// **'Reports to'**
  String get reportsTo;

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

  /// Toast shown when adding repositories fails, with the count of failed picks and the first error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add {count, plural, =1 {1 repository} other {{count} repositories}}: {error}'**
  String repositoriesAddFailed(int count, String error);

  /// Toast shown after repositories were added, with the added count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Repository added} other {{count} repositories added}}'**
  String repositoriesAdded(int count);

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

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @enclosedTerminalTitle.
  ///
  /// In en, this message translates to:
  /// **'Enclosed terminal'**
  String get enclosedTerminalTitle;

  /// No description provided for @enclosedTerminalStart.
  ///
  /// In en, this message translates to:
  /// **'Open the shell'**
  String get enclosedTerminalStart;

  /// No description provided for @enclosedTerminalStartHint.
  ///
  /// In en, this message translates to:
  /// **'This shell runs inside this conversation’s disposable VM. It boots when you open it, not when the app starts.'**
  String get enclosedTerminalStartHint;

  /// No description provided for @terminalStreamReconnecting.
  ///
  /// In en, this message translates to:
  /// **'stream interrupted — reconnecting…'**
  String get terminalStreamReconnecting;

  /// No description provided for @terminalStreamError.
  ///
  /// In en, this message translates to:
  /// **'stream error:'**
  String get terminalStreamError;

  /// No description provided for @terminalShellExited.
  ///
  /// In en, this message translates to:
  /// **'shell exited'**
  String get terminalShellExited;

  /// Restart shell
  ///
  /// In en, this message translates to:
  /// **'Restart shell'**
  String get restartShell;

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

  /// Runs
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runs;

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

  /// No description provided for @sandboxBackendMicrovmLabel.
  ///
  /// In en, this message translates to:
  /// **'Enclosed VM'**
  String get sandboxBackendMicrovmLabel;

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

  /// Native sandbox is not supported on this platform yet. Falls back to No isolation.
  ///
  /// In en, this message translates to:
  /// **'Native sandbox is not supported on this platform yet. Falls back to \"No isolation\".'**
  String get sandboxUnsupported;

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

  /// PR queue search field / empty-search state
  ///
  /// In en, this message translates to:
  /// **'No matching pull requests'**
  String get noPrsMatchSearch;

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
  /// **'Search KLIPY'**
  String get searchGifsHint;

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

  /// No description provided for @showNativeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show system notifications for events.'**
  String get showNativeNotifications;

  /// Checkbox label to show superseded facts
  ///
  /// In en, this message translates to:
  /// **'Show superseded'**
  String get showSuperseded;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get signedIn;

  /// Signed in to a provider as user
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}.'**
  String signedInAs(String username);

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

  /// Label of the Sources tab on the Skills settings page
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get skillsSourcesTab;

  /// Disclaimer on the skill sources panel
  ///
  /// In en, this message translates to:
  /// **'Skills install from GitHub repositories you add. Repository metadata is untrusted — the antivirus scan is the real safety signal.'**
  String get skillSourcesDisclaimer;

  /// Empty state when no skill sources are registered
  ///
  /// In en, this message translates to:
  /// **'No skill repositories'**
  String get skillSourcesEmpty;

  /// Hint under the empty-sources state
  ///
  /// In en, this message translates to:
  /// **'Add a GitHub repository to browse its skills.'**
  String get skillSourcesEmptyHint;

  /// Button that opens the add-repository dialog
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get skillSourceAdd;

  /// Title of the add-repository dialog
  ///
  /// In en, this message translates to:
  /// **'Add skill repository'**
  String get skillSourceAddTitle;

  /// Placeholder for the repository URL field
  ///
  /// In en, this message translates to:
  /// **'https://github.com/owner/repo'**
  String get skillSourceAddHint;

  /// Error when the entered URL is not a GitHub repo URL
  ///
  /// In en, this message translates to:
  /// **'Enter a GitHub repository URL (https://github.com/owner/repo).'**
  String get skillSourceInvalidUrl;

  /// Toast after a repository is added; {repo} is owner/repo
  ///
  /// In en, this message translates to:
  /// **'Repository {repo} added.'**
  String skillSourceAdded(String repo);

  /// Toast when the repository is already registered; {repo} is owner/repo
  ///
  /// In en, this message translates to:
  /// **'Repository {repo} is already added.'**
  String skillSourceAlreadyAdded(String repo);

  /// Toast after a repository is removed; {repo} is owner/repo
  ///
  /// In en, this message translates to:
  /// **'Repository {repo} removed.'**
  String skillSourceRemoved(String repo);

  /// Remove-repository action label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get skillSourceRemove;

  /// Confirmation title; {repo} is owner/repo
  ///
  /// In en, this message translates to:
  /// **'Remove {repo}?'**
  String skillSourceRemoveConfirmTitle(String repo);

  /// Confirmation body for removing a source
  ///
  /// In en, this message translates to:
  /// **'Installed skills stay installed. Only the repository catalog is removed.'**
  String get skillSourceRemoveConfirmBody;

  /// Empty state when a source repository has no skills
  ///
  /// In en, this message translates to:
  /// **'No skills found in this repository (a skill is a directory containing a SKILL.md).'**
  String get skillSourceNoSkills;

  /// Refresh action for a source's catalog
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get skillSourceRefresh;

  /// Badge when a skill is installed from this source
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get skillSourceInstalledBadge;

  /// Badge when an installed skill has an upstream update
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get skillSourceUpdateBadge;

  /// Badge when the local slug is taken by another skill
  ///
  /// In en, this message translates to:
  /// **'Name in use'**
  String get skillSourceSlugTaken;

  /// Number of files in the skill bundle; {count} is a number
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String skillSourceFilesCount(num count);

  /// Section label above the skill's README
  ///
  /// In en, this message translates to:
  /// **'README'**
  String get skillSourceReadme;

  /// Note when a skill has no README
  ///
  /// In en, this message translates to:
  /// **'This skill has no README.'**
  String get skillSourceNoReadme;

  /// Empty state when the grid filter matches no skills
  ///
  /// In en, this message translates to:
  /// **'No skills match your filter.'**
  String get skillSourceNoMatches;

  /// Update action for an installed skill
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get skillUpdateAction;

  /// Uninstall action label
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get skillUninstallAction;

  /// Confirmation title; {slug} is the skill slug
  ///
  /// In en, this message translates to:
  /// **'Uninstall \"{slug}\"?'**
  String skillUninstallConfirmTitle(String slug);

  /// Toast after a skill is uninstalled; {slug} is the skill slug
  ///
  /// In en, this message translates to:
  /// **'Skill \"{slug}\" uninstalled.'**
  String skillUninstalled(String slug);

  /// Label prefix for a finding's line number
  ///
  /// In en, this message translates to:
  /// **'line'**
  String get skillFindingLine;

  /// Override checkbox label for installing a quarantined skill
  ///
  /// In en, this message translates to:
  /// **'I understand the risk — install anyway'**
  String get skillInstallAnywayOverride;

  /// Toast shown after a skill installs successfully
  ///
  /// In en, this message translates to:
  /// **'Skill \"{slug}\" installed.'**
  String skillInstalled(String slug);

  /// Field label for a skill preview's declared capabilities
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get skillPreviewCapabilities;

  /// Field label for a skill preview's scanner findings
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get skillPreviewFindings;

  /// Field label for a skill preview's required action classes
  ///
  /// In en, this message translates to:
  /// **'Guarded actions'**
  String get skillPreviewGuardedActions;

  /// Badge indicating the scan was reviewed by an LLM
  ///
  /// In en, this message translates to:
  /// **'LLM-reviewed'**
  String get skillPreviewLlmReviewed;

  /// Shown when a skill preview declares no capabilities
  ///
  /// In en, this message translates to:
  /// **'No capabilities declared.'**
  String get skillPreviewNoCapabilities;

  /// Shown when a skill scan produced no findings
  ///
  /// In en, this message translates to:
  /// **'No findings.'**
  String get skillPreviewNoFindings;

  /// Loading message while a registry skill is being scanned
  ///
  /// In en, this message translates to:
  /// **'Scanning skill…'**
  String get skillPreviewScanning;

  /// Field label for a skill's scan verdict
  ///
  /// In en, this message translates to:
  /// **'Scan verdict'**
  String get skillPreviewVerdictLabel;

  /// Verdict badge label for a passing scan
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get skillPreviewVerdictPass;

  /// Verdict badge label for a quarantined scan
  ///
  /// In en, this message translates to:
  /// **'Quarantined'**
  String get skillPreviewVerdictQuarantine;

  /// Verdict badge label for a warning scan
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get skillPreviewVerdictWarn;

  /// Warning shown above the override checkbox for a quarantined skill
  ///
  /// In en, this message translates to:
  /// **'This skill was quarantined by the scanner. Installing it runs code on your machine. Only continue if you trust the source and have reviewed the findings.'**
  String get skillQuarantineWarning;

  /// No description provided for @skillDetachedFromAgents.
  ///
  /// In en, this message translates to:
  /// **'Quarantined and detached from agents: {agents}'**
  String skillDetachedFromAgents(String agents);

  /// No description provided for @skillNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned'**
  String get skillNotScanned;

  /// No description provided for @skillOriginGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get skillOriginGithub;

  /// No description provided for @skillOriginManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get skillOriginManual;

  /// No description provided for @skillOriginRuntimeLocal.
  ///
  /// In en, this message translates to:
  /// **'Runtime local'**
  String get skillOriginRuntimeLocal;

  /// No description provided for @skillRulesStale.
  ///
  /// In en, this message translates to:
  /// **'Scan outdated'**
  String get skillRulesStale;

  /// No description provided for @skillSaveAnywayOverride.
  ///
  /// In en, this message translates to:
  /// **'I understand the risk — save anyway'**
  String get skillSaveAnywayOverride;

  /// No description provided for @skillSaveBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'The content was blocked before anything was written.'**
  String get skillSaveBlockedBody;

  /// No description provided for @skillSaveBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save blocked by the scan gate'**
  String get skillSaveBlockedTitle;

  /// No description provided for @skillScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get skillScanAction;

  /// No description provided for @skillScanAll.
  ///
  /// In en, this message translates to:
  /// **'Scan all'**
  String get skillScanAll;

  /// No description provided for @skillScanAllSummary.
  ///
  /// In en, this message translates to:
  /// **'{pass} passed · {warn} warnings · {quarantine} quarantined'**
  String skillScanAllSummary(int pass, int warn, int quarantine);

  /// No description provided for @skillStateDrifted.
  ///
  /// In en, this message translates to:
  /// **'Modified since install'**
  String get skillStateDrifted;

  /// No description provided for @skillStateUnmanaged.
  ///
  /// In en, this message translates to:
  /// **'Unmanaged'**
  String get skillStateUnmanaged;

  /// Severity tag for a finding that blocks install
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get skillSeverityBlocked;

  /// Severity tag for a warning-level finding
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get skillSeverityWarn;

  /// Tab label for listing installed skills
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get skillsInstalledTab;

  /// Skills
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

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

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Onboarding progress-bar label for the connect step
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get onboardingStepConnect;

  /// Onboarding progress-bar label for the workspace step
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get onboardingStepWorkspace;

  /// Onboarding progress-bar label for the sandbox step
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get onboardingStepSandbox;

  /// Onboarding progress-bar label for the adapter step
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get onboardingStepAdapter;

  /// Onboarding progress-bar label for the optional voice step
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get onboardingStepVoice;

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

  /// Toolbar button that turns a line comment into a code suggestion
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

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

  /// No description provided for @ticketLabel.
  ///
  /// In en, this message translates to:
  /// **'TICKET'**
  String get ticketLabel;

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

  /// Toggle theme
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

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

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

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

  /// Weak isolation - namespace boundary only, no kernel boundary.
  ///
  /// In en, this message translates to:
  /// **'Weak isolation - namespace boundary only, no kernel boundary.'**
  String get weakIsolationDescription;

  /// No description provided for @whenOffServerStaysStopped.
  ///
  /// In en, this message translates to:
  /// **'When off, the server stays stopped until you start it.'**
  String get whenOffServerStaysStopped;

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

  /// Shown while recording: capture and transcription are on-device, but the summary agent may use a cloud model
  ///
  /// In en, this message translates to:
  /// **'Recording and transcription stay on this machine. The summary is written by an agent, so if it uses a cloud model your transcript and notes are sent to that provider.'**
  String get meetingSummaryPrivacyNotice;

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

  /// Tooltip to minimize app to compact focus bar
  ///
  /// In en, this message translates to:
  /// **'Minimize to bar'**
  String get focusModeFloat;

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

  /// Title of the popover listing a pull request stack
  ///
  /// In en, this message translates to:
  /// **'Stacked pull requests'**
  String get stackedPullRequests;

  /// Tooltip on the stack badge of a pull request row
  ///
  /// In en, this message translates to:
  /// **'Part of a stack ({position} of {total})'**
  String partOfStack(int position, int total);

  /// Bulk action button that creates a pull request stack from the selection
  ///
  /// In en, this message translates to:
  /// **'Create stack'**
  String get createStack;

  /// Title of the stack creation confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Create pull request stack'**
  String get createStackDialogTitle;

  /// Body of the stack creation confirmation dialog, followed by the ordered PR list
  ///
  /// In en, this message translates to:
  /// **'These {count} pull requests will be stacked, from the bottom up:'**
  String createStackDialogBody(int count);

  /// Error shown when the selection can't form a stack
  ///
  /// In en, this message translates to:
  /// **'Select at least two pull requests from the same repository to create a stack'**
  String get createStackInvalidSelection;

  /// Error shown when the selected pull requests don't chain by branch
  ///
  /// In en, this message translates to:
  /// **'The selected pull requests don\'t form a chain: each pull request\'s base branch must be the previous one\'s head branch'**
  String get createStackNotAChain;

  /// Error shown when a selected pull request already belongs to a stack
  ///
  /// In en, this message translates to:
  /// **'One or more selected pull requests are already in a stack'**
  String get createStackAlreadyStacked;

  /// Toast shown after a pull request stack is created
  ///
  /// In en, this message translates to:
  /// **'Stack created'**
  String get stackCreated;

  /// Toast shown when stack creation fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the stack'**
  String get stackCreationFailed;

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

  /// Accessibility label for the merge method segmented control
  ///
  /// In en, this message translates to:
  /// **'Merge method'**
  String get mergeMethod;

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

  /// Button label that takes a draft pull request out of draft so reviewers are notified
  ///
  /// In en, this message translates to:
  /// **'Ready for review'**
  String get markReadyForReview;

  /// Confirmation body shown before taking a draft pull request out of draft
  ///
  /// In en, this message translates to:
  /// **'This pull request will leave draft. Reviewers are notified, required checks start gating the merge and any automation watching for ready pull requests runs.'**
  String get markReadyForReviewConfirm;

  /// Overflow menu item that converts an open pull request back to a draft
  ///
  /// In en, this message translates to:
  /// **'Convert to draft'**
  String get convertToDraft;

  /// Confirmation dialog body for converting a pull request back to a draft
  ///
  /// In en, this message translates to:
  /// **'This pull request will go back to draft. Its pending review requests are dismissed and it can no longer be merged until you mark it ready again.'**
  String get convertToDraftConfirm;

  /// Success message after marking a draft pull request ready for review
  ///
  /// In en, this message translates to:
  /// **'Pull request marked ready for review'**
  String get pullRequestMarkedReady;

  /// Success message after converting a pull request back to a draft
  ///
  /// In en, this message translates to:
  /// **'Pull request converted to draft'**
  String get pullRequestConvertedToDraft;

  /// Error message when marking a pull request ready for review fails
  ///
  /// In en, this message translates to:
  /// **'Failed to mark ready for review: {error}'**
  String failedToMarkPrReady(String error);

  /// Error message when converting a pull request to a draft fails
  ///
  /// In en, this message translates to:
  /// **'Failed to convert to draft: {error}'**
  String failedToConvertPrToDraft(String error);

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

  /// Warning that the PR branch conflicts with its base branch and cannot be merged
  ///
  /// In en, this message translates to:
  /// **'This branch has conflicts that must be resolved'**
  String get mergeConflictsWithBase;

  /// Warning that the PR branch is behind its base branch and must be updated before merging
  ///
  /// In en, this message translates to:
  /// **'This branch is out of date with the base branch'**
  String get branchOutOfDateWithBase;

  /// Warning that branch protection rules block merging this pull request
  ///
  /// In en, this message translates to:
  /// **'Branch protection blocks this merge'**
  String get mergeBlockedByBranchProtection;

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

  /// Section heading for the concurrency settings in run settings
  ///
  /// In en, this message translates to:
  /// **'Concurrency'**
  String get pipelineRunSettingsConcurrencyTitle;

  /// Label for the maximum number of runs of a template that may execute at once
  ///
  /// In en, this message translates to:
  /// **'Max parallel runs'**
  String get pipelineRunSettingsMaxParallel;

  /// Help text under the max parallel runs field
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited. Extra runs wait in a queue and start as slots free up.'**
  String get pipelineRunSettingsMaxParallelHelp;

  /// Placeholder in the max parallel runs field meaning no cap
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get pipelineRunSettingsMaxParallelHint;

  /// Validation error when the max parallel runs value is not a positive whole number
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of 1 or more, or leave it empty for unlimited.'**
  String get pipelineRunSettingsMaxParallelInvalid;

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
  /// **'State key the value is stored under (e.g. repo_full_name).'**
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

  /// Pipeline status: queued behind the template concurrency cap
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get pipelineStatusQueued;

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

  /// Run header progress: completed vs total steps
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} steps'**
  String pipelineRunStepProgress(int completed, int total);

  /// Collapsible section header above the pipeline run timing waterfall
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get pipelineWaterfallTimeline;

  /// Pipeline run waterfall header: total time the run was actually executing
  ///
  /// In en, this message translates to:
  /// **'Active {duration}'**
  String pipelineWaterfallActive(String duration);

  /// Pipeline run waterfall chip: time excluded from the active total
  ///
  /// In en, this message translates to:
  /// **'idle {duration}'**
  String pipelineWaterfallIdle(String duration);

  /// Tooltip explaining what the idle chip on the pipeline run waterfall measures
  ///
  /// In en, this message translates to:
  /// **'Time excluded from the active total: the run was stopped or waiting between steps.'**
  String get pipelineWaterfallIdleTooltip;

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

  /// Step detail callout header for a non-fatal skip reason
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get pipelineStepSkippedReason;

  /// Step detail section header: earlier tries of the step before the current one (retry history)
  ///
  /// In en, this message translates to:
  /// **'Previous attempts'**
  String get pipelineStepPriorAttempts;

  /// Step detail label: which try of the step is currently shown (1-based)
  ///
  /// In en, this message translates to:
  /// **'Attempt'**
  String get pipelineStepAttemptLabel;

  /// Step detail prior-attempt row: 1-based try number
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String pipelineStepAttemptN(int number);

  /// Step detail prior-attempt status: the try never settled (the process died or the run was retried underneath it)
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get pipelineStepAttemptInterrupted;

  /// Runs table column header: the pipeline a run belongs to
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get pipelineRunColumnPipeline;

  /// Runs table column header: how long a run was actively executing
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get pipelineRunColumnDuration;

  /// Runs table duration cell for the queued run that will be admitted next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get pipelineRunQueueNext;

  /// Runs table duration cell for a queued run waiting behind others
  ///
  /// In en, this message translates to:
  /// **'{position} in queue'**
  String pipelineRunQueuePosition(int position);

  /// Runs table column header: how long ago a run started
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get pipelineRunColumnStarted;

  /// Opens a menu of the other runs of the same pipeline, for comparing one run against another
  ///
  /// In en, this message translates to:
  /// **'Run history'**
  String get pipelineRunHistory;

  /// Shown in the run history menu when this pipeline has only ever run once
  ///
  /// In en, this message translates to:
  /// **'No other runs yet'**
  String get pipelineRunHistoryEmpty;

  /// When the run's CURRENT attempt started, on a run that has been rerun
  ///
  /// In en, this message translates to:
  /// **'Rerun {time}'**
  String pipelineRunRerunAgo(String time);

  /// Which attempt of a pipeline run the operator is looking at, 1-based
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String pipelineRunAttempt(int number);

  /// When a rerun pipeline run first started, shown beside the current attempt's start
  ///
  /// In en, this message translates to:
  /// **'first started {time}'**
  String pipelineRunFirstStarted(String time);

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

  /// Title for the teams settings screen
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsTitle;

  /// Button to add a new team
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get teamsAddTeam;

  /// Error shown when the teams list fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load teams'**
  String get teamsLoadError;

  /// Title of the empty state when there are no teams
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get teamsEmptyTitle;

  /// Body of the empty state when there are no teams
  ///
  /// In en, this message translates to:
  /// **'Group agents into teams so work assigned to a team routes through a leader who delegates.'**
  String get teamsEmptyDescription;

  /// Title of the create-team dialog
  ///
  /// In en, this message translates to:
  /// **'New team'**
  String get teamCreateTitle;

  /// Title of the edit-team dialog
  ///
  /// In en, this message translates to:
  /// **'Edit team'**
  String get teamEditTitle;

  /// Label for the team name field
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamNameLabel;

  /// Placeholder for the team name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Frontend'**
  String get teamNameHint;

  /// Label for the team description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get teamDescriptionLabel;

  /// Placeholder for the team description field
  ///
  /// In en, this message translates to:
  /// **'What this team is responsible for'**
  String get teamDescriptionHint;

  /// Label for the team leader selector
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get teamLeaderLabel;

  /// Help text explaining the team leader's role
  ///
  /// In en, this message translates to:
  /// **'The coordinator that receives team-assigned work and delegates to the best-suited member.'**
  String get teamLeaderHelp;

  /// Option for a team with no designated leader
  ///
  /// In en, this message translates to:
  /// **'No leader'**
  String get teamNoLeader;

  /// Label for the team operating instructions field
  ///
  /// In en, this message translates to:
  /// **'Operating instructions'**
  String get teamInstructionsLabel;

  /// Help text for the team operating instructions field
  ///
  /// In en, this message translates to:
  /// **'Appended to the leader\'s briefing — team conventions, escalation rules, tone.'**
  String get teamInstructionsHelp;

  /// Placeholder for the optional team instructions field
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get teamInstructionsHint;

  /// Toast shown after saving team changes
  ///
  /// In en, this message translates to:
  /// **'Team saved'**
  String get teamSaved;

  /// Error shown when a team's members fail to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get teamMembersError;

  /// Header label showing how many members a team has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String teamMemberCount(int count);

  /// Button to add a member to a team
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get teamAddMember;

  /// Title of the add-member picker dialog
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get teamAddMemberTitle;

  /// Confirm button in the add-member picker, reflecting the selection count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add} =1{Add 1} other{Add {count}}}'**
  String teamAddMembersCount(int count);

  /// Message when there are no more agents to add to a team
  ///
  /// In en, this message translates to:
  /// **'Every agent is already on this team.'**
  String get teamNoAgentsToAdd;

  /// Tooltip for removing a member from a team
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get teamRemoveMember;

  /// Badge marking the team leader in the member list
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get teamLeaderBadge;

  /// Fallback name for a member whose agent record is missing
  ///
  /// In en, this message translates to:
  /// **'Unknown agent'**
  String get teamUnknownAgent;

  /// Title of the empty state when a team has no members
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get teamMembersEmpty;

  /// Body of the empty state when a team has no members
  ///
  /// In en, this message translates to:
  /// **'Add agents so the leader has people to delegate to.'**
  String get teamMembersEmptyDescription;

  /// Prompt shown when no team is selected
  ///
  /// In en, this message translates to:
  /// **'Select a team'**
  String get teamSelectPrompt;

  /// Body of the prompt shown when no team is selected
  ///
  /// In en, this message translates to:
  /// **'Choose a team from the list, or create a new one.'**
  String get teamSelectPromptDescription;

  /// Title of the delete-team confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete team?'**
  String get teamDeleteTitle;

  /// Body of the delete-team confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'{name} will be deleted. Its agents are not affected.'**
  String teamDeleteBody(String name);

  /// Tooltip on the leader indicator in the team roster
  ///
  /// In en, this message translates to:
  /// **'Has a leader'**
  String get teamHasLeaderTooltip;

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

  /// Empty state for the editor canvas
  ///
  /// In en, this message translates to:
  /// **'Drag a node from the library to start.'**
  String get editorEmptyCanvas;

  /// Eyebrow label above the trigger node on the pipeline editor canvas
  ///
  /// In en, this message translates to:
  /// **'When this happens'**
  String get pipelineWhenThisHappens;

  /// Eyebrow label above the first action nodes on the pipeline editor canvas
  ///
  /// In en, this message translates to:
  /// **'Do this'**
  String get pipelineDoThis;

  /// Button/tooltip that opens the quick-insert step picker on the pipeline editor canvas
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get pipelineAddStep;

  /// Tooltip for the canvas control that auto-arranges pipeline nodes
  ///
  /// In en, this message translates to:
  /// **'Tidy up layout'**
  String get pipelineTidyUp;

  /// Legend hint shown on the pipeline editor canvas
  ///
  /// In en, this message translates to:
  /// **'Drag steps to arrange · drag a handle to connect'**
  String get pipelineEditorHint;

  /// Tooltip for the control that deletes an edge between two pipeline steps
  ///
  /// In en, this message translates to:
  /// **'Remove connection'**
  String get pipelineRemoveConnection;

  /// Tooltip for the output handle that starts an on-canvas edge
  ///
  /// In en, this message translates to:
  /// **'Drag to connect'**
  String get pipelineDragToConnect;

  /// Default name given to a newly created pipeline template
  ///
  /// In en, this message translates to:
  /// **'New pipeline'**
  String get pipelineNewDefaultName;

  /// Node library category grouping the pipeline trigger entries
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get nodeCategoryTriggers;

  /// Display label for the webhook trigger type
  ///
  /// In en, this message translates to:
  /// **'Webhook'**
  String get triggerEventWebhook;

  /// Placeholder tile shown on the pipeline editor canvas when the template has no triggers yet
  ///
  /// In en, this message translates to:
  /// **'Add a trigger'**
  String get pipelineAddTrigger;

  /// Node library entry for a pipeline trigger that fires on a domain event
  ///
  /// In en, this message translates to:
  /// **'On event'**
  String get pipelineOnEvent;

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

  /// Form label for the repo scope selector on conversation-starting nodes
  ///
  /// In en, this message translates to:
  /// **'Repositories to clone'**
  String get nodeConfigRepos;

  /// Helper text for the repo scope selector
  ///
  /// In en, this message translates to:
  /// **'Repos cloned and code-indexed when this node starts its conversation. Selecting every repo clones all of them (the default).'**
  String get nodeConfigReposHelp;

  /// Placeholder for the per-repo base-branch field on the space node
  ///
  /// In en, this message translates to:
  /// **'Branch (default)'**
  String get nodeConfigRepoBranchHint;

  /// Helper text under the per-repo base-branch fields
  ///
  /// In en, this message translates to:
  /// **'The branch each checkout is cut from. Leave empty for the repo\'s own default branch — the worktree still gets its own branch, so nothing an agent commits lands on this one.'**
  String get nodeConfigRepoBranchHelp;

  /// Caption listing placeholder repo entries (e.g. {{repo_id}}) preserved on the node
  ///
  /// In en, this message translates to:
  /// **'Dynamic entries kept: {entries}'**
  String nodeConfigReposDynamic(String entries);

  /// Checkbox label: whether the space node also opens a conversation in the room
  ///
  /// In en, this message translates to:
  /// **'Open a conversation in it'**
  String get nodeConfigCreateConversation;

  /// Helper text for the create-conversation checkbox
  ///
  /// In en, this message translates to:
  /// **'Leave this off when several agent nodes follow — each opens its own named stream. Turn it on when a single agent node follows, so the room never shows an untitled conversation beside it.'**
  String get nodeConfigCreateConversationHelp;

  /// Form label for the name of the conversation the space node opens
  ///
  /// In en, this message translates to:
  /// **'Conversation name'**
  String get nodeConfigConversationTitle;

  /// Helper text for the conversation name field
  ///
  /// In en, this message translates to:
  /// **'Give the agent node downstream the same name and both work in one stream. Defaults to the node\'s label.'**
  String get nodeConfigConversationTitleHelp;

  /// Form label for the name of the room a space node opens
  ///
  /// In en, this message translates to:
  /// **'Space name'**
  String get nodeConfigSpaceName;

  /// Helper text for the room-name field
  ///
  /// In en, this message translates to:
  /// **'What the room this node opens is called. Supports the same state placeholders as a prompt. Leave empty to use the node\'s label.'**
  String get nodeConfigSpaceNameHelp;

  /// Placeholder for the room-name field
  ///
  /// In en, this message translates to:
  /// **'Review of pr_number'**
  String get nodeConfigSpaceNameHint;

  /// Form label for the named stream an agent node writes into
  ///
  /// In en, this message translates to:
  /// **'Conversation name'**
  String get nodeConfigStreamTitle;

  /// Helper text for the stream-name field
  ///
  /// In en, this message translates to:
  /// **'The named stream this node\'s agent works in inside the room. Supports the same state placeholders as a prompt. Leave it empty and the turn lands in the room\'s standing conversation, where a fan-out interleaves every agent.'**
  String get nodeConfigStreamTitleHelp;

  /// Placeholder for the conversation name field
  ///
  /// In en, this message translates to:
  /// **'Architecture analysis'**
  String get nodeConfigConversationTitleHint;

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
  /// **'Runs with bash -c in the OS sandbox. GH_TOKEN and GITHUB_TOKEN hold a read-only token for the linked repository. Placeholders are quoted and substituted before execution.'**
  String get nodeConfigScriptHelp;

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
  /// **'State key holding the directory paths resolve against (default repo_local_path).'**
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

  /// No description provided for @triggerManualHelp.
  ///
  /// In en, this message translates to:
  /// **'Show on the run page and start by hand.'**
  String get triggerManualHelp;

  /// No description provided for @triggerKindSchedule.
  ///
  /// In en, this message translates to:
  /// **'On a schedule'**
  String get triggerKindSchedule;

  /// No description provided for @triggerScheduleExprLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule (cron or every:seconds)'**
  String get triggerScheduleExprLabel;

  /// No description provided for @triggerTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone (optional)'**
  String get triggerTimezoneLabel;

  /// No description provided for @triggerCatchUpLabel.
  ///
  /// In en, this message translates to:
  /// **'On missed runs'**
  String get triggerCatchUpLabel;

  /// No description provided for @triggerCatchUpRunOnce.
  ///
  /// In en, this message translates to:
  /// **'Run once'**
  String get triggerCatchUpRunOnce;

  /// No description provided for @triggerCatchUpSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get triggerCatchUpSkip;

  /// No description provided for @syncHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync health'**
  String get syncHealthTitle;

  /// No description provided for @syncHealthNoConfigs.
  ///
  /// In en, this message translates to:
  /// **'No sync connections yet'**
  String get syncHealthNoConfigs;

  /// No description provided for @syncHealthNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncHealthNeverSynced;

  /// No description provided for @syncOutcomeOk.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncOutcomeOk;

  /// No description provided for @syncOutcomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncOutcomeFailed;

  /// No description provided for @syncOutcomeSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get syncOutcomeSkipped;

  /// No description provided for @syncHealthFailedStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} consecutive failures'**
  String syncHealthFailedStreak(int count);

  /// No description provided for @triggerWebhookHelp.
  ///
  /// In en, this message translates to:
  /// **'A signed webhook URL is generated. External systems POST to it to start this pipeline.'**
  String get triggerWebhookHelp;

  /// No description provided for @triggerWebhookPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Webhook path'**
  String get triggerWebhookPathLabel;

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

  /// No description provided for @triggerEventCodeGraphWatch.
  ///
  /// In en, this message translates to:
  /// **'File change'**
  String get triggerEventCodeGraphWatch;

  /// How many files changed on disk to trigger a background code-index run
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 changed file} other{{count} changed files}}'**
  String pipelineRunCauseChangedFiles(int count);

  /// Suffix after the named changed paths, counting the ones not listed
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String pipelineRunCauseMorePaths(int count);

  /// No description provided for @pipelineRunCauseRescan.
  ///
  /// In en, this message translates to:
  /// **'Changed on disk'**
  String get pipelineRunCauseRescan;

  /// No description provided for @pipelineRunCauseInitial.
  ///
  /// In en, this message translates to:
  /// **'First index of this checkout'**
  String get pipelineRunCauseInitial;

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

  /// No description provided for @ticketingApiKey.
  ///
  /// In en, this message translates to:
  /// **'Ticketing API key'**
  String get ticketingApiKey;

  /// No description provided for @ticketingProvider.
  ///
  /// In en, this message translates to:
  /// **'Ticketing provider'**
  String get ticketingProvider;

  /// No description provided for @connectGitHubAndTicketing.
  ///
  /// In en, this message translates to:
  /// **'Connect a code host so Control Center can read your pull requests, issues and reviews. Optionally connect a ticketing provider. Credentials are held by your server, never by this machine.'**
  String get connectGitHubAndTicketing;

  /// No description provided for @triggerEventTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned'**
  String get triggerEventTicketAssigned;

  /// No description provided for @triggerEventTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get triggerEventTicketCreated;

  /// No description provided for @triggerEventTicketStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Ticket status changed'**
  String get triggerEventTicketStatusChanged;

  /// No description provided for @triggerEventMeetingRecordingStopped.
  ///
  /// In en, this message translates to:
  /// **'Meeting recording stopped'**
  String get triggerEventMeetingRecordingStopped;

  /// No description provided for @triggerEventSkillUpdated.
  ///
  /// In en, this message translates to:
  /// **'Skill updated'**
  String get triggerEventSkillUpdated;

  /// No description provided for @triggerEventSpaceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Space deleted'**
  String get triggerEventSpaceDeleted;

  /// No description provided for @triggerEventSpaceArchived.
  ///
  /// In en, this message translates to:
  /// **'Space archived'**
  String get triggerEventSpaceArchived;

  /// No description provided for @triggerEventSpaceProvisioningChanged.
  ///
  /// In en, this message translates to:
  /// **'Space provisioning changed'**
  String get triggerEventSpaceProvisioningChanged;

  /// No description provided for @triggerEventPrHeadChanged.
  ///
  /// In en, this message translates to:
  /// **'PR head changed'**
  String get triggerEventPrHeadChanged;

  /// No description provided for @triggerEventEnvironmentStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Environment status changed'**
  String get triggerEventEnvironmentStatusChanged;

  /// No description provided for @triggerEventEnvironmentReady.
  ///
  /// In en, this message translates to:
  /// **'Environment ready'**
  String get triggerEventEnvironmentReady;

  /// No description provided for @triggerEventEnvironmentDestroyed.
  ///
  /// In en, this message translates to:
  /// **'Environment destroyed'**
  String get triggerEventEnvironmentDestroyed;

  /// No description provided for @triggerEventEnvironmentProcessExited.
  ///
  /// In en, this message translates to:
  /// **'Environment process exited'**
  String get triggerEventEnvironmentProcessExited;

  /// No description provided for @triggerExternalPrHelp.
  ///
  /// In en, this message translates to:
  /// **'A pull request opened on the code host, not from Control Center.'**
  String get triggerExternalPrHelp;

  /// No description provided for @triggerPrPublishedHelp.
  ///
  /// In en, this message translates to:
  /// **'A pull request opened from Control Center or by an agent.'**
  String get triggerPrPublishedHelp;

  /// No description provided for @triggerPrStatusChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'Merged, closed, opened, reopened, or approved. Filter by status in the inspector.'**
  String get triggerPrStatusChangedHelp;

  /// No description provided for @triggerPrMergedHelp.
  ///
  /// In en, this message translates to:
  /// **'Only when the pull request is merged, not closed or reopened.'**
  String get triggerPrMergedHelp;

  /// No description provided for @triggerRepoAddedHelp.
  ///
  /// In en, this message translates to:
  /// **'A repository is linked to this workspace.'**
  String get triggerRepoAddedHelp;

  /// No description provided for @triggerCodeGraphWatchHelp.
  ///
  /// In en, this message translates to:
  /// **'A file in a linked repository changes on disk.'**
  String get triggerCodeGraphWatchHelp;

  /// No description provided for @triggerMessageReceivedHelp.
  ///
  /// In en, this message translates to:
  /// **'A new message arrives in a space.'**
  String get triggerMessageReceivedHelp;

  /// No description provided for @triggerTicketCreatedHelp.
  ///
  /// In en, this message translates to:
  /// **'A ticket is created in this workspace.'**
  String get triggerTicketCreatedHelp;

  /// No description provided for @triggerTicketStatusChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'A ticket moves between statuses.'**
  String get triggerTicketStatusChangedHelp;

  /// No description provided for @triggerTicketCompletedHelp.
  ///
  /// In en, this message translates to:
  /// **'A ticket finishes successfully.'**
  String get triggerTicketCompletedHelp;

  /// No description provided for @triggerTicketFailedHelp.
  ///
  /// In en, this message translates to:
  /// **'An agent run failed and the ticket is marked failed.'**
  String get triggerTicketFailedHelp;

  /// No description provided for @triggerTicketCancelledHelp.
  ///
  /// In en, this message translates to:
  /// **'A ticket is cancelled and will not continue.'**
  String get triggerTicketCancelledHelp;

  /// No description provided for @triggerBudgetCrossedHelp.
  ///
  /// In en, this message translates to:
  /// **'A workspace or agent spend limit is crossed.'**
  String get triggerBudgetCrossedHelp;

  /// No description provided for @triggerTicketAssignedHelp.
  ///
  /// In en, this message translates to:
  /// **'A ticket is assigned to a person, agent, or team.'**
  String get triggerTicketAssignedHelp;

  /// No description provided for @triggerMeetingRecordingStoppedHelp.
  ///
  /// In en, this message translates to:
  /// **'A meeting recording finishes.'**
  String get triggerMeetingRecordingStoppedHelp;

  /// No description provided for @triggerSkillUpdatedHelp.
  ///
  /// In en, this message translates to:
  /// **'A skill is installed or updated.'**
  String get triggerSkillUpdatedHelp;

  /// No description provided for @triggerSpaceDeletedHelp.
  ///
  /// In en, this message translates to:
  /// **'A conversation space is deleted.'**
  String get triggerSpaceDeletedHelp;

  /// No description provided for @triggerSpaceArchivedHelp.
  ///
  /// In en, this message translates to:
  /// **'A conversation space is archived.'**
  String get triggerSpaceArchivedHelp;

  /// No description provided for @triggerSpaceProvisioningChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'Setup of a space\'s worktrees starts, finishes, or fails.'**
  String get triggerSpaceProvisioningChangedHelp;

  /// No description provided for @triggerPrHeadChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'New commits are pushed to an open pull request.'**
  String get triggerPrHeadChangedHelp;

  /// No description provided for @triggerEnvironmentStatusChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'A space environment moves to a new status.'**
  String get triggerEnvironmentStatusChangedHelp;

  /// No description provided for @triggerEnvironmentReadyHelp.
  ///
  /// In en, this message translates to:
  /// **'A space environment has started and can be used.'**
  String get triggerEnvironmentReadyHelp;

  /// No description provided for @triggerEnvironmentDestroyedHelp.
  ///
  /// In en, this message translates to:
  /// **'A space environment is torn down.'**
  String get triggerEnvironmentDestroyedHelp;

  /// No description provided for @triggerEnvironmentProcessExitedHelp.
  ///
  /// In en, this message translates to:
  /// **'A process run by an environment exits.'**
  String get triggerEnvironmentProcessExitedHelp;

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

  /// No description provided for @stopAgent.
  ///
  /// In en, this message translates to:
  /// **'Stop agent'**
  String get stopAgent;

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

  /// No description provided for @ticketSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket to view its details'**
  String get ticketSelectPrompt;

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

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labels;

  /// No description provided for @noLabelsYet.
  ///
  /// In en, this message translates to:
  /// **'No labels yet'**
  String get noLabelsYet;

  /// No description provided for @clearLabels.
  ///
  /// In en, this message translates to:
  /// **'Clear labels'**
  String get clearLabels;

  /// No description provided for @pipelineStepAgentActivity.
  ///
  /// In en, this message translates to:
  /// **'Agent activity'**
  String get pipelineStepAgentActivity;

  /// No description provided for @runStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get runStatusCompleted;

  /// No description provided for @runStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get runStatusQueued;

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

  /// No description provided for @sidebarGroupWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get sidebarGroupWorkspace;

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

  /// Badge in the notification panel header counting unread entries
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnreadCount(int count);

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get notificationsMarkUnread;

  /// No description provided for @notificationsEntryActions.
  ///
  /// In en, this message translates to:
  /// **'Notification actions'**
  String get notificationsEntryActions;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @teamsNav.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsNav;

  /// No description provided for @noWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No workspace'**
  String get noWorkspace;

  /// Workspace switcher placeholder shown when no workspace is active, inviting selection
  ///
  /// In en, this message translates to:
  /// **'Select a workspace'**
  String get selectWorkspace;

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

  /// Tooltip on a knowledge graph topic node that expands its facts
  ///
  /// In en, this message translates to:
  /// **'Show facts'**
  String get memoryGraphShowFacts;

  /// Tooltip on a knowledge graph topic node that collapses its facts
  ///
  /// In en, this message translates to:
  /// **'Hide facts'**
  String get memoryGraphHideFacts;

  /// Tooltip for the knowledge graph control that expands every topic
  ///
  /// In en, this message translates to:
  /// **'Expand all facts'**
  String get memoryGraphExpandAll;

  /// Tooltip for the knowledge graph control that collapses every topic
  ///
  /// In en, this message translates to:
  /// **'Collapse all facts'**
  String get memoryGraphCollapseAll;

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

  /// No description provided for @agentQuestionFreeformHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer…'**
  String get agentQuestionFreeformHint;

  /// Caption on an ask-user card locating this question in a batch
  ///
  /// In en, this message translates to:
  /// **'Question {index} of {count}'**
  String agentQuestionProgress(int index, int count);

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

  /// No description provided for @agentQuestionTimedOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get agentQuestionTimedOutLabel;

  /// No description provided for @agentQuestionTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left to answer'**
  String get agentQuestionTimeLeft;

  /// No description provided for @agentQuestionFreeformOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe in your own words…'**
  String get agentQuestionFreeformOptionHint;

  /// No description provided for @reviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get reviewRequested;

  /// No description provided for @noRepositoriesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No repositories configured'**
  String get noRepositoriesConfigured;

  /// Relative-time suffix for when a PR was opened
  ///
  /// In en, this message translates to:
  /// **'Opened {age}'**
  String openedAgo(String age);

  /// Activity feed: PR opened event
  ///
  /// In en, this message translates to:
  /// **'{author} opened this pull request'**
  String prTimelineOpened(String author);

  /// Activity feed: PR opened event with commit count
  ///
  /// In en, this message translates to:
  /// **'{author} opened this pull request with {count, plural, =1{1 commit} other{{count} commits}}'**
  String prTimelineOpenedWithCommits(String author, int count);

  /// Activity feed: review requested event
  ///
  /// In en, this message translates to:
  /// **'{actor} requested review from {reviewers}'**
  String prTimelineRequestedReview(String actor, String reviewers);

  /// Activity feed: review request withdrawn event
  ///
  /// In en, this message translates to:
  /// **'{actor} removed the review request for {reviewers}'**
  String prTimelineRemovedReviewRequest(String actor, String reviewers);

  /// Activity feed: grouped review requested and withdrawn events by the same actor
  ///
  /// In en, this message translates to:
  /// **'{actor} requested review from {requested} and removed the review request for {removed}'**
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  );

  /// Activity feed: one or more labels added to the pull request
  ///
  /// In en, this message translates to:
  /// **'{actor} added the {labels} {count, plural, =1{label} other{labels}}'**
  String prTimelineAddedLabels(String actor, String labels, int count);

  /// Activity feed: one or more labels removed from the pull request
  ///
  /// In en, this message translates to:
  /// **'{actor} removed the {labels} {count, plural, =1{label} other{labels}}'**
  String prTimelineRemovedLabels(String actor, String labels, int count);

  /// Activity feed: grouped label add and remove events by the same actor
  ///
  /// In en, this message translates to:
  /// **'{actor} added the {added} {addedCount, plural, =1{label} other{labels}} and removed the {removed} {removedCount, plural, =1{label} other{labels}}'**
  String prTimelineAddedAndRemovedLabels(
    String actor,
    String added,
    int addedCount,
    String removed,
    int removedCount,
  );

  /// Activity feed: commit pushed event (sha + message follow)
  ///
  /// In en, this message translates to:
  /// **'{author} committed'**
  String prTimelineCommitted(String author);

  /// Activity feed: collapsed run of same-author commits (accordion header)
  ///
  /// In en, this message translates to:
  /// **'{author} pushed {count, plural, =1{1 commit} other{{count} commits}}'**
  String prTimelinePushedCommits(String author, int count);

  /// Activity feed: review approved without summary
  ///
  /// In en, this message translates to:
  /// **'{author} approved these changes'**
  String prTimelineApproved(String author);

  /// Activity feed: review requested changes without summary
  ///
  /// In en, this message translates to:
  /// **'{author} requested changes'**
  String prTimelineChangesRequested(String author);

  /// Activity feed: jump-to-diff button under a review row
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code comment} other{{count} code comments}}'**
  String prTimelineCodeComments(int count);

  /// Activity feed: review submitted without verdict or summary
  ///
  /// In en, this message translates to:
  /// **'{author} reviewed'**
  String prTimelineReviewed(String author);

  /// Activity feed: fallback actor name when the forge omitted the user
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get prTimelineSomeone;

  /// Activity feed: badge on comments authored by an app/bot account
  ///
  /// In en, this message translates to:
  /// **'bot'**
  String get prTimelineBotBadge;

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

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @loadingChecks.
  ///
  /// In en, this message translates to:
  /// **'Loading checks…'**
  String get loadingChecks;

  /// No description provided for @noChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No checks have run yet'**
  String get noChecksYet;

  /// No description provided for @noChangesToReview.
  ///
  /// In en, this message translates to:
  /// **'No changes to review'**
  String get noChangesToReview;

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

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @reviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{prs, plural, =1{1 PR} other{{prs} PRs}} awaiting your review across {repos, plural, =1{1 repo} other{{repos} repos}}'**
  String reviewSummary(int prs, int repos);

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

  /// Error shown when saving the workspace logo fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save the logo image. Make sure the app can read the selected file.'**
  String get failedToSaveLogo;

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

  /// Label for the Overview tab on the pull request detail page
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Empty-state label for the files section when a PR changes no files
  ///
  /// In en, this message translates to:
  /// **'No files changed'**
  String get noFilesChanged;

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

  /// Label for the base (before) side of a PR image diff
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get imageDiffBefore;

  /// Label for the head (after) side of a PR image diff
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get imageDiffAfter;

  /// Side-by-side comparison mode for a PR image diff
  ///
  /// In en, this message translates to:
  /// **'2-up'**
  String get imageDiffModeTwoUp;

  /// Swipe-divider comparison mode for a PR image diff
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get imageDiffModeSwipe;

  /// Pixel overlay comparison mode for a PR image diff
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get imageDiffModeDifference;

  /// Caption showing how much of a PR image pair differs
  ///
  /// In en, this message translates to:
  /// **'{percent}% changed'**
  String imageDiffChangedPercent(String percent);

  /// Header toggle to show SVG as pictures instead of XML hunks
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get imageDiffPictures;

  /// Header toggle to show an SVG file's XML source diff
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get imageDiffSource;

  /// Label for the removed (before) side of a PR image asset comparison
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get imageDiffDeleted;

  /// Label for the added (after) side of a PR image asset comparison
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get imageDiffAdded;

  /// Intrinsic pixel size caption under a PR image-diff asset
  ///
  /// In en, this message translates to:
  /// **'W: {width}px | H: {height}px'**
  String imageDiffDimensions(int width, int height);

  /// Badge marking a PR review comment whose diff line no longer exists
  ///
  /// In en, this message translates to:
  /// **'Outdated'**
  String get outdated;

  /// Title of the collapsed group listing a file's outdated PR review comments
  ///
  /// In en, this message translates to:
  /// **'Outdated comments'**
  String get outdatedComments;

  /// Label on the file-header badge that opens the outdated-comments group, showing how many there are
  ///
  /// In en, this message translates to:
  /// **'{count} outdated'**
  String outdatedCountLabel(int count);

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

  /// Button to add labels to a pull request
  ///
  /// In en, this message translates to:
  /// **'Add labels'**
  String get addLabels;

  /// Search hint in the pull request label picker
  ///
  /// In en, this message translates to:
  /// **'Search labels…'**
  String get searchLabels;

  /// Empty state in the pull request label picker when the search matches nothing
  ///
  /// In en, this message translates to:
  /// **'No matching labels'**
  String get noMatchingLabels;

  /// Accessible name for the control that removes a label from a pull request
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String removeLabel(String label);

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

  /// Label for a GitHub user status flagged as busy
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get userStatusBusy;

  /// Section header for teams in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsSectionLabel;

  /// Section header for GitHub's suggested reviewers in the reviewer picker
  ///
  /// In en, this message translates to:
  /// **'Suggested reviewers'**
  String get suggestedReviewers;

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

  /// Footer hint in the markdown editor box
  ///
  /// In en, this message translates to:
  /// **'Markdown is supported'**
  String get markdownSupported;

  /// Footer hint in the markdown editor box; tapping it opens the image picker
  ///
  /// In en, this message translates to:
  /// **'Click to add images'**
  String get markdownAttachImages;

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

  /// Error when updating pull request labels fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update labels: {error}'**
  String failedToUpdateLabels(String error);

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
  /// **'No meetings yet'**
  String get meetingsEmpty;

  /// No description provided for @meetingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Record your first meeting — audio stays on this device and the agent turns it into notes, decisions and action items.'**
  String get meetingsEmptyHint;

  /// No description provided for @meetingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Jot quick notes — the agent expands them after the meeting.'**
  String get meetingNotesHint;

  /// No description provided for @meetingSpeakerMe.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get meetingSpeakerMe;

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

  /// No description provided for @meetingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Captured and transcribed on this device, then summarized by an agent.'**
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

  /// No description provided for @meetingsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No meetings} =1{1 meeting} other{{count} meetings}}'**
  String meetingsCountLabel(int count);

  /// No description provided for @meetingsLedgerOpenActions.
  ///
  /// In en, this message translates to:
  /// **'Open actions'**
  String get meetingsLedgerOpenActions;

  /// No description provided for @meetingsLedgerDecisions.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get meetingsLedgerDecisions;

  /// No description provided for @meetingsLiveOpen.
  ///
  /// In en, this message translates to:
  /// **'Open recording'**
  String get meetingsLiveOpen;

  /// No description provided for @meetingTemplateShort.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get meetingTemplateShort;

  /// No description provided for @meetingsStatThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get meetingsStatThisWeek;

  /// No description provided for @meetingsStatRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get meetingsStatRecorded;

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

  /// No description provided for @meetingReRunNoTranscript.
  ///
  /// In en, this message translates to:
  /// **'There\'s no transcript to summarize yet.'**
  String get meetingReRunNoTranscript;

  /// No description provided for @meetingNotesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate them from the transcript, or write your own.'**
  String get meetingNotesEmptyDescription;

  /// No description provided for @meetingNotesGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate notes'**
  String get meetingNotesGenerate;

  /// No description provided for @meetingNotesWriteOwn.
  ///
  /// In en, this message translates to:
  /// **'Write your own'**
  String get meetingNotesWriteOwn;

  /// No description provided for @meetingNothingTranscribed.
  ///
  /// In en, this message translates to:
  /// **'Nothing was transcribed.'**
  String get meetingNothingTranscribed;

  /// No description provided for @meetingNothingTranscribedDescription.
  ///
  /// In en, this message translates to:
  /// **'There\'s no transcript to summarize, but you can still keep your own notes.'**
  String get meetingNothingTranscribedDescription;

  /// No description provided for @meetingOverviewSpeakers.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get meetingOverviewSpeakers;

  /// No description provided for @meetingOverviewSpeakersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Talk time per speaker appears once there\'s a transcript.'**
  String get meetingOverviewSpeakersEmpty;

  /// Overflow line under the speaker talk-time list.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String meetingOverviewMoreSpeakers(int count);

  /// Screen-reader label for one speaker's talk-time bar.
  ///
  /// In en, this message translates to:
  /// **'{name}: {share} of talk time, {duration}'**
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  );

  /// No description provided for @meetingOverviewActionItemsAllDone.
  ///
  /// In en, this message translates to:
  /// **'All action items are done.'**
  String get meetingOverviewActionItemsAllDone;

  /// Link from an overview section to its full tab.
  ///
  /// In en, this message translates to:
  /// **'View all {count}'**
  String meetingOverviewViewAll(int count);

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
  /// **'Watch the calendar and conferencing apps and offer to record when a meeting starts.'**
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

  /// Badge under an agent turn that ended because it hit the max-turns ceiling
  ///
  /// In en, this message translates to:
  /// **'Stopped at the turn limit — reply to continue'**
  String get turnLimitReached;

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

  /// No description provided for @transcriptErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get transcriptErrorLabel;

  /// No description provided for @transcriptSandboxBlocked.
  ///
  /// In en, this message translates to:
  /// **'Sandbox blocked an action'**
  String get transcriptSandboxBlocked;

  /// No description provided for @transcriptShowFullOutput.
  ///
  /// In en, this message translates to:
  /// **'Show full output (+{kb} KB)'**
  String transcriptShowFullOutput(int kb);

  /// No description provided for @transcriptShowAllLines.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} lines'**
  String transcriptShowAllLines(int count);

  /// No description provided for @transcriptShowingFirstLines.
  ///
  /// In en, this message translates to:
  /// **'Showing first {count} lines'**
  String transcriptShowingFirstLines(int count);

  /// No description provided for @transcriptGrepNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get transcriptGrepNoMatches;

  /// No description provided for @transcriptGrepStats.
  ///
  /// In en, this message translates to:
  /// **'{matches, plural, =1{1 match} other{{matches} matches}} · {files, plural, =1{1 file} other{{files} files}}'**
  String transcriptGrepStats(int matches, int files);

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

  /// No description provided for @connectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedLabel;

  /// No description provided for @ideTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get ideTabGeneral;

  /// No description provided for @ideTabExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get ideTabExplorer;

  /// No description provided for @ideTabSourceControl.
  ///
  /// In en, this message translates to:
  /// **'Source control'**
  String get ideTabSourceControl;

  /// No description provided for @generalSectionTodos.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get generalSectionTodos;

  /// Sidebar section listing the conversation's durable supervised goals (/goal + /loop)
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get generalSectionGoals;

  /// Status chip for a goal the supervisor is actively pursuing
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalRunStatusActive;

  /// Status chip for a goal a human paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get goalRunStatusPaused;

  /// Status chip for a goal the agent declared achieved
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalRunStatusCompleted;

  /// Status chip for a goal the supervisor gave up on after repeated failures
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get goalRunStatusFailed;

  /// Status chip for a goal a human cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get goalRunStatusCancelled;

  /// Status chip for a goal that hit a budget wall (deadline, cost cap, or run budget)
  ///
  /// In en, this message translates to:
  /// **'Budget exhausted'**
  String get goalRunStatusBudgetExhausted;

  /// Secondary line under a live goal: runs dispatched vs. the run budget and dollars spent vs. the cost cap
  ///
  /// In en, this message translates to:
  /// **'Run {run} of {max} · {cost} of {cap}'**
  String goalRunProgress(int run, int max, String cost, String cap);

  /// Secondary line under a live goal with no run cap: runs dispatched so far and dollars spent vs. the cost cap
  ///
  /// In en, this message translates to:
  /// **'Run {run} · {cost} of {cap}'**
  String goalRunProgressNoCap(int run, String cost, String cap);

  /// Goal tooltip line naming the wall-clock deadline
  ///
  /// In en, this message translates to:
  /// **'Due {deadline}'**
  String goalRunDeadline(String deadline);

  /// Icon-button label: pause a live goal
  ///
  /// In en, this message translates to:
  /// **'Pause goal'**
  String get goalRunPause;

  /// Icon-button label: resume a paused goal
  ///
  /// In en, this message translates to:
  /// **'Resume goal'**
  String get goalRunResume;

  /// Tooltip on the resume control of a budget-exhausted goal; names the new cost cap the resume will set
  ///
  /// In en, this message translates to:
  /// **'Resume · raise cap to {cap}'**
  String goalRunResumeRaise(String cap);

  /// Icon-button label: permanently cancel a goal
  ///
  /// In en, this message translates to:
  /// **'Stop goal'**
  String get goalRunStop;

  /// No description provided for @generalSectionAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get generalSectionAgents;

  /// No description provided for @generalSectionTerminals.
  ///
  /// In en, this message translates to:
  /// **'Terminals'**
  String get generalSectionTerminals;

  /// No description provided for @generalTodosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No todos yet'**
  String get generalTodosEmpty;

  /// No description provided for @generalAgentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agents running'**
  String get generalAgentsEmpty;

  /// No description provided for @generalTerminalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No terminals open'**
  String get generalTerminalsEmpty;

  /// No description provided for @generalSectionBrowsers.
  ///
  /// In en, this message translates to:
  /// **'Browsers'**
  String get generalSectionBrowsers;

  /// No description provided for @generalSectionComputers.
  ///
  /// In en, this message translates to:
  /// **'Computers'**
  String get generalSectionComputers;

  /// No description provided for @generalBrowsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No browsers open'**
  String get generalBrowsersEmpty;

  /// No description provided for @generalComputersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No computers open'**
  String get generalComputersEmpty;

  /// No description provided for @generalSectionPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get generalSectionPhones;

  /// No description provided for @generalPhonesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No phones open'**
  String get generalPhonesEmpty;

  /// No description provided for @pauseAgent.
  ///
  /// In en, this message translates to:
  /// **'Pause agent'**
  String get pauseAgent;

  /// No description provided for @resumeAgent.
  ///
  /// In en, this message translates to:
  /// **'Resume agent'**
  String get resumeAgent;

  /// No description provided for @agentCannotPause.
  ///
  /// In en, this message translates to:
  /// **'This agent can\'t be paused — stop it instead.'**
  String get agentCannotPause;

  /// No description provided for @goalClear.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get goalClear;

  /// No description provided for @undoLabelGoalClear.
  ///
  /// In en, this message translates to:
  /// **'clear goal'**
  String get undoLabelGoalClear;

  /// No description provided for @todoStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get todoStatusPending;

  /// No description provided for @todoStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get todoStatusInProgress;

  /// No description provided for @todoStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todoStatusCompleted;

  /// No description provided for @reorderTodo.
  ///
  /// In en, this message translates to:
  /// **'Reorder todo'**
  String get reorderTodo;

  /// No description provided for @focusTerminal.
  ///
  /// In en, this message translates to:
  /// **'Focus terminal'**
  String get focusTerminal;

  /// No description provided for @focusMachine.
  ///
  /// In en, this message translates to:
  /// **'Focus machine'**
  String get focusMachine;

  /// No description provided for @focusBrowser.
  ///
  /// In en, this message translates to:
  /// **'Focus browser'**
  String get focusBrowser;

  /// No description provided for @todoEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit todos'**
  String get todoEditorTitle;

  /// No description provided for @todoEditorHint.
  ///
  /// In en, this message translates to:
  /// **'One item per line. Use - [ ] for pending, - [~] for in progress, - [x] for done.'**
  String get todoEditorHint;

  /// No description provided for @todoNeedsText.
  ///
  /// In en, this message translates to:
  /// **'Add some text after the command'**
  String get todoNeedsText;

  /// No description provided for @todoNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching todo'**
  String get todoNotFound;

  /// No description provided for @todoCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared the todo list'**
  String get todoCleared;

  /// No description provided for @todoNothingToCopy.
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy'**
  String get todoNothingToCopy;

  /// No description provided for @todoAdded.
  ///
  /// In en, this message translates to:
  /// **'Added \"{content}\"'**
  String todoAdded(String content);

  /// No description provided for @todoStarted.
  ///
  /// In en, this message translates to:
  /// **'Started \"{content}\"'**
  String todoStarted(String content);

  /// No description provided for @todoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed \"{content}\"'**
  String todoCompleted(String content);

  /// No description provided for @todoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{content}\"'**
  String todoRemoved(String content);

  /// No description provided for @todoCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} items'**
  String todoCopied(int count);

  /// No description provided for @todoImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items'**
  String todoImported(int count);

  /// No description provided for @todoUnknownSubcommand.
  ///
  /// In en, this message translates to:
  /// **'Unknown todo command \"{name}\"'**
  String todoUnknownSubcommand(String name);

  /// The singular label for one terminal (tab strip + sidebar row) when no live shell title is set.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

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

  /// No description provided for @ideSplitRight.
  ///
  /// In en, this message translates to:
  /// **'Split right'**
  String get ideSplitRight;

  /// No description provided for @ideSplitDown.
  ///
  /// In en, this message translates to:
  /// **'Split down'**
  String get ideSplitDown;

  /// No description provided for @ideSplitLeft.
  ///
  /// In en, this message translates to:
  /// **'Split left'**
  String get ideSplitLeft;

  /// No description provided for @ideSplitUp.
  ///
  /// In en, this message translates to:
  /// **'Split up'**
  String get ideSplitUp;

  /// No description provided for @ideCloseGroup.
  ///
  /// In en, this message translates to:
  /// **'Close group'**
  String get ideCloseGroup;

  /// No description provided for @ideCloseOthers.
  ///
  /// In en, this message translates to:
  /// **'Close others'**
  String get ideCloseOthers;

  /// No description provided for @ideCloseToRight.
  ///
  /// In en, this message translates to:
  /// **'Close to the right'**
  String get ideCloseToRight;

  /// No description provided for @ideCloseSaved.
  ///
  /// In en, this message translates to:
  /// **'Close saved'**
  String get ideCloseSaved;

  /// No description provided for @ideCloseAll.
  ///
  /// In en, this message translates to:
  /// **'Close all'**
  String get ideCloseAll;

  /// No description provided for @ideSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get ideSplit;

  /// No description provided for @ideToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get ideToggleSidebar;

  /// No description provided for @ideNewTab.
  ///
  /// In en, this message translates to:
  /// **'Open editor'**
  String get ideNewTab;

  /// No description provided for @ideNewTabMenu.
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get ideNewTabMenu;

  /// No description provided for @ideReviewCode.
  ///
  /// In en, this message translates to:
  /// **'Review code'**
  String get ideReviewCode;

  /// No description provided for @ideReviewCodeInRepo.
  ///
  /// In en, this message translates to:
  /// **'Review code ({repo})'**
  String ideReviewCodeInRepo(String repo);

  /// No description provided for @ideRevertConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Revert changes'**
  String get ideRevertConfirmTitle;

  /// No description provided for @ideRevertUntracked.
  ///
  /// In en, this message translates to:
  /// **'Untracked files can\'t be reverted'**
  String get ideRevertUntracked;

  /// No description provided for @ideRevertFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t revert the files. The conversation worktree may be unavailable.'**
  String get ideRevertFailed;

  /// No description provided for @ideRevertSomeSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}} couldn\'t be reverted (untracked).'**
  String ideRevertSomeSkipped(int count);

  /// No description provided for @ideSearchMatchCase.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get ideSearchMatchCase;

  /// No description provided for @ideSearchWholeWord.
  ///
  /// In en, this message translates to:
  /// **'Whole word'**
  String get ideSearchWholeWord;

  /// No description provided for @ideSearchRegex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get ideSearchRegex;

  /// No description provided for @ideSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search filters'**
  String get ideSearchFilters;

  /// No description provided for @ideSearchFilesToInclude.
  ///
  /// In en, this message translates to:
  /// **'Files to include'**
  String get ideSearchFilesToInclude;

  /// No description provided for @ideSearchFilesToExclude.
  ///
  /// In en, this message translates to:
  /// **'Files to exclude'**
  String get ideSearchFilesToExclude;

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

  /// No description provided for @ideCodeServer.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get ideCodeServer;

  /// No description provided for @ideUnsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes to {fileName}?'**
  String ideUnsavedChangesTitle(String fileName);

  /// No description provided for @ideUnsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost if you don\'t save them.'**
  String get ideUnsavedChangesBody;

  /// No description provided for @ideDontSave.
  ///
  /// In en, this message translates to:
  /// **'Don\'t save'**
  String get ideDontSave;

  /// No description provided for @editorAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto save'**
  String get editorAutoSave;

  /// No description provided for @editorAutoSaveDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically save changes in the embedded editor.'**
  String get editorAutoSaveDescription;

  /// No description provided for @editorAutoSaveOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get editorAutoSaveOff;

  /// No description provided for @editorAutoSaveAfterDelay.
  ///
  /// In en, this message translates to:
  /// **'After a delay'**
  String get editorAutoSaveAfterDelay;

  /// No description provided for @editorAutoSaveOnFocusChange.
  ///
  /// In en, this message translates to:
  /// **'On focus change'**
  String get editorAutoSaveOnFocusChange;

  /// No description provided for @ideCodeServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Code-server is not available on this server'**
  String get ideCodeServerUnavailable;

  /// No description provided for @ideCodeServerUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Install code-server (coder/code-server) on the server host, then reopen the editor.'**
  String get ideCodeServerUnavailableHint;

  /// No description provided for @ideCodeServerInstalling.
  ///
  /// In en, this message translates to:
  /// **'Preparing editor…'**
  String get ideCodeServerInstalling;

  /// No description provided for @ideCodeServerOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open editor in browser'**
  String get ideCodeServerOpenInBrowser;

  /// No description provided for @ideCodeServerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the editor'**
  String get ideCodeServerError;

  /// No description provided for @paneSuspendedCaption.
  ///
  /// In en, this message translates to:
  /// **'Suspended to save resources — it reloads when focused'**
  String get paneSuspendedCaption;

  /// Inline tree row shown when a directory listing page failed to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this folder'**
  String get ideFolderLoadFailed;

  /// No description provided for @ideFileSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search files'**
  String get ideFileSearchFailed;

  /// No description provided for @ideSearchInFiles.
  ///
  /// In en, this message translates to:
  /// **'Search in files'**
  String get ideSearchInFiles;

  /// No description provided for @ideNoContentMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get ideNoContentMatches;

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

  /// Empty state for the Source Control and Explorer panels when the conversation cloned no repositories
  ///
  /// In en, this message translates to:
  /// **'No repositories in this conversation'**
  String get noReposInConversation;

  /// Source control empty state shown when no conversation is open, so there is no working tree to report on
  ///
  /// In en, this message translates to:
  /// **'Open a conversation to see its changes'**
  String get ideSourceControlNoSpace;

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

  /// Under 'Tool approval' in the External MCP servers section. It governs Control Center's own tools by capability tier (reads, writes, everything), not the personal MCP servers listed in that section, which a run's action policy and confirmations govern
  ///
  /// In en, this message translates to:
  /// **'Which actions of Control Center\'s own tools, called through its MCP endpoint or by its agents, run without asking. Reads are always allowed; higher tiers prompt. Servers inside a run follow that run\'s action policy.'**
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

  /// No description provided for @providersAndModels.
  ///
  /// In en, this message translates to:
  /// **'Providers & models'**
  String get providersAndModels;

  /// No description provided for @providersAndModelsDescription.
  ///
  /// In en, this message translates to:
  /// **'List every provider the built-in agent can use — set an API key or log in with your browser, see each connected provider\'s models and pricing and govern which providers this workspace may use.'**
  String get providersAndModelsDescription;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncNowResult.
  ///
  /// In en, this message translates to:
  /// **'Sync complete — {applied} applied, {failed} failed'**
  String syncNowResult(int applied, int failed);

  /// No description provided for @syncNowFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncNowFailed(String error);

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// Switch semantic label
  ///
  /// In en, this message translates to:
  /// **'Allow {provider}'**
  String allowProviderSemantic(String provider);

  /// Provider enabled via env var
  ///
  /// In en, this message translates to:
  /// **'Enabled via {key}'**
  String enabledViaEnv(String key);

  /// Per-million-token cost
  ///
  /// In en, this message translates to:
  /// **'{input} / {output} per 1M'**
  String costPerMillion(String input, String output);

  /// Context window chip
  ///
  /// In en, this message translates to:
  /// **'{tokens} context'**
  String contextTokens(String tokens);

  /// No description provided for @subscriptionUsage.
  ///
  /// In en, this message translates to:
  /// **'Subscription usage'**
  String get subscriptionUsage;

  /// No description provided for @subscriptionUsageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get subscriptionUsageUnavailable;

  /// No description provided for @subscriptionUsageExhausted.
  ///
  /// In en, this message translates to:
  /// **'Quota exhausted'**
  String get subscriptionUsageExhausted;

  /// No description provided for @subscriptionUsageSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get subscriptionUsageSignInRequired;

  /// No description provided for @subscriptionUsageSignInExpired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in expired, renews on the next run'**
  String get subscriptionUsageSignInExpired;

  /// How much of a quota window is used, under its meter
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String subscriptionUsagePercentUsed(int percent);

  /// Quota reset countdown
  ///
  /// In en, this message translates to:
  /// **'Resets in {duration}'**
  String resetsIn(String duration);

  /// No description provided for @feedbackHelpful.
  ///
  /// In en, this message translates to:
  /// **'This was helpful'**
  String get feedbackHelpful;

  /// No description provided for @feedbackNotHelpful.
  ///
  /// In en, this message translates to:
  /// **'This wasn\'t helpful'**
  String get feedbackNotHelpful;

  /// No description provided for @modeChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get modeChat;

  /// No description provided for @modePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get modePlan;

  /// No description provided for @modeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get modeReview;

  /// No description provided for @modeOrchestrate.
  ///
  /// In en, this message translates to:
  /// **'Orchestrate'**
  String get modeOrchestrate;

  /// No description provided for @editorTheme.
  ///
  /// In en, this message translates to:
  /// **'Editor theme'**
  String get editorTheme;

  /// No description provided for @editorThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Import a VS Code color theme so the embedded diff and editor match your IDE.'**
  String get editorThemeDescription;

  /// No description provided for @editorThemePasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the contents of a VS Code color-theme JSON file'**
  String get editorThemePasteHint;

  /// No description provided for @editorThemeImported.
  ///
  /// In en, this message translates to:
  /// **'Theme imported'**
  String get editorThemeImported;

  /// No description provided for @editorThemeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid VS Code theme'**
  String get editorThemeInvalid;

  /// No description provided for @importTheme.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get importTheme;

  /// No description provided for @clearTheme.
  ///
  /// In en, this message translates to:
  /// **'Clear theme'**
  String get clearTheme;

  /// No description provided for @openInDiffViewer.
  ///
  /// In en, this message translates to:
  /// **'Open in diff viewer'**
  String get openInDiffViewer;

  /// No description provided for @shellCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get shellCommand;

  /// No description provided for @shellOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get shellOutput;

  /// Per-message action: revert the conversation to this point
  ///
  /// In en, this message translates to:
  /// **'Revert to here'**
  String get revertToHere;

  /// Confirmation body for reverting a conversation to a message
  ///
  /// In en, this message translates to:
  /// **'Hide the messages after this point and roll back the agent\'s file changes to this turn? You can undo this.'**
  String get revertConfirmBody;

  /// Confirm button label for reverting a conversation
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get revert;

  /// Toast after a successful conversation revert
  ///
  /// In en, this message translates to:
  /// **'Reverted to here'**
  String get revertedToHere;

  /// Toast when there is nothing to revert/undo
  ///
  /// In en, this message translates to:
  /// **'Nothing to revert'**
  String get nothingToRevert;

  /// Header action: undo the most-recent conversation revert
  ///
  /// In en, this message translates to:
  /// **'Undo revert'**
  String get undoRevert;

  /// Toast after undoing a conversation revert
  ///
  /// In en, this message translates to:
  /// **'Revert undone'**
  String get revertUndone;

  /// No description provided for @systemBehavior.
  ///
  /// In en, this message translates to:
  /// **'System behavior'**
  String get systemBehavior;

  /// No description provided for @keepAwakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep computer awake while agents run'**
  String get keepAwakeTitle;

  /// No description provided for @keepAwakeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The computer won\'t sleep while an agent is working'**
  String get keepAwakeOnSubtitle;

  /// No description provided for @keepAwakeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The computer may sleep even while an agent is working'**
  String get keepAwakeOffSubtitle;

  /// No description provided for @spaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get spaces;

  /// No description provided for @spacesHomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick a space from the list, or start a new one.'**
  String get spacesHomeDescription;

  /// No description provided for @noSpacesYet.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet'**
  String get noSpacesYet;

  /// No description provided for @newSpace.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get newSpace;

  /// No description provided for @spaceName.
  ///
  /// In en, this message translates to:
  /// **'Space name'**
  String get spaceName;

  /// No description provided for @spaceReposHint.
  ///
  /// In en, this message translates to:
  /// **'Repos to include'**
  String get spaceReposHint;

  /// No description provided for @newSpaceFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newSpaceFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @renameSpaceFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get renameSpaceFolder;

  /// No description provided for @deleteSpaceFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get deleteSpaceFolder;

  /// No description provided for @moveSpaceToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveSpaceToFolder;

  /// No description provided for @removeSpaceFromFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get removeSpaceFromFolder;

  /// No description provided for @spaceFolderActions.
  ///
  /// In en, this message translates to:
  /// **'Folder actions'**
  String get spaceFolderActions;

  /// Danger warning when choosing to permanently delete the spaces inside a folder
  ///
  /// In en, this message translates to:
  /// **'Deleting spaces permanently removes their messages and worktrees for everyone. This cannot be undone.'**
  String get deleteFolderWithSpacesWarning;

  /// Checkbox to permanently delete all spaces in a folder when deleting the folder
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the spaces in this folder'**
  String get deleteSpacesInFolder;

  /// Confirmation action for deleting a folder and its spaces permanently
  ///
  /// In en, this message translates to:
  /// **'Delete folder and spaces'**
  String get deleteFolderAndSpaces;

  /// Explains that spaces remain unfiled if the delete-spaces checkbox is left unchecked
  ///
  /// In en, this message translates to:
  /// **'Otherwise, spaces will remain unfiled.'**
  String get keepSpacesInFolder;

  /// Empty state in the space folder picker when no folders exist
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get noSpaceFoldersYet;

  /// No description provided for @ideSourceControl.
  ///
  /// In en, this message translates to:
  /// **'Source control'**
  String get ideSourceControl;

  /// No description provided for @stagedChanges.
  ///
  /// In en, this message translates to:
  /// **'Staged changes'**
  String get stagedChanges;

  /// No description provided for @changes.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changes;

  /// No description provided for @stageFile.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stageFile;

  /// No description provided for @unstageFile.
  ///
  /// In en, this message translates to:
  /// **'Unstage'**
  String get unstageFile;

  /// No description provided for @stageAll.
  ///
  /// In en, this message translates to:
  /// **'Stage all changes'**
  String get stageAll;

  /// No description provided for @unstageAll.
  ///
  /// In en, this message translates to:
  /// **'Unstage all'**
  String get unstageAll;

  /// No description provided for @stageChangesToCommit.
  ///
  /// In en, this message translates to:
  /// **'Stage changes to commit'**
  String get stageChangesToCommit;

  /// No description provided for @syncToPrHead.
  ///
  /// In en, this message translates to:
  /// **'Pull latest PR commits'**
  String get syncToPrHead;

  /// No description provided for @syncedToPrHead.
  ///
  /// In en, this message translates to:
  /// **'Synced to the latest PR commits'**
  String get syncedToPrHead;

  /// No description provided for @syncPrHeadDirty.
  ///
  /// In en, this message translates to:
  /// **'Commit or discard your changes before syncing'**
  String get syncPrHeadDirty;

  /// No description provided for @syncPrHeadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync to the PR head'**
  String get syncPrHeadFailed;

  /// No description provided for @spaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get spaceLabel;

  /// No description provided for @keybindingNewSpace.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get keybindingNewSpace;

  /// No description provided for @jumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// No description provided for @streaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get streaming;

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newMessages;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @agentResponding.
  ///
  /// In en, this message translates to:
  /// **'Agent responding'**
  String get agentResponding;

  /// No description provided for @agentFinished.
  ///
  /// In en, this message translates to:
  /// **'Agent finished'**
  String get agentFinished;

  /// No description provided for @harnessConnectProviderForModels.
  ///
  /// In en, this message translates to:
  /// **'Connect a provider to see models.'**
  String get harnessConnectProviderForModels;

  /// No description provided for @providerSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get providerSignOut;

  /// No description provided for @providerWaitingForDeviceCode.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to confirm the code in your browser…'**
  String get providerWaitingForDeviceCode;

  /// No description provided for @providerDeviceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Check this code matches the one shown in your browser, then approve.'**
  String get providerDeviceCodeHint;

  /// No description provided for @providerPlanUsageLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking plan usage…'**
  String get providerPlanUsageLoading;

  /// No description provided for @providerPlanUsageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This plan didn\'t report usage.'**
  String get providerPlanUsageUnavailable;

  /// No description provided for @providerRemoveKeyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the {provider} API key?'**
  String providerRemoveKeyConfirmTitle(String provider);

  /// No description provided for @providerRemoveKeyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The stored key is deleted and cannot be shown again. Agents using {provider} models stop working until you paste a new one.'**
  String providerRemoveKeyConfirmBody(String provider);

  /// No description provided for @providerRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {provider}?'**
  String providerRemoveConfirmTitle(String provider);

  /// No description provided for @providerRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The provider and its stored key are deleted. Agents pinned to its models stop working.'**
  String providerRemoveConfirmBody(String provider);

  /// No description provided for @providerApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste an API key'**
  String get providerApiKeyHint;

  /// No description provided for @providerApiKeyStoredHint.
  ///
  /// In en, this message translates to:
  /// **'Paste another API key to add it'**
  String get providerApiKeyStoredHint;

  /// No description provided for @providerAddAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Add another account'**
  String get providerAddAnotherAccount;

  /// No description provided for @providerActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get providerActiveBadge;

  /// No description provided for @providerOauthAccountFallback.
  ///
  /// In en, this message translates to:
  /// **'OAuth account'**
  String get providerOauthAccountFallback;

  /// No description provided for @providerApiKeyFallback.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerApiKeyFallback;

  /// No description provided for @providerRemoveCredentialConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this credential?'**
  String get providerRemoveCredentialConfirmTitle;

  /// No description provided for @providerSignOutAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this account?'**
  String get providerSignOutAccountConfirmTitle;

  /// No description provided for @providerCredentialRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Agents using {provider} fall back to its other keys and accounts. With none left, they stop until you add one.'**
  String providerCredentialRemoveConfirmBody(String provider);

  /// No description provided for @providerBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Base URL (optional)'**
  String get providerBaseUrlHint;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get addProvider;

  /// No description provided for @noCustomProviders.
  ///
  /// In en, this message translates to:
  /// **'No custom providers yet.'**
  String get noCustomProviders;

  /// No description provided for @providerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get providerNameLabel;

  /// No description provided for @apiTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'API type'**
  String get apiTypeLabel;

  /// No description provided for @providerBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get providerBaseUrlLabel;

  /// No description provided for @providerApiKeyOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'API key (optional)'**
  String get providerApiKeyOptionalHint;

  /// No description provided for @dialectOpenAiCompatible.
  ///
  /// In en, this message translates to:
  /// **'OpenAI compatible'**
  String get dialectOpenAiCompatible;

  /// No description provided for @dialectAnthropicCompatible.
  ///
  /// In en, this message translates to:
  /// **'Anthropic compatible'**
  String get dialectAnthropicCompatible;

  /// No description provided for @removeProviderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove provider'**
  String get removeProviderTooltip;

  /// No description provided for @providerLogInWithBrowser.
  ///
  /// In en, this message translates to:
  /// **'Log in with browser'**
  String get providerLogInWithBrowser;

  /// No description provided for @providerLoginDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to {provider}'**
  String providerLoginDialogTitle(String provider);

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @selectProviderToLogin.
  ///
  /// In en, this message translates to:
  /// **'Select a provider to log in'**
  String get selectProviderToLogin;

  /// No description provided for @providerLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String providerLoginFailed(String error);

  /// No description provided for @providerWaitingForBrowser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to authorize in the browser…'**
  String get providerWaitingForBrowser;

  /// No description provided for @providerPasteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste the code from your browser'**
  String get providerPasteCodeHint;

  /// No description provided for @providerCompleteLogin.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get providerCompleteLogin;

  /// No description provided for @providerConnectedApiKey.
  ///
  /// In en, this message translates to:
  /// **'Connected via API key'**
  String get providerConnectedApiKey;

  /// No description provided for @providerConnectedOauth.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get providerConnectedOauth;

  /// No description provided for @providerConnectedAccount.
  ///
  /// In en, this message translates to:
  /// **'Connected · {account}'**
  String providerConnectedAccount(String account);

  /// No description provided for @providerLocalReady.
  ///
  /// In en, this message translates to:
  /// **'Local · ready'**
  String get providerLocalReady;

  /// No description provided for @providerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get providerNotConnected;

  /// No description provided for @preparingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Preparing workspace…'**
  String get preparingWorkspace;

  /// No description provided for @provisioningRunningTasks.
  ///
  /// In en, this message translates to:
  /// **'Running worktree tasks for {repo}…'**
  String provisioningRunningTasks(String repo);

  /// No description provided for @provisioningCloningRepo.
  ///
  /// In en, this message translates to:
  /// **'Cloning {repo}…'**
  String provisioningCloningRepo(String repo);

  /// No description provided for @provisioningCheckingOutPr.
  ///
  /// In en, this message translates to:
  /// **'Checking out pull request in {repo}…'**
  String provisioningCheckingOutPr(String repo);

  /// No description provided for @provisioningSettingUpAgent.
  ///
  /// In en, this message translates to:
  /// **'Setting up agent {agent}…'**
  String provisioningSettingUpAgent(String agent);

  /// No description provided for @workspacePrepFailed.
  ///
  /// In en, this message translates to:
  /// **'Workspace setup failed'**
  String get workspacePrepFailed;

  /// No description provided for @workspacePrepStopped.
  ///
  /// In en, this message translates to:
  /// **'Workspace setup stopped'**
  String get workspacePrepStopped;

  /// No description provided for @stopWorkspacePrep.
  ///
  /// In en, this message translates to:
  /// **'Stop preparing'**
  String get stopWorkspacePrep;

  /// No description provided for @stopWorkspacePrepTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop preparing this workspace'**
  String get stopWorkspacePrepTooltip;

  /// No description provided for @stopWorkspacePrepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop preparing this workspace? The clone in progress is discarded — you can start it again from here.'**
  String get stopWorkspacePrepConfirm;

  /// No description provided for @messageWillSendWhenReady.
  ///
  /// In en, this message translates to:
  /// **'{count} message(s) will send when ready'**
  String messageWillSendWhenReady(int count);

  /// No description provided for @membersNav.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersNav;

  /// No description provided for @membersSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'People with access to this workspace: roster, invites and audit trail'**
  String get membersSettingsDescription;

  /// No description provided for @memberRosterLabel.
  ///
  /// In en, this message translates to:
  /// **'Member roster'**
  String get memberRosterLabel;

  /// No description provided for @memberRepoAccessAction.
  ///
  /// In en, this message translates to:
  /// **'Repo access'**
  String get memberRepoAccessAction;

  /// No description provided for @memberRepoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Repo access for {name}'**
  String memberRepoAccessTitle(String name);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get roleGuest;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this workspace? They immediately lose access.'**
  String removeMemberConfirm(String name);

  /// No description provided for @transferOwnershipAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get transferOwnershipAction;

  /// No description provided for @transferOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get transferOwnershipTitle;

  /// No description provided for @transferOwnershipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make {name} the owner of this workspace? You become an admin. Only an owner can delete the workspace or change another admin\'s role.'**
  String transferOwnershipConfirm(String name);

  /// No description provided for @transferOwnershipCta.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferOwnershipCta;

  /// No description provided for @auditTrailLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorization audit trail'**
  String get auditTrailLabel;

  /// No description provided for @auditTrailDescription.
  ///
  /// In en, this message translates to:
  /// **'Every allow and refusal, hash-chained so a modified or deleted entry is detectable.'**
  String get auditTrailDescription;

  /// No description provided for @auditVerifyChain.
  ///
  /// In en, this message translates to:
  /// **'Verify chain'**
  String get auditVerifyChain;

  /// No description provided for @auditChainIntact.
  ///
  /// In en, this message translates to:
  /// **'Chain intact — {count} entries verified'**
  String auditChainIntact(int count);

  /// No description provided for @auditChainBroken.
  ///
  /// In en, this message translates to:
  /// **'Chain broken at entry {seq}: {reason}'**
  String auditChainBroken(int seq, String reason);

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No decisions recorded yet.'**
  String get auditEmpty;

  /// No description provided for @auditDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get auditDenied;

  /// No description provided for @auditAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get auditAllowed;

  /// No description provided for @auditOnBehalfOf.
  ///
  /// In en, this message translates to:
  /// **'for {user}'**
  String auditOnBehalfOf(String user);

  /// No description provided for @policyTemplatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Policy templates'**
  String get policyTemplatesLabel;

  /// No description provided for @policyTemplatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Apply a starting posture, or move one between workspaces.'**
  String get policyTemplatesDescription;

  /// No description provided for @policyTemplateStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get policyTemplateStrict;

  /// No description provided for @policyTemplateBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get policyTemplateBalanced;

  /// No description provided for @policyTemplatePermissive.
  ///
  /// In en, this message translates to:
  /// **'Permissive'**
  String get policyTemplatePermissive;

  /// No description provided for @policyTemplateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get policyTemplateApply;

  /// No description provided for @policyTemplateApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied {count} rules'**
  String policyTemplateApplied(int count);

  /// No description provided for @policyExport.
  ///
  /// In en, this message translates to:
  /// **'Copy policy'**
  String get policyExport;

  /// No description provided for @policyExported.
  ///
  /// In en, this message translates to:
  /// **'Policy copied to the clipboard'**
  String get policyExported;

  /// No description provided for @policyImport.
  ///
  /// In en, this message translates to:
  /// **'Paste policy'**
  String get policyImport;

  /// No description provided for @policyImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} rules'**
  String policyImported(int count);

  /// No description provided for @approveAndRemember.
  ///
  /// In en, this message translates to:
  /// **'Approve for 8 hours'**
  String get approveAndRemember;

  /// No description provided for @approveAndRememberTooltip.
  ///
  /// In en, this message translates to:
  /// **'Approves this action and stops asking for similar ones in this space for 8 hours. It expires on its own.'**
  String get approveAndRememberTooltip;

  /// No description provided for @unknownUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUserLabel;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMember;

  /// No description provided for @inviteRepoAccessHeader.
  ///
  /// In en, this message translates to:
  /// **'Repository access'**
  String get inviteRepoAccessHeader;

  /// No description provided for @inviteRepoAccessExplainer.
  ///
  /// In en, this message translates to:
  /// **'Only the repositories you check are shared with the invitee, at the level you choose. Everything else stays hidden.'**
  String get inviteRepoAccessExplainer;

  /// No description provided for @grantLevelRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get grantLevelRead;

  /// No description provided for @grantLevelReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get grantLevelReview;

  /// No description provided for @grantLevelWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get grantLevelWrite;

  /// No description provided for @inviteExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get inviteExpiryLabel;

  /// No description provided for @expiryOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get expiryOneDay;

  /// No description provided for @expirySevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expirySevenDays;

  /// No description provided for @expiryThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get expiryThirtyDays;

  /// No description provided for @createInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get createInviteAction;

  /// No description provided for @inviteOneTimeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get inviteOneTimeCodeLabel;

  /// No description provided for @inviteCodeShownOnce.
  ///
  /// In en, this message translates to:
  /// **'This code is shown only once — copy it now.'**
  String get inviteCodeShownOnce;

  /// No description provided for @inviteLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get inviteLinkLabel;

  /// No description provided for @inviteRedeemHint.
  ///
  /// In en, this message translates to:
  /// **'Share the code with the invitee; they redeem it against your server URL.'**
  String get inviteRedeemHint;

  /// No description provided for @inviteScanQr.
  ///
  /// In en, this message translates to:
  /// **'Or scan to redeem'**
  String get inviteScanQr;

  /// No description provided for @inviteLoopbackWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite points at a local address'**
  String get inviteLoopbackWarningTitle;

  /// No description provided for @inviteLoopbackWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Collaborators on other machines won\'t be able to reach this server. Start a tunnel (Settings → Integrations → Share this server) or bind to your network so off-host users can connect.'**
  String get inviteLoopbackWarningBody;

  /// No description provided for @inviteStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get inviteStatusOpen;

  /// No description provided for @inviteStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get inviteStatusUsed;

  /// No description provided for @inviteStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get inviteStatusRevoked;

  /// No description provided for @inviteStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inviteStatusExpired;

  /// No description provided for @inviteCreatedTime.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String inviteCreatedTime(String time);

  /// No description provided for @inviteExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'expires {date}'**
  String inviteExpiresOn(String date);

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @couldNotLoadMembers.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get couldNotLoadMembers;

  /// No description provided for @couldNotLoadInvites.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load invites'**
  String get couldNotLoadInvites;

  /// No description provided for @couldNotLoadActivity.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load activity'**
  String get couldNotLoadActivity;

  /// No description provided for @yourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get yourDevices;

  /// No description provided for @yourDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Clients paired to your account on this server.'**
  String get yourDevicesDescription;

  /// No description provided for @noOwnDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices are paired to your account yet'**
  String get noOwnDevices;

  /// No description provided for @renameDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename device'**
  String get renameDeviceTitle;

  /// No description provided for @revokeDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke device'**
  String get revokeDeviceTitle;

  /// No description provided for @revokeDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke {label}? It is disconnected immediately and can no longer reach this server.'**
  String revokeDeviceConfirm(String label);

  /// No description provided for @devicePairedTime.
  ///
  /// In en, this message translates to:
  /// **'Paired {time}'**
  String devicePairedTime(String time);

  /// No description provided for @deviceLastSeenTime.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String deviceLastSeenTime(String time);

  /// No description provided for @deviceNeverSeen.
  ///
  /// In en, this message translates to:
  /// **'Never connected'**
  String get deviceNeverSeen;

  /// No description provided for @profileSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSectionLabel;

  /// No description provided for @profileSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'How you appear to teammates and in git commit authorship in this workspace. Empty fields inherit your account name and email.'**
  String get profileSectionDescription;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @gitAuthorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Git author name'**
  String get gitAuthorNameLabel;

  /// No description provided for @gitAuthorEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Git author email'**
  String get gitAuthorEmailLabel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get presenceOnline;

  /// No description provided for @presenceIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get presenceIdle;

  /// No description provided for @presenceTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get presenceTyping;

  /// Tooltip for a presence avatar chip: participant name and current status
  ///
  /// In en, this message translates to:
  /// **'{name} — {status}'**
  String presenceNameStatus(String name, String status);

  /// No description provided for @presenceRailLabel.
  ///
  /// In en, this message translates to:
  /// **'Who\'s online'**
  String get presenceRailLabel;

  /// Overflow count in the workspace presence rail
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String presencePlusCount(int count);

  /// No description provided for @dndTooltipOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on do not disturb'**
  String get dndTooltipOn;

  /// No description provided for @dndTooltipOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off do not disturb'**
  String get dndTooltipOff;

  /// No description provided for @startPresenting.
  ///
  /// In en, this message translates to:
  /// **'Start presenting'**
  String get startPresenting;

  /// No description provided for @stopPresenting.
  ///
  /// In en, this message translates to:
  /// **'Stop presenting'**
  String get stopPresenting;

  /// Banner shown when a teammate or agent is spotlighting (presenting) this conversation
  ///
  /// In en, this message translates to:
  /// **'{name} is presenting'**
  String spotlightPresentingBanner(String name);

  /// No description provided for @spotlightLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get spotlightLeave;

  /// Shown above the composer when another participant is typing in this conversation
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String typingIndicator(String name);

  /// No description provided for @ideTabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ideTabNotes;

  /// Tooltip for the IDE sidebar overflow caret when every view has a cell in the strip
  ///
  /// In en, this message translates to:
  /// **'All views'**
  String get ideSidebarAllViews;

  /// Tooltip for the IDE sidebar overflow caret when some views are folded into it
  ///
  /// In en, this message translates to:
  /// **'All views ({count} hidden)'**
  String ideSidebarAllViewsHidden(int count);

  /// Pins a view so it keeps an icon cell in the IDE sidebar strip
  ///
  /// In en, this message translates to:
  /// **'Pin to sidebar'**
  String get ideSidebarPinView;

  /// Removes a view's icon cell from the IDE sidebar strip
  ///
  /// In en, this message translates to:
  /// **'Unpin from sidebar'**
  String get ideSidebarUnpinView;

  /// No description provided for @notesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note for anyone who picks up this conversation…'**
  String get notesEmptyHint;

  /// No description provided for @notesEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesEditTooltip;

  /// Caption under the space Notes doc showing who last wrote it and when
  ///
  /// In en, this message translates to:
  /// **'Updated by {name} · {time}'**
  String notesUpdatedBy(String name, String time);

  /// Quiet hint shown when another participant currently holds the Notes soft-claim
  ///
  /// In en, this message translates to:
  /// **'{name} is editing'**
  String notesEditingHint(String name);

  /// No description provided for @notesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the note'**
  String get notesSaveFailed;

  /// No description provided for @reactionAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get reactionAddTooltip;

  /// Tooltip/semantic label for one reaction chip or palette entry
  ///
  /// In en, this message translates to:
  /// **'React with {emoji}'**
  String reactionToggleTooltip(String emoji);

  /// No description provided for @reactionThumbsUp.
  ///
  /// In en, this message translates to:
  /// **'Thumbs up'**
  String get reactionThumbsUp;

  /// No description provided for @reactionThumbsDown.
  ///
  /// In en, this message translates to:
  /// **'Thumbs down'**
  String get reactionThumbsDown;

  /// No description provided for @reactionLaugh.
  ///
  /// In en, this message translates to:
  /// **'Laugh'**
  String get reactionLaugh;

  /// No description provided for @reactionHooray.
  ///
  /// In en, this message translates to:
  /// **'Hooray'**
  String get reactionHooray;

  /// No description provided for @reactionConfused.
  ///
  /// In en, this message translates to:
  /// **'Confused'**
  String get reactionConfused;

  /// No description provided for @reactionHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get reactionHeart;

  /// No description provided for @reactionRocket.
  ///
  /// In en, this message translates to:
  /// **'Rocket'**
  String get reactionRocket;

  /// No description provided for @reactionEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get reactionEyes;

  /// No description provided for @commentReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get commentReact;

  /// No description provided for @commentResolveThread.
  ///
  /// In en, this message translates to:
  /// **'Resolve thread'**
  String get commentResolveThread;

  /// No description provided for @commentReopenThread.
  ///
  /// In en, this message translates to:
  /// **'Reopen thread'**
  String get commentReopenThread;

  /// No description provided for @commentCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link to comment'**
  String get commentCopyLink;

  /// No description provided for @commentCopyMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get commentCopyMarkdown;

  /// No description provided for @commentCopyThreadMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy thread as Markdown'**
  String get commentCopyThreadMarkdown;

  /// No description provided for @commentCopyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy as prompt'**
  String get commentCopyPrompt;

  /// No description provided for @commentCopyThreadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy thread as prompt'**
  String get commentCopyThreadPrompt;

  /// No description provided for @commentSendToAgent.
  ///
  /// In en, this message translates to:
  /// **'Send to agent'**
  String get commentSendToAgent;

  /// No description provided for @commentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get commentDelete;

  /// No description provided for @commentEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get commentEdit;

  /// No description provided for @commentActions.
  ///
  /// In en, this message translates to:
  /// **'Comment actions'**
  String get commentActions;

  /// No description provided for @commentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get commentDeleteTitle;

  /// No description provided for @commentDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the pull request.'**
  String get commentDeleteBody;

  /// No description provided for @commentSentToAgent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the agent'**
  String get commentSentToAgent;

  /// No description provided for @commentSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send this comment to an agent'**
  String get commentSendFailed;

  /// No description provided for @commentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete this comment'**
  String get commentDeleteFailed;

  /// No description provided for @autonomyDialLabel.
  ///
  /// In en, this message translates to:
  /// **'Autonomy'**
  String get autonomyDialLabel;

  /// No description provided for @autonomyProposeOnly.
  ///
  /// In en, this message translates to:
  /// **'Propose only'**
  String get autonomyProposeOnly;

  /// No description provided for @autonomyActWithApproval.
  ///
  /// In en, this message translates to:
  /// **'Act with approval'**
  String get autonomyActWithApproval;

  /// No description provided for @autonomyActFreely.
  ///
  /// In en, this message translates to:
  /// **'Act freely'**
  String get autonomyActFreely;

  /// No description provided for @autonomyDefaultOption.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get autonomyDefaultOption;

  /// No description provided for @checkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get checkerLabel;

  /// No description provided for @checkerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get checkerNone;

  /// No description provided for @checkerCaption.
  ///
  /// In en, this message translates to:
  /// **'The checker reviews other agents\' completed runs.'**
  String get checkerCaption;

  /// No description provided for @takeoverTooltip.
  ///
  /// In en, this message translates to:
  /// **'Take over the worktree'**
  String get takeoverTooltip;

  /// No description provided for @takeoverBannerSelf.
  ///
  /// In en, this message translates to:
  /// **'You have taken over this conversation\'s worktree'**
  String get takeoverBannerSelf;

  /// Banner shown in the conversation pane while another participant holds the worktree take-over
  ///
  /// In en, this message translates to:
  /// **'{name} has taken over this conversation\'s worktree'**
  String takeoverBannerOther(String name);

  /// No description provided for @handBackButton.
  ///
  /// In en, this message translates to:
  /// **'Hand back'**
  String get handBackButton;

  /// No description provided for @handBackDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand back the worktree'**
  String get handBackDialogTitle;

  /// No description provided for @handBackDialogNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for the agent…'**
  String get handBackDialogNoteHint;

  /// Toast shown when takeover.begin fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t take over: {message}'**
  String takeoverFailed(String message);

  /// Toast shown when takeover.handBack fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hand back: {message}'**
  String handBackFailed(String message);

  /// Plan Studio: planStudioTitle
  ///
  /// In en, this message translates to:
  /// **'Plan Studio'**
  String get planStudioTitle;

  /// Plan Studio: plansTitle
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// Plan Studio: plansSubtitle
  ///
  /// In en, this message translates to:
  /// **'Active plans, plan documents and playbooks'**
  String get plansSubtitle;

  /// Plan Studio: plansActiveSection
  ///
  /// In en, this message translates to:
  /// **'Active plans'**
  String get plansActiveSection;

  /// Plan Studio: plansDocumentsSection
  ///
  /// In en, this message translates to:
  /// **'Plan documents'**
  String get plansDocumentsSection;

  /// Plan Studio: plansPlaybooksSection
  ///
  /// In en, this message translates to:
  /// **'Playbooks'**
  String get plansPlaybooksSection;

  /// Plan Studio: plansNoActive
  ///
  /// In en, this message translates to:
  /// **'No active plans yet.'**
  String get plansNoActive;

  /// Plan Studio: plansNoDocuments
  ///
  /// In en, this message translates to:
  /// **'No plan documents yet.'**
  String get plansNoDocuments;

  /// Plan Studio: plansNoPlaybooks
  ///
  /// In en, this message translates to:
  /// **'No playbooks yet.'**
  String get plansNoPlaybooks;

  /// Plan Studio: planNotFound
  ///
  /// In en, this message translates to:
  /// **'Plan not found.'**
  String get planNotFound;

  /// Plan Studio: planOpenInStudio
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get planOpenInStudio;

  /// Plan Studio: planNodeTitle
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get planNodeTitle;

  /// Plan Studio: planNodeDescription
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get planNodeDescription;

  /// Plan Studio: planNodeDescriptionHint
  ///
  /// In en, this message translates to:
  /// **'What this step should do…'**
  String get planNodeDescriptionHint;

  /// Plan Studio: planNodeApplyDescription
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get planNodeApplyDescription;

  /// Plan Studio: planNodeRole
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get planNodeRole;

  /// Plan Studio: planNodeDependencies
  ///
  /// In en, this message translates to:
  /// **'Depends on'**
  String get planNodeDependencies;

  /// Plan Studio: placeholder on the node dependency picker
  ///
  /// In en, this message translates to:
  /// **'Add a dependency'**
  String get planNodeDependenciesHint;

  /// Plan Studio: selected count on the node dependency picker
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dependency} other{{count} dependencies}}'**
  String planNodeDependencyCount(int count);

  /// Plan Studio: hint shown when a node has no dependencies
  ///
  /// In en, this message translates to:
  /// **'No dependencies, so this runs as soon as the plan starts'**
  String get planNodeNoDependencies;

  /// Plan Studio: planNodeOutputSchema
  ///
  /// In en, this message translates to:
  /// **'Output schema (JSON)'**
  String get planNodeOutputSchema;

  /// Plan Studio: planNodeEstimate
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get planNodeEstimate;

  /// Plan Studio: planNodeProvenance
  ///
  /// In en, this message translates to:
  /// **'Provenance'**
  String get planNodeProvenance;

  /// Plan Studio: planNodeAlreadyExecuted
  ///
  /// In en, this message translates to:
  /// **'Already executed — editing forks the plan from here.'**
  String get planNodeAlreadyExecuted;

  /// Plan Studio: planNewNodeTitle
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get planNewNodeTitle;

  /// Plan Studio: planEstimateNoHistory
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get planEstimateNoHistory;

  /// Plan Studio: planEstimateBlastUnknown
  ///
  /// In en, this message translates to:
  /// **'Blast radius: unknown'**
  String get planEstimateBlastUnknown;

  /// Plan Studio: planEstimatePartial
  ///
  /// In en, this message translates to:
  /// **'partial'**
  String get planEstimatePartial;

  /// Plan Studio: planEstimateAction
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get planEstimateAction;

  /// Plan Studio: planEstimateDuration
  ///
  /// In en, this message translates to:
  /// **'Duration {range}'**
  String planEstimateDuration(String range);

  /// Plan Studio: planEstimateBlastRadius
  ///
  /// In en, this message translates to:
  /// **'Blast radius: {files} files, {symbols} symbols'**
  String planEstimateBlastRadius(int files, int symbols);

  /// Plan Studio: planApprove
  ///
  /// In en, this message translates to:
  /// **'Approve plan'**
  String get planApprove;

  /// Plan Studio: planApproveSelectedNodes
  ///
  /// In en, this message translates to:
  /// **'Approve selected'**
  String get planApproveSelectedNodes;

  /// Plan Studio: planReject
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get planReject;

  /// Plan Studio: planCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel run'**
  String get planCancel;

  /// Plan Studio: planContinueNode
  ///
  /// In en, this message translates to:
  /// **'Continue node'**
  String get planContinueNode;

  /// Plan Studio: planTotalNotEstimated
  ///
  /// In en, this message translates to:
  /// **'Not estimated yet'**
  String get planTotalNotEstimated;

  /// Plan Studio: planBudgetExceeded
  ///
  /// In en, this message translates to:
  /// **'over budget'**
  String get planBudgetExceeded;

  /// Plan Studio: planBudgetCeiling
  ///
  /// In en, this message translates to:
  /// **'budget ≤ \${amount}'**
  String planBudgetCeiling(String amount);

  /// Plan Studio: planVersionsTitle
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get planVersionsTitle;

  /// Plan Studio: planNoRevisions
  ///
  /// In en, this message translates to:
  /// **'No revisions yet.'**
  String get planNoRevisions;

  /// Plan Studio: planDiffIdentical
  ///
  /// In en, this message translates to:
  /// **'No changes.'**
  String get planDiffIdentical;

  /// Plan Studio: planDiffGoalChanged
  ///
  /// In en, this message translates to:
  /// **'Goal changed'**
  String get planDiffGoalChanged;

  /// Plan Studio: planDiffBudgetChanged
  ///
  /// In en, this message translates to:
  /// **'Budget changed'**
  String get planDiffBudgetChanged;

  /// Plan Studio: planDiffHeader
  ///
  /// In en, this message translates to:
  /// **'Changes from v{fromRev} to v{toRev}'**
  String planDiffHeader(int fromRev, int toRev);

  /// Plan Studio: planDiffAdded
  ///
  /// In en, this message translates to:
  /// **'Added {node}'**
  String planDiffAdded(String node);

  /// Plan Studio: planDiffRemoved
  ///
  /// In en, this message translates to:
  /// **'Removed {node}'**
  String planDiffRemoved(String node);

  /// Plan Studio: planDiffChanged
  ///
  /// In en, this message translates to:
  /// **'Changed {node}: {fields}'**
  String planDiffChanged(String node, String fields);

  /// Plan Studio: planDiffEdgeAdded
  ///
  /// In en, this message translates to:
  /// **'Edge added: {edge}'**
  String planDiffEdgeAdded(String edge);

  /// Plan Studio: planDiffEdgeRemoved
  ///
  /// In en, this message translates to:
  /// **'Edge removed: {edge}'**
  String planDiffEdgeRemoved(String edge);

  /// Plan Studio: planDiffRoleAdded
  ///
  /// In en, this message translates to:
  /// **'Role added: {role}'**
  String planDiffRoleAdded(String role);

  /// Plan Studio: planDiffRoleRemoved
  ///
  /// In en, this message translates to:
  /// **'Role removed: {role}'**
  String planDiffRoleRemoved(String role);

  /// Plan Studio: planDiffRoleReassigned
  ///
  /// In en, this message translates to:
  /// **'Role reassigned: {role}'**
  String planDiffRoleReassigned(String role);

  /// Plan Studio: planReplanBanner
  ///
  /// In en, this message translates to:
  /// **'Plan replanned: you approved v{approved}, it is now v{current}. Review the diff before it continues.'**
  String planReplanBanner(int approved, int current);

  /// Plan Studio: planLiveActualCost
  ///
  /// In en, this message translates to:
  /// **'Actual cost: \${amount}'**
  String planLiveActualCost(String amount);

  /// Plan Studio: planPlaybookRun
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get planPlaybookRun;

  /// Plan Studio: planPlaybookDelete
  ///
  /// In en, this message translates to:
  /// **'Delete playbook'**
  String get planPlaybookDelete;

  /// Plan Studio: planPlaybookProposed
  ///
  /// In en, this message translates to:
  /// **'Plan proposed — approve it in Plan Studio.'**
  String get planPlaybookProposed;

  /// Plan Studio: planPlaybookAnchorTicket
  ///
  /// In en, this message translates to:
  /// **'Anchor ticket'**
  String get planPlaybookAnchorTicket;

  /// Plan Studio: planPlaybookPickTicket
  ///
  /// In en, this message translates to:
  /// **'Pick a ticket…'**
  String get planPlaybookPickTicket;

  /// Plan Studio: planPlaybookProposeRun
  ///
  /// In en, this message translates to:
  /// **'Propose plan'**
  String get planPlaybookProposeRun;

  /// Plan Studio: planPlaybookRepoHint
  ///
  /// In en, this message translates to:
  /// **'A repository id'**
  String get planPlaybookRepoHint;

  /// Plan Studio: planPlaybookAgentHint
  ///
  /// In en, this message translates to:
  /// **'An agent id'**
  String get planPlaybookAgentHint;

  /// Plan Studio: planPlaybookRunTitle
  ///
  /// In en, this message translates to:
  /// **'Run {name}'**
  String planPlaybookRunTitle(String name);

  /// Plan Studio: planPlaybookParamCount
  ///
  /// In en, this message translates to:
  /// **'{count} params'**
  String planPlaybookParamCount(int count);

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @cheatSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get cheatSheetTitle;

  /// No description provided for @cheatSheetGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get cheatSheetGlobal;

  /// No description provided for @cheatSheetThisScreen.
  ///
  /// In en, this message translates to:
  /// **'This screen'**
  String get cheatSheetThisScreen;

  /// No description provided for @cheatSheetReservedInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser reserved'**
  String get cheatSheetReservedInBrowser;

  /// No description provided for @keybindingCheatSheet.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keybindingCheatSheet;

  /// No description provided for @runPlaybookLabel.
  ///
  /// In en, this message translates to:
  /// **'Run playbook'**
  String get runPlaybookLabel;

  /// No description provided for @playbooksLabel.
  ///
  /// In en, this message translates to:
  /// **'Playbooks'**
  String get playbooksLabel;

  /// No description provided for @keybindingUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get keybindingUndo;

  /// No description provided for @keybindingRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get keybindingRedo;

  /// No description provided for @undone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get undone;

  /// No description provided for @redone.
  ///
  /// In en, this message translates to:
  /// **'Redone'**
  String get redone;

  /// No description provided for @undoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo'**
  String get undoFailed;

  /// No description provided for @undoLabelTicketEdit.
  ///
  /// In en, this message translates to:
  /// **'ticket edit'**
  String get undoLabelTicketEdit;

  /// No description provided for @undoLabelMessageEdit.
  ///
  /// In en, this message translates to:
  /// **'message edit'**
  String get undoLabelMessageEdit;

  /// No description provided for @undoLabelTodoStatus.
  ///
  /// In en, this message translates to:
  /// **'todo status'**
  String get undoLabelTodoStatus;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @inboxReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get inboxReview;

  /// No description provided for @inboxOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get inboxOpen;

  /// No description provided for @inboxAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get inboxAllCaughtUp;

  /// No description provided for @inboxGitHubDownTitle.
  ///
  /// In en, this message translates to:
  /// **'GitHub might be down'**
  String get inboxGitHubDownTitle;

  /// Inbox empty-state body shown when githubstatus.com reports trouble
  ///
  /// In en, this message translates to:
  /// **'GitHub is reporting {status}, so pull requests may be missing from this list rather than actually done.'**
  String inboxGitHubDownBody(String status);

  /// No description provided for @inboxGitHubIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm your GitHub account'**
  String get inboxGitHubIdentityTitle;

  /// No description provided for @inboxGitHubIdentityBody.
  ///
  /// In en, this message translates to:
  /// **'The inbox is sorted by who you are on GitHub. Until that loads it stays empty, even when pull requests are waiting for you.'**
  String get inboxGitHubIdentityBody;

  /// No description provided for @inboxSeverityBlocking.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get inboxSeverityBlocking;

  /// No description provided for @inboxSeverityWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get inboxSeverityWaiting;

  /// No description provided for @inboxSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get inboxSeverityInfo;

  /// No description provided for @inboxSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get inboxSyncFailed;

  /// No description provided for @inboxNeedsYourAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get inboxNeedsYourAttention;

  /// No description provided for @inboxSectionNeedsYourReview.
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get inboxSectionNeedsYourReview;

  /// No description provided for @inboxSectionReturnedToYou.
  ///
  /// In en, this message translates to:
  /// **'Returned to you'**
  String get inboxSectionReturnedToYou;

  /// No description provided for @inboxSectionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get inboxSectionApproved;

  /// No description provided for @inboxSectionDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get inboxSectionDrafts;

  /// No description provided for @inboxSectionWaitingForReviewers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reviewers'**
  String get inboxSectionWaitingForReviewers;

  /// No description provided for @inboxSectionMergingAndMerged.
  ///
  /// In en, this message translates to:
  /// **'Merging and recently merged'**
  String get inboxSectionMergingAndMerged;

  /// No description provided for @inboxSectionWaitingForAuthor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for author'**
  String get inboxSectionWaitingForAuthor;

  /// No description provided for @inboxColumnTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get inboxColumnTitle;

  /// No description provided for @inboxColumnChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get inboxColumnChanges;

  /// No description provided for @inboxColumnUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get inboxColumnUpdated;

  /// No description provided for @inboxReviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get inboxReviewApproved;

  /// No description provided for @inboxReviewChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get inboxReviewChangesRequested;

  /// Inbox hero subtitle, shown while the snapshot loads or when nothing is pending
  ///
  /// In en, this message translates to:
  /// **'Every pull request that involves you, sorted by what happens next.'**
  String get inboxHeroSubtitle;

  /// Inbox hero summary fragment: pull requests awaiting the operator's review
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pull request needs your review} other{{count} pull requests need your review}}'**
  String inboxHeroNeedsReview(int count);

  /// Inbox hero summary fragment: the operator's pull requests sent back by reviewers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 returned to you} other{{count} returned to you}}'**
  String inboxHeroReturnedToYou(int count);

  /// No description provided for @optimisticChangeReverted.
  ///
  /// In en, this message translates to:
  /// **'That change didn\'t save and was reverted'**
  String get optimisticChangeReverted;

  /// No description provided for @offlinePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get offlinePendingLabel;

  /// No description provided for @offlineSyncingLabel.
  ///
  /// In en, this message translates to:
  /// **'syncing'**
  String get offlineSyncingLabel;

  /// No description provided for @copyLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy link to this page'**
  String get copyLinkLabel;

  /// No description provided for @agentsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsSectionLabel;

  /// No description provided for @fleetWorkersTitle.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get fleetWorkersTitle;

  /// No description provided for @fleetWorkersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Machines available to run jobs'**
  String get fleetWorkersSubtitle;

  /// No description provided for @fleetJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get fleetJobsTitle;

  /// No description provided for @fleetJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work distributed across the fleet'**
  String get fleetJobsSubtitle;

  /// No description provided for @fleetNoWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers yet — a second machine running `cc_worker --server <url>` joins the fleet.'**
  String get fleetNoWorkers;

  /// No description provided for @fleetNoJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs.'**
  String get fleetNoJobs;

  /// No description provided for @fleetError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the fleet'**
  String get fleetError;

  /// No description provided for @fleetCores.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 core} other{{count} cores}}'**
  String fleetCores(int count);

  /// No description provided for @fleetHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'Heartbeat {time}'**
  String fleetHeartbeat(String time);

  /// No description provided for @fleetNoHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'No heartbeat yet'**
  String get fleetNoHeartbeat;

  /// No description provided for @fleetLastErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String fleetLastErrorLabel(String error);

  /// No description provided for @fleetDrain.
  ///
  /// In en, this message translates to:
  /// **'Drain'**
  String get fleetDrain;

  /// No description provided for @fleetResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get fleetResume;

  /// No description provided for @fleetRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get fleetRevoke;

  /// No description provided for @fleetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get fleetRemove;

  /// No description provided for @fleetRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke worker?'**
  String get fleetRevokeTitle;

  /// No description provided for @fleetRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}? Its session ends and any active jobs are reassigned.'**
  String fleetRevokeBody(String name);

  /// No description provided for @fleetRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove worker?'**
  String get fleetRemoveTitle;

  /// No description provided for @fleetRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the fleet? This deletes its record.'**
  String fleetRemoveBody(String name);

  /// No description provided for @fleetActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get fleetActionFailed;

  /// No description provided for @fleetJobUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get fleetJobUnassigned;

  /// No description provided for @fleetJobAttempts.
  ///
  /// In en, this message translates to:
  /// **'{attempts}/{max} attempts'**
  String fleetJobAttempts(int attempts, int max);

  /// No description provided for @fleetPlacementReasons.
  ///
  /// In en, this message translates to:
  /// **'Placement decisions'**
  String get fleetPlacementReasons;

  /// No description provided for @fleetNoPlacements.
  ///
  /// In en, this message translates to:
  /// **'No placement decisions yet.'**
  String get fleetNoPlacements;

  /// No description provided for @fleetStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get fleetStatusOnline;

  /// No description provided for @fleetStatusDraining.
  ///
  /// In en, this message translates to:
  /// **'Draining'**
  String get fleetStatusDraining;

  /// No description provided for @fleetStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get fleetStatusOffline;

  /// No description provided for @fleetStatusIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Incompatible'**
  String get fleetStatusIncompatible;

  /// No description provided for @fleetStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get fleetStatusRevoked;

  /// No description provided for @fleetJobStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get fleetJobStatusQueued;

  /// No description provided for @fleetJobStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get fleetJobStatusRunning;

  /// No description provided for @fleetJobStatusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get fleetJobStatusSucceeded;

  /// No description provided for @fleetJobStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get fleetJobStatusFailed;

  /// No description provided for @fleetJobStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get fleetJobStatusCancelled;

  /// No description provided for @evalsNoSuites.
  ///
  /// In en, this message translates to:
  /// **'No eval suites yet.'**
  String get evalsNoSuites;

  /// No description provided for @evalsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load evals'**
  String get evalsError;

  /// No description provided for @evalsStarterBadge.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get evalsStarterBadge;

  /// No description provided for @evalsDefaultBatch.
  ///
  /// In en, this message translates to:
  /// **'Default batch of {count}'**
  String evalsDefaultBatch(int count);

  /// No description provided for @evalsRecentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get evalsRecentRuns;

  /// No description provided for @evalsNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get evalsNoRuns;

  /// No description provided for @evalsPassRate.
  ///
  /// In en, this message translates to:
  /// **'Pass rate'**
  String get evalsPassRate;

  /// No description provided for @evalsBatchTimes.
  ///
  /// In en, this message translates to:
  /// **'× {count}'**
  String evalsBatchTimes(int count);

  /// No description provided for @evalsTriggeredBy.
  ///
  /// In en, this message translates to:
  /// **'by {who}'**
  String evalsTriggeredBy(String who);

  /// No description provided for @evalsRunFinished.
  ///
  /// In en, this message translates to:
  /// **'Eval finished — {rate} passed'**
  String evalsRunFinished(String rate);

  /// No description provided for @evalsRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t run the suite'**
  String get evalsRunFailed;

  /// No description provided for @evalsRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get evalsRun;

  /// No description provided for @evalsStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get evalsStatusQueued;

  /// No description provided for @evalsStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get evalsStatusRunning;

  /// No description provided for @evalsStatusPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get evalsStatusPassed;

  /// No description provided for @evalsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get evalsStatusFailed;

  /// No description provided for @bannerMeetingJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get bannerMeetingJoin;

  /// No description provided for @bannerMeetingRecordAndLink.
  ///
  /// In en, this message translates to:
  /// **'Record & link'**
  String get bannerMeetingRecordAndLink;

  /// No description provided for @bannerCalendarReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get bannerCalendarReconnect;

  /// No description provided for @bannerView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bannerView;

  /// Title of the soundscape control panel dialog
  ///
  /// In en, this message translates to:
  /// **'Soundscapes'**
  String get soundscapeTitle;

  /// Button/tooltip to start soundscape playback
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get soundscapePlay;

  /// Button/tooltip to pause soundscape playback
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get soundscapePause;

  /// Label above the soundscape mood picker
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get soundscapeMoodLabel;

  /// Soundscape mood: alert background ambience for working
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get soundscapeMoodFocus;

  /// Soundscape mood: warmer ambience for unwinding
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get soundscapeMoodRelax;

  /// Soundscape mood: low drones for winding down
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get soundscapeMoodSleep;

  /// Soundscape mood: buoyant melody with a soft pulse for when work feels heavy
  ///
  /// In en, this message translates to:
  /// **'Rise'**
  String get soundscapeMoodRise;

  /// Label above the soundscape master volume slider
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get soundscapeVolumeLabel;

  /// Label above the 2D soundscape tune pad
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get soundscapeTuneLabel;

  /// Tune pad left edge: calm/low-intensity end of the energy axis
  ///
  /// In en, this message translates to:
  /// **'Mellow'**
  String get soundscapeTuneMellow;

  /// Tune pad top edge: open/brilliant end of the brightness axis
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get soundscapeTuneBright;

  /// Tune pad right edge: dense/driving end of the energy axis
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get soundscapeTuneEnergetic;

  /// Tune pad bottom edge: reverberant/dreamy end of the brightness axis
  ///
  /// In en, this message translates to:
  /// **'Spacy'**
  String get soundscapeTuneSpacy;

  /// Hint under the tune pad explaining the double-tap reset gesture
  ///
  /// In en, this message translates to:
  /// **'Double-tap to reset'**
  String get soundscapeTuneResetHint;

  /// Label above the current soundscape scene summary
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get soundscapeSceneLabel;

  /// Placeholder shown while the current scene is still loading
  ///
  /// In en, this message translates to:
  /// **'Tuning the ambience…'**
  String get soundscapeSceneLoading;

  /// Outdoor temperature shown in the scene summary, in Celsius
  ///
  /// In en, this message translates to:
  /// **'{degrees}°C'**
  String soundscapeTemperature(int degrees);

  /// Label above the soundscape location controls
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get soundscapeLocationLabel;

  /// Shown when no weather location has been detected yet
  ///
  /// In en, this message translates to:
  /// **'Detecting location…'**
  String get soundscapeLocationDetecting;

  /// Note explaining that the soundscape weather location comes from this device
  ///
  /// In en, this message translates to:
  /// **'Location comes from this device.'**
  String get soundscapeLocationAutoNote;

  /// Button to force an immediate weather re-fetch
  ///
  /// In en, this message translates to:
  /// **'Refresh weather'**
  String get soundscapeRefreshWeather;

  /// Label for the switch that auto-starts a soundscape during focus mode
  ///
  /// In en, this message translates to:
  /// **'Start with focus mode'**
  String get soundscapeAutoStartLabel;

  /// Description under the auto-start-with-focus-mode switch
  ///
  /// In en, this message translates to:
  /// **'Play a soundscape automatically when you start a focus session.'**
  String get soundscapeAutoStartDescription;

  /// Tooltip on the mini-player button that closes the floating HUD and refocuses the main window
  ///
  /// In en, this message translates to:
  /// **'Return to app'**
  String get soundscapeReturnToApp;

  /// Tooltip on the title-bar button that opens the floating soundscape mini-player
  ///
  /// In en, this message translates to:
  /// **'Pop out player'**
  String get soundscapePopOut;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get saveFailed;

  /// No description provided for @commitAndPush.
  ///
  /// In en, this message translates to:
  /// **'Commit & push'**
  String get commitAndPush;

  /// No description provided for @commit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commit;

  /// No description provided for @commitAmend.
  ///
  /// In en, this message translates to:
  /// **'Commit (amend)'**
  String get commitAmend;

  /// No description provided for @commitAndSync.
  ///
  /// In en, this message translates to:
  /// **'Commit & sync'**
  String get commitAndSync;

  /// No description provided for @scmSyncChanges.
  ///
  /// In en, this message translates to:
  /// **'Sync changes'**
  String get scmSyncChanges;

  /// No description provided for @scmPublishBranch.
  ///
  /// In en, this message translates to:
  /// **'Publish branch'**
  String get scmPublishBranch;

  /// No description provided for @scmSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get scmSyncFailed;

  /// No description provided for @scmSyncDirty.
  ///
  /// In en, this message translates to:
  /// **'Commit or discard changes before syncing'**
  String get scmSyncDirty;

  /// No description provided for @scmSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get scmSynced;

  /// No description provided for @scmPushRefused.
  ///
  /// In en, this message translates to:
  /// **'Push was refused'**
  String get scmPushRefused;

  /// No description provided for @scmPulledPushRefused.
  ///
  /// In en, this message translates to:
  /// **'Pulled, but the push was refused'**
  String get scmPulledPushRefused;

  /// No description provided for @scmPushRefusedHint.
  ///
  /// In en, this message translates to:
  /// **'The remote or a hook rejected the update'**
  String get scmPushRefusedHint;

  /// No description provided for @scmSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select a branch to checkout'**
  String get scmSelectBranch;

  /// No description provided for @scmCreateBranch.
  ///
  /// In en, this message translates to:
  /// **'Create new branch…'**
  String get scmCreateBranch;

  /// No description provided for @scmCreateBranchFrom.
  ///
  /// In en, this message translates to:
  /// **'Create new branch from…'**
  String get scmCreateBranchFrom;

  /// No description provided for @scmCheckoutDetached.
  ///
  /// In en, this message translates to:
  /// **'Checkout detached…'**
  String get scmCheckoutDetached;

  /// No description provided for @scmBranchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get scmBranchName;

  /// No description provided for @scmCreateBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get scmCreateBranchTitle;

  /// No description provided for @scmFromRef.
  ///
  /// In en, this message translates to:
  /// **'From ⁨{ref}⁩'**
  String scmFromRef(String ref);

  /// No description provided for @scmCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t switch branches'**
  String get scmCheckoutFailed;

  /// No description provided for @scmCheckoutDirty.
  ///
  /// In en, this message translates to:
  /// **'Commit or discard changes before switching branches'**
  String get scmCheckoutDirty;

  /// No description provided for @scmSwitchedToBranch.
  ///
  /// In en, this message translates to:
  /// **'Switched to ⁨{branch}⁩'**
  String scmSwitchedToBranch(String branch);

  /// No description provided for @scmDetachedAt.
  ///
  /// In en, this message translates to:
  /// **'Detached at ⁨{ref}⁩'**
  String scmDetachedAt(String ref);

  /// No description provided for @scmDetachedHead.
  ///
  /// In en, this message translates to:
  /// **'Detached HEAD'**
  String get scmDetachedHead;

  /// No description provided for @scmNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No matching branches'**
  String get scmNoBranches;

  /// No description provided for @scmBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get scmBranches;

  /// No description provided for @scmRemoteBranches.
  ///
  /// In en, this message translates to:
  /// **'Remote branches'**
  String get scmRemoteBranches;

  /// No description provided for @scmTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get scmTags;

  /// No description provided for @scmPickStartPoint.
  ///
  /// In en, this message translates to:
  /// **'Select a start point'**
  String get scmPickStartPoint;

  /// No description provided for @scmSwitchBranch.
  ///
  /// In en, this message translates to:
  /// **'Switch branch'**
  String get scmSwitchBranch;

  /// No description provided for @scmPullConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Pull would conflict'**
  String get scmPullConflictTitle;

  /// No description provided for @scmPullConflictBody.
  ///
  /// In en, this message translates to:
  /// **'Pulling {count} commits onto ⁨{branch}⁩ would conflict with the work in this checkout.'**
  String scmPullConflictBody(int count, String branch);

  /// No description provided for @scmAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get scmAskAi;

  /// No description provided for @scmResolveConflictPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pull ⁨{branch}⁩ in ⁨{repo}⁩. It is {count} commits behind its upstream, and the pull conflicts with the local work. Resolve the conflicts and finish the pull.'**
  String scmResolveConflictPrompt(String branch, String repo, int count);

  /// No description provided for @commitMessageOnBranch.
  ///
  /// In en, this message translates to:
  /// **'Message ({shortcut} to commit on “{branch}”)'**
  String commitMessageOnBranch(String shortcut, String branch);

  /// No description provided for @committed.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get committed;

  /// No description provided for @commitAmended.
  ///
  /// In en, this message translates to:
  /// **'Commit amended'**
  String get commitAmended;

  /// No description provided for @commitFailed.
  ///
  /// In en, this message translates to:
  /// **'Commit failed'**
  String get commitFailed;

  /// No description provided for @moreCommitActions.
  ///
  /// In en, this message translates to:
  /// **'More commit actions'**
  String get moreCommitActions;

  /// No description provided for @sourceControl.
  ///
  /// In en, this message translates to:
  /// **'Source control'**
  String get sourceControl;

  /// No description provided for @fixFindingTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix: {location}'**
  String fixFindingTitle(String location);

  /// No description provided for @openInEditor.
  ///
  /// In en, this message translates to:
  /// **'Open in editor'**
  String get openInEditor;

  /// No description provided for @regexTesterTitle.
  ///
  /// In en, this message translates to:
  /// **'Test regular expression'**
  String get regexTesterTitle;

  /// No description provided for @regexTesterHint.
  ///
  /// In en, this message translates to:
  /// **'Type a sample'**
  String get regexTesterHint;

  /// No description provided for @regexMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get regexMatch;

  /// No description provided for @regexNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get regexNoMatch;

  /// No description provided for @regexInvalidPattern.
  ///
  /// In en, this message translates to:
  /// **'Invalid pattern'**
  String get regexInvalidPattern;

  /// No description provided for @symbolLookupNone.
  ///
  /// In en, this message translates to:
  /// **'No definition in the index or this pull request'**
  String get symbolLookupNone;

  /// No description provided for @symbolLookupInDiff.
  ///
  /// In en, this message translates to:
  /// **'Found in this pull request'**
  String get symbolLookupInDiff;

  /// No description provided for @symbolLookupFromBase.
  ///
  /// In en, this message translates to:
  /// **'From the base checkout — this PR\'s worktree isn\'t indexed yet'**
  String get symbolLookupFromBase;

  /// No description provided for @symbolImplementations.
  ///
  /// In en, this message translates to:
  /// **'Implementations'**
  String get symbolImplementations;

  /// No description provided for @symbolCallersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} callers'**
  String symbolCallersCount(int count);

  /// No description provided for @commitMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Commit message'**
  String get commitMessageHint;

  /// No description provided for @pushedToPr.
  ///
  /// In en, this message translates to:
  /// **'Pushed to the PR'**
  String get pushedToPr;

  /// No description provided for @pushFailed.
  ///
  /// In en, this message translates to:
  /// **'Push failed'**
  String get pushFailed;

  /// No description provided for @reviewFindings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get reviewFindings;

  /// No description provided for @treeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get treeLabel;

  /// No description provided for @toggleFileTree.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the file tree'**
  String get toggleFileTree;

  /// No description provided for @diffViewSettings.
  ///
  /// In en, this message translates to:
  /// **'Diff view settings'**
  String get diffViewSettings;

  /// No description provided for @splitViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitViewLabel;

  /// No description provided for @unifiedViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get unifiedViewLabel;

  /// No description provided for @wrapLines.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get wrapLines;

  /// No description provided for @shiftClickSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Shift-click to select a range'**
  String get shiftClickSelectRange;

  /// No description provided for @diffFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String diffFilesCount(int count);

  /// Changed-lines tag on a pull request, e.g. 320 LOC
  ///
  /// In en, this message translates to:
  /// **'{loc} LOC'**
  String prComplexityLoc(String loc);

  /// Tooltip on the PR size tag for a small PR.
  ///
  /// In en, this message translates to:
  /// **'Small PR — {files}, ~{minutes} min to review'**
  String prComplexityTooltipSmall(String files, int minutes);

  /// Tooltip on the PR size tag for a medium PR.
  ///
  /// In en, this message translates to:
  /// **'Medium PR — {files}, block ~{minutes} min to review'**
  String prComplexityTooltipMedium(String files, int minutes);

  /// Tooltip on the PR size tag for a large PR (past the ~400 LOC review-quality cliff).
  ///
  /// In en, this message translates to:
  /// **'Large PR — {files}, consider splitting before review'**
  String prComplexityTooltipLarge(String files);

  /// No description provided for @searchInFiles.
  ///
  /// In en, this message translates to:
  /// **'Search in files'**
  String get searchInFiles;

  /// No description provided for @showFileList.
  ///
  /// In en, this message translates to:
  /// **'Show file list'**
  String get showFileList;

  /// No description provided for @searchInFilesHintField.
  ///
  /// In en, this message translates to:
  /// **'Search in files…'**
  String get searchInFilesHintField;

  /// No description provided for @searchInFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Search across the pull request\'s files'**
  String get searchInFilesHint;

  /// No description provided for @searchInWholeRepo.
  ///
  /// In en, this message translates to:
  /// **'Search in the whole repo'**
  String get searchInWholeRepo;

  /// No description provided for @searchInThisPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Search in this pull request'**
  String get searchInThisPullRequest;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}} in {files, plural, =1{1 file} other{{files} files}}'**
  String searchResultsCount(int count, int files);

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Discard {count, plural, =1{1 file} other{{count} files}} to HEAD? This cannot be undone.'**
  String discardChangesMessage(int count);

  /// No description provided for @discardAll.
  ///
  /// In en, this message translates to:
  /// **'Discard all'**
  String get discardAll;

  /// No description provided for @discardFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to discard changes'**
  String get discardFailed;

  /// No description provided for @discardedFiles.
  ///
  /// In en, this message translates to:
  /// **'Discarded {count, plural, =1{1 file} other{{count} files}}'**
  String discardedFiles(int count);

  /// No description provided for @discardedWithSkipped.
  ///
  /// In en, this message translates to:
  /// **'Discarded {reverted, plural, =1{1 file} other{{reverted} files}}; {skipped} skipped (untracked)'**
  String discardedWithSkipped(int reverted, int skipped);

  /// No description provided for @prWorktreeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Workspace not ready'**
  String get prWorktreeUnavailable;

  /// No description provided for @prWorktreeUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Preparing the pull request\'s files failed. Reopen the pull request to try again.'**
  String get prWorktreeUnavailableHint;

  /// No description provided for @timestampRelativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get timestampRelativeLabel;

  /// No description provided for @timestampRawLabel.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestampRawLabel;

  /// No description provided for @copyTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Copy timestamp'**
  String get copyTimestamp;

  /// No description provided for @copiedTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Copied timestamp'**
  String get copiedTimestamp;

  /// Generic label for the auto-detected deployment-preview tab on a pull request when the site name is unknown
  ///
  /// In en, this message translates to:
  /// **'Preview deployment'**
  String get previewDeployment;

  /// Label for a per-site deployment-preview tab on a pull request
  ///
  /// In en, this message translates to:
  /// **'Preview: {site}'**
  String previewDeploymentTab(String site);

  /// No description provided for @askForReview.
  ///
  /// In en, this message translates to:
  /// **'Ask for review…'**
  String get askForReview;

  /// No description provided for @closePrsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close pull requests?'**
  String get closePrsConfirmTitle;

  /// No description provided for @closePrsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Close 1 pull request?} other{Close {count} pull requests?}}'**
  String closePrsConfirmBody(int count);

  /// No description provided for @closedCountPrs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Closed 1 pull request} other{Closed {count} pull requests}}'**
  String closedCountPrs(int count);

  /// No description provided for @assignedCountPrs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Assigned 1 pull request} other{Assigned {count} pull requests}}'**
  String assignedCountPrs(int count);

  /// No description provided for @requestedReviewCountPrs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Requested review on 1 pull request} other{Requested review on {count} pull requests}}'**
  String requestedReviewCountPrs(int count);

  /// No description provided for @bulkActionPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action failed} other{{count} actions failed}}'**
  String bulkActionPartialFailure(int count);

  /// Header label for a rendered mermaid diagram
  ///
  /// In en, this message translates to:
  /// **'Diagram'**
  String get diagram;

  /// Toggle showing the mermaid source of a diagram
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get diagramViewSource;

  /// Toggle hiding the mermaid source of a diagram
  ///
  /// In en, this message translates to:
  /// **'Hide source'**
  String get diagramHideSource;

  /// Caption when a mermaid diagram cannot be rendered
  ///
  /// In en, this message translates to:
  /// **'Diagram preview unavailable ({reason})'**
  String diagramPreviewUnavailable(String reason);

  /// Shown in the plan bubble when the plan document cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Plan unavailable'**
  String get planUnavailable;

  /// Number of steps in a submitted plan
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String planStepCount(int count);

  /// Button that approves a plan and starts the work
  ///
  /// In en, this message translates to:
  /// **'Approve and run'**
  String get planApproveAndRun;

  /// Plan status label: being authored
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get planStatusDraft;

  /// Plan status label: submitted, awaiting review
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planStatusProposed;

  /// Plan status label: approved and running
  ///
  /// In en, this message translates to:
  /// **'Plan approved'**
  String get planStatusApproved;

  /// Plan status label: rejected by the operator
  ///
  /// In en, this message translates to:
  /// **'Plan rejected'**
  String get planStatusRejected;

  /// Plan status label: replaced by a newer plan
  ///
  /// In en, this message translates to:
  /// **'Plan superseded'**
  String get planStatusSuperseded;

  /// Revision number badge on a plan card
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String planRevisionLabel(int revision);

  /// Section heading for the adapter enforcement matrix in Settings -> Adapters
  ///
  /// In en, this message translates to:
  /// **'What this adapter enforces'**
  String get adapterEnforcementTitle;

  /// Enforcement row: whether Control Center decides which tools exist
  ///
  /// In en, this message translates to:
  /// **'Control Center picks the tools'**
  String get enforcementFiltersToolSurface;

  /// Enforcement row: whether every tool call is gated pre-execution
  ///
  /// In en, this message translates to:
  /// **'Every call is gated before it runs'**
  String get enforcementInterceptsToolCalls;

  /// Enforcement row: whether the run's completion contract can be enforced
  ///
  /// In en, this message translates to:
  /// **'The run is held to its deliverable'**
  String get enforcementObservesCompletionContract;

  /// Enforcement row: whether the runner's built-in tools are visible to Control Center
  ///
  /// In en, this message translates to:
  /// **'The runner\'s own tools are visible'**
  String get enforcementNativeToolsInterceptable;

  /// Enforcement row: whether in-process tools are covered by a sandbox profile
  ///
  /// In en, this message translates to:
  /// **'In-process tools are sandboxed'**
  String get enforcementInProcessToolsSandboxed;

  /// Affirmative value for an enforcement row
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get enforcementYes;

  /// Negative value for an enforcement row
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get enforcementNo;

  /// Label above the list of enforcement caveats for an adapter
  ///
  /// In en, this message translates to:
  /// **'Caveats'**
  String get adapterEnforcementCaveats;

  /// Collapsed-accordion verdict when a read-only mode is structurally guaranteed on this transport
  ///
  /// In en, this message translates to:
  /// **'Modes enforced'**
  String get enforcementSummaryModesEnforced;

  /// Collapsed-accordion verdict when a read-only mode is not structurally guaranteed on this transport
  ///
  /// In en, this message translates to:
  /// **'Modes not enforced'**
  String get enforcementSummaryModesNotEnforced;

  /// Number of enforcement caveats shown on the collapsed accordion header
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 caveat} other{{count} caveats}}'**
  String enforcementCaveatCount(int count);

  /// Enforcement caveat: Control Center cannot filter the tool surface
  ///
  /// In en, this message translates to:
  /// **'Read-only modes are not structural: Control Center cannot remove this runner\'s own tools.'**
  String get caveatToolSurfaceNotFiltered;

  /// Enforcement caveat: no pre-execution gate on tool calls
  ///
  /// In en, this message translates to:
  /// **'No pre-execution gate: only MCP tool calls pass through Control Center.'**
  String get caveatToolCallsNotIntercepted;

  /// Enforcement caveat: the runner's native tools bypass Control Center
  ///
  /// In en, this message translates to:
  /// **'The runner\'s own file and shell tools never reach Control Center; the OS sandbox is the only floor under them.'**
  String get caveatNativeToolsBypassControlCenter;

  /// Enforcement caveat: in-process tools are not sandboxed
  ///
  /// In en, this message translates to:
  /// **'In-process file tools run outside the sandbox, so the tool surface is the only filesystem boundary.'**
  String get caveatInProcessToolsUnsandboxed;

  /// Enforcement caveat: the completion contract cannot be enforced
  ///
  /// In en, this message translates to:
  /// **'Control Center cannot nudge or fail a run that ends without producing its deliverable.'**
  String get caveatCompletionContractUnobservable;

  /// Badge on the mode selector when the adapter cannot enforce the selected mode
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get modeDegraded;

  /// Tooltip explaining that the selected mode is only sandbox-enforced on this adapter
  ///
  /// In en, this message translates to:
  /// **'{mode} mode on {adapter} relies on the sandbox only; the agent\'s own file tools are not intercepted.'**
  String modeDegradedTooltip(String mode, String adapter);

  /// Shown when an artifact cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Artifact unavailable'**
  String get artifactUnavailable;

  /// Revision count badge on an artifact card
  ///
  /// In en, this message translates to:
  /// **'{count} revisions'**
  String artifactRevisionLabel(int count);

  /// Expands a collapsed artifact
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get artifactShowMore;

  /// Collapses an expanded artifact
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get artifactShowLess;

  /// Copies an artifact as text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get artifactCopy;

  /// Toast after copying an artifact
  ///
  /// In en, this message translates to:
  /// **'Artifact copied'**
  String get artifactCopied;

  /// Side-panel tab listing a conversation's artifacts
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get artifactsTabLabel;

  /// Empty state title for the artifacts panel
  ///
  /// In en, this message translates to:
  /// **'No artifacts yet'**
  String get artifactsEmptyTitle;

  /// Empty state body for the artifacts panel
  ///
  /// In en, this message translates to:
  /// **'When an agent publishes a table, chart, or diagram here, it appears in this list.'**
  String get artifactsEmptyBody;

  /// Label for the artifact revision picker
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get artifactRevisionPickerLabel;

  /// Restores an older artifact revision as a new head
  ///
  /// In en, this message translates to:
  /// **'Restore this revision'**
  String get artifactRestoreRevision;

  /// Opens an artifact in its own editor tab
  ///
  /// In en, this message translates to:
  /// **'Open in tab'**
  String get artifactOpenInTab;

  /// Generic name for an artifact whose title is not loaded yet
  ///
  /// In en, this message translates to:
  /// **'Artifact'**
  String get artifactTitleFallback;

  /// No description provided for @providerGenerationLabel.
  ///
  /// In en, this message translates to:
  /// **'Generation defaults'**
  String get providerGenerationLabel;

  /// No description provided for @providerGenerationHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a field empty to use the endpoint\'s own default. Models publish their own output ceilings and sampling recipes; serving one at other values can degrade it.'**
  String get providerGenerationHint;

  /// No description provided for @providerMaxTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Max output tokens'**
  String get providerMaxTokensLabel;

  /// Button: register a model by hand on a provider
  ///
  /// In en, this message translates to:
  /// **'Add model'**
  String get addModel;

  /// Heading above a provider's model list
  ///
  /// In en, this message translates to:
  /// **'Model list'**
  String get modelListTitle;

  /// Rail group label: the built-in model providers
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get railProvidersGroup;

  /// Rail group label: user-added custom model providers
  ///
  /// In en, this message translates to:
  /// **'Custom providers'**
  String get railCustomProvidersGroup;

  /// Dialog title: edit a provider model's metadata
  ///
  /// In en, this message translates to:
  /// **'Edit model settings'**
  String get editModelSettings;

  /// Field label: the provider-native model identifier
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelIdLabel;

  /// Hint under the read-only model id field when editing
  ///
  /// In en, this message translates to:
  /// **'The id the endpoint serves; fixed once listed.'**
  String get modelIdImmutableHint;

  /// Field label: total context window in tokens
  ///
  /// In en, this message translates to:
  /// **'Context window'**
  String get contextWindowLabel;

  /// Field label: accepted input modalities
  ///
  /// In en, this message translates to:
  /// **'Input types'**
  String get inputTypesLabel;

  /// Field label: produced output modalities
  ///
  /// In en, this message translates to:
  /// **'Output types'**
  String get outputTypesLabel;

  /// Modality checkbox: text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get modalityText;

  /// Modality checkbox: image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get modalityImage;

  /// Modality checkbox: audio
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get modalityAudio;

  /// Modality checkbox: video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get modalityVideo;

  /// Modality checkbox: PDF documents
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get modalityPdf;

  /// Button: clear the stored model override and inherit endpoint/catalog metadata again
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get modelOverrideReset;

  /// Badge on a model row whose metadata was overridden by hand
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get modelOverrideEdited;

  /// Badge on a model row the user registered by hand
  ///
  /// In en, this message translates to:
  /// **'Added by hand'**
  String get manualModelBadge;

  /// Validation error: the model id field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a model id.'**
  String get modelIdRequired;

  /// Validation error: a token count field is not a positive whole number
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number of tokens.'**
  String get modelTokensInvalid;

  /// Tooltip: remove a hand-registered model
  ///
  /// In en, this message translates to:
  /// **'Remove model'**
  String get removeModelAction;

  /// Confirm dialog title for removing a hand-registered model
  ///
  /// In en, this message translates to:
  /// **'Remove {model}?'**
  String removeModelConfirmTitle(String model);

  /// Confirm dialog body for removing a hand-registered model
  ///
  /// In en, this message translates to:
  /// **'The model leaves the list and agents pinned to it stop working. The provider is unaffected.'**
  String get removeModelConfirmBody;

  /// Pane title: register a custom model provider
  ///
  /// In en, this message translates to:
  /// **'Add model provider'**
  String get addModelProviderTitle;

  /// Pane subtitle: register a custom model provider
  ///
  /// In en, this message translates to:
  /// **'Configure a custom API endpoint and its models.'**
  String get addModelProviderDescription;

  /// Empty state for a provider model list with no models
  ///
  /// In en, this message translates to:
  /// **'No models configured. Add a model to use it in chat.'**
  String get modelListEmptyHint;

  /// Footnote explaining models are fetched live and hand registration is optional
  ///
  /// In en, this message translates to:
  /// **'Models are fetched live once the endpoint answers. Add one by hand only if it cannot list its own.'**
  String get addProviderModelsHint;

  /// No description provided for @providerTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get providerTemperatureLabel;

  /// No description provided for @providerTopPLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-p'**
  String get providerTopPLabel;

  /// No description provided for @providerTopKLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-k'**
  String get providerTopKLabel;

  /// No description provided for @providerGenerationSaved.
  ///
  /// In en, this message translates to:
  /// **'Generation defaults saved'**
  String get providerGenerationSaved;

  /// No description provided for @providerGenerationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the values: max output tokens and top-k must be positive, temperature 0–2, top-p 0–1.'**
  String get providerGenerationInvalid;

  /// No description provided for @providerGenerationOverridden.
  ///
  /// In en, this message translates to:
  /// **'Overridden'**
  String get providerGenerationOverridden;

  /// No description provided for @branchNotPushed.
  ///
  /// In en, this message translates to:
  /// **'not pushed'**
  String get branchNotPushed;

  /// No description provided for @branchNotOnRemote.
  ///
  /// In en, this message translates to:
  /// **'“{branch}” only exists in this conversation'**
  String branchNotOnRemote(String branch);

  /// No description provided for @branchNotOnRemoteHint.
  ///
  /// In en, this message translates to:
  /// **'GitHub has never seen this branch, so a pull request cannot use it yet. Publishing pushes the commits already in the worktree — uncommitted changes are left alone.'**
  String get branchNotOnRemoteHint;

  /// No description provided for @publishBranch.
  ///
  /// In en, this message translates to:
  /// **'Publish branch'**
  String get publishBranch;

  /// No description provided for @branchPublished.
  ///
  /// In en, this message translates to:
  /// **'Published “{branch}” to origin'**
  String branchPublished(String branch);

  /// No description provided for @branchPublishedWithUncommitted.
  ///
  /// In en, this message translates to:
  /// **'Branch published. {count} uncommitted change(s) were not included.'**
  String branchPublishedWithUncommitted(int count);

  /// No description provided for @composePrLoadingBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading branches from GitHub…'**
  String get composePrLoadingBranches;

  /// No description provided for @composePrBranchesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load branches from GitHub. Type a branch name, or check the GitHub connection.'**
  String get composePrBranchesFailed;

  /// No description provided for @composePrSubtitleFromSpace.
  ///
  /// In en, this message translates to:
  /// **'From this conversation’s branch — publish it first if GitHub hasn’t seen it'**
  String get composePrSubtitleFromSpace;

  /// No description provided for @obsTabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get obsTabInsights;

  /// No description provided for @obsTabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get obsTabLive;

  /// No description provided for @obsTabQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get obsTabQuality;

  /// No description provided for @obsTabUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get obsTabUsage;

  /// No description provided for @obsUsageTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total tokens'**
  String get obsUsageTotalTokens;

  /// No description provided for @obsUsagePeakTokens.
  ///
  /// In en, this message translates to:
  /// **'Peak tokens'**
  String get obsUsagePeakTokens;

  /// No description provided for @obsUsageLongestSession.
  ///
  /// In en, this message translates to:
  /// **'Longest session'**
  String get obsUsageLongestSession;

  /// No description provided for @obsUsageCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get obsUsageCurrentStreak;

  /// No description provided for @obsUsageLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get obsUsageLongestStreak;

  /// No description provided for @obsUsageDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String obsUsageDayCount(int count);

  /// No description provided for @obsUsageTokenActivity.
  ///
  /// In en, this message translates to:
  /// **'Token activity'**
  String get obsUsageTokenActivity;

  /// No description provided for @obsUsageActivityModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Token activity mode'**
  String get obsUsageActivityModeLabel;

  /// No description provided for @obsUsageModeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get obsUsageModeDaily;

  /// No description provided for @obsUsageModeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get obsUsageModeWeekly;

  /// No description provided for @obsUsageModeCumulative.
  ///
  /// In en, this message translates to:
  /// **'Cumulative'**
  String get obsUsageModeCumulative;

  /// No description provided for @obsUsageTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get obsUsageTimeRange;

  /// No description provided for @obsUsageTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily token trend'**
  String get obsUsageTrendTitle;

  /// No description provided for @obsUsageModelUsage.
  ///
  /// In en, this message translates to:
  /// **'Model usage'**
  String get obsUsageModelUsage;

  /// No description provided for @obsUsageTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get obsUsageTokensLabel;

  /// No description provided for @obsUsageNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No token usage recorded yet'**
  String get obsUsageNoActivity;

  /// No description provided for @obsUsageOtherModels.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get obsUsageOtherModels;

  /// No description provided for @obsUsageCellReadout.
  ///
  /// In en, this message translates to:
  /// **'{date} · {tokens} tokens'**
  String obsUsageCellReadout(String date, String tokens);

  /// No description provided for @obsUsageActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'Token activity from {start} to {end}. {activeDays} active days. Busiest day {peak} tokens.'**
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  );

  /// No description provided for @obsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live agent control, cost attribution, quotas and quality signals'**
  String get obsScreenSubtitle;

  /// No description provided for @obsRangeLast24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get obsRangeLast24h;

  /// No description provided for @obsRangeLast7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get obsRangeLast7d;

  /// No description provided for @obsRangeLast30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get obsRangeLast30d;

  /// No description provided for @obsRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get obsRangeAll;

  /// No description provided for @obsAddFilter.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get obsAddFilter;

  /// No description provided for @obsFilterAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get obsFilterAgent;

  /// No description provided for @obsFilterModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get obsFilterModel;

  /// No description provided for @obsFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get obsFilterStatus;

  /// No description provided for @obsFilterRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get obsFilterRole;

  /// No description provided for @obsKpiTotalRuns.
  ///
  /// In en, this message translates to:
  /// **'Total runs'**
  String get obsKpiTotalRuns;

  /// No description provided for @obsKpiTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get obsKpiTotalCost;

  /// No description provided for @obsKpiErrorRate.
  ///
  /// In en, this message translates to:
  /// **'Error rate'**
  String get obsKpiErrorRate;

  /// No description provided for @obsKpiCacheRate.
  ///
  /// In en, this message translates to:
  /// **'Cache rate'**
  String get obsKpiCacheRate;

  /// No description provided for @obsKpiTokensPerSec.
  ///
  /// In en, this message translates to:
  /// **'Tokens / sec'**
  String get obsKpiTokensPerSec;

  /// No description provided for @obsKpiAvgLatency.
  ///
  /// In en, this message translates to:
  /// **'Avg latency'**
  String get obsKpiAvgLatency;

  /// No description provided for @obsKpiTtft.
  ///
  /// In en, this message translates to:
  /// **'Time to first token'**
  String get obsKpiTtft;

  /// No description provided for @obsDeltaVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs previous period'**
  String obsDeltaVsPrevious(String delta);

  /// No description provided for @obsChartActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get obsChartActivity;

  /// No description provided for @obsChartCost.
  ///
  /// In en, this message translates to:
  /// **'Cost over time'**
  String get obsChartCost;

  /// No description provided for @obsLegendRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get obsLegendRuns;

  /// No description provided for @obsLegendErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get obsLegendErrors;

  /// No description provided for @obsAgentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get obsAgentsTitle;

  /// No description provided for @obsShowAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} agents'**
  String obsShowAllAgents(int count);

  /// No description provided for @obsShowFewerAgents.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get obsShowFewerAgents;

  /// No description provided for @obsRunsTitle.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get obsRunsTitle;

  /// No description provided for @obsNoRunsInRange.
  ///
  /// In en, this message translates to:
  /// **'No runs in this range'**
  String get obsNoRunsInRange;

  /// No description provided for @obsColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get obsColTime;

  /// No description provided for @obsColAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get obsColAgent;

  /// No description provided for @obsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get obsColStatus;

  /// No description provided for @obsColModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get obsColModel;

  /// No description provided for @obsColDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get obsColDuration;

  /// No description provided for @obsColTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get obsColTokens;

  /// No description provided for @obsColCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get obsColCost;

  /// No description provided for @obsColErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get obsColErrors;

  /// No description provided for @obsColRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get obsColRuns;

  /// No description provided for @obsColAvgLatency.
  ///
  /// In en, this message translates to:
  /// **'Avg latency'**
  String get obsColAvgLatency;

  /// No description provided for @obsColLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get obsColLastActive;

  /// No description provided for @obsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get obsStatusPending;

  /// No description provided for @obsStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get obsStatusRunning;

  /// No description provided for @obsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get obsStatusCompleted;

  /// No description provided for @obsStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get obsStatusError;

  /// No description provided for @obsRosterLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the agent roster.'**
  String get obsRosterLoadError;

  /// No description provided for @obsRosterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agents yet'**
  String get obsRosterEmpty;

  /// No description provided for @obsRosterEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Dispatch an agent and it will appear here live — status, current tool, tokens, cost.'**
  String get obsRosterEmptyDescription;

  /// No description provided for @obsKillAgent.
  ///
  /// In en, this message translates to:
  /// **'Kill agent'**
  String get obsKillAgent;

  /// No description provided for @obsRosterTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'tok'**
  String get obsRosterTokensLabel;

  /// No description provided for @obsCostByRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost by role'**
  String get obsCostByRoleTitle;

  /// No description provided for @obsCostByRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this workspace spends, by agent role'**
  String get obsCostByRoleSubtitle;

  /// No description provided for @obsRoleMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get obsRoleMain;

  /// No description provided for @obsRoleSubagents.
  ///
  /// In en, this message translates to:
  /// **'Subagents'**
  String get obsRoleSubagents;

  /// No description provided for @obsRoleAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Advisor'**
  String get obsRoleAdvisor;

  /// No description provided for @obsRoleCaption.
  ///
  /// In en, this message translates to:
  /// **'Main: {main} · subagents: {sub} · advisor: {advisor}'**
  String obsRoleCaption(String main, String sub, String advisor);

  /// No description provided for @obsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get obsTotal;

  /// No description provided for @obsTokenModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Token model (5 axes)'**
  String get obsTokenModelTitle;

  /// No description provided for @obsTokenModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every token this workspace has spent, by axis'**
  String get obsTokenModelSubtitle;

  /// No description provided for @obsAxisInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get obsAxisInput;

  /// No description provided for @obsAxisOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get obsAxisOutput;

  /// No description provided for @obsAxisReasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get obsAxisReasoning;

  /// No description provided for @obsAxisCacheRead.
  ///
  /// In en, this message translates to:
  /// **'Cache read'**
  String get obsAxisCacheRead;

  /// No description provided for @obsAxisCacheWrite.
  ///
  /// In en, this message translates to:
  /// **'Cache write'**
  String get obsAxisCacheWrite;

  /// No description provided for @obsTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total tokens'**
  String get obsTotalTokens;

  /// No description provided for @obsCacheDiscountNote.
  ///
  /// In en, this message translates to:
  /// **'Cache-read tokens are billed at a discount, so they cost far less than the same volume of fresh input.'**
  String get obsCacheDiscountNote;

  /// No description provided for @obsByModelTitle.
  ///
  /// In en, this message translates to:
  /// **'By model'**
  String get obsByModelTitle;

  /// No description provided for @obsByModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Token and cost usage per model'**
  String get obsByModelSubtitle;

  /// No description provided for @obsNoModelUsage.
  ///
  /// In en, this message translates to:
  /// **'No model usage recorded yet.'**
  String get obsNoModelUsage;

  /// No description provided for @obsRunCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String obsRunCount(int count);

  /// No description provided for @obsPerRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Per-run'**
  String get obsPerRunTitle;

  /// No description provided for @obsPerRunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Typical token cost of a single run'**
  String get obsPerRunSubtitle;

  /// No description provided for @obsMedianRunTokens.
  ///
  /// In en, this message translates to:
  /// **'Median run tokens'**
  String get obsMedianRunTokens;

  /// No description provided for @obsMedianRunTokensSub.
  ///
  /// In en, this message translates to:
  /// **'Midpoint across all runs'**
  String get obsMedianRunTokensSub;

  /// No description provided for @obsRunsInWorkspace.
  ///
  /// In en, this message translates to:
  /// **'In this workspace'**
  String get obsRunsInWorkspace;

  /// No description provided for @obsCostShare.
  ///
  /// In en, this message translates to:
  /// **'Cost share'**
  String get obsCostShare;

  /// No description provided for @obsQuotaConfiguredLimits.
  ///
  /// In en, this message translates to:
  /// **'Configured limits'**
  String get obsQuotaConfiguredLimits;

  /// No description provided for @obsQuotaConfiguredLimitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage against the ceilings you set, worst status first.'**
  String get obsQuotaConfiguredLimitsSubtitle;

  /// No description provided for @obsQuotaAddLimit.
  ///
  /// In en, this message translates to:
  /// **'Add limit'**
  String get obsQuotaAddLimit;

  /// No description provided for @obsQuotaNoLimits.
  ///
  /// In en, this message translates to:
  /// **'No quota limits configured yet — add one to track usage against a ceiling.'**
  String get obsQuotaNoLimits;

  /// No description provided for @obsQuotaRemoveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} limit'**
  String obsQuotaRemoveSemantic(String title);

  /// No description provided for @obsQuotaResetDetail.
  ///
  /// In en, this message translates to:
  /// **'Resets in {duration} · {status}'**
  String obsQuotaResetDetail(String duration, String status);

  /// No description provided for @obsQuotaUsageWindows.
  ///
  /// In en, this message translates to:
  /// **'Usage windows'**
  String get obsQuotaUsageWindows;

  /// No description provided for @obsQuotaUsageWindowsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Observed usage across all providers, no ceiling applied.'**
  String get obsQuotaUsageWindowsSubtitle;

  /// No description provided for @obsQuotaNoUsage.
  ///
  /// In en, this message translates to:
  /// **'No usage recorded yet.'**
  String get obsQuotaNoUsage;

  /// No description provided for @obsQuotaTokensUsed.
  ///
  /// In en, this message translates to:
  /// **'Tokens used'**
  String get obsQuotaTokensUsed;

  /// No description provided for @obsQuotaRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get obsQuotaRequests;

  /// No description provided for @obsQuotaUnitTokens.
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get obsQuotaUnitTokens;

  /// No description provided for @obsQuotaUnitRequests.
  ///
  /// In en, this message translates to:
  /// **'requests'**
  String get obsQuotaUnitRequests;

  /// No description provided for @obsQuotaUnitCost.
  ///
  /// In en, this message translates to:
  /// **'cost'**
  String get obsQuotaUnitCost;

  /// No description provided for @obsQuotaAddLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Add quota limit'**
  String get obsQuotaAddLimitTitle;

  /// No description provided for @obsQuotaProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get obsQuotaProviderLabel;

  /// No description provided for @obsQuotaWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get obsQuotaWindowLabel;

  /// No description provided for @obsQuotaUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get obsQuotaUnitLabel;

  /// No description provided for @obsQuotaLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit ({unit})'**
  String obsQuotaLimitLabel(String unit);

  /// No description provided for @obsQuotaCentsHint.
  ///
  /// In en, this message translates to:
  /// **'In US cents (500 = \$5.00).'**
  String get obsQuotaCentsHint;

  /// No description provided for @obsQuotaStatusOk.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get obsQuotaStatusOk;

  /// No description provided for @obsQuotaStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get obsQuotaStatusWarning;

  /// No description provided for @obsQuotaStatusExhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get obsQuotaStatusExhausted;

  /// No description provided for @obsQuotaStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get obsQuotaStatusUnknown;

  /// No description provided for @obsGoalNoActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active goal'**
  String get obsGoalNoActiveTitle;

  /// No description provided for @obsGoalNoActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Set a goal to give the agents an objective and an optional token budget. As runs complete, the budget fills and the agents are nudged to wrap up once it is nearly spent.'**
  String get obsGoalNoActiveBody;

  /// No description provided for @obsGoalSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get obsGoalSetGoal;

  /// No description provided for @obsGoalTokenBudget.
  ///
  /// In en, this message translates to:
  /// **'Token budget'**
  String get obsGoalTokenBudget;

  /// No description provided for @obsGoalTokensLeft.
  ///
  /// In en, this message translates to:
  /// **'{tokens} left'**
  String obsGoalTokensLeft(String tokens);

  /// No description provided for @obsGoalTokensUsedNoBudget.
  ///
  /// In en, this message translates to:
  /// **'{tokens} (no budget set)'**
  String obsGoalTokensUsedNoBudget(String tokens);

  /// No description provided for @obsGoalTokensUsed.
  ///
  /// In en, this message translates to:
  /// **'Tokens used'**
  String get obsGoalTokensUsed;

  /// No description provided for @obsGoalElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get obsGoalElapsed;

  /// No description provided for @obsGoalWrapUp.
  ///
  /// In en, this message translates to:
  /// **'Wrap up'**
  String get obsGoalWrapUp;

  /// No description provided for @obsGoalClear.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get obsGoalClear;

  /// No description provided for @obsGoalFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get obsGoalFallbackTitle;

  /// No description provided for @obsGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Mode budget'**
  String get obsGoalSubtitle;

  /// No description provided for @obsGoalStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get obsGoalStatusActive;

  /// No description provided for @obsGoalStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get obsGoalStatusPaused;

  /// No description provided for @obsGoalStatusBudgetLimited.
  ///
  /// In en, this message translates to:
  /// **'Budget limited'**
  String get obsGoalStatusBudgetLimited;

  /// No description provided for @obsGoalStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get obsGoalStatusComplete;

  /// No description provided for @obsGoalStatusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get obsGoalStatusDropped;

  /// No description provided for @obsGoalObjectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get obsGoalObjectiveLabel;

  /// No description provided for @obsGoalBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Token budget (optional)'**
  String get obsGoalBudgetLabel;

  /// No description provided for @obsGoalSetAction.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get obsGoalSetAction;

  /// No description provided for @obsBenchmarkPassAt1.
  ///
  /// In en, this message translates to:
  /// **'pass@1'**
  String get obsBenchmarkPassAt1;

  /// No description provided for @obsBenchmarkSuccessPct.
  ///
  /// In en, this message translates to:
  /// **'Success %'**
  String get obsBenchmarkSuccessPct;

  /// No description provided for @obsBenchmarkPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get obsBenchmarkPassed;

  /// No description provided for @obsBenchmarkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get obsBenchmarkFailed;

  /// No description provided for @obsBenchmarkErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get obsBenchmarkErrors;

  /// No description provided for @obsBenchmarkSpend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get obsBenchmarkSpend;

  /// No description provided for @obsBenchmarkCostPerTask.
  ///
  /// In en, this message translates to:
  /// **'Cost / task'**
  String get obsBenchmarkCostPerTask;

  /// No description provided for @obsBenchmarkTrials.
  ///
  /// In en, this message translates to:
  /// **'Trials'**
  String get obsBenchmarkTrials;

  /// No description provided for @obsBenchmarkNoTrials.
  ///
  /// In en, this message translates to:
  /// **'No runs to score yet.'**
  String get obsBenchmarkNoTrials;

  /// No description provided for @obsBenchmarkAndMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{And 1 more} other{And {count} more}}'**
  String obsBenchmarkAndMore(int count);

  /// No description provided for @obsBenchmarkTrialPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get obsBenchmarkTrialPass;

  /// No description provided for @obsBenchmarkTrialFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get obsBenchmarkTrialFail;

  /// No description provided for @obsBenchmarkTrialError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get obsBenchmarkTrialError;

  /// No description provided for @obsBenchmarkTrialRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get obsBenchmarkTrialRunning;

  /// No description provided for @obsBenchmarkReward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get obsBenchmarkReward;

  /// No description provided for @obsBenchmarkReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get obsBenchmarkReport;

  /// No description provided for @obsBenchmarkCopyMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy markdown'**
  String get obsBenchmarkCopyMarkdown;

  /// No description provided for @obsBenchmarkCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard'**
  String get obsBenchmarkCopied;

  /// No description provided for @obsBehaviorCaption.
  ///
  /// In en, this message translates to:
  /// **'These are frustration signals parsed from your own messages — a read on conversation health, not a score for the agents. Computed locally; nothing leaves this device.'**
  String get obsBehaviorCaption;

  /// No description provided for @obsBehaviorMessagesAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Messages analyzed'**
  String get obsBehaviorMessagesAnalyzed;

  /// No description provided for @obsBehaviorTotalSignals.
  ///
  /// In en, this message translates to:
  /// **'Total signals'**
  String get obsBehaviorTotalSignals;

  /// No description provided for @obsBehaviorYelling.
  ///
  /// In en, this message translates to:
  /// **'Yelling'**
  String get obsBehaviorYelling;

  /// No description provided for @obsBehaviorProfanity.
  ///
  /// In en, this message translates to:
  /// **'Profanity'**
  String get obsBehaviorProfanity;

  /// No description provided for @obsBehaviorAnguish.
  ///
  /// In en, this message translates to:
  /// **'Anguish'**
  String get obsBehaviorAnguish;

  /// No description provided for @obsBehaviorNegation.
  ///
  /// In en, this message translates to:
  /// **'Negation'**
  String get obsBehaviorNegation;

  /// No description provided for @obsBehaviorRepetition.
  ///
  /// In en, this message translates to:
  /// **'Repetition'**
  String get obsBehaviorRepetition;

  /// No description provided for @obsBehaviorBlame.
  ///
  /// In en, this message translates to:
  /// **'Blame'**
  String get obsBehaviorBlame;

  /// No description provided for @obsBehaviorConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Most-frustrated conversations'**
  String get obsBehaviorConversationsTitle;

  /// No description provided for @obsBehaviorConversationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ranked by signal density across your messages.'**
  String get obsBehaviorConversationsSubtitle;

  /// No description provided for @obsBehaviorNoSignals.
  ///
  /// In en, this message translates to:
  /// **'No frustration signals detected — smooth sailing.'**
  String get obsBehaviorNoSignals;

  /// No description provided for @obsBehaviorMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages analyzed'**
  String obsBehaviorMessagesCount(String count);

  /// No description provided for @obsBehaviorSignalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} signals'**
  String obsBehaviorSignalsCount(String count);

  /// No description provided for @obsAgentStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get obsAgentStatusIdle;

  /// No description provided for @obsAgentStatusParked.
  ///
  /// In en, this message translates to:
  /// **'Parked'**
  String get obsAgentStatusParked;

  /// No description provided for @obsAgentStatusAborted.
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get obsAgentStatusAborted;

  /// No description provided for @obsAgentKindSub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get obsAgentKindSub;

  /// Empty state when a commit has no CI checks
  ///
  /// In en, this message translates to:
  /// **'No checks have run on this commit.'**
  String get noChecksOnCommit;

  /// Workflow summary while checks are running
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Running — 1 job} other{Running — {count} jobs}}'**
  String checksSummaryRunning(int count);

  /// Workflow summary when all checks passed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{All checks passed — 1 job} other{All checks passed — {count} jobs}}'**
  String checksSummarySuccess(int count);

  /// Workflow summary when checks completed neutrally
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Completed — 1 job} other{Completed — {count} jobs}}'**
  String checksSummaryNeutral(int count);

  /// Workflow summary when some checks failed
  ///
  /// In en, this message translates to:
  /// **'{failed} of {total, plural, =1{1 job} other{{total} jobs}} failed'**
  String checksSummaryFailure(int failed, int total);

  /// Job count label on a workflow graph node
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String graphJobsCount(int count);

  /// Title of a workflow graph node whose job expands into several matrix variations, labelled by its YAML job id
  ///
  /// In en, this message translates to:
  /// **'Matrix: {jobId}'**
  String matrixJobLabel(String jobId);

  /// Caption shown while a job is still running and logs are not yet published
  ///
  /// In en, this message translates to:
  /// **'Logs will appear here when the job finishes.'**
  String get jobLogsPending;

  /// Caption shown when logs cannot be fetched for a job
  ///
  /// In en, this message translates to:
  /// **'Logs aren\'t available for this job.'**
  String get jobLogsUnavailable;

  /// Caption shown when a step has no captured log section
  ///
  /// In en, this message translates to:
  /// **'No logs captured for this step.'**
  String get noLogsForStep;

  /// Caption shown when a job log was tail-truncated
  ///
  /// In en, this message translates to:
  /// **'Log truncated — showing the most recent output.'**
  String get jobLogsTruncated;

  /// Header of the full job log accordion item
  ///
  /// In en, this message translates to:
  /// **'Full log'**
  String get fullLog;

  /// Tooltip of the copy-logs button
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get copyLogs;

  /// Semantics label of the workflow graph resize grip
  ///
  /// In en, this message translates to:
  /// **'Drag to resize the graph'**
  String get resizeGraph;

  /// Workflow accordion subtitle when the run is in progress; {time} is a relative time like '2m ago'
  ///
  /// In en, this message translates to:
  /// **'Started {time}'**
  String workflowRunStartedAgo(String time);

  /// Workflow accordion subtitle when the run finished; {time} is a relative time like '5h ago'
  ///
  /// In en, this message translates to:
  /// **'Completed {time}'**
  String workflowRunCompletedAgo(String time);

  /// Title of the chat bridges settings section
  ///
  /// In en, this message translates to:
  /// **'Chat bridges'**
  String get chatBridgesTitle;

  /// Subtitle of a chat provider row when it is not connected
  ///
  /// In en, this message translates to:
  /// **'Mention the bot in {provider} to put an agent on something, or draft tickets with {command}.'**
  String chatProviderDescription(String provider, String command);

  /// Button that opens the connect dialog for a chat provider
  ///
  /// In en, this message translates to:
  /// **'Connect {provider}'**
  String chatConnectProvider(String provider);

  /// Button that closes the workspace's connection to a chat provider
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get chatDisconnectProvider;

  /// Title of a chat provider row when connected, naming the bot and the provider-side workspace
  ///
  /// In en, this message translates to:
  /// **'{botName} in {teamName}'**
  String chatConnectedTo(String botName, String teamName);

  /// Status tag when the chat transport is up
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get chatStateLive;

  /// Status tag while the chat transport is being established
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get chatStateConnecting;

  /// Status tag when the chat connection is failing
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get chatStateError;

  /// Status tag when no chat app is connected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get chatNotConnected;

  /// Caveat shown when the provider refused native response streaming
  ///
  /// In en, this message translates to:
  /// **'Live streaming is off for this {provider} app — replies arrive as one message.'**
  String chatStreamingUnavailable(String provider);

  /// Explains why the connect button is disabled for non-admins
  ///
  /// In en, this message translates to:
  /// **'Only an admin can connect {provider} for this workspace.'**
  String chatAdminOnly(String provider);

  /// Instruction at the top of the chat connect dialog
  ///
  /// In en, this message translates to:
  /// **'Create a {provider} app, then paste its credentials here. Control Center connects out to {provider}, so this server needs no public address.'**
  String chatConnectHint(String provider);

  /// Button that opens the provider's app console in a browser
  ///
  /// In en, this message translates to:
  /// **'Open {provider} console'**
  String chatOpenConsole(String provider);

  /// Button that opens the provider's setup documentation
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get chatOpenSetupGuide;

  /// Label of the bot token credential field
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get chatFieldBotToken;

  /// Label of the app-level (socket) token credential field
  ///
  /// In en, this message translates to:
  /// **'App-level token'**
  String get chatFieldAppToken;

  /// Label of the app-management credential field
  ///
  /// In en, this message translates to:
  /// **'App configuration token'**
  String get chatFieldConfigRefreshToken;

  /// Wraps a credential field label the provider does not require
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String chatFieldOptional(String label);

  /// Button that mints a one-time code to link the current user's chat account
  ///
  /// In en, this message translates to:
  /// **'Link my {provider} account'**
  String chatLinkMyAccount(String provider);

  /// Subtitle of the personal chat link row when the user is not linked yet
  ///
  /// In en, this message translates to:
  /// **'Link your {provider} account so messages you send there are attributed to you.'**
  String chatLinkMyAccountDescription(String provider);

  /// Subtitle of the personal chat link row once linked
  ///
  /// In en, this message translates to:
  /// **'Linked to {externalUserId}'**
  String chatLinkedAs(String externalUserId);

  /// Title of the dialog showing the one-time chat link code
  ///
  /// In en, this message translates to:
  /// **'Link your {provider} account'**
  String chatLinkCodeTitle(String provider);

  /// Instruction above the one-time code the member sends to the bot in a direct message
  ///
  /// In en, this message translates to:
  /// **'Send this code to the {provider} bot in a direct message. It works once and expires in 15 minutes.'**
  String chatLinkCodeInstruction(String provider);

  /// Shown in the link dialog once the member has redeemed the code in the chat app
  ///
  /// In en, this message translates to:
  /// **'Your {provider} account is now linked — messages you send there are attributed to you.'**
  String chatLinkCodeLinked(String provider);

  /// Title of the row that heads the chat link roster
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get chatLinkedAccounts;

  /// Subtitle of the chat link roster when it is empty
  ///
  /// In en, this message translates to:
  /// **'No one has linked their {provider} account yet.'**
  String chatNoLinkedAccounts(String provider);

  /// How many workspace members have linked their chat identity
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 linked account} other{{count} linked accounts}}'**
  String chatLinkedMemberCount(int count);

  /// Subtitle of a chat link that was established automatically by email
  ///
  /// In en, this message translates to:
  /// **'{externalUserId} · matched by email'**
  String chatLinkMethodEmail(String externalUserId);

  /// Subtitle of a chat link that was established with a one-time code
  ///
  /// In en, this message translates to:
  /// **'{externalUserId} · linked with a code'**
  String chatLinkMethodCode(String externalUserId);

  /// Button that removes a member's chat link
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get chatUnlink;

  /// Button that opens the dialog for renaming/reshaping the bot
  ///
  /// In en, this message translates to:
  /// **'Customize bot'**
  String get chatCustomizeBot;

  /// Subtitle of the customize-bot settings row
  ///
  /// In en, this message translates to:
  /// **'Rename the bot, change what it says about itself, or rename the slash command.'**
  String get chatCustomizeBotDescription;

  /// Explains why the bot cannot be edited from Control Center
  ///
  /// In en, this message translates to:
  /// **'Control Center needs an app configuration token to edit the bot. Reconnect and include one.'**
  String get chatCustomizeBotUnavailable;

  /// Title of the guided app creation dialog
  ///
  /// In en, this message translates to:
  /// **'Create the {provider} app'**
  String chatCreateAppTitle(String provider);

  /// Explains what the guided app creation does
  ///
  /// In en, this message translates to:
  /// **'Control Center can create the {provider} app for you, with the right permissions and events already set. You will finish in {provider}, then paste the credentials here.'**
  String chatCreateAppHint(String provider);

  /// Button that creates the provider-side app from Control Center
  ///
  /// In en, this message translates to:
  /// **'Create app'**
  String get chatCreateApp;

  /// Settings button offering the guided app creation
  ///
  /// In en, this message translates to:
  /// **'Create app for me'**
  String get chatCreateAppCta;

  /// Label of the app name field
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get chatAppNameLabel;

  /// Label of the bot display name field
  ///
  /// In en, this message translates to:
  /// **'Bot name (what members type after @)'**
  String get chatBotDisplayNameLabel;

  /// Label of the app description field
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get chatDescriptionLabel;

  /// Label of the agent description field
  ///
  /// In en, this message translates to:
  /// **'What the bot says it can do'**
  String get chatAgentDescriptionLabel;

  /// Label of the slash command field
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get chatCommandLabel;

  /// Toggle enabling the provider's direct-message experience
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get chatDirectMessages;

  /// Explains the requirements of the direct-message experience
  ///
  /// In en, this message translates to:
  /// **'Lets members chat with the bot in a DM. May need a paid {provider} plan.'**
  String chatDirectMessagesHint(String provider);

  /// Confirms the provider-side app was created
  ///
  /// In en, this message translates to:
  /// **'{provider} created the app {appId}.'**
  String chatAppCreated(String provider, String appId);

  /// Introduces the steps the provider has no API for
  ///
  /// In en, this message translates to:
  /// **'A few steps are left and only {provider} can do them:'**
  String chatRemainingSteps(String provider);

  /// Step: generate the app-level token
  ///
  /// In en, this message translates to:
  /// **'Generate an app-level token'**
  String get chatStepAppToken;

  /// Step: install the app to the provider-side workspace
  ///
  /// In en, this message translates to:
  /// **'Install the app'**
  String get chatStepInstall;

  /// Button opening the app's settings page
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get chatOpenAppSettings;

  /// Button moving on to pasting the credentials
  ///
  /// In en, this message translates to:
  /// **'Paste the credentials'**
  String get chatContinueToCredentials;

  /// Toast shown after the bot was updated on the provider
  ///
  /// In en, this message translates to:
  /// **'Bot updated in {provider}.'**
  String chatBotUpdated(String provider);

  /// Warns that changed permissions need a reinstall to take effect
  ///
  /// In en, this message translates to:
  /// **'{provider} changed the app\'s permissions. Reinstall the app for them to take effect.'**
  String chatScopesChangedReinstall(String provider);

  /// Button opening the provider's console to reinstall the app
  ///
  /// In en, this message translates to:
  /// **'Reinstall app'**
  String get chatReinstallApp;

  /// Explains that the bot icon can only be changed on the provider's side
  ///
  /// In en, this message translates to:
  /// **'The bot\'s icon can only be changed in {provider}\'s own app settings.'**
  String chatIconNotEditable(String provider);

  /// Points at the credential-free app-creation link
  ///
  /// In en, this message translates to:
  /// **'You can also create it in {provider} yourself — no token needed. The settings above travel with the link.'**
  String chatCreateAppLinkHint(String provider);

  /// Button opening the provider's console with the app configuration pre-filled
  ///
  /// In en, this message translates to:
  /// **'Create in {provider}'**
  String chatCreateAppWithLink(String provider);

  /// Explains what happens after the pre-filled creation link was opened
  ///
  /// In en, this message translates to:
  /// **'{provider} opened in your browser with this configuration pre-filled. Create the app there, then finish these steps and come back with the tokens.'**
  String chatSetupLinkBody(String provider);

  /// Warns that an app created by link cannot be customized from Control Center
  ///
  /// In en, this message translates to:
  /// **'{provider} does not report which app it created, so customizing the bot from here needs an app configuration token later.'**
  String chatSetupLinkNotManageable(String provider);

  /// Step: create the app from the pre-filled configuration
  ///
  /// In en, this message translates to:
  /// **'Create the app from the pre-filled configuration'**
  String get chatStepCreateApp;

  /// Hint for the create-the-app step
  ///
  /// In en, this message translates to:
  /// **'Pick a workspace in {provider} and confirm.'**
  String chatStepCreateAppHint(String provider);

  /// Hint for the app-level token step
  ///
  /// In en, this message translates to:
  /// **'Basic information → app-level tokens, with the connections:write scope.'**
  String get chatStepAppTokenHint;

  /// Hint for the install-the-app step
  ///
  /// In en, this message translates to:
  /// **'Install app → copy the bot user OAuth token.'**
  String get chatStepInstallHint;

  /// Section heading for the About card (build identity of the app and connected server)
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aboutAppVersion;

  /// No description provided for @aboutServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Connected server'**
  String get aboutServerVersion;

  /// No description provided for @aboutRpcCatalog.
  ///
  /// In en, this message translates to:
  /// **'RPC catalog'**
  String get aboutRpcCatalog;

  /// No description provided for @aboutServerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get aboutServerUnknown;

  /// No description provided for @serverStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'The bundled server is older than this app'**
  String get serverStaleTitle;

  /// Shown when the spawned local cc_server build is older than the app build
  ///
  /// In en, this message translates to:
  /// **'The running cc_server is {serverVersion} while this app is {appVersion}. Restart the app so it picks up the latest bundled server build; in development, rebuild it with `dart build cli` in apps/cc_server.'**
  String serverStaleBody(String serverVersion, String appVersion);

  /// No description provided for @updateCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckButton;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateUpToDate;

  /// No description provided for @updateDeferredBusy.
  ///
  /// In en, this message translates to:
  /// **'An update is ready but a meeting is recording — it will prompt after it ends.'**
  String get updateDeferredBusy;

  /// Status shown on platforms without an in-app updater (Linux) after the Check for updates button opens the releases page in a browser.
  ///
  /// In en, this message translates to:
  /// **'Opened the releases page in your browser.'**
  String get updateOpenedReleasesPage;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateCheckFailed;

  /// Shown next to the check-for-updates button when a new desktop version was found
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String updateAvailableVersion(String version);

  /// Web banner: a newer build is deployed at this origin
  ///
  /// In en, this message translates to:
  /// **'A new Control Center is available'**
  String get updateBannerTitle;

  /// No description provided for @updateBannerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get updateBannerRefresh;

  /// No description provided for @updateBlockedRecording.
  ///
  /// In en, this message translates to:
  /// **'Refreshing is paused while a meeting is recording — it will reload when it ends.'**
  String get updateBlockedRecording;

  /// Locale string for settingsScopeYou
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get settingsScopeYou;

  /// Locale string for settingsScopeWorkspace
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get settingsScopeWorkspace;

  /// Locale string for settingsScopeServer
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsScopeServer;

  /// Locale string for settingsProfile
  ///
  /// In en, this message translates to:
  /// **'Profile & identity'**
  String get settingsProfile;

  /// Locale string for settingsYourDevices
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get settingsYourDevices;

  /// Locale string for settingsWorkspaceGeneral
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsWorkspaceGeneral;

  /// Locale string for settingsServerConnection
  ///
  /// In en, this message translates to:
  /// **'Connection & status'**
  String get settingsServerConnection;

  /// Locale string for settingsModelProviders
  ///
  /// In en, this message translates to:
  /// **'Model providers'**
  String get settingsModelProviders;

  /// Locale string for settingsVoiceModels
  ///
  /// In en, this message translates to:
  /// **'Voice & meeting models'**
  String get settingsVoiceModels;

  /// Locale string for settingsDiagnostics
  ///
  /// In en, this message translates to:
  /// **'Diagnostics & privacy'**
  String get settingsDiagnostics;

  /// Locale string for settingsAbout
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Locale string for settingsProfileDescription
  ///
  /// In en, this message translates to:
  /// **'Your name, email and git identity in this workspace. Switching workspace switches this overlay; your username, sign-in and devices stay on your account in You → Profile.'**
  String get settingsProfileDescription;

  /// Locale string for settingsServerConnectionDescription
  ///
  /// In en, this message translates to:
  /// **'Which server this client talks to, and how this server is shared (mDNS, tunnels, relay).'**
  String get settingsServerConnectionDescription;

  /// Locale string for settingsAboutDescription
  ///
  /// In en, this message translates to:
  /// **'Build identity and updates.'**
  String get settingsAboutDescription;

  /// Locale string for settingsDiagnosticsDescription
  ///
  /// In en, this message translates to:
  /// **'Isolation, indexing, syncing, logging and crash reporting for this install.'**
  String get settingsDiagnosticsDescription;

  /// Locale string for settingsWorkspaceGeneralDescription
  ///
  /// In en, this message translates to:
  /// **'Policy and conventions shared by everyone in this workspace.'**
  String get settingsWorkspaceGeneralDescription;

  /// Locale string for settingsWorkspaceMeetingsDescription
  ///
  /// In en, this message translates to:
  /// **'Note templates and saved voices for meetings in this workspace.'**
  String get settingsWorkspaceMeetingsDescription;

  /// Locale string for settingsWorkspacePolicyLabel
  ///
  /// In en, this message translates to:
  /// **'Workspace policy'**
  String get settingsWorkspacePolicyLabel;

  /// Locale string for settingsWorkspacePolicyDescription
  ///
  /// In en, this message translates to:
  /// **'Applies to every member and every agent in this workspace.'**
  String get settingsWorkspacePolicyDescription;

  /// Locale string for settingsSecretGlobsLabel
  ///
  /// In en, this message translates to:
  /// **'Secret path exclusions'**
  String get settingsSecretGlobsLabel;

  /// Locale string for settingsSecretGlobsHelp
  ///
  /// In en, this message translates to:
  /// **'One glob per line. These paths are hidden from viewers and guests on code-bearing surfaces, on top of the built-in defaults.'**
  String get settingsSecretGlobsHelp;

  /// Locale string for settingsReviewConcurrencyLabel
  ///
  /// In en, this message translates to:
  /// **'Review fan-out'**
  String get settingsReviewConcurrencyLabel;

  /// Locale string for settingsReviewConcurrencyHelp
  ///
  /// In en, this message translates to:
  /// **'How many reviewers are dispatched in parallel when no explicit count is given.'**
  String get settingsReviewConcurrencyHelp;

  /// Locale string for settingsReviewLevelLabel
  ///
  /// In en, this message translates to:
  /// **'Review level'**
  String get settingsReviewLevelLabel;

  /// Locale string for settingsReviewLevelHelp
  ///
  /// In en, this message translates to:
  /// **'How deep the AI review goes, and how much of what it finds is reported up front. Nothing is discarded — a lighter level groups minor findings instead of dropping them.'**
  String get settingsReviewLevelHelp;

  /// Locale string for reviewLevelLight
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get reviewLevelLight;

  /// Locale string for reviewLevelBalanced
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get reviewLevelBalanced;

  /// Locale string for reviewLevelThorough
  ///
  /// In en, this message translates to:
  /// **'Thorough'**
  String get reviewLevelThorough;

  /// Locale string for reviewLevelLightHint
  ///
  /// In en, this message translates to:
  /// **'One reviewer. Only what materially matters is reported up front.'**
  String get reviewLevelLightHint;

  /// Locale string for reviewLevelBalancedHint
  ///
  /// In en, this message translates to:
  /// **'Three reviewers covering QA, architecture and implementation.'**
  String get reviewLevelBalancedHint;

  /// Locale string for reviewLevelThoroughHint
  ///
  /// In en, this message translates to:
  /// **'Adds security and performance specialists, and reports everything found.'**
  String get reviewLevelThoroughHint;

  /// Locale string for askAiReviewAtLevel
  ///
  /// In en, this message translates to:
  /// **'Review at a different level'**
  String get askAiReviewAtLevel;

  /// Locale string for reviewNitpicksGroup
  ///
  /// In en, this message translates to:
  /// **'Nitpicks ({count})'**
  String reviewNitpicksGroup(int count);

  /// Locale string for reviewFindingResolve
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get reviewFindingResolve;

  /// Locale string for reviewFindingResolveHint
  ///
  /// In en, this message translates to:
  /// **'Mark this finding as fixed. It stops counting against the review.'**
  String get reviewFindingResolveHint;

  /// Locale string for reviewFindingDismiss
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get reviewFindingDismiss;

  /// Locale string for reviewFindingDismissHint
  ///
  /// In en, this message translates to:
  /// **'Not a real problem. Reviewers stop flagging this pattern on future PRs.'**
  String get reviewFindingDismissHint;

  /// Locale string for reviewFindingReopen
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reviewFindingReopen;

  /// No description provided for @reviewFindingStatusUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'Finding status'**
  String get reviewFindingStatusUndoLabel;

  /// Locale string for reviewFindingDismissTitle
  ///
  /// In en, this message translates to:
  /// **'Dismiss this finding'**
  String get reviewFindingDismissTitle;

  /// Locale string for reviewFindingDismissReasonHint
  ///
  /// In en, this message translates to:
  /// **'Why does this not apply? Reviewers will read it.'**
  String get reviewFindingDismissReasonHint;

  /// Locale string for reviewFindingStatusFailed
  ///
  /// In en, this message translates to:
  /// **'Could not update the finding: {error}'**
  String reviewFindingStatusFailed(String error);

  /// Locale string for reviewStaleTitle
  ///
  /// In en, this message translates to:
  /// **'This review is out of date'**
  String get reviewStaleTitle;

  /// Locale string for reviewStaleBody
  ///
  /// In en, this message translates to:
  /// **'The pull request has moved on since this review ran. Findings may point at code that no longer exists.'**
  String get reviewStaleBody;

  /// Locale string for reviewStaleReviewedAt
  ///
  /// In en, this message translates to:
  /// **'Reviewed at {sha}'**
  String reviewStaleReviewedAt(String sha);

  /// Locale string for reviewStaleRerun
  ///
  /// In en, this message translates to:
  /// **'Review again'**
  String get reviewStaleRerun;

  /// Locale string for reviewStaleNotificationTitle
  ///
  /// In en, this message translates to:
  /// **'Review out of date on #{prNumber}'**
  String reviewStaleNotificationTitle(int prNumber);

  /// Locale string for reviewStaleNotificationBody
  ///
  /// In en, this message translates to:
  /// **'{title} has new commits since its last review.'**
  String reviewStaleNotificationBody(String title);

  /// Locale string for reviewCategorySecurity
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get reviewCategorySecurity;

  /// Locale string for reviewCategoryStability
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get reviewCategoryStability;

  /// Locale string for reviewCategoryDataIntegrity
  ///
  /// In en, this message translates to:
  /// **'Data integrity'**
  String get reviewCategoryDataIntegrity;

  /// Locale string for reviewCategoryCorrectness
  ///
  /// In en, this message translates to:
  /// **'Correctness'**
  String get reviewCategoryCorrectness;

  /// Locale string for reviewCategoryPerformance
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get reviewCategoryPerformance;

  /// Locale string for reviewCategoryMaintainability
  ///
  /// In en, this message translates to:
  /// **'Maintainability'**
  String get reviewCategoryMaintainability;

  /// Locale string for reviewEffortQuickWin
  ///
  /// In en, this message translates to:
  /// **'Quick win'**
  String get reviewEffortQuickWin;

  /// Locale string for reviewEffortModerate
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get reviewEffortModerate;

  /// Locale string for reviewEffortHeavyLift
  ///
  /// In en, this message translates to:
  /// **'Heavy lift'**
  String get reviewEffortHeavyLift;

  /// Locale string for reviewProposedFix
  ///
  /// In en, this message translates to:
  /// **'Proposed fix'**
  String get reviewProposedFix;

  /// Locale string for reviewAiAgentPrompt
  ///
  /// In en, this message translates to:
  /// **'Prompt for AI agents'**
  String get reviewAiAgentPrompt;

  /// Locale string for reviewCopyAiPrompt
  ///
  /// In en, this message translates to:
  /// **'Copy prompt'**
  String get reviewCopyAiPrompt;

  /// Locale string for settingsWorkspaceAdminOnly
  ///
  /// In en, this message translates to:
  /// **'Only workspace admins can change these.'**
  String get settingsWorkspaceAdminOnly;

  /// Locale string for chatMyAccountsTitle
  ///
  /// In en, this message translates to:
  /// **'Linked chat accounts'**
  String get chatMyAccountsTitle;

  /// Locale string for settingsServerSso
  ///
  /// In en, this message translates to:
  /// **'Single sign-on'**
  String get settingsServerSso;

  /// Locale string for settingsServerSsoDescription
  ///
  /// In en, this message translates to:
  /// **'SAML and OpenID Connect login with user provisioning'**
  String get settingsServerSsoDescription;

  /// Locale string for ssoProviderSaml
  ///
  /// In en, this message translates to:
  /// **'SAML'**
  String get ssoProviderSaml;

  /// Locale string for ssoProviderOidc
  ///
  /// In en, this message translates to:
  /// **'OpenID Connect'**
  String get ssoProviderOidc;

  /// Locale string for ssoEnabledDescription
  ///
  /// In en, this message translates to:
  /// **'Users can sign in with this provider'**
  String get ssoEnabledDescription;

  /// Locale string for ssoEnabledDescriptionOn
  ///
  /// In en, this message translates to:
  /// **'Sign-in is live for this provider'**
  String get ssoEnabledDescriptionOn;

  /// Locale string for ssoIdpMetadataLabel
  ///
  /// In en, this message translates to:
  /// **'IdP metadata XML'**
  String get ssoIdpMetadataLabel;

  /// Locale string for ssoIdpMetadataHint
  ///
  /// In en, this message translates to:
  /// **'paste the IdP\'s EntityDescriptor XML'**
  String get ssoIdpMetadataHint;

  /// Locale string for ssoEmailAttributeLabel
  ///
  /// In en, this message translates to:
  /// **'Email attribute'**
  String get ssoEmailAttributeLabel;

  /// Locale string for ssoDisplayNameAttributeLabel
  ///
  /// In en, this message translates to:
  /// **'Display name attribute'**
  String get ssoDisplayNameAttributeLabel;

  /// Locale string for ssoGroupsAttributeLabel
  ///
  /// In en, this message translates to:
  /// **'Groups attribute'**
  String get ssoGroupsAttributeLabel;

  /// Locale string for ssoIssuerLabel
  ///
  /// In en, this message translates to:
  /// **'Issuer URL'**
  String get ssoIssuerLabel;

  /// Locale string for ssoClientIdLabel
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get ssoClientIdLabel;

  /// Locale string for ssoGroupsClaimLabel
  ///
  /// In en, this message translates to:
  /// **'Groups claim'**
  String get ssoGroupsClaimLabel;

  /// Locale string for ssoAutoMemberLabel
  ///
  /// In en, this message translates to:
  /// **'Add users to every workspace on first login'**
  String get ssoAutoMemberLabel;

  /// Locale string for ssoAutoMemberDescription
  ///
  /// In en, this message translates to:
  /// **'Turn off to require an invite per workspace'**
  String get ssoAutoMemberDescription;

  /// Locale string for ssoAllowJitLabel
  ///
  /// In en, this message translates to:
  /// **'Provision unknown users on first login'**
  String get ssoAllowJitLabel;

  /// Locale string for ssoAllowJitDescription
  ///
  /// In en, this message translates to:
  /// **'Turn off to reject users without an existing account'**
  String get ssoAllowJitDescription;

  /// Locale string for ssoAllowIdpInitiatedLabel
  ///
  /// In en, this message translates to:
  /// **'Accept unsolicited (IdP-initiated) sign-in'**
  String get ssoAllowIdpInitiatedLabel;

  /// Locale string for ssoAllowIdpInitiatedDescription
  ///
  /// In en, this message translates to:
  /// **'Strictly for IdP portals that launch apps directly'**
  String get ssoAllowIdpInitiatedDescription;

  /// Locale string for ssoWantResponseSignedLabel
  ///
  /// In en, this message translates to:
  /// **'Require a signed response envelope'**
  String get ssoWantResponseSignedLabel;

  /// Locale string for ssoWantResponseSignedDescription
  ///
  /// In en, this message translates to:
  /// **'Assertion signatures are always required'**
  String get ssoWantResponseSignedDescription;

  /// Locale string for ssoTestConnectionButton
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get ssoTestConnectionButton;

  /// Locale string for ssoTestConnectionOk
  ///
  /// In en, this message translates to:
  /// **'Connection works:'**
  String get ssoTestConnectionOk;

  /// Locale string for ssoCopySpMetadata
  ///
  /// In en, this message translates to:
  /// **'Copy SP metadata'**
  String get ssoCopySpMetadata;

  /// Locale string for ssoCopySpMetadataDone
  ///
  /// In en, this message translates to:
  /// **'SP metadata copied to the clipboard'**
  String get ssoCopySpMetadataDone;

  /// Locale string for ssoSavedToast
  ///
  /// In en, this message translates to:
  /// **'Single sign-on settings saved'**
  String get ssoSavedToast;

  /// Locale string for ssoUnavailable
  ///
  /// In en, this message translates to:
  /// **'This server does not expose single sign-on settings. Update the server binary and try again.'**
  String get ssoUnavailable;

  /// Locale string for ssoScimCardTitle
  ///
  /// In en, this message translates to:
  /// **'User provisioning (SCIM)'**
  String get ssoScimCardTitle;

  /// Locale string for ssoScimDescription
  ///
  /// In en, this message translates to:
  /// **'Point your identity provider\'s SCIM connector at the endpoint below with a bearer token. Deprovisioning revokes sessions and workspace access within seconds. The server must be reachable by the IdP (tunnel or public URL).'**
  String get ssoScimDescription;

  /// Locale string for ssoScimEndpoint
  ///
  /// In en, this message translates to:
  /// **'SCIM endpoint'**
  String get ssoScimEndpoint;

  /// Locale string for ssoScimEndpointUnknownOrigin
  ///
  /// In en, this message translates to:
  /// **'Set the server\'s public URL or enable a tunnel first'**
  String get ssoScimEndpointUnknownOrigin;

  /// Locale string for ssoScimRegenerate
  ///
  /// In en, this message translates to:
  /// **'Regenerate token'**
  String get ssoScimRegenerate;

  /// Locale string for ssoScimRegenerateConfirm
  ///
  /// In en, this message translates to:
  /// **'Generate a new SCIM bearer token? The previous token stops working immediately.'**
  String get ssoScimRegenerateConfirm;

  /// Locale string for ssoScimTokenTitle
  ///
  /// In en, this message translates to:
  /// **'Bearer token'**
  String get ssoScimTokenTitle;

  /// Locale string for ssoScimTokenPresent
  ///
  /// In en, this message translates to:
  /// **'A token is configured'**
  String get ssoScimTokenPresent;

  /// Locale string for ssoScimTokenAbsent
  ///
  /// In en, this message translates to:
  /// **'No token yet — generate one to enable SCIM'**
  String get ssoScimTokenAbsent;

  /// Locale string for ssoScimTokenOnce
  ///
  /// In en, this message translates to:
  /// **'SCIM token (shown once)'**
  String get ssoScimTokenOnce;

  /// Locale string for ssoSignInWith
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String ssoSignInWith(String provider);

  /// Locale string for ssoProbeFailed
  ///
  /// In en, this message translates to:
  /// **'Could not reach that server for single sign-on'**
  String get ssoProbeFailed;

  /// Locale string for ssoOpensBrowser
  ///
  /// In en, this message translates to:
  /// **'Opens your browser to finish signing in'**
  String get ssoOpensBrowser;

  /// Locale string for ssoWaitingForBrowser
  ///
  /// In en, this message translates to:
  /// **'Waiting for your browser to finish signing in…'**
  String get ssoWaitingForBrowser;

  /// Locale string for ssoBrowserOpenFailed
  ///
  /// In en, this message translates to:
  /// **'Could not open your browser for single sign-on'**
  String get ssoBrowserOpenFailed;

  /// Locale string for ssoUseManualPairing
  ///
  /// In en, this message translates to:
  /// **'Sign in with an invite or pairing key instead'**
  String get ssoUseManualPairing;

  /// Locale string for ssoHideManualPairing
  ///
  /// In en, this message translates to:
  /// **'Hide manual pairing'**
  String get ssoHideManualPairing;

  /// Locale string for ssoClientIdHint
  ///
  /// In en, this message translates to:
  /// **'Public (PKCE) client — no secret needed'**
  String get ssoClientIdHint;

  /// Locale string for ssoClientSecretLabel
  ///
  /// In en, this message translates to:
  /// **'Client secret (optional)'**
  String get ssoClientSecretLabel;

  /// Locale string for ssoClientSecretHintUnset
  ///
  /// In en, this message translates to:
  /// **'Only needed for confidential IdP clients'**
  String get ssoClientSecretHintUnset;

  /// Locale string for ssoClientSecretHintSet
  ///
  /// In en, this message translates to:
  /// **'A secret is stored — leave blank to keep it'**
  String get ssoClientSecretHintSet;

  /// Locale string for ssoPairingToggle
  ///
  /// In en, this message translates to:
  /// **'Allow manual pairing (invite codes and pairing keys)'**
  String get ssoPairingToggle;

  /// Locale string for ssoPairingToggleDescription
  ///
  /// In en, this message translates to:
  /// **'Turn off to make joining single sign-on only — new devices arrive through SSO logins; existing devices keep working'**
  String get ssoPairingToggleDescription;

  /// Locale string for ssoPairConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Connect to server?'**
  String get ssoPairConfirmTitle;

  /// Locale string for ssoPairConfirmBody
  ///
  /// In en, this message translates to:
  /// **'A sign-in credential for {server} arrived, but no sign-in was started from this app. Connect to this server?'**
  String ssoPairConfirmBody(String server);

  /// Locale string for ssoPairConfirmConnect
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get ssoPairConfirmConnect;

  /// Locale string for ssoPairConfirmCancel
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ssoPairConfirmCancel;

  /// Locale string for forgeConnections
  ///
  /// In en, this message translates to:
  /// **'Code hosting'**
  String get forgeConnections;

  /// Locale string for connect
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Locale string for disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Locale string for notConnected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// Locale string for checkingConnection
  ///
  /// In en, this message translates to:
  /// **'Checking connection…'**
  String get checkingConnection;

  /// Locale string for forgeTokenTitle
  ///
  /// In en, this message translates to:
  /// **'{forge} token'**
  String forgeTokenTitle(String forge);

  /// Settings → You → Audio (nav label)
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// Settings → You → Audio page subtitle
  ///
  /// In en, this message translates to:
  /// **'Microphone, dictation, meeting detection and soundscape output.'**
  String get settingsAudioDescription;

  /// Section card: the microphone and soundscape output device pickers on You → Audio
  ///
  /// In en, this message translates to:
  /// **'Audio devices'**
  String get audioDevicesSection;

  /// Section card: dictation/meeting toggles on You → Voice input
  ///
  /// In en, this message translates to:
  /// **'Dictation and meetings'**
  String get voiceInputBehaviorSection;

  /// Row title: the app-wide audio output device picker
  ///
  /// In en, this message translates to:
  /// **'Output device'**
  String get audioOutputDeviceTitle;

  /// Subtitle when the system default output is selected
  ///
  /// In en, this message translates to:
  /// **'All app sound plays through the system default output.'**
  String get audioOutputDefaultHint;

  /// Subtitle when the selected output device has disappeared
  ///
  /// In en, this message translates to:
  /// **'The selected output device is no longer connected — the system default is used until you pick another.'**
  String get audioOutputGone;

  /// No description provided for @reviewHubIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Agents analyze the diff, map the change areas and reach a consensus verdict.'**
  String get reviewHubIntroBody;

  /// No description provided for @reviewHubAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'A review is already running for this pull request'**
  String get reviewHubAlreadyRunning;

  /// Strip: what moved since the previous review pass
  ///
  /// In en, this message translates to:
  /// **'Since last review: {resolved} resolved · {added} new · {open} still open'**
  String reviewHubDeltaSummary(int resolved, int added, int open);

  /// Which head the previous pass reviewed
  ///
  /// In en, this message translates to:
  /// **'Previously reviewed at {sha}'**
  String reviewHubDeltaPreviousSha(String sha);

  /// Action that hands every open finding to an agent to fix and push
  ///
  /// In en, this message translates to:
  /// **'Fix {count} findings'**
  String reviewArtifactFixAll(int count);

  /// Action that hands the ticked findings to an agent to fix and push
  ///
  /// In en, this message translates to:
  /// **'Fix {count} selected'**
  String reviewArtifactFixSelected(int count);

  /// Action that posts the ticked findings to the pull request as inline comments
  ///
  /// In en, this message translates to:
  /// **'Comment {count} selected'**
  String reviewArtifactCommentSelected(int count);

  /// Accessible label for the 'stay connected' checkbox
  ///
  /// In en, this message translates to:
  /// **'Stay connected on this device'**
  String get webConnectStayConnected;

  /// Explanation next to the 'stay connected' checkbox
  ///
  /// In en, this message translates to:
  /// **'Stay connected on this device (stores your key in this browser)'**
  String get webConnectStayConnectedDetail;

  /// Error shown when creating a workspace fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create workspace: {error}'**
  String failedToCreateWorkspace(String error);

  /// Commit byline: 'committed 3m ago'
  ///
  /// In en, this message translates to:
  /// **'committed {relative}'**
  String committedRelative(String relative);

  /// Hint for the multi-select that attaches agents to a skill
  ///
  /// In en, this message translates to:
  /// **'Select agents'**
  String get selectAgents;

  /// Count of selected agents
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent} other{{count} agents}}'**
  String agentCountPlural(int count);

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @untitledConversation.
  ///
  /// In en, this message translates to:
  /// **'Untitled conversation'**
  String get untitledConversation;

  /// No description provided for @conversationTitleOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — leave empty and the title model names it automatically'**
  String get conversationTitleOptionalHint;

  /// Shown when a side question, handoff, goal interview or title suggestion cannot run because the workspace's Content synthesizer agent is missing or its runner cannot run ("Content synthesizer" is the agent's literal name and stays untranslated)
  ///
  /// In en, this message translates to:
  /// **'The Content synthesizer agent is missing or has no working runner'**
  String get contentSynthesizerUnavailable;

  /// Composer placeholder and warning toast in a conversation with no agent in it: nothing runs until an agent is @mentioned
  ///
  /// In en, this message translates to:
  /// **'Mention an agent with @ to start this conversation'**
  String get conversationNeedsAgent;

  /// Button in the rename-conversation dialog that asks the short-task model to propose a title
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get conversationTitleGenerate;

  /// Rename-conversation dialog: generation needs a human message to name the conversation from
  ///
  /// In en, this message translates to:
  /// **'Send a message first. The title is generated from it.'**
  String get conversationTitleNoMessages;

  /// Rename-conversation dialog: the short-task model failed or returned nothing usable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate a title. Try again.'**
  String get conversationTitleGenerateFailed;

  /// No description provided for @startThread.
  ///
  /// In en, this message translates to:
  /// **'Start thread'**
  String get startThread;

  /// No description provided for @deleteSpaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this space? All messages will be lost.'**
  String get deleteSpaceConfirm;

  /// Editor tab header for a thread conversation, prefixed so it is never mistaken for the stream it was branched from
  ///
  /// In en, this message translates to:
  /// **'Thread: {title}'**
  String threadTabTitle(String title);

  /// Reply count on the thread indicator shown under the message a thread was started from
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String threadReplyCount(int count);

  /// Relative time of a thread's newest reply, shown beside the reply count
  ///
  /// In en, this message translates to:
  /// **'Last reply {time}'**
  String threadLastReply(String time);

  /// Primary action on a provider row when the server can run a browser sign-in
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String signInWithProvider(String provider);

  /// Re-runs a provider sign-in for an already connected account
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgain;

  /// Workspace shell warning title when no code host has a working sign-in for this workspace
  ///
  /// In en, this message translates to:
  /// **'Code hosting isn\'t connected in this workspace'**
  String get forgeSignInBannerTitle;

  /// Workspace shell warning body: why the code-hosting sign-in is missing and what is paused
  ///
  /// In en, this message translates to:
  /// **'A sign-in expired or was revoked, or this workspace uses its own GitHub App. Pull requests, reviews and repository sync are paused until you sign in.'**
  String get forgeSignInBannerBody;

  /// Button on the code-hosting warning that opens the workspace sign-in settings
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get forgeSignInBannerAction;

  /// Card title for the ticketing vendor and its credential
  ///
  /// In en, this message translates to:
  /// **'Ticketing'**
  String get ticketing;

  /// Subtitle for the ticketing provider selector
  ///
  /// In en, this message translates to:
  /// **'Where your tickets live. Local keeps them in Control Center.'**
  String get ticketingProviderHelp;

  /// Label for a ticketing vendor that is not implemented yet
  ///
  /// In en, this message translates to:
  /// **'{provider} (soon)'**
  String providerComingSoon(String provider);

  /// The built-in ticketing provider, stored by Control Center itself
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get ticketProviderLocal;

  /// Server settings card: how this server authenticates as itself
  ///
  /// In en, this message translates to:
  /// **'Provider apps'**
  String get providerApps;

  /// Subtitle of the provider apps card
  ///
  /// In en, this message translates to:
  /// **'Apps this server registered with each provider itself. People sign in through them, and background work like webhooks, polling and sync runs on them, never on a person\'s sign-in.'**
  String get providerAppsDescription;

  /// The GitHub App's numeric id
  ///
  /// In en, this message translates to:
  /// **'App id'**
  String get providerAppId;

  /// The GitHub App's RSA private key (.pem)
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get providerPrivateKey;

  /// OAuth client id used for user sign-in
  ///
  /// In en, this message translates to:
  /// **'Client id'**
  String get providerClientId;

  /// OAuth client secret used for user sign-in
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get providerClientSecret;

  /// The redirect URL to register with the provider
  ///
  /// In en, this message translates to:
  /// **'Callback URL'**
  String get providerCallbackUrl;

  /// Provider app status: both lanes configured
  ///
  /// In en, this message translates to:
  /// **'The server can act as itself, and people can sign in.'**
  String get providerAppFullyConfigured;

  /// Provider app status: server lane only
  ///
  /// In en, this message translates to:
  /// **'The server can act as itself. Add a client id and secret to let people sign in.'**
  String get providerAppServerOnly;

  /// Provider app status: sign-in lane only
  ///
  /// In en, this message translates to:
  /// **'People can sign in. Background work falls back to their credentials.'**
  String get providerAppSignInOnly;

  /// Result of testing a provider app
  ///
  /// In en, this message translates to:
  /// **'The credentials work. Installed on: {accounts}'**
  String providerAppInstalledOn(String accounts);

  /// Error when the app cannot launch a browser for a sign-in
  ///
  /// In en, this message translates to:
  /// **'No browser could be opened. Copy the link and finish the sign-in yourself.'**
  String get couldNotOpenBrowser;

  /// Title of the context-window usage flyout opened from the conversation header meter
  ///
  /// In en, this message translates to:
  /// **'Context usage'**
  String get contextUsage;

  /// Suffix after the percentage in the context flyout summary, as in "69% full"
  ///
  /// In en, this message translates to:
  /// **'full'**
  String get contextUsageFull;

  /// Unit after the token counts in the context flyout summary, as in "~177.3K / 256K tokens"
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get contextUsageTokens;

  /// Footer action in the context usage flyout that opens the full context explorer
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get contextSeeMore;

  /// Context breakdown category: base instructions and standing framing
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get contextSegmentSystemPrompt;

  /// Context breakdown category: AGENTS.md, the agent's instructions and persona
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get contextSegmentRules;

  /// Context breakdown category: the skills index
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get contextSegmentSkills;

  /// Context breakdown category: built-in tool schemas
  ///
  /// In en, this message translates to:
  /// **'Tool definitions'**
  String get contextSegmentToolDefinitions;

  /// Context breakdown category: bridged MCP and dynamic tools
  ///
  /// In en, this message translates to:
  /// **'MCP & dynamic tools'**
  String get contextSegmentMcpTools;

  /// Context breakdown category: tools listed by name only, whose schemas load on first use
  ///
  /// In en, this message translates to:
  /// **'Tools loaded on demand'**
  String get contextSegmentDeferredTools;

  /// Context breakdown category: the subagent profiles the task tool can spawn
  ///
  /// In en, this message translates to:
  /// **'Subagent definitions'**
  String get contextSegmentSubagents;

  /// Context breakdown category: the injected memory preamble
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get contextSegmentMemory;

  /// Context breakdown category: the live conversation messages
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get contextSegmentConversation;

  /// Context breakdown category: what an external runner such as Claude Code adds on its own (its system prompt, built-in tools, MCP schemas and the turn's tool calls)
  ///
  /// In en, this message translates to:
  /// **'Runner prompt, tools and turn work'**
  String get contextSegmentRunner;

  /// Caption under the context usage total when the number is the provider-reported size of the model's most recent call
  ///
  /// In en, this message translates to:
  /// **'Reported by the model\'s last call'**
  String get contextUsageMeasured;

  /// Caption under the context usage total when the number is an estimate because no run has reported its usage yet
  ///
  /// In en, this message translates to:
  /// **'Estimated until a run reports usage'**
  String get contextUsageEstimated;

  /// Title of the context explorer tab and dialog
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get contextExplorerTitle;

  /// Context explorer rail entry that selects the whole context
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get contextExplorerEverything;

  /// Empty state of the context explorer detail pane before anything is selected
  ///
  /// In en, this message translates to:
  /// **'Select a part to inspect its content'**
  String get contextExplorerSelectPart;

  /// Error-state title when the context breakdown could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Context breakdown unavailable'**
  String get contextExplorerUnavailable;

  /// Button that retries loading the context breakdown
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get contextRetry;

  /// Settings kit: marks a form field as not required
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get settingsFieldOptional;

  /// No description provided for @settingsFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter this list'**
  String get settingsFilterHint;

  /// No description provided for @settingsValueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get settingsValueNotAvailable;

  /// No description provided for @settingsNoEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get settingsNoEntriesYet;

  /// Badge on a collapsed settings section whose values differ from the defaults
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get settingsChangedBadge;

  /// No description provided for @ssoConnectionCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how people sign in to this server, then turn that connection on.'**
  String get ssoConnectionCardDescription;

  /// No description provided for @ssoUseSamlForSignIn.
  ///
  /// In en, this message translates to:
  /// **'Use SAML for sign-in'**
  String get ssoUseSamlForSignIn;

  /// No description provided for @ssoUseOidcForSignIn.
  ///
  /// In en, this message translates to:
  /// **'Use OpenID Connect for sign-in'**
  String get ssoUseOidcForSignIn;

  /// No description provided for @ssoSaveConnection.
  ///
  /// In en, this message translates to:
  /// **'Save connection'**
  String get ssoSaveConnection;

  /// No description provided for @ssoStateLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get ssoStateLive;

  /// No description provided for @ssoStateConfiguredOff.
  ///
  /// In en, this message translates to:
  /// **'Configured, off'**
  String get ssoStateConfiguredOff;

  /// No description provided for @ssoStateOnIncomplete.
  ///
  /// In en, this message translates to:
  /// **'On, incomplete'**
  String get ssoStateOnIncomplete;

  /// No description provided for @ssoStateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ssoStateActive;

  /// No description provided for @ssoStateAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get ssoStateAllowed;

  /// No description provided for @ssoStateNoToken.
  ///
  /// In en, this message translates to:
  /// **'No token'**
  String get ssoStateNoToken;

  /// No description provided for @ssoSummaryDirectorySync.
  ///
  /// In en, this message translates to:
  /// **'Directory sync'**
  String get ssoSummaryDirectorySync;

  /// No description provided for @ssoSummaryManualPairing.
  ///
  /// In en, this message translates to:
  /// **'Manual pairing'**
  String get ssoSummaryManualPairing;

  /// No description provided for @ssoNoMethodLiveNote.
  ///
  /// In en, this message translates to:
  /// **'No sign-in method is live. New devices join with an invite or pairing key until you configure a connection and turn it on.'**
  String get ssoNoMethodLiveNote;

  /// No description provided for @ssoMethodSamlBlurb.
  ///
  /// In en, this message translates to:
  /// **'For identity providers that speak SAML 2.0, such as Okta, Entra ID or Google Workspace.'**
  String get ssoMethodSamlBlurb;

  /// No description provided for @ssoMethodOidcBlurb.
  ///
  /// In en, this message translates to:
  /// **'For identity providers that speak OpenID Connect. Usually the simpler of the two to set up.'**
  String get ssoMethodOidcBlurb;

  /// No description provided for @ssoGroupIdentityProvider.
  ///
  /// In en, this message translates to:
  /// **'Identity provider'**
  String get ssoGroupIdentityProvider;

  /// No description provided for @ssoGroupIdentityProviderSamlDescription.
  ///
  /// In en, this message translates to:
  /// **'Where assertions come from, and how this server verifies them.'**
  String get ssoGroupIdentityProviderSamlDescription;

  /// No description provided for @ssoGroupIdentityProviderOidcDescription.
  ///
  /// In en, this message translates to:
  /// **'Which issuer this server trusts, and the client it authenticates as.'**
  String get ssoGroupIdentityProviderOidcDescription;

  /// No description provided for @ssoSpEntityIdShortLabel.
  ///
  /// In en, this message translates to:
  /// **'SP entity ID'**
  String get ssoSpEntityIdShortLabel;

  /// No description provided for @ssoSpEntityIdDescription.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to derive it from the server URL.'**
  String get ssoSpEntityIdDescription;

  /// No description provided for @ssoIssuerDescription.
  ///
  /// In en, this message translates to:
  /// **'The base URL that serves the provider’s discovery document.'**
  String get ssoIssuerDescription;

  /// No description provided for @ssoSecretStored.
  ///
  /// In en, this message translates to:
  /// **'Stored'**
  String get ssoSecretStored;

  /// No description provided for @ssoGroupHandoff.
  ///
  /// In en, this message translates to:
  /// **'What your identity provider needs'**
  String get ssoGroupHandoff;

  /// No description provided for @ssoGroupHandoffDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste these into the application you created at your provider.'**
  String get ssoGroupHandoffDescription;

  /// No description provided for @ssoOriginUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'This server does not know its public URL'**
  String get ssoOriginUnknownTitle;

  /// No description provided for @ssoOriginUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'The sign-in and callback URLs are built from it, so your provider cannot reach this server until one is set. Add a public URL or enable a tunnel under Server → Connection.'**
  String get ssoOriginUnknownBody;

  /// No description provided for @ssoAcsUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Assertion consumer service (ACS) URL'**
  String get ssoAcsUrlLabel;

  /// No description provided for @ssoAcsUrlDescription.
  ///
  /// In en, this message translates to:
  /// **'Where your provider posts the signed assertion.'**
  String get ssoAcsUrlDescription;

  /// No description provided for @ssoSpEntityIdResolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Service provider entity ID'**
  String get ssoSpEntityIdResolvedLabel;

  /// No description provided for @ssoMetadataUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'SP metadata URL'**
  String get ssoMetadataUrlLabel;

  /// No description provided for @ssoMetadataUrlDescription.
  ///
  /// In en, this message translates to:
  /// **'Providers that import metadata can fetch it from here instead.'**
  String get ssoMetadataUrlDescription;

  /// No description provided for @ssoRedirectUriLabel.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI'**
  String get ssoRedirectUriLabel;

  /// No description provided for @ssoRedirectUriDescription.
  ///
  /// In en, this message translates to:
  /// **'Add this to the allowed redirect URIs of your provider’s application.'**
  String get ssoRedirectUriDescription;

  /// No description provided for @ssoSignInUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-in URL'**
  String get ssoSignInUrlLabel;

  /// No description provided for @ssoSignInUrlDescription.
  ///
  /// In en, this message translates to:
  /// **'Send people here to start a single sign-on login.'**
  String get ssoSignInUrlDescription;

  /// No description provided for @ssoGroupAttributeMapping.
  ///
  /// In en, this message translates to:
  /// **'Attribute mapping'**
  String get ssoGroupAttributeMapping;

  /// No description provided for @ssoGroupAttributeMappingDescription.
  ///
  /// In en, this message translates to:
  /// **'Which claim carries each field. Keep the defaults unless your provider renames them.'**
  String get ssoGroupAttributeMappingDescription;

  /// No description provided for @ssoGroupAccess.
  ///
  /// In en, this message translates to:
  /// **'Access and roles'**
  String get ssoGroupAccess;

  /// No description provided for @ssoGroupAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'What someone who signs in successfully is allowed to do.'**
  String get ssoGroupAccessDescription;

  /// No description provided for @ssoDefaultRoleShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Default role'**
  String get ssoDefaultRoleShortLabel;

  /// No description provided for @ssoDefaultRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Given to anyone whose groups match no mapping below.'**
  String get ssoDefaultRoleDescription;

  /// No description provided for @ssoRoleMapShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Group to role mapping'**
  String get ssoRoleMapShortLabel;

  /// No description provided for @ssoRoleMapDescription.
  ///
  /// In en, this message translates to:
  /// **'The first matching group wins. Owner cannot be granted this way.'**
  String get ssoRoleMapDescription;

  /// No description provided for @ssoRoleMapGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Group name from your provider'**
  String get ssoRoleMapGroupHint;

  /// No description provided for @ssoRoleMapAdd.
  ///
  /// In en, this message translates to:
  /// **'Add mapping'**
  String get ssoRoleMapAdd;

  /// No description provided for @ssoRoleMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mappings — everyone gets the default role.'**
  String get ssoRoleMapEmpty;

  /// No description provided for @ssoAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Clock skew, IdP-initiated sign-in, signature policy'**
  String get ssoAdvancedSummary;

  /// No description provided for @ssoClockSkewShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Clock skew'**
  String get ssoClockSkewShortLabel;

  /// No description provided for @ssoClockSkewDescription.
  ///
  /// In en, this message translates to:
  /// **'Seconds of tolerance on assertion timestamps. 90 suits most providers.'**
  String get ssoClockSkewDescription;

  /// No description provided for @ssoScimGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate token'**
  String get ssoScimGenerate;

  /// No description provided for @ssoScimTokenOnceBody.
  ///
  /// In en, this message translates to:
  /// **'Copied to your clipboard. It is shown once and cannot be recovered, so paste it into your provider now.'**
  String get ssoScimTokenOnceBody;

  /// No description provided for @ssoPairingCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual pairing'**
  String get ssoPairingCardTitle;

  /// No description provided for @ssoPairingCardDescription.
  ///
  /// In en, this message translates to:
  /// **'The other way into this server: invite codes and pairing keys, for devices that do not go through single sign-on.'**
  String get ssoPairingCardDescription;

  /// Settings kit: how many rows are shown out of how many exist
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String settingsCountOfTotal(int count, int total);

  /// No description provided for @providersNoneConnectedNote.
  ///
  /// In en, this message translates to:
  /// **'No provider is connected, so the built-in agent runtime has nothing to run on. Add an API key or sign in to one below.'**
  String get providersNoneConnectedNote;

  /// No description provided for @providersFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter providers'**
  String get providersFilterHint;

  /// No description provided for @providersNoneMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter'**
  String get providersNoneMatch;

  /// No description provided for @providerDeniedHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Denied in this workspace'**
  String get providerDeniedHereTitle;

  /// No description provided for @providerDeniedHereBody.
  ///
  /// In en, this message translates to:
  /// **'Agents here cannot use this provider, even though it is connected. Other workspaces are unaffected.'**
  String get providerDeniedHereBody;

  /// No description provided for @providerNeedsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this provider'**
  String get providerNeedsSignIn;

  /// No description provided for @providerNeedsApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add an API key to use this provider'**
  String get providerNeedsApiKey;

  /// No description provided for @providerApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerApiKeyLabel;

  /// No description provided for @providerGenerationDefaults.
  ///
  /// In en, this message translates to:
  /// **'Provider defaults'**
  String get providerGenerationDefaults;

  /// No description provided for @providerNoModelsYet.
  ///
  /// In en, this message translates to:
  /// **'No models reported yet. Connect the provider, then sync.'**
  String get providerNoModelsYet;

  /// No description provided for @providerModelsFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter models'**
  String get providerModelsFilterHint;

  /// No description provided for @adaptersNoneReadyNote.
  ///
  /// In en, this message translates to:
  /// **'None of the catalogued runner CLIs were found on this machine. Install one, then refresh.'**
  String get adaptersNoneReadyNote;

  /// No description provided for @adaptersFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter runners'**
  String get adaptersFilterHint;

  /// No description provided for @adaptersLaunchGroup.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get adaptersLaunchGroup;

  /// No description provided for @adaptersLaunchGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'What this runner is given when an agent starts it. Set these ahead of installing the CLI if you like.'**
  String get adaptersLaunchGroupDescription;

  /// No description provided for @adaptersEnvNone.
  ///
  /// In en, this message translates to:
  /// **'None set'**
  String get adaptersEnvNone;

  /// Button label: how many environment variables are configured for an adapter
  ///
  /// In en, this message translates to:
  /// **'{count} set'**
  String adaptersEnvCount(int count);

  /// No description provided for @adapterArgumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Appended to the runner\'s command line on every launch.'**
  String get adapterArgumentsDescription;

  /// No description provided for @settingsStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get settingsStateFailed;

  /// No description provided for @providerAppsGroupServer.
  ///
  /// In en, this message translates to:
  /// **'Acting as the server'**
  String get providerAppsGroupServer;

  /// No description provided for @providerAppsGroupServerDescription.
  ///
  /// In en, this message translates to:
  /// **'Used by workspaces that follow this server\'s sign-in apps. A workspace on its own apps sets up its App under Workspace → Integrations.'**
  String get providerAppsGroupServerDescription;

  /// Settings group: how developers talk to the server on GitHub PRs
  ///
  /// In en, this message translates to:
  /// **'Pull request conversations'**
  String get providerAppsGroupPrConversations;

  /// Settings group description for the PR-conversations group
  ///
  /// In en, this message translates to:
  /// **'How developers can talk to this server on GitHub in workspaces that follow this server. A workspace on its own apps has its own bot under Workspace → Integrations. Works with no webhook or public URL — the server polls.'**
  String get providerAppsGroupPrConversationsDescription;

  /// The GitHub App bot account login, shown copyable in settings
  ///
  /// In en, this message translates to:
  /// **'Bot login'**
  String get providerAppBotLogin;

  /// Placeholder shown before the bot login has been probed
  ///
  /// In en, this message translates to:
  /// **'Test the connection to resolve the bot login.'**
  String get providerAppBotLoginEmpty;

  /// Field label for the how-to-mention-the-bot hint
  ///
  /// In en, this message translates to:
  /// **'Asking on GitHub'**
  String get providerAppAskOnGitHub;

  /// Hint explaining the mention/reply/label ways to invoke the bot
  ///
  /// In en, this message translates to:
  /// **'Mention the bot login above in a pull request comment — the [bot] suffix is optional — to request a review or ask a question, reply inside its review threads, or add the `ai-review` label to request a review.'**
  String get providerAppAskOnGitHubHint;

  /// No description provided for @providerAppsGroupSignIn.
  ///
  /// In en, this message translates to:
  /// **'Signing people in'**
  String get providerAppsGroupSignIn;

  /// No description provided for @providerAppsGroupSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Lets each member connect their own account and get a credential of their own.'**
  String get providerAppsGroupSignInDescription;

  /// No description provided for @providerAppCapActsAsServer.
  ///
  /// In en, this message translates to:
  /// **'Acts as the server'**
  String get providerAppCapActsAsServer;

  /// No description provided for @providerAppCapSignsIn.
  ///
  /// In en, this message translates to:
  /// **'Signs people in'**
  String get providerAppCapSignsIn;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @mcpBridgedToolsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get mcpBridgedToolsLabel;

  /// No description provided for @guardrailFamilyFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get guardrailFamilyFiles;

  /// No description provided for @guardrailFamilyGit.
  ///
  /// In en, this message translates to:
  /// **'Git and pull requests'**
  String get guardrailFamilyGit;

  /// No description provided for @guardrailFamilyMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine and network'**
  String get guardrailFamilyMachine;

  /// No description provided for @guardrailFamilyControl.
  ///
  /// In en, this message translates to:
  /// **'Secrets and workspace'**
  String get guardrailFamilyControl;

  /// No description provided for @guardrailScopeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Editing rules for'**
  String get guardrailScopeFieldLabel;

  /// No description provided for @guardrailScopeFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'A narrower scope wins over a wider one. Rules set here apply on top of what is inherited.'**
  String get guardrailScopeFieldDescription;

  /// No description provided for @guardrailSetHere.
  ///
  /// In en, this message translates to:
  /// **'Set here'**
  String get guardrailSetHere;

  /// No description provided for @guardrailClearAllHere.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get guardrailClearAllHere;

  /// Agent permissions settings: heading of the group that lists rules written for a shell command prefix (e.g. `git push`) rather than for an action type.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get guardrailFamilyCommands;

  /// Agent permissions settings: names a rule created when someone answered an agent's approval request with 'Approve for 8 hours'. Shown as the source badge of an action row and inside each listed approval.
  ///
  /// In en, this message translates to:
  /// **'Standing approval'**
  String get guardrailStandingApproval;

  /// Agent permissions settings: one listed standing approval or conditional rule that allows something. {what} is a phrase such as 'branches feature/**' or 'every action of this kind'.
  ///
  /// In en, this message translates to:
  /// **'Allowed for {what}'**
  String guardrailEntryAllow(String what);

  /// Agent permissions settings: one listed conditional rule that makes agents ask before acting. {what} is a phrase such as 'paths src/**'.
  ///
  /// In en, this message translates to:
  /// **'Ask first for {what}'**
  String guardrailEntryPrompt(String what);

  /// Agent permissions settings: one listed conditional rule that blocks something. {what} is a phrase such as 'branches main'.
  ///
  /// In en, this message translates to:
  /// **'Denied for {what}'**
  String guardrailEntryDeny(String what);

  /// Agent permissions settings: what a listed rule covers, inserted into 'Allowed for {what}'. {patterns} is a comma-separated list of git branch patterns, shown as typed.
  ///
  /// In en, this message translates to:
  /// **'branches {patterns}'**
  String guardrailCoversBranches(String patterns);

  /// Agent permissions settings: what a listed rule covers, inserted into 'Allowed for {what}'. {patterns} is a comma-separated list of file path patterns.
  ///
  /// In en, this message translates to:
  /// **'paths {patterns}'**
  String guardrailCoversPaths(String patterns);

  /// Agent permissions settings: what a listed rule covers, inserted into 'Allowed for {what}'. {patterns} is a comma-separated list of network host names.
  ///
  /// In en, this message translates to:
  /// **'hosts {patterns}'**
  String guardrailCoversHosts(String patterns);

  /// Agent permissions settings: what a listed rule covers, inserted into 'Allowed for {what}'. {patterns} is a comma-separated list of shell commands.
  ///
  /// In en, this message translates to:
  /// **'commands {patterns}'**
  String guardrailCoversCommands(String patterns);

  /// Agent permissions settings: what a listed rule covers, inserted into 'Allowed for {what}'. {names} is a comma-separated list of agent tool names, shown as typed.
  ///
  /// In en, this message translates to:
  /// **'tools {names}'**
  String guardrailCoversTools(String names);

  /// Agent permissions settings: what a command rule covers, inserted into 'Allowed for {what}'. {prefix} is the start of a shell command.
  ///
  /// In en, this message translates to:
  /// **'commands starting with {prefix}'**
  String guardrailCoversCommandPrefix(String prefix);

  /// Agent permissions settings: a limit on how many items (for example files) one action may touch, inserted into 'Allowed for {what}'. {count} is an already formatted number.
  ///
  /// In en, this message translates to:
  /// **'at most {count} at once'**
  String guardrailCoversMaxCount(String count);

  /// Agent permissions settings: a spending limit, in cents, for one action, inserted into 'Allowed for {what}'. {amount} is an already formatted number.
  ///
  /// In en, this message translates to:
  /// **'at most {amount} cents'**
  String guardrailCoversMaxCents(String amount);

  /// Agent permissions settings: inserted into 'Allowed for {what}' when a listed rule has no condition and covers the whole action type.
  ///
  /// In en, this message translates to:
  /// **'every action of this kind'**
  String get guardrailCoversEverything;

  /// Agent permissions settings: who gave a standing approval, shown after the rule as ' · by Alex'. Only shown when it was someone other than the viewer.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String guardrailEntryGivenBy(String name);

  /// Agent permissions settings: when a standing approval stops applying, shown after the rule as ' · ends 18:40'. {time} is a formatted time, with the date when it is not today.
  ///
  /// In en, this message translates to:
  /// **'ends {time}'**
  String guardrailEntryEnds(String time);

  /// Agent permissions settings: shown after a listed rule that has no end time, as ' · until revoked'.
  ///
  /// In en, this message translates to:
  /// **'until revoked'**
  String get guardrailEntryNoEnd;

  /// Agent permissions settings: screen reader label of the button that deletes one listed standing approval or rule. {entry} is the rule's description, e.g. 'Allowed for branches feature/**'.
  ///
  /// In en, this message translates to:
  /// **'Revoke: {entry}'**
  String guardrailRevokeEntry(String entry);

  /// Agent permissions settings: toast shown when deleting a standing approval or rule failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t revoke it. Try again.'**
  String get guardrailRevokeFailed;

  /// Agent permissions settings: shown after a listed standing approval, as ' · not in effect while denied', when the action it approves is set to Deny. A standing approval only spares a question; it never overrides a Deny.
  ///
  /// In en, this message translates to:
  /// **'not in effect while denied'**
  String get guardrailEntryInactive;

  /// Agent permissions settings: second line of an action row whose setting is 'Ask first' or 'Deny' while standing approvals listed under it still let some of these actions through.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Allowed in 1 case listed below} other{Allowed in {count} cases listed below}}'**
  String guardrailClassPartlyAllowed(int count);

  /// Agent permissions settings: note under the summary when a single space or agent is being edited and standing approvals given for the whole workspace also apply to it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 standing approval for the whole workspace also applies here.} other{{count} standing approvals for the whole workspace also apply here.}}'**
  String guardrailStandingFromWorkspace(int count);

  /// Agent permissions settings: note under the summary when the whole workspace is being edited and standing approvals exist that were given for one space or one agent only. 'Space' and 'Agent' are the scope toggle's labels.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 standing approval is set for a single space or agent. Pick Space or Agent above to see it.} other{{count} standing approvals are set for single spaces or agents. Pick Space or Agent above to see them.}}'**
  String guardrailStandingInNarrowerScopes(int count);

  /// No description provided for @sandboxingCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Sandboxing'**
  String get sandboxingCardLabel;

  /// No description provided for @sandboxingCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether agent work runs isolated from this host, and what an isolated agent can still reach.'**
  String get sandboxingCardDescription;

  /// No description provided for @sandboxBackendNoneActive.
  ///
  /// In en, this message translates to:
  /// **'Host, no isolation'**
  String get sandboxBackendNoneActive;

  /// No description provided for @sandboxSummaryHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get sandboxSummaryHost;

  /// No description provided for @sandboxGroupIsolation.
  ///
  /// In en, this message translates to:
  /// **'Isolation'**
  String get sandboxGroupIsolation;

  /// No description provided for @sandboxGroupIsolationDescription.
  ///
  /// In en, this message translates to:
  /// **'Where an agent\'s processes and file writes actually happen.'**
  String get sandboxGroupIsolationDescription;

  /// Settings → Sandboxing: heading of the group that points to agent permissions for what an agent may do.
  ///
  /// In en, this message translates to:
  /// **'What agents may do'**
  String get sandboxGroupAgentActions;

  /// Settings → Sandboxing: says push, pull requests and network access are decided by the allow/ask/deny action policy, not the sandbox.
  ///
  /// In en, this message translates to:
  /// **'Pushing, opening a pull request and accessing the network are each allowed, asked about or denied in agent permissions.'**
  String get sandboxGroupAgentActionsDescription;

  /// No description provided for @sandboxBackendFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Auto picks the strongest one this host supports. Pin one to stop it changing under you.'**
  String get sandboxBackendFieldDescription;

  /// No description provided for @sandboxSummaryInForce.
  ///
  /// In en, this message translates to:
  /// **'In force'**
  String get sandboxSummaryInForce;

  /// No description provided for @rigsInstallHintLabel.
  ///
  /// In en, this message translates to:
  /// **'How to install it'**
  String get rigsInstallHintLabel;

  /// No description provided for @rigsStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get rigsStarting;

  /// No description provided for @rigsResidentMemory.
  ///
  /// In en, this message translates to:
  /// **'Resident memory'**
  String get rigsResidentMemory;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedLabel;

  /// No description provided for @notInstalledLabel.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get notInstalledLabel;

  /// Badge on the SSO method picker when the other connection kind has uncommitted edits
  ///
  /// In en, this message translates to:
  /// **'{method} has unsaved changes'**
  String ssoOtherKindUnsaved(String method);

  /// Tooltip on the chevron that collapses an inline review comment thread to one line
  ///
  /// In en, this message translates to:
  /// **'Collapse comment'**
  String get collapseComment;

  /// Tooltip on the affordance that expands a collapsed inline review comment thread
  ///
  /// In en, this message translates to:
  /// **'Expand comment'**
  String get expandComment;

  /// Header of the mini-diff rendering a ```suggestion block inside a review comment
  ///
  /// In en, this message translates to:
  /// **'Suggested change'**
  String get suggestedChange;

  /// Preview text for a collapsed review comment whose body has no readable line
  ///
  /// In en, this message translates to:
  /// **'Empty comment'**
  String get emptyComment;

  /// Reply count on a collapsed inline review comment thread
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String repliesCountLabel(int count);

  /// Badge on an inline comment that is queued to be published with the next review submission
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// Toast shown when marking a review conversation resolved or reopened failed
  ///
  /// In en, this message translates to:
  /// **'Could not update the conversation: {error}'**
  String failedToResolveConversation(String error);

  /// Composer action that posts one inline comment immediately instead of queuing it for a review
  ///
  /// In en, this message translates to:
  /// **'Add single comment'**
  String get addSingleComment;

  /// Composer action that queues an inline comment for the review already in progress
  ///
  /// In en, this message translates to:
  /// **'Add to review'**
  String get addToReview;

  /// Composer action that queues the first inline comment, starting a batched review
  ///
  /// In en, this message translates to:
  /// **'Start a review'**
  String get startAReview;

  /// Diff comment composer destination: hand the comment to the pull request's agent chat instead of the forge
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get commentModeAgent;

  /// Diff comment composer destination: post the comment on its own, right away
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentModeComment;

  /// Diff comment composer destination: queue the comment for the batched review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get commentModeReview;

  /// Accessibility label for the segmented control choosing where a diff comment is sent (agent, single comment or review)
  ///
  /// In en, this message translates to:
  /// **'Comment destination'**
  String get commentDestination;

  /// Placeholder of the diff comment field while the composer sends to the agent
  ///
  /// In en, this message translates to:
  /// **'Send to agent…'**
  String get commentHintAgent;

  /// Placeholder of the diff comment field while the composer queues comments for the review
  ///
  /// In en, this message translates to:
  /// **'Add to review…'**
  String get commentHintReview;

  /// Warning toast when a comment-only review is submitted with no summary and no queued comments
  ///
  /// In en, this message translates to:
  /// **'Write a summary or queue an inline comment first'**
  String get reviewNeedsABody;

  /// Toast confirming a comment-only review was submitted
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// Title of the review submission panel
  ///
  /// In en, this message translates to:
  /// **'Finish your review'**
  String get finishYourReview;

  /// Review verdict button that submits feedback without approving or requesting changes
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentVerdict;

  /// Header of the queued-inline-comments list in the review submission panel
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending comment} other{{count} pending comments}}'**
  String pendingCommentsCount(int count);

  /// Trailing line when the queued-comment list is truncated
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String andNMore(int count);

  /// Hint shown in place of the reply box on an inline comment queued for the next review submission
  ///
  /// In en, this message translates to:
  /// **'This comment goes out when you submit your review.'**
  String get queuedCommentHint;

  /// Range label on a multi-line inline review comment card
  ///
  /// In en, this message translates to:
  /// **'Lines {start} to {end}'**
  String commentOnLinesRange(int start, int end);

  /// No description provided for @claudeAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Claude Code accounts'**
  String get claudeAccountsTitle;

  /// No description provided for @claudeAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Each account is a separate Claude Code login. Runs use the accounts attached below, in this order.'**
  String get claudeAccountsDescription;

  /// No description provided for @claudeAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get claudeAccountsEmpty;

  /// No description provided for @claudeAccountAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get claudeAccountAdd;

  /// No description provided for @claudeAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get claudeAccountSignIn;

  /// No description provided for @claudeAccountSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get claudeAccountSignInAgain;

  /// No description provided for @claudeAccountSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Run this in a terminal on the server. It opens a browser to finish the login, and writes the credential into this account\'s directory.'**
  String get claudeAccountSignInHint;

  /// No description provided for @claudeAccountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get claudeAccountSignedOut;

  /// No description provided for @claudeAccountExpired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in expired'**
  String get claudeAccountExpired;

  /// No description provided for @claudeAccountExpiredDetail.
  ///
  /// In en, this message translates to:
  /// **'The sign-in expired at {when}. Sign in again to use this account.'**
  String claudeAccountExpiredDetail(String when);

  /// No description provided for @claudeAccountMakeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make default'**
  String get claudeAccountMakeDefault;

  /// No description provided for @claudeAccountDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get claudeAccountDefault;

  /// No description provided for @claudeAccountRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}?'**
  String claudeAccountRemoveConfirm(String label);

  /// No description provided for @claudeAccountRemoveDetail.
  ///
  /// In en, this message translates to:
  /// **'This signs the account out and deletes its directory on the server. The login itself is not affected.'**
  String get claudeAccountRemoveDetail;

  /// No description provided for @claudeAccountStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not check this account: {error}'**
  String claudeAccountStatusUnknown(String error);

  /// No description provided for @claudeAccountUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String claudeAccountUsedPercent(String percent);

  /// No description provided for @accountPoolStrategy.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get accountPoolStrategy;

  /// No description provided for @accountPoolPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get accountPoolPinned;

  /// No description provided for @accountPoolRoundRobin.
  ///
  /// In en, this message translates to:
  /// **'Round robin'**
  String get accountPoolRoundRobin;

  /// No description provided for @accountPoolSerial.
  ///
  /// In en, this message translates to:
  /// **'One at a time'**
  String get accountPoolSerial;

  /// No description provided for @accountPoolPinnedHint.
  ///
  /// In en, this message translates to:
  /// **'Always start on the first account. The others stay as fallback if it fails.'**
  String get accountPoolPinnedHint;

  /// No description provided for @accountPoolRoundRobinHint.
  ///
  /// In en, this message translates to:
  /// **'Spread runs across the accounts, moving to the next one each dispatch.'**
  String get accountPoolRoundRobinHint;

  /// No description provided for @accountPoolSerialHint.
  ///
  /// In en, this message translates to:
  /// **'Drain the first account before touching the next.'**
  String get accountPoolSerialHint;

  /// No description provided for @accountPoolMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get accountPoolMoveUp;

  /// No description provided for @accountPoolMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get accountPoolMoveDown;

  /// No description provided for @accountPoolUsingAll.
  ///
  /// In en, this message translates to:
  /// **'Nothing attached yet — every account is used, in this order.'**
  String get accountPoolUsingAll;

  /// No description provided for @accountPoolInheriting.
  ///
  /// In en, this message translates to:
  /// **'Inheriting the workspace\'s accounts.'**
  String get accountPoolInheriting;

  /// No description provided for @accountPoolResetToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Reset to the workspace\'s accounts'**
  String get accountPoolResetToWorkspace;

  /// No description provided for @accountPoolCoolingOff.
  ///
  /// In en, this message translates to:
  /// **'out of quota until {when}'**
  String accountPoolCoolingOff(String when);

  /// No description provided for @accountPoolSignedOut.
  ///
  /// In en, this message translates to:
  /// **'signed out'**
  String get accountPoolSignedOut;

  /// No description provided for @accountPoolExpired.
  ///
  /// In en, this message translates to:
  /// **'sign-in expired'**
  String get accountPoolExpired;

  /// No description provided for @accountPoolLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the rotation: {error}'**
  String accountPoolLoadFailed(String error);

  /// No description provided for @providerSignedInAccount.
  ///
  /// In en, this message translates to:
  /// **'signed-in account'**
  String get providerSignedInAccount;

  /// No description provided for @agentAccountsTab.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get agentAccountsTab;

  /// No description provided for @agentClaudeAccountsNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Claude Code accounts'**
  String get agentClaudeAccountsNoticeTitle;

  /// No description provided for @agentClaudeAccountsNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This runner signs in as one of the {count} Claude Code accounts on this host. Pick which one, or rotate between them, in the Accounts tab.'**
  String agentClaudeAccountsNoticeBody(int count);

  /// No description provided for @agentAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Which accounts this agent\'s runs use. Each block starts out inheriting the workspace\'s choice.'**
  String get agentAccountsDescription;

  /// No description provided for @agentAccountsNothingToRotate.
  ///
  /// In en, this message translates to:
  /// **'Nothing to rotate — connect a second account or key first.'**
  String get agentAccountsNothingToRotate;

  /// Toast shown when replying to an inline review comment failed
  ///
  /// In en, this message translates to:
  /// **'Could not post the reply: {error}'**
  String failedToPostReply(String error);

  /// Line label on a single-line inline review conversation in the PR timeline
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String commentOnLine(int line);

  /// Tooltip on the action that jumps from a timeline conversation to its file in the Diff tab
  ///
  /// In en, this message translates to:
  /// **'View in diff'**
  String get viewInDiff;

  /// No description provided for @subscriptionUsagePreviousAccount.
  ///
  /// In en, this message translates to:
  /// **'Previous account'**
  String get subscriptionUsagePreviousAccount;

  /// No description provided for @subscriptionUsageNextAccount.
  ///
  /// In en, this message translates to:
  /// **'Next account'**
  String get subscriptionUsageNextAccount;

  /// Header on a timeline card showing a reply posted into a conversation the review did not start; follows back to it
  ///
  /// In en, this message translates to:
  /// **'In reply to {path}'**
  String inReplyTo(String path);

  /// No description provided for @subscriptionUsageNoneReported.
  ///
  /// In en, this message translates to:
  /// **'No usage reported for this account.'**
  String get subscriptionUsageNoneReported;

  /// No description provided for @subscriptionUsageCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get subscriptionUsageCredits;

  /// Badge on a deterministic (non-agent) finding
  ///
  /// In en, this message translates to:
  /// **'Static rule'**
  String get reviewHubStaticRule;

  /// No description provided for @reviewHubStarted.
  ///
  /// In en, this message translates to:
  /// **'Review started'**
  String get reviewHubStarted;

  /// Explains a deterministic finding
  ///
  /// In en, this message translates to:
  /// **'Found by a deterministic rule ({rule}) on a line this pull request adds — not by a reviewer agent.'**
  String reviewHubStaticRuleTooltip(String rule);

  /// Title of the PR review artifact tab
  ///
  /// In en, this message translates to:
  /// **'PR review'**
  String get prReviewArtifactTab;

  /// Status line while the review pipeline is running
  ///
  /// In en, this message translates to:
  /// **'Reviewing this pull request…'**
  String get prReviewRunning;

  /// Title on the review tab between pressing Ask AI and the pipeline run appearing
  ///
  /// In en, this message translates to:
  /// **'Starting review…'**
  String get prReviewStarting;

  /// Body under prReviewStarting explaining what the wait is
  ///
  /// In en, this message translates to:
  /// **'Preparing this pull request\'s worktree. The reviewers start as soon as it is ready.'**
  String get prReviewStartingBody;

  /// Shown when the review pipeline run failed with no message
  ///
  /// In en, this message translates to:
  /// **'Review failed.'**
  String get prReviewFailed;

  /// Status line while a newer review runs over a published one
  ///
  /// In en, this message translates to:
  /// **'Re-reviewing…'**
  String get prReviewRerunning;

  /// Shown in the review actions bar when nothing is open
  ///
  /// In en, this message translates to:
  /// **'No open findings'**
  String get prReviewNoOpenFindings;

  /// Count of still-open findings in the review actions bar
  ///
  /// In en, this message translates to:
  /// **'{count} open findings'**
  String prReviewOpenFindings(int count);

  /// No description provided for @subscriptionUsageSpend.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String subscriptionUsageSpend(String used, String limit);

  /// Result of posting a review's findings to GitHub as inline comments
  ///
  /// In en, this message translates to:
  /// **'Posted {posted} comment(s) as the bot. {skipped} skipped (no file anchor), {failed} failed.'**
  String reviewCommentsPosted(int posted, int skipped, int failed);

  /// Warning shown when review findings are anchored to files the pull request does not change
  ///
  /// In en, this message translates to:
  /// **'{count} finding(s) target code this pull request does not change ({files}). GitHub only accepts inline comments on the diff.'**
  String reviewFindingsOutOfDiff(int count, String files);

  /// Rail row that shows the review's consolidated report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reviewRailReport;

  /// Empty state title for the review findings list
  ///
  /// In en, this message translates to:
  /// **'No review findings yet'**
  String get reviewNoFindingsTitle;

  /// Empty state hint for the review findings list
  ///
  /// In en, this message translates to:
  /// **'Findings appear here as agents post them.'**
  String get reviewNoFindingsHint;

  /// Reveals the dismissed findings hidden at the end of the list
  ///
  /// In en, this message translates to:
  /// **'Show {count} dismissed'**
  String reviewShowDismissed(int count);

  /// Hides the dismissed findings again
  ///
  /// In en, this message translates to:
  /// **'Hide {count} dismissed'**
  String reviewHideDismissed(int count);

  /// Header of the panel listing findings two reviewers disagreed on
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reviewer disagreement detected} other{{count} reviewer disagreements detected}}'**
  String reviewDisagreementsDetected(int count);

  /// Rail filter group for the finding kind
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get reviewFilterKind;

  /// Rail filter group for the finding status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reviewFilterStatus;

  /// Review finding kind: a defect
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get reviewKindBug;

  /// Review finding kind: a non-blocking improvement
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get reviewKindSuggestion;

  /// Review finding kind: an architectural note
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get reviewKindRecommendation;

  /// Review finding kind: an open question
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get reviewKindQuestion;

  /// Review finding kind: a ticket spawned from the review
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get reviewKindTicket;

  /// Inline archive prompt shown when all pull requests in a space are merged
  ///
  /// In en, this message translates to:
  /// **'All pull requests in this space have been merged. Archive this space?'**
  String get spaceAllPrsMerged;

  /// Decline the archive prompt for a space whose pull requests have all been merged
  ///
  /// In en, this message translates to:
  /// **'No, keep this space'**
  String get spaceKeepAfterMerge;

  /// Explains that declining the archive prompt suppresses future prompts for this space
  ///
  /// In en, this message translates to:
  /// **'You won’t be asked again for this space.'**
  String get spaceKeepAfterMergeHint;

  /// Sidebar status for a space whose pull requests have all been merged
  ///
  /// In en, this message translates to:
  /// **'All pull requests merged'**
  String get spaceAllPrsMergedLabel;

  /// Archive a space (soft hide, restorable) — row menu, header button and tooltip
  ///
  /// In en, this message translates to:
  /// **'Archive space'**
  String get archiveSpace;

  /// Archived spaces dialog title and sidebar trigger tooltip
  ///
  /// In en, this message translates to:
  /// **'Archived spaces'**
  String get archivedSpaces;

  /// Empty state of the archived spaces dialog
  ///
  /// In en, this message translates to:
  /// **'No archived spaces'**
  String get archivedSpacesEmpty;

  /// Restore an archived space to the sidebar
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSpace;

  /// Space menu item and archived conversations dialog title
  ///
  /// In en, this message translates to:
  /// **'Archived conversations'**
  String get archivedConversations;

  /// Empty state of the archived conversations dialog
  ///
  /// In en, this message translates to:
  /// **'No archived conversations'**
  String get archivedConversationsEmpty;

  /// Tooltip for restoring an archived conversation
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreConversation;

  /// Subtitle on an archived space row; {time} is a relative time like '2 days ago'
  ///
  /// In en, this message translates to:
  /// **'Archived {time}'**
  String archivedWhen(String time);

  /// Permanently delete an archived space (destructive, confirmed)
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteSpacePermanently;

  /// Rename a space — sidebar row menu item and dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename space'**
  String get renameSpace;

  /// Rename a conversation — sidebar row menu item and dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get renameConversation;

  /// Accessible name for the space row overflow menu trigger
  ///
  /// In en, this message translates to:
  /// **'Space actions'**
  String get spaceActions;

  /// Accessible name for the conversation row overflow menu trigger
  ///
  /// In en, this message translates to:
  /// **'Conversation actions'**
  String get conversationActions;

  /// Edit a space's repository selection — sidebar row menu item
  ///
  /// In en, this message translates to:
  /// **'Edit repositories'**
  String get editSpaceRepos;

  /// Title of the space repository selection dialog
  ///
  /// In en, this message translates to:
  /// **'Space repositories'**
  String get editSpaceReposTitle;

  /// Caption in the repository dialog explaining that an added repository is checked out into the space and a removed one loses its folder
  ///
  /// In en, this message translates to:
  /// **'Adding a repository checks it out into this space; removing one deletes its folder.'**
  String get editSpaceReposWarning;

  /// Section heading for the agent form block holding name, title, reporting line and prompt.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get agentSectionIdentity;

  /// Section heading for the agent form block holding adapter, model and limits.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get agentSectionRuntime;

  /// Section heading for the agent form block holding the identity check and sandbox permissions.
  ///
  /// In en, this message translates to:
  /// **'Guardrails'**
  String get agentSectionGuardrails;

  /// Badge on an org-chart card counting an agent’s direct reports
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String orgChartReportCount(int count);

  /// Placeholder in the teams rail search field
  ///
  /// In en, this message translates to:
  /// **'Filter teams…'**
  String get teamsFilterHint;

  /// Summary strip fact: how many teams have a leader assigned
  ///
  /// In en, this message translates to:
  /// **'With a leader'**
  String get teamsSummaryWithLeader;

  /// Live count above the teams rail
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No teams} =1{1 team} other{{count} teams}}'**
  String teamCountLabel(int count);

  /// Danger-zone body in the agent settings form, above the delete button
  ///
  /// In en, this message translates to:
  /// **'Deleting {name} removes its profile, its skill links and its run history. This cannot be undone.'**
  String agentDeleteLongDescription(String name);

  /// Button that stages a built-in agent’s seeded title, persona and skills back onto the form
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// Create an agent: the empty state's button, and the accessible name of the roster's New button
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get newAgent;

  /// Create a skill: the editor's heading for an unsaved skill, and the accessible name of the rail's New button
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get newSkill;

  /// Short button beside a list's filter field that creates an item in that list, such as an agent or a skill
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItemAction;

  /// Tooltip on the canvas zoom-in control
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// Tooltip on the canvas zoom-out control
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// Tooltip on the image viewer control that returns the zoom to fit
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoom;

  /// Caption on the placeholder card shown when a GitHub-hosted attachment image cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Image hosted on GitHub'**
  String get imageHostedOnGitHub;

  /// Caption on the placeholder card shown when an embedded image cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Image · open externally'**
  String get imageOpenExternally;

  /// Memory scope filter option showing facts/policies from every scope
  ///
  /// In en, this message translates to:
  /// **'All scopes'**
  String get memoryScopeAll;

  /// Memory scope for entries not tied to any repository
  ///
  /// In en, this message translates to:
  /// **'Workspace-wide'**
  String get memoryScopeWorkspace;

  /// Accessible label for the memory scope filter dropdown
  ///
  /// In en, this message translates to:
  /// **'Filter by scope'**
  String get memoryScopeFilterLabel;

  /// Tooltip on the chip marking a fact or policy as scoped to one repository
  ///
  /// In en, this message translates to:
  /// **'Scoped to the {repo} repository'**
  String memoryScopeRepoTooltip(String repo);

  /// Accessible label for an image a tool returned in the transcript.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from the agent'**
  String get toolScreenshot;

  /// Shown in place of a tool-result image that could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get toolImageUnavailable;

  /// Shown in place of several tool-result images that could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'{count} images unavailable'**
  String toolImagesUnavailable(int count);

  /// Toast when /shake cannot run (no dispatch engine on the host).
  ///
  /// In en, this message translates to:
  /// **'Shaking isn\'t available on this server'**
  String get shakeUnavailable;

  /// Toast when /shake found nothing droppable.
  ///
  /// In en, this message translates to:
  /// **'Nothing to shake out — recent turns are protected'**
  String get shakeNothing;

  /// Toast summarising what /shake reclaimed.
  ///
  /// In en, this message translates to:
  /// **'Freed about {tokens} tokens'**
  String shakeDone(int tokens);

  /// Label on the inline divider marking where the agent's context was compacted.
  ///
  /// In en, this message translates to:
  /// **'Compacted'**
  String get compactionDivider;

  /// Divider label naming how many messages a compaction folded.
  ///
  /// In en, this message translates to:
  /// **'Compacted · {count} messages folded'**
  String compactionDividerCount(int count);

  /// Overlay shown on the composer while a file is dragged over it.
  ///
  /// In en, this message translates to:
  /// **'Drop to attach'**
  String get composerDropToAttach;

  /// Status of a composer attachment being uploaded before the message is sent.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get composerAttachmentUploading;

  /// Status of a composer attachment uploaded and ready to send.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get composerAttachmentReady;

  /// Status of a composer attachment whose upload failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get composerAttachmentUploadFailed;

  /// Composer attachment rejected because its file size exceeds the upload limit.
  ///
  /// In en, this message translates to:
  /// **'File exceeds the {limit} limit'**
  String composerAttachmentTooLarge(String limit);

  /// Composer attachment rejected because its file contents could not be read for upload.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file'**
  String get composerAttachmentUnreadable;

  /// Prompt shown when sending is blocked by attachments still uploading.
  ///
  /// In en, this message translates to:
  /// **'Wait for attachments to finish uploading'**
  String get composerAttachmentWaitForUploads;

  /// Prompt shown when sending is blocked by failed attachment uploads.
  ///
  /// In en, this message translates to:
  /// **'Retry or remove failed attachments before sending'**
  String get composerAttachmentResolveFailures;

  /// Title of the attachment preview when the attachment is no longer held in memory.
  ///
  /// In en, this message translates to:
  /// **'Attachment unavailable'**
  String get attachmentUnavailable;

  /// Body of the attachment preview when the registry entry has been evicted.
  ///
  /// In en, this message translates to:
  /// **'This attachment is no longer held in memory. Attach it again to preview it.'**
  String get attachmentUnavailableDetail;

  /// Shown when reading or decoding an attachment for preview failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this file'**
  String get attachmentPreviewFailed;

  /// Shown when the app has no renderer for an attachment's type.
  ///
  /// In en, this message translates to:
  /// **'No preview for this file type'**
  String get attachmentPreviewUnsupported;

  /// Shown when a text attachment exceeds the preview size ceiling.
  ///
  /// In en, this message translates to:
  /// **'Too large to preview'**
  String get attachmentTooLargeToPreview;

  /// Hands an attachment to the operating system's default handler.
  ///
  /// In en, this message translates to:
  /// **'Open in default app'**
  String get attachmentOpenExternally;

  /// Toast when a side-channel command runs on an empty conversation.
  ///
  /// In en, this message translates to:
  /// **'Nothing to work from yet'**
  String get asideEmpty;

  /// Toast when a side-channel request produced nothing.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get an answer'**
  String get asideFailed;

  /// Dialog title for the generated handoff document.
  ///
  /// In en, this message translates to:
  /// **'Handoff'**
  String get handoffTitle;

  /// Dialog title for an ephemeral /btw answer.
  ///
  /// In en, this message translates to:
  /// **'Side question'**
  String get asideTitle;

  /// Tooltip on the composer's attach button, which also names the drag-and-drop affordance.
  ///
  /// In en, this message translates to:
  /// **'Attach files — or drop them here'**
  String get attachFilesOrDrop;

  /// Tooltip on the composer toolbar button that grows the message composer to fill most of the conversation pane for writing a long prompt. The shortcut is a platform-formatted key combination such as ⌘⇧E or Ctrl+Shift+E.
  ///
  /// In en, this message translates to:
  /// **'Expand editor ({shortcut})'**
  String composerExpand(String shortcut);

  /// Tooltip on the composer toolbar button that shrinks an expanded message composer back to its normal size. The shortcut is a platform-formatted key combination such as ⌘⇧E or Ctrl+Shift+E.
  ///
  /// In en, this message translates to:
  /// **'Collapse editor ({shortcut})'**
  String composerCollapse(String shortcut);

  /// Title of the guided-goal interview dialog.
  ///
  /// In en, this message translates to:
  /// **'Sharpen the objective'**
  String get guidedGoalTitle;

  /// Explanatory line at the top of the guided-goal interview.
  ///
  /// In en, this message translates to:
  /// **'An agent working unsupervised needs to know exactly when it is done. A few questions first.'**
  String get guidedGoalIntro;

  /// Placeholder for the guided-goal answer field.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get guidedGoalAnswerHint;

  /// Button that submits an answer in the guided-goal interview.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guidedGoalNext;

  /// Button that dispatches the finished objective.
  ///
  /// In en, this message translates to:
  /// **'Start the goal'**
  String get guidedGoalStart;

  /// Button that skips the interview and dispatches the raw objective.
  ///
  /// In en, this message translates to:
  /// **'Skip and run as written'**
  String get guidedGoalSkip;

  /// Warning listing objective requirements the draft still lacks.
  ///
  /// In en, this message translates to:
  /// **'Still unspecified: {items}'**
  String guidedGoalStillMissing(String items);

  /// Title of the conversation branch navigator.
  ///
  /// In en, this message translates to:
  /// **'Conversation tree'**
  String get conversationTreeTitle;

  /// How many distinct paths the conversation holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 branch} other{{count} branches}}'**
  String conversationTreeBranches(int count);

  /// Action that moves the branch pointer to a message.
  ///
  /// In en, this message translates to:
  /// **'Continue from here'**
  String get conversationTreeSwitch;

  /// Action that copies a branch into a new conversation.
  ///
  /// In en, this message translates to:
  /// **'Fork into a new conversation'**
  String get conversationTreeFork;

  /// Badge marking a message on the branch currently shown.
  ///
  /// In en, this message translates to:
  /// **'On this branch'**
  String get conversationTreeCurrent;

  /// Empty state of the conversation tree.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get conversationTreeEmpty;

  /// Toast confirming a fork.
  ///
  /// In en, this message translates to:
  /// **'Forked into a new conversation'**
  String get conversationTreeForked;

  /// Toast confirming a branch switch.
  ///
  /// In en, this message translates to:
  /// **'Now continuing from that message'**
  String get conversationTreeSwitched;

  /// Toast naming where an export was written.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportSaved(String path);

  /// Toast when an export could not be written.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t write the export'**
  String get exportFailed;

  /// Toast when /context runs in a space with no agent.
  ///
  /// In en, this message translates to:
  /// **'No agent in this conversation, so there is no context window to open'**
  String get contextCommandNoAgent;

  /// Toast when /context names an agent that is not in the space.
  ///
  /// In en, this message translates to:
  /// **'No agent named “{name}” in this conversation. Try: {names}'**
  String contextCommandNoSuchAgent(String name, String names);

  /// Toast confirming /dump.
  ///
  /// In en, this message translates to:
  /// **'Transcript copied to the clipboard'**
  String get dumpCopied;

  /// No description provided for @messageQueueHint.
  ///
  /// In en, this message translates to:
  /// **'Keep typing to queue follow-up changes'**
  String get messageQueueHint;

  /// No description provided for @steerNow.
  ///
  /// In en, this message translates to:
  /// **'Steer'**
  String get steerNow;

  /// No description provided for @steerForce.
  ///
  /// In en, this message translates to:
  /// **'Stop and send'**
  String get steerForce;

  /// No description provided for @steeringQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Queued steering messages'**
  String get steeringQueueLabel;

  /// No description provided for @steeringDeliverUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No running agent can take that right now — it stays queued.'**
  String get steeringDeliverUnavailable;

  /// No description provided for @reorderSteeringCard.
  ///
  /// In en, this message translates to:
  /// **'Reorder queued message'**
  String get reorderSteeringCard;

  /// No description provided for @editSteeringCard.
  ///
  /// In en, this message translates to:
  /// **'Edit queued message'**
  String get editSteeringCard;

  /// No description provided for @deleteSteeringCard.
  ///
  /// In en, this message translates to:
  /// **'Delete queued message'**
  String get deleteSteeringCard;

  /// No description provided for @steeringBadge.
  ///
  /// In en, this message translates to:
  /// **'Steered'**
  String get steeringBadge;

  /// Settings → Server → Sandbox nav label
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get settingsSandboxLabel;

  /// Title of the executable-grants settings card
  ///
  /// In en, this message translates to:
  /// **'Executable grants'**
  String get sandboxExecGrantsTitle;

  /// Explanation under the executable-grants card title
  ///
  /// In en, this message translates to:
  /// **'Programs agents may run from their working copy of your repositories. Each entry was approved by you when the sandbox asked.'**
  String get sandboxExecGrantsSubtitle;

  /// Empty state for the executable-grants list
  ///
  /// In en, this message translates to:
  /// **'No decisions recorded yet. You\'ll be asked the first time an agent needs to run a program from its working copy.'**
  String get sandboxExecGrantsEmpty;

  /// Button revoking one executable grant
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get sandboxExecGrantRevoke;

  /// Badge for an allowed executable grant
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get sandboxExecGrantAllowed;

  /// Badge for a blocked executable grant
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get sandboxExecGrantBlocked;

  /// Confirm dialog title when revoking a grant
  ///
  /// In en, this message translates to:
  /// **'Revoke this decision?'**
  String get sandboxExecGrantRevokeConfirmTitle;

  /// Confirm dialog body when revoking a grant
  ///
  /// In en, this message translates to:
  /// **'You\'ll be asked again the next time an agent needs to run a program from this copy.'**
  String get sandboxExecGrantRevokeConfirmBody;

  /// Placeholder of the search field filtering executable grants by path
  ///
  /// In en, this message translates to:
  /// **'Search paths'**
  String get sandboxExecGrantsSearchHint;

  /// Shown when no executable grant path matches the search
  ///
  /// In en, this message translates to:
  /// **'No grants match your search'**
  String get sandboxExecGrantsNoMatch;

  /// Persistent badge in the app shell header when connected to a public demo server
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoBadgeLabel;

  /// Title of the demo mock file picker
  ///
  /// In en, this message translates to:
  /// **'Demo files'**
  String get demoFilePickerTitle;

  /// Body copy of the demo mock file picker
  ///
  /// In en, this message translates to:
  /// **'The demo fakes uploads: pick any of these and it attaches to your message without touching a disk.'**
  String get demoFilePickerBody;

  /// Attach button of the demo mock file picker
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get demoFilePickerAttach;

  /// Badge/tooltip for a save action that is disabled on a demo server
  ///
  /// In en, this message translates to:
  /// **'Read-only in the demo'**
  String get demoReadOnlySave;

  /// Tooltip on the demo badge explaining what a demo server is
  ///
  /// In en, this message translates to:
  /// **'You\'re exploring a demo. The data is fictional and the agents are scripted.'**
  String get demoBadgeTooltip;

  /// Title of the one-time note shown on a visitor's first frame in the demo
  ///
  /// In en, this message translates to:
  /// **'You\'re in a live demo'**
  String get demoFirstRunTitle;

  /// Body of the demo first-run note
  ///
  /// In en, this message translates to:
  /// **'This is the real app running on real code — only the data is invented. Agents stream genuine runs from a script, so nothing reaches a model and nothing runs on a machine. Your workspace is yours alone and disappears after {minutes} minutes.'**
  String demoFirstRunBody(int minutes);

  /// Dismiss button on the demo first-run note
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get demoFirstRunDismiss;

  /// Title of the demo's guided tour panel
  ///
  /// In en, this message translates to:
  /// **'Where to look first'**
  String get demoTourTitle;

  /// Subtitle of the demo's guided tour panel
  ///
  /// In en, this message translates to:
  /// **'Four places that show what the app actually does.'**
  String get demoTourSubtitle;

  /// Button that dismisses the demo tour without walking it
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get demoTourSkip;

  /// Button in the demo tour header that opens the project's own GitHub repository in the OS browser
  ///
  /// In en, this message translates to:
  /// **'Star on GitHub'**
  String get demoTourStarRepo;

  /// Button on a demo tour step that navigates to that pillar
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get demoTourOpen;

  /// Demo tour step title: messaging and agent runs
  ///
  /// In en, this message translates to:
  /// **'Talk to an agent'**
  String get demoTourSpacesTitle;

  /// Demo tour step body: messaging and agent runs
  ///
  /// In en, this message translates to:
  /// **'Send a message in a space and watch a run stream in — thinking, tool calls and cost, exactly as a real run renders.'**
  String get demoTourSpacesBody;

  /// Demo tour step title: PR review
  ///
  /// In en, this message translates to:
  /// **'Review a pull request'**
  String get demoTourReviewTitle;

  /// Demo tour step body: PR review
  ///
  /// In en, this message translates to:
  /// **'Open #412. Leave an inline comment or submit a review; your words land in the thread and stay there.'**
  String get demoTourReviewBody;

  /// Demo tour step title: tickets, todos and plans
  ///
  /// In en, this message translates to:
  /// **'Follow the work'**
  String get demoTourTicketsTitle;

  /// Demo tour step body: tickets, todos and plans
  ///
  /// In en, this message translates to:
  /// **'Tickets, todos and plans are linked to the same conversations the agents are having.'**
  String get demoTourTicketsBody;

  /// Demo tour step title: the unified inbox
  ///
  /// In en, this message translates to:
  /// **'See the whole operation'**
  String get demoTourInboxTitle;

  /// Demo tour step body: the unified inbox
  ///
  /// In en, this message translates to:
  /// **'Every alert from every pillar lands in one inbox — reviews, tickets, runs and meetings.'**
  String get demoTourInboxBody;

  /// Heading of the notice shown where a demo server has removed a capability
  ///
  /// In en, this message translates to:
  /// **'Not available in the demo'**
  String get demoUnavailableTitle;

  /// Why the terminal is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'A terminal runs a real shell on the server host. The demo has no execution surface at all — that is what makes it safe to open to the public.'**
  String get demoUnavailableTerminal;

  /// Why enclosures (VMs) are unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'An enclosure is a disposable virtual machine an agent drives. The demo boots none: a public endpoint that can start a VM is not a demo.'**
  String get demoUnavailableRig;

  /// Why the in-browser code editor is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'The in-browser editor runs a code-server process against a real checkout. The demo has neither.'**
  String get demoUnavailableEditor;

  /// Why the newsfeed subscription list cannot be edited on a demo server
  ///
  /// In en, this message translates to:
  /// **'The demo reads real feeds, but its subscription list is fixed. Adding or removing one is disabled here.'**
  String get demoUnavailableFeeds;

  /// Why forge sign-in and credentials are unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'The demo holds no credentials and never contacts GitHub, GitLab or Linear. Its pull requests are fixtures, and your comments on them are stored locally.'**
  String get demoUnavailableForge;

  /// Why LLM provider and model management is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'The demo calls no model. Agent runs are scripted playback, which is why they cost nothing and reach no provider.'**
  String get demoUnavailableModels;

  /// Why the MCP tool surface is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'The MCP tool surface is not mounted on the demo, so no external client can attach to it.'**
  String get demoUnavailableMcp;

  /// Why repositories, worktrees and git are unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'The demo checks out no code and runs no git. The repository you see is a fixture behind the pull requests.'**
  String get demoUnavailableRepos;

  /// Why installing skills is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'Installing a skill downloads and scans code. The demo fetches nothing.'**
  String get demoUnavailableSkills;

  /// Why single sign-on is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'Single sign-on is server configuration. The demo signs you in as a temporary guest instead.'**
  String get demoUnavailableSso;

  /// Why meeting recording and dictation are unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'Recording and dictation need audio capture and a speech model on the host. The demo ships neither, so its meetings are transcripts without playback.'**
  String get demoUnavailableAudio;

  /// Why server administration is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'This is server administration. The demo gives every visitor their own throwaway workspace and nothing beyond it.'**
  String get demoUnavailableServerAdmin;

  /// Why creating, starting and triggering pipelines is unavailable on a demo server
  ///
  /// In en, this message translates to:
  /// **'Pipelines cannot run here. A visitor who can write a bash step and start it — by hand or through an event trigger — is executing code on this host.'**
  String get demoUnavailablePipelines;

  /// Settings → Server → Backup & restore nav label and page title
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupRestore;

  /// Subtitle of the backup & restore settings page
  ///
  /// In en, this message translates to:
  /// **'Snapshots of every database on this server, plus export, import and delete for a single workspace.'**
  String get settingsBackupRestoreDescription;

  /// Card label for the whole-install snapshot list
  ///
  /// In en, this message translates to:
  /// **'Install snapshots'**
  String get backupSnapshotsLabel;

  /// What a snapshot is and how a restore works
  ///
  /// In en, this message translates to:
  /// **'A snapshot copies every database into a timestamped folder on the server host. Restoring a whole install means copying that folder back with the server stopped; a single workspace can be restored from here.'**
  String get backupSnapshotsExplainer;

  /// Button that takes a snapshot of every database on the server
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNowAction;

  /// Toast after a snapshot is taken, naming the directory on the server
  ///
  /// In en, this message translates to:
  /// **'Snapshot written to {path}'**
  String backupSnapshotWritten(String path);

  /// Empty state of the snapshot list
  ///
  /// In en, this message translates to:
  /// **'No install snapshots yet. Take one now, or use a workspace backup pipeline for scheduled copies.'**
  String get backupNoSnapshots;

  /// Status of a snapshot whose manifest and files are all present
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get backupSnapshotComplete;

  /// Status of a snapshot that died halfway
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get backupSnapshotIncomplete;

  /// What an incomplete snapshot can and cannot restore
  ///
  /// In en, this message translates to:
  /// **'The manifest is missing or names files that are not there, so this snapshot cannot restore the whole install. The workspace files it does have can still be adopted one by one.'**
  String get backupSnapshotIncompleteNote;

  /// Heading of the destructive action inside an expanded install snapshot
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get backupDeleteSnapshotLabel;

  /// Danger callout explaining permanent snapshot deletion
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this snapshot from the server. Download it first if you need to keep a copy.'**
  String get backupDeleteSnapshotDescription;

  /// Button confirming deletion of a server snapshot
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get backupDeleteSnapshotAction;

  /// Title of the snapshot deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this snapshot?'**
  String get backupDeleteSnapshotTitle;

  /// Confirmation message for deleting a whole-install snapshot
  ///
  /// In en, this message translates to:
  /// **'Delete {name} from the server? All databases in this snapshot will be lost. This cannot be undone.'**
  String backupDeleteSnapshotBody(String name);

  /// Success toast for deleting a server snapshot
  ///
  /// In en, this message translates to:
  /// **'Deleted snapshot {name}.'**
  String backupDeleteSnapshotDone(String name);

  /// How many workspaces a snapshot captured
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workspaces} =1{1 workspace} other{{count} workspaces}}'**
  String backupSnapshotWorkspaces(int count);

  /// How many workspaces a snapshot could not capture
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workspace not captured} other{{count} workspaces not captured}}'**
  String backupSnapshotSkipped(int count);

  /// Label above a filesystem path that lives on the server host
  ///
  /// In en, this message translates to:
  /// **'Path on the server'**
  String get backupServerPathLabel;

  /// Heading of the Settings section listing each workspace's pipeline backups
  ///
  /// In en, this message translates to:
  /// **'Scheduled backups'**
  String get backupScheduledLabel;

  /// Explains where scheduled workspace backups come from and where to configure them
  ///
  /// In en, this message translates to:
  /// **'Copies saved by each workspace\'s backup pipeline. Set the schedule and retention in the pipeline\'s template.'**
  String get backupScheduledExplainer;

  /// Status of a workspace whose backup pipeline has saved nothing yet
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupScheduledNone;

  /// How many scheduled backups a workspace has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 backup} other{{count} backups}}'**
  String backupScheduledCount(int count);

  /// When a workspace was last backed up; time is a relative phrase such as '5 days ago'
  ///
  /// In en, this message translates to:
  /// **'Last backup {time}'**
  String backupScheduledLast(String time);

  /// Shown on a workspace row when the server refuses to list its backups
  ///
  /// In en, this message translates to:
  /// **'You need the admin role on this workspace to see its backups.'**
  String get backupListForbidden;

  /// Title of the confirmation before deleting one scheduled backup
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get backupScheduledDeleteTitle;

  /// Confirmation body before deleting one scheduled backup
  ///
  /// In en, this message translates to:
  /// **'Delete the {date} backup of {name} from the server? This cannot be undone.'**
  String backupScheduledDeleteBody(String date, String name);

  /// Toast after one scheduled backup was deleted
  ///
  /// In en, this message translates to:
  /// **'Backup deleted.'**
  String get backupScheduledDeleteDone;

  /// Status of a row listing backups left by a deleted workspace
  ///
  /// In en, this message translates to:
  /// **'Workspace deleted'**
  String get backupScheduledWorkspaceDeleted;

  /// Button that adopts a workspace file from a snapshot
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreAction;

  /// Title of the restore-workspace confirmation
  ///
  /// In en, this message translates to:
  /// **'Restore workspace'**
  String get backupRestoreTitle;

  /// Consequences of restoring a workspace from a snapshot
  ///
  /// In en, this message translates to:
  /// **'This replaces everything in {name} with the copy held in this snapshot. Whatever that workspace has done since the snapshot was taken is lost, and it cannot be undone.'**
  String backupRestoreBody(String name);

  /// Toast after a workspace is restored from a snapshot
  ///
  /// In en, this message translates to:
  /// **'Restored {name} from the snapshot.'**
  String backupRestoreDone(String name);

  /// Subtitle for a snapshot workspace the server no longer has
  ///
  /// In en, this message translates to:
  /// **'Not on this server any more'**
  String get backupWorkspaceUnknown;

  /// Card label for the per-workspace export, import and delete actions
  ///
  /// In en, this message translates to:
  /// **'Workspace data'**
  String get backupWorkspaceDataLabel;

  /// Why exporting a workspace is a file operation
  ///
  /// In en, this message translates to:
  /// **'One workspace is one database file, so exporting it copies that file rather than dumping table by table. Importing replaces everything in the target workspace with the file you name.'**
  String get backupWorkspaceDataExplainer;

  /// Button that writes one workspace out as one file
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get backupExportAction;

  /// Toast after a workspace is exported, naming the file on the server
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String backupExportDone(String path);

  /// Label above the path of the file an export just wrote
  ///
  /// In en, this message translates to:
  /// **'Exported file on the server'**
  String get backupExportedFileLabel;

  /// Button that adopts a workspace database file
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get backupImportAction;

  /// Title of the import dialog, naming the target workspace
  ///
  /// In en, this message translates to:
  /// **'Import into {name}'**
  String backupImportTitle(String name);

  /// Consequences of importing a database file into a workspace
  ///
  /// In en, this message translates to:
  /// **'This replaces everything in {name} with the contents of the file. Whatever that workspace holds now is lost, and it cannot be undone.'**
  String backupImportBody(String name);

  /// Label of the field naming the file to import
  ///
  /// In en, this message translates to:
  /// **'Workspace database file'**
  String get backupImportSourceLabel;

  /// That import paths are resolved on the server, not the client
  ///
  /// In en, this message translates to:
  /// **'A .db file the server can read. Paths resolve on the server host, not on this device.'**
  String get backupImportSourceDescription;

  /// Toast after a workspace database is imported
  ///
  /// In en, this message translates to:
  /// **'Imported into {name}.'**
  String backupImportDone(String name);

  /// What deleting a workspace does and what it leaves on disk
  ///
  /// In en, this message translates to:
  /// **'{name} disappears from every list and lookup. Its database file stays on disk, backups still include it, and nothing reclaims the space automatically.'**
  String backupDeleteBody(String name);

  /// That an export can be left on the server or downloaded here
  ///
  /// In en, this message translates to:
  /// **'Write a copy on the server, or download one to this device.'**
  String get backupExportDescription;

  /// Button that writes an export onto the server's own disk
  ///
  /// In en, this message translates to:
  /// **'Save on server'**
  String get backupExportOnServerAction;

  /// Button that downloads a backup to this device
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get backupDownloadAction;

  /// Toast naming where a download was saved on this device
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String backupDownloadSaved(String path);

  /// Toast when the browser took over the download (web build)
  ///
  /// In en, this message translates to:
  /// **'Your browser is downloading it.'**
  String get backupDownloadInBrowser;

  /// Field label for restoring from a file on this device
  ///
  /// In en, this message translates to:
  /// **'Restore from this device'**
  String get backupRestoreFromDeviceLabel;

  /// That the picked file is uploaded to the server
  ///
  /// In en, this message translates to:
  /// **'Pick a workspace database file here and Control Center uploads it to the server. This is the one that works when the server is not this machine.'**
  String get backupRestoreFromDeviceDescription;

  /// Button that picks a file and uploads it to restore a workspace
  ///
  /// In en, this message translates to:
  /// **'Choose a file and upload'**
  String get backupUploadAction;

  /// Why download and upload are off: the app has no file lane to the server for this session (direct and relayed connections both carry one once connected)
  ///
  /// In en, this message translates to:
  /// **'File transfers aren\'t set up for this connection yet. Reconnect to the server to download or upload a backup.'**
  String get backupTransferUnavailable;

  /// Which role each backup transfer requires, after a refusal
  ///
  /// In en, this message translates to:
  /// **'The server refused. Downloading a workspace needs the workspace admin role. Restoring one needs the server owner, who must also own the workspace. A whole snapshot needs the server owner.'**
  String get backupTransferForbidden;

  /// That this server has no backup surface at all
  ///
  /// In en, this message translates to:
  /// **'This server has no backup surface.'**
  String get backupTransferUnsupported;

  /// That the uploaded file exceeds what the server accepts
  ///
  /// In en, this message translates to:
  /// **'The file is larger than the server accepts.'**
  String get backupTransferTooLarge;

  /// Dialog title when a run is parked on a credential
  ///
  /// In en, this message translates to:
  /// **'Waiting on a credential'**
  String get credentialGateWaitingTitle;

  /// Dialog title when a harness provider has no credential
  ///
  /// In en, this message translates to:
  /// **'{provider} has no credential'**
  String credentialGateHarnessTitle(String provider);

  /// Dialog title when the Claude Code account is signed out
  ///
  /// In en, this message translates to:
  /// **'Claude Code is signed out'**
  String get credentialGateSignedOutTitle;

  /// Dialog title when the Claude Code sign-in has expired
  ///
  /// In en, this message translates to:
  /// **'Your Claude Code sign-in has expired'**
  String get credentialGateExpiredTitle;

  /// Dialog title when the Claude Code plan is out of headroom
  ///
  /// In en, this message translates to:
  /// **'Claude Code plan limit reached'**
  String get credentialGatePlanSpentTitle;

  /// Which agent's turn is parked
  ///
  /// In en, this message translates to:
  /// **'{agent} is waiting to continue.'**
  String credentialGateWaitingAgent(String agent);

  /// That a run is parked, when the agent is unknown
  ///
  /// In en, this message translates to:
  /// **'A run is waiting to continue.'**
  String get credentialGateWaitingRun;

  /// That the server is watching for the fix and resumes on its own
  ///
  /// In en, this message translates to:
  /// **'Watching for the fix — the run continues on its own.'**
  String get credentialGateWatching;

  /// When a spent plan window reopens
  ///
  /// In en, this message translates to:
  /// **'Frees up at {time}'**
  String credentialGateFreesUpAt(String time);

  /// When the parked run stops waiting and fails
  ///
  /// In en, this message translates to:
  /// **'The run gives up at {time}'**
  String credentialGateGivesUpAt(String time);

  /// Button that re-probes the credential now
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get credentialGateCheckAgain;

  /// Button that gives up on the parked run
  ///
  /// In en, this message translates to:
  /// **'Cancel run'**
  String get credentialGateCancelRun;

  /// Heading above the accounts the run considered
  ///
  /// In en, this message translates to:
  /// **'Accounts tried'**
  String get credentialGateAccountsTried;

  /// How to sign a Claude Code account back in
  ///
  /// In en, this message translates to:
  /// **'Sign in from Settings → Adapters → Claude Code, or run the login command in a terminal. The run picks it up on its own.'**
  String get credentialGateClaudeSignInHint;

  /// Button that opens the settings screen
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get credentialGateOpenSettings;

  /// Credential-gate dialog title when every Claude Code account on the agent or workspace list was removed from the server
  ///
  /// In en, this message translates to:
  /// **'The attached Claude Code accounts were removed'**
  String get credentialGateAccountsRemovedTitle;

  /// Credential-gate dialog hint explaining how to fix a list of removed Claude Code accounts
  ///
  /// In en, this message translates to:
  /// **'Attach another account in this agent\'s or the workspace\'s account settings, or clear the list to use the default. The run picks it up on its own.'**
  String get credentialGateAccountsRemovedHint;

  /// Account rotation editor notice when every account on the list was removed from the server
  ///
  /// In en, this message translates to:
  /// **'Every account on this list has been removed from the server. Attach another one, or clear the list.'**
  String get accountPoolAllRemoved;

  /// Button that clears an account rotation list
  ///
  /// In en, this message translates to:
  /// **'Clear the list'**
  String get accountPoolClear;

  /// Title of the model browser dialog and hint of the model picker field
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// Model browser rail item that clears the provider filter
  ///
  /// In en, this message translates to:
  /// **'All models'**
  String get allModels;

  /// Model browser footer when the search matches nothing
  ///
  /// In en, this message translates to:
  /// **'No models match your search'**
  String get noModelsMatchSearch;

  /// Model browser row offering the raw search text as a custom model id
  ///
  /// In en, this message translates to:
  /// **'Use “{id}”'**
  String useCustomModelId(String id);

  /// Price shown for a model with zero cost on both lanes
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get modelFree;

  /// Compact output-token ceiling, e.g. '131k output'
  ///
  /// In en, this message translates to:
  /// **'{tokens} output'**
  String modelOutputTokens(String tokens);

  /// Model price breakdown, e.g. '$1.40 in / $4.40 out per 1M tokens'
  ///
  /// In en, this message translates to:
  /// **'{input} in / {output} out per 1M tokens'**
  String modelPricePerMTokens(String input, String output);

  /// The reasoning effort levels a model accepts, e.g. 'Reasoning effort: Low · Medium'
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort: {levels}'**
  String modelEffortLevels(String levels);

  /// Tooltip on the icon marking a model with a reasoning-effort control
  ///
  /// In en, this message translates to:
  /// **'Supports reasoning effort'**
  String get modelSupportsReasoning;

  /// No description provided for @profileDeliveryMetrics.
  ///
  /// In en, this message translates to:
  /// **'Delivery metrics'**
  String get profileDeliveryMetrics;

  /// Number of pull requests sampled for profile metrics
  ///
  /// In en, this message translates to:
  /// **'PRs analyzed: {count}'**
  String profileMetricsSample(int count);

  /// No description provided for @profileMergeRate.
  ///
  /// In en, this message translates to:
  /// **'Merge rate'**
  String get profileMergeRate;

  /// No description provided for @profileReviewCoverage.
  ///
  /// In en, this message translates to:
  /// **'Review coverage'**
  String get profileReviewCoverage;

  /// No description provided for @profilePrSize.
  ///
  /// In en, this message translates to:
  /// **'PR size'**
  String get profilePrSize;

  /// No description provided for @profileTimeToMerge.
  ///
  /// In en, this message translates to:
  /// **'Time to merge'**
  String get profileTimeToMerge;

  /// No description provided for @profileMergeTimeTrend.
  ///
  /// In en, this message translates to:
  /// **'Merge time trend'**
  String get profileMergeTimeTrend;

  /// No description provided for @profileWeeklyMedian.
  ///
  /// In en, this message translates to:
  /// **'Weekly median, log scale'**
  String get profileWeeklyMedian;

  /// No description provided for @profilePrOpeningPattern.
  ///
  /// In en, this message translates to:
  /// **'Weekday × hour, local time'**
  String get profilePrOpeningPattern;

  /// No description provided for @profileFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Time to first review'**
  String get profileFirstReview;

  /// No description provided for @profileMetricsTruncated.
  ///
  /// In en, this message translates to:
  /// **'Percentiles use a limited sample of the available pull requests.'**
  String get profileMetricsTruncated;

  /// Compact count of lines changed
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String profileLinesChanged(String count);

  /// Compact duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String profileDurationMinutes(int count);

  /// Compact duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count} hr'**
  String profileDurationHours(int count);

  /// Compact duration in days and hours
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String profileDurationDaysHours(int days, int hours);

  /// Median and 90th percentile values
  ///
  /// In en, this message translates to:
  /// **'p50 {median} · p90 {p90}'**
  String profilePercentiles(String median, String p90);

  /// Team member count
  ///
  /// In en, this message translates to:
  /// **'Members: {count}'**
  String profileTeamMembers(int count);

  /// Empty state for a team with no workspace pull requests
  ///
  /// In en, this message translates to:
  /// **'No pull requests by {team} in this workspace'**
  String noPrsByTeamInWorkspace(String team);

  /// No description provided for @profilePrStateFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter pull requests by state'**
  String get profilePrStateFilterLabel;

  /// No description provided for @noProfilePrsMatchSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Try another title or pull request number'**
  String get noProfilePrsMatchSearchHint;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'Network unrestricted'**
  String get rigNetworkUnrestricted;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'Allow all hosts'**
  String get rigNetworkAllowAllHosts;

  /// Browser shield flyout title
  ///
  /// In en, this message translates to:
  /// **'Site permissions'**
  String get rigBrowserPermissionsTitle;

  /// Browser shield tooltip
  ///
  /// In en, this message translates to:
  /// **'Site permissions and network'**
  String get rigBrowserPermissionsTooltip;

  /// Empty state in the browser shield flyout
  ///
  /// In en, this message translates to:
  /// **'No site has asked for a permission yet'**
  String get rigBrowserPermissionEmpty;

  /// Pending site permission in the browser shield flyout
  ///
  /// In en, this message translates to:
  /// **'{origin} wants to use {permission}'**
  String rigBrowserPermissionPrompt(String origin, String permission);

  /// Refuse a site permission request
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get rigBrowserPermissionBlock;

  /// No description provided for @rigBrowserPermissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get rigBrowserPermissionCamera;

  /// No description provided for @rigBrowserPermissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get rigBrowserPermissionMicrophone;

  /// No description provided for @rigBrowserPermissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get rigBrowserPermissionNotifications;

  /// No description provided for @rigBrowserPermissionGeolocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get rigBrowserPermissionGeolocation;

  /// No description provided for @rigBrowserPermissionPersistentStorage.
  ///
  /// In en, this message translates to:
  /// **'Persistent storage'**
  String get rigBrowserPermissionPersistentStorage;

  /// No description provided for @rigBrowserPermissionClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get rigBrowserPermissionClipboard;

  /// No description provided for @rigBrowserPermissionDisplayCapture.
  ///
  /// In en, this message translates to:
  /// **'Screen capture'**
  String get rigBrowserPermissionDisplayCapture;

  /// No description provided for @rigBrowserPermissionMidi.
  ///
  /// In en, this message translates to:
  /// **'MIDI'**
  String get rigBrowserPermissionMidi;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'Allow every network host?'**
  String get rigNetworkBypassTitle;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'This restarts the enclosure and discards uncommitted work inside it. The guest can then reach any network host until it is closed.'**
  String get rigNetworkBypassBody;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'Restart unrestricted'**
  String get rigNetworkRestartUnrestricted;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'This enclosure can reach every network host. Close it and open a new one to restore the default restrictions.'**
  String get rigNetworkUnrestrictedBody;

  /// Enclosure network security control
  ///
  /// In en, this message translates to:
  /// **'This Android emulator already manages its own networking, so Control Center cannot enforce a per-host allowlist. No restart is needed.'**
  String get rigNetworkAlreadyUnrestrictedBody;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Paste clipboard into this enclosure?'**
  String get rigClipboardPermissionHostToRigTitle;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Control Center will read your device clipboard and send its contents to the enclosure. Clipboard content may contain passwords or other secrets.'**
  String get rigClipboardPermissionHostToRigBody;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Copy clipboard out of this enclosure?'**
  String get rigClipboardPermissionRigToHostTitle;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Control Center will read the enclosure clipboard and replace your device clipboard with its contents. Treat content from the enclosure as untrusted.'**
  String get rigClipboardPermissionRigToHostBody;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Allow for 10 minutes'**
  String get rigClipboardAllowTenMinutes;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get rigClipboardAlwaysAllow;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Clipboard access'**
  String get rigClipboardSettingsTitle;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Choose which clipboard transfers can run without asking. Temporary permissions expire after 10 minutes.'**
  String get rigClipboardSettingsHint;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Always allow paste into enclosures'**
  String get rigClipboardAlwaysPasteTitle;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Send this device\'s clipboard to any enclosure without asking.'**
  String get rigClipboardAlwaysPasteDescription;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Always allow copy from enclosures'**
  String get rigClipboardAlwaysCopyTitle;

  /// Rig clipboard permission and settings
  ///
  /// In en, this message translates to:
  /// **'Put clipboard content from any enclosure on this device without asking.'**
  String get rigClipboardAlwaysCopyDescription;

  /// Profile card subtitle: workspace overlay, not a second account
  ///
  /// In en, this message translates to:
  /// **'These fields are you in this workspace. Empty fields inherit your account name and email. Switching workspace switches this overlay.'**
  String get profileOverlayHint;

  /// Menu item that cuts the next branch in this space's stack
  ///
  /// In en, this message translates to:
  /// **'Start next part'**
  String get stackStartNextPart;

  /// Title of the dialog that names the next stack part
  ///
  /// In en, this message translates to:
  /// **'Part name'**
  String get stackPartNameTitle;

  /// Example part name
  ///
  /// In en, this message translates to:
  /// **'e.g. migration'**
  String get stackPartNameHint;

  /// Button that pushes the stack and opens its pull requests
  ///
  /// In en, this message translates to:
  /// **'Publish stack'**
  String get stackPublish;

  /// Marker on the stack layer that is checked out
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get stackCurrentPart;

  /// Shown when a stack move is refused because the checkout is dirty
  ///
  /// In en, this message translates to:
  /// **'Commit or discard changes before switching parts'**
  String get stackSwitchDirty;

  /// Toast when cutting a stack part fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the next part'**
  String get stackCutFailed;

  /// Toast when publishing a stack fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish the stack'**
  String get stackPublishFailed;

  /// Toast when the stack's pull requests were opened
  ///
  /// In en, this message translates to:
  /// **'Published the stack as drafts'**
  String get stackPublished;

  /// Menu item that opens a stack layer's pull request
  ///
  /// In en, this message translates to:
  /// **'Open pull request'**
  String get stackOpenPullRequest;

  /// Section heading for the layers of a branch stack
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get stackSection;

  /// Label of the merge button when the pull request conflicts with its base branch; opens a flyout listing the conflicting files
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get mergeConflictsButton;

  /// Summary above the list of files that conflict with the base branch
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file conflicts with {base}} other{{count} files conflict with {base}}}'**
  String mergeConflictsFileCount(int count, String base);

  /// Shown while the server computes which files conflict
  ///
  /// In en, this message translates to:
  /// **'Finding the conflicting files…'**
  String get mergeConflictsLoading;

  /// Shown when the conflicting files could not be listed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t list the conflicting files'**
  String get mergeConflictsLoadFailed;

  /// Shown when GitHub reported conflicts but none were found on the current branch
  ///
  /// In en, this message translates to:
  /// **'No conflicting files found. GitHub may still be updating this pull request.'**
  String get mergeConflictsNoneFound;

  /// Button that starts an AI agent resolving the pull request's merge conflicts
  ///
  /// In en, this message translates to:
  /// **'Ask AI to fix conflicts'**
  String get askAiToFixConflicts;

  /// Toast after an agent was started to resolve merge conflicts
  ///
  /// In en, this message translates to:
  /// **'An agent is resolving the conflicts in this pull request\'s chat'**
  String get fixConflictsStarted;

  /// Toast when the conflict-fixing agent could not be started
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the conflict fix: {error}'**
  String failedToStartConflictFix(String error);

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get settingsLinks;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Choose where links from outside Control Center open, such as a pull request opened from GitHub.'**
  String get linksSettingsDescription;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Remembered workspaces'**
  String get repoLinkRememberedTitle;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'When a repository is linked in more than one workspace, opening a link to it asks which workspace to use. The choices you asked to remember are listed here.'**
  String get repoLinkRememberedHint;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'No remembered choices yet.'**
  String get repoLinkRememberedEmpty;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get repoLinkForget;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Workspace no longer available'**
  String get repoLinkWorkspaceUnavailable;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Choose a workspace'**
  String get repoLinkWorkspaceDialogTitle;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'{repo} is linked in more than one workspace. Which one should this link open in?'**
  String repoLinkWorkspaceDialogBody(String repo);

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Remember my choice for this repository'**
  String get repoLinkWorkspaceRemember;

  /// Settings → You → Links, and the dialog asking which workspace a repository link opens in
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get repoLinkWorkspaceOpen;

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'Add repository to a workspace'**
  String get repoLinkUnlinkedTitle;

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'No workspace links {repo} yet. Add it to one to open this link.'**
  String repoLinkUnlinkedBody(String repo);

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'Add to {workspace}'**
  String repoLinkUnlinkedAddTo(String workspace);

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'Pick its checkout on the server.'**
  String get repoLinkUnlinkedAddToHint;

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get repoLinkUnlinkedCreate;

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'Name it, then pick the checkout.'**
  String get repoLinkUnlinkedCreateHint;

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'Select the checkout of {repo} on the machine running the server.'**
  String repoLinkChooseCheckout(String repo);

  /// The dialog shown when a link names a repository no workspace links, and the add-repository step it leads to
  ///
  /// In en, this message translates to:
  /// **'None of the added repositories is {repo}, so the link opened without it.'**
  String repoLinkCheckoutMismatch(String repo);

  /// Tooltip and accessible name of the app-drawn minimize button in the window's title bar (Windows, Linux)
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowMinimize;

  /// Tooltip and accessible name of the app-drawn maximize button in the window's title bar (Windows, Linux)
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowMaximize;

  /// Tooltip and accessible name of the app-drawn button that restores a maximized window to its previous size (Windows, Linux)
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowRestore;

  /// Onboarding sandbox step title when the host platform has no native sandbox at all (nothing to install)
  ///
  /// In en, this message translates to:
  /// **'Native sandbox is not supported on {platform} yet.'**
  String nativeSandboxUnsupported(String platform);

  /// Onboarding sandbox step button on a platform with no native sandbox: agents will run without isolation
  ///
  /// In en, this message translates to:
  /// **'Continue without sandbox'**
  String get continueWithoutSandbox;

  /// Onboarding sandbox step button that re-detects the sandbox after the user installed the missing tools
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get sandboxCheckAgain;

  /// Keyboard shortcut label (⌘P / Ctrl+P) for the IDE quick open file picker.
  ///
  /// In en, this message translates to:
  /// **'Go to file'**
  String get ideQuickOpen;

  /// Placeholder in the quick open picker's search field.
  ///
  /// In en, this message translates to:
  /// **'Search files by name'**
  String get ideQuickOpenHint;

  /// Tag on a quick open row that comes from the recently opened file list.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get ideQuickOpenRecentlyOpened;

  /// Tooltip on a quick open row's button that opens the file in a new split pane to the side.
  ///
  /// In en, this message translates to:
  /// **'Open to the side'**
  String get ideQuickOpenOpenToSide;

  /// Tooltip on a quick open row's button that removes the file from the recently opened list.
  ///
  /// In en, this message translates to:
  /// **'Remove from recently opened'**
  String get ideQuickOpenRemoveRecent;

  /// Quick open empty state when nothing is typed and no files have been opened yet.
  ///
  /// In en, this message translates to:
  /// **'No recently opened files'**
  String get ideQuickOpenNoRecent;

  /// Tooltip and screen-reader name of the PR diff file header button that marks the file as viewed.
  ///
  /// In en, this message translates to:
  /// **'Mark as viewed'**
  String get diffMarkFileViewed;

  /// Tooltip and screen-reader name of the PR diff file header button that clears the viewed mark.
  ///
  /// In en, this message translates to:
  /// **'Mark as not viewed'**
  String get diffMarkFileNotViewed;

  /// Number of added lines in a diff, read by screen readers in place of the green "+N".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 addition} other{{count} additions}}'**
  String diffAdditionsCount(int count);

  /// Number of removed lines in a diff, read by screen readers in place of the red "−N".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deletion} other{{count} deletions}}'**
  String diffDeletionsCount(int count);

  /// Screen-reader label of a PR diff file header. status is e.g. "Modified"; additions/deletions are diffAdditionsCount/diffDeletionsCount.
  ///
  /// In en, this message translates to:
  /// **'{path}, {status}, {additions}, {deletions}'**
  String diffFileSemantics(
    String path,
    String status,
    String additions,
    String deletions,
  );

  /// Screen-reader label of a PR diff file header for a file the reviewer marked viewed.
  ///
  /// In en, this message translates to:
  /// **'{path}, {status}, {additions}, {deletions}, viewed'**
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  );

  /// Screen-reader status of a renamed file in the PR diff; previous is the old path.
  ///
  /// In en, this message translates to:
  /// **'renamed from {previous}'**
  String diffFileRenamedFrom(String previous);

  /// Screen-reader label of a folder row in the PR diff file tree.
  ///
  /// In en, this message translates to:
  /// **'{name}, folder, {count, plural, =1{1 file} other{{count} files}}'**
  String diffTreeFolderSemantics(String name, int count);

  /// Screen-reader label of a file row in the PR diff file tree; status is e.g. "Added".
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}'**
  String diffTreeFileSemantics(String name, String status);

  /// Screen-reader label of a file row in the PR diff file tree that the reviewer marked viewed.
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}, viewed'**
  String diffTreeFileSemanticsViewed(String name, String status);

  /// Screen-reader label of an added code line in the PR diff.
  ///
  /// In en, this message translates to:
  /// **'Added line {line}: {code}'**
  String diffLineAdded(int line, String code);

  /// Screen-reader label of a removed code line in the PR diff.
  ///
  /// In en, this message translates to:
  /// **'Removed line {line}: {code}'**
  String diffLineRemoved(int line, String code);

  /// Screen-reader label of an unchanged code line in the PR diff.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: {code}'**
  String diffLineContext(int line, String code);

  /// Screen-reader label of a diff hunk header row ("@@ -1,4 +1,5 @@ ...").
  ///
  /// In en, this message translates to:
  /// **'Hunk {header}'**
  String diffLineHunk(String header);

  /// Read by screen readers in place of an empty code line in the PR diff.
  ///
  /// In en, this message translates to:
  /// **'blank'**
  String get diffLineBlank;

  /// Screen-reader action on a PR diff code line that opens the inline comment composer.
  ///
  /// In en, this message translates to:
  /// **'Comment on this line'**
  String get diffCommentOnLineAction;

  /// Screen-reader announcement after marking a PR diff file viewed.
  ///
  /// In en, this message translates to:
  /// **'{path} marked as viewed'**
  String diffFileMarkedViewedAnnouncement(String path);

  /// Screen-reader announcement after clearing a PR diff file's viewed mark.
  ///
  /// In en, this message translates to:
  /// **'{path} marked as not viewed'**
  String diffFileMarkedNotViewedAnnouncement(String path);

  /// Screen-reader summary of a changed file's added/removed line counts in the PR sidebar.
  ///
  /// In en, this message translates to:
  /// **'Lines added: {additions}, lines removed: {deletions}'**
  String prLineChangesSemantics(int additions, int deletions);

  /// Accessible name of a workbench tab's close button.
  ///
  /// In en, this message translates to:
  /// **'Close {tab}'**
  String closeTabNamed(String tab);

  /// Number of comments in a code review conversation, shown in its header.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String threadCommentCount(int count);

  /// No description provided for @notificationAgentAwaitingInput.
  ///
  /// In en, this message translates to:
  /// **'Agent needs attention'**
  String get notificationAgentAwaitingInput;

  /// No description provided for @notifyAgentAwaitingInput.
  ///
  /// In en, this message translates to:
  /// **'When an agent needs approval, an answer or working credentials, or policy blocks an action'**
  String get notifyAgentAwaitingInput;

  /// No description provided for @notificationAgentNeedsApproval.
  ///
  /// In en, this message translates to:
  /// **'{agent} needs your approval'**
  String notificationAgentNeedsApproval(String agent);

  /// No description provided for @notificationAgentNeedsApprovalUnnamed.
  ///
  /// In en, this message translates to:
  /// **'An agent needs your approval'**
  String get notificationAgentNeedsApprovalUnnamed;

  /// No description provided for @notificationAgentAskedQuestion.
  ///
  /// In en, this message translates to:
  /// **'{agent} has a question'**
  String notificationAgentAskedQuestion(String agent);

  /// No description provided for @notificationAgentAskedQuestionUnnamed.
  ///
  /// In en, this message translates to:
  /// **'An agent has a question'**
  String get notificationAgentAskedQuestionUnnamed;

  /// No description provided for @notificationAgentBlockedOnCredential.
  ///
  /// In en, this message translates to:
  /// **'{agent} is blocked on a credential'**
  String notificationAgentBlockedOnCredential(String agent);

  /// No description provided for @notificationAgentBlockedOnCredentialUnnamed.
  ///
  /// In en, this message translates to:
  /// **'An agent is blocked on a credential'**
  String get notificationAgentBlockedOnCredentialUnnamed;

  /// Title of a reminder notification for an agent wait nobody has answered yet. {title} is the original notification title, e.g. "engineer needs your approval".
  ///
  /// In en, this message translates to:
  /// **'Still waiting: {title}'**
  String notificationWaitReminder(String title);

  /// Tooltip on a sidebar TERMINALS row's trash button that ends the shell.
  ///
  /// In en, this message translates to:
  /// **'Kill terminal'**
  String get killTerminal;

  /// Tooltip on the stop button of a running agent shell command in the sidebar.
  ///
  /// In en, this message translates to:
  /// **'Stop command'**
  String get stopAgentCommand;

  /// Status shown on an agent command row after Stop, until the process exits.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get agentCommandStopping;

  /// Compact sidebar age in seconds
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String sidebarAgeSeconds(int count);

  /// Screen reader label for a running agent shell command row.
  ///
  /// In en, this message translates to:
  /// **'Agent command {command}, running for {elapsed}'**
  String agentCommandSemantics(String command, String elapsed);

  /// Title of the dialog shown while the app has lost its server connection and is retrying.
  ///
  /// In en, this message translates to:
  /// **'Lost connection to the server'**
  String get serverLostTitle;

  /// Body of the lost-connection dialog.
  ///
  /// In en, this message translates to:
  /// **'Control Center keeps trying to reconnect in the background. Try again now, or go to the sign-in screen to pick a server.'**
  String get serverLostBody;

  /// Status line while a reconnect attempt is in flight.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get serverLostRetrying;

  /// Countdown to the next automatic reconnect attempt.
  ///
  /// In en, this message translates to:
  /// **'Next attempt in {seconds}s'**
  String serverLostNextAttempt(int seconds);

  /// Button that retries the server connection immediately.
  ///
  /// In en, this message translates to:
  /// **'Try to reconnect'**
  String get serverLostReconnect;

  /// Button that leaves the app for the server sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Go to sign-in'**
  String get serverLostSignIn;

  /// Title of the dialog shown when the server rejected this device or changed identity, so retrying cannot help.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reconnect to the server'**
  String get serverEndedTitle;

  /// Shutdown dialog subtitle when the server itself is stopping (not stopped by this app).
  ///
  /// In en, this message translates to:
  /// **'The server is stopping'**
  String get shutdownSubtitleServer;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Absent vs available'**
  String get skillEvalAbsent;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Ambient skills'**
  String get skillEvalAmbient;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Artifact reference: {reference}'**
  String skillEvalArtifactRef(String reference);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'{task} · {arm} · repeat {repeat}'**
  String skillEvalAttempt(String task, String arm, int repeat);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get skillEvalAttempts;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get skillEvalAvailableEvent;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Previous revision hash'**
  String get skillEvalBaseline;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Body loaded'**
  String get skillEvalBodyLoad;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Budget (US cents)'**
  String get skillEvalBudgetCents;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Paid evaluation uses the selected provider and budget. Security scan results are separate.'**
  String get skillEvalBudgetNote;

  /// Explains the subscription evaluation stopping threshold and possible in-flight overshoot.
  ///
  /// In en, this message translates to:
  /// **'Subscription budgets track API-equivalent usage, not invoices. An in-flight call may exceed the budget; no further calls start once it is reached. Security scans are separate.'**
  String get skillEvalUsageBudgetNote;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel run'**
  String get skillEvalCancel;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get skillEvalCancelled;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelling'**
  String get skillEvalCancelling;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get skillEvalComparison;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get skillEvalCompleted;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get skillEvalComposition;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Task corpus'**
  String get skillEvalCorpus;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'{corpus} · {repeats} repeats'**
  String skillEvalCoverage(String corpus, int repeats);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'All planned trials observed'**
  String get skillEvalCoverageComplete;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Current package hash: {hash}'**
  String skillEvalCurrentHash(String hash);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Disable update evaluations'**
  String get skillEvalDisableUpdates;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Enable update evaluations'**
  String get skillEvalEnableUpdates;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Copy redacted JSON'**
  String get skillEvalExport;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get skillEvalFailed;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Forced load vs absent'**
  String get skillEvalForced;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Forced load'**
  String get skillEvalForcedEvent;

  /// Label for the content hash of the installed skill revision.
  ///
  /// In en, this message translates to:
  /// **'Package hash'**
  String get skillEvalHashLabel;

  /// Label for how many evaluation attempts have finished.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get skillEvalProgressLabel;

  /// Title of the switch that starts a budgeted evaluation when a skill is saved.
  ///
  /// In en, this message translates to:
  /// **'Update evaluations'**
  String get skillEvalUpdatesToggle;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Package hash unavailable on this server. Evaluation is disabled.'**
  String get skillEvalHashUnavailable;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Revision history'**
  String get skillEvalHistory;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get skillEvalImproved;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get skillEvalIncomplete;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Inconclusive'**
  String get skillEvalInconclusive;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Inferred'**
  String get skillEvalInferred;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get skillEvalInterrupted;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Skill loading not observable; absence of an event does not prove it was ignored.'**
  String get skillEvalLoadUnobserved;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Selected model'**
  String get skillEvalModel;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet.'**
  String get skillEvalNoAttempts;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No connected models available. Connect a provider in Settings first.'**
  String get skillEvalNoModels;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No previous hash in campaign history. Evaluate the previous revision before replacing it.'**
  String get skillEvalNoPrevious;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No report yet; partial attempts remain available.'**
  String get skillEvalNoReport;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No workspace selected.'**
  String get skillEvalNoWorkspace;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No tasks reported yet.'**
  String get skillEvalNoTasks;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'No verifier evidence recorded.'**
  String get skillEvalNoVerifiers;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated for these exact bytes. A scan is not behavioral evidence.'**
  String get skillEvalNotEvaluated;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get skillEvalNotVerified;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get skillEvalObserved;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Open Quality'**
  String get skillEvalOpenQuality;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'By default, saving a skill does not start a paid evaluation. If you explicitly enable automatic update reevaluation, saving starts a budgeted paid evaluation.'**
  String get skillEvalPolicyNote;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Evaluate a revision first to configure the update policy.'**
  String get skillEvalPolicyNeedsCampaign;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Update policy configuration'**
  String get skillEvalPolicyTemplate;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Partial evidence; no adoption verdict'**
  String get skillEvalPartial;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {planned} attempts'**
  String skillEvalProgress(int completed, int planned);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String skillEvalProvider(String provider);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Workspace skill campaigns and revision-specific evidence.'**
  String get skillEvalQualityIntro;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get skillEvalQueued;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to campaign snapshots…'**
  String get skillEvalReconnecting;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get skillEvalRefresh;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Reference loaded'**
  String get skillEvalReferenceLoad;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Repeats per task'**
  String get skillEvalRepetitions;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence report'**
  String get skillEvalReport;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get skillEvalRunning;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Script executed'**
  String get skillEvalScriptExecution;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Spend: {spent} / budget {budget}'**
  String skillEvalSpend(String spent, String budget);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Start evaluation'**
  String get skillEvalStart;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Compare skill revisions'**
  String get skillEvalStartTitle;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get skillEvalStale;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Stale: {reason}'**
  String skillEvalStaleReason(String reason);

  /// Number of distinct task clusters sampled in a skill evaluation; repeated runs of the same task are not independent samples.
  ///
  /// In en, this message translates to:
  /// **'Distinct task clusters: {count}'**
  String skillEvalTaskClusters(String count);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'{rate} ({passes} verified) · {cost}'**
  String skillEvalTaskEvidence(String rate, String passes, String cost);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Tasks by arm'**
  String get skillEvalTasks;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Tool error'**
  String get skillEvalToolError;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Tool events'**
  String get skillEvalTools;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Skill evaluation'**
  String get skillEvalTitle;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: {reason}'**
  String skillEvalUnavailable(String reason);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get skillEvalUnknown;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Unsaved edits are not included. Save before evaluating.'**
  String get skillEvalUnsaved;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Uncertainty interval'**
  String get skillEvalUncertainty;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get skillEvalVerified;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get skillEvalVerifiers;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Verdict'**
  String get skillEvalVerdict;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Copy complete: {filename}'**
  String skillEvalExportCopied(String filename);

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Plan violation'**
  String get skillEvalPlanViolation;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Quality preserved'**
  String get skillEvalPreserved;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Previous vs current'**
  String get skillEvalPrevious;

  /// Skill campaign operator interface.
  ///
  /// In en, this message translates to:
  /// **'Regression demonstrated'**
  String get skillEvalRegressed;

  /// Skill campaign regression type.
  ///
  /// In en, this message translates to:
  /// **'Cost regression'**
  String get skillEvalCostRegression;

  /// Skill campaign regression type.
  ///
  /// In en, this message translates to:
  /// **'Harness error'**
  String get skillEvalHarnessError;

  /// Heading for per-arm observed skill routing.
  ///
  /// In en, this message translates to:
  /// **'Skill routing'**
  String get skillBehaviorRouting;

  /// Observable skill-routing confusion counts. All placeholders are locale-formatted counts or unknown.
  ///
  /// In en, this message translates to:
  /// **'{truePositive} expected uses · {falsePositive} unexpected uses · {falseNegative} missed uses · {trueNegative} correct skips'**
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  );

  /// Uncertain or unavailable routing observations.
  ///
  /// In en, this message translates to:
  /// **'{positive} uncertain uses · {negative} uncertain skips · {notOffered} not offered'**
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  );

  /// Observed routing rates; unknown where denominator is unobservable.
  ///
  /// In en, this message translates to:
  /// **'Observed precision {precision} · recall {recall} · false-positive rate {falsePositiveRate}'**
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  );

  /// Forced skill availability is diagnostic, not organic routing.
  ///
  /// In en, this message translates to:
  /// **'Forced arm · diagnostic only'**
  String get skillBehaviorForced;

  /// Limitations of routing measurement.
  ///
  /// In en, this message translates to:
  /// **'Rates use observable accesses only. Shell or search access may remain unknown; loading a skill does not prove it was applied.'**
  String get skillBehaviorRoutingNote;

  /// Heading for synthetic safety artifact checks.
  ///
  /// In en, this message translates to:
  /// **'Synthetic safety'**
  String get skillBehaviorSafety;

  /// Synthetic artifact passes out of all attempts; denied actions and protected file violations.
  ///
  /// In en, this message translates to:
  /// **'{passes}/{attempts} artifact passes · {denials} policy denials · {violations} protected-file violations'**
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  );

  /// Limitations of synthetic safety measurement.
  ///
  /// In en, this message translates to:
  /// **'Artifact checks are synthetic, not real-world attack rates; actual side effects are not instrumented.'**
  String get skillBehaviorSafetyNote;

  /// Heading for grouped verified utility by task family.
  ///
  /// In en, this message translates to:
  /// **'Utility by family'**
  String get skillBehaviorUtility;

  /// Verified successes out of all attempts including failed and incomplete attempts.
  ///
  /// In en, this message translates to:
  /// **'{verified}/{attempts} verified successes'**
  String skillBehaviorUtilityCounts(String verified, String attempts);

  /// Denominator policy for verified utility.
  ///
  /// In en, this message translates to:
  /// **'All attempts count toward the utility denominator, including failures and incomplete runs.'**
  String get skillBehaviorUtilityNote;

  /// Badge on a Claude Code account a run reported as no longer authenticating
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get claudeAccountSignInFailed;

  /// Title of the dialog listing Claude Code accounts that need signing in
  ///
  /// In en, this message translates to:
  /// **'Sign in to Claude Code'**
  String get claudeSignInDialogTitle;

  /// Explains how to use the login commands in the Claude Code sign-in dialog
  ///
  /// In en, this message translates to:
  /// **'Run each command in a terminal on the server. It opens a browser to finish the login and writes the credential into that account\'s directory.'**
  String get claudeSignInDialogHint;

  /// Shown when no managed Claude Code account needs signing in; followed by the plain login command
  ///
  /// In en, this message translates to:
  /// **'No managed account is signed out. If this agent uses Claude Code\'s own login, run:'**
  String get claudeSignInNoAccounts;

  /// Shown when the login command for a Claude Code account could not be loaded
  ///
  /// In en, this message translates to:
  /// **'The server could not provide a login command for this account.'**
  String get claudeSignInCommandUnavailable;

  /// Badge on a Claude Code account whose sign-in just finished while the sign-in dialog was open. The opposite of the 'Signed out' badge
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get claudeAccountSignedIn;

  /// Line under the login command in the Claude Code sign-in dialog, beside a spinner. The dialog watches for the login the user runs in a terminal and closes itself when it finishes
  ///
  /// In en, this message translates to:
  /// **'This closes on its own once the sign-in finishes.'**
  String get claudeSignInClosesItself;

  /// Same line as claudeSignInClosesItself when the dialog lists several Claude Code accounts, each with its own login command
  ///
  /// In en, this message translates to:
  /// **'This closes on its own once every account is signed in.'**
  String get claudeSignInClosesItselfAll;

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

  /// Label of the help button in the sidebar footer, and the heading of its menu
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpMenuLabel;

  /// Help menu item and dialog title showing the release notes
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get helpWhatsNew;

  /// Heading of the help menu section for reporting a bug
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get helpReportProblem;

  /// Help menu item that opens a new GitHub issue in the browser
  ///
  /// In en, this message translates to:
  /// **'Create a GitHub issue'**
  String get helpCreateGitHubIssue;

  /// Tag beside the release the user is running in the release notes dialog
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get changelogInstalled;

  /// Heading above the new features of a release in the release notes dialog
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get changelogGroupNew;

  /// Heading above the improvements of a release in the release notes dialog
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get changelogGroupImproved;

  /// Heading above the bug fixes of a release in the release notes dialog
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get changelogGroupFixed;

  /// Shown in the release notes dialog when the release notes could not be fetched
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the release notes.'**
  String get changelogLoadFailed;

  /// Tooltip of the button opening the release notes on the website
  ///
  /// In en, this message translates to:
  /// **'Open on the website'**
  String get changelogOpenWebsite;

  /// Heading of the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Control Center'**
  String get connectWelcomeTitle;

  /// Sentence under the login heading on desktop, which can run its own server
  ///
  /// In en, this message translates to:
  /// **'Run it here, or connect to a server you already have.'**
  String get connectWelcomeSubtitle;

  /// Sentence under the login heading on web, which can only connect to a server
  ///
  /// In en, this message translates to:
  /// **'Connect to your server to get started.'**
  String get connectWelcomeSubtitleWeb;

  /// Login action and dialog title for connecting to a server by its address
  ///
  /// In en, this message translates to:
  /// **'Connect to a server'**
  String get connectToServer;

  /// One line at the top of the connect-to-a-server dialog
  ///
  /// In en, this message translates to:
  /// **'Enter the address of a Control Center server.'**
  String get connectToServerIntro;

  /// Disclosure that reveals the device id and pairing key fields
  ///
  /// In en, this message translates to:
  /// **'Use a pairing key'**
  String get connectUsePairingKey;

  /// Login action and dialog title for connecting with a pasted link
  ///
  /// In en, this message translates to:
  /// **'Paste a pairing link'**
  String get connectPasteLink;

  /// One line at the top of the paste-a-link dialog
  ///
  /// In en, this message translates to:
  /// **'Paste the invite or pairing link you were given.'**
  String get connectPasteLinkIntro;

  /// Label of the field that takes a pasted link
  ///
  /// In en, this message translates to:
  /// **'Invite or pairing link'**
  String get connectPasteLinkLabel;

  /// Validation error when the pasted text is not a usable link
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a Control Center invite or pairing link. Copy the whole link and try again.'**
  String get connectPasteLinkInvalid;

  /// Label above the server address a pasted link will connect to
  ///
  /// In en, this message translates to:
  /// **'Connects to'**
  String get connectPasteLinkTarget;

  /// Menu item in the sidebar that ends the running focus session
  ///
  /// In en, this message translates to:
  /// **'End focus session'**
  String get focusModeEnd;

  /// Time left in the running focus session, shown as the tooltip and menu heading of its sidebar entry
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String focusModeRemaining(int minutes);

  /// Space environments: demoUnavailableEnvironments
  ///
  /// In en, this message translates to:
  /// **'Environments run real processes on the host, so the demo has none.'**
  String get demoUnavailableEnvironments;

  /// Space environments: environmentChecksFailing
  ///
  /// In en, this message translates to:
  /// **'Some checks are failing on the server'**
  String get environmentChecksFailing;

  /// Space environments: environmentCliEndpoints
  ///
  /// In en, this message translates to:
  /// **'Endpoints: {names}'**
  String environmentCliEndpoints(String names);

  /// Space environments: environmentCliServices
  ///
  /// In en, this message translates to:
  /// **'Services: {names}'**
  String environmentCliServices(String names);

  /// Space environments: environmentCopied
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get environmentCopied;

  /// Space environments: environmentCopyCommand
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get environmentCopyCommand;

  /// Space environments: environmentCopyUrl
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get environmentCopyUrl;

  /// Space environments: environmentDefinition
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get environmentDefinition;

  /// Space environments: environmentDefinitionCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 definition} other{{count} definitions}}'**
  String environmentDefinitionCount(int count);

  /// Space environments: environmentDestroy
  ///
  /// In en, this message translates to:
  /// **'Destroy'**
  String get environmentDestroy;

  /// Space environments: environmentDestroyBody
  ///
  /// In en, this message translates to:
  /// **'{name} and its data are removed. Start creates a new one.'**
  String environmentDestroyBody(String name);

  /// Space environments: environmentDestroyTitle
  ///
  /// In en, this message translates to:
  /// **'Destroy this environment?'**
  String get environmentDestroyTitle;

  /// Space environments: environmentExec
  ///
  /// In en, this message translates to:
  /// **'Exec'**
  String get environmentExec;

  /// Space environments: environmentExecTitle
  ///
  /// In en, this message translates to:
  /// **'Run in a service'**
  String get environmentExecTitle;

  /// Space environments: environmentExitCode
  ///
  /// In en, this message translates to:
  /// **'Exit code {code}'**
  String environmentExitCode(int code);

  /// Heading of a notice on an environment whose start stopped because its tool needs an answer only a person at a terminal on the server can give, for example a sudo password.
  ///
  /// In en, this message translates to:
  /// **'This needs setting up on the server'**
  String get environmentInputNeeded;

  /// Space environments: environmentKindApp
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get environmentKindApp;

  /// Space environments: environmentKindCli
  ///
  /// In en, this message translates to:
  /// **'CLI'**
  String get environmentKindCli;

  /// Space environments: environmentKindCompose
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get environmentKindCompose;

  /// Space environments: environmentKindProcess
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get environmentKindProcess;

  /// Space environments: environmentKindTask
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get environmentKindTask;

  /// Space environments: environmentLaunch
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get environmentLaunch;

  /// Space environments: environmentLogsGone
  ///
  /// In en, this message translates to:
  /// **'These logs are no longer available.'**
  String get environmentLogsGone;

  /// Space environments: environmentLogsTab
  ///
  /// In en, this message translates to:
  /// **'Logs: {name}'**
  String environmentLogsTab(String name);

  /// Space environments: environmentLogsWaiting
  ///
  /// In en, this message translates to:
  /// **'Waiting for output'**
  String get environmentLogsWaiting;

  /// Space environments: environmentMoreActions
  ///
  /// In en, this message translates to:
  /// **'More environment actions'**
  String get environmentMoreActions;

  /// Space environments: environmentNeedsRecreate
  ///
  /// In en, this message translates to:
  /// **'A change needs this environment recreated.'**
  String get environmentNeedsRecreate;

  /// Space environments: environmentNoStack
  ///
  /// In en, this message translates to:
  /// **'Runs worktree tasks only, so there is nothing to start.'**
  String get environmentNoStack;

  /// Space environments: environmentOnTheServer
  ///
  /// In en, this message translates to:
  /// **'On the server'**
  String get environmentOnTheServer;

  /// Space environments: environmentOpenInBrowserVm
  ///
  /// In en, this message translates to:
  /// **'Open in Browser (VM)'**
  String get environmentOpenInBrowserVm;

  /// Space environments: environmentOpenViewer
  ///
  /// In en, this message translates to:
  /// **'Open viewer'**
  String get environmentOpenViewer;

  /// Space environments: environmentPlacementRig
  ///
  /// In en, this message translates to:
  /// **'In a VM'**
  String get environmentPlacementRig;

  /// Space environments: environmentPreviewTab
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentPreviewTab;

  /// Space environments: environmentRebuildRelaunch
  ///
  /// In en, this message translates to:
  /// **'Rebuild & relaunch'**
  String get environmentRebuildRelaunch;

  /// Space environments: environmentRecreate
  ///
  /// In en, this message translates to:
  /// **'Recreate'**
  String get environmentRecreate;

  /// Space environments: environmentRecreateBody
  ///
  /// In en, this message translates to:
  /// **'{name} is destroyed and started again with the same options. Its data is lost.'**
  String environmentRecreateBody(String name);

  /// Space environments: environmentRecreateTitle
  ///
  /// In en, this message translates to:
  /// **'Recreate this environment?'**
  String get environmentRecreateTitle;

  /// Space environments: environmentResetBody
  ///
  /// In en, this message translates to:
  /// **'{name} returns to its baseline. Data created since then is lost.'**
  String environmentResetBody(String name);

  /// Space environments: environmentResetData
  ///
  /// In en, this message translates to:
  /// **'Reset data'**
  String get environmentResetData;

  /// Space environments: environmentResetTitle
  ///
  /// In en, this message translates to:
  /// **'Reset data?'**
  String get environmentResetTitle;

  /// Space environments: environmentRestart
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get environmentRestart;

  /// Space environments: environmentRestarts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 restart} other{{count} restarts}}'**
  String environmentRestarts(int count);

  /// Space environments: environmentRun
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get environmentRun;

  /// Space environments: environmentRunInTerminal
  ///
  /// In en, this message translates to:
  /// **'Run in terminal'**
  String get environmentRunInTerminal;

  /// Space environments: environmentSectionTitle
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentSectionTitle;

  /// Space environments: environmentService
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get environmentService;

  /// Space environments: environmentServiceActions
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String environmentServiceActions(String name);

  /// Space environments: environmentStartTitle
  ///
  /// In en, this message translates to:
  /// **'Start environment'**
  String get environmentStartTitle;

  /// Space environments: environmentStateCrashed
  ///
  /// In en, this message translates to:
  /// **'Crashed'**
  String get environmentStateCrashed;

  /// Space environments: environmentStatusDegraded
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get environmentStatusDegraded;

  /// Space environments: environmentStatusDestroying
  ///
  /// In en, this message translates to:
  /// **'Destroying'**
  String get environmentStatusDestroying;

  /// Space environments: environmentStatusGone
  ///
  /// In en, this message translates to:
  /// **'Gone'**
  String get environmentStatusGone;

  /// Space environments: environmentStatusStopping
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get environmentStatusStopping;

  /// Space environments: environmentStopDataLoss
  ///
  /// In en, this message translates to:
  /// **'Stopping {name} loses its data, and Start won\'t bring it back.'**
  String environmentStopDataLoss(String name);

  /// Space environments: environmentStopLoseData
  ///
  /// In en, this message translates to:
  /// **'Stop and lose data'**
  String get environmentStopLoseData;

  /// Space environments: environmentStopTitle
  ///
  /// In en, this message translates to:
  /// **'Stop this environment?'**
  String get environmentStopTitle;

  /// Space environments: environmentTaskNeverRun
  ///
  /// In en, this message translates to:
  /// **'Not run yet'**
  String get environmentTaskNeverRun;

  /// Space environments: environmentsAddCheck
  ///
  /// In en, this message translates to:
  /// **'Add check'**
  String get environmentsAddCheck;

  /// Space environments: environmentsAddOption
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get environmentsAddOption;

  /// Space environments: environmentsAddRole
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get environmentsAddRole;

  /// Space environments: environmentsAdminOnly
  ///
  /// In en, this message translates to:
  /// **'Only workspace admins can change definitions.'**
  String get environmentsAdminOnly;

  /// Space environments: environmentsAfter
  ///
  /// In en, this message translates to:
  /// **'Wait for these components'**
  String get environmentsAfter;

  /// Space environments: environmentsAnchor
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get environmentsAnchor;

  /// Space environments: environmentsAutoCreate
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get environmentsAutoCreate;

  /// Space environments: environmentsAutoCreateAll
  ///
  /// In en, this message translates to:
  /// **'In every eligible space'**
  String get environmentsAutoCreateAll;

  /// Space environments: environmentsAutoCreateOff
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get environmentsAutoCreateOff;

  /// Space environments: environmentsAutoCreatePrs
  ///
  /// In en, this message translates to:
  /// **'In pull request spaces'**
  String get environmentsAutoCreatePrs;

  /// Space environments: environmentsBlank
  ///
  /// In en, this message translates to:
  /// **'Blank definition'**
  String get environmentsBlank;

  /// Space environments: environmentsCheckFix
  ///
  /// In en, this message translates to:
  /// **'Fix command'**
  String get environmentsCheckFix;

  /// Space environments: environmentsCheckHint
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get environmentsCheckHint;

  /// Space environments: environmentsCommandHelp
  ///
  /// In en, this message translates to:
  /// **'Arguments are separated by spaces. Quote one that contains a space.'**
  String get environmentsCommandHelp;

  /// Space environments: environmentsComponentCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 component} other{{count} components}}'**
  String environmentsComponentCount(int count);

  /// Space environments: environmentsComponentId
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get environmentsComponentId;

  /// Space environments: environmentsComposeBuild
  ///
  /// In en, this message translates to:
  /// **'Build images on start'**
  String get environmentsComposeBuild;

  /// Space environments: environmentsComposeFile
  ///
  /// In en, this message translates to:
  /// **'Compose file'**
  String get environmentsComposeFile;

  /// Space environments: environmentsComposeHttp
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get environmentsComposeHttp;

  /// Space environments: environmentsComposeNoFile
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read a compose file. Service names can still go in the JSON view.'**
  String get environmentsComposeNoFile;

  /// Space environments: environmentsComposeServices
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get environmentsComposeServices;

  /// Space environments: environmentsComposeServicesHint
  ///
  /// In en, this message translates to:
  /// **'Leave every service unchecked to run them all.'**
  String get environmentsComposeServicesHint;

  /// Space environments: environmentsConditionalArgs
  ///
  /// In en, this message translates to:
  /// **'This command has conditional arguments. Edit it in the JSON view.'**
  String get environmentsConditionalArgs;

  /// Space environments: environmentsCwdPath
  ///
  /// In en, this message translates to:
  /// **'Working path'**
  String get environmentsCwdPath;

  /// Space environments: environmentsCwdRole
  ///
  /// In en, this message translates to:
  /// **'Working role'**
  String get environmentsCwdRole;

  /// Space environments: environmentsDeleteBody
  ///
  /// In en, this message translates to:
  /// **'Spaces can no longer start it. Running environments keep running until they are stopped.'**
  String get environmentsDeleteBody;

  /// Space environments: environmentsDeleteTitle
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String environmentsDeleteTitle(String name);

  /// Space environments: environmentsDescription
  ///
  /// In en, this message translates to:
  /// **'What each space can start, and the tasks its worktrees run.'**
  String get environmentsDescription;

  /// Space environments: environmentsDraftFromRepo
  ///
  /// In en, this message translates to:
  /// **'Draft from repo'**
  String get environmentsDraftFromRepo;

  /// Space environments: environmentsEmpty
  ///
  /// In en, this message translates to:
  /// **'No definitions yet'**
  String get environmentsEmpty;

  /// Space environments: environmentsEnabledWhen
  ///
  /// In en, this message translates to:
  /// **'Enabled when'**
  String get environmentsEnabledWhen;

  /// Space environments: environmentsEndpointRole
  ///
  /// In en, this message translates to:
  /// **'Endpoint role'**
  String get environmentsEndpointRole;

  /// Space environments: environmentsFollowPrHead
  ///
  /// In en, this message translates to:
  /// **'Follow the pull request\'s head'**
  String get environmentsFollowPrHead;

  /// Space environments: environmentsForkApproval
  ///
  /// In en, this message translates to:
  /// **'Each start needs an admin'**
  String get environmentsForkApproval;

  /// Space environments: environmentsForkDeny
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get environmentsForkDeny;

  /// Space environments: environmentsForkPrs
  ///
  /// In en, this message translates to:
  /// **'Fork pull requests'**
  String get environmentsForkPrs;

  /// Space environments: environmentsForkRig
  ///
  /// In en, this message translates to:
  /// **'Run in a VM'**
  String get environmentsForkRig;

  /// Space environments: environmentsIdleStop
  ///
  /// In en, this message translates to:
  /// **'Stop after idle minutes'**
  String get environmentsIdleStop;

  /// Space environments: environmentsIsolateHome
  ///
  /// In en, this message translates to:
  /// **'Give the app a private home'**
  String get environmentsIsolateHome;

  /// Space environments: environmentsIssues
  ///
  /// In en, this message translates to:
  /// **'Fix these before saving'**
  String get environmentsIssues;

  /// Space environments: environmentsJsonInvalid
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON: {error}'**
  String environmentsJsonInvalid(String error);

  /// Space environments: environmentsKeepsData
  ///
  /// In en, this message translates to:
  /// **'Keeps its data when stopped'**
  String get environmentsKeepsData;

  /// Space environments: environmentsLinkConfirm
  ///
  /// In en, this message translates to:
  /// **'Link and approve'**
  String get environmentsLinkConfirm;

  /// Space environments: environmentsLinkFile
  ///
  /// In en, this message translates to:
  /// **'Link a repo file'**
  String get environmentsLinkFile;

  /// Space environments: environmentsLinkHelp
  ///
  /// In en, this message translates to:
  /// **'Read from the default branch only, and run only once approved.'**
  String get environmentsLinkHelp;

  /// Space environments: environmentsLinkPath
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get environmentsLinkPath;

  /// Space environments: environmentsMaxRunning
  ///
  /// In en, this message translates to:
  /// **'Running at once'**
  String get environmentsMaxRunning;

  /// Space environments: environmentsNamingProject
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get environmentsNamingProject;

  /// Space environments: environmentsNamingTemplate
  ///
  /// In en, this message translates to:
  /// **'Name template'**
  String get environmentsNamingTemplate;

  /// Space environments: environmentsNew
  ///
  /// In en, this message translates to:
  /// **'New definition'**
  String get environmentsNew;

  /// Space environments: environmentsNewDefinitionName
  ///
  /// In en, this message translates to:
  /// **'New environment'**
  String get environmentsNewDefinitionName;

  /// Space environments: environmentsNoChecks
  ///
  /// In en, this message translates to:
  /// **'This definition has no checks.'**
  String get environmentsNoChecks;

  /// Space environments: environmentsNoRuns
  ///
  /// In en, this message translates to:
  /// **'No test runs yet'**
  String get environmentsNoRuns;

  /// Space environments: environmentsOnChange
  ///
  /// In en, this message translates to:
  /// **'Paths to watch'**
  String get environmentsOnChange;

  /// Space environments: environmentsOptionBool
  ///
  /// In en, this message translates to:
  /// **'Yes or no'**
  String get environmentsOptionBool;

  /// Space environments: environmentsOptionEnum
  ///
  /// In en, this message translates to:
  /// **'One of'**
  String get environmentsOptionEnum;

  /// Space environments: environmentsOptionMulti
  ///
  /// In en, this message translates to:
  /// **'Several of'**
  String get environmentsOptionMulti;

  /// Space environments: environmentsOptionValues
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get environmentsOptionValues;

  /// Space environments: environmentsPlacement
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get environmentsPlacement;

  /// Space environments: environmentsPlacementHost
  ///
  /// In en, this message translates to:
  /// **'On the host'**
  String get environmentsPlacementHost;

  /// Space environments: environmentsPlacementRig
  ///
  /// In en, this message translates to:
  /// **'In a VM'**
  String get environmentsPlacementRig;

  /// Space environments: environmentsPrepareTask
  ///
  /// In en, this message translates to:
  /// **'Prepare task'**
  String get environmentsPrepareTask;

  /// Space environments: environmentsPrimaryEndpoint
  ///
  /// In en, this message translates to:
  /// **'Primary endpoint'**
  String get environmentsPrimaryEndpoint;

  /// Space environments: environmentsReadyHttp
  ///
  /// In en, this message translates to:
  /// **'Ready when this URL answers'**
  String get environmentsReadyHttp;

  /// Space environments: environmentsRestartAlways
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get environmentsRestartAlways;

  /// Space environments: environmentsRestartNever
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get environmentsRestartNever;

  /// Space environments: environmentsRestartOn
  ///
  /// In en, this message translates to:
  /// **'Restart when these paths change'**
  String get environmentsRestartOn;

  /// Space environments: environmentsRestartOnFailure
  ///
  /// In en, this message translates to:
  /// **'On failure'**
  String get environmentsRestartOnFailure;

  /// Space environments: environmentsRestartPolicy
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get environmentsRestartPolicy;

  /// Space environments: environmentsRigTtl
  ///
  /// In en, this message translates to:
  /// **'VM lifetime in hours'**
  String get environmentsRigTtl;

  /// Space environments: environmentsRunChecks
  ///
  /// In en, this message translates to:
  /// **'Run again'**
  String get environmentsRunChecks;

  /// Space environments: environmentsRunTest
  ///
  /// In en, this message translates to:
  /// **'Run test'**
  String get environmentsRunTest;

  /// Space environments: environmentsSaved
  ///
  /// In en, this message translates to:
  /// **'Definition saved'**
  String get environmentsSaved;

  /// Space environments: environmentsSectionComponents
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get environmentsSectionComponents;

  /// Space environments: environmentsSectionOptions
  ///
  /// In en, this message translates to:
  /// **'Start options'**
  String get environmentsSectionOptions;

  /// Space environments: environmentsSectionSeedFiles
  ///
  /// In en, this message translates to:
  /// **'Seed files'**
  String get environmentsSectionSeedFiles;

  /// Space environments: environmentsSectionVariables
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get environmentsSectionVariables;

  /// Space environments: environmentsSeedHelp
  ///
  /// In en, this message translates to:
  /// **'One path per line, copied from the registered checkout. Fork pull requests never receive these.'**
  String get environmentsSeedHelp;

  /// Space environments: environmentsShellHelp
  ///
  /// In en, this message translates to:
  /// **'Placeholders aren\'t expanded here. Read CC_ENV_* variables instead.'**
  String get environmentsShellHelp;

  /// Space environments: environmentsSourceApprove
  ///
  /// In en, this message translates to:
  /// **'Approve this version'**
  String get environmentsSourceApprove;

  /// Space environments: environmentsSourceCurrent
  ///
  /// In en, this message translates to:
  /// **'{path} matches the approved version.'**
  String environmentsSourceCurrent(String path);

  /// Space environments: environmentsSourceNotice
  ///
  /// In en, this message translates to:
  /// **'The approved version keeps running until you approve this one.'**
  String get environmentsSourceNotice;

  /// Space environments: environmentsTabJson
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get environmentsTabJson;

  /// Space environments: environmentsTabSource
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get environmentsTabSource;

  /// Space environments: environmentsTestHelp
  ///
  /// In en, this message translates to:
  /// **'Runs a throwaway environment end to end: check, start, wait for ready, destroy.'**
  String get environmentsTestHelp;

  /// Space environments: environmentsTestSaveFirst
  ///
  /// In en, this message translates to:
  /// **'Save the definition first.'**
  String get environmentsTestSaveFirst;

  /// Space environments: environmentsTimeoutSeconds
  ///
  /// In en, this message translates to:
  /// **'Timeout in seconds'**
  String get environmentsTimeoutSeconds;

  /// Space environments: environmentsTitle
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get environmentsTitle;

  /// Space environments: environmentsTriggerArchive
  ///
  /// In en, this message translates to:
  /// **'Before the worktree is deleted'**
  String get environmentsTriggerArchive;

  /// Space environments: environmentsTriggerChange
  ///
  /// In en, this message translates to:
  /// **'When watched paths change'**
  String get environmentsTriggerChange;

  /// Space environments: environmentsTriggerCreate
  ///
  /// In en, this message translates to:
  /// **'Once per environment'**
  String get environmentsTriggerCreate;

  /// Space environments: environmentsTriggerManual
  ///
  /// In en, this message translates to:
  /// **'On request'**
  String get environmentsTriggerManual;

  /// Space environments: environmentsTriggerProvision
  ///
  /// In en, this message translates to:
  /// **'When the worktree is created'**
  String get environmentsTriggerProvision;

  /// Space environments: environmentsTriggerStart
  ///
  /// In en, this message translates to:
  /// **'On every start'**
  String get environmentsTriggerStart;

  /// Space environments: environmentsTriggers
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get environmentsTriggers;

  /// Space environments: environmentsUnreadable
  ///
  /// In en, this message translates to:
  /// **'This client can\'t read this definition.'**
  String get environmentsUnreadable;

  /// Space environments: environmentsUpdateAvailable
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get environmentsUpdateAvailable;

  /// Space environments: environmentsUseShell
  ///
  /// In en, this message translates to:
  /// **'Use a shell command'**
  String get environmentsUseShell;

  /// Space environments: environmentsUseSourceWarning
  ///
  /// In en, this message translates to:
  /// **'The tool then runs against your own checkout. Treat it as read-only.'**
  String get environmentsUseSourceWarning;

  /// Space environments: environmentsWhenMissing
  ///
  /// In en, this message translates to:
  /// **'When a space lacks it'**
  String get environmentsWhenMissing;

  /// Space environments: environmentsWhenMissingAdd
  ///
  /// In en, this message translates to:
  /// **'Add it to the space'**
  String get environmentsWhenMissingAdd;

  /// Space environments: environmentsWhenMissingSkip
  ///
  /// In en, this message translates to:
  /// **'Skip it'**
  String get environmentsWhenMissingSkip;

  /// Space environments: environmentsWhenMissingSource
  ///
  /// In en, this message translates to:
  /// **'Use the registered checkout'**
  String get environmentsWhenMissingSource;

  /// Space environments: environmentsUnsupported
  ///
  /// In en, this message translates to:
  /// **'This server doesn\'t support environments.'**
  String get environmentsUnsupported;

  /// Space environments: environmentViewerUnavailable
  ///
  /// In en, this message translates to:
  /// **'No viewer: the server can\'t capture this window. Allow Screen Recording for Control Center on the server.'**
  String get environmentViewerUnavailable;

  /// Space environments: environmentHealthHealthy
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get environmentHealthHealthy;

  /// Space environments: environmentHealthUnhealthy
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get environmentHealthUnhealthy;

  /// Space environments: environmentTerminalStale
  ///
  /// In en, this message translates to:
  /// **'This terminal opened before the environment started, so it lacks its variables.'**
  String get environmentTerminalStale;

  /// Space environments: environmentTerminalFresh
  ///
  /// In en, this message translates to:
  /// **'Open a fresh terminal'**
  String get environmentTerminalFresh;

  /// Space environments: environmentsShellStays
  ///
  /// In en, this message translates to:
  /// **'A multi-line script stays a shell command: its lines are its structure.'**
  String get environmentsShellStays;

  /// Space environments: environmentsOverrides
  ///
  /// In en, this message translates to:
  /// **'Workspace overrides'**
  String get environmentsOverrides;

  /// Space environments: environmentsOverridesHelp
  ///
  /// In en, this message translates to:
  /// **'The file\'s own settings are read-only here. Bind its roles to this workspace\'s repos, or override any field as JSON.'**
  String get environmentsOverridesHelp;

  /// Space environments: environmentsReposHelp
  ///
  /// In en, this message translates to:
  /// **'The repositories this environment uses, each bound to a role.'**
  String get environmentsReposHelp;

  /// Space environments: environmentsComponentsHelp
  ///
  /// In en, this message translates to:
  /// **'What the environment runs, in start order.'**
  String get environmentsComponentsHelp;

  /// Space environments: environmentsOptionsHelp
  ///
  /// In en, this message translates to:
  /// **'Choices offered when someone starts the environment.'**
  String get environmentsOptionsHelp;

  /// Space environments: environmentsVariablesHelp
  ///
  /// In en, this message translates to:
  /// **'Set on tasks, processes, apps and space terminals.'**
  String get environmentsVariablesHelp;

  /// Space environments: environmentsChecksHelp
  ///
  /// In en, this message translates to:
  /// **'What the host needs for this environment to run.'**
  String get environmentsChecksHelp;

  /// Space environments: environmentsIdleStopHelp
  ///
  /// In en, this message translates to:
  /// **'0 never stops it.'**
  String get environmentsIdleStopHelp;

  /// Space environments: environmentsAnchorHelp
  ///
  /// In en, this message translates to:
  /// **'A space holding this repository can start the environment.'**
  String get environmentsAnchorHelp;

  /// Space environments: environmentsRequiredHelp
  ///
  /// In en, this message translates to:
  /// **'The environment can\'t run without it.'**
  String get environmentsRequiredHelp;

  /// Space environments: environmentsFollowPrHeadHelp
  ///
  /// In en, this message translates to:
  /// **'Sync and refresh when the pull request\'s head moves.'**
  String get environmentsFollowPrHeadHelp;

  /// Space environments: environmentsRecordNeedsFix
  ///
  /// In en, this message translates to:
  /// **'Needs a fix'**
  String get environmentsRecordNeedsFix;

  /// Space environments: environmentsCheckFile
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get environmentsCheckFile;

  /// Space environments: environmentsDiscardBody
  ///
  /// In en, this message translates to:
  /// **'Your edits to this definition will be lost.'**
  String get environmentsDiscardBody;

  /// Space environments: environmentsWorktreeRuns
  ///
  /// In en, this message translates to:
  /// **'Worktree task runs'**
  String get environmentsWorktreeRuns;

  /// Space environments: environmentsNoWorktreeRuns
  ///
  /// In en, this message translates to:
  /// **'No worktree task has run yet.'**
  String get environmentsNoWorktreeRuns;

  /// Space environments: environmentsLinkRoles
  ///
  /// In en, this message translates to:
  /// **'Roles in this file'**
  String get environmentsLinkRoles;

  /// Space environments: environmentsLinkNoFile
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file from the repo. Roles can be bound after linking.'**
  String get environmentsLinkNoFile;

  /// Guardrail action class: running commands on the host outside any sandbox, at an agent's request
  ///
  /// In en, this message translates to:
  /// **'Run commands on the host'**
  String get guardrailClassHostExecution;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'URLs'**
  String get environmentUrls;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get environmentScripts;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'No environment for this space'**
  String get environmentNoneForSpace;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'No environment for this pull request'**
  String get environmentNoneForPr;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'An environment runs a repo\'s services, scripts and URLs for one space. Set it up once and every space on the repo can start it.'**
  String get environmentSetupBody;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'Set up environment'**
  String get environmentSetUp;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'Edit definition'**
  String get environmentEditDefinition;

  /// Environment panel copy.
  ///
  /// In en, this message translates to:
  /// **'Open environment'**
  String get environmentOpenPanel;

  /// Status of an environment whose start stopped for something only a person can do: an answer at a terminal such as a sudo password, a sign-in, or a missing dependency. Nothing is broken. Shown in a small status tag, so keep it to two or three words.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get environmentStatusBlocked;

  /// State of one part of an environment while its tool runs on a terminal tab and waits for the person to answer it. Shown next to a status dot, so keep it to two or three words.
  ///
  /// In en, this message translates to:
  /// **'In terminal'**
  String get environmentStateInTerminal;

  /// Heading of a notice on an environment that is still starting: one step of the start runs on a terminal tab and waits for the person to type a password or answer a prompt.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you in a terminal'**
  String get environmentWaitingInTerminal;

  /// Button that opens the terminal tab a start is waiting on.
  ///
  /// In en, this message translates to:
  /// **'Open terminal'**
  String get environmentOpenTerminal;

  /// Heading of a notice on an environment whose start stopped because the tool behind it needs the person to sign in again, for example an expired cloud session.
  ///
  /// In en, this message translates to:
  /// **'This needs you to sign in'**
  String get environmentSignInNeeded;

  /// Heading of a notice on an environment whose start stopped because something it depends on is missing or not running, for example Docker. The tool's own explanation follows below it.
  ///
  /// In en, this message translates to:
  /// **'Something this needs is not available'**
  String get environmentDependencyNeeded;

  /// Heading of a notice on a terminal tab after the tool got the answer it needed there. The terminal has gone quiet, and the rest of the start happens in the background.
  ///
  /// In en, this message translates to:
  /// **'Done here. The environment is still starting'**
  String get environmentStartTerminalDone;

  /// Environment host setup: the terminal tab a stopped start finishes in.
  ///
  /// In en, this message translates to:
  /// **'Continue in terminal'**
  String get environmentContinueInTerminal;

  /// Body of a notice shown while one step of a start runs on a terminal tab: the tool asks there for a password or an answer, and the start carries on by itself once it has it.
  ///
  /// In en, this message translates to:
  /// **'The tool needs you in a terminal, for a password or a prompt. Starting carries on when it finishes.'**
  String get environmentStartTerminalHint;

  /// Heading of the notice on a terminal tab that opened by itself after a Start stopped for a person. Says why the tab appeared.
  ///
  /// In en, this message translates to:
  /// **'This terminal opened because the start needs you'**
  String get environmentStartTerminalReason;

  /// Title of the terminal tab a start runs on when its tool needs the person, for example for a sudo password. A tab title, so keep it to two or three words.
  ///
  /// In en, this message translates to:
  /// **'Environment setup'**
  String get environmentStartTerminalTab;

  /// Empty state of the Running tab of an environment definition.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running from this definition.'**
  String get environmentsNothingRunning;

  /// Placeholder for the policy search field.
  ///
  /// In en, this message translates to:
  /// **'Search policies...'**
  String get searchPoliciesHint;

  /// Empty state when a policy search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No policies match your search'**
  String get noPoliciesMatch;

  /// Label for a memory policy being switched on.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get memoryPolicyActive;

  /// Label for the kind of a memory fact, such as instruction or error.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get memoryFactType;

  /// How many times agents have recalled a memory fact.
  ///
  /// In en, this message translates to:
  /// **'Times recalled'**
  String get memoryTimesRecalled;

  /// Heading above the facts a memory policy was derived from.
  ///
  /// In en, this message translates to:
  /// **'Source facts'**
  String get memorySourceFacts;

  /// Title of the tab following what a space's workspace preparation prints: the copy, the fetch, the checkout and any setup tasks.
  ///
  /// In en, this message translates to:
  /// **'Setup logs'**
  String get spaceSetupLogs;

  /// No description provided for @claudeCompactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Compaction'**
  String get claudeCompactionTitle;

  /// No description provided for @claudeCompactionDescription.
  ///
  /// In en, this message translates to:
  /// **'How Claude Code keeps long conversations within its context window.'**
  String get claudeCompactionDescription;

  /// No description provided for @claudeAutoCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-compact after'**
  String get claudeAutoCompactLabel;

  /// No description provided for @claudeAutoCompactHint.
  ///
  /// In en, this message translates to:
  /// **'Tokens, from {min} to {max}. Leave empty to use Claude Code\'s default.'**
  String claudeAutoCompactHint(String min, String max);

  /// No description provided for @claudeAutoCompactInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}.'**
  String claudeAutoCompactInvalid(String min, String max);

  /// No description provided for @claudeIdleCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'Compact idle conversations'**
  String get claudeIdleCompactLabel;

  /// No description provided for @claudeIdleCompactDescription.
  ///
  /// In en, this message translates to:
  /// **'Compacts a conversation over {threshold} tokens just before its prompt cache expires, so coming back to it costs less. Each compaction uses your plan.'**
  String claudeIdleCompactDescription(String threshold);

  /// No description provided for @claudeCompactionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this setting.'**
  String get claudeCompactionSaveFailed;

  /// Settings sidebar entry (under You) for the desktop app's tray, closing and login behaviour
  ///
  /// In en, this message translates to:
  /// **'Desktop app'**
  String get navDesktopApp;

  /// Subtitle of the Settings → Desktop app page
  ///
  /// In en, this message translates to:
  /// **'The tray icon, closing the window and opening at login.'**
  String get desktopAppSettingsSubtitle;

  /// macOS: section label for the menu bar (status item) icon settings
  ///
  /// In en, this message translates to:
  /// **'Menu bar'**
  String get desktopSectionMenuBar;

  /// Windows/Linux: section label for the system tray icon settings
  ///
  /// In en, this message translates to:
  /// **'System tray'**
  String get desktopSectionTray;

  /// macOS: switch that shows the app's icon in the menu bar
  ///
  /// In en, this message translates to:
  /// **'Show in the menu bar'**
  String get desktopTrayTitleMac;

  /// Windows/Linux: switch that shows the app's icon in the system tray
  ///
  /// In en, this message translates to:
  /// **'Show in the system tray'**
  String get desktopTrayTitle;

  /// Explains what the tray/menu bar icon offers
  ///
  /// In en, this message translates to:
  /// **'Status, what needs you, your spaces and plan usage, one click away.'**
  String get desktopTraySubtitle;

  /// Linux: warning title when the desktop shows no tray icons
  ///
  /// In en, this message translates to:
  /// **'No system tray found'**
  String get desktopTrayMissingTitle;

  /// Linux: how to get a tray. 'GNOME', 'AppIndicator' and 'Control Center' are names, keep them as-is
  ///
  /// In en, this message translates to:
  /// **'This desktop doesn\'t show tray icons. On GNOME, install the AppIndicator extension, then restart Control Center.'**
  String get desktopTrayMissingBody;

  /// Section label for what the window's close button does
  ///
  /// In en, this message translates to:
  /// **'Closing the window'**
  String get desktopSectionClosing;

  /// Label of the choice between keeping the app running and quitting when the main window is closed
  ///
  /// In en, this message translates to:
  /// **'When you close the window'**
  String get desktopCloseTitle;

  /// Segment: closing the window hides it and the app keeps running. Short, fits a segmented control
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get desktopCloseKeepRunning;

  /// Segment: closing the window quits the app. Short, fits a segmented control
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get desktopCloseQuit;

  /// macOS: what Keep running means
  ///
  /// In en, this message translates to:
  /// **'Agents and notifications carry on. Open the window again from the Dock or the menu bar.'**
  String get desktopCloseKeepRunningSubtitleMac;

  /// Windows/Linux: what Keep running means
  ///
  /// In en, this message translates to:
  /// **'Agents and notifications carry on. Open the window again from the tray icon.'**
  String get desktopCloseKeepRunningSubtitle;

  /// What Quit means
  ///
  /// In en, this message translates to:
  /// **'Closing the window quits Control Center. Notifications stop until you open it again.'**
  String get desktopCloseQuitSubtitle;

  /// Windows/Linux: the close choice is disabled because without a tray icon there would be no way back to the window
  ///
  /// In en, this message translates to:
  /// **'Turn on the tray icon to keep Control Center running with its window closed.'**
  String get desktopCloseNeedsTray;

  /// Section label for opening the app when the user signs in to the computer
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get desktopSectionLogin;

  /// Switch: start the app automatically when the user signs in to the computer
  ///
  /// In en, this message translates to:
  /// **'Open at login'**
  String get desktopLoginTitle;

  /// Explains Open at login
  ///
  /// In en, this message translates to:
  /// **'Start Control Center when you sign in, so notifications arrive from the start.'**
  String get desktopLoginSubtitle;

  /// Shown instead of the explanation when the OS has no login item support
  ///
  /// In en, this message translates to:
  /// **'This system doesn\'t support opening apps at login.'**
  String get desktopLoginUnsupported;

  /// macOS: the login item is waiting for the user's approval in System Settings → General → Login Items. 'Login Items' is the macOS settings pane name
  ///
  /// In en, this message translates to:
  /// **'Allow Control Center in Login Items to finish turning this on.'**
  String get desktopLoginNeedsApproval;

  /// macOS: button that opens System Settings → General → Login Items. Use the localized macOS name of that pane
  ///
  /// In en, this message translates to:
  /// **'Open Login Items'**
  String get desktopLoginOpenLoginItems;

  /// Windows/Linux: registering or removing the login launch failed
  ///
  /// In en, this message translates to:
  /// **'The system didn\'t accept the change. Your administrator may manage it.'**
  String get desktopLoginRefused;

  /// Switch: when opened at login, the app starts without showing its window
  ///
  /// In en, this message translates to:
  /// **'Start in the background'**
  String get desktopLoginStartHiddenTitle;

  /// macOS: explains Start in the background
  ///
  /// In en, this message translates to:
  /// **'Opens without a window at login. Find it in the Dock or the menu bar.'**
  String get desktopLoginStartHiddenSubtitleMac;

  /// Windows/Linux: explains Start in the background
  ///
  /// In en, this message translates to:
  /// **'Opens without a window at login. Find it in the tray.'**
  String get desktopLoginStartHiddenSubtitle;

  /// Windows/Linux: why Start in the background is disabled
  ///
  /// In en, this message translates to:
  /// **'Needs the tray icon, so there\'s a way to open the window.'**
  String get desktopLoginStartHiddenNeedsTray;

  /// Windows/Linux: dialog title shown the first time the user closes the main window
  ///
  /// In en, this message translates to:
  /// **'Keep Control Center running?'**
  String get closeToTrayPromptTitle;

  /// Body of the first-close dialog. 'Settings → Desktop app' names the settings page; translate both parts like navDesktopApp
  ///
  /// In en, this message translates to:
  /// **'Agents keep working and notifications keep arriving with the window closed. Open it again from the tray icon. You can change this in Settings → Desktop app.'**
  String get closeToTrayPromptBody;

  /// First-close dialog button: quit the app
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get closeToTrayPromptQuit;

  /// First-close dialog button: hide the window and keep running in the tray
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get closeToTrayPromptKeepRunning;

  /// Tray status: the app is not connected to its server. Short status tag
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get trayStatusOffline;

  /// Tray status: the connection to the server is being re-established. Short status tag
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get trayStatusReconnecting;

  /// Tray status: how many agent questions and approvals wait on the user. Joined with trayStatusWorking by ' · '
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs you} other{{count} need you}}'**
  String trayStatusNeedsYou(int count);

  /// Tray status: how many spaces have an agent working right now
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 working} other{{count} working}}'**
  String trayStatusWorking(int count);

  /// Tray status: nothing is running and nothing waits on the user
  ///
  /// In en, this message translates to:
  /// **'All quiet'**
  String get trayStatusAllQuiet;

  /// Hover text of the tray icon: the app name, then the status line
  ///
  /// In en, this message translates to:
  /// **'Control Center · {status}'**
  String trayTooltip(String status);

  /// Tray menu line: a space and how many agent questions there wait on the user
  ///
  /// In en, this message translates to:
  /// **'{space} · {count, plural, =1{1 question} other{{count} questions}}'**
  String trayMenuSpaceQuestions(String space, int count);

  /// Tray menu line: agent actions waiting for the user's approval
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 approval waiting} other{{count} approvals waiting}}'**
  String trayApprovalsWaiting(int count);

  /// Tray menu item: show the main window
  ///
  /// In en, this message translates to:
  /// **'Open Control Center'**
  String get trayMenuOpen;

  /// Tray menu item: open the Desktop app settings (ellipsis because it opens a window)
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get trayMenuSettings;

  /// Tray menu item and panel button tooltip: quit the app
  ///
  /// In en, this message translates to:
  /// **'Quit Control Center'**
  String get trayMenuQuit;

  /// Tray panel header when no workspace is active (the product name; keep as-is unless the product name is localized elsewhere)
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get trayPanelTitle;

  /// Tray panel body when no workspace is active
  ///
  /// In en, this message translates to:
  /// **'Open Control Center to choose a workspace.'**
  String get trayPanelNoWorkspace;

  /// Tray panel button: show the main window
  ///
  /// In en, this message translates to:
  /// **'Open Control Center'**
  String get trayPanelOpenApp;

  /// Tray panel icon button tooltip: open Settings → Desktop app
  ///
  /// In en, this message translates to:
  /// **'Desktop app settings'**
  String get trayPanelSettings;

  /// Tray panel section heading (shown uppercase): what waits on the user
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get trayPanelNeedsYou;

  /// Tray panel row: agent actions waiting for approval (a count follows)
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get trayPanelApprovals;

  /// Tray panel section heading (shown uppercase): the workspace's spaces
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get trayPanelSpaces;

  /// Tray panel: the workspace has no spaces
  ///
  /// In en, this message translates to:
  /// **'No spaces yet.'**
  String get trayPanelNoSpaces;

  /// Tray panel row that opens the full spaces list; count is the total number of spaces
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{All spaces} other{All {count} spaces}}'**
  String trayPanelAllSpaces(int count);

  /// Tray panel section heading (shown uppercase): subscription plan usage
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get trayPanelUsage;

  /// Tray panel header: accessible name of the workspace switcher (the workspace name and status open a menu of workspaces)
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get trayPanelSwitchWorkspace;

  /// Button that starts a sign-in with a provider; provider is a brand name such as GitHub or Linear
  ///
  /// In en, this message translates to:
  /// **'Sign in to {provider}'**
  String signInToProvider(String provider);

  /// Button: a workspace admin connects the Linear app actor used by agents and pipelines
  ///
  /// In en, this message translates to:
  /// **'Connect Linear for automation'**
  String get linearConnectAutomation;

  /// Sign-in dialog status while the sign-in page is being opened
  ///
  /// In en, this message translates to:
  /// **'Opening {provider} in your browser…'**
  String signInOpeningBrowser(String provider);

  /// Title of the alert shown when a provider sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t finish'**
  String get signInFailedTitle;

  /// Button that reopens the provider sign-in page in the browser
  ///
  /// In en, this message translates to:
  /// **'Open the sign-in page again'**
  String get signInReopenPage;

  /// Sign-in dialog instruction, for every sign-in: the browser page (Control Center Connect's or this server's own) first asks to confirm, then shows an 8-character code to type here
  ///
  /// In en, this message translates to:
  /// **'Confirm in your browser, then enter the code it shows.'**
  String get signInCodePrompt;

  /// Validation error under the sign-in code field
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a sign-in code. Codes have 8 letters and digits.'**
  String get signInCodeMalformed;

  /// Hint under the sign-in code field about the deep link
  ///
  /// In en, this message translates to:
  /// **'If your browser asks to open Control Center, allow it and you can skip typing the code.'**
  String get signInCodeDeepLinkHint;

  /// Toast after a successful sign-in; account is the provider login or email
  ///
  /// In en, this message translates to:
  /// **'Signed in to {provider} as {account}'**
  String signInSucceeded(String provider, String account);

  /// Toast after a successful sign-in when no account name is known
  ///
  /// In en, this message translates to:
  /// **'Signed in to {provider}'**
  String signInSucceededNoAccount(String provider);

  /// Sign-in failure: the attempt timed out
  ///
  /// In en, this message translates to:
  /// **'This sign-in expired. Start it again.'**
  String get signInErrorExpired;

  /// Sign-in failure: the person declined on the provider page
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in was cancelled or denied.'**
  String signInErrorAccessDenied(String provider);

  /// Sign-in failure: not all requested scopes were granted
  ///
  /// In en, this message translates to:
  /// **'{provider} granted fewer permissions than Control Center needs. Sign in again and approve every permission.'**
  String signInErrorScopeMismatch(String provider);

  /// Sign-in failure: wrong confirmation code
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match this sign-in. Check it and try again.'**
  String get signInErrorInvalidCode;

  /// Sign-in failure: too many wrong confirmation codes ended the attempt
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Start the sign-in again.'**
  String get signInErrorTooManyCodes;

  /// Sign-in failure: the server no longer knows this attempt (cancelled on the browser page, already used, or replaced by a newer one)
  ///
  /// In en, this message translates to:
  /// **'This sign-in is no longer open: it was cancelled, used or replaced. Start it again.'**
  String get signInErrorStaleRequest;

  /// Sign-in failure: the server could not read the request
  ///
  /// In en, this message translates to:
  /// **'The server couldn\'t read this sign-in request. Start it again.'**
  String get signInErrorInvalidRequest;

  /// Sign-in failure: the sign-in service (Control Center Connect or the provider) is limiting requests. Must not ask the person to sign in again; the dialog offers Try again
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Wait a bit, then try again.'**
  String get signInErrorRateLimited;

  /// Sign-in failure: the grant came back but the server could not store it
  ///
  /// In en, this message translates to:
  /// **'{provider} accepted the sign-in, but the server couldn\'t save it. Try again.'**
  String signInErrorStoreFailed(String provider);

  /// Sign-in failure: the provider is down
  ///
  /// In en, this message translates to:
  /// **'{provider} isn\'t responding right now. Try again in a few minutes.'**
  String signInErrorProviderUnavailable(String provider);

  /// Sign-in failure: the token exchange failed
  ///
  /// In en, this message translates to:
  /// **'{provider} accepted the sign-in, but the server couldn\'t finish it. Try again.'**
  String signInErrorExchangeFailed(String provider);

  /// Sign-in failure: the provider app configuration is broken
  ///
  /// In en, this message translates to:
  /// **'This server\'s {provider} app is set up incorrectly. Ask the server owner to check Settings → Server → Single sign-on.'**
  String signInErrorMisconfigured(String provider);

  /// The person has a grant, but it no longer works
  ///
  /// In en, this message translates to:
  /// **'Your {provider} sign-in has lapsed. Sign in again to keep working as yourself.'**
  String signInErrorNeedsSignIn(String provider);

  /// Sign-in failure: the provider app is not installed on the needed account
  ///
  /// In en, this message translates to:
  /// **'The {provider} app isn\'t installed where this needs it. Install it, then try again.'**
  String signInErrorNotInstalled(String provider);

  /// Sign-in failure: the Linear team belongs to another server
  ///
  /// In en, this message translates to:
  /// **'This Slack workspace is already connected to another Control Center server.'**
  String get signInErrorTeamBoundElsewhere;

  /// Sign-in failure: the person who approved the first Slack connection is not a workspace admin or owner
  ///
  /// In en, this message translates to:
  /// **'Only a Slack workspace admin or owner can connect it to Control Center the first time. Ask one of them to add the app.'**
  String get signInErrorNotAdmin;

  /// Sign-in failure: the provider app installation is suspended
  ///
  /// In en, this message translates to:
  /// **'The {provider} app is suspended. Unsuspend it on {provider}, then try again.'**
  String signInErrorSuspended(String provider);

  /// Sign-in failure: Connect refuses this server install
  ///
  /// In en, this message translates to:
  /// **'Control Center Connect has blocked this server. Contact whoever runs your Connect server.'**
  String get signInErrorInstallBlocked;

  /// Sign-in failure with no known reason
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed for a reason the server didn\'t report. Try again.'**
  String get signInErrorUnknown;

  /// Title of the warning shown for a sign-in link this app did not start
  ///
  /// In en, this message translates to:
  /// **'Sign-in not started here'**
  String get signInPhishingTitle;

  /// Warning shown for a sign-in link this app did not start
  ///
  /// In en, this message translates to:
  /// **'This sign-in was not started from this app. If someone sent you this link, do not continue.'**
  String get signInPhishingBody;

  /// Explains why the unknown sign-in link was ignored
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Completing a sign-in someone else started would connect your account to their server.'**
  String get signInPhishingDetail;

  /// Dialog title when an action was refused because the person is not signed in
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in needed'**
  String signInRequiredTitle(String provider);

  /// Dialog body when an action was refused because the person is not signed in
  ///
  /// In en, this message translates to:
  /// **'This runs as you on {provider}, and you aren\'t signed in. Sign in, then try again.'**
  String signInRequiredBody(String provider);

  /// Inline notice above a surface whose actions run as the person
  ///
  /// In en, this message translates to:
  /// **'You aren\'t signed in to {provider}. Anything you do here runs as you, so sign in first.'**
  String signInRequiredBanner(String provider);

  /// Shown instead of a sign-in button when the server has no way to sign in to the provider
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in isn\'t set up on this server yet.'**
  String signInUnavailable(String provider);

  /// Settings group title listing where the GitHub App is installed
  ///
  /// In en, this message translates to:
  /// **'GitHub App installations'**
  String get githubInstallations;

  /// Settings group description for GitHub App installations
  ///
  /// In en, this message translates to:
  /// **'Where the GitHub App is installed, among the accounts this workspace\'s repositories belong to.'**
  String get githubInstallationsDescription;

  /// Empty state for the GitHub App installations list
  ///
  /// In en, this message translates to:
  /// **'The GitHub App isn\'t installed on any account this workspace\'s repositories belong to.'**
  String get githubInstallationsEmpty;

  /// Button that opens the GitHub App installation page
  ///
  /// In en, this message translates to:
  /// **'Install GitHub App'**
  String get githubInstallApp;

  /// Status tag: the GitHub App installation is suspended
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get githubInstallationSuspended;

  /// Row title for the workspace Linear app actor
  ///
  /// In en, this message translates to:
  /// **'Linear automation'**
  String get linearAutomationTitle;

  /// Row subtitle for the workspace Linear app actor
  ///
  /// In en, this message translates to:
  /// **'Lets this workspace\'s agents and pipelines act in Linear as an app rather than as a person. Workspace admins connect it.'**
  String get linearAutomationHint;

  /// Row subtitle when the Linear app actor is connected; account is the Linear workspace
  ///
  /// In en, this message translates to:
  /// **'Connected to {account}'**
  String linearAutomationConnectedAs(String account);

  /// Connect mode option: hosted Connect
  ///
  /// In en, this message translates to:
  /// **'Use Control Center\'s apps'**
  String get connectModeHosted;

  /// Disclosure under the hosted Connect option
  ///
  /// In en, this message translates to:
  /// **'Sign-ins run through Control Center Connect. Connect seals each sign-in so only this server can open it, mints GitHub tokens limited to one repository, holds no repository key, and never receives your source code.'**
  String get connectModeHostedDisclosure;

  /// Connect mode option: the operator registers their own provider apps
  ///
  /// In en, this message translates to:
  /// **'Use my own apps'**
  String get connectModeOwn;

  /// Hint under the own-apps option
  ///
  /// In en, this message translates to:
  /// **'Register GitHub, Google and Linear apps yourself under Settings → Server → Single sign-on, and connect each workspace\'s own Slack app under Workspace → Integrations, where a workspace can also pick its own apps or Connect. Create my GitHub App sets up GitHub in one step.'**
  String get connectModeOwnHint;

  /// Connect mode option: a self-run Connect server
  ///
  /// In en, this message translates to:
  /// **'Use a custom Connect server'**
  String get connectModeCustom;

  /// Hint under the custom Connect option
  ///
  /// In en, this message translates to:
  /// **'Your organization runs its own Connect server. Sign-ins go there instead of to Control Center\'s.'**
  String get connectModeCustomHint;

  /// Connect mode when none was chosen
  ///
  /// In en, this message translates to:
  /// **'Not set up yet'**
  String get connectModeUnset;

  /// Label of the custom Connect server URL field
  ///
  /// In en, this message translates to:
  /// **'Connect server URL'**
  String get connectCustomUrlLabel;

  /// Validation error for the custom Connect URL
  ///
  /// In en, this message translates to:
  /// **'Enter an HTTPS address, like https://connect.example.com.'**
  String get connectCustomUrlInvalid;

  /// Helper under the custom Connect URL field when the URL is plain HTTP to this machine
  ///
  /// In en, this message translates to:
  /// **'Plain HTTP only reaches a Connect on this machine. Use HTTPS for anything on a network.'**
  String get connectCustomUrlLoopbackHint;

  /// Connect health: this build has no hosted Connect
  ///
  /// In en, this message translates to:
  /// **'Control Center\'s hosted apps are not available yet on this build. Use your own apps or a custom Connect server.'**
  String get connectErrorHostedUnprovisioned;

  /// Connect health: bad signature
  ///
  /// In en, this message translates to:
  /// **'Connect\'s configuration failed its signature check. Sign-ins through Connect are paused until it verifies again.'**
  String get connectErrorSignature;

  /// Connect health: configuration rollback
  ///
  /// In en, this message translates to:
  /// **'Connect served an older configuration than this server has already seen, so it was refused. Sign-ins through Connect are paused.'**
  String get connectErrorRollback;

  /// Connect health: unreachable
  ///
  /// In en, this message translates to:
  /// **'This server can\'t reach Connect right now. Sign-ins that use it will fail until it\'s back.'**
  String get connectErrorUnreachable;

  /// Connect health: install blocked
  ///
  /// In en, this message translates to:
  /// **'Connect has blocked this server\'s install id. Contact whoever runs your Connect server.'**
  String get connectErrorInstallBlocked;

  /// Connect health: new signing keys await confirmation
  ///
  /// In en, this message translates to:
  /// **'Connect\'s apps changed'**
  String get connectErrorPinsChanged;

  /// Connect health: protocol mismatch
  ///
  /// In en, this message translates to:
  /// **'Connect answered in a way this server doesn\'t understand. Update the server or check the Connect URL.'**
  String get connectErrorProtocol;

  /// Connect health: unknown error
  ///
  /// In en, this message translates to:
  /// **'Connect reported a problem it didn\'t explain. Run a test to retry.'**
  String get connectErrorUnknown;

  /// Explains the pending signing keys
  ///
  /// In en, this message translates to:
  /// **'Your Connect server now names different GitHub, Google, Linear or Slack apps than the ones this server pinned on first use. Trust them only if its operator told you to expect this.'**
  String get connectPinsConfirmHint;

  /// Button that accepts Connect signing keys
  ///
  /// In en, this message translates to:
  /// **'Trust new apps'**
  String get connectConfirmPins;

  /// Connect warning: stale configuration
  ///
  /// In en, this message translates to:
  /// **'The configuration in use is older than expected. Run a test to refresh it.'**
  String get connectStale;

  /// Lane source tag: an own provider app
  ///
  /// In en, this message translates to:
  /// **'Own app'**
  String get connectLaneSourceOwn;

  /// Lane source tag: Control Center Connect (product name)
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectLaneSourceConnect;

  /// Lane source tag: sign-in unavailable
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get connectLaneSourceOff;

  /// Settings card title (product name)
  ///
  /// In en, this message translates to:
  /// **'Control Center Connect'**
  String get connectTitle;

  /// Settings card description for Connect
  ///
  /// In en, this message translates to:
  /// **'Whose apps this server uses for GitHub, Google Calendar, Linear, Slack and GIF search.'**
  String get connectDescription;

  /// Summary fact label: which apps sign people in
  ///
  /// In en, this message translates to:
  /// **'Sign-in apps'**
  String get connectFactMode;

  /// Summary fact label: Connect health
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get connectFactHealth;

  /// Summary fact label: Connect configuration epoch
  ///
  /// In en, this message translates to:
  /// **'Configuration version'**
  String get connectFactEpoch;

  /// Connect status: not used
  ///
  /// In en, this message translates to:
  /// **'Not in use'**
  String get connectHealthOff;

  /// Connect status: healthy
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get connectHealthOk;

  /// Connect status: unhealthy
  ///
  /// In en, this message translates to:
  /// **'Not working'**
  String get connectHealthDown;

  /// Shown when the environment pins the Connect mode; CC_CONNECT_URL is an environment variable
  ///
  /// In en, this message translates to:
  /// **'CC_CONNECT_URL in this server\'s environment sets this. Change it there and restart the server.'**
  String get connectLocked;

  /// Settings group title listing each provider lane source
  ///
  /// In en, this message translates to:
  /// **'Where each sign-in runs'**
  String get connectLanesTitle;

  /// Settings group description for lane sources
  ///
  /// In en, this message translates to:
  /// **'An own app always takes precedence over Connect for its provider.'**
  String get connectLanesDescription;

  /// Settings group title for the server identity on Connect
  ///
  /// In en, this message translates to:
  /// **'This server'**
  String get connectServerGroup;

  /// Field label: this server install id on Connect
  ///
  /// In en, this message translates to:
  /// **'Install id'**
  String get connectInstallId;

  /// Field description for the install id
  ///
  /// In en, this message translates to:
  /// **'Identifies this server to Connect. Give it to an organization owner or Connect operator who asks for it.'**
  String get connectInstallIdHint;

  /// Shown when there is no install id yet
  ///
  /// In en, this message translates to:
  /// **'Assigned the first time this server uses Connect.'**
  String get connectInstallIdEmpty;

  /// Toast after a successful Connect test
  ///
  /// In en, this message translates to:
  /// **'Connect is working.'**
  String get connectTestOk;

  /// Button that rotates the server Connect key
  ///
  /// In en, this message translates to:
  /// **'Rotate key'**
  String get connectRotateKey;

  /// Confirm dialog title for rotating the Connect key
  ///
  /// In en, this message translates to:
  /// **'Rotate this server\'s Connect key?'**
  String get connectRotateKeyTitle;

  /// Confirm dialog body for rotating the Connect key
  ///
  /// In en, this message translates to:
  /// **'This server gets a new key and install id, and the old id is retired at Connect: sign-ins sealed under it, and the old key, stop working there, so everyone who signed in through Connect signs in again. Tokens already handed out keep working until they expire. Sign-ins through your own apps aren\'t affected. If Connect can\'t be reached, nothing changes and you can try again.'**
  String get connectRotateKeyBody;

  /// Toast after rotating the Connect key
  ///
  /// In en, this message translates to:
  /// **'Key rotated. Everyone who signed in through Connect needs to sign in again.'**
  String get connectRotateKeyDone;

  /// Field label above the cc_server connect command line
  ///
  /// In en, this message translates to:
  /// **'From a terminal'**
  String get connectCliLabel;

  /// Onboarding progress label: choose sign-in apps
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get onboardingStepSignIn;

  /// Onboarding step title: choose sign-in apps
  ///
  /// In en, this message translates to:
  /// **'Choose how people sign in'**
  String get onboardingConnectTitle;

  /// Onboarding step subtitle: choose sign-in apps
  ///
  /// In en, this message translates to:
  /// **'Control Center works with GitHub, Google Calendar, Linear, Slack and GIF search through apps registered with each provider. Pick whose apps this server uses. You can change it later in Settings → Server → Single sign-on.'**
  String get onboardingConnectSubtitle;

  /// Onboarding note under the own-apps option
  ///
  /// In en, this message translates to:
  /// **'Create a GitHub App for this server now, or add your apps later in Settings → Server → Single sign-on.'**
  String get onboardingConnectOwnNext;

  /// Field label: the Linear service API key used by the server itself
  ///
  /// In en, this message translates to:
  /// **'Service API key'**
  String get providerServiceApiKey;

  /// Provider app status: some fields are set and others are missing
  ///
  /// In en, this message translates to:
  /// **'Setup isn\'t finished'**
  String get providerAppPartial;

  /// Lists the missing provider app fields
  ///
  /// In en, this message translates to:
  /// **'Still missing: {fields}. Until every field is set, sign-ins for this provider are refused rather than sent through Connect.'**
  String providerAppMissingFields(String fields);

  /// Settings group description for the Linear app fields
  ///
  /// In en, this message translates to:
  /// **'The client id signs members in. The service API key lets this server read and write Linear by itself.'**
  String get providerAppsGroupSignInLinearDescription;

  /// Field label when the provider needs several callback URLs registered
  ///
  /// In en, this message translates to:
  /// **'Callback URLs'**
  String get providerCallbackUrls;

  /// Field description for callback URLs
  ///
  /// In en, this message translates to:
  /// **'Register this with the provider exactly as shown.'**
  String get providerCallbackUrlHint;

  /// Settings group title for the GitHub App manifest flow
  ///
  /// In en, this message translates to:
  /// **'Create a GitHub App'**
  String get providerAppCreateGitHubTitle;

  /// Settings group description for the GitHub App manifest flow
  ///
  /// In en, this message translates to:
  /// **'GitHub registers an App with the right permissions and callback, then hands its credentials to this server. Nothing to copy by hand.'**
  String get providerAppCreateGitHubHint;

  /// Button that starts the GitHub App manifest flow
  ///
  /// In en, this message translates to:
  /// **'Create my GitHub App'**
  String get providerAppCreateGitHub;

  /// Label of the optional field naming the GitHub organization the new App is created under
  ///
  /// In en, this message translates to:
  /// **'Organization (optional)'**
  String get providerAppCreateGitHubOrg;

  /// Hint under the GitHub organization field of the App manifest flow
  ///
  /// In en, this message translates to:
  /// **'Leave empty to create the app under your own GitHub account. Creating it under an organization takes an owner of that organization.'**
  String get providerAppCreateGitHubOrgHint;

  /// Provider app status: sign-in works
  ///
  /// In en, this message translates to:
  /// **'People can sign in.'**
  String get providerAppSignInReady;

  /// Status line under the link code while Control Center waits for the code to arrive in a direct message
  ///
  /// In en, this message translates to:
  /// **'Waiting for your direct message…'**
  String get chatLinkWaiting;

  /// Title of the panel asking the member to confirm the chat profile that sent their link code
  ///
  /// In en, this message translates to:
  /// **'Is this your {provider} account?'**
  String chatLinkClaimTitle(String provider);

  /// Explains what confirming a claimed link code does
  ///
  /// In en, this message translates to:
  /// **'This account sent your code to the bot. Confirm only if it is yours: once linked, what it sends in {provider} acts as you in this workspace.'**
  String chatLinkClaimBody(String provider);

  /// Button that refuses the chat profile that claimed the link code
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get chatLinkDecline;

  /// Shown in the link dialog after the member declined the claim
  ///
  /// In en, this message translates to:
  /// **'Nothing was linked. Get a new code if you still want to link your {provider} account.'**
  String chatLinkDeclined(String provider);

  /// Button that mints a fresh link code after a decline
  ///
  /// In en, this message translates to:
  /// **'Get a new code'**
  String get chatLinkNewCode;

  /// Title of the row and sign-in dialog that installs the shared Control Center app into a chat workspace
  ///
  /// In en, this message translates to:
  /// **'Add Control Center to {provider}'**
  String signInAddControlCenter(String provider);

  /// Toast after the shared Control Center app was installed; workspace is the chat workspace name
  ///
  /// In en, this message translates to:
  /// **'Control Center was added to {workspace}'**
  String signInAddedControlCenter(String workspace);

  /// Subtitle of the row that installs the shared Control Center app
  ///
  /// In en, this message translates to:
  /// **'Installs the shared Control Center app in your {provider} workspace. There is no app to create and no token to paste.'**
  String chatSharedAppHint(String provider);

  /// Button that starts the shared Control Center app install
  ///
  /// In en, this message translates to:
  /// **'Add to {provider}'**
  String chatAddToProvider(String provider);

  /// Caption on a chat connection that runs on the shared Control Center app
  ///
  /// In en, this message translates to:
  /// **'Runs on the shared Control Center app, so there are no tokens or bot settings to manage here.'**
  String get chatSharedAppConnected;

  /// Title of the settings card listing the member's ticket drafts from chat
  ///
  /// In en, this message translates to:
  /// **'Ticket drafts from chat'**
  String get chatTicketDraftsTitle;

  /// Explains that chat ticket drafts only become tickets when created in Control Center
  ///
  /// In en, this message translates to:
  /// **'A draft becomes a backlog ticket only when you create it here. Drafts you leave are dropped after a day.'**
  String get chatTicketDraftsDescription;

  /// Where a ticket draft came from
  ///
  /// In en, this message translates to:
  /// **'From {provider}'**
  String chatTicketDraftFrom(String provider);

  /// Button that creates a backlog ticket from a chat draft
  ///
  /// In en, this message translates to:
  /// **'Create ticket'**
  String get chatTicketDraftCreate;

  /// Toast after a chat draft became a ticket; key is the ticket key
  ///
  /// In en, this message translates to:
  /// **'Created {key}'**
  String chatTicketDraftCreated(String key);

  /// Lists the fields a workspace's own provider app still needs
  ///
  /// In en, this message translates to:
  /// **'Still missing: {fields}. Until every field is set, this provider is off in this workspace. It does not fall back to this server\'s app.'**
  String workspaceProviderAppMissingFields(String fields);

  /// Hint under a workspace provider app's credential fields
  ///
  /// In en, this message translates to:
  /// **'Changing the app signs everyone in this workspace out of it. They sign in again with the new one.'**
  String get workspaceProviderAppClientChangeHint;

  /// Label of the Klipy app key field
  ///
  /// In en, this message translates to:
  /// **'App key'**
  String get workspaceProviderAppKlipyKey;

  /// Description of the Klipy app key group
  ///
  /// In en, this message translates to:
  /// **'GIF search in this workspace uses this key.'**
  String get workspaceProviderAppKlipyHint;

  /// Settings nav item and page title: every provider this workspace uses (code hosting, tickets, calendar, chat, GIFs)
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsWorkspaceIntegrations;

  /// Subtitle of Settings → Workspace → Integrations
  ///
  /// In en, this message translates to:
  /// **'Code hosting, tickets, calendar, chat and GIF search in this workspace, and whose apps they sign in through.'**
  String get settingsWorkspaceIntegrationsDescription;

  /// Subtitle of the workspace's Control Center Connect card
  ///
  /// In en, this message translates to:
  /// **'Whose apps this workspace uses for GitHub, Google Calendar, Linear, Slack and GIF search. Unless an admin picks something else, it follows this server.'**
  String get workspaceConnectDescription;

  /// Workspace Connect choice: follow the server owner's choice of sign-in apps
  ///
  /// In en, this message translates to:
  /// **'Same as this server'**
  String get workspaceConnectModeInherit;

  /// Hint under 'Same as this server' when the server uses Control Center's hosted Connect
  ///
  /// In en, this message translates to:
  /// **'This server uses Control Center\'s apps.'**
  String get workspaceConnectInheritHosted;

  /// Hint under 'Same as this server' when the server uses a custom Connect server
  ///
  /// In en, this message translates to:
  /// **'This server uses the Connect server at {url}.'**
  String workspaceConnectInheritCustom(String url);

  /// Hint under 'Same as this server' when the server uses its own provider apps
  ///
  /// In en, this message translates to:
  /// **'This server uses its own apps.'**
  String get workspaceConnectInheritOwn;

  /// Hint under 'Same as this server' when the server owner has not picked sign-in apps
  ///
  /// In en, this message translates to:
  /// **'This server\'s owner hasn\'t chosen yet, so the server\'s own apps apply.'**
  String get workspaceConnectInheritUnset;

  /// Hint under 'Use my own apps' on the workspace Connect card
  ///
  /// In en, this message translates to:
  /// **'Only this workspace\'s apps are used. Add each one below, next to its provider. A provider without one is off here; this server\'s apps and Connect are never used instead.'**
  String get workspaceConnectOwnHint;

  /// Helper under the workspace's custom Connect server URL field
  ///
  /// In en, this message translates to:
  /// **'HTTPS only. Addresses on a private or local network are refused.'**
  String get workspaceConnectCustomUrlHint;

  /// Notice when the server environment forbids a workspace from choosing a Connect server; CC_CONNECT_URL is an environment variable name, keep it verbatim
  ///
  /// In en, this message translates to:
  /// **'CC_CONNECT_URL in this server\'s environment sets where sign-ins go, so this workspace can\'t pick a Connect of its own. It can follow this server or use its own apps.'**
  String get workspaceConnectLocked;

  /// Confirm dialog title when an admin changes the workspace's Connect choice
  ///
  /// In en, this message translates to:
  /// **'Switch this workspace\'s sign-in apps?'**
  String get workspaceConnectSwitchTitle;

  /// Confirm dialog body when an admin changes the workspace's Connect choice
  ///
  /// In en, this message translates to:
  /// **'Everyone in this workspace has to sign in to GitHub, Linear and Google Calendar again through the new apps. Sign-ins made through the current ones stop working here.'**
  String get workspaceConnectSwitchBody;

  /// Confirm button that changes the workspace's Connect choice
  ///
  /// In en, this message translates to:
  /// **'Switch apps'**
  String get workspaceConnectSwitchAction;

  /// Description of the per-provider list on the workspace Connect card
  ///
  /// In en, this message translates to:
  /// **'Follows the choice above. A provider never falls back to another app.'**
  String get workspaceConnectLanesDescription;

  /// Status tag: this provider runs on the workspace's own app
  ///
  /// In en, this message translates to:
  /// **'Workspace\'s app'**
  String get workspaceConnectLaneWorkspaceOwn;

  /// Status tag: this provider runs on the server's own app
  ///
  /// In en, this message translates to:
  /// **'Server\'s app'**
  String get workspaceConnectLaneServerOwn;

  /// Title of the workspace card about the GitHub App the workspace runs on
  ///
  /// In en, this message translates to:
  /// **'GitHub App'**
  String get workspaceGitHubAppTitle;

  /// Subtitle of the GitHub App card while the workspace uses its own apps
  ///
  /// In en, this message translates to:
  /// **'This workspace\'s own App acts for its repositories and signs members in. It never falls back to this server\'s App or to Connect.'**
  String get workspaceGitHubAppOwnDescription;

  /// Subtitle of the GitHub App card while the workspace uses the server's apps or a Connect
  ///
  /// In en, this message translates to:
  /// **'This workspace uses the GitHub App its sign-in apps provide. Install it on the accounts your repositories belong to.'**
  String get workspaceGitHubAppSharedDescription;

  /// Group title for the workspace GitHub App's id and private key
  ///
  /// In en, this message translates to:
  /// **'Acting for this workspace'**
  String get workspaceGitHubAppActingTitle;

  /// Description of the workspace GitHub App's id and private key group
  ///
  /// In en, this message translates to:
  /// **'The App\'s bot comments, reviews and polls pull requests in this workspace\'s repositories.'**
  String get workspaceGitHubAppActingDescription;

  /// Title of the card holding a workspace's own app for one provider
  ///
  /// In en, this message translates to:
  /// **'{provider} app'**
  String workspaceOwnAppTitle(String provider);

  /// Subtitle of the card holding a workspace's own app for one provider
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-ins and requests in this workspace use only this app.'**
  String workspaceOwnAppDescription(String provider);

  /// Title of the workspace card about GIF search
  ///
  /// In en, this message translates to:
  /// **'GIFs'**
  String get workspaceGifsTitle;

  /// GIF search runs on the workspace's own Klipy key; Klipy is a brand name
  ///
  /// In en, this message translates to:
  /// **'GIF search uses this workspace\'s Klipy key.'**
  String get workspaceGifsSourceWorkspaceOwn;

  /// GIF search runs on the server's own Klipy key; Klipy is a brand name
  ///
  /// In en, this message translates to:
  /// **'GIF search uses this server\'s Klipy key.'**
  String get workspaceGifsSourceServerOwn;

  /// GIF search runs through a Control Center Connect server
  ///
  /// In en, this message translates to:
  /// **'GIF search runs through Control Center Connect.'**
  String get workspaceGifsSourceConnect;

  /// No app or key provides GIF search in this workspace
  ///
  /// In en, this message translates to:
  /// **'GIF search is off in this workspace.'**
  String get workspaceGifsSourceOff;

  /// Menu item that opens the pull request on its code host's website
  ///
  /// In en, this message translates to:
  /// **'Open on {forge}'**
  String openOnForge(String forge);

  /// Warning above a pull request's file list when the code host capped its file listing, so only part of the change is shown
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} files. {forge} doesn\'t list the rest.'**
  String prFilesTruncatedNotice(String forge, int count);

  /// Empty state when no code host (GitHub, GitLab, Bitbucket) is connected
  ///
  /// In en, this message translates to:
  /// **'Connect a code host to load pull requests'**
  String get connectForgeToLoadPrs;

  /// Hint under the empty pull request and inbox states pointing at where a person connects their own code hosting accounts. 'Settings → You → Profile' must match the nav labels settingsScopeYou and accountProfileTitle
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub, GitLab or Bitbucket in Settings → You → Profile'**
  String get connectForgeHint;

  /// Hint when the workspace has no repository on a supported code host
  ///
  /// In en, this message translates to:
  /// **'Add at least one repository on GitHub, GitLab or Bitbucket to see pull requests'**
  String get addForgeRepoPrompt;

  /// Compose screen empty state: no repository on a code host is selected
  ///
  /// In en, this message translates to:
  /// **'No code-hosted repository selected'**
  String get composePrNoForgeRepo;

  /// Compose screen hint explaining which repositories can open a pull request
  ///
  /// In en, this message translates to:
  /// **'Select a workspace with a repository on GitHub, GitLab or Bitbucket to open a pull request.'**
  String get composePrNoForgeRepoHint;

  /// Compose screen empty state when the repository's code host is not connected
  ///
  /// In en, this message translates to:
  /// **'Connect {forge} to open a pull request in this repository'**
  String composePrForgeNotConnected(String forge);

  /// A forge or provider connection whose grant expired or was revoked, naming the last known account
  ///
  /// In en, this message translates to:
  /// **'Your {provider} sign-in as {account} has lapsed. Sign in again.'**
  String connectionNeedsSignInAs(String provider, String account);

  /// A connection whose grant is parked because the workspace's sign-in service (Connect or its own apps) changed; not the person's fault
  ///
  /// In en, this message translates to:
  /// **'Paused: this workspace\'s sign-in service changed'**
  String get connectionPaused;

  /// A connection whose grant could not be renewed because the provider or sign-in service is down; it retries on its own
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {provider} right now. Retrying.'**
  String connectionUnreachable(String provider);

  /// Body of the workspace banner when the person's forge sign-in is paused because the workspace's sign-in service changed
  ///
  /// In en, this message translates to:
  /// **'Your sign-in is kept and works again once the service is back. A workspace admin can check the sign-in setup in Integrations.'**
  String get forgeSignInBannerPausedBody;

  /// Sign-in failure: the server no longer knows the attempt (it restarted)
  ///
  /// In en, this message translates to:
  /// **'The server restarted. Start the sign-in again.'**
  String get signInErrorAttemptUnknown;

  /// Why a sign-in lane cannot be used: nothing is configured for it
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in isn\'t set up for this workspace.'**
  String signInUnavailableNotConfigured(String provider);

  /// Why a sign-in lane cannot be used: its own app is set up wrongly; error is the server's explanation
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in is set up incorrectly: {error}'**
  String signInUnavailableMisconfigured(String provider, String error);

  /// Why a sign-in lane cannot be used: the workspace uses its own apps and none is set up for this provider
  ///
  /// In en, this message translates to:
  /// **'This workspace uses its own apps but has no {provider} app.'**
  String signInUnavailableOwnAppMissing(String provider);

  /// Why a sign-in lane cannot be used: this server build cannot verify the hosted Connect service
  ///
  /// In en, this message translates to:
  /// **'This build can\'t verify Control Center Connect, so {provider} sign-in is off.'**
  String signInUnavailableConnectUnprovisioned(String provider);

  /// Why sign-in cannot be used: the custom Connect service's identifiers changed and await an admin's confirmation
  ///
  /// In en, this message translates to:
  /// **'This workspace\'s sign-in service changed its identity. An admin needs to confirm it.'**
  String get signInUnavailableConnectPinsPending;

  /// Why sign-in cannot be used: the Connect service cannot be reached or trusted
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach this workspace\'s sign-in service right now.'**
  String get signInUnavailableConnectUnreachable;

  /// Why sign-in cannot be used: the custom Connect URL is missing or unusable
  ///
  /// In en, this message translates to:
  /// **'This workspace\'s sign-in service address is missing or invalid.'**
  String get signInUnavailableConnectUrlInvalid;

  /// Why sign-in cannot be used: the server operator pinned the Connect service in the environment
  ///
  /// In en, this message translates to:
  /// **'The server\'s operator set the sign-in service, so this workspace\'s own choice doesn\'t apply.'**
  String get signInUnavailableBlockedByEnvironment;

  /// Why a sign-in lane cannot be used: the sign-in service in use does not support this provider
  ///
  /// In en, this message translates to:
  /// **'This workspace\'s sign-in service doesn\'t offer {provider}.'**
  String signInUnavailableLaneNotOffered(String provider);

  /// Button taking a workspace admin to Workspace > Integrations to fix the sign-in setup
  ///
  /// In en, this message translates to:
  /// **'Open integrations'**
  String get signInOpenIntegrations;

  /// Button taking the server owner to the server's sign-in settings to fix the sign-in setup
  ///
  /// In en, this message translates to:
  /// **'Open sign-in settings'**
  String get signInOpenServerSettings;

  /// Dialog body when an action was refused because the person has no token for a token-only forge
  ///
  /// In en, this message translates to:
  /// **'This runs as you on {provider}, and you haven\'t added a token. Add one, then try again.'**
  String forgeTokenRequiredBody(String provider);

  /// Title of the confirmation before disconnecting a forge
  ///
  /// In en, this message translates to:
  /// **'Disconnect {provider}?'**
  String disconnectProviderTitle(String provider);

  /// Confirmation body before disconnecting a forge outside any workspace
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to connect {provider} again to work on its repositories.'**
  String disconnectProviderBody(String provider);

  /// Confirmation body: the credential being removed belongs to this workspace only
  ///
  /// In en, this message translates to:
  /// **'This disconnects {provider} in this workspace only. Other workspaces keep their own connection.'**
  String disconnectScopeWorkspaceBody(String provider);

  /// Confirmation body: the credential being removed is shared by all workspaces
  ///
  /// In en, this message translates to:
  /// **'This disconnects {provider} in every workspace that shares this connection.'**
  String disconnectScopeGlobalBody(String provider);

  /// Toast after removing a credential kept for this workspace only
  ///
  /// In en, this message translates to:
  /// **'Disconnected {provider} from this workspace'**
  String disconnectedFromWorkspace(String provider);

  /// Toast after removing a credential shared by all workspaces
  ///
  /// In en, this message translates to:
  /// **'Disconnected {provider} from all workspaces'**
  String disconnectedFromAllWorkspaces(String provider);

  /// Notice title: the workspace's GitHub App is not installed on the account that owns linked repositories
  ///
  /// In en, this message translates to:
  /// **'Install the GitHub App on {owner}'**
  String repoAccessInstallTitle(String owner);

  /// Notice body naming the repositories affected by the missing GitHub App installation
  ///
  /// In en, this message translates to:
  /// **'Automation can\'t reach {repos} until the App is installed there.'**
  String repoAccessInstallBody(String repos);

  /// Notice title: the GitHub App is installed but these repositories are not selected in the installation
  ///
  /// In en, this message translates to:
  /// **'Add {repos} to the GitHub App\'s repositories'**
  String repoAccessSelectTitle(String repos);

  /// Notice body for repositories not selected in the GitHub App installation
  ///
  /// In en, this message translates to:
  /// **'The App is installed on this account but can\'t see these repositories yet.'**
  String get repoAccessSelectBody;

  /// Button opening the GitHub App installation's repository selection
  ///
  /// In en, this message translates to:
  /// **'Choose repositories'**
  String get repoAccessChooseRepos;

  /// Notice title: the GitHub App installation covering linked repositories is suspended
  ///
  /// In en, this message translates to:
  /// **'GitHub App installation suspended'**
  String get repoAccessSuspendedTitle;

  /// Notice body for a suspended GitHub App installation
  ///
  /// In en, this message translates to:
  /// **'Automation for {repos} is paused until an owner of the account resumes the installation on GitHub.'**
  String repoAccessSuspendedBody(String repos);

  /// Notice title: automation acting for the workspace's accountable person is paused for some repositories
  ///
  /// In en, this message translates to:
  /// **'Automation is paused'**
  String get repoAccessAutomationPausedTitle;

  /// Notice body: the accountable person lost access to these repositories
  ///
  /// In en, this message translates to:
  /// **'The person accountable for this workspace\'s automation can no longer see {repos}, so nothing runs there on their behalf.'**
  String repoAccessOwnerCannotSeeBody(String repos);

  /// Notice body: the accountable person is not signed in to the forge
  ///
  /// In en, this message translates to:
  /// **'The person accountable for this workspace\'s automation isn\'t signed in to the forge, so automation for {repos} waits until they sign in.'**
  String repoAccessOwnerNotSignedInBody(String repos);

  /// Muted line: the forge did not answer an access check; it is retried automatically
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check access to {repos}. Retrying.'**
  String repoAccessTransient(String repos);

  /// Shown to a non-admin member: who in the workspace can fix the access problem
  ///
  /// In en, this message translates to:
  /// **'Ask {admins} to fix this.'**
  String repoAccessAskAdmins(String admins);

  /// Shown to a non-admin member when the admins' names are not known
  ///
  /// In en, this message translates to:
  /// **'Ask a workspace admin to fix this.'**
  String get repoAccessAskAnAdmin;

  /// Notice above a PR list: repositories hidden because the person is not signed in to that forge
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sign in to {forge} to see pull requests from 1 more repository} other{Sign in to {forge} to see pull requests from {count} more repositories}}'**
  String hiddenReposSignIn(int count, String forge);

  /// Notice above a PR list: repositories hidden because the person's own forge account cannot read them
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repository is hidden because your {forge} account can\'t see it} other{{count} repositories are hidden because your {forge} account can\'t see them}}'**
  String hiddenReposNoForgeAccess(int count, String forge);

  /// Notice above a PR list: repositories hidden because the person holds no grant on them in this workspace
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repository is hidden because you don\'t have access to it in this workspace} other{{count} repositories are hidden because you don\'t have access to them in this workspace}}'**
  String hiddenReposNoGrant(int count);

  /// Quiet line above a PR list while the person's access to some repositories is still being checked
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checking your access to 1 more repository…} other{Checking your access to {count} more repositories…}}'**
  String hiddenReposChecking(int count);

  /// Title of the dialog listing access problems found while linking repositories
  ///
  /// In en, this message translates to:
  /// **'Linked, but automation can\'t reach everything yet'**
  String get repoLinkAccessWarningsTitle;

  /// Button installing the workspace's GitHub App on another account or organization
  ///
  /// In en, this message translates to:
  /// **'Install on another organization'**
  String get githubInstallOnAnotherOrganization;

  /// Label of the email field next to a Bitbucket API token; Bitbucket API tokens authenticate with the Atlassian account's email
  ///
  /// In en, this message translates to:
  /// **'Atlassian account email'**
  String get forgeTokenEmailLabel;

  /// Inline error when the Atlassian account email for a Bitbucket token is missing or malformed
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of your Atlassian account.'**
  String get forgeTokenEmailInvalid;

  /// Label of the Bitbucket API token field
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get forgeTokenApiTokenLabel;

  /// Explains why the Bitbucket token dialog also asks for an email
  ///
  /// In en, this message translates to:
  /// **'Bitbucket API tokens work together with the email of the Atlassian account that created them.'**
  String get forgeTokenBitbucketHint;

  /// Section title: bot access tokens GitLab/Bitbucket background work uses
  ///
  /// In en, this message translates to:
  /// **'Automation tokens'**
  String get automationTokensTitle;

  /// Section description in Settings → Repositories
  ///
  /// In en, this message translates to:
  /// **'Background work on GitLab and Bitbucket, such as pull request updates, AI review comments and merge requests nobody asked for, uses a bot access token, never a person\'s. A repository\'s own token wins over the workspace\'s.'**
  String get automationTokensRepoHint;

  /// Section description in Settings → Workspace → Integrations
  ///
  /// In en, this message translates to:
  /// **'Used for every GitLab or Bitbucket repository in this workspace that has no automation token of its own. Background work there shows as this token\'s bot.'**
  String get automationTokensWorkspaceHint;

  /// Status: this repository has no automation token
  ///
  /// In en, this message translates to:
  /// **'No token. Automation is paused here.'**
  String get automationTokenNone;

  /// Status: the repository uses the workspace-wide automation token
  ///
  /// In en, this message translates to:
  /// **'Uses the workspace\'s token'**
  String get automationTokenFromWorkspace;

  /// Status: automation acts as this bot account
  ///
  /// In en, this message translates to:
  /// **'Acts as {name}'**
  String automationTokenActsAs(String name);

  /// Status: a token is stored but the forge did not name its bot
  ///
  /// In en, this message translates to:
  /// **'Access token added'**
  String get automationTokenStored;

  /// Status: the stored automation token was revoked or expired
  ///
  /// In en, this message translates to:
  /// **'The forge refused this token. Replace it.'**
  String get automationTokenRejected;

  /// Dialog title for adding an automation token
  ///
  /// In en, this message translates to:
  /// **'{forge} automation token'**
  String automationTokenDialogTitle(String forge);

  /// Dialog hint for a GitLab automation token
  ///
  /// In en, this message translates to:
  /// **'Paste a project or group access token. It needs read_api and read_repository; add api and write_repository for comments, merge requests and pushes. GitLab shows its work as the token\'s bot.'**
  String get automationTokenGitLabHint;

  /// Dialog hint for a Bitbucket automation token. 'You → Profile' must match the nav labels settingsScopeYou and accountProfileTitle
  ///
  /// In en, this message translates to:
  /// **'Paste a repository, project or workspace access token with repository read, plus pull request write for comments and pull requests. Your own API token belongs under You → Profile, not here.'**
  String get automationTokenBitbucketHint;

  /// Toast after saving a workspace automation token that cannot read some repositories
  ///
  /// In en, this message translates to:
  /// **'Token saved, but it can\'t read {repos}. Automation there stays paused.'**
  String automationTokenUnreadable(String repos);

  /// Confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove automation token?'**
  String get automationTokenRemoveTitle;

  /// Confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Automation that relies on this token pauses until another one is added.'**
  String get automationTokenRemoveBody;

  /// What a workspace-wide automation token applies to
  ///
  /// In en, this message translates to:
  /// **'Every {forge} repository without its own token'**
  String automationTokenWorkspaceTarget(String forge);

  /// Notice body: GitLab/Bitbucket repositories without a working automation token
  ///
  /// In en, this message translates to:
  /// **'No automation token can read {repos}, so background work there is paused.'**
  String repoAccessAutomationTokenMissingBody(String repos);

  /// Subtitle of Settings > You > Commits: authorship, co-author credit and commit signing
  ///
  /// In en, this message translates to:
  /// **'Commits from work you start carry your name. Choose who else is credited, and whether forges show your commits as verified.'**
  String get settingsCommitsDescription;

  /// Section label on the Commits settings page: whose name commits carry
  ///
  /// In en, this message translates to:
  /// **'Authorship'**
  String get settingsCommitAuthorshipSection;

  /// Row label: commits from work the person started themselves (chat, pipeline, editor)
  ///
  /// In en, this message translates to:
  /// **'Work you start'**
  String get settingsCommitAuthorshipYoursLabel;

  /// Explains that the person is author and committer of commits from work they start, under the email their forge verified
  ///
  /// In en, this message translates to:
  /// **'You are the author and committer, under the email your forge verified for your sign-in. This covers chats with agents, pipelines you start and commits you make in the editor.'**
  String get settingsCommitAuthorshipYoursBody;

  /// Row label: runs nobody started by hand (schedules, webhooks)
  ///
  /// In en, this message translates to:
  /// **'Automated runs'**
  String get settingsCommitAuthorshipBotLabel;

  /// Explains that runs started by a schedule or webhook commit as the bot account and are never signed
  ///
  /// In en, this message translates to:
  /// **'Runs started by a schedule or a webhook commit as the bot, and are never signed.'**
  String get settingsCommitAuthorshipBotBody;

  /// Note: without a forge sign-in in a workspace, the person's runs there commit as the bot
  ///
  /// In en, this message translates to:
  /// **'Until you sign in to a forge in a workspace, your runs there commit as the bot.'**
  String get settingsCommitAuthorshipSignInNote;

  /// Personal toggle: add Control Center as co-author on the person's commits
  ///
  /// In en, this message translates to:
  /// **'Credit Control Center as co-author'**
  String get settingsCoauthorCreditTitle;

  /// What the co-author toggle does on the person's own commits and on automated runs they armed
  ///
  /// In en, this message translates to:
  /// **'Your commits name Control Center (@usectrl) as co-author, and automated runs you armed name you. When off, neither line is added.'**
  String get settingsCoauthorCreditDescription;

  /// Notice shown when a workspace setting locks the personal co-author toggle
  ///
  /// In en, this message translates to:
  /// **'This workspace overrides your personal choice. Your preference is saved but does not apply here.'**
  String get settingsCoauthorCreditWorkspaceOverride;

  /// Status shown while personal and workspace co-author settings load
  ///
  /// In en, this message translates to:
  /// **'Loading attribution settings…'**
  String get settingsCoauthorCreditLoading;

  /// Section label and select label for the workspace co-author credit policy
  ///
  /// In en, this message translates to:
  /// **'Co-author credit'**
  String get settingsWorkspaceCoauthorCreditTitle;

  /// Explains the workspace co-author credit policy and that it overrides each member's preference
  ///
  /// In en, this message translates to:
  /// **'Whether commits carry co-author lines: Control Center on a member\'s own commits, and the members who armed an automated run on its commits. A choice here overrides each member\'s own.'**
  String get settingsWorkspaceCoauthorCreditDescription;

  /// Workspace co-author option: each member's own preference applies
  ///
  /// In en, this message translates to:
  /// **'Use each member\'s preference'**
  String get settingsWorkspaceCoauthorCreditInherit;

  /// Workspace co-author option: co-author lines are always added
  ///
  /// In en, this message translates to:
  /// **'Always add co-author credit'**
  String get settingsWorkspaceCoauthorCreditAlways;

  /// Workspace co-author option: co-author lines are never added
  ///
  /// In en, this message translates to:
  /// **'Never add co-author credit'**
  String get settingsWorkspaceCoauthorCreditNever;

  /// Section label for the person's commit signing key
  ///
  /// In en, this message translates to:
  /// **'Verified commits'**
  String get settingsCommitSigningSection;

  /// Status tag: the person has a signing key, so their commits are signed
  ///
  /// In en, this message translates to:
  /// **'Signing'**
  String get settingsCommitSigningStatusOn;

  /// Status tag: the person has no signing key, so their commits are not signed
  ///
  /// In en, this message translates to:
  /// **'Not signing'**
  String get settingsCommitSigningStatusOff;

  /// Shown when the person has no signing key yet: what creating one does
  ///
  /// In en, this message translates to:
  /// **'This server can sign your commits with a key of your own, so GitHub and GitLab show them as verified. Nothing is signed until you create the key.'**
  String get settingsCommitSigningIntro;

  /// Button: create the person's commit signing key on the server
  ///
  /// In en, this message translates to:
  /// **'Create signing key'**
  String get settingsCommitSigningCreate;

  /// Toast after creating a signing key
  ///
  /// In en, this message translates to:
  /// **'Signing key created. Add it to your forge account.'**
  String get settingsCommitSigningCreated;

  /// Label above the SSH public key to copy
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get settingsCommitSigningPublicKeyLabel;

  /// Toast after copying the public key
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get settingsCommitSigningKeyCopied;

  /// Label before the key's SHA256 fingerprint
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get settingsCommitSigningFingerprintLabel;

  /// Label before the date the key was created
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get settingsCommitSigningCreatedLabel;

  /// Heading above the per-forge steps for adding the public key as a signing key
  ///
  /// In en, this message translates to:
  /// **'Add it to your forge account'**
  String get settingsCommitSigningAddTitle;

  /// Explains that a commit is verified only when the person is also signed in to that forge in the workspace
  ///
  /// In en, this message translates to:
  /// **'A commit shows as verified only while you are also signed in to that forge in the workspace, so the forge vouches for your email.'**
  String get settingsCommitSigningAddDescription;

  /// Steps on GitHub. 'Settings', 'SSH and GPG keys', 'New SSH key', 'Key type' and 'Signing Key' are GitHub's own English UI labels: keep them in English
  ///
  /// In en, this message translates to:
  /// **'Settings → SSH and GPG keys → New SSH key. Set Key type to Signing Key.'**
  String get settingsCommitSigningGitHubSteps;

  /// Steps on GitLab. 'Preferences', 'SSH Keys', 'Usage type' and 'Signing' are GitLab's UI labels: keep them in English
  ///
  /// In en, this message translates to:
  /// **'Preferences → SSH Keys. Set Usage type to Signing.'**
  String get settingsCommitSigningGitLabSteps;

  /// Bitbucket does not support signing with this key; warns not to add it there because a Bitbucket SSH key also grants access
  ///
  /// In en, this message translates to:
  /// **'Commits on Bitbucket are not signed. Do not add this key to your Bitbucket account: an SSH key there is also a login.'**
  String get settingsCommitSigningBitbucketSteps;

  /// Tag beside a forge that does not support this signing key
  ///
  /// In en, this message translates to:
  /// **'Not supported'**
  String get settingsCommitSigningUnsupported;

  /// Heading above the plain statements of what creating a signing key entrusts to the server
  ///
  /// In en, this message translates to:
  /// **'What you are trusting'**
  String get settingsCommitSigningTrustTitle;

  /// Trust statement: the private key never leaves the server and signs only the person's commits
  ///
  /// In en, this message translates to:
  /// **'The private key never leaves this server.'**
  String get settingsCommitSigningTrustPrivate;

  /// Trust statement: the server's operator can sign as the person while the key is on their forge account
  ///
  /// In en, this message translates to:
  /// **'Whoever controls this server can sign commits as you for as long as the key is on your forge account.'**
  String get settingsCommitSigningTrustControl;

  /// Trust statement: GitHub keeps already verified commits verified after the key is removed
  ///
  /// In en, this message translates to:
  /// **'On GitHub, commits already shown as verified stay verified after you remove the key.'**
  String get settingsCommitSigningTrustVerified;

  /// Button and confirm label: delete the person's signing key
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get settingsCommitSigningDelete;

  /// Confirmation dialog title for deleting the signing key
  ///
  /// In en, this message translates to:
  /// **'Delete your signing key?'**
  String get settingsCommitSigningDeleteTitle;

  /// Confirmation dialog body: consequences of deleting the signing key
  ///
  /// In en, this message translates to:
  /// **'Your commits are unsigned from now on. The key stays on your forge accounts until you remove it there.'**
  String get settingsCommitSigningDeleteBody;

  /// Toast after deleting the signing key
  ///
  /// In en, this message translates to:
  /// **'Signing key deleted'**
  String get settingsCommitSigningDeleted;

  /// Error shown when the signing key could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Could not load your signing key: {error}'**
  String settingsCommitSigningLoadFailed(String error);

  /// Settings > You > Profile: nav label and page title for the person's own account (username, name, picture, single sign-on identity) and, under their own heading, the accounts they connect
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfileTitle;

  /// Subtitle of Settings > You > Profile, the page that holds the person's profile and, under it, their connected accounts
  ///
  /// In en, this message translates to:
  /// **'Who you are in every workspace, and your own code hosting, ticketing, calendar and chat accounts.'**
  String get accountProfileDescription;

  /// Card label on Settings > You > Profile holding username, display name, email and picture
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// Explains account-wide fields vs the per-workspace overlay. 'Workspace → Profile & identity' must match the nav labels settingsScopeWorkspace and settingsProfile
  ///
  /// In en, this message translates to:
  /// **'Your username and name follow you into every workspace. A workspace can show a different name or email: set that in Workspace → Profile & identity.'**
  String get accountSectionDescription;

  /// Error shown when the person's own account row cannot be read; error is a server message
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile: {error}'**
  String accountLoadFailed(String error);

  /// Hint under the Display name field (account profile and onboarding 'You' step)
  ///
  /// In en, this message translates to:
  /// **'The name people see on your messages and reviews.'**
  String get accountDisplayNameHint;

  /// Validation error when the display name field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a display name.'**
  String get accountDisplayNameRequired;

  /// Validation error when the person empties the email or picture field, which the server cannot clear
  ///
  /// In en, this message translates to:
  /// **'This can be changed but not removed.'**
  String get accountFieldCannotBeCleared;

  /// Label of the profile picture (avatar image link) field
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get accountAvatarLabel;

  /// Hint under the profile picture field. Keep 'https://' literal
  ///
  /// In en, this message translates to:
  /// **'A link to a square image, starting with https://.'**
  String get accountAvatarHint;

  /// Validation error for a profile picture link that is not an https URL. Keep 'https://' literal
  ///
  /// In en, this message translates to:
  /// **'Use a link that starts with https://.'**
  String get accountAvatarInvalid;

  /// Label of the username field (the person's unique @name). Use the same term everywhere for 'username'
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Hint under the username field describing the rule
  ///
  /// In en, this message translates to:
  /// **'2 to 32 lowercase letters, digits, dots, dashes or underscores. People mention you with it.'**
  String get usernameRule;

  /// Status under the username field: the typed name is free
  ///
  /// In en, this message translates to:
  /// **'Available.'**
  String get usernameAvailable;

  /// Status under the username field when the typed name is free but is stored normalized (lowercased); username is ASCII
  ///
  /// In en, this message translates to:
  /// **'Available. It will be saved as {username}.'**
  String usernameAvailableAs(String username);

  /// Error under the username field: the name breaks the rule. Keep the three quoted characters literal
  ///
  /// In en, this message translates to:
  /// **'Use 2 to 32 lowercase letters, digits, “.”, “_” or “-”, starting and ending with a letter or digit.'**
  String get usernameInvalid;

  /// Error under the username field: nobody may hold this name
  ///
  /// In en, this message translates to:
  /// **'That username is reserved.'**
  String get usernameReserved;

  /// Error under the username field: someone else has this name
  ///
  /// In en, this message translates to:
  /// **'That username is taken.'**
  String get usernameTaken;

  /// Status under the username field when the availability check failed
  ///
  /// In en, this message translates to:
  /// **'Could not check this name right now. You can still save; the server decides.'**
  String get usernameCheckFailed;

  /// Heading on Settings > You > Profile over the accounts a person connects for themself (code hosting, ticketing, calendar, chat). Also the link text on Workspace > Integrations that leads there, and a command palette entry
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get linkedAccountsTitle;

  /// Row title on Settings > You > Profile for the single sign-on (SAML/OIDC) identity the account is pinned to
  ///
  /// In en, this message translates to:
  /// **'Identity provider'**
  String get linkedAccountsIdentityProvider;

  /// State of one of the reader's own accounts in the summary line on Settings > Workspace > Integrations (the detail of yourAccountEntry): the provider refused the sign-in or it expired
  ///
  /// In en, this message translates to:
  /// **'Needs sign-in'**
  String get linkedAccountStatusNeedsSignIn;

  /// State of one of the reader's own accounts in the summary line on Settings > Workspace > Integrations (the detail of yourAccountEntry): parked because the workspace's sign-in service changed
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get linkedAccountStatusPaused;

  /// State of one of the reader's own accounts in the summary line on Settings > Workspace > Integrations (the detail of yourAccountEntry): its renewal failed for now
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get linkedAccountStatusUnreachable;

  /// Subtitle of the Single sign-on card on Settings > You > Profile, shown only when the account is pinned to an identity provider
  ///
  /// In en, this message translates to:
  /// **'The identity provider your account signs in through. Whoever runs this server manages it.'**
  String get ssoIdentityDescription;

  /// Text under the Connected accounts heading on Settings > You > Profile. Keep 'Control Center' untranslated
  ///
  /// In en, this message translates to:
  /// **'The accounts you connect for yourself. Control Center acts as you through them, and changing them affects only you.'**
  String get settingsAccountsDescription;

  /// One line on a connected account's card on Settings > You > Profile: the account applies in every workspace on this server
  ///
  /// In en, this message translates to:
  /// **'Used in every workspace on this server.'**
  String get accountReachServer;

  /// One line on a connected account's card on Settings > You > Profile: the account applies only in the named workspace (the one settings were opened from)
  ///
  /// In en, this message translates to:
  /// **'Used only in {workspace}.'**
  String accountReachWorkspace(String workspace);

  /// Code hosting card line on Settings > You > Profile when the current workspace has its own sign-in apps (its own GitHub App or its own Connect; same term as workspaceConnectSwitchTitle), so the GitHub sign-in is kept for that workspace only. Keep GitHub, GitLab and Bitbucket untranslated
  ///
  /// In en, this message translates to:
  /// **'GitHub is used only in {workspace}, which has its own sign-in apps. GitLab and Bitbucket are used in every workspace on this server.'**
  String forgeReachGitHubOwnApp(String workspace);

  /// Leading label of the one-line summary of the reader's own account at the top of a provider group on Settings > Workspace > Integrations
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccountLabel;

  /// One account in the summary line on Settings > Workspace > Integrations; provider is a service name (GitHub, Linear, Slack), detail is the account name or its state (for example 'Needs sign-in')
  ///
  /// In en, this message translates to:
  /// **'{provider}: {detail}'**
  String yourAccountEntry(String provider, String detail);

  /// Screen reader label of the account summary line on Settings > Workspace > Integrations. 'You → Profile' must match the nav labels settingsScopeYou and accountProfileTitle
  ///
  /// In en, this message translates to:
  /// **'Your account: {status}. Opens You → Profile.'**
  String yourAccountLineSemantics(String status);

  /// Account summary line on Settings > Workspace > Integrations > code hosting when the reader has connected no GitHub, GitLab or Bitbucket account
  ///
  /// In en, this message translates to:
  /// **'No code hosting account connected'**
  String get yourForgeAccountNone;

  /// Account summary line on Settings > Workspace > Integrations when the reader has not signed in to the provider
  ///
  /// In en, this message translates to:
  /// **'No {provider} account connected'**
  String yourAccountNotConnected(String provider);

  /// Account summary line on Settings > Workspace > Integrations > chat when the reader has not linked their chat account
  ///
  /// In en, this message translates to:
  /// **'No {provider} account linked'**
  String yourChatAccountNotLinked(String provider);

  /// Demo notice on Settings > You > Profile
  ///
  /// In en, this message translates to:
  /// **'You are a temporary guest in the demo, so there is no account to change: no username, profile or connected accounts.'**
  String get demoUnavailableAccount;

  /// Onboarding progress-bar label of the first step, where the person chooses their username and display name
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get onboardingStepYou;

  /// Title of the onboarding 'You' step
  ///
  /// In en, this message translates to:
  /// **'Choose your username'**
  String get onboardingYouTitle;

  /// Lead of the onboarding 'You' step. 'Settings → You → Profile' must match the nav labels settingsScopeYou and accountProfileTitle
  ///
  /// In en, this message translates to:
  /// **'Your username is how people mention you and how your work is labeled. You can change it and your display name later in Settings → You → Profile.'**
  String get onboardingYouSubtitle;

  /// Sign-in failure: the provider account the person signed in with is already held by another person on this server; one account acts for one person only
  ///
  /// In en, this message translates to:
  /// **'This {provider} account is already connected to another person on this server. Sign in with a different {provider} account.'**
  String signInErrorAccountAlreadyBound(String provider);

  /// Settings → Code hosting: under a forge row, when the pasted GitLab/Bitbucket token stops working. Hovering the line shows the exact time
  ///
  /// In en, this message translates to:
  /// **'Token expires {date}'**
  String forgeTokenExpiresOn(String date);

  /// Settings → Code hosting: warning under a forge row once the pasted token has expired
  ///
  /// In en, this message translates to:
  /// **'Token expired {date}. Paste a new one to keep working.'**
  String forgeTokenExpiredOn(String date);

  /// Token dialog error: the server could not ask the forge about the pasted token (offline, rate limited)
  ///
  /// In en, this message translates to:
  /// **'{forge} could not be reached to check this token. Try again in a moment.'**
  String personTokenUnreachable(String forge);

  /// Token dialog error: the forge refused the pasted token (wrong, revoked, or for Bitbucket the wrong email)
  ///
  /// In en, this message translates to:
  /// **'{forge} does not accept this token. Check that you copied all of it and that it has not been revoked.'**
  String personTokenRejected(String forge);

  /// Token dialog error: the pasted token belongs to a bot, project, group or workspace instead of the person
  ///
  /// In en, this message translates to:
  /// **'This is not a personal token. Paste a personal access token from your own {forge} account, not a project, group, workspace or bot token.'**
  String personTokenWrongKind(String forge);

  /// Token dialog error: the pasted token lacks a permission. {scope} is the forge's own scope name, e.g. api or write:pullrequest:bitbucket; keep it as is
  ///
  /// In en, this message translates to:
  /// **'This token is missing the {scope} scope, which reviewing and commenting need. Create one that has it.'**
  String personTokenNarrowScope(String scope);

  /// Token dialog error: the pasted token is already expired
  ///
  /// In en, this message translates to:
  /// **'This token has expired. Create a new one and paste it here.'**
  String get personTokenExpired;

  /// Settings → You → Commits → Verified commits, "What you are trusting" list. "Deleting the key here" = the Delete key action on this page, not removing it from the forge
  ///
  /// In en, this message translates to:
  /// **'Agents you start can make commits signed as you, in any repository they work in. Deleting the key here stops that at once: runs already under way sign nothing further.'**
  String get settingsCommitSigningTrustAgents;

  /// Settings → Connect: toast when rotating the server's Connect key failed (for example Connect could not be reached). The old key and id keep working; the Rotate key button stays for another try. {error} is the server's sentence
  ///
  /// In en, this message translates to:
  /// **'The key was not rotated, and nothing changed: {error} Try again.'**
  String connectRotateKeyFailed(String error);

  /// Workspace picker, shown to a signed-in person who belongs to no workspace and may not create one (only the server owner can). Title of a calm dead end, not an error.
  ///
  /// In en, this message translates to:
  /// **'You are not in a workspace yet'**
  String get noWorkspaceInviteTitle;

  /// Body under noWorkspaceInviteTitle. 'Invite' = an admin adds them to an existing workspace; 'the server owner' = the person who runs this Control Center server.
  ///
  /// In en, this message translates to:
  /// **'A workspace admin has to invite you, or the server owner can create a workspace for you. It opens here as soon as you are added.'**
  String get noWorkspaceInviteBody;

  /// Small line under noWorkspaceInviteBody, reassuring the person that their sign-in worked.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String noWorkspaceSignedInAs(String name);

  /// Button on the no-workspace dead end: re-reads whether they were added to a workspace (or may now create one).
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get noWorkspaceCheckAgain;

  /// Button on the no-workspace dead end: leaves this server for the server sign-in screen, so they can sign in as someone else or pick another server.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get noWorkspaceSignOut;

  /// Error in the new-workspace form when the server refuses because only its owner may create workspaces (their right was withdrawn after the form opened).
  ///
  /// In en, this message translates to:
  /// **'Only the server owner can create workspaces. Ask them to create one, or ask a workspace admin to invite you.'**
  String get workspaceCreateOwnerOnly;

  /// Toast when a link names a repository no workspace links, the person is in no workspace, and they may not create one.
  ///
  /// In en, this message translates to:
  /// **'{repo} is not in any of your workspaces, and you are not in a workspace to add it to. Ask a workspace admin to invite you.'**
  String repoLinkNoWorkspaceToAddTo(String repo);

  /// Shared title when the server refused something only its owner (the person who runs this Control Center server) may do. Used for the embedded editor today.
  ///
  /// In en, this message translates to:
  /// **'Only the server owner can do this'**
  String get serverOwnerOnly;

  /// Under serverOwnerOnly in an editor tab when opening the embedded VS Code editor was refused. 'Explorer' is the IDE's file tree panel, whose built-in single-file editor everyone can still use
  ///
  /// In en, this message translates to:
  /// **'The full editor runs on the server\'s own machine, so only the server\'s owner can open it. You can still open and edit files from the Explorer.'**
  String get ideCodeServerOwnerOnlyHint;

  /// Small badge above a terminal that runs inside the sandbox (not directly on the server host)
  ///
  /// In en, this message translates to:
  /// **'Sandboxed'**
  String get terminalSandboxedBadge;

  /// One line beside terminalSandboxedBadge, for someone who is not the server owner: why some things are missing in their terminal
  ///
  /// In en, this message translates to:
  /// **'Runs in a sandbox inside this workspace\'s folders, so some host tools and paths are not available here.'**
  String get terminalSandboxedHint;

  /// Terminal panel, when the server refused an unsandboxed host shell to someone who is not its owner
  ///
  /// In en, this message translates to:
  /// **'The host shell runs on the server without a sandbox, so only the server owner can open one. A regular terminal runs in the sandbox.'**
  String get terminalHostShellOwnerOnly;

  /// Terminal panel, when the server refused a working directory outside the workspace's directories
  ///
  /// In en, this message translates to:
  /// **'A terminal can only open inside this workspace\'s own folders.'**
  String get terminalOutsideWorkspace;

  /// Settings → Environments, when saving or approving a definition was refused because it places something on the server host. 'Rig' = an isolated machine Control Center boots for the environment (keep the product term)
  ///
  /// In en, this message translates to:
  /// **'Only the server owner can save or approve an environment that runs on the server host. A workspace admin can use one that runs in a rig.'**
  String get environmentHostOwnerOnly;

  /// You → Commits, in the list of what to know about commits made here. 'git commit --no-verify' is a literal command; keep it verbatim
  ///
  /// In en, this message translates to:
  /// **'Commits you make in the app\'s own editor run no Git hooks from the repository, as with git commit --no-verify: the server runs Git on its own host, in a tree that agents and pull requests can change.'**
  String get settingsCommitsNoHooks;

  /// Settings → MCP servers, under the Authentication token label, for the server owner. 'Authorization: Bearer' is the literal HTTP header; keep it verbatim
  ///
  /// In en, this message translates to:
  /// **'MCP clients send this token with every request, as an Authorization: Bearer header. The server creates it on first start; you can rotate it but not remove it.'**
  String get mcpTokenDescription;

  /// Button: reveals the MCP token (as the header line to copy). Server owner only
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get mcpShowToken;

  /// Button: hides the MCP token again
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get mcpHideToken;

  /// Button, and the confirm button of the rotate dialog: replaces the MCP token with a new random one
  ///
  /// In en, this message translates to:
  /// **'Rotate token'**
  String get mcpRotateToken;

  /// Title of the confirm dialog before rotating the MCP token
  ///
  /// In en, this message translates to:
  /// **'Rotate the MCP token?'**
  String get mcpRotateTokenTitle;

  /// Body of the rotate-token confirm dialog: the consequence
  ///
  /// In en, this message translates to:
  /// **'The server switches to a new token right away. Every MCP client still using the current one is refused until you give it the new one.'**
  String get mcpRotateTokenBody;

  /// Toast after the MCP token was rotated; the new token is shown in the card
  ///
  /// In en, this message translates to:
  /// **'Token rotated. Give your MCP clients the new one.'**
  String get mcpTokenRotated;

  /// Settings → MCP servers, for someone who is not the server owner. Informational, not an error
  ///
  /// In en, this message translates to:
  /// **'The MCP endpoint is for the server owner'**
  String get mcpOwnerOnlyTitle;

  /// Under mcpOwnerOnlyTitle
  ///
  /// In en, this message translates to:
  /// **'Its token opens every tool on this server, so only the server owner can see it, rotate it, or start and stop the endpoint.'**
  String get mcpOwnerOnlyBody;

  /// Activity log entry: someone rotated the server's MCP token (op mcp.rotateToken)
  ///
  /// In en, this message translates to:
  /// **'Rotated the MCP token'**
  String get activityRotatedMcpToken;

  /// Settings → Connect, dialog title after Rotate key failed because a Connect could not retire the old key. The server's own explanation (which Connect, which error code) is shown under it
  ///
  /// In en, this message translates to:
  /// **'Connect could not retire the old key'**
  String get connectRotateKeyRetireFailedTitle;

  /// Same dialog, under the server's explanation: what 'Rotate anyway' leaves behind. 'Connect' = Control Center Connect (product name)
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. If you rotate anyway, this server gets its new key, but the old identity stays usable at that Connect until its sign-ins expire.'**
  String get connectRotateKeyForceBody;

  /// Destructive button in that dialog: rotates the key even though a Connect could not retire the old one
  ///
  /// In en, this message translates to:
  /// **'Rotate anyway'**
  String get connectRotateKeyAnyway;

  /// Settings → Server navigation entry and page title: one table of who changed what across the server and the workspaces the person administers
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get settingsAuditLog;

  /// Subtitle of the Audit log page
  ///
  /// In en, this message translates to:
  /// **'Who changed what, where and how it ended, across the server and every workspace you administer. Server operations record argument names, never their values.'**
  String get settingsAuditLogDescription;

  /// Alert title on the Audit log page for someone who is neither the server owner nor a workspace admin
  ///
  /// In en, this message translates to:
  /// **'Admins only'**
  String get auditLogNoAccessTitle;

  /// Alert body under auditLogNoAccessTitle
  ///
  /// In en, this message translates to:
  /// **'The audit log covers the server and the workspaces you administer. You don\'t administer any workspace, so there\'s nothing to show.'**
  String get auditLogNoAccess;

  /// Where an audit record happened: the whole server (install-wide settings), as opposed to a workspace. Shown on rows and as a filter option
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get auditLogSourceServer;

  /// Fallback name for a workspace whose name is unknown, on an audit log row
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get auditLogSourceWorkspace;

  /// Audit log toolbar button that opens the filter menu
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get auditLogAddFilter;

  /// Placeholder of the search field inside a filter flyout (e.g. the list of actors)
  ///
  /// In en, this message translates to:
  /// **'Filter…'**
  String get auditLogFilterOptionsHint;

  /// Audit log filter category: the person who made the change
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get auditLogFilterActor;

  /// Audit log filter category: which workspace (or the server) the change happened in
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get auditLogFilterSource;

  /// Audit log filter category: how the operation ended (succeeded, denied, failed)
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get auditLogFilterOutcome;

  /// Audit log toolbar button that adds a time condition
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get auditLogFilterTime;

  /// Active filter chip, e.g. 'Actor: Ada, Riley'. {category} is a filter category name, {values} the selected values
  ///
  /// In en, this message translates to:
  /// **'{category}: {values}'**
  String auditLogFilterChip(String category, String values);

  /// Selected values of a filter chip when more than two are selected: the first two, then how many more, e.g. 'Ada, Riley +3'
  ///
  /// In en, this message translates to:
  /// **'{values} +{count}'**
  String auditLogFilterChipMore(String values, int count);

  /// Audit outcome: the operation ran and returned
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get auditLogOutcomeOk;

  /// Audit outcome: a permission check refused the operation before it ran
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get auditLogOutcomeDenied;

  /// Audit outcome: the operation ran and threw an error
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get auditLogOutcomeFailed;

  /// Time filter comparison ≥ in words
  ///
  /// In en, this message translates to:
  /// **'On or after'**
  String get auditLogTimeAtOrAfter;

  /// Time filter comparison > in words
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get auditLogTimeAfter;

  /// Time filter comparison < in words
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get auditLogTimeBefore;

  /// Time filter comparison ≤ in words
  ///
  /// In en, this message translates to:
  /// **'On or before'**
  String get auditLogTimeAtOrBefore;

  /// Active time filter chip, e.g. 'Time ≥ Nov 10, 2026 14:30'. {operator} is a comparison symbol (or its words for screen readers), {time} a formatted date and time
  ///
  /// In en, this message translates to:
  /// **'Time {operator} {time}'**
  String auditLogTimeChip(String operator, String time);

  /// Time filter preset: the instant one hour before now
  ///
  /// In en, this message translates to:
  /// **'1 hour ago'**
  String get auditLogTimePresetHour;

  /// Time filter preset: the instant 24 hours before now
  ///
  /// In en, this message translates to:
  /// **'24 hours ago'**
  String get auditLogTimePresetDay;

  /// Time filter preset: the instant 7 days before now
  ///
  /// In en, this message translates to:
  /// **'7 days ago'**
  String get auditLogTimePresetWeek;

  /// Time filter preset: the instant 30 days before now
  ///
  /// In en, this message translates to:
  /// **'30 days ago'**
  String get auditLogTimePresetMonth;

  /// Label above the field where a date and time is typed for a time filter
  ///
  /// In en, this message translates to:
  /// **'Exact time'**
  String get auditLogTimeExact;

  /// Error under the exact-time field when the typed text is not a date. Keep YYYY-MM-DD and HH:MM literally
  ///
  /// In en, this message translates to:
  /// **'Use YYYY-MM-DD, optionally with HH:MM'**
  String get auditLogTimeInvalid;

  /// Button that adds the typed exact time as a filter condition
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get auditLogTimeAdd;

  /// Repository access notice (pull requests, Settings → Repositories) when the linked owner/name now names a different repository on the forge (deleted and re-created, or moved and replaced). Nothing is sent to it until an admin relinks it
  ///
  /// In en, this message translates to:
  /// **'{repo} now points to a different repository'**
  String repoAccessReplacedTitle(String repo);

  /// Under repoAccessReplacedTitle. 'Path' = the repository's owner/name on the forge. A member also sees who to ask, appended after it
  ///
  /// In en, this message translates to:
  /// **'This path now points to a different repository on {forge}. Relink it to keep using it.'**
  String repoAccessReplacedBody(String forge);

  /// Button on that notice, for workspace admins only: links the repository again, so the server checks it with the admin's own forge sign-in and pins the new repository
  ///
  /// In en, this message translates to:
  /// **'Relink'**
  String get repoRelink;

  /// Toast after Relink succeeded
  ///
  /// In en, this message translates to:
  /// **'Relinked {repo}.'**
  String repoRelinked(String repo);

  /// Code views (file content, terminal in a space) when the server refused because the repository was replaced on its forge
  ///
  /// In en, this message translates to:
  /// **'This path now points to a different repository. A workspace admin has to relink it before it can be used.'**
  String get repoCodeRepoReplaced;

  /// Code views (file content, a terminal in a space) when the server refused because the person's own forge account cannot read a repository in the space
  ///
  /// In en, this message translates to:
  /// **'Your {forge} account can\'t read this repository.'**
  String repoCodeForgeCannotRead(String forge);

  /// Same place, when the forge could not be asked whether the person can read the repository; a retry is offered
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm your {forge} access. Try again.'**
  String repoCodeForgeUnconfirmed(String forge);

  /// repoCodeForgeCannotRead when the server did not name the forge. 'Forge' = the code host (GitHub, GitLab, Bitbucket)
  ///
  /// In en, this message translates to:
  /// **'Your forge account can\'t read this repository.'**
  String get repoCodeForgeCannotReadUnnamed;

  /// repoCodeForgeUnconfirmed when the server did not name the forge
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm your forge access. Try again.'**
  String get repoCodeForgeUnconfirmedUnnamed;

  /// Linking or relinking a repository was refused: its folder lies outside the workspace's storage on the server
  ///
  /// In en, this message translates to:
  /// **'Only the server\'s owner can link a folder outside this workspace\'s storage.'**
  String get repoPathHostPath;

  /// Linking a repository was refused: no folder at that path on the server
  ///
  /// In en, this message translates to:
  /// **'Nothing exists at that path on the server.'**
  String get repoPathMissing;

  /// Linking a repository was refused: the folder is inside the server's own data folder
  ///
  /// In en, this message translates to:
  /// **'A repository can\'t point into the server\'s data folder.'**
  String get repoPathDataDir;

  /// Linking a repository was refused: the folder is the workspace's root folder itself
  ///
  /// In en, this message translates to:
  /// **'A repository can\'t be the workspace\'s own folder.'**
  String get repoPathWorkspaceRoot;

  /// Linking a repository was refused: the git origin of the folder names another repository than the one being linked
  ///
  /// In en, this message translates to:
  /// **'That folder\'s origin is a different repository.'**
  String get repoPathOriginMismatch;

  /// Member repository access dialog, under a repository row right after its grant was saved: the member is not signed in to its forge
  ///
  /// In en, this message translates to:
  /// **'Saved. They need to sign in to {forge} before they can open this repository.'**
  String repoGrantNeedsSignIn(String forge);

  /// Same place: the member's own forge account cannot read the repository
  ///
  /// In en, this message translates to:
  /// **'Saved. Their {forge} account can\'t read this repository yet, so it stays hidden from them.'**
  String repoGrantCannotRead(String forge);

  /// Same place: the forge could not be asked whether the member can read it
  ///
  /// In en, this message translates to:
  /// **'Saved. Couldn\'t confirm their {forge} access right now.'**
  String repoGrantUnconfirmed(String forge);

  /// Toast when someone who is not the server owner opens a repository link (e.g. from the browser extension) for a repository no workspace of theirs links. Adding one means picking a folder on the server's machine, which only the server owner (the person who runs this Control Center server) may do
  ///
  /// In en, this message translates to:
  /// **'{repo} is not linked in any of your workspaces. Ask the server owner to add it.'**
  String repoLinkAskOwnerToAdd(String repo);

  /// Settings → Repositories, empty list, for someone who is not the server owner: why there is no Add button. 'Server owner' = the person who runs this Control Center server
  ///
  /// In en, this message translates to:
  /// **'The server owner adds repositories from the server\'s folders.'**
  String get reposEmptyAskOwner;

  /// Under the email field in the person's own profile settings while their address is unconfirmed (they typed it themselves; neither their identity provider nor the server owner has vouched for it)
  ///
  /// In en, this message translates to:
  /// **'Only you have entered this address. Single sign-on won\'t match it until the server\'s owner confirms it.'**
  String get accountEmailUnconfirmedHint;

  /// Settings → Server navigation item and page title: every account on this server. Server owner only
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get settingsServerPeople;

  /// Subtitle of Settings → Server → People
  ///
  /// In en, this message translates to:
  /// **'Everyone with an account on this server, and whether their email address is confirmed.'**
  String get settingsServerPeopleDescription;

  /// Section label above the list of accounts on Settings → Server → People
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get serverPeopleLabel;

  /// Settings → Server → People, under serverOwnerOnly, for anyone who is not the server owner; also a toast when the server refused to confirm an address for that reason
  ///
  /// In en, this message translates to:
  /// **'Only the server\'s owner can see everyone\'s account and confirm email addresses.'**
  String get serverPeopleOwnerOnly;

  /// Status tag on an account row in Settings → Server → People (shown to the server owner only) when the person typed their email address themselves and nobody has vouched for it
  ///
  /// In en, this message translates to:
  /// **'Email not confirmed'**
  String get serverPeopleEmailNotConfirmed;

  /// Row action (icon button tooltip), confirmation dialog title and its confirm button on Settings → Server → People: the server owner vouches that the address belongs to that person
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get serverPeopleConfirmEmail;

  /// Body of the Confirm email dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm that {email} belongs to {name}? Single sign-on will match this address to their account.'**
  String serverPeopleConfirmEmailBody(String email, String name);

  /// Toast after the server owner confirmed an email address
  ///
  /// In en, this message translates to:
  /// **'Confirmed {email}.'**
  String serverPeopleEmailConfirmed(String email);

  /// Title of the notice in a chat turn (and the run's title in its activity tab) when the server refused to start an agent run because it has no sandbox and the person is not the server owner. Guidance, not an error
  ///
  /// In en, this message translates to:
  /// **'Agents need a sandbox on this server'**
  String get runSandboxUnavailableTitle;

  /// Body of that notice. 'Owner' = the person who runs this Control Center server; 'sandbox' = the isolation agents run in
  ///
  /// In en, this message translates to:
  /// **'This server has no sandbox, so only its owner can run agents here. The owner can install the sandbox or turn sandboxing off for everyone.'**
  String get runSandboxUnavailable;

  /// Settings → Repositories, under a repository the server lists but does not serve (no IDE, environments, terminals, index) until it is confirmed, shown to the server owner, next to a Confirm button. Every checkout linked from a desktop before this rule shows it once
  ///
  /// In en, this message translates to:
  /// **'This folder is outside the workspace\'s storage. Confirm that this server may use it.'**
  String get repoPathIssueHostPath;

  /// Same notice for anyone who is not the server owner (no button)
  ///
  /// In en, this message translates to:
  /// **'This folder is outside the workspace\'s storage. Only the server\'s owner can confirm it.'**
  String get repoPathIssueHostPathAskOwner;

  /// Settings → Repositories, under a repository whose folder no longer exists on the server. Workspace admins see a Remove button beside it; no action re-points an existing repository's folder
  ///
  /// In en, this message translates to:
  /// **'Nothing exists at this path on the server anymore. Remove this repository and add it again from its current folder.'**
  String get repoPathIssueMissing;

  /// Settings → Repositories, under a repository whose folder is the server's own data folder or the workspace's storage root. Workspace admins see a Remove button beside it
  ///
  /// In en, this message translates to:
  /// **'This folder can\'t be used as a repository. Remove it and add the repository from another folder.'**
  String get repoPathIssueUnusable;

  /// Button next to repoPathIssueHostPath: the server owner confirms the server may use the folder (the server re-checks the link as them)
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get repoPathConfirm;

  /// Button above the repository list when more than one repository waits for that confirmation; confirms them one after another
  ///
  /// In en, this message translates to:
  /// **'Confirm all'**
  String get repoPathConfirmAll;

  /// Title of the notice above the repository list that carries Confirm all
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder is outside the workspace\'s storage} other{{count} folders are outside the workspace\'s storage}}'**
  String repoPathConfirmAllTitle(int count);

  /// Body of that notice
  ///
  /// In en, this message translates to:
  /// **'Confirm that this server may use them. Each repository is checked again with your access.'**
  String get repoPathConfirmAllBody;

  /// Second line under the External MCP servers title in Settings → Server → MCP (seen by the server owner). 'This machine's own tool settings' = the MCP configs of Claude, Cursor, VS Code etc. on the server's own OS account; 'MCP endpoint' = the MCP server Control Center itself exposes
  ///
  /// In en, this message translates to:
  /// **'Servers found in this machine\'s own tool settings are available only in runs you start or are accountable for. Other people\'s runs never see them, and they aren\'t offered through Control Center\'s MCP endpoint.'**
  String get mcpExternalServersOwnerRunsOnly;

  /// Code views (the Explorer's file tree and searches, a file, a diff) when the server refused because the person has no sign-in of their own for the repository's forge. Shown with a 'Sign in' action
  ///
  /// In en, this message translates to:
  /// **'Sign in to {provider} to see this repository\'s code.'**
  String repoCodeNeedsSignIn(String provider);

  /// Action beside repoCodeNeedsSignIn in the Explorer tree row and code panes; opens the sign-in prompt for the person's forge account
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get repoCodeSignIn;

  /// Explorer, 'search in files' (content search) mode: the search failed for a reason that is not an access refusal. Sibling of ideFileSearchFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search in files'**
  String get ideContentSearchFailed;

  /// Quick-fix file editor (conversation IDE, PR workbench) when the file could not be read from the conversation's own copy of the repository. Shown with a 'Retry' action
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t available in this worktree.'**
  String get ideWorktreeFileUnavailable;

  /// Review tab of the conversation IDE (the branch diff) when the diff could not be loaded for a reason that is not an access refusal. Shown with a 'Retry' action
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the changes'**
  String get ideChangesLoadFailed;

  /// Code views (Explorer tree and searches, a file, a diff, a terminal in a space) when the server refused because the linked repository's owner/name now names a different repository on the forge. The forge-named sibling of repoCodeRepoReplaced, used when the server names the forge
  ///
  /// In en, this message translates to:
  /// **'This path now points to a different repository on {forge}. A workspace admin has to relink it before it can be used.'**
  String repoCodeRepoReplacedOn(String forge);

  /// Settings → Server → Backup & restore, in place of the Restore buttons and the restore/import fields, for anyone who is not the server owner. Restoring replaces a workspace's data with a file on the server's own machine, so it is the owner's; downloading stays available
  ///
  /// In en, this message translates to:
  /// **'Only the server owner can restore backups. You can still download them.'**
  String get backupRestoreServerOwnerOnly;

  /// Small badge above a terminal the person may watch but not type into (an environment's setup or process terminal they lack the right to operate)
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get terminalReadOnlyBadge;

  /// One quiet line beside terminalReadOnlyBadge, above a read-only terminal. 'Conversation' = the space whose environment runs the terminal; 'write access' = the person's write grant on each repository there (admins have it)
  ///
  /// In en, this message translates to:
  /// **'You can watch this terminal. Typing in it, resizing or stopping it needs write access to every repository in this conversation.'**
  String get terminalReadOnlyHint;

  /// One quiet line in the Environment panel and sidebar section when the person may see the environment but not operate it; its start/stop/restart/launch controls are disabled. 'Write access' = the person's write grant on each repository in the conversation (admins have it)
  ///
  /// In en, this message translates to:
  /// **'You can watch this environment. Starting, stopping or restarting it needs write access to every repository in this conversation.'**
  String get environmentOperateNeedsWrite;

  /// Settings → Environments, a quiet line under a definition (in the list and at the top of its editor) that runs something on the server's own machine and has no approval from the current server owner. Seen by the server owner, beside an 'Approve' button that saves the definition unchanged
  ///
  /// In en, this message translates to:
  /// **'Runs on this server. Approve it to let it start.'**
  String get environmentHostApprovalOwner;

  /// Same place as environmentHostApprovalOwner, for anyone who is not the server owner; no action
  ///
  /// In en, this message translates to:
  /// **'Runs on this server. The server owner has to approve it before it can start.'**
  String get environmentHostApprovalMember;

  /// Button beside environmentHostApprovalOwner; the server owner approves the definition by saving it unchanged
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get environmentHostApprove;

  /// Error under the approval notice when the server owner is not a workspace admin, so the definition they see has its secret values hidden and cannot be saved back unchanged
  ///
  /// In en, this message translates to:
  /// **'Approve it as a workspace admin: only an admin\'s copy shows its secret values, and approving saves them back.'**
  String get environmentHostApproveNeedsAdmin;

  /// Environment panel in a conversation (and the toast after a refused start, restart, task, exec, check, setup or test) when the environment's definition runs on the server's own machine and the current server owner has not approved it. Seen by anyone but the server owner
  ///
  /// In en, this message translates to:
  /// **'The server owner hasn\'t approved this environment yet, so it can\'t run on this server.'**
  String get environmentHostUnapproved;

  /// Same situation as environmentHostUnapproved, seen by the server owner; in the panel it sits beside environmentHostApprovalReview
  ///
  /// In en, this message translates to:
  /// **'You haven\'t approved this environment yet. It runs on this server, so it starts once you approve its definition.'**
  String get environmentHostUnapprovedOwner;

  /// Button beside environmentHostUnapprovedOwner in the Environment panel; opens the environment's definition in Settings, where the owner approves it
  ///
  /// In en, this message translates to:
  /// **'Review and approve'**
  String get environmentHostApprovalReview;

  /// In place of a whole space (conversation workspace) the person opened from a link, a notification or the last space they had open, when the server refused because they are not signed in to the forge that hosts one of the space's repositories. Followed by a Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign in to {provider} to open this space.'**
  String spaceAccessNeedsSignIn(String provider);

  /// In place of a whole space when the person's own forge account cannot read one of the repositories the space uses, so the server will not show the space to them
  ///
  /// In en, this message translates to:
  /// **'Your {forge} account can\'t read a repository this space uses.'**
  String spaceAccessForgeCannotRead(String forge);

  /// Same as spaceAccessForgeCannotRead, when the server's refusal does not name the forge
  ///
  /// In en, this message translates to:
  /// **'Your forge account can\'t read a repository this space uses.'**
  String get spaceAccessForgeCannotReadUnnamed;

  /// In place of a whole space when the person holds no read grant on one of the repositories the space uses
  ///
  /// In en, this message translates to:
  /// **'You don\'t have read access to a repository this space uses. A workspace admin can grant it.'**
  String get spaceAccessNoGrant;

  /// In place of a whole space when opening it failed for a reason other than access, with a Retry button
  ///
  /// In en, this message translates to:
  /// **'This space couldn\'t be opened.'**
  String get spaceAccessFailed;

  /// Context explorer tab (what an agent holds in its context window), when the server refuses the inspection for this kind of session or person; no retry is offered
  ///
  /// In en, this message translates to:
  /// **'The context breakdown isn\'t available in this session.'**
  String get contextExplorerRefused;

  /// Toast after saving a repository's forge link (owner/organization and repository name) when the server refused because one of them was cleared
  ///
  /// In en, this message translates to:
  /// **'A linked repository needs both an owner and a repository name.'**
  String get repoLinkForgeRemoteRequired;

  /// Code views (Explorer, a file, a diff, search) and repository actions when the server refused because the person holds no Control Center read grant on the repository
  ///
  /// In en, this message translates to:
  /// **'You don\'t have read access to this repository. A workspace admin can grant it.'**
  String get repoCodeNoReadGrant;

  /// Toast when saving a file, reverting, committing, pushing, publishing, syncing or checking out a branch, or moving a stack part was refused because the person holds only a read grant on the repository
  ///
  /// In en, this message translates to:
  /// **'You can read this repository but not change it. A workspace admin can grant write access.'**
  String get repoCodeNoWriteGrant;

  /// Toast or notice when approving, requesting changes or another review action was refused because the person holds no Control Center review grant on the repository
  ///
  /// In en, this message translates to:
  /// **'You can read this repository but not review it. A workspace admin can grant review access.'**
  String get repoCodeNoReviewGrant;

  /// Badge above a rig (Browser, Desktop, Android or iOS machine) the person may watch but not drive, because they hold only a read grant on the space's repositories
  ///
  /// In en, this message translates to:
  /// **'Watch only'**
  String get rigWatchOnlyBadge;

  /// One quiet line beside the watch-only badge above a rig, saying what is off and why
  ///
  /// In en, this message translates to:
  /// **'You can watch this machine. Driving it, forwarding its ports, pasting into it or dropping files on it needs write access to every repository in this space.'**
  String get rigWatchOnlyHint;

  /// Under the disabled Start button of a rig tab when the server refused opening a rig because the person holds only a read grant on the space's repositories
  ///
  /// In en, this message translates to:
  /// **'Starting a machine here needs write access to every repository in this space. A workspace admin can grant it.'**
  String get rigStartNeedsWrite;

  /// In place of a rig when its live view was refused because the person cannot read the rig's space
  ///
  /// In en, this message translates to:
  /// **'You can\'t view this machine. It belongs to a space you don\'t have read access to.'**
  String get rigViewRefused;

  /// Line in a rig's forwarded-ports popover, in place of the add-a-port field, when the person may watch the rig but not change its ports
  ///
  /// In en, this message translates to:
  /// **'Changing these ports needs write access to every repository in this space.'**
  String get rigPortsWatchOnly;

  /// Toast after a refused action on a rig (Browser, Desktop, Android or iOS machine, or a Terminal (VM)) that carries another person's own sign-ins, and the line in its forwarded-ports popover in place of the add-a-port field
  ///
  /// In en, this message translates to:
  /// **'Only the person this machine was opened for can drive it. It uses their own sign-ins.'**
  String get rigHolderOnly;

  /// One quiet line beside the watch-only badge above a rig that carries another person's own sign-ins, saying what is off and why
  ///
  /// In en, this message translates to:
  /// **'You can watch this machine. It uses the sign-ins of the person it was opened for, so only they can drive it, forward its ports, paste into it or drop files on it.'**
  String get rigHolderOnlyHint;
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
