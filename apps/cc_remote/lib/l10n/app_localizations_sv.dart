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
  String get copyCommand => 'Kopiera kommando';

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
      'Skanna QR-koden från Control Center för att parkoppla den här telefonen.';

  @override
  String get scanQrHelp =>
      'Öppna kameran och rikta den mot QR-koden som visas i Control Center. Den här telefonen ansluter direkt över en privat länk.';

  @override
  String get connectingToMac => 'Ansluter till Control Center…';

  @override
  String get connectingDetail => 'Upprättar en säker, direkt länk.';

  @override
  String get identityChangedTitle => 'Serverns identitet har ändrats';

  @override
  String get identityChangedBody =>
      'Den här servern matchar inte längre identiteten som sparades när du parkopplade. Det kan betyda att servern har installerats om — eller att något fångar upp anslutningen. För säkerhets skull ansluter den här enheten inte. Ta bort parkopplingen och skanna sedan en ny QR-kod från Control Center för att parkoppla igen.';

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
      'Inte parkopplad — skanna QR-koden från Control Center';

  @override
  String get failureUnreachable =>
      'Kunde inte nå servern på någon väg — kontrollera att den körs, eller prova samma nätverk';

  @override
  String get failureIdentityChanged =>
      'Serverns identitet har ändrats — om den installerats om, parkoppla den här enheten igen';

  @override
  String get failureAuthRejected =>
      'Servern avvisade den här enheten — parkoppla den igen från Control Center';

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
      'Tryck igen för att koppla från den här enheten från Control Center';

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
  String get newSpaceFolder => 'Ny mapp';

  @override
  String get folderName => 'Mappnamn';

  @override
  String get renameSpaceFolder => 'Byt namn på mapp';

  @override
  String get deleteSpaceFolder => 'Ta bort mapp';

  @override
  String get moveSpaceToFolder => 'Flytta till mapp';

  @override
  String get removeSpaceFromFolder => 'Ta bort från mapp';

  @override
  String get spaceFolderActions => 'Mappåtgärder';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Om du tar bort utrymmen permanent försvinner deras meddelanden och arbetskataloger för alla. Det går inte att ångra.';

  @override
  String get deleteSpacesInFolder =>
      'Ta bort utrymmena i den här mappen permanent';

  @override
  String get deleteFolderAndSpaces => 'Ta bort mapp och utrymmen';

  @override
  String get keepSpacesInFolder => 'Annars blir utrymmena kvar utanför mappar.';

  @override
  String get create => 'Skapa';

  @override
  String get otherSpaces => 'Andra utrymmen';

  @override
  String get folderUpdateFailed => 'Det gick inte att uppdatera mapparna';

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

  @override
  String get mobileConversations => 'Samtal';

  @override
  String get mobileNewConversation => 'Nytt samtal';

  @override
  String get mobileConversationName => 'Samtalsnamn';

  @override
  String get mobileRename => 'Byt namn';

  @override
  String get mobileManageSpace => 'Hantera yta';

  @override
  String get mobileArchived => 'Arkiverat';

  @override
  String get mobileSearchMessages => 'Sök i alla meddelanden på ytan';

  @override
  String get mobileSearch => 'Sök';

  @override
  String get mobileNoResults => 'Inga resultat';

  @override
  String get mobileReopen => 'Öppna igen';

  @override
  String get mobileArchive => 'Arkivera';

  @override
  String get mobileProgress => 'Förlopp och kontext';

  @override
  String get mobileReadFailed => 'Kunde inte markera samtalet som läst';

  @override
  String get mobileSendFailed =>
      'Meddelandet skickades inte. Ditt utkast finns kvar.';

  @override
  String get sentAttachmentUnavailable => 'Bilagan är inte tillgänglig';

  @override
  String get sentAttachmentLoadFailed => 'Kunde inte läsa in bilagan';

  @override
  String get mobileActionFailed => 'Åtgärden misslyckades';

  @override
  String get mobileRemove => 'Ta bort';

  @override
  String get mobileLinkedMessage => 'Länkat meddelande';

  @override
  String get mobileOlderMessages => 'Äldre meddelanden';

  @override
  String get mobileMessageActions => 'Meddelandeåtgärder';

  @override
  String get mobileOpenThread => 'Öppna tråd';

  @override
  String get mobileCopyLink => 'Kopiera länk';

  @override
  String get mobileStopRun => 'Stoppa körning';

  @override
  String get mobileStopRunConfirm =>
      'Stoppa agentkörningen? Redan slutfört arbete sparas.';

  @override
  String get mobileControlUnsupported =>
      'Körningen är avslutad eller stöder inte den här åtgärden.';

  @override
  String get mobilePauseRequested => 'Paus begärd efter aktuell tur';

  @override
  String get mobileResumed => 'Körningen har återupptagits';

  @override
  String get mobileStopRequested => 'Stopp begärt';

  @override
  String get mobileQueuedMessages => 'Köade meddelanden';

  @override
  String get mobilePauseRun => 'Pausa efter aktuell tur';

  @override
  String get mobileResumeRun => 'Återuppta';

  @override
  String get mobileEditQueued => 'Redigera köat meddelande';

  @override
  String get mobileSteerNow => 'Styr nu';

  @override
  String get mobileMoveUp => 'Flytta upp';

  @override
  String get mobileMoveDown => 'Flytta ner';

  @override
  String get mobileQueueChanged =>
      'Kön har ändrats eller så kan körningen inte ta emot styrning i realtid. Uppdatera och försök igen.';

  @override
  String get mobileActivity => 'Aktivitet';

  @override
  String get mobilePermissions => 'Behörigheter och granskningslogg';

  @override
  String get mobilePlans => 'Planer';

  @override
  String get mobileGoals => 'Övervakade mål';

  @override
  String get mobileCredentials => 'Anslutningar och inloggningsuppgifter';

  @override
  String get mobileWorkspaceUnavailable =>
      'Arbetsytan är inte tillgänglig eller så har du inte längre åtkomst.';

  @override
  String get mobilePrReviewThreads => 'Granskningstrådar';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Kunde inte läsa in granskningstrådar';

  @override
  String get mobilePrNoReviewThreads =>
      'Inga granskningstrådar för enskilda rader ännu';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Du har inte behörighet att kommentera i det här arkivet.';

  @override
  String get mobilePrPermissionChecking => 'Kontrollerar kommentarsbehörighet…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Kunde inte kontrollera kommentarsbehörighet. Försök igen för att kommentera.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, rad $line';
  }

  @override
  String get mobilePrOriginalSide => 'Ursprunglig';

  @override
  String get mobilePrSelectCommentLine => 'Välj en rad att kommentera';

  @override
  String get mobilePrUpdatedSide => 'Uppdaterad';

  @override
  String get mobilePrThreadResolved => 'Löst';

  @override
  String get mobilePrReplyHint => 'Skriv ett svar…';

  @override
  String get mobilePrCommentRequired =>
      'Skriv en kommentar innan du publicerar.';

  @override
  String get mobilePrReply => 'Svara';

  @override
  String get mobilePrReopenThread => 'Öppna tråden igen';

  @override
  String get mobilePrResolveThread => 'Lös tråden';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Bara den som skapade pull requesten eller någon med skrivbehörighet kan lösa tråden.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Kommentera $side, rad $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Skriv en radkommentar…';

  @override
  String get mobilePrPostInlineComment => 'Publicera kommentar';

  @override
  String get mobilePrCommentUnavailable =>
      'Radkommentarer är inte tillgängliga för den här pull requesten.';

  @override
  String get mobilePrPatchUnavailable =>
      'Kodplattformen tillhandahöll ingen textpatch för filen.';

  @override
  String get mobilePrNoPatchForFile => 'Patchen för filen är inte tillgänglig.';

  @override
  String get mobileTicketNew => 'Nytt ärende';

  @override
  String get mobileTicketCreate => 'Skapa ärende';

  @override
  String get mobileTicketEdit => 'Redigera ärende';

  @override
  String get mobileTicketTitle => 'Titel';

  @override
  String get mobileTicketTitleRequired =>
      'Ange en titel för att spara ärendet.';

  @override
  String get mobileTicketDescription => 'Beskrivning';

  @override
  String get mobileTicketMarkdownHint => 'Lägg till detaljer i Markdown';

  @override
  String get mobileTicketPriority => 'Prioritet';

  @override
  String get mobileTicketPriorityNone => 'Ingen prioritet';

  @override
  String get mobileTicketPriorityUrgent => 'Brådskande';

  @override
  String get mobileTicketPriorityHigh => 'Hög';

  @override
  String get mobileTicketPriorityMedium => 'Medel';

  @override
  String get mobileTicketPriorityLow => 'Låg';

  @override
  String get mobileTicketLabels => 'Etiketter';

  @override
  String get mobileTicketLabelsHint => 'En etikett per rad';

  @override
  String get mobileTicketLabelsHelp => 'Ange varje etikett på en egen rad.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrerat i $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Ej tilldelad';

  @override
  String get mobileTicketAssignedFilter => 'Tilldelade';

  @override
  String get mobileTicketAgentsLoadFailed => 'Kunde inte läsa in agenter';

  @override
  String get mobileTicketSearch => 'Sök ärenden';

  @override
  String get mobileTicketSearchHint =>
      'Titel, nyckel, beskrivning, etikett eller ansvarig';

  @override
  String get mobileTicketClearSearch => 'Rensa ärendesökning';

  @override
  String get mobileTicketNoMatches => 'Inga matchande ärenden';

  @override
  String get mobileTicketAdjustFilters =>
      'Prova en annan sökning eller ändra filtren.';

  @override
  String get mobileTicketClearFilters => 'Rensa filter';

  @override
  String get mobileTicketNotFound => 'Ärendet hittades inte';

  @override
  String get mobileTicketNotFoundDescription =>
      'Ärendet kan ha tagits bort eller flyttats från arbetsytan.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Arbetsytan har ändrats. Återgå till den aktuella arbetsytan innan du sparar.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Öppna länkad yta';

  @override
  String get mobileTicketReadOnly =>
      'Du måste ha medlemsrollen i arbetsytan för att ändra ärenden.';

  @override
  String get permissionTitle => 'Behörigheter';

  @override
  String get permissionWorkspaceFailed => 'Kunde inte läsa in arbetsytan';

  @override
  String get permissionNoWorkspace =>
      'Välj en arbetsyta för att granska behörigheter.';

  @override
  String get permissionLoading => 'Läser in behörigheter…';

  @override
  String get permissionScopeDescription =>
      'Se hur varje åtgärd bedöms på den här nivån. Arbetsytans regler kan ärvas av agenter och ytor.';

  @override
  String get permissionScope => 'Regelnivå';

  @override
  String get permissionWorkspaceScope => 'Arbetsyta';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Yta';

  @override
  String get permissionAgentContext => 'Agent som agerar på ytan';

  @override
  String get permissionNoAgentContext => 'Ingen agent vald';

  @override
  String get permissionTargetsFailed => 'Kunde inte läsa in objekt för nivån';

  @override
  String get permissionNoTargets =>
      'Inga objekt är tillgängliga på den här nivån.';

  @override
  String get permissionRoleFailed =>
      'Kunde inte bekräfta din roll i arbetsytan';

  @override
  String get permissionMemberRequired =>
      'Du måste ha medlemsrollen i arbetsytan för att se behörighetsregler.';

  @override
  String get permissionRulesFailed => 'Kunde inte läsa in behörighetsregler';

  @override
  String get permissionAuditAdminOnly =>
      'Behörighetshistoriken är bara tillgänglig för arbetsytans administratörer.';

  @override
  String get permissionAllow => 'Tillåt';

  @override
  String get permissionAsk => 'Fråga först';

  @override
  String get permissionDeny => 'Neka';

  @override
  String get permissionFileDelete => 'Ta bort filer';

  @override
  String get permissionFileWriteOutsideWorktree => 'Skriv utanför arbetsträdet';

  @override
  String get permissionGitCommit => 'Skapa commits';

  @override
  String get permissionGitPush => 'Pusha commits';

  @override
  String get permissionPrCreate => 'Skapa pull requests';

  @override
  String get permissionPrPublish => 'Publicera pull requests';

  @override
  String get permissionVendorSyncWrite => 'Skriv till ett externt ärendesystem';

  @override
  String get permissionNetworkEgress => 'Använd nätverket';

  @override
  String get permissionSecretAccess => 'Läs hemligheter';

  @override
  String get permissionPackageInstall => 'Installera paket';

  @override
  String get permissionProcessSpawn => 'Starta processer';

  @override
  String get permissionWorkspaceMutation => 'Ändra arbetsyta';

  @override
  String get permissionEnclosureControl => 'Styr en avskild miljö (station)';

  @override
  String get permissionChangeFailed => 'Kunde inte ändra regeln';

  @override
  String get permissionEffectiveDescription =>
      'Gäller på den här nivån utan åtgärdsargument. Villkorade behörigheter nedan gäller bara matchande förfrågningar. Servern fattar det slutliga beslutet.';

  @override
  String get permissionSpaceAgentNote =>
      'Ingen agent vald. Agentspecifika regler visas först när du väljer en agent ovan.';

  @override
  String get permissionScopedGrants => 'Regler på den här nivån';

  @override
  String get permissionModePreset => 'Lägesförinställning';

  @override
  String get permissionBuiltInDefault => 'Inbyggd standard';

  @override
  String get permissionRemembered => 'Sparat godkännande';

  @override
  String get permissionSource => 'Källa';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · angiven här';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · ärvd';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Går ut $date';
  }

  @override
  String get permissionSetHere => 'Ange en regel här';

  @override
  String get permissionRevokeBeforeEdit =>
      'Återkalla den nivåspecifika eller sparade regeln innan du anger en allmän regel för åtgärden.';

  @override
  String get permissionConfirmRevoke => 'Bekräfta återkallande';

  @override
  String get permissionRevokeRule => 'Återkalla regel';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Kommandoprefix: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Ingen utgångstid';

  @override
  String get permissionExpired => 'Utgången';

  @override
  String get permissionExplicitRule => 'Uttrycklig regel';

  @override
  String get permissionEnforcementAdvisory =>
      'Rådgivande: Fråga först-regler loggas utan att någon fråga visas';

  @override
  String get permissionEnforcementSoft =>
      'Mjuk tillämpning: undantag kräver godkännande';

  @override
  String get permissionEnforcementHard =>
      'Strikt tillämpning: kan inte åsidosättas';

  @override
  String permissionPaths(String paths) {
    return 'Sökvägar: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-referenser: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Värdar: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Kommandon: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Högsta antal: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Högsta belopp i cent: $cents';
  }

  @override
  String get permissionAuditHeading => 'Behörighetshistorik';

  @override
  String get permissionAuditDescription =>
      'Senaste besluten som registrerats av servern. Endast administratörer kan granska loggen eller verifiera dess hashkedja.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'för $user';
  }

  @override
  String get permissionPrompted => 'Mänskligt godkännande begärt';

  @override
  String get permissionVerifyChain => 'Verifiera loggkedjan';

  @override
  String get permissionVerifyFailed => 'Kunde inte verifiera loggkedjan';

  @override
  String permissionChainIntact(String count) {
    return 'Kedjan är intakt · $count poster kontrollerade';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Kedjan är bruten vid post $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Inga behörighetsbeslut har registrerats ännu.';

  @override
  String get permissionAuditFailed =>
      'Kunde inte läsa in behörighetshistoriken';

  @override
  String get mobilePlansLoadFailed => 'Kunde inte läsa in planer';

  @override
  String get mobilePlansEmpty => 'Inga planer ännu';

  @override
  String get mobilePlansEmptyDescription =>
      'Planer som agenter skickar in visas här för granskning.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Den här planen är inte längre tillgänglig i den här arbetsytan.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count steg';
  }

  @override
  String get mobilePlanDraft => 'Utkast';

  @override
  String get mobilePlanProposed => 'Väntar på granskning';

  @override
  String get mobilePlanApproved => 'Godkänd';

  @override
  String get mobilePlanRejected => 'Avvisad';

  @override
  String get mobilePlanSuperseded => 'Ersatt';

  @override
  String get mobilePlanExecuting => 'Körs';

  @override
  String get mobilePlanSynthesizing => 'Syntetiserar';

  @override
  String get mobilePlanCompleted => 'Slutförd';

  @override
  String get mobilePlanFailed => 'Misslyckades';

  @override
  String get mobilePlanCancelled => 'Avbruten';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revision $revision';
  }

  @override
  String get mobilePlanSteps => 'Steg';

  @override
  String get mobilePlanNoSteps =>
      'Inga steg har skickats in för den här planen.';

  @override
  String get mobilePlanAssumptions => 'Förtydliganden';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Beror på $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Beräknas kosta högst $cost';
  }

  @override
  String get mobilePlanSelect => 'Välj';

  @override
  String get mobilePlanSelected => 'Vald';

  @override
  String get mobilePlanEstimate => 'Beräkna kostnad';

  @override
  String get mobilePlanEstimateRequired =>
      'Beräkna planens kostnad innan du godkänner körningen.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Beräknad kostnad: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'inte tillgänglig';

  @override
  String get mobilePlanNoHardCap => 'inget fast tak';

  @override
  String get mobilePlanExceedsBudget =>
      'Den beräknade kostnaden överskrider den inställda budgeten. Granska innan du godkänner.';

  @override
  String get mobilePlanPartialEstimate =>
      'Kostnadsberäkningen gäller hela planen. Valda steg kan kosta mindre.';

  @override
  String get mobilePlanConfirmAll => 'Starta hela planen?';

  @override
  String get mobilePlanConfirmSelected => 'Starta valda steg?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Godkännandet startar körningen och kan medföra kostnader. Beräknad övre kostnad: $cost. Budgettak: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Godkänn alla och kör';

  @override
  String get mobilePlanApproveSelected => 'Godkänn valda och kör';

  @override
  String get mobilePlanWiden => 'Godkänn fler steg';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Tillåt körning av ytterligare $count steg? De kan medföra kostnader. Befintligt kostnadstak för körningen: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Planen ändrades under granskningen. Öppna den senaste revisionen och beräkna kostnaden igen.';

  @override
  String get mobilePlanReject => 'Avvisa plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Avvisa den här planen? Den kommer inte att köras.';

  @override
  String get mobilePlanStop => 'Stoppa körning';

  @override
  String get mobilePlanStopConfirm =>
      'Stoppa körningen av den här planen? Redan slutfört arbete ångras inte.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Körning: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Godkännandet har tagits emot. Väntar på att körningen registreras…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed av $total körningssteg slutförda';
  }

  @override
  String get mobilePlanOpenConversation => 'Öppna samtal';

  @override
  String get mobileGoalsTitle => 'Övervakade mål';

  @override
  String get mobileGoalsLoadFailed => 'Kunde inte läsa in övervakade mål';

  @override
  String get mobileGoalsEmpty => 'Inga övervakade mål ännu';

  @override
  String get mobileGoalsEmptyDescription =>
      'Starta ett i en yta eller skicka /goal i ett samtal.';

  @override
  String get mobileGoalMissing =>
      'Det här målet är inte längre tillgängligt i den här arbetsytan.';

  @override
  String get mobileGoalActive => 'Aktiv';

  @override
  String get mobileGoalPaused => 'Pausat';

  @override
  String get mobileGoalCompleted => 'Slutförd';

  @override
  String get mobileGoalFailed => 'Misslyckades';

  @override
  String get mobileGoalCancelled => 'Avbruten';

  @override
  String get mobileGoalBudgetExhausted => 'Budgetgränsen nådd';

  @override
  String get mobileGoalGoal => 'Mål';

  @override
  String get mobileGoalLoop => 'Slinga';

  @override
  String mobileGoalKind(String kind) {
    return 'Typ: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count körningar';
  }

  @override
  String get mobileGoalNoRunLimit => 'obegränsat';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Körningar: $runs / $maxRuns · Förbrukat: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Tidsgräns: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Misslyckade körningar i rad: $count';
  }

  @override
  String get mobileGoalSummary => 'Slutsammanfattning';

  @override
  String get mobileGoalFailedDescription =>
      'Övervakaren stoppade efter upprepade misslyckade körningar. Se samtalet för mer information.';

  @override
  String get mobileGoalBudgetWall =>
      'Tidsgränsen eller körningsgränsen har nåtts. Målet kan inte återupptas genom att höja kostnadstaket.';

  @override
  String get mobileGoalPause => 'Pausa mål';

  @override
  String get mobileGoalResume => 'Återuppta mål';

  @override
  String get mobileGoalStop => 'Avbryt mål';

  @override
  String get mobileGoalStopConfirm =>
      'Avbryt det här övervakade målet permanent? Det kan inte återupptas.';

  @override
  String get mobileGoalRaiseBudget => 'Höj budgeten och återuppta';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Höj budgeten till $amount och återuppta';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Höj målets kostnadstak från $oldCap till $newCap och tillåt fortsatta kostnader?';
  }

  @override
  String get mobileGoalOpenConversation => 'Öppna målets samtal';

  @override
  String get mobileGoalCreate => 'Starta övervakat mål';

  @override
  String get mobileGoalChooseSpace => 'Kör i yta';

  @override
  String get mobileGoalNoSpaces => 'Skapa en yta innan du startar ett mål.';

  @override
  String get mobileGoalChooseAgent => 'Kör med agent';

  @override
  String get mobileGoalNoAgents =>
      'Lägg till en aktiv agent innan du startar ett mål.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name har valts';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Vilket resultat ska agenten sträva efter?';

  @override
  String get mobileGoalBudgetUsd => 'Kostnadstak (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Välj en yta och en agent, ange en målsättning och sätt ett positivt kostnadstak i USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Starta ett övervakat mål med en högsta kostnad på $cap? Agenten kan börja direkt.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Serveranslutningen är inte redo. Försök igen efter att anslutningen har återställts.';

  @override
  String get mobileGoalConversationMissing =>
      'Det valda samtalet är inte längre tillgängligt i den här arbetsytan.';

  @override
  String get mobileGoalCreateSent =>
      'Målet har startats. Övervakarens status visas i den här listan.';

  @override
  String get mobileGoalStartRefused =>
      'Ingen målkörning startades. Se samtalet för övervakarens motivering.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name har valts';
  }

  @override
  String get requestUnavailable =>
      'Den här begäran är inte längre tillgänglig i den aktiva arbetsytan.';

  @override
  String get requestAlreadyResolved => 'Den här begäran har redan hanterats.';

  @override
  String get inboxCredentialsBlocked =>
      'Inloggningsuppgifter blockerar körningar';

  @override
  String get inboxSyncFailures => 'Misslyckade leverantörssynkroniseringar';

  @override
  String get inboxConfigureCredentials => 'Konfigurera inloggningsuppgifter';

  @override
  String get openTicket => 'Öppna ärende';

  @override
  String get activityTitle => 'Aktivitet';

  @override
  String get activityClearAll => 'Rensa aktivitet';

  @override
  String get activityClearConfirm =>
      'Detta döljer all aktivitet som hittills registrerats för dig på alla dina enheter. Ny aktivitet visas fortfarande.';

  @override
  String get activityMarkAllRead => 'Markera alla som lästa';

  @override
  String get activityMarkAllConfirm =>
      'Markera all aktivitet i den här arbetsytan som läst på alla dina enheter?';

  @override
  String get activityMarkRead => 'Markera som läst';

  @override
  String get activityMarkUnread => 'Markera som oläst';

  @override
  String get activityDismiss => 'Stäng';

  @override
  String get activityResolved => 'Löst';

  @override
  String get activityOpen => 'Öppen';

  @override
  String get activityEmpty => 'Ingen aktivitet ännu';

  @override
  String get activityLoadFailed => 'Kunde inte läsa in aktivitet';

  @override
  String get activityAgentWaiting => 'Agenten behöver svar';

  @override
  String get activityAgentBlocked => 'Agentens åtgärd blockerad';

  @override
  String get activityMessage => 'Nytt meddelande';

  @override
  String get activityPullRequest => 'Uppdatering av pull request';

  @override
  String get activityTicket => 'Ärendeuppdatering';

  @override
  String get activityMeeting => 'Mötesuppdatering';

  @override
  String get activityCalendar => 'Kalenderanslutning';

  @override
  String get activityRig => 'Stationsuppdatering';

  @override
  String get activityEvent => 'Uppdatera';

  @override
  String get activityPrReady => 'Pull request redo att slås samman';

  @override
  String get activityPrBlocked => 'Sammanslagning av pull request blockerad';

  @override
  String get activityPrApproved => 'Pull request godkänd';

  @override
  String get activityPrChanges => 'Ändringar begärda';

  @override
  String get activityPrChecksFailed =>
      'Kontroller av pull request misslyckades';

  @override
  String get activityPrChecksRecovered =>
      'Kontroller av pull request fungerar igen';

  @override
  String get activityPrComment => 'Kommentar på pull request';

  @override
  String get activityPrPublished => 'Pull request publicerad';

  @override
  String get activityPrMerged => 'Pull request sammanslagen';

  @override
  String get activityPrMentioned => 'Omnämnd i en pull request';

  @override
  String get activityPrReviewRequested => 'Granskning begärd';

  @override
  String get activityPrReviewStale => 'Granskningen behöver uppdateras';

  @override
  String get activityTicketAssigned => 'Ärende tilldelat';

  @override
  String get activityTicketChanged => 'Ärendestatus ändrad';

  @override
  String get activityMeetingSoon => 'Mötet börjar snart';

  @override
  String get activityCalendarExpired => 'Kalenderanslutningen har gått ut';

  @override
  String get activityRigControl => 'Stationens styrning har ändrats';

  @override
  String get activityRigClosed => 'Stationen har stoppats';

  @override
  String get mobileSpacesSearch => 'Sök ytor';

  @override
  String get mobileSpacesArchived => 'Arkiverat';

  @override
  String get mobileSpacesActive => 'Aktiv';

  @override
  String get mobileSpacesNew => 'Ny yta';

  @override
  String get mobileSpacesManage => 'Hantera yta';

  @override
  String get mobileSpacesName => 'Ytnamn';

  @override
  String get mobileSpacesAgents => 'Agenter';

  @override
  String get mobileSpacesMembers => 'Personer';

  @override
  String get mobileSpacesRepos => 'Arkiv';

  @override
  String get mobileSpacesAllRepos => 'Alla länkade arkiv';

  @override
  String get mobileSpacesNoRepos => 'Inga arkiv';

  @override
  String get mobileSpacesBaseBranch => 'Basgren (valfritt)';

  @override
  String get mobileSpacesDefaultBranch => 'Standardgren';

  @override
  String get mobileSpacesMode => 'Läge';

  @override
  String get mobileSpacesModeChat => 'Chatt';

  @override
  String get mobileSpacesModeReview => 'Granska (skrivskyddat)';

  @override
  String get mobileSpacesModePlan => 'Planera (skrivskyddat)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestrera';

  @override
  String get mobileSpacesAutonomy => 'Åsidosätt autonomi';

  @override
  String get mobileSpacesAutonomyInherited => 'Ärvt';

  @override
  String get mobileSpacesAutonomyPropose => 'Bara föreslå';

  @override
  String get mobileSpacesAutonomyApproval => 'Agera med godkännande';

  @override
  String get mobileSpacesAutonomyFreely => 'Agera fritt';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Ett åsidosättande kan inte kringgå åtgärdspolicyns godkännandekrav eller nekanden. Endast arbetsytans administratörer kan ändra det.';

  @override
  String get mobileSpacesArchive => 'Arkivera yta';

  @override
  String get mobileSpacesReopen => 'Öppna ytan igen';

  @override
  String get mobileSpacesSave => 'Spara ändringar';

  @override
  String get mobileSpacesCreate => 'Skapa yta';

  @override
  String get mobileSpacesOperationFailed => 'Det gick inte att uppdatera ytan';

  @override
  String get mobileSpacesMissing => 'Ytan hittades inte i den här arbetsytan';

  @override
  String get mobileSpacesEmptyName => 'Ange ett ytnamn';

  @override
  String get mobileSpacesNoMatches => 'Inga matchande ytor';

  @override
  String get mobileSpacesUnread => 'Oläst agentsvar';

  @override
  String get mobileSpacesNeedsInput => 'Behöver din återkoppling';

  @override
  String get mobileSpacesRunning => 'Agenten körs';

  @override
  String get mobileSpacesNoAgents => 'Inga agenter i den här arbetsytan';

  @override
  String get mobileSpacesNoMembers => 'Inga andra medlemmar i arbetsytan';

  @override
  String get mobileSpacesRepoError => 'Det gick inte att läsa in arkiven';

  @override
  String get mobileSpacesRetry => 'Försök igen';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Välj eller ange en basgren när du skapar en yta. Basgrenen kan inte ändras för befintliga ytor.';

  @override
  String get mobileSpacesArchivedEmpty => 'Inga arkiverade ytor';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Arkiv som länkas till arbetsytan framöver kommer också att ingå i den här ytan.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ytan har skapats. Försök lägga till personer igen eller öppna ytans hanteringssida.';

  @override
  String get progressTitle => 'Förlopp';

  @override
  String get progressConversation => 'Samtal';

  @override
  String get progressLoadFailed => 'Det gick inte att läsa in förloppet';

  @override
  String get progressUnavailable => 'Samtalet är inte tillgängligt';

  @override
  String get progressUnavailableDescription =>
      'Det här samtalet finns inte i den aktiva arbetsytan och ytan. Gå tillbaka till samtalets yta för att fortsätta.';

  @override
  String get progressSaveFailed => 'Det gick inte att uppdatera förloppet';

  @override
  String get progressGoal => 'Mål';

  @override
  String get progressNoGoal => 'Inget arbetsmål angivet';

  @override
  String get progressSetGoal => 'Sätt mål';

  @override
  String get progressEditGoal => 'Redigera mål';

  @override
  String get progressClearGoal => 'Rensa mål';

  @override
  String get progressGoalRequired => 'Ange ett mål innan du sparar.';

  @override
  String get progressTodos => 'Uppgifter';

  @override
  String get transcriptToolTodos => 'Uppgifter';

  @override
  String get transcriptToolSearchMemory => 'Sök i minnet';

  @override
  String get transcriptToolRenderMedia => 'Visa media';

  @override
  String get progressNoTodos => 'Inga uppgifter ännu';

  @override
  String get progressNewTodo => 'Ny uppgift';

  @override
  String get progressAddTodo => 'Lägg till uppgift';

  @override
  String get progressEditTodo => 'Redigera uppgift';

  @override
  String get progressTodoRequired => 'Ange en uppgift innan du sparar.';

  @override
  String get progressTodoNoLongerExists =>
      'Uppgiften har tagits bort. Läs in listan igen och försök på nytt.';

  @override
  String get progressWorkspaceChanged =>
      'Den aktiva arbetsytan har ändrats. Gå tillbaka till det här samtalet och försök igen.';

  @override
  String progressRemoveTodo(String name) {
    return 'Ta bort uppgiften $name';
  }

  @override
  String get progressPending => 'Väntar';

  @override
  String get progressInProgress => 'Pågår';

  @override
  String get progressCompleted => 'Slutförd';

  @override
  String get progressMoveUp => 'Flytta upp uppgiften';

  @override
  String get progressMoveDown => 'Flytta ner uppgiften';

  @override
  String get progressRunTree => 'Agentkörningar';

  @override
  String get progressNoRuns => 'Inga körningar i det här samtalet ännu';

  @override
  String get progressRunning => 'Körs';

  @override
  String get progressFailed => 'Misslyckades';

  @override
  String get progressUnknown => 'Okänd';

  @override
  String get progressHealthy => 'Aktiv';

  @override
  String get progressBlocked => 'Blockerad';

  @override
  String get progressLooping => 'Fast i en loop';

  @override
  String get progressStalled => 'Har stannat av';

  @override
  String get progressDead => 'Stoppades oväntat';

  @override
  String get progressQuiet => 'Inga utdata ännu';

  @override
  String get progressCostReported => 'Avgift rapporterad av leverantören';

  @override
  String get progressCostNotional =>
      'Teoretiskt listpris för abonnemanget, inte en faktura';

  @override
  String get progressCostMixed => 'Blandade kostnadskällor';

  @override
  String get progressCostEstimated => 'Uppskattad kostnad';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modell: $model · Tid: $duration · Kostnad: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Startad $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Hälsa: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Indata: $input · Utdata: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Endast de första 6 000 tecknen i strukturerade utdata visas.';

  @override
  String progressRetryOf(String runId) {
    return 'Nytt försök av körning $runId';
  }

  @override
  String get progressContext => 'Kontext och gränser';

  @override
  String get progressNoAgent => 'Ingen agent att inspektera';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Kontext rapporterad av leverantören vid det senaste anropet';

  @override
  String get progressEstimated =>
      'Uppskattat utifrån det lagrade samtalet och beständig kontext';

  @override
  String get progressContextUnknown =>
      'Kontextanvändningen har inte rapporterats ännu';

  @override
  String progressContextPercent(String percent) {
    return '$percent% av kontextfönstret';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Inställd månadsgräns för agenten: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Lagrat pågående samtal: uppskattningsvis $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Beständig kontext för $agent · $model';
  }

  @override
  String get progressContextSystem => 'Systemprompt';

  @override
  String get progressContextRules => 'Regler';

  @override
  String get progressContextSkills => 'Färdigheter';

  @override
  String get progressContextTools => 'Verktygsdefinitioner';

  @override
  String get progressContextMcp => 'MCP-verktyg';

  @override
  String get progressContextDeferred => 'Uppskjutna verktyg';

  @override
  String get progressContextSubagents => 'Subagenter';

  @override
  String get progressContextRunner => 'Extern körare';

  @override
  String get progressContextMemory => 'Minne';

  @override
  String get progressContextHistory => 'Samtalshistorik';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Senaste utdata';

  @override
  String get progressNoOutputs => 'Inga utdata från agenten på sistone';

  @override
  String get progressStructuredOutputsAbove =>
      'Strukturerade utdata från körningar visas i agentkörningarna ovan.';

  @override
  String get progressRecentOutputsOnly =>
      'Endast de senaste meddelandena visas. Öppna samtalet för att se tidigare arbete.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Resultat';

  @override
  String get progressHideArtifact => 'Dölj artefakt';

  @override
  String get progressReadArtifact => 'Läs artefakt';

  @override
  String get progressArtifactUnavailable =>
      'Artefakten är inte längre tillgänglig';

  @override
  String get progressArtifactPreviewLimited =>
      'En begränsad förhandsvisning av artefakten visas.';

  @override
  String get progressDiagramSource => 'Diagramkälla';

  @override
  String progressOpenAttachment(String name) {
    return 'Öppna $name';
  }

  @override
  String get progressOpenPlan => 'Öppna plan';

  @override
  String progressOpenDiff(String label) {
    return 'Granska ändrade filer: $label';
  }

  @override
  String get progressViewMessage => 'Visa meddelande';

  @override
  String get pushTitle => 'Bakgrundsaviseringar';

  @override
  String get pushIntro =>
      'Få en privat avisering när något behöver din uppmärksamhet, även när appen är stängd. Detaljerna stannar inom din krypterade anslutning.';

  @override
  String get pushLoading => 'Kontrollerar aviseringsinställningar…';

  @override
  String get pushError =>
      'Det gick inte att uppdatera aviseringarna. Kontrollera anslutningen och försök igen.';

  @override
  String get pushEnable => 'Aktivera aviseringar';

  @override
  String get pushDisable => 'Stäng av aviseringar';

  @override
  String get pushQuiet => 'Pausa aviseringar på den här enheten';

  @override
  String get pushCategories => 'Avisera mig om';

  @override
  String get pushCategoryAgents => 'Agenter';

  @override
  String get pushCategoryMessages => 'Meddelanden';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Ärenden';

  @override
  String get pushCategoryCalendar => 'Kalender';

  @override
  String get pushCategoryMachines => 'Datorer';

  @override
  String get pushSecureOrigin => 'Aviseringar kräver HTTPS.';

  @override
  String get pushInstallIos =>
      'På iPhone eller iPad lägger du till appen på hemskärmen och öppnar den där för att aktivera aviseringar.';

  @override
  String get pushUnsupported =>
      'Den här webbläsaren stöder inte bakgrundsaviseringar.';

  @override
  String get pushDenied =>
      'Webbläsaren rapporterar att aviseringar är blockerade. Kontrollera webbplatsens behörighet och aviseringsinställningarna i webbläsaren eller på enheten, och uppdatera sedan sidan.';

  @override
  String get pushResubscribe => 'Återanslut aviseringar';

  @override
  String get pushStatusEnabled => 'Aviseringar är på för den här enheten.';

  @override
  String get pushStatusDisabled => 'Aviseringar är av för den här enheten.';

  @override
  String get credentialsTitle => 'Anslutningar och inloggningsuppgifter';

  @override
  String get credentialsIntro =>
      'Anslut kontona som dina körningar och integrationer använder. Hemligheter lagras på din server, inte på den här telefonen.';

  @override
  String get credentialsModelProviders => 'Modellleverantörer';

  @override
  String get credentialsOwnerOnly =>
      'Bara serverägaren kan lägga till, logga in på eller ta bort inloggningsuppgifter för modellleverantörer. Nycklarna delas mellan arbetsytor.';

  @override
  String get credentialsContactOwner =>
      'Be serverägaren ansluta leverantören som den blockerade körningen behöver.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code loggar in via CLI på värddatorn. Be serverägaren logga in eller förnya inloggningen i värddatorns terminal. Det går inte från den här telefonen.';

  @override
  String get credentialsYourForgeAccounts => 'Dina konton på kodplattformar';

  @override
  String get credentialsYourTicketingAccount => 'Ditt ärendekonto';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Lokala ärenden kräver ingen inloggning. Anslut Linear här om din arbetsyta använder Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Gå med i en arbetsyta för att hantera inloggningsuppgifter för kodplattformar eller ärendesystem. Be en administratör om åtkomst.';

  @override
  String get credentialsSwitchWorkspace =>
      'Länken pekar på en annan arbetsyta. Byt till den arbetsytan innan du ändrar inloggningsuppgifter.';

  @override
  String get credentialsReturnToInbox =>
      'Gå tillbaka till Inkorgen och försök köra igen när inloggningsuppgifterna har anslutits. Värddatorn kontrollerar också pausade körningar automatiskt.';

  @override
  String get credentialsLoadFailed =>
      'Kunde inte läsa in anslutningar. Kontrollera serveranslutningen och försök igen.';

  @override
  String get credentialsOperationFailed =>
      'Kunde inte ändra anslutningen. Kontrollera serveranslutningen, din åtkomst och inloggningsuppgifterna och försök igen.';

  @override
  String get credentialsConnected => 'Ansluten';

  @override
  String get credentialsNotConnected => 'Inte ansluten';

  @override
  String credentialsSignedInAs(String username) {
    return 'Inloggad som $username';
  }

  @override
  String get credentialsAccount => 'Anslutet konto';

  @override
  String get credentialsStoredKey => 'Sparad nyckel';

  @override
  String get credentialsActive => 'Aktiv';

  @override
  String get credentialsRemove => 'Ta bort';

  @override
  String get credentialsRemoveConfirm =>
      'Ta bort dina sparade inloggningsuppgifter? Du kan behöva logga in igen.';

  @override
  String get credentialsApiKey => 'API-nyckel';

  @override
  String get credentialsApiKeyHint =>
      'Klistra in en API-nyckel från leverantören';

  @override
  String get credentialsBrowserLogin => 'Logga in via webbläsaren';

  @override
  String get credentialsSignInAgain => 'Logga in igen';

  @override
  String get credentialsWaitingForLogin =>
      'Väntar på godkännande i din webbläsare…';

  @override
  String get credentialsLoginTimedOut =>
      'Inloggningsförsöket har gått ut. Starta ett nytt försök.';

  @override
  String get credentialsCopyCode => 'Kopiera kod';

  @override
  String get credentialsDeviceCodeHint =>
      'Bekräfta koden på leverantörens sida. Låt den här skärmen vara öppen medan servern slutför inloggningen.';

  @override
  String get credentialsPasteRedirect =>
      'Auktoriseringskod eller omdirigeringsadress';

  @override
  String get credentialsPasteRedirectHint =>
      'Klistra in koden eller den fullständiga omdirigeringsadressen från leverantören';

  @override
  String get credentialsCompleteLogin => 'Slutför inloggningen';

  @override
  String get credentialsRedirectUnavailable =>
      'Serverns webbläsaråteranrop kan inte nås säkert från en telefon. Be serverägaren konfigurera ett publikt HTTPS-återanrop eller lägg till en token i stället.';

  @override
  String get credentialsUpdateToken => 'Uppdatera token';

  @override
  String get credentialsAddToken => 'Lägg till token';

  @override
  String get credentialsPersonalToken => 'Personlig åtkomsttoken';

  @override
  String get credentialsPersonalTokenHint =>
      'Klistra in en personlig åtkomsttoken';

  @override
  String get credentialsHostManaged =>
      'Anslutningen kommer från serverappen eller serverns miljö. Bara serverägaren kan ändra den där, men du kan lägga till en egen token.';

  @override
  String get credentialsStopWatching => 'Sluta bevaka';
}
