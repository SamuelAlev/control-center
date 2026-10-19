// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Terug';

  @override
  String get cancel => 'Annuleren';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get settings => 'Instellingen';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get approve => 'Goedkeuren';

  @override
  String get deny => 'Weigeren';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get agentQuestionHeader => 'Vraag voor jou';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwoord';

  @override
  String get agentQuestionSkip => 'Overslaan';

  @override
  String get agentQuestionSkippedLabel => 'Overgeslagen';

  @override
  String get agentQuestionFreeformHint => 'Typ je antwoord…';

  @override
  String get agentApprovalRequired => 'Goedkeuring vereist';

  @override
  String get copyCommand => 'Opdracht kopiëren';

  @override
  String get approveAndRemember => '8 uur goedkeuren';

  @override
  String get decline => 'Weigeren';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Verzenden';

  @override
  String get close => 'Sluiten';

  @override
  String get expand => 'Uitvouwen';

  @override
  String get zoomIn => 'Inzoomen';

  @override
  String get zoomOut => 'Uitzoomen';

  @override
  String get resetZoom => 'Zoom herstellen';

  @override
  String get scanQrPrompt =>
      'Scan de QR-code in Control Center om deze telefoon te koppelen.';

  @override
  String get scanQrHelp =>
      'Open je camera en richt die op de QR in Control Center. Deze telefoon maakt rechtstreeks via een privéverbinding contact.';

  @override
  String get connectingToMac => 'Verbinden met Control Center…';

  @override
  String get connectingDetail =>
      'Beveiligde, directe verbinding wordt opgezet.';

  @override
  String get identityChangedTitle => 'Serveridentiteit gewijzigd';

  @override
  String get identityChangedBody =>
      'Deze server komt niet meer overeen met de identiteit die bij het koppelen is opgeslagen. Dat kan betekenen dat de server opnieuw is geïnstalleerd — of dat iets de verbinding onderschept. Voor je veiligheid maakt dit apparaat geen verbinding. Verwijder de koppeling en scan daarna een nieuwe QR-code in Control Center om opnieuw te koppelen.';

  @override
  String get removePairing => 'Koppeling verwijderen';

  @override
  String get couldntConnect => 'Verbinden mislukt';

  @override
  String get pendingPairingTitle => 'Verbinden met deze server?';

  @override
  String get pendingPairingBody =>
      'Een link vroeg Control Center om met deze server te koppelen. Ga alleen verder als je dit zelf hebt gestart.';

  @override
  String get connect => 'Verbinden';

  @override
  String get failureNotPaired =>
      'Niet gekoppeld — scan de QR-code in Control Center';

  @override
  String get failureUnreachable =>
      'Server via geen enkel pad bereikbaar — controleer of die actief is, of probeer hetzelfde netwerk';

  @override
  String get failureIdentityChanged =>
      'De identiteit van de server is gewijzigd — als die opnieuw is geïnstalleerd, koppel dit apparaat opnieuw';

  @override
  String get failureAuthRejected =>
      'De server wees dit apparaat af — koppel het opnieuw vanaf Control Center';

  @override
  String get failureUnknown => 'Verbinden mislukt — tik om opnieuw te proberen';

  @override
  String get statusConnected => 'Verbonden';

  @override
  String get statusConnecting => 'Verbinden';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identiteit komt niet overeen';

  @override
  String get statusNotPaired => 'Niet gekoppeld';

  @override
  String get statusConfirmPairing => 'Koppeling bevestigen';

  @override
  String get connectionFailed => 'Verbinding mislukt';

  @override
  String get identityMismatchBanner =>
      'Serveridentiteit gewijzigd — verbinding gestopt. Koppel dit apparaat opnieuw om verder te gaan.';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PR\'s';

  @override
  String get tabCalendar => 'Agenda';

  @override
  String get tabNews => 'Nieuws';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count in behandeling';
  }

  @override
  String get updateAvailable => 'Er is een nieuwe Control Center beschikbaar';

  @override
  String get appearance => 'Weergave';

  @override
  String get language => 'Taal';

  @override
  String get device => 'Apparaat';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get languageSystem => 'Systeem';

  @override
  String get disconnectTapAgain =>
      'Tik nogmaals om dit apparaat van Control Center te ontkoppelen';

  @override
  String get disconnectDevice => 'Dit apparaat ontkoppelen';

  @override
  String get disconnect => 'Loskoppelen';

  @override
  String get chooseWorkspace => 'Werkruimte kiezen';

  @override
  String get workspaces => 'Werkruimtes';

  @override
  String get workspacesLoadFailed => 'Werkruimtes laden mislukt';

  @override
  String get noWorkspacesYet => 'Nog geen werkruimtes';

  @override
  String selectWorkspace(String name) {
    return '$name selecteren';
  }

  @override
  String get inboxLoadFailed => 'Inbox laden mislukt';

  @override
  String get allCaughtUp => 'Je bent helemaal bij';

  @override
  String get inboxNoForgeAccount =>
      'Er is geen forge-account op de server gekoppeld, dus pull requests kunnen nog niet aan jou worden toegeschreven.';

  @override
  String get inboxNothingWaiting =>
      'Niets is geblokkeerd en er wacht geen pull request op jou.';

  @override
  String get blocked => 'Geblokkeerd';

  @override
  String get sectionNeedsYourReview => 'Wacht op jouw review';

  @override
  String get sectionReturnedToYou => 'Terug naar jou';

  @override
  String get sectionApprovedAndReady => 'Goedgekeurd en klaar';

  @override
  String get sectionYourDrafts => 'Jouw concepten';

  @override
  String get sectionWaitingForReviewers => 'Wacht op reviewers';

  @override
  String get sectionMergingAndMerged => 'Aan het mergen en recent gemerged';

  @override
  String get sectionWaitingForAuthor => 'Wacht op auteur';

  @override
  String waitingAgo(String ago) {
    return 'wacht $ago';
  }

  @override
  String get openConversation => 'Gesprek openen';

  @override
  String get calendarLoadFailed => 'Agenda laden mislukt';

  @override
  String get nothingScheduled => 'Niets gepland';

  @override
  String get calendarEmptyDescription =>
      'Afspraken uit je gekoppelde agenda\'s verschijnen hier.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Agenda\'s nu synchroniseren';

  @override
  String get event => 'Afspraak';

  @override
  String get eventNotFound => 'Afspraak niet gevonden';

  @override
  String get eventNotFoundDescription =>
      'Die valt mogelijk buiten het agendavenster, of is elders verwijderd.';

  @override
  String get joinMeeting => 'Deelnemen aan vergadering';

  @override
  String get join => 'Deelnemen';

  @override
  String attendeesCount(int count) {
    return 'Deelnemers ($count)';
  }

  @override
  String get details => 'Details';

  @override
  String get allDay => 'Hele dag';

  @override
  String get happeningNow => 'Nu bezig';

  @override
  String inDuration(String duration) {
    return 'Over $duration';
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
  String get attendeeAccepted => 'geaccepteerd';

  @override
  String get attendeeDeclined => 'afgewezen';

  @override
  String get attendeeMaybe => 'misschien';

  @override
  String get attendeeNoReply => 'geen reactie';

  @override
  String get organizer => 'organisator';

  @override
  String get calendarNoAccounts =>
      'Er is geen agenda gekoppeld voor deze werkruimte. Koppel er een via de desktop-app — de aanmelding slaat het token op de server op.';

  @override
  String get calendarReauthNeeded =>
      'Een agenda-account moet opnieuw worden gekoppeld — wat je hieronder ziet, kan verouderd zijn. Koppel het opnieuw via de desktop-app.';

  @override
  String get spacesLoadFailed => 'Spaces laden mislukt';

  @override
  String get noSpaces => 'Geen spaces';

  @override
  String get spacesEmptyDescription =>
      'Spaces in deze werkruimte verschijnen hier.';

  @override
  String get newSpaceFolder => 'Nieuwe map';

  @override
  String get folderName => 'Mapnaam';

  @override
  String get renameSpaceFolder => 'Map hernoemen';

  @override
  String get deleteSpaceFolder => 'Map verwijderen';

  @override
  String get moveSpaceToFolder => 'Naar map verplaatsen';

  @override
  String get removeSpaceFromFolder => 'Uit map verwijderen';

  @override
  String get spaceFolderActions => 'Mapacties';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Als je ruimtes definitief verwijdert, verdwijnen hun berichten en werkmappen voor iedereen. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get deleteSpacesInFolder =>
      'Ruimtes in deze map definitief verwijderen';

  @override
  String get deleteFolderAndSpaces => 'Map en ruimtes verwijderen';

  @override
  String get keepSpacesInFolder => 'Anders blijven de ruimtes buiten een map.';

  @override
  String get create => 'Aanmaken';

  @override
  String get otherSpaces => 'Andere ruimtes';

  @override
  String get folderUpdateFailed => 'Kan mappen niet bijwerken';

  @override
  String get thread => 'Thread';

  @override
  String get agentWorking => 'Agent is bezig';

  @override
  String get messagesLoadFailed => 'Berichten laden mislukt';

  @override
  String get noMessagesYet => 'Nog geen berichten';

  @override
  String get noMessagesDescription =>
      'Stuur een bericht om het gesprek te starten.';

  @override
  String get agentResponding => 'Agent reageert';

  @override
  String get agentFinished => 'Agent klaar';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names zijn te groot om hier te versturen.',
      one: '$names is te groot om hier te versturen.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names zijn te groot om hier via de relay te versturen.',
      one: '$names is te groot om hier via de relay te versturen.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Bijlage uploaden mislukt. Probeer het opnieuw.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bijlagen konden niet worden geüpload en zijn weggelaten.',
      one: '1 bijlage kon niet worden geüpload en is weggelaten.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Teamlid';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Bestand bijvoegen';

  @override
  String get messageHint => 'Bericht';

  @override
  String removeAttachment(String name) {
    return '$name verwijderen';
  }

  @override
  String get articlesLoadFailed => 'Artikelen laden mislukt';

  @override
  String get noArticles => 'Geen artikelen';

  @override
  String get articlesEmptyDescription =>
      'Nieuwe artikelen verschijnen hier wanneer feeds worden bijgewerkt.';

  @override
  String get unread => 'Ongelezen';

  @override
  String get allFeeds => 'Alle feeds';

  @override
  String get save => 'Opslaan';

  @override
  String get unsave => 'Opslaan ongedaan maken';

  @override
  String get readFullArticle => 'Volledig artikel lezen';

  @override
  String get ticketsLoadFailed => 'Tickets laden mislukt';

  @override
  String get noTickets => 'Geen tickets';

  @override
  String get ticketsEmptyDescription =>
      'Tickets in deze workspace verschijnen hier.';

  @override
  String get all => 'Alles';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Ticket laden mislukt';

  @override
  String assignedTo(String name) {
    return 'Toegewezen aan $name';
  }

  @override
  String get openInBrowser => 'Openen in browser';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Toewijzen';

  @override
  String get reassign => 'Opnieuw toewijzen';

  @override
  String get noAgents => 'Geen agenten';

  @override
  String get noAgentsDescription => 'Wijs een agent uit deze workspace toe.';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In uitvoering';

  @override
  String get statusBlocked => 'Geblokkeerd';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusDone => 'Gereed';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Voor mij';

  @override
  String get lensMine => 'Van mij';

  @override
  String get prsLoadFailed => 'Pull requests laden mislukt';

  @override
  String get noOpenPullRequests => 'Geen open pull requests';

  @override
  String get nothingWaitingOnReview => 'Niets wacht op jouw review';

  @override
  String get noOwnOpenPullRequests => 'Je hebt geen open pull requests';

  @override
  String get nothingBlocked => 'Niets geblokkeerd';

  @override
  String get prsEmptyDescription =>
      'Pull requests uit de repo’s van deze workspace verschijnen hier.';

  @override
  String get refreshPullRequests => 'Pull requests vernieuwen';

  @override
  String get noForgeConnected =>
      'Er is geen forge gekoppeld op de server, dus er kunnen geen pull requests worden opgehaald. Koppel er een via de desktop-app.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo’s konden niet worden gelezen.',
      one: '1 repo kon niet worden gelezen.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Niet leesbaar: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'GitHub App-installatie is opgeschort';

  @override
  String installationSuspendedBody(String names) {
    return 'Laatst bekende gegevens voor $names worden getoond. Hervat de installatie op GitHub, of koppel een token met toegang.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App-installatie is opgeschort. Laatst bekende gegevens voor $names worden getoond. Hervat de installatie op GitHub, of koppel een token met toegang.';
  }

  @override
  String get draft => 'Concept';

  @override
  String get merged => 'Samengevoegd';

  @override
  String get closed => 'Gesloten';

  @override
  String get open => 'Open';

  @override
  String get approved => 'Goedgekeurd';

  @override
  String get changesRequested => 'Wijzigingen aangevraagd';

  @override
  String get reviewRequired => 'Review vereist';

  @override
  String get checksPassing => 'Controles geslaagd';

  @override
  String get checksFailing => 'Controles mislukt';

  @override
  String get checksRunning => 'Controles bezig';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Deze pull request laden mislukt';

  @override
  String get openOnForge => 'Openen op de forge';

  @override
  String get requestChangesNeedsComment =>
      'Voeg een toelichting toe over wat er moet veranderen.';

  @override
  String get conversation => 'Gesprek';

  @override
  String get files => 'Bestanden';

  @override
  String get checks => 'Controles';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
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
  String get conflicts => 'Conflicten';

  @override
  String get reviewers => 'REVIEWERS';

  @override
  String get noDescriptionNoComments =>
      'Nog geen beschrijving en geen reacties.';

  @override
  String get noChangedFiles => 'Geen gewijzigde bestanden.';

  @override
  String get noChecksReported =>
      'Geen checks gerapporteerd voor de head-commit.';

  @override
  String get reviewCommentHint => 'Laat een reviewreactie achter…';

  @override
  String get comment => 'Reactie';

  @override
  String get commentPosted => 'Reactie geplaatst';

  @override
  String get request => 'Aanvragen';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — geen acties beschikbaar.';
  }

  @override
  String get reviewApproved => 'goedgekeurd';

  @override
  String get reviewRequestedChanges => 'wijzigingen gevraagd';

  @override
  String get reviewCommented => 'beoordeeld';

  @override
  String get reviewPending => 'in behandeling';

  @override
  String get unknownAuthor => 'onbekend';

  @override
  String hideDiffFor(String file) {
    return 'Diff van $file verbergen';
  }

  @override
  String showDiffFor(String file) {
    return 'Diff van $file tonen';
  }

  @override
  String get checkRunning => 'bezig';

  @override
  String get checkPassed => 'geslaagd';

  @override
  String get checkFailed => 'mislukt';

  @override
  String get checkCancelled => 'geannuleerd';

  @override
  String get checkSkipped => 'overgeslagen';

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
      'Geen tekst-diff voor dit bestand — het is binair, of te groot om door de forge te worden teruggegeven.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toon de resterende $count regels',
      one: 'Toon de resterende regel',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ongewijzigde regels',
      one: '1 ongewijzigde regel',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Naar nieuwste';

  @override
  String get streaming => 'Actief';

  @override
  String get working => 'Bezig';

  @override
  String get input => 'Invoer';

  @override
  String get output => 'Uitvoer';

  @override
  String get now => 'nu';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}u';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Vandaag';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get yesterday => 'gisteren';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}u';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}u ${minutes}m';
  }

  @override
  String get mobileConversations => 'Gesprekken';

  @override
  String get mobileNewConversation => 'Nieuw gesprek';

  @override
  String get mobileConversationName => 'Naam van het gesprek';

  @override
  String get mobileRename => 'Naam wijzigen';

  @override
  String get mobileManageSpace => 'Ruimte beheren';

  @override
  String get mobileArchived => 'Gearchiveerd';

  @override
  String get mobileSearchMessages => 'Alle berichten in deze ruimte zoeken';

  @override
  String get mobileSearch => 'Zoeken';

  @override
  String get mobileNoResults => 'Geen resultaten';

  @override
  String get mobileReopen => 'Opnieuw openen';

  @override
  String get mobileArchive => 'Archiveren';

  @override
  String get mobileProgress => 'Voortgang en context';

  @override
  String get mobileReadFailed => 'Kan dit gesprek niet als gelezen markeren';

  @override
  String get mobileSendFailed =>
      'Bericht niet verzonden. Je concept is bewaard.';

  @override
  String get sentAttachmentUnavailable => 'Bijlage niet beschikbaar';

  @override
  String get sentAttachmentLoadFailed => 'Kon bijlage niet laden';

  @override
  String get mobileActionFailed => 'Actie mislukt';

  @override
  String get mobileRemove => 'Verwijderen';

  @override
  String get mobileLinkedMessage => 'Gekoppeld bericht';

  @override
  String get mobileOlderMessages => 'Oudere berichten';

  @override
  String get mobileMessageActions => 'Berichtacties';

  @override
  String get mobileOpenThread => 'Thread openen';

  @override
  String get mobileCopyLink => 'Link kopiëren';

  @override
  String get mobileStopRun => 'Run stoppen';

  @override
  String get mobileStopRunConfirm =>
      'Deze agentrun stoppen? Voltooid werk blijft bewaard.';

  @override
  String get mobileControlUnsupported =>
      'Deze run is voltooid of ondersteunt deze actie niet.';

  @override
  String get mobilePauseRequested => 'Pauze aangevraagd na de huidige beurt';

  @override
  String get mobileResumed => 'Run hervat';

  @override
  String get mobileStopRequested => 'Stop aangevraagd';

  @override
  String get mobileQueuedMessages => 'Wachtende berichten';

  @override
  String get mobilePauseRun => 'Pauzeren na de huidige beurt';

  @override
  String get mobileResumeRun => 'Hervatten';

  @override
  String get mobileEditQueued => 'Wachtend bericht bewerken';

  @override
  String get mobileSteerNow => 'Nu bijsturen';

  @override
  String get mobileMoveUp => 'Omhoog';

  @override
  String get mobileMoveDown => 'Omlaag';

  @override
  String get mobileQueueChanged =>
      'De wachtrij is gewijzigd of deze run kan niet direct worden bijgestuurd. Vernieuw en probeer opnieuw.';

  @override
  String get mobileActivity => 'Activiteit';

  @override
  String get mobilePermissions => 'Machtigingen en audit';

  @override
  String get mobilePlans => 'Plannen';

  @override
  String get mobileGoals => 'Doelen onder toezicht';

  @override
  String get mobileCredentials => 'Verbindingen en inloggegevens';

  @override
  String get mobileWorkspaceUnavailable =>
      'Deze werkruimte is niet beschikbaar of je hebt geen toegang meer.';

  @override
  String get mobilePrReviewThreads => 'Reviewdraden';

  @override
  String get mobilePrThreadsLoadFailed => 'Kan reviewdraden niet laden';

  @override
  String get mobilePrNoReviewThreads => 'Nog geen reviewdraden bij coderegels';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Je mag geen opmerkingen plaatsen bij deze repository.';

  @override
  String get mobilePrPermissionChecking =>
      'Machtiging voor opmerkingen controleren…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Kan de machtiging voor opmerkingen niet controleren. Probeer het opnieuw.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, regel $line';
  }

  @override
  String get mobilePrOriginalSide => 'Oorspronkelijk';

  @override
  String get mobilePrSelectCommentLine => 'Kies een regel om op te reageren';

  @override
  String get mobilePrUpdatedSide => 'Bijgewerkt';

  @override
  String get mobilePrThreadResolved => 'Opgelost';

  @override
  String get mobilePrReplyHint => 'Schrijf een reactie…';

  @override
  String get mobilePrCommentRequired =>
      'Schrijf een opmerking voordat je deze plaatst.';

  @override
  String get mobilePrReply => 'Reageren';

  @override
  String get mobilePrReopenThread => 'Thread heropenen';

  @override
  String get mobilePrResolveThread => 'Thread oplossen';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Alleen de auteur van de pull request of iemand met schrijftoegang kan deze thread oplossen.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Opmerking bij $side, regel $line';
  }

  @override
  String get mobilePrInlineCommentHint =>
      'Schrijf een opmerking bij deze regel…';

  @override
  String get mobilePrPostInlineComment => 'Opmerking plaatsen';

  @override
  String get mobilePrCommentUnavailable =>
      'Opmerkingen bij coderegels zijn niet beschikbaar voor deze pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Het codeplatform heeft geen tekstpatch voor dit bestand geleverd.';

  @override
  String get mobilePrNoPatchForFile =>
      'De patch voor dit bestand is niet beschikbaar.';

  @override
  String get mobileTicketNew => 'Nieuw ticket';

  @override
  String get mobileTicketCreate => 'Ticket aanmaken';

  @override
  String get mobileTicketEdit => 'Ticket bewerken';

  @override
  String get mobileTicketTitle => 'Titel';

  @override
  String get mobileTicketTitleRequired =>
      'Voer een titel in om dit ticket op te slaan.';

  @override
  String get mobileTicketDescription => 'Beschrijving';

  @override
  String get mobileTicketMarkdownHint => 'Voeg details toe in Markdown';

  @override
  String get mobileTicketPriority => 'Prioriteit';

  @override
  String get mobileTicketPriorityNone => 'Geen prioriteit';

  @override
  String get mobileTicketPriorityUrgent => 'Urgent';

  @override
  String get mobileTicketPriorityHigh => 'Hoog';

  @override
  String get mobileTicketPriorityMedium => 'Middel';

  @override
  String get mobileTicketPriorityLow => 'Laag';

  @override
  String get mobileTicketLabels => 'Labels';

  @override
  String get mobileTicketLabelsHint => 'Eén label per regel';

  @override
  String get mobileTicketLabelsHelp => 'Voer elk label op een aparte regel in.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Aangemaakt in $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Niet toegewezen';

  @override
  String get mobileTicketAssignedFilter => 'Toegewezen';

  @override
  String get mobileTicketAgentsLoadFailed => 'Kan agenten niet laden';

  @override
  String get mobileTicketSearch => 'Tickets zoeken';

  @override
  String get mobileTicketSearchHint =>
      'Titel, sleutel, beschrijving, label of toegewezen persoon';

  @override
  String get mobileTicketClearSearch => 'Ticketzoekopdracht wissen';

  @override
  String get mobileTicketNoMatches => 'Geen overeenkomende tickets';

  @override
  String get mobileTicketAdjustFilters =>
      'Probeer een andere zoekopdracht of pas de filters aan.';

  @override
  String get mobileTicketClearFilters => 'Filters wissen';

  @override
  String get mobileTicketNotFound => 'Ticket niet gevonden';

  @override
  String get mobileTicketNotFoundDescription =>
      'Dit ticket is mogelijk verwijderd of uit deze werkruimte verplaatst.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'De werkruimte is gewijzigd. Ga terug naar de huidige werkruimte voordat je opslaat.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Gekoppelde ruimte openen';

  @override
  String get mobileTicketReadOnly =>
      'Je moet lid zijn van de werkruimte om tickets te wijzigen.';

  @override
  String get permissionTitle => 'Machtigingen';

  @override
  String get permissionWorkspaceFailed => 'Kan de werkruimte niet laden';

  @override
  String get permissionNoWorkspace =>
      'Selecteer een werkruimte om machtigingen te bekijken.';

  @override
  String get permissionLoading => 'Machtigingen laden…';

  @override
  String get permissionScopeDescription =>
      'Bekijk hoe per actie wordt beslist binnen dit bereik. Regels van de werkruimte kunnen worden overgenomen door agenten en ruimtes.';

  @override
  String get permissionScope => 'Beleidsbereik';

  @override
  String get permissionWorkspaceScope => 'Werkruimte';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Ruimte';

  @override
  String get permissionAgentContext => 'Agent die in deze ruimte handelt';

  @override
  String get permissionNoAgentContext => 'Geen agent geselecteerd';

  @override
  String get permissionTargetsFailed => 'Kan doelen voor dit bereik niet laden';

  @override
  String get permissionNoTargets =>
      'Geen doelen beschikbaar binnen dit bereik.';

  @override
  String get permissionRoleFailed =>
      'Kan je rol in de werkruimte niet bevestigen';

  @override
  String get permissionMemberRequired =>
      'Je moet lid zijn van de werkruimte om beleidsregels te bekijken.';

  @override
  String get permissionRulesFailed => 'Kan beleidsregels niet laden';

  @override
  String get permissionAuditAdminOnly =>
      'Alleen beheerders van de werkruimte kunnen de autorisatiegeschiedenis bekijken.';

  @override
  String get permissionAllow => 'Toestaan';

  @override
  String get permissionAsk => 'Eerst vragen';

  @override
  String get permissionDeny => 'Weigeren';

  @override
  String get permissionFileDelete => 'Bestanden verwijderen';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Buiten de worktree schrijven';

  @override
  String get permissionGitCommit => 'Wijzigingen committen';

  @override
  String get permissionGitPush => 'Commits pushen';

  @override
  String get permissionPrCreate => 'Pull requests aanmaken';

  @override
  String get permissionPrPublish => 'Pull requests publiceren';

  @override
  String get permissionVendorSyncWrite => 'Vendorsynchronisatie wijzigen';

  @override
  String get permissionNetworkEgress => 'Netwerktoegang';

  @override
  String get permissionSecretAccess => 'Toegang tot geheimen';

  @override
  String get permissionPackageInstall => 'Pakketten installeren';

  @override
  String get permissionProcessSpawn => 'Processen starten';

  @override
  String get permissionWorkspaceMutation => 'Werkruimte wijzigen';

  @override
  String get permissionEnclosureControl => 'Een omhulling (rig) aansturen';

  @override
  String get permissionChangeFailed => 'Kan de regel niet wijzigen';

  @override
  String get permissionEffectiveDescription =>
      'Geldt binnen dit bereik zonder actieargumenten. De voorwaardelijke toestemmingen hieronder gelden alleen voor overeenkomende verzoeken; de server neemt de definitieve beslissing.';

  @override
  String get permissionSpaceAgentNote =>
      'Geen agent geselecteerd. Agentspecifieke regels worden pas getoond als je hierboven een agent kiest.';

  @override
  String get permissionScopedGrants => 'Regels binnen dit bereik';

  @override
  String get permissionModePreset => 'Modusvoorinstelling';

  @override
  String get permissionBuiltInDefault => 'Standaardwaarde';

  @override
  String get permissionRemembered => 'Opgeslagen goedkeuring';

  @override
  String get permissionSource => 'Bron';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · hier ingesteld';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · overgenomen';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Verloopt op $date';
  }

  @override
  String get permissionSetHere => 'Hier een regel instellen';

  @override
  String get permissionRevokeBeforeEdit =>
      'Trek de regel voor dit bereik of de onthouden regel in voordat je een algemene regel voor deze actie instelt.';

  @override
  String get permissionConfirmRevoke => 'Intrekken bevestigen';

  @override
  String get permissionRevokeRule => 'Regel intrekken';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Opdrachtvoorvoegsel: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Verloopt niet';

  @override
  String get permissionExpired => 'Verlopen';

  @override
  String get permissionExplicitRule => 'Expliciete regel';

  @override
  String get permissionEnforcementAdvisory =>
      'Adviserend: regels met \'Eerst vragen\' worden vastgelegd zonder navraag';

  @override
  String get permissionEnforcementSoft =>
      'Zachte handhaving: voor een uitzondering is autorisatie vereist';

  @override
  String get permissionEnforcementHard =>
      'Strikte handhaving: geen uitzonderingen mogelijk';

  @override
  String permissionPaths(String paths) {
    return 'Paden: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-refs: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosts: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Opdrachten: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Maximaal aantal: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maximaal aantal centen: $cents';
  }

  @override
  String get permissionAuditHeading => 'Autorisatiegeschiedenis';

  @override
  String get permissionAuditDescription =>
      'Recente beslissingen die door de server zijn vastgelegd. Alleen beheerders kunnen het logboek bekijken of de hashketen verifiëren.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'namens $user';
  }

  @override
  String get permissionPrompted => 'Menselijke goedkeuring gevraagd';

  @override
  String get permissionVerifyChain => 'Auditketen verifiëren';

  @override
  String get permissionVerifyFailed =>
      'Auditketen kon niet worden geverifieerd';

  @override
  String permissionChainIntact(String count) {
    return 'Keten intact · $count vermeldingen gecontroleerd';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Keten verbroken bij vermelding $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Nog geen autorisatiebeslissingen vastgelegd.';

  @override
  String get permissionAuditFailed =>
      'Autorisatiegeschiedenis kon niet worden geladen';

  @override
  String get mobilePlansLoadFailed => 'Plannen konden niet worden geladen';

  @override
  String get mobilePlansEmpty => 'Nog geen plannen';

  @override
  String get mobilePlansEmptyDescription =>
      'Plannen van agenten verschijnen hier ter beoordeling.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Dit plan is niet meer beschikbaar in deze werkruimte.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count stappen';
  }

  @override
  String get mobilePlanDraft => 'Concept';

  @override
  String get mobilePlanProposed => 'Wacht op beoordeling';

  @override
  String get mobilePlanApproved => 'Goedgekeurd';

  @override
  String get mobilePlanRejected => 'Afgewezen';

  @override
  String get mobilePlanSuperseded => 'Vervangen';

  @override
  String get mobilePlanExecuting => 'Bezig';

  @override
  String get mobilePlanSynthesizing => 'Synthese';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Mislukt';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisie $revision';
  }

  @override
  String get mobilePlanSteps => 'Stappen';

  @override
  String get mobilePlanNoSteps => 'Voor dit plan zijn geen stappen ingediend.';

  @override
  String get mobilePlanAssumptions => 'Verduidelijkingen';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Afhankelijk van $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Geschat op maximaal $cost';
  }

  @override
  String get mobilePlanSelect => 'Selecteren';

  @override
  String get mobilePlanSelected => 'Geselecteerd';

  @override
  String get mobilePlanEstimate => 'Kosten schatten';

  @override
  String get mobilePlanEstimateRequired =>
      'Schat de kosten voordat je de uitvoering goedkeurt.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Geschatte kosten: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'niet beschikbaar';

  @override
  String get mobilePlanNoHardCap => 'geen vaste limiet';

  @override
  String get mobilePlanExceedsBudget =>
      'De schatting overschrijdt het ingestelde budget. Controleer dit vóór goedkeuring.';

  @override
  String get mobilePlanPartialEstimate =>
      'Deze schatting geldt voor het hele plan; geselecteerde stappen kunnen minder kosten.';

  @override
  String get mobilePlanConfirmAll => 'Het hele plan starten?';

  @override
  String get mobilePlanConfirmSelected => 'Geselecteerde stappen starten?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Na goedkeuring start de uitvoering en kunnen kosten ontstaan. Hoogste kostenraming: $cost. Budgetlimiet: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Alles goedkeuren en uitvoeren';

  @override
  String get mobilePlanApproveSelected => 'Selectie goedkeuren en uitvoeren';

  @override
  String get mobilePlanWiden => 'Extra stappen goedkeuren';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '$count extra stappen vrijgeven voor uitvoering? Hieraan kunnen kosten verbonden zijn. Bestaande kostenlimiet: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Het plan is tijdens de beoordeling gewijzigd. Open de nieuwste revisie en schat de kosten opnieuw.';

  @override
  String get mobilePlanReject => 'Plan afwijzen';

  @override
  String get mobilePlanRejectConfirm =>
      'Dit plan afwijzen? Het wordt dan niet uitgevoerd.';

  @override
  String get mobilePlanStop => 'Uitvoering stoppen';

  @override
  String get mobilePlanStopConfirm =>
      'De uitvoering van dit plan stoppen? Voltooid werk wordt niet ongedaan gemaakt.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Uitvoeringsrun: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Goedkeuring geaccepteerd. Wachten op het uitvoeringsrecord…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed van $total uitvoeringsstappen voltooid';
  }

  @override
  String get mobilePlanOpenConversation => 'Gesprek openen';

  @override
  String get mobileGoalsTitle => 'Doelen onder toezicht';

  @override
  String get mobileGoalsLoadFailed =>
      'Doelen onder toezicht konden niet worden geladen';

  @override
  String get mobileGoalsEmpty => 'Nog geen doelen onder toezicht';

  @override
  String get mobileGoalsEmptyDescription =>
      'Start er een in een ruimte of stuur /goal in een gesprek.';

  @override
  String get mobileGoalMissing =>
      'Dit doel is niet meer beschikbaar in deze werkruimte.';

  @override
  String get mobileGoalActive => 'Actief';

  @override
  String get mobileGoalPaused => 'Gepauzeerd';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Mislukt';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Budget bereikt';

  @override
  String get mobileGoalGoal => 'Doel';

  @override
  String get mobileGoalLoop => 'Cyclus';

  @override
  String mobileGoalKind(String kind) {
    return 'Type: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count uitvoeringen';
  }

  @override
  String get mobileGoalNoRunLimit => 'onbeperkt';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Runs: $runs / $maxRuns · Uitgegeven: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Einddatum: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Opeenvolgende mislukte runs: $count';
  }

  @override
  String get mobileGoalSummary => 'Samenvatting van de afronding';

  @override
  String get mobileGoalFailedDescription =>
      'De supervisor is gestopt na herhaalde mislukte runs. Bekijk het gesprek voor details.';

  @override
  String get mobileGoalBudgetWall =>
      'De deadline of runlimiet is bereikt. Dit doel kan niet worden hervat door de kostenlimiet te verhogen.';

  @override
  String get mobileGoalPause => 'Doel pauzeren';

  @override
  String get mobileGoalResume => 'Doel hervatten';

  @override
  String get mobileGoalStop => 'Doel annuleren';

  @override
  String get mobileGoalStopConfirm =>
      'Dit doel onder toezicht definitief annuleren? Het kan niet worden hervat.';

  @override
  String get mobileGoalRaiseBudget => 'Budget verhogen en hervatten';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Budget verhogen naar $amount en hervatten';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'De kostenlimiet voor dit doel verhogen van $oldCap naar $newCap en de uitgaven hervatten?';
  }

  @override
  String get mobileGoalOpenConversation => 'Doelgesprek openen';

  @override
  String get mobileGoalCreate => 'Doel onder toezicht starten';

  @override
  String get mobileGoalChooseSpace => 'Uitvoeren in ruimte';

  @override
  String get mobileGoalNoSpaces =>
      'Maak een ruimte aan voordat je een doel start.';

  @override
  String get mobileGoalChooseAgent => 'Uitvoeren met agent';

  @override
  String get mobileGoalNoAgents =>
      'Voeg een actieve agent toe voordat je een doel start.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name geselecteerd';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Welk resultaat moet de agent bereiken?';

  @override
  String get mobileGoalBudgetUsd => 'Kostenlimiet (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Kies een ruimte en agent, voer een doelstelling in en stel een positieve kostenlimiet in USD in.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Een begeleid doel starten met een maximale kostprijs van $cap? De agent kan direct beginnen.';
  }

  @override
  String get mobileGoalUnavailable =>
      'De serververbinding is nog niet beschikbaar. Probeer het opnieuw na het verbinden.';

  @override
  String get mobileGoalConversationMissing =>
      'Het geselecteerde gesprek is niet meer beschikbaar in deze werkruimte.';

  @override
  String get mobileGoalCreateSent =>
      'Doel gestart. De supervisorstatus verschijnt in deze lijst.';

  @override
  String get mobileGoalStartRefused =>
      'Er is geen run gestart. Bekijk het gesprek voor de reden van de supervisor.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name geselecteerd';
  }

  @override
  String get requestUnavailable =>
      'Dit verzoek is niet meer beschikbaar in de actieve werkruimte.';

  @override
  String get requestAlreadyResolved => 'Dit verzoek is al afgehandeld.';

  @override
  String get inboxCredentialsBlocked => 'Runs geblokkeerd door inloggegevens';

  @override
  String get inboxSyncFailures => 'Mislukte leverancierssynchronisaties';

  @override
  String get inboxConfigureCredentials => 'Inloggegevens instellen';

  @override
  String get openTicket => 'Ticket openen';

  @override
  String get activityTitle => 'Activiteit';

  @override
  String get activityClearAll => 'Activiteit wissen';

  @override
  String get activityClearConfirm =>
      'Dit verbergt alle tot nu toe vastgelegde activiteit op al je apparaten. Nieuwe activiteit blijft zichtbaar.';

  @override
  String get activityMarkAllRead => 'Alles als gelezen markeren';

  @override
  String get activityMarkAllConfirm =>
      'Alle activiteiten in deze werkruimte op al je apparaten als gelezen markeren?';

  @override
  String get activityMarkRead => 'Als gelezen markeren';

  @override
  String get activityMarkUnread => 'Als ongelezen markeren';

  @override
  String get activityDismiss => 'Afwijzen';

  @override
  String get activityResolved => 'Opgelost';

  @override
  String get activityOpen => 'Open';

  @override
  String get activityEmpty => 'Nog geen activiteit';

  @override
  String get activityLoadFailed => 'Kan activiteit niet laden';

  @override
  String get activityAgentWaiting => 'Agent wacht op invoer';

  @override
  String get activityAgentBlocked => 'Agentactie geblokkeerd';

  @override
  String get activityMessage => 'Nieuw bericht';

  @override
  String get activityPullRequest => 'Pull request bijgewerkt';

  @override
  String get activityTicket => 'Ticket bijgewerkt';

  @override
  String get activityMeeting => 'Vergadering bijgewerkt';

  @override
  String get activityCalendar => 'Agendaverbinding';

  @override
  String get activityRig => 'Rig bijgewerkt';

  @override
  String get activityEvent => 'Bijwerken';

  @override
  String get activityPrReady => 'Pull request klaar om samen te voegen';

  @override
  String get activityPrBlocked => 'Samenvoegen van pull request geblokkeerd';

  @override
  String get activityPrApproved => 'Pull request goedgekeurd';

  @override
  String get activityPrChanges => 'Wijzigingen aangevraagd';

  @override
  String get activityPrChecksFailed => 'Controles van pull request mislukt';

  @override
  String get activityPrChecksRecovered => 'Controles van pull request hersteld';

  @override
  String get activityPrComment => 'Reactie op pull request';

  @override
  String get activityPrPublished => 'Pull request gepubliceerd';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Genoemd in een pull request';

  @override
  String get activityPrReviewRequested => 'Review aangevraagd';

  @override
  String get activityPrReviewStale => 'Review moet worden vernieuwd';

  @override
  String get activityTicketAssigned => 'Ticket toegewezen';

  @override
  String get activityTicketChanged => 'Ticketstatus gewijzigd';

  @override
  String get activityMeetingSoon => 'Vergadering begint zo';

  @override
  String get activityCalendarExpired => 'Agendaverbinding verlopen';

  @override
  String get activityRigControl => 'Rigbediening gewijzigd';

  @override
  String get activityRigClosed => 'Rig gestopt';

  @override
  String get mobileSpacesSearch => 'Ruimtes zoeken';

  @override
  String get mobileSpacesArchived => 'Gearchiveerd';

  @override
  String get mobileSpacesActive => 'Actief';

  @override
  String get mobileSpacesNew => 'Nieuw ruimte';

  @override
  String get mobileSpacesManage => 'Ruimte beheren';

  @override
  String get mobileSpacesName => 'Naam van de ruimte';

  @override
  String get mobileSpacesAgents => 'Agenten';

  @override
  String get mobileSpacesMembers => 'Personen';

  @override
  String get mobileSpacesRepos => 'Repository\'s';

  @override
  String get mobileSpacesAllRepos => 'Alle gekoppelde repository\'s';

  @override
  String get mobileSpacesNoRepos => 'Geen repository\'s';

  @override
  String get mobileSpacesBaseBranch => 'Basisbranch (optioneel)';

  @override
  String get mobileSpacesDefaultBranch => 'Standaardbranch';

  @override
  String get mobileSpacesMode => 'Modus';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Review (alleen-lezen)';

  @override
  String get mobileSpacesModePlan => 'Plan (alleen-lezen)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestreren';

  @override
  String get mobileSpacesAutonomy => 'Autonomie overschrijven';

  @override
  String get mobileSpacesAutonomyInherited => 'Overgenomen';

  @override
  String get mobileSpacesAutonomyPropose => 'Alleen voorstellen';

  @override
  String get mobileSpacesAutonomyApproval => 'Handelen met goedkeuring';

  @override
  String get mobileSpacesAutonomyFreely => 'Vrij handelen';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Overschrijven omzeilt geen vragen of weigeringen van het actiebeleid. Alleen werkruimtebeheerders kunnen dit wijzigen.';

  @override
  String get mobileSpacesArchive => 'Ruimte archiveren';

  @override
  String get mobileSpacesReopen => 'Ruimte opnieuw openen';

  @override
  String get mobileSpacesSave => 'Wijzigingen opslaan';

  @override
  String get mobileSpacesCreate => 'Ruimte aanmaken';

  @override
  String get mobileSpacesOperationFailed => 'Ruimte bijwerken mislukt';

  @override
  String get mobileSpacesMissing => 'Ruimte niet gevonden in deze werkruimte';

  @override
  String get mobileSpacesEmptyName => 'Voer een naam voor de ruimte in';

  @override
  String get mobileSpacesNoMatches => 'Geen overeenkomende ruimtes';

  @override
  String get mobileSpacesUnread => 'Ongelezen antwoord van agent';

  @override
  String get mobileSpacesNeedsInput => 'Wacht op jouw invoer';

  @override
  String get mobileSpacesRunning => 'Agent is bezig';

  @override
  String get mobileSpacesNoAgents => 'Geen agenten in deze werkruimte';

  @override
  String get mobileSpacesNoMembers => 'Geen andere leden in deze werkruimte';

  @override
  String get mobileSpacesRepoError => 'Repository\'s laden mislukt';

  @override
  String get mobileSpacesRetry => 'Opnieuw proberen';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Kies of typ een basisbranch bij het aanmaken van een ruimte. De basisbranch van een bestaande ruimte kan niet worden gewijzigd.';

  @override
  String get mobileSpacesArchivedEmpty => 'Geen gearchiveerde ruimtes';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Nieuw gekoppelde repository\'s in de werkruimte worden ook aan deze ruimte toegevoegd.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ruimte aangemaakt. Probeer opnieuw personen toe te voegen of open de beheerpagina.';

  @override
  String get progressTitle => 'Voortgang';

  @override
  String get progressConversation => 'Gesprek';

  @override
  String get progressLoadFailed => 'Voortgang laden mislukt';

  @override
  String get progressUnavailable => 'Gesprek niet beschikbaar';

  @override
  String get progressUnavailableDescription =>
      'Dit gesprek staat niet in de actieve werkruimte en ruimte. Ga terug naar de bijbehorende ruimte om door te gaan.';

  @override
  String get progressSaveFailed => 'Voortgang bijwerken mislukt';

  @override
  String get progressGoal => 'Doel';

  @override
  String get progressNoGoal => 'Geen werkdoel ingesteld';

  @override
  String get progressSetGoal => 'Doel instellen';

  @override
  String get progressEditGoal => 'Doel bewerken';

  @override
  String get progressClearGoal => 'Doel wissen';

  @override
  String get progressGoalRequired => 'Voer een doel in voordat je opslaat.';

  @override
  String get progressTodos => 'Taken';

  @override
  String get transcriptToolTodos => 'Taken';

  @override
  String get transcriptToolSearchMemory => 'Geheugen doorzoeken';

  @override
  String get transcriptToolRenderMedia => 'Media weergeven';

  @override
  String get progressNoTodos => 'Nog geen taken';

  @override
  String get progressNewTodo => 'Nieuwe taak';

  @override
  String get progressAddTodo => 'Taak toevoegen';

  @override
  String get progressEditTodo => 'Taak bewerken';

  @override
  String get progressTodoRequired => 'Voer een taak in voordat je opslaat.';

  @override
  String get progressTodoNoLongerExists =>
      'Die taak is verwijderd. Laad de lijst opnieuw en probeer het nog eens.';

  @override
  String get progressWorkspaceChanged =>
      'De actieve werkruimte is gewijzigd. Ga terug naar dit gesprek en probeer het opnieuw.';

  @override
  String progressRemoveTodo(String name) {
    return 'Taak $name verwijderen';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'Bezig';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Taak omhoog';

  @override
  String get progressMoveDown => 'Taak omlaag';

  @override
  String get progressRunTree => 'Agentruns';

  @override
  String get progressNoRuns => 'Nog geen runs in dit gesprek';

  @override
  String get progressRunning => 'Actief';

  @override
  String get progressFailed => 'Mislukt';

  @override
  String get progressUnknown => 'Onbekend';

  @override
  String get progressHealthy => 'Actief';

  @override
  String get progressBlocked => 'Geblokkeerd';

  @override
  String get progressLooping => 'In een lus';

  @override
  String get progressStalled => 'Vastgelopen';

  @override
  String get progressDead => 'Onverwacht gestopt';

  @override
  String get progressQuiet => 'Nog geen uitvoer';

  @override
  String get progressCostReported => 'Door provider opgegeven kosten';

  @override
  String get progressCostNotional =>
      'Indicatieve abonnementsprijs; geen factuur';

  @override
  String get progressCostMixed => 'Verschillende kostenbronnen';

  @override
  String get progressCostEstimated => 'Geschatte kosten';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Tijd: $duration · Kosten: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Gestart $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Status: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Invoer: $input · Uitvoer: $output tokens';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Alleen de eerste 6.000 tekens van de gestructureerde uitvoer worden getoond.';

  @override
  String progressRetryOf(String runId) {
    return 'Nieuwe poging van run $runId';
  }

  @override
  String get progressContext => 'Context en limieten';

  @override
  String get progressNoAgent => 'Geen agent om te bekijken';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokens';
  }

  @override
  String get progressMeasured =>
      'Door provider opgegeven context bij de laatste aanroep';

  @override
  String get progressEstimated =>
      'Geschat op basis van opgeslagen gesprekken en blijvende context';

  @override
  String get progressContextUnknown => 'Contextgebruik nog niet opgegeven';

  @override
  String progressContextPercent(String percent) {
    return '$percent% van het contextvenster';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Ingestelde maandlimiet voor de agent: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Opgeslagen huidig gesprek: naar schatting $tokens tokens';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Blijvende context voor $agent · $model';
  }

  @override
  String get progressContextSystem => 'Systeem-prompt';

  @override
  String get progressContextRules => 'Regels';

  @override
  String get progressContextSkills => 'Vaardigheden';

  @override
  String get progressContextTools => 'Tooldefinities';

  @override
  String get progressContextMcp => 'MCP-tools';

  @override
  String get progressContextDeferred => 'Uitgestelde tools';

  @override
  String get progressContextSubagents => 'Subagents';

  @override
  String get progressContextRunner => 'Externe runner';

  @override
  String get progressContextMemory => 'GEHEUGEN';

  @override
  String get progressContextHistory => 'Gespreksgeschiedenis';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokens';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokens';
  }

  @override
  String get progressOutputs => 'Recente uitvoer';

  @override
  String get progressNoOutputs => 'Geen recente uitvoer van agenten';

  @override
  String get progressStructuredOutputsAbove =>
      'De gestructureerde uitvoer staat bij de agentruns hierboven.';

  @override
  String get progressRecentOutputsOnly =>
      'Alleen recente berichten worden getoond. Open het gesprek voor ouder werk.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefact';

  @override
  String get progressResult => 'Resultaat';

  @override
  String get progressHideArtifact => 'Artefact verbergen';

  @override
  String get progressReadArtifact => 'Artefact lezen';

  @override
  String get progressArtifactUnavailable => 'Artefact niet meer beschikbaar';

  @override
  String get progressArtifactPreviewLimited =>
      'Beperkt voorbeeld van dit artefact.';

  @override
  String get progressDiagramSource => 'Diagrambron';

  @override
  String progressOpenAttachment(String name) {
    return '$name openen';
  }

  @override
  String get progressOpenPlan => 'Plan openen';

  @override
  String progressOpenDiff(String label) {
    return 'Gewijzigde bestanden bekijken: $label';
  }

  @override
  String get progressViewMessage => 'Bericht bekijken';

  @override
  String get pushTitle => 'Meldingen op de achtergrond';

  @override
  String get pushIntro =>
      'Ontvang een privéwaarschuwing als iets je aandacht nodig heeft, ook wanneer de app gesloten is. Details blijven binnen je versleutelde verbinding.';

  @override
  String get pushLoading => 'Meldingsinstellingen controleren…';

  @override
  String get pushError =>
      'Meldingen konden niet worden bijgewerkt. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get pushEnable => 'Meldingen inschakelen';

  @override
  String get pushDisable => 'Meldingen uitschakelen';

  @override
  String get pushQuiet => 'Meldingen op dit apparaat pauzeren';

  @override
  String get pushCategories => 'Meld me over';

  @override
  String get pushCategoryAgents => 'Agenten';

  @override
  String get pushCategoryMessages => 'Berichten';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Agenda';

  @override
  String get pushCategoryMachines => 'Machines';

  @override
  String get pushSecureOrigin => 'Voor meldingen is HTTPS vereist.';

  @override
  String get pushInstallIos =>
      'Voeg deze app op je iPhone of iPad toe aan het beginscherm en open hem daar om meldingen in te schakelen.';

  @override
  String get pushUnsupported =>
      'Deze browser ondersteunt geen meldingen op de achtergrond.';

  @override
  String get pushDenied =>
      'De browser meldt dat meldingen geblokkeerd zijn. Controleer de toestemming voor deze site en de meldingsinstellingen van de browser of het apparaat en vernieuw de pagina.';

  @override
  String get pushOsHint =>
      'Je browser heeft ook toestemming nodig om meldingen te tonen in de systeeminstellingen van je apparaat.';

  @override
  String get pushServiceUnavailable =>
      'De pushservice van de browser heeft het abonnement geweigerd. Sommige browsers, zoals Brave, zetten die standaard uit: zoek in de privacyinstellingen van de browser naar een optie voor pushberichten en probeer het opnieuw.';

  @override
  String get pushWorkerUnavailable =>
      'De meldingsservice kon niet starten in deze browser. Laad de pagina opnieuw en probeer het nog eens.';

  @override
  String get pushResubscribe => 'Meldingen opnieuw verbinden';

  @override
  String get pushStatusEnabled => 'Meldingen staan aan op dit apparaat.';

  @override
  String get pushStatusDisabled => 'Meldingen staan uit op dit apparaat.';

  @override
  String get credentialsTitle => 'Verbindingen en inloggegevens';

  @override
  String get credentialsIntro =>
      'Koppel de accounts die je runs en integraties gebruiken. Geheimen worden op je server opgeslagen, niet op deze telefoon.';

  @override
  String get credentialsModelProviders => 'Modelaanbieders';

  @override
  String get credentialsOwnerOnly =>
      'Alleen de servereigenaar kan inloggegevens voor modelaanbieders toevoegen of verwijderen en zich bij die aanbieders aanmelden. Deze sleutels worden gedeeld tussen werkruimtes.';

  @override
  String get credentialsContactOwner =>
      'Vraag de servereigenaar om de aanbieder te koppelen die je geblokkeerde run nodig heeft.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code meldt zich aan via de CLI op de host. Vraag de servereigenaar de aanmelding in de terminal op de host te voltooien of te vernieuwen; dit kan niet op deze telefoon.';

  @override
  String get credentialsYourForgeAccounts => 'Je accounts bij codeplatforms';

  @override
  String get credentialsYourTicketingAccount => 'Je account voor ticketbeheer';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Voor lokale tickets hoef je je niet aan te melden. Koppel hier Linear als je werkruimte Linear gebruikt.';

  @override
  String get credentialsMembershipRequired =>
      'Word lid van een werkruimte om je inloggegevens voor codeplatforms of ticketbeheer te beheren. Vraag een werkruimtebeheerder om toegang.';

  @override
  String get credentialsSwitchWorkspace =>
      'Deze link verwijst naar een andere werkruimte. Schakel naar die werkruimte voordat je inloggegevens wijzigt.';

  @override
  String get credentialsReturnToInbox =>
      'Ga terug naar de inbox om een geblokkeerde run opnieuw te proberen zodra de inloggegevens zijn gekoppeld. De host controleert geparkeerde runs ook automatisch.';

  @override
  String get credentialsLoadFailed =>
      'Verbindingen konden niet worden geladen. Controleer de serververbinding en probeer het opnieuw.';

  @override
  String get credentialsOperationFailed =>
      'Deze verbinding kon niet worden gewijzigd. Controleer de serververbinding, je toegang en de inloggegevens en probeer het opnieuw.';

  @override
  String get credentialsConnected => 'Verbonden';

  @override
  String get credentialsNotConnected => 'Niet verbonden';

  @override
  String credentialsSignedInAs(String username) {
    return 'Aangemeld als $username';
  }

  @override
  String get credentialsAccount => 'Gekoppeld account';

  @override
  String get credentialsStoredKey => 'Opgeslagen sleutel';

  @override
  String get credentialsActive => 'Actief';

  @override
  String get credentialsRemove => 'Verwijderen';

  @override
  String get credentialsRemoveConfirm =>
      'Je opgeslagen inloggegevens verwijderen? Mogelijk moet je je opnieuw aanmelden.';

  @override
  String get credentialsApiKey => 'API-sleutel';

  @override
  String get credentialsApiKeyHint => 'Plak een API-sleutel van de aanbieder';

  @override
  String get credentialsBrowserLogin => 'Aanmelden via browser';

  @override
  String get credentialsSignInAgain => 'Meld je opnieuw aan';

  @override
  String get credentialsWaitingForLogin =>
      'Wachten op toestemming in je browser…';

  @override
  String get credentialsLoginTimedOut =>
      'De aanmelding is verlopen. Begin opnieuw met aanmelden.';

  @override
  String get credentialsCopyCode => 'Code kopiëren';

  @override
  String get credentialsDeviceCodeHint =>
      'Bevestig deze code op de pagina van de aanbieder. Houd dit scherm open terwijl de server de aanmelding voltooit.';

  @override
  String get credentialsPasteRedirect => 'Autorisatiecode of omleidings-URL';

  @override
  String get credentialsPasteRedirectHint =>
      'Plak de code of volledige omleidings-URL van de aanbieder';

  @override
  String get credentialsCompleteLogin => 'Aanmelding voltooien';

  @override
  String get credentialsRedirectUnavailable =>
      'De browsercallback van deze server is niet veilig bereikbaar vanaf een telefoon. Vraag de servereigenaar om een openbare HTTPS-callback in te stellen of voeg in plaats daarvan een token toe.';

  @override
  String get credentialsUpdateToken => 'Token bijwerken';

  @override
  String get credentialsAddToken => 'Token toevoegen';

  @override
  String get credentialsPersonalToken => 'Persoonlijk toegangstoken';

  @override
  String get credentialsPersonalTokenHint =>
      'Plak een persoonlijk toegangstoken';

  @override
  String get credentialsHostManaged =>
      'Deze verbinding komt uit de serverapp of de omgeving. Alleen de servereigenaar kan deze daar wijzigen; je kunt wel je eigen token toevoegen.';

  @override
  String get credentialsStopWatching => 'Stoppen met volgen';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Aanmelding bij Claude Code verlopen';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'De run is gestopt omdat het account zich niet meer authenticeert. Meld je opnieuw aan en probeer de beurt dan opnieuw.';

  @override
  String get transcriptSignInExpiredTitle => 'Aanmelding bij provider verlopen';

  @override
  String get transcriptSignInExpiredBody =>
      'De run is gestopt omdat de inloggegevens van de provider niet meer werken. Verbind hem opnieuw via Instellingen → Providers en probeer de beurt dan opnieuw.';
}
