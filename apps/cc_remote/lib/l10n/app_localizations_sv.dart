// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Tillbaka';

  @override
  String get cancel => 'Avbryt';

  @override
  String get retry => 'Försök igen';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get settings => 'Inställningar';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get approve => 'Godkänn';

  @override
  String get deny => 'Neka';

  @override
  String get continueLabel => 'Fortsätt';

  @override
  String get agentQuestionHeader => 'Fråga till dig';

  @override
  String get agentQuestionAnsweredLabel => 'Besvarad';

  @override
  String get agentQuestionSkip => 'Hoppa över';

  @override
  String get agentQuestionSkippedLabel => 'Överhoppad';

  @override
  String get agentQuestionFreeformHint => 'Skriv ditt svar…';

  @override
  String get agentApprovalRequired => 'Godkännande krävs';

  @override
  String get approveAndRemember => 'Godkänn i 8 timmar';

  @override
  String get decline => 'Avböj';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get send => 'Skicka';

  @override
  String get close => 'Stäng';

  @override
  String get expand => 'Visa mer';

  @override
  String get zoomIn => 'Zooma in';

  @override
  String get zoomOut => 'Zooma ut';

  @override
  String get resetZoom => 'Återställ zoom';

  @override
  String get scanQrPrompt =>
      'Skanna QR-koden från din Mac för att parkoppla den här telefonen.';

  @override
  String get scanQrHelp =>
      'Öppna kameran och rikta den mot QR-koden som visas i Control Center på din Mac. Den här telefonen ansluter direkt till din Mac över en privat länk.';

  @override
  String get connectingToMac => 'Ansluter till din Mac…';

  @override
  String get connectingDetail => 'Upprättar en säker, direkt länk.';

  @override
  String get identityChangedTitle => 'Serverns identitet har ändrats';

  @override
  String get identityChangedBody =>
      'Den här servern matchar inte längre identiteten som sparades när du parkopplade. Det kan betyda att servern har installerats om — eller att något fångar upp anslutningen. För säkerhets skull ansluter den här enheten inte. Ta bort parkopplingen och skanna sedan en ny QR-kod från din Mac för att parkoppla igen.';

  @override
  String get removePairing => 'Ta bort parkoppling';

  @override
  String get couldntConnect => 'Kunde inte ansluta';

  @override
  String get pendingPairingTitle => 'Anslut till den här servern?';

  @override
  String get pendingPairingBody =>
      'En länk bad Control Center att parkoppla med den här servern. Fortsätt bara om du startade det själv.';

  @override
  String get connect => 'Anslut';

  @override
  String get failureNotPaired =>
      'Inte parkopplad — skanna QR-koden från din Mac';

  @override
  String get failureUnreachable =>
      'Kunde inte nå servern på någon väg — kontrollera att den körs, eller prova samma nätverk';

  @override
  String get failureIdentityChanged =>
      'Serverns identitet har ändrats — om den installerats om, parkoppla den här enheten igen';

  @override
  String get failureAuthRejected =>
      'Servern avvisade den här enheten — parkoppla den igen från din Mac';

  @override
  String get failureUnknown =>
      'Kunde inte ansluta — tryck för att försöka igen';

  @override
  String get statusConnected => 'Ansluten';

  @override
  String get statusConnecting => 'Ansluter';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identitetsfel';

  @override
  String get statusNotPaired => 'Inte parkopplad';

  @override
  String get statusConfirmPairing => 'Bekräfta parkoppling';

  @override
  String get connectionFailed => 'Anslutningen misslyckades';

  @override
  String get identityMismatchBanner =>
      'Serverns identitet har ändrats — anslutningen stoppades. Parkoppla den här enheten igen för att fortsätta.';

  @override
  String get tabInbox => 'Inkorg';

  @override
  String get tabTickets => 'Ärenden';

  @override
  String get tabChat => 'Chatt';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabNews => 'Nyheter';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count väntar';
  }

  @override
  String get updateAvailable => 'En ny Control Center är tillgänglig';

  @override
  String get appearance => 'Utseende';

  @override
  String get language => 'Språk';

  @override
  String get device => 'Enhet';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Tryck igen för att koppla från den här enheten från din Mac';

  @override
  String get disconnectDevice => 'Koppla från den här enheten';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get chooseWorkspace => 'Välj arbetsyta';

  @override
  String get workspaces => 'Arbetsytor';

  @override
  String get workspacesLoadFailed => 'Kunde inte läsa in arbetsytor';

  @override
  String get noWorkspacesYet => 'Inga arbetsytor ännu';

  @override
  String selectWorkspace(String name) {
    return 'Välj $name';
  }

  @override
  String get inboxLoadFailed => 'Kunde inte läsa in inkorgen';

  @override
  String get allCaughtUp => 'Du är ikapp';

  @override
  String get inboxNoForgeAccount =>
      'Inget forge-konto är anslutet på servern, så pull requests kan inte tillskrivas dig ännu.';

  @override
  String get inboxNothingWaiting =>
      'Inget är blockerat och ingen pull request väntar på dig.';

  @override
  String get blocked => 'Blockerad';

  @override
  String get sectionNeedsYourReview => 'Behöver din granskning';

  @override
  String get sectionReturnedToYou => 'Åter till dig';

  @override
  String get sectionApprovedAndReady => 'Godkända och redo';

  @override
  String get sectionYourDrafts => 'Dina utkast';

  @override
  String get sectionWaitingForReviewers => 'Väntar på granskare';

  @override
  String get sectionMergingAndMerged => 'Sammanslås och nyligen sammanslagna';

  @override
  String get sectionWaitingForAuthor => 'Väntar på författare';

  @override
  String waitingAgo(String ago) {
    return 'väntar $ago';
  }

  @override
  String get openConversation => 'Öppna samtalet';

  @override
  String get calendarLoadFailed => 'Kunde inte läsa in kalendern';

  @override
  String get nothingScheduled => 'Inget inbokat';

  @override
  String get calendarEmptyDescription =>
      'Händelser från dina anslutna kalendrar visas här.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synka kalendrar nu';

  @override
  String get event => 'Händelse';

  @override
  String get eventNotFound => 'Händelsen hittades inte';

  @override
  String get eventNotFoundDescription =>
      'Den kan ligga utanför agendafönstret, eller ha tagits bort uppströms.';

  @override
  String get joinMeeting => 'Anslut till mötet';

  @override
  String get join => 'Anslut';

  @override
  String attendeesCount(int count) {
    return 'Deltagare ($count)';
  }

  @override
  String get details => 'Detaljer';

  @override
  String get allDay => 'Heldag';

  @override
  String get happeningNow => 'Pågår nu';

  @override
  String inDuration(String duration) {
    return 'Om $duration';
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
  String get attendeeAccepted => 'accepterat';

  @override
  String get attendeeDeclined => 'avböjt';

  @override
  String get attendeeMaybe => 'kanske';

  @override
  String get attendeeNoReply => 'inget svar';

  @override
  String get organizer => 'organisatör';

  @override
  String get calendarNoAccounts =>
      'Ingen kalender är ansluten för den här arbetsytan. Anslut en från desktopappen — inloggningen lagrar tokenet på servern.';

  @override
  String get calendarReauthNeeded =>
      'Ett kalenderkonto måste anslutas igen — det du ser nedan kan vara inaktuellt. Anslut det igen från desktopappen.';

  @override
  String get spacesLoadFailed => 'Kunde inte läsa in ytor';

  @override
  String get noSpaces => 'Inga ytor';

  @override
  String get spacesEmptyDescription => 'Ytor i den här arbetsytan visas här.';

  @override
  String get thread => 'Tråd';

  @override
  String get agentWorking => 'Agenten arbetar';

  @override
  String get messagesLoadFailed => 'Kunde inte läsa in meddelanden';

  @override
  String get noMessagesYet => 'Inga meddelanden ännu';

  @override
  String get noMessagesDescription =>
      'Skicka ett meddelande för att starta samtalet.';

  @override
  String get agentResponding => 'Agenten svarar';

  @override
  String get agentFinished => 'Agenten är klar';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names är för stora för att skickas härifrån.',
      one: '$names är för stor för att skickas härifrån.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names är för stora för att skickas över relän härifrån.',
      one: '$names är för stor för att skickas över relän härifrån.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Kunde inte ladda upp bilagan. Försök igen.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bilagor kunde inte laddas upp och utelämnades.',
      one: '1 bilaga kunde inte laddas upp och utelämnades.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Kollega';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Bifoga en fil';

  @override
  String get messageHint => 'Meddelande';

  @override
  String removeAttachment(String name) {
    return 'Ta bort $name';
  }

  @override
  String get articlesLoadFailed => 'Kunde inte läsa in artiklar';

  @override
  String get noArticles => 'Inga artiklar';

  @override
  String get articlesEmptyDescription =>
      'Nya artiklar visas här när flöden uppdateras.';

  @override
  String get unread => 'Olästa';

  @override
  String get allFeeds => 'Alla flöden';

  @override
  String get save => 'Spara';

  @override
  String get unsave => 'Ta bort sparad';

  @override
  String get readFullArticle => 'Läs hela artikeln';

  @override
  String get ticketsLoadFailed => 'Kunde inte läsa in ärenden';

  @override
  String get noTickets => 'Inga ärenden';

  @override
  String get ticketsEmptyDescription =>
      'Ärenden i den här arbetsytan visas här.';

  @override
  String get all => 'Alla';

  @override
  String get ticket => 'Ärende';

  @override
  String get ticketLoadFailed => 'Kunde inte läsa in ärendet';

  @override
  String assignedTo(String name) {
    return 'Tilldelad $name';
  }

  @override
  String get openInBrowser => 'Öppna i webbläsaren';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Tilldela';

  @override
  String get reassign => 'Tilldela om';

  @override
  String get noAgents => 'Inga agenter';

  @override
  String get noAgentsDescription =>
      'Tilldela en agent från den här arbetsytan.';

  @override
  String get statusOpen => 'Öppen';

  @override
  String get statusInProgress => 'Pågår';

  @override
  String get statusBlocked => 'Blockerad';

  @override
  String get statusInReview => 'Under granskning';

  @override
  String get statusDone => 'Klar';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Behöver mig';

  @override
  String get lensMine => 'Mina';

  @override
  String get prsLoadFailed => 'Kunde inte läsa in pull requests';

  @override
  String get noOpenPullRequests => 'Inga öppna pull requests';

  @override
  String get nothingWaitingOnReview => 'Inget väntar på din granskning';

  @override
  String get noOwnOpenPullRequests => 'Du har inga öppna pull requests';

  @override
  String get nothingBlocked => 'Inget är blockerat';

  @override
  String get prsEmptyDescription =>
      'Pull requests från den här arbetsytans repon visas här.';

  @override
  String get refreshPullRequests => 'Uppdatera pull requests';

  @override
  String get noForgeConnected =>
      'Ingen forge är ansluten på servern, så inga pull requests kan hämtas. Anslut en från desktopappen.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repon kunde inte läsas.',
      one: '1 repo kunde inte läsas.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Går inte att läsa: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'GitHub App-installationen är avstängd';

  @override
  String installationSuspendedBody(String names) {
    return 'Visar senast kända data för $names. Återuppta installationen på GitHub, eller anslut en token som har åtkomst.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App-installationen är avstängd. Visar senast kända data för $names. Återuppta installationen på GitHub, eller anslut en token som har åtkomst.';
  }

  @override
  String get draft => 'Utkast';

  @override
  String get merged => 'Sammanslagen';

  @override
  String get closed => 'Stängd';

  @override
  String get open => 'Öppen';

  @override
  String get approved => 'Godkänd';

  @override
  String get changesRequested => 'Ändringar begärda';

  @override
  String get reviewRequired => 'Granskning krävs';

  @override
  String get checksPassing => 'Kontroller går igenom';

  @override
  String get checksFailing => 'Kontroller misslyckas';

  @override
  String get checksRunning => 'Kontroller körs';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Kunde inte läsa in den här pull requesten';

  @override
  String get openOnForge => 'Öppna på forge';

  @override
  String get requestChangesNeedsComment =>
      'Lägg till en kommentar som förklarar vad som behöver ändras.';

  @override
  String get conversation => 'Samtal';

  @override
  String get files => 'Filer';

  @override
  String get checks => 'Kontroller';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
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
  String get conflicts => 'Konflikter';

  @override
  String get reviewers => 'Granskare';

  @override
  String get noDescriptionNoComments =>
      'Ingen beskrivning och inga kommentarer ännu.';

  @override
  String get noChangedFiles => 'Inga ändrade filer.';

  @override
  String get noChecksReported =>
      'Inga kontroller rapporterade för head-commit.';

  @override
  String get reviewCommentHint => 'Lämna en granskningskommentar…';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentPosted => 'Kommentaren publicerades';

  @override
  String get request => 'Begär';

  @override
  String get squashAndMerge => 'Squasha och slå samman';

  @override
  String noActionsAvailable(String status) {
    return '$status — inga åtgärder tillgängliga.';
  }

  @override
  String get reviewApproved => 'godkände';

  @override
  String get reviewRequestedChanges => 'begärde ändringar';

  @override
  String get reviewCommented => 'granskade';

  @override
  String get reviewPending => 'väntar';

  @override
  String get unknownAuthor => 'okänd';

  @override
  String hideDiffFor(String file) {
    return 'Dölj diffen för $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Visa diffen för $file';
  }

  @override
  String get checkRunning => 'körs';

  @override
  String get checkPassed => 'godkänd';

  @override
  String get checkFailed => 'misslyckades';

  @override
  String get checkCancelled => 'avbruten';

  @override
  String get checkSkipped => 'hoppades över';

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
      'Ingen textdiff för den här filen — den är binär, eller för stor för att forge ska returnera en.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visa de återstående $count raderna',
      one: 'Visa den återstående raden',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oförändrade rader',
      one: '1 oförändrad rad',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Hoppa till senaste';

  @override
  String get streaming => 'Strömmar';

  @override
  String get working => 'Arbetar';

  @override
  String get input => 'Indata';

  @override
  String get output => 'Utdata';

  @override
  String get now => 'nu';

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
  String get today => 'Idag';

  @override
  String get tomorrow => 'Imorgon';

  @override
  String get yesterday => 'Igår';

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
