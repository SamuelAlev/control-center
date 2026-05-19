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

  /// No description provided for @keybindingPushToTalkDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold or toggle voice dictation in the message composer'**
  String get keybindingPushToTalkDescription;

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
  /// **'Publish a review or merge'**
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
  /// **'This server cannot host enclosed VMs. Rigs need a hypervisor on the machine running cc_server.'**
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

  /// No description provided for @rigSurfaceMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get rigSurfaceMobile;

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

  /// No description provided for @rigStopMachine.
  ///
  /// In en, this message translates to:
  /// **'Stop the machine'**
  String get rigStopMachine;

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

  /// Heading over the enclosed-machine rows of the editor's [+] menu. It is what lets those rows drop their '(VM)' suffix.
  ///
  /// In en, this message translates to:
  /// **'Virtual machine'**
  String get ideMenuSectionVirtualMachine;

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

  /// Desktop rig, named inside the [+] menu's VIRTUAL MACHINE group — no '(VM)' suffix because the heading already says it. The TAB keeps rigTabComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get rigMenuComputer;

  /// Browser rig with no named engine, inside the [+] menu's VIRTUAL MACHINE group. The TAB keeps rigTabBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get rigMenuBrowser;

  /// Android rig, inside the [+] menu's VIRTUAL MACHINE group. The TAB keeps rigTabMobile.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get rigMenuMobile;

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
  /// **'Open the verification page on any device, sign in and enter this code:'**
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

  /// No description provided for @keybindingOpenThePullRequestFilterMenuDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the pull request filter menu'**
  String get keybindingOpenThePullRequestFilterMenuDescription;

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

  /// Relative time since an agent was last active
  ///
  /// In en, this message translates to:
  /// **'Active {duration} ago'**
  String lastActiveAgo(String duration);

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

  /// No description provided for @activityUpdatedGitHubToken.
  ///
  /// In en, this message translates to:
  /// **'Updated the GitHub token'**
  String get activityUpdatedGitHubToken;

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

  /// No description provided for @activityStartedCalendarConnect.
  ///
  /// In en, this message translates to:
  /// **'Started the calendar connection'**
  String get activityStartedCalendarConnect;

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

  /// No description provided for @activityUpdatedMcpToken.
  ///
  /// In en, this message translates to:
  /// **'Updated the MCP token'**
  String get activityUpdatedMcpToken;

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

  /// No description provided for @categoryCreation.
  ///
  /// In en, this message translates to:
  /// **'Creation'**
  String get categoryCreation;

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

  /// Locale string for closeKeyboardHint
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeKeyboardHint;

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

  /// No description provided for @configureDefaultRunners.
  ///
  /// In en, this message translates to:
  /// **'Configure which adapter and model are used for new spaces and title generation.'**
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

  /// Default capabilities · new spaces
  ///
  /// In en, this message translates to:
  /// **'Default capabilities · new spaces'**
  String get defaultCapabilities;

  /// Default chat
  ///
  /// In en, this message translates to:
  /// **'Default chat'**
  String get defaultChat;

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

  /// No description provided for @archiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Archive conversation'**
  String get archiveConversation;

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

  /// Title of the dialog for editing a chat message
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

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

  /// Locale string for installRequired
  ///
  /// In en, this message translates to:
  /// **'Installation required'**
  String get installRequired;

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

  /// Locale string for keybindingCreateANewAgentDescription
  ///
  /// In en, this message translates to:
  /// **'Create a new agent'**
  String get keybindingCreateANewAgentDescription;

  /// Locale string for keybindingCreateANewWorkspaceDescription
  ///
  /// In en, this message translates to:
  /// **'Create a new workspace'**
  String get keybindingCreateANewWorkspaceDescription;

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

  /// Locale string for keybindingRefreshAllFeedsDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh all feeds'**
  String get keybindingRefreshAllFeedsDescription;

  /// Locale string for keybindingRefreshThePullRequestListDescription
  ///
  /// In en, this message translates to:
  /// **'Refresh the pull request list'**
  String get keybindingRefreshThePullRequestListDescription;

  /// Locale string for keybindingRescanForAdaptersDescription
  ///
  /// In en, this message translates to:
  /// **'Rescan for adapters'**
  String get keybindingRescanForAdaptersDescription;

  /// Locale string for keybindingSelectTheNextArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Select the next article'**
  String get keybindingSelectTheNextArticleDescription;

  /// Locale string for keybindingSelectTheNextSpaceDescription
  ///
  /// In en, this message translates to:
  /// **'Select the next space'**
  String get keybindingSelectTheNextSpaceDescription;

  /// Locale string for keybindingSelectThePreviousArticleDescription
  ///
  /// In en, this message translates to:
  /// **'Select the previous article'**
  String get keybindingSelectThePreviousArticleDescription;

  /// Locale string for keybindingSelectThePreviousSpaceDescription
  ///
  /// In en, this message translates to:
  /// **'Select the previous space'**
  String get keybindingSelectThePreviousSpaceDescription;

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

  /// Locale string for keybindingSwitchBetweenLightAndDarkModeDescription
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark mode'**
  String get keybindingSwitchBetweenLightAndDarkModeDescription;

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

  /// No description provided for @mcpAuthToken.
  ///
  /// In en, this message translates to:
  /// **'MCP authentication token'**
  String get mcpAuthToken;

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

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

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
  /// **'Notify on new agent messages in other spaces.'**
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

  /// No description provided for @notificationsUnmuteRepo.
  ///
  /// In en, this message translates to:
  /// **'Unmute this repository'**
  String get notificationsUnmuteRepo;

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

  /// No description provided for @openApplicationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open application settings'**
  String get openApplicationSettings;

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

  /// No description provided for @readPrsIssuesMetadata.
  ///
  /// In en, this message translates to:
  /// **'Lets the agent read PRs, issues and repo metadata.'**
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

  /// Body of the notice listing repos the server's forge credential cannot access
  ///
  /// In en, this message translates to:
  /// **'The server\'s GitHub credential can\'t see {repos}. If a repository belongs to an organization, install the GitHub App there or connect a token that has access.'**
  String repoAccessNoticeBody(String repos);

  /// Title of the notice shown when the server's forge credential cannot access linked repos
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {A repository can\'t be accessed} other {{count} repositories can\'t be accessed}}'**
  String repoAccessNoticeTitle(int count);

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

  /// Run completed
  ///
  /// In en, this message translates to:
  /// **'Run completed'**
  String get runCompleted;

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

  /// Note shown next to a keyboard shortcut that the browser reserves (e.g. ⌘T, ⌘W, ⌘1–9) so it only works in the desktop app
  ///
  /// In en, this message translates to:
  /// **'Unavailable in the browser'**
  String get shortcutUnavailableInBrowser;

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

  /// No description provided for @skillOriginRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get skillOriginRegistry;

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

  /// Header label for the suggestion composer
  ///
  /// In en, this message translates to:
  /// **'Suggest a change'**
  String get suggestAChange;

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

  /// Configured — clients must present this token.
  ///
  /// In en, this message translates to:
  /// **'Configured — clients must present this token.'**
  String get tokenConfigured;

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

  /// No description provided for @triggerKindWebhook.
  ///
  /// In en, this message translates to:
  /// **'Via a webhook'**
  String get triggerKindWebhook;

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
  /// **'Connect a code host so Control Center can read your pull requests, issues and reviews. Optionally connect a ticketing provider. Credentials are held by your server, never by this machine.'**
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

  /// No description provided for @connectGitHubHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to GitHub or add a token in Settings → You → Profile & identity → Code hosting'**
  String get connectGitHubHint;

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

  /// No description provided for @agentsRunningCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 agent running} other{{count} agents running}}'**
  String agentsRunningCount(int count);

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

  /// No description provided for @ideRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get ideRevert;

  /// No description provided for @ideRevertConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Revert changes'**
  String get ideRevertConfirmTitle;

  /// No description provided for @ideRevertConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Revert {count, plural, =1{1 file} other{{count} files}} to HEAD? This discards working-tree changes.'**
  String ideRevertConfirmMessage(int count);

  /// No description provided for @ideRevertConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get ideRevertConfirmAction;

  /// No description provided for @ideRevertConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ideRevertConfirmCancel;

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

  /// No description provided for @ideViewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get ideViewSource;

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

  /// Source control action shown in place of "Create pull request" once the conversation's worktree branch already has an open pull request
  ///
  /// In en, this message translates to:
  /// **'View pull request #{number}'**
  String ideSourceControlViewPr(int number);

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

  /// No description provided for @usageAndCost.
  ///
  /// In en, this message translates to:
  /// **'Usage & cost'**
  String get usageAndCost;

  /// No description provided for @usageAndCostDescription.
  ///
  /// In en, this message translates to:
  /// **'Spend across your agents over the last 7 days, from observed run costs.'**
  String get usageAndCostDescription;

  /// No description provided for @noUsageYet.
  ///
  /// In en, this message translates to:
  /// **'No usage recorded yet.'**
  String get noUsageYet;

  /// No description provided for @spentThisWeek.
  ///
  /// In en, this message translates to:
  /// **'spent this week'**
  String get spentThisWeek;

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

  /// No description provided for @subscriptionUsagePartiallyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Partially available'**
  String get subscriptionUsagePartiallyAvailable;

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

  /// No description provided for @syncEngineSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync engine'**
  String get syncEngineSectionTitle;

  /// No description provided for @syncEngineDescription.
  ///
  /// In en, this message translates to:
  /// **'Tickets, messaging and notes update live via small incremental changes instead of full snapshots. Turning a toggle off falls that store back to full-snapshot mode — reload the app for the change to take effect.'**
  String get syncEngineDescription;

  /// No description provided for @syncEngineTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get syncEngineTicketsTitle;

  /// No description provided for @syncEngineMessagingTitle.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get syncEngineMessagingTitle;

  /// No description provided for @syncEngineNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get syncEngineNotesTitle;

  /// No description provided for @syncEngineOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live delta sync is active'**
  String get syncEngineOnSubtitle;

  /// No description provided for @syncEngineOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Using full-snapshot sync'**
  String get syncEngineOffSubtitle;

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

  /// No description provided for @keybindingCreateANewSpaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new space'**
  String get keybindingCreateANewSpaceDescription;

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

  /// No description provided for @customProvidersDescription.
  ///
  /// In en, this message translates to:
  /// **'Any OpenAI- or Anthropic-compatible endpoint — Ollama, LM Studio, vLLM, or a private deployment — with an optional API key.'**
  String get customProvidersDescription;

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

  /// No description provided for @provisioningRunningSetupScript.
  ///
  /// In en, this message translates to:
  /// **'Running the setup script for {repo}…'**
  String provisioningRunningSetupScript(String repo);

  /// No description provided for @repoScriptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get repoScriptsTitle;

  /// No description provided for @repoScriptsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Configure lifecycle scripts'**
  String get repoScriptsTooltip;

  /// No description provided for @repoScriptsSetupLabel.
  ///
  /// In en, this message translates to:
  /// **'Setup script'**
  String get repoScriptsSetupLabel;

  /// No description provided for @repoScriptsSetupHelp.
  ///
  /// In en, this message translates to:
  /// **'Runs in the space\'s worktree right after it is created — install dependencies, generate files. A failure marks the space as failed; retry runs it again.'**
  String get repoScriptsSetupHelp;

  /// No description provided for @repoScriptsArchiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive script'**
  String get repoScriptsArchiveLabel;

  /// No description provided for @repoScriptsArchiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Runs just before a space\'s worktree is deleted — clean up resources outside the worktree. A failure never blocks deletion.'**
  String get repoScriptsArchiveHelp;

  /// No description provided for @repoScriptsEnvHelp.
  ///
  /// In en, this message translates to:
  /// **'Runs via bash from the worktree, with CC_WORKSPACE_PATH (the worktree), CC_ROOT_PATH (the repo root), CC_SPACE_ID, CC_SPACE_NAME and CC_REPO_NAME set.'**
  String get repoScriptsEnvHelp;

  /// No description provided for @repoScriptsSetupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. pnpm install'**
  String get repoScriptsSetupPlaceholder;

  /// No description provided for @repoScriptsArchivePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. docker compose -p \$CC_SPACE_ID down'**
  String get repoScriptsArchivePlaceholder;

  /// No description provided for @repoScriptsRecentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get repoScriptsRecentRuns;

  /// No description provided for @repoScriptsNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get repoScriptsNoRuns;

  /// No description provided for @repoScriptsOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get repoScriptsOutput;

  /// No description provided for @repoScriptsSaved.
  ///
  /// In en, this message translates to:
  /// **'Scripts saved'**
  String get repoScriptsSaved;

  /// No description provided for @repoScriptsRunKindSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get repoScriptsRunKindSetup;

  /// No description provided for @repoScriptsRunKindArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get repoScriptsRunKindArchive;

  /// No description provided for @repoScriptsRunStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get repoScriptsRunStatusRunning;

  /// No description provided for @repoScriptsRunStatusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get repoScriptsRunStatusSucceeded;

  /// No description provided for @repoScriptsRunStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get repoScriptsRunStatusFailed;

  /// No description provided for @repoScriptsRunStatusTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get repoScriptsRunStatusTimedOut;

  /// No description provided for @repoScriptsExitCode.
  ///
  /// In en, this message translates to:
  /// **'Exit code {code}'**
  String repoScriptsExitCode(int code);

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
  /// **'How you appear to teammates and in git commit authorship.'**
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

  /// No description provided for @presenceAgentThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get presenceAgentThinking;

  /// No description provided for @presenceAgentRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get presenceAgentRunning;

  /// No description provided for @presenceAgentBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get presenceAgentBlocked;

  /// No description provided for @presenceAgentDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get presenceAgentDone;

  /// Tooltip for a presence avatar chip: participant name and current status
  ///
  /// In en, this message translates to:
  /// **'{name} — {status}'**
  String presenceNameStatus(String name, String status);

  /// Tooltip for an agent presence avatar chip, including its running cost
  ///
  /// In en, this message translates to:
  /// **'{name} — {status} ({cost})'**
  String presenceNameStatusCost(String name, String status, String cost);

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

  /// No description provided for @keybindingShowKeyboardShortcutsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the keyboard shortcut cheat-sheet for the current screen'**
  String get keybindingShowKeyboardShortcutsDescription;

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

  /// No description provided for @keybindingUndoLastActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Undo your last reversible action'**
  String get keybindingUndoLastActionDescription;

  /// No description provided for @keybindingRedoLastActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Redo the last undone action'**
  String get keybindingRedoLastActionDescription;

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

  /// Note explaining that the soundscape weather location is auto-detected
  ///
  /// In en, this message translates to:
  /// **'Location is detected automatically from this workspace.'**
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

  /// No description provided for @spaceFlyoutNeedsInput.
  ///
  /// In en, this message translates to:
  /// **'Needs input'**
  String get spaceFlyoutNeedsInput;

  /// No description provided for @spaceFlyoutPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get spaceFlyoutPreparing;

  /// No description provided for @spaceFlyoutSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get spaceFlyoutSetupFailed;

  /// No description provided for @spaceFlyoutSetupStopped.
  ///
  /// In en, this message translates to:
  /// **'Setup stopped'**
  String get spaceFlyoutSetupStopped;

  /// No description provided for @spaceFlyoutNeverRun.
  ///
  /// In en, this message translates to:
  /// **'No agent has run here yet'**
  String get spaceFlyoutNeverRun;

  /// Accessible description of an agent's context-window meter in the space hover flyout.
  ///
  /// In en, this message translates to:
  /// **'Context window {used} used, {percent} full'**
  String spaceFlyoutContextUsage(String used, String percent);

  /// Count of subagent runs in flight, shown beside the agent count in the space hover flyout.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subagent} other{{count} subagents}}'**
  String subagentsRunningCount(int count);

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
  /// **'Mention the bot in {provider} to put an agent on something, or file tickets with {command}.'**
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

  /// Instruction above the copyable link command
  ///
  /// In en, this message translates to:
  /// **'Send this command to the bot in {provider}. It works once and expires in 15 minutes.'**
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

  /// Option using Control Center's own Google OAuth app
  ///
  /// In en, this message translates to:
  /// **'Use Control Center\'s Google app'**
  String get calendarUseBuiltinApp;

  /// Explains the built-in Google app option
  ///
  /// In en, this message translates to:
  /// **'Approve with your Google account. Nothing to set up in Google Cloud.'**
  String get calendarUseBuiltinAppHint;

  /// Option using the user's own Google Cloud OAuth client
  ///
  /// In en, this message translates to:
  /// **'Use my own Google Cloud client'**
  String get calendarUseOwnClient;

  /// Explains the bring-your-own Google client option
  ///
  /// In en, this message translates to:
  /// **'Enter an OAuth client from your own Google Cloud project.'**
  String get calendarUseOwnClientHint;

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

  /// Locale string for settingsScopeBadgeYou
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get settingsScopeBadgeYou;

  /// Locale string for settingsScopeBadgeDevice
  ///
  /// In en, this message translates to:
  /// **'THIS DEVICE'**
  String get settingsScopeBadgeDevice;

  /// Locale string for settingsScopeBadgeWorkspace
  ///
  /// In en, this message translates to:
  /// **'WORKSPACE'**
  String get settingsScopeBadgeWorkspace;

  /// Locale string for settingsScopeBadgeServer
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get settingsScopeBadgeServer;

  /// Locale string for settingsProfileDescription
  ///
  /// In en, this message translates to:
  /// **'Your name, email and the git identity stamped on commits made for you.'**
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
  /// **'Identity, policy and conventions shared by everyone in this workspace.'**
  String get settingsWorkspaceGeneralDescription;

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

  /// Locale string for fromEnvironment
  ///
  /// In en, this message translates to:
  /// **'from the environment'**
  String get fromEnvironment;

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

  /// Title of the web client's connect gate
  ///
  /// In en, this message translates to:
  /// **'Connect to Control Center'**
  String get webConnectTitle;

  /// Subtitle explaining the web connect gate
  ///
  /// In en, this message translates to:
  /// **'Dial a running cc-server over WebSocket. Your key stays on this device.'**
  String get webConnectSubtitle;

  /// Label for the server URL field on the web connect gate
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get webConnectServerLabel;

  /// Label for the device id field on the web connect gate
  ///
  /// In en, this message translates to:
  /// **'Device id'**
  String get webConnectDeviceIdLabel;

  /// Label for the pairing key field on the web connect gate
  ///
  /// In en, this message translates to:
  /// **'Pairing key'**
  String get webConnectPairingKeyLabel;

  /// Hint for the pairing key field on the web connect gate
  ///
  /// In en, this message translates to:
  /// **'paste the PSK'**
  String get webConnectPairingKeyHint;

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

  /// No description provided for @conversationTitlesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation titles'**
  String get conversationTitlesSectionTitle;

  /// No description provided for @conversationTitlesSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Pick the runner that names new conversations in this workspace automatically. Titles stay off until an adapter is chosen, and apply to every member.'**
  String get conversationTitlesSectionCaption;

  /// No description provided for @conversationTitlesModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Title model'**
  String get conversationTitlesModelLabel;

  /// No description provided for @conversationTitlesAdapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get conversationTitlesAdapterLabel;

  /// No description provided for @conversationTitlesAdapterHint.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get conversationTitlesAdapterHint;

  /// No description provided for @conversationTitlesAdapterOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get conversationTitlesAdapterOff;

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

  /// Toast when the app stopped waiting for a provider sign-in
  ///
  /// In en, this message translates to:
  /// **'The sign-in has not come back yet. Finish it in your browser, then check again.'**
  String get signInNotFinished;

  /// Title of the re-authentication screen shown when a completed setup lost its forge credential
  ///
  /// In en, this message translates to:
  /// **'You\'re signed out'**
  String get signedOutTitle;

  /// Explains that only the forge credential lapsed and nothing else was lost
  ///
  /// In en, this message translates to:
  /// **'Your code-hosting connection is no longer valid — a token expired, or its access was revoked. Nothing else changed: sign back in and everything is where you left it.'**
  String get signedOutSubtitle;

  /// Credential source label: the server's own app identity
  ///
  /// In en, this message translates to:
  /// **'via this server\'s app'**
  String get viaServerApp;

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

  /// Action that opens the paste-a-key dialog for a ticketing vendor
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get addKey;

  /// Server settings card: how this server authenticates as itself
  ///
  /// In en, this message translates to:
  /// **'Provider apps'**
  String get providerApps;

  /// Subtitle of the provider apps card
  ///
  /// In en, this message translates to:
  /// **'How this server authenticates as itself, and what a person signs in through. Background work — webhooks, polling, sync — runs on the app, never on a person\'s token.'**
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

  /// Server-level API key for a provider
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerApiKey;

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

  /// Device-code dialog body
  ///
  /// In en, this message translates to:
  /// **'Enter this code on the {provider} page that just opened. It has been copied to your clipboard.'**
  String deviceCodeInstructions(String provider);

  /// Device-code dialog status while polling
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to finish in the browser…'**
  String get deviceCodeWaiting;

  /// Device-code dialog action: copy the code and reopen the provider page
  ///
  /// In en, this message translates to:
  /// **'Copy code and open'**
  String get copyCodeAndOpen;

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

  /// No description provided for @providersFacetNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get providersFacetNeedsSetup;

  /// No description provided for @providersFacetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get providersFacetCustom;

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

  /// No description provided for @adaptersFacetReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get adaptersFacetReady;

  /// No description provided for @adaptersFacetMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get adaptersFacetMissing;

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

  /// No description provided for @defaultChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs new conversations and any agent with no runner of its own.'**
  String get defaultChatDescription;

  /// No description provided for @shortTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs quick background work such as titles and summaries. A smaller model belongs here.'**
  String get shortTaskDescription;

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
  /// **'Lets background work reach repositories with no human behind the request: webhooks, pull-request polling, ticket sync.'**
  String get providerAppsGroupServerDescription;

  /// Settings group: how developers talk to the server on GitHub PRs
  ///
  /// In en, this message translates to:
  /// **'Pull request conversations'**
  String get providerAppsGroupPrConversations;

  /// Settings group description for the PR-conversations group
  ///
  /// In en, this message translates to:
  /// **'How developers can talk to this server directly on GitHub. Works with no webhook or public URL — the server polls.'**
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

  /// No description provided for @mcpNoTokenWarning.
  ///
  /// In en, this message translates to:
  /// **'Without a token, anything that can reach this port can call every tool.'**
  String get mcpNoTokenWarning;

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

  /// No description provided for @sandboxBackendFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Auto picks the strongest one this host supports. Pin one to stop it changing under you.'**
  String get sandboxBackendFieldDescription;

  /// No description provided for @sandboxCapabilitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'The holes punched through the boundary. Each one is something an isolated agent can still do to the outside world.'**
  String get sandboxCapabilitiesDescription;

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

  /// Primary action in the agents card header: create an agent
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get newAgent;

  /// Primary action in the skills card header: create a skill
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get newSkill;

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

  /// Toast when /handoff, /btw or /omfg has no configured runner.
  ///
  /// In en, this message translates to:
  /// **'Set a one-shot model in workspace settings to use this'**
  String get asideUnavailable;

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

  /// No description provided for @repoScriptsTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get repoScriptsTest;

  /// No description provided for @repoScriptsTestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Run this draft in a throwaway clone of the repo'**
  String get repoScriptsTestTooltip;

  /// No description provided for @repoScriptsRunKindTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get repoScriptsRunKindTest;

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

  /// Button that closes the demo tour on the last step
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get demoTourDone;

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

  /// Warning shown as a demo visitor's TTL approaches
  ///
  /// In en, this message translates to:
  /// **'This demo session ends in {minutes} minutes.'**
  String demoSessionEndingSoon(int minutes);

  /// Shown when a demo visitor's session has been reaped
  ///
  /// In en, this message translates to:
  /// **'This demo session has ended. Reload the page to start a new one.'**
  String get demoSessionEnded;

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
  /// **'No snapshots yet. One is taken only when you ask for it — nothing is scheduled.'**
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

  /// Button that opens the native file picker for an import
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get backupImportChooseFile;

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

  /// Why download and upload are unavailable on a relayed connection
  ///
  /// In en, this message translates to:
  /// **'This connection reaches the server through a relay, which carries no file transfers. Connect to the server directly to download or upload a backup.'**
  String get backupTransferUnavailable;

  /// Which role each backup transfer requires, after a refusal
  ///
  /// In en, this message translates to:
  /// **'The server refused. Downloading a workspace needs the admin role, restoring one needs owner, and a whole snapshot needs the install\'s operator.'**
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
