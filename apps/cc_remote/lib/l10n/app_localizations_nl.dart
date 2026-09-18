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
      'Scan de QR-code op je Mac om deze telefoon te koppelen.';

  @override
  String get scanQrHelp =>
      'Open je camera en richt die op de QR in Control Center op je Mac. Deze telefoon maakt rechtstreeks via een privéverbinding contact met je Mac.';

  @override
  String get connectingToMac => 'Verbinden met je Mac…';

  @override
  String get connectingDetail =>
      'Beveiligde, directe verbinding wordt opgezet.';

  @override
  String get identityChangedTitle => 'Serveridentiteit gewijzigd';

  @override
  String get identityChangedBody =>
      'Deze server komt niet meer overeen met de identiteit die bij het koppelen is opgeslagen. Dat kan betekenen dat de server opnieuw is geïnstalleerd — of dat iets de verbinding onderschept. Voor je veiligheid maakt dit apparaat geen verbinding. Verwijder de koppeling en scan daarna een nieuwe QR-code op je Mac om opnieuw te koppelen.';

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
  String get failureNotPaired => 'Niet gekoppeld — scan de QR-code op je Mac';

  @override
  String get failureUnreachable =>
      'Server via geen enkel pad bereikbaar — controleer of die actief is, of probeer hetzelfde netwerk';

  @override
  String get failureIdentityChanged =>
      'De identiteit van de server is gewijzigd — als die opnieuw is geïnstalleerd, koppel dit apparaat opnieuw';

  @override
  String get failureAuthRejected =>
      'De server wees dit apparaat af — koppel het opnieuw vanaf je Mac';

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
      'Tik nogmaals om dit apparaat van je Mac te ontkoppelen';

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
}
