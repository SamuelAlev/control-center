// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'חזרה';

  @override
  String get cancel => 'ביטול';

  @override
  String get retry => 'ניסיון חוזר';

  @override
  String get tryAgain => 'נסו שוב';

  @override
  String get settings => 'הגדרות';

  @override
  String get refresh => 'רענון';

  @override
  String get approve => 'אישור';

  @override
  String get deny => 'דחייה';

  @override
  String get continueLabel => 'המשך';

  @override
  String get agentQuestionHeader => 'שאלה אליכם';

  @override
  String get agentQuestionAnsweredLabel => 'נענתה';

  @override
  String get agentQuestionSkip => 'דילוג';

  @override
  String get agentQuestionSkippedLabel => 'דולגה';

  @override
  String get agentQuestionFreeformHint => 'הקלידו את תשובתכם…';

  @override
  String get agentApprovalRequired => 'נדרש אישור';

  @override
  String get copyCommand => 'העתקת הפקודה';

  @override
  String get approveAndRemember => 'אישור ל־8 שעות';

  @override
  String get decline => 'סירוב';

  @override
  String get confirm => 'אישור';

  @override
  String get send => 'שליחה';

  @override
  String get close => 'סגירה';

  @override
  String get expand => 'הרחבה';

  @override
  String get zoomIn => 'הגדלה';

  @override
  String get zoomOut => 'הקטנה';

  @override
  String get resetZoom => 'איפוס זום';

  @override
  String get scanQrPrompt =>
      'סרקו את קוד ה-QR מ-Control Center כדי לצמד את הטלפון הזה.';

  @override
  String get scanQrHelp =>
      'פתחו את המצלמה וכוונו אותה אל קוד ה-QR שמוצג ב-Control Center. הטלפון הזה מתחבר ישירות בקישור פרטי.';

  @override
  String get connectingToMac => 'מתחבר ל-Control Center…';

  @override
  String get connectingDetail => 'יוצר חיבור ישיר ומאובטח.';

  @override
  String get identityChangedTitle => 'זהות השרת השתנתה';

  @override
  String get identityChangedBody =>
      'השרת הזה כבר לא תואם את הזהות שנשמרה בעת הצימוד. ייתכן שהשרת הותקן מחדש — או שמשהו מיירט את החיבור. ליתר ביטחון, המכשיר הזה לא יתחבר. הסירו את הצימוד, ואז סרקו קוד QR חדש מ-Control Center כדי לצמד מחדש.';

  @override
  String get removePairing => 'הסרת הצימוד';

  @override
  String get couldntConnect => 'לא ניתן להתחבר';

  @override
  String get pendingPairingTitle => 'להתחבר לשרת הזה?';

  @override
  String get pendingPairingBody =>
      'קישור ביקש מ-Control Center לבצע צימוד לשרת הזה. המשיכו רק אם יזמתם זאת בעצמכם.';

  @override
  String get connect => 'התחברות';

  @override
  String get failureNotPaired =>
      'אין צימוד — סרקו את קוד ה-QR מ-Control Center';

  @override
  String get failureUnreachable =>
      'לא ניתן להגיע לשרת בשום נתיב — ודאו שהוא פועל, או נסו מאותה רשת';

  @override
  String get failureIdentityChanged =>
      'זהות השרת השתנתה — אם הוא הותקן מחדש, צמדו את המכשיר מחדש';

  @override
  String get failureAuthRejected =>
      'השרת דחה את המכשיר הזה — צמדו אותו מחדש מ-Control Center';

  @override
  String get failureUnknown => 'לא ניתן להתחבר — הקישו כדי לנסות שוב';

  @override
  String get statusConnected => 'מחובר';

  @override
  String get statusConnecting => 'מתחבר';

  @override
  String get statusOffline => 'לא מקוון';

  @override
  String get statusIdentityMismatch => 'אי-התאמת זהות';

  @override
  String get statusNotPaired => 'אין צימוד';

  @override
  String get statusConfirmPairing => 'אישור צימוד';

  @override
  String get connectionFailed => 'החיבור נכשל';

  @override
  String get identityMismatchBanner =>
      'זהות השרת השתנתה — החיבור הופסק. צמדו את המכשיר מחדש כדי להמשיך.';

  @override
  String get tabInbox => 'דואר נכנס';

  @override
  String get tabTickets => 'כרטיסים';

  @override
  String get tabChat => 'צ\'אט';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'יומן';

  @override
  String get tabNews => 'חדשות';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count בהמתנה';
  }

  @override
  String get updateAvailable => 'גרסה חדשה של Control Center זמינה';

  @override
  String get appearance => 'מראה';

  @override
  String get language => 'שפה';

  @override
  String get device => 'מכשיר';

  @override
  String get themeSystem => 'מערכת';

  @override
  String get themeLight => 'בהיר';

  @override
  String get themeDark => 'כהה';

  @override
  String get languageSystem => 'מערכת';

  @override
  String get disconnectTapAgain =>
      'הקישו שוב כדי לנתק את המכשיר הזה מ-Control Center';

  @override
  String get disconnectDevice => 'ניתוק המכשיר הזה';

  @override
  String get disconnect => 'ניתוק';

  @override
  String get chooseWorkspace => 'בחירת סביבת עבודה';

  @override
  String get workspaces => 'סביבות עבודה';

  @override
  String get workspacesLoadFailed => 'לא ניתן לטעון את סביבות העבודה';

  @override
  String get noWorkspacesYet => 'עדיין אין סביבות עבודה';

  @override
  String selectWorkspace(String name) {
    return 'בחירת $name';
  }

  @override
  String get inboxLoadFailed => 'לא ניתן לטעון את הדואר הנכנס';

  @override
  String get allCaughtUp => 'התעדכנתם בהכול';

  @override
  String get inboxNoForgeAccount =>
      'לא מחובר חשבון forge בשרת, ולכן עדיין לא ניתן לשייך אליכם בקשות משיכה.';

  @override
  String get inboxNothingWaiting =>
      'שום דבר לא חסום ואף בקשת משיכה לא ממתינה לכם.';

  @override
  String get blocked => 'חסומים';

  @override
  String get sectionNeedsYourReview => 'ממתינים לסקירה שלכם';

  @override
  String get sectionReturnedToYou => 'הוחזרו אליכם';

  @override
  String get sectionApprovedAndReady => 'מאושרים ומוכנים';

  @override
  String get sectionYourDrafts => 'הטיוטות שלכם';

  @override
  String get sectionWaitingForReviewers => 'ממתינים לסוקרים';

  @override
  String get sectionMergingAndMerged => 'במיזוג ומוזגו לאחרונה';

  @override
  String get sectionWaitingForAuthor => 'ממתינים למחבר';

  @override
  String waitingAgo(String ago) {
    return 'ממתין $ago';
  }

  @override
  String get openConversation => 'פתיחת השיחה';

  @override
  String get calendarLoadFailed => 'לא ניתן לטעון את היומן';

  @override
  String get nothingScheduled => 'אין אירועים מתוכננים';

  @override
  String get calendarEmptyDescription =>
      'אירועים מהיומנים המחוברים שלכם יופיעו כאן.';

  @override
  String get agenda => 'סדר יום';

  @override
  String get syncCalendarsNow => 'סנכרון היומנים עכשיו';

  @override
  String get event => 'אירוע';

  @override
  String get eventNotFound => 'האירוע לא נמצא';

  @override
  String get eventNotFoundDescription =>
      'ייתכן שהוא מחוץ לחלון סדר היום, או שהוסר במקור.';

  @override
  String get joinMeeting => 'הצטרפות לפגישה';

  @override
  String get join => 'הצטרפות';

  @override
  String attendeesCount(int count) {
    return 'משתתפים ($count)';
  }

  @override
  String get details => 'פרטים';

  @override
  String get allDay => 'כל היום';

  @override
  String get happeningNow => 'מתרחש עכשיו';

  @override
  String inDuration(String duration) {
    return 'בעוד $duration';
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
  String get attendeeAccepted => 'אישרו';

  @override
  String get attendeeDeclined => 'סירבו';

  @override
  String get attendeeMaybe => 'אולי';

  @override
  String get attendeeNoReply => 'ללא מענה';

  @override
  String get organizer => 'מארגן';

  @override
  String get calendarNoAccounts =>
      'לא מחובר יומן לסביבת העבודה הזו. חברו יומן מאפליקציית שולחן העבודה — ההתחברות שומרת את הטוקן שלה בשרת.';

  @override
  String get calendarReauthNeeded =>
      'חשבון יומן דורש חיבור מחדש — מה שמוצג למטה עשוי להיות לא מעודכן. חברו אותו מחדש מאפליקציית שולחן העבודה.';

  @override
  String get spacesLoadFailed => 'לא ניתן לטעון את המרחבים';

  @override
  String get noSpaces => 'אין מרחבים';

  @override
  String get spacesEmptyDescription => 'מרחבים בסביבת העבודה הזו יופיעו כאן.';

  @override
  String get newSpaceFolder => 'תיקייה חדשה';

  @override
  String get folderName => 'שם התיקייה';

  @override
  String get renameSpaceFolder => 'שינוי שם התיקייה';

  @override
  String get deleteSpaceFolder => 'מחיקת התיקייה';

  @override
  String get moveSpaceToFolder => 'העברה לתיקייה';

  @override
  String get removeSpaceFromFolder => 'הסרה מהתיקייה';

  @override
  String get spaceFolderActions => 'פעולות התיקייה';

  @override
  String get deleteFolderWithSpacesWarning =>
      'מחיקה לצמיתות של מרחבים מסירה את ההודעות ועצי העבודה שלהם עבור כולם. אי אפשר לבטל פעולה זו.';

  @override
  String get deleteSpacesInFolder => 'מחיקת המרחבים שבתיקייה הזו לצמיתות';

  @override
  String get deleteFolderAndSpaces => 'מחיקת התיקייה והמרחבים';

  @override
  String get keepSpacesInFolder => 'אחרת, המרחבים יישארו מחוץ לתיקיות.';

  @override
  String get create => 'יצירה';

  @override
  String get otherSpaces => 'מרחבים אחרים';

  @override
  String get folderUpdateFailed => 'לא ניתן לעדכן את התיקיות';

  @override
  String get thread => 'שרשור';

  @override
  String get agentWorking => 'הסוכן עובד';

  @override
  String get messagesLoadFailed => 'לא ניתן לטעון את ההודעות';

  @override
  String get noMessagesYet => 'עדיין אין הודעות';

  @override
  String get noMessagesDescription => 'שלחו הודעה כדי להתחיל את השיחה.';

  @override
  String get agentResponding => 'הסוכן מגיב';

  @override
  String get agentFinished => 'הסוכן סיים';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      many: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      two: '⁨$names⁩ גדולים מדי לשליחה מכאן.',
      one: '⁨$names⁩ גדול מדי לשליחה מכאן.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      many: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      two: '⁨$names⁩ גדולים מדי לשליחה דרך הממסר מכאן.',
      one: '⁨$names⁩ גדול מדי לשליחה דרך הממסר מכאן.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'לא ניתן להעלות את הקובץ המצורף. נסו שוב.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים מצורפים לא הועלו ולא נכללו.',
      many: '$count קבצים מצורפים לא הועלו ולא נכללו.',
      two: 'שני קבצים מצורפים לא הועלו ולא נכללו.',
      one: 'קובץ מצורף אחד לא הועלה ולא נכלל.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'חבר צוות';

  @override
  String get agent => 'סוכן';

  @override
  String get attachFile => 'צירוף קובץ';

  @override
  String get messageHint => 'הודעה';

  @override
  String removeAttachment(String name) {
    return 'הסרת ⁨$name⁩';
  }

  @override
  String get articlesLoadFailed => 'לא ניתן לטעון כתבות';

  @override
  String get noArticles => 'אין כתבות';

  @override
  String get articlesEmptyDescription =>
      'כתבות חדשות יופיעו כאן כשהפידים יתעדכנו.';

  @override
  String get unread => 'לא נקראו';

  @override
  String get allFeeds => 'כל הפידים';

  @override
  String get save => 'שמירה';

  @override
  String get unsave => 'ביטול שמירה';

  @override
  String get readFullArticle => 'קריאת הכתבה המלאה';

  @override
  String get ticketsLoadFailed => 'לא ניתן לטעון כרטיסים';

  @override
  String get noTickets => 'אין כרטיסים';

  @override
  String get ticketsEmptyDescription => 'כרטיסים בסביבת העבודה הזו יופיעו כאן.';

  @override
  String get all => 'הכול';

  @override
  String get ticket => 'כרטיס';

  @override
  String get ticketLoadFailed => 'לא ניתן לטעון את הכרטיס';

  @override
  String assignedTo(String name) {
    return 'הוקצה ל-$name';
  }

  @override
  String get openInBrowser => 'פתיחה בדפדפן';

  @override
  String get status => 'סטטוס';

  @override
  String get assign => 'הקצאה';

  @override
  String get reassign => 'הקצאה מחדש';

  @override
  String get noAgents => 'אין סוכנים';

  @override
  String get noAgentsDescription => 'הקצו סוכן מסביבת העבודה הזו.';

  @override
  String get statusOpen => 'פתוח';

  @override
  String get statusInProgress => 'בתהליך';

  @override
  String get statusBlocked => 'חסום';

  @override
  String get statusInReview => 'בסקירה';

  @override
  String get statusDone => 'הושלם';

  @override
  String get statusBacklog => 'בקלוג';

  @override
  String get lensNeedsMe => 'ממתינים לי';

  @override
  String get lensMine => 'שלי';

  @override
  String get prsLoadFailed => 'לא ניתן לטעון בקשות משיכה';

  @override
  String get noOpenPullRequests => 'אין בקשות משיכה פתוחות';

  @override
  String get nothingWaitingOnReview => 'שום דבר לא ממתין לסקירה שלכם';

  @override
  String get noOwnOpenPullRequests => 'אין לכם בקשות משיכה פתוחות';

  @override
  String get nothingBlocked => 'שום דבר לא חסום';

  @override
  String get prsEmptyDescription =>
      'בקשות משיכה מהמאגרים של סביבת העבודה הזו יופיעו כאן.';

  @override
  String get refreshPullRequests => 'רענון בקשות משיכה';

  @override
  String get noForgeConnected =>
      'לא מחובר forge בשרת, ולכן לא ניתן להביא בקשות משיכה. חברו אחד מאפליקציית שולחן העבודה.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לא ניתן לקרוא $count מאגרים.',
      many: 'לא ניתן לקרוא $count מאגרים.',
      two: 'לא ניתן לקרוא שני מאגרים.',
      one: 'לא ניתן לקרוא מאגר אחד.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'לא ניתנים לקריאה: ⁨$names⁩';
  }

  @override
  String get installationSuspendedTitle => 'התקנת GitHub App הושעתה';

  @override
  String installationSuspendedBody(String names) {
    return 'מוצגים הנתונים האחרונים הידועים עבור ⁨$names⁩. חדש את ההתקנה ב-GitHub, או חבר אסימון עם גישה.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'התקנת GitHub App הושעתה. מוצגים הנתונים האחרונים הידועים עבור ⁨$names⁩. חדש את ההתקנה ב-GitHub, או חבר אסימון עם גישה.';
  }

  @override
  String get draft => 'טיוטה';

  @override
  String get merged => 'מוזג';

  @override
  String get closed => 'נסגר';

  @override
  String get open => 'פתוח';

  @override
  String get approved => 'אושר';

  @override
  String get changesRequested => 'התבקשו שינויים';

  @override
  String get reviewRequired => 'נדרשת סקירה';

  @override
  String get checksPassing => 'הבדיקות עוברות';

  @override
  String get checksFailing => 'הבדיקות נכשלות';

  @override
  String get checksRunning => 'הבדיקות פועלות';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'בקשת משיכה';

  @override
  String get prLoadFailed => 'לא ניתן לטעון את בקשת המשיכה הזו';

  @override
  String get openOnForge => 'פתיחה ב-forge';

  @override
  String get requestChangesNeedsComment =>
      'הוסיפו תגובה שמסבירה מה צריך לשנות.';

  @override
  String get conversation => 'שיחה';

  @override
  String get files => 'קבצים';

  @override
  String get checks => 'בדיקות';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קבצים',
      many: '$count קבצים',
      two: 'שני קבצים',
      one: 'קובץ אחד',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קומיטים',
      many: '$count קומיטים',
      two: 'שני קומיטים',
      one: 'קומיט אחד',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'קונפליקטים';

  @override
  String get reviewers => 'סוקרים';

  @override
  String get noDescriptionNoComments => 'עדיין אין תיאור ואין תגובות.';

  @override
  String get noChangedFiles => 'אין קבצים ששונו.';

  @override
  String get noChecksReported => 'לא דווחו בדיקות לקומיט העדכני.';

  @override
  String get reviewCommentHint => 'כתבו תגובת סקירה…';

  @override
  String get comment => 'תגובה';

  @override
  String get commentPosted => 'התגובה פורסמה';

  @override
  String get request => 'בקשת שינויים';

  @override
  String get squashAndMerge => 'Squash ומיזוג';

  @override
  String noActionsAvailable(String status) {
    return '$status — אין פעולות זמינות.';
  }

  @override
  String get reviewApproved => 'אישר';

  @override
  String get reviewRequestedChanges => 'ביקש שינויים';

  @override
  String get reviewCommented => 'הגיב';

  @override
  String get reviewPending => 'בהמתנה';

  @override
  String get unknownAuthor => 'לא ידוע';

  @override
  String hideDiffFor(String file) {
    return 'הסתרת ה-diff של ⁨$file⁩';
  }

  @override
  String showDiffFor(String file) {
    return 'הצגת ה-diff של ⁨$file⁩';
  }

  @override
  String get checkRunning => 'פועלת';

  @override
  String get checkPassed => 'עברה';

  @override
  String get checkFailed => 'נכשלה';

  @override
  String get checkCancelled => 'בוטלה';

  @override
  String get checkSkipped => 'דולגה';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '⁨$name⁩, $state';
  }

  @override
  String get noTextDiff =>
      'אין diff טקסטואלי לקובץ הזה — הוא בינארי, או גדול מכדי שה-forge יחזיר אותו.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הצגת $count השורות הנותרות',
      many: 'הצגת $count השורות הנותרות',
      two: 'הצגת שתי השורות הנותרות',
      one: 'הצגת השורה הנותרת',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שורות ללא שינוי',
      many: '$count שורות ללא שינוי',
      two: 'שתי שורות ללא שינוי',
      one: 'שורה אחת ללא שינוי',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'מעבר להודעה האחרונה';

  @override
  String get streaming => 'סטרימינג';

  @override
  String get working => 'עובד';

  @override
  String get input => 'קלט';

  @override
  String get output => 'פלט';

  @override
  String get now => 'עכשיו';

  @override
  String agoMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String agoHours(int count) {
    return '$count שע׳';
  }

  @override
  String agoDays(int count) {
    return '$count ימ׳';
  }

  @override
  String get today => 'היום';

  @override
  String get tomorrow => 'מחר';

  @override
  String get yesterday => 'אתמול';

  @override
  String durationMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String durationHours(int count) {
    return '$count שע׳';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours שע׳ $minutes דק׳';
  }

  @override
  String get mobileConversations => 'שיחות';

  @override
  String get mobileNewConversation => 'שיחה חדשה';

  @override
  String get mobileConversationName => 'שם השיחה';

  @override
  String get mobileRename => 'שינוי שם';

  @override
  String get mobileManageSpace => 'ניהול המרחב';

  @override
  String get mobileArchived => 'בארכיון';

  @override
  String get mobileSearchMessages => 'חיפוש בכל ההודעות במרחב הזה';

  @override
  String get mobileSearch => 'חיפוש';

  @override
  String get mobileNoResults => 'אין תוצאות';

  @override
  String get mobileReopen => 'פתח מחדש';

  @override
  String get mobileArchive => 'העברה לארכיון';

  @override
  String get mobileProgress => 'התקדמות והקשר';

  @override
  String get mobileReadFailed => 'לא ניתן לסמן את השיחה כנקראה';

  @override
  String get mobileSendFailed => 'ההודעה לא נשלחה. הטיוטה שלך נשמרה.';

  @override
  String get sentAttachmentUnavailable => 'הקובץ המצורף אינו זמין';

  @override
  String get sentAttachmentLoadFailed => 'לא ניתן לטעון את הקובץ המצורף';

  @override
  String get mobileActionFailed => 'הפעולה נכשלה';

  @override
  String get mobileRemove => 'הסר';

  @override
  String get mobileLinkedMessage => 'הודעה מקושרת';

  @override
  String get mobileOlderMessages => 'הודעות קודמות';

  @override
  String get mobileMessageActions => 'פעולות בהודעה';

  @override
  String get mobileOpenThread => 'פתיחת השרשור';

  @override
  String get mobileCopyLink => 'העתקת קישור';

  @override
  String get mobileStopRun => 'עצור הרצה';

  @override
  String get mobileStopRunConfirm =>
      'לעצור את הרצת הסוכן? העבודה שכבר הושלמה תישמר.';

  @override
  String get mobileControlUnsupported =>
      'ההרצה הסתיימה או אינה תומכת בפעולה הזאת.';

  @override
  String get mobilePauseRequested => 'התבקשה השהיה בסוף הסבב הבא';

  @override
  String get mobileResumed => 'ההרצה חודשה';

  @override
  String get mobileStopRequested => 'התבקשה עצירה';

  @override
  String get mobileQueuedMessages => 'הודעות בתור';

  @override
  String get mobilePauseRun => 'השהיה בסבב הבא';

  @override
  String get mobileResumeRun => 'המשך';

  @override
  String get mobileEditQueued => 'עריכת הודעה בתור';

  @override
  String get mobileSteerNow => 'הנחיה מיידית';

  @override
  String get mobileMoveUp => 'העברה למעלה';

  @override
  String get mobileMoveDown => 'העברה למטה';

  @override
  String get mobileQueueChanged =>
      'התור השתנה, או שההרצה אינה מקבלת הנחיות בזמן אמת. יש לרענן ולנסות שוב.';

  @override
  String get mobileActivity => 'פעילות';

  @override
  String get mobilePermissions => 'הרשאות וביקורת';

  @override
  String get mobilePlans => 'תוכניות';

  @override
  String get mobileGoals => 'יעדים מפוקחים';

  @override
  String get mobileCredentials => 'חיבורים ופרטי גישה';

  @override
  String get mobileWorkspaceUnavailable =>
      'סביבת העבודה אינה זמינה, או שכבר אין לך גישה אליה.';

  @override
  String get mobilePrReviewThreads => 'שרשורי סקירה';

  @override
  String get mobilePrThreadsLoadFailed => 'לא ניתן לטעון שרשורי סקירה';

  @override
  String get mobilePrNoReviewThreads => 'אין עדיין שרשורי סקירה בתוך הקוד';

  @override
  String get mobilePrCommentPermissionDenied => 'אין לך הרשאה להגיב במאגר הזה.';

  @override
  String get mobilePrPermissionChecking => 'בודק הרשאות לתגובות…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'לא ניתן לבדוק הרשאות לתגובות. יש לנסות שוב כדי להגיב.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, שורה $line';
  }

  @override
  String get mobilePrOriginalSide => 'מקורי';

  @override
  String get mobilePrSelectCommentLine => 'בחרו שורה להוספת תגובה';

  @override
  String get mobilePrUpdatedSide => 'עודכן';

  @override
  String get mobilePrThreadResolved => 'נפתר';

  @override
  String get mobilePrReplyHint => 'כתיבת תשובה…';

  @override
  String get mobilePrCommentRequired => 'יש לכתוב תגובה לפני הפרסום.';

  @override
  String get mobilePrReply => 'השבה';

  @override
  String get mobilePrReopenThread => 'פתיחת השרשור מחדש';

  @override
  String get mobilePrResolveThread => 'פתרון השרשור';

  @override
  String get mobilePrResolvePermissionDenied =>
      'רק מי שיצר את בקשת המשיכה או בעל הרשאת כתיבה יכולים לפתור את השרשור הזה.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'תגובה על $side, שורה $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'כתיבת תגובה בתוך הקוד…';

  @override
  String get mobilePrPostInlineComment => 'פרסום התגובה';

  @override
  String get mobilePrCommentUnavailable =>
      'תגובות בתוך הקוד אינן זמינות לבקשת המשיכה הזאת.';

  @override
  String get mobilePrPatchUnavailable =>
      'שירות המאגר לא סיפק תיקון טקסט לקובץ הזה.';

  @override
  String get mobilePrNoPatchForFile => 'התיקון לקובץ הזה אינו זמין.';

  @override
  String get mobileTicketNew => 'כרטיס חדש';

  @override
  String get mobileTicketCreate => 'יצירת כרטיס';

  @override
  String get mobileTicketEdit => 'עריכת כרטיס';

  @override
  String get mobileTicketTitle => 'כותרת';

  @override
  String get mobileTicketTitleRequired => 'יש להזין כותרת כדי לשמור את הכרטיס.';

  @override
  String get mobileTicketDescription => 'תיאור';

  @override
  String get mobileTicketMarkdownHint => 'הוספת פרטים ב-Markdown';

  @override
  String get mobileTicketPriority => 'עדיפות';

  @override
  String get mobileTicketPriorityNone => 'ללא עדיפות';

  @override
  String get mobileTicketPriorityUrgent => 'דחופה';

  @override
  String get mobileTicketPriorityHigh => 'גבוה';

  @override
  String get mobileTicketPriorityMedium => 'בינוני';

  @override
  String get mobileTicketPriorityLow => 'נמוך';

  @override
  String get mobileTicketLabels => 'תוויות';

  @override
  String get mobileTicketLabelsHint => 'תווית אחת בכל שורה';

  @override
  String get mobileTicketLabelsHelp => 'יש להזין כל תווית בשורה נפרדת.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'נפתח ב-$provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'ללא אחראי';

  @override
  String get mobileTicketAssignedFilter => 'הוקצו';

  @override
  String get mobileTicketAgentsLoadFailed => 'לא ניתן לטעון סוכנים';

  @override
  String get mobileTicketSearch => 'חיפוש כרטיסים';

  @override
  String get mobileTicketSearchHint => 'כותרת, מזהה, תיאור, תווית או אחראי';

  @override
  String get mobileTicketClearSearch => 'ניקוי החיפוש בכרטיסים';

  @override
  String get mobileTicketNoMatches => 'אין כרטיסים תואמים';

  @override
  String get mobileTicketAdjustFilters =>
      'אפשר לנסות חיפוש אחר או לשנות את המסננים.';

  @override
  String get mobileTicketClearFilters => 'נקה מסננים';

  @override
  String get mobileTicketNotFound => 'הכרטיס לא נמצא';

  @override
  String get mobileTicketNotFoundDescription =>
      'ייתכן שהכרטיס נמחק או הועבר מסביבת העבודה הזאת.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'סביבת העבודה השתנתה. יש לחזור לסביבת העבודה הנוכחית לפני השמירה.';

  @override
  String get mobileTicketOpenLinkedSpace => 'פתיחת המרחב המקושר';

  @override
  String get mobileTicketReadOnly =>
      'כדי לשנות כרטיסים נדרשת חברות בסביבת העבודה.';

  @override
  String get permissionTitle => 'הרשאות';

  @override
  String get permissionWorkspaceFailed => 'לא ניתן לטעון את סביבת העבודה';

  @override
  String get permissionNoWorkspace => 'יש לבחור סביבת עבודה כדי לבדוק הרשאות.';

  @override
  String get permissionLoading => 'טוען הרשאות…';

  @override
  String get permissionScopeDescription =>
      'כאן אפשר לראות כיצד מתקבלת החלטה לגבי כל פעולה בטווח הזה. סוכנים ומרחבים יכולים לרשת כללים מסביבת העבודה.';

  @override
  String get permissionScope => 'טווח המדיניות';

  @override
  String get permissionWorkspaceScope => 'סביבת עבודה';

  @override
  String get permissionAgentScope => 'סוכן';

  @override
  String get permissionSpaceScope => 'מרחב';

  @override
  String get permissionAgentContext => 'סוכן הפועל במרחב הזה';

  @override
  String get permissionNoAgentContext => 'לא נבחר סוכן';

  @override
  String get permissionTargetsFailed => 'לא ניתן לטעון יעדים בטווח הזה';

  @override
  String get permissionNoTargets => 'אין יעדים זמינים בטווח הזה.';

  @override
  String get permissionRoleFailed => 'לא ניתן לאמת את התפקיד שלך בסביבת העבודה';

  @override
  String get permissionMemberRequired =>
      'כדי להציג כללי מדיניות נדרשת חברות בסביבת העבודה.';

  @override
  String get permissionRulesFailed => 'לא ניתן לטעון כללי מדיניות';

  @override
  String get permissionAuditAdminOnly =>
      'היסטוריית ההרשאות זמינה למנהלי סביבת העבודה בלבד.';

  @override
  String get permissionAllow => 'אפשר';

  @override
  String get permissionAsk => 'שאל קודם';

  @override
  String get permissionDeny => 'חסום';

  @override
  String get permissionFileDelete => 'מחיקת קבצים';

  @override
  String get permissionFileWriteOutsideWorktree => 'כתיבה מחוץ לעץ העבודה';

  @override
  String get permissionGitCommit => 'ביצוע commit לשינויים';

  @override
  String get permissionGitPush => 'דחיפת commits';

  @override
  String get permissionPrCreate => 'יצירת בקשות משיכה';

  @override
  String get permissionPrPublish => 'פרסום בקשות משיכה';

  @override
  String get permissionVendorSyncWrite => 'כתיבה בסנכרון עם ספק';

  @override
  String get permissionNetworkEgress => 'גישה לרשת';

  @override
  String get permissionSecretAccess => 'גישה לסודות';

  @override
  String get permissionPackageInstall => 'התקנת חבילות';

  @override
  String get permissionProcessSpawn => 'הפעלת תהליכים';

  @override
  String get permissionWorkspaceMutation => 'שינוי סביבת העבודה';

  @override
  String get permissionEnclosureControl => 'שליטה במתחם';

  @override
  String get permissionChangeFailed => 'לא ניתן לשנות את הכלל';

  @override
  String get permissionEffectiveDescription =>
      'ההחלטה החלה בטווח הזה ללא ארגומנטים של פעולה. ההרשאות המותנות שלהלן חלות רק על בקשות תואמות; השרת מקבל את ההחלטה הסופית.';

  @override
  String get permissionSpaceAgentNote =>
      'לא נבחר סוכן. כללים ייחודיים לסוכן יוצגו לאחר בחירת סוכן למעלה.';

  @override
  String get permissionScopedGrants => 'כללים בטווח הזה';

  @override
  String get permissionModePreset => 'ערכת מצב';

  @override
  String get permissionBuiltInDefault => 'ברירת מחדל מובנית';

  @override
  String get permissionRemembered => 'אישור שמור';

  @override
  String get permissionSource => 'מקור';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · הוגדר כאן';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · התקבל בירושה';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'תוקף עד $date';
  }

  @override
  String get permissionSetHere => 'הגדרת כלל כאן';

  @override
  String get permissionRevokeBeforeEdit =>
      'יש לבטל את הכלל בטווח הזה או את האישור השמור לפני הגדרת כלל כללי לפעולה הזאת.';

  @override
  String get permissionConfirmRevoke => 'אישור ביטול';

  @override
  String get permissionRevokeRule => 'ביטול הכלל';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'קידומת פקודה: $prefix';
  }

  @override
  String get permissionNoExpiry => 'ללא תאריך תפוגה';

  @override
  String get permissionExpired => 'פג תוקפה';

  @override
  String get permissionExplicitRule => 'כלל מפורש';

  @override
  String get permissionEnforcementAdvisory =>
      'מצב מייעץ: כללי ״שאל קודם״ נרשמים ללא בקשת אישור';

  @override
  String get permissionEnforcementSoft => 'אכיפה גמישה: עקיפה דורשת הרשאה';

  @override
  String get permissionEnforcementHard => 'אכיפה קשיחה: אי אפשר לעקוף';

  @override
  String permissionPaths(String paths) {
    return 'נתיבים: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'הפניות Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'מארחים: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'פקודות: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'מספר מרבי: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'מספר מרבי של סנטים: $cents';
  }

  @override
  String get permissionAuditHeading => 'היסטוריית הרשאות';

  @override
  String get permissionAuditDescription =>
      'החלטות אחרונות שנרשמו בשרת. רק מנהלים יכולים לעיין ביומן או לאמת את שרשרת הגיבובים שלו.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'בשם $user';
  }

  @override
  String get permissionPrompted => 'התבקש אישור מאדם';

  @override
  String get permissionVerifyChain => 'אימות שרשרת הביקורת';

  @override
  String get permissionVerifyFailed => 'לא ניתן לאמת את שרשרת הביקורת';

  @override
  String permissionChainIntact(String count) {
    return 'השרשרת תקינה · נבדקו $count רשומות';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'השרשרת נקטעה ברשומה $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'טרם נרשמו החלטות הרשאה.';

  @override
  String get permissionAuditFailed => 'לא ניתן לטעון את היסטוריית ההרשאות';

  @override
  String get mobilePlansLoadFailed => 'לא ניתן לטעון תוכניות';

  @override
  String get mobilePlansEmpty => 'אין עדיין תוכניות';

  @override
  String get mobilePlansEmptyDescription =>
      'תוכניות שיגישו סוכנים יופיעו כאן לסקירה.';

  @override
  String get mobilePlanTitle => 'תכנון';

  @override
  String get mobilePlanMissing =>
      'התוכנית הזאת כבר אינה זמינה בסביבת העבודה הזאת.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count שלבים';
  }

  @override
  String get mobilePlanDraft => 'טיוטה';

  @override
  String get mobilePlanProposed => 'ממתינה לסקירה';

  @override
  String get mobilePlanApproved => 'אושרה';

  @override
  String get mobilePlanRejected => 'נדחה';

  @override
  String get mobilePlanSuperseded => 'הוחלפה';

  @override
  String get mobilePlanExecuting => 'מבצע';

  @override
  String get mobilePlanSynthesizing => 'מסנתז';

  @override
  String get mobilePlanCompleted => 'הושלם';

  @override
  String get mobilePlanFailed => 'נכשלה';

  @override
  String get mobilePlanCancelled => 'בוטל';

  @override
  String mobilePlanRevision(String revision) {
    return 'גרסה $revision';
  }

  @override
  String get mobilePlanSteps => 'שלבים';

  @override
  String get mobilePlanNoSteps => 'לא הוגשו שלבים לתוכנית הזאת.';

  @override
  String get mobilePlanAssumptions => 'הבהרות';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'תלוי ב-$keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'עלות מוערכת עד $cost';
  }

  @override
  String get mobilePlanSelect => 'בחר';

  @override
  String get mobilePlanSelected => 'נבחר';

  @override
  String get mobilePlanEstimate => 'הערכת עלות';

  @override
  String get mobilePlanEstimateRequired =>
      'יש להעריך את התוכנית לפני אישור הביצוע.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'עלות מוערכת: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'לא זמין';

  @override
  String get mobilePlanNoHardCap => 'ללא תקרה קשיחה';

  @override
  String get mobilePlanExceedsBudget =>
      'ההערכה חורגת מהתקציב שהוגדר. יש לבדוק אותה לפני האישור.';

  @override
  String get mobilePlanPartialEstimate =>
      'ההערכה הזאת כוללת את כל התוכנית; השלבים שנבחרו עשויים לעלות פחות.';

  @override
  String get mobilePlanConfirmAll => 'להתחיל את כל התוכנית?';

  @override
  String get mobilePlanConfirmSelected => 'להתחיל את השלבים שנבחרו?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'האישור מתחיל את הביצוע ועלול לגרור חיובים. עלות מרבית מוערכת: $cost. תקרת תקציב: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'אישור הכול והפעלה';

  @override
  String get mobilePlanApproveSelected => 'אישור השלבים שנבחרו והפעלה';

  @override
  String get mobilePlanWiden => 'אישור שלבים נוספים';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'לאשר ביצוע של עוד $count שלבים? הם עשויים לגרור חיובים. תקרת העלות הקיימת לביצוע: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'התוכנית השתנתה במהלך הסקירה. יש לפתוח את הגרסה האחרונה ולהעריך אותה מחדש.';

  @override
  String get mobilePlanReject => 'דחיית התוכנית';

  @override
  String get mobilePlanRejectConfirm => 'לדחות את התוכנית? היא לא תבוצע.';

  @override
  String get mobilePlanStop => 'עצירת הביצוע';

  @override
  String get mobilePlanStopConfirm =>
      'לעצור את ביצוע התוכנית? העבודה שכבר הושלמה לא תבוטל.';

  @override
  String mobilePlanRunId(String runId) {
    return 'הרצת ביצוע: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'האישור התקבל. ממתינים לרישום הביצוע…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'הושלמו $completed מתוך $total שלבי ביצוע';
  }

  @override
  String get mobilePlanOpenConversation => 'פתיחת השיחה';

  @override
  String get mobileGoalsTitle => 'יעדים מפוקחים';

  @override
  String get mobileGoalsLoadFailed => 'לא ניתן לטעון יעדים מפוקחים';

  @override
  String get mobileGoalsEmpty => 'אין עדיין יעדים מפוקחים';

  @override
  String get mobileGoalsEmptyDescription =>
      'אפשר להתחיל יעד במרחב או לשלוח /goal בשיחה.';

  @override
  String get mobileGoalMissing => 'היעד הזה כבר אינו זמין בסביבת העבודה הזאת.';

  @override
  String get mobileGoalActive => 'פעיל';

  @override
  String get mobileGoalPaused => 'מושהה';

  @override
  String get mobileGoalCompleted => 'הושלם';

  @override
  String get mobileGoalFailed => 'נכשלה';

  @override
  String get mobileGoalCancelled => 'בוטל';

  @override
  String get mobileGoalBudgetExhausted => 'התקציב מוצה';

  @override
  String get mobileGoalGoal => 'מטרה';

  @override
  String get mobileGoalLoop => 'לולאה';

  @override
  String mobileGoalKind(String kind) {
    return 'סוג: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count הרצות';
  }

  @override
  String get mobileGoalNoRunLimit => 'ללא הגבלה';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'הרצות: $runs / $maxRuns · הוצאה: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'תאריך יעד: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'הרצות רצופות שנכשלו: $count';
  }

  @override
  String get mobileGoalSummary => 'סיכום השלמה';

  @override
  String get mobileGoalFailedDescription =>
      'המפקח עצר לאחר כישלונות חוזרים בהרצות. יש לעיין בשיחה לפרטים.';

  @override
  String get mobileGoalBudgetWall =>
      'תאריך היעד או מגבלת ההרצות הושגו. הגדלת תקרת העלות לא תאפשר לחדש את היעד הזה.';

  @override
  String get mobileGoalPause => 'השהיית היעד';

  @override
  String get mobileGoalResume => 'חידוש היעד';

  @override
  String get mobileGoalStop => 'ביטול היעד';

  @override
  String get mobileGoalStopConfirm =>
      'לבטל לצמיתות את היעד המפוקח? לא ניתן יהיה לחדש אותו.';

  @override
  String get mobileGoalRaiseBudget => 'הגדלת התקציב וחידוש';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'הגדלת התקציב ל-$amount וחידוש';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'להגדיל את תקרת העלות של היעד מ-$oldCap ל-$newCap ולחדש את ההוצאות?';
  }

  @override
  String get mobileGoalOpenConversation => 'פתיחת שיחת היעד';

  @override
  String get mobileGoalCreate => 'התחלת יעד מפוקח';

  @override
  String get mobileGoalChooseSpace => 'הרצה במרחב';

  @override
  String get mobileGoalNoSpaces => 'יש ליצור מרחב לפני שמתחילים יעד.';

  @override
  String get mobileGoalChooseAgent => 'הרצה עם סוכן';

  @override
  String get mobileGoalNoAgents => 'יש להוסיף סוכן פעיל לפני שמתחילים יעד.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'נבחר $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'איזו תוצאה הסוכן צריך להשיג?';

  @override
  String get mobileGoalBudgetUsd => 'תקרת עלות (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'יש לבחור מרחב וסוכן, להזין יעד ולהגדיר תקרת עלות חיובית בדולרים.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'להתחיל יעד מפוקח בעלות מרבית של $cap? הסוכן עשוי להתחיל מיד.';
  }

  @override
  String get mobileGoalUnavailable =>
      'החיבור לשרת עדיין לא מוכן. יש לנסות שוב לאחר החיבור מחדש.';

  @override
  String get mobileGoalConversationMissing =>
      'השיחה שנבחרה כבר אינה זמינה בסביבת העבודה הזאת.';

  @override
  String get mobileGoalCreateSent =>
      'היעד התחיל. מצב הפיקוח יופיע ברשימה הזאת.';

  @override
  String get mobileGoalStartRefused =>
      'לא החלה הרצת יעד. אפשר לעיין בשיחה כדי להבין את סיבת הסירוב של המפקח.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'נבחר $name';
  }

  @override
  String get requestUnavailable =>
      'הבקשה הזאת כבר אינה זמינה בסביבת העבודה הפעילה.';

  @override
  String get requestAlreadyResolved => 'הבקשה הזאת כבר טופלה.';

  @override
  String get inboxCredentialsBlocked => 'פרטי גישה חוסמים הרצות';

  @override
  String get inboxSyncFailures => 'סנכרונים שנכשלו מול ספקים';

  @override
  String get inboxConfigureCredentials => 'הגדרת פרטי גישה';

  @override
  String get openTicket => 'פתיחת הכרטיס';

  @override
  String get activityTitle => 'פעילות';

  @override
  String get activityClearAll => 'ניקוי הפעילות';

  @override
  String get activityClearConfirm =>
      'הפעולה תסתיר את כל הפעילות שנרשמה עבורך עד כה בכל המכשירים. פעילות חדשה עדיין תופיע.';

  @override
  String get activityMarkAllRead => 'סימון הכול כנקרא';

  @override
  String get activityMarkAllConfirm =>
      'לסמן את כל פריטי הפעילות בסביבת העבודה הזאת כנקראו בכל המכשירים שלך?';

  @override
  String get activityMarkRead => 'סימון כנקרא';

  @override
  String get activityMarkUnread => 'סימון כלא נקרא';

  @override
  String get activityDismiss => 'סגירה';

  @override
  String get activityResolved => 'נפתר';

  @override
  String get activityOpen => 'פתוחה';

  @override
  String get activityEmpty => 'אין פעילות עדיין';

  @override
  String get activityLoadFailed => 'לא ניתן לטעון את הפעילות';

  @override
  String get activityAgentWaiting => 'הסוכן ממתין לתגובה';

  @override
  String get activityAgentBlocked => 'פעולת הסוכן נחסמה';

  @override
  String get activityMessage => 'הודעה חדשה';

  @override
  String get activityPullRequest => 'עדכון בבקשת משיכה';

  @override
  String get activityTicket => 'עדכון בכרטיס';

  @override
  String get activityMeeting => 'עדכון בפגישה';

  @override
  String get activityCalendar => 'חיבור ללוח השנה';

  @override
  String get activityRig => 'עדכון במתחם';

  @override
  String get activityEvent => 'עדכן';

  @override
  String get activityPrReady => 'בקשת המשיכה מוכנה למיזוג';

  @override
  String get activityPrBlocked => 'מיזוג בקשת המשיכה נחסם';

  @override
  String get activityPrApproved => 'בקשת המשיכה אושרה';

  @override
  String get activityPrChanges => 'התבקשו שינויים';

  @override
  String get activityPrChecksFailed => 'בדיקות בקשת המשיכה נכשלו';

  @override
  String get activityPrChecksRecovered => 'בדיקות בקשת המשיכה חזרו לפעול';

  @override
  String get activityPrComment => 'תגובה לבקשת משיכה';

  @override
  String get activityPrPublished => 'בקשת המשיכה פורסמה';

  @override
  String get activityPrMerged => 'בקשת המשיכה מוזגה';

  @override
  String get activityPrMentioned => 'אוזכרת בבקשת משיכה';

  @override
  String get activityPrReviewRequested => 'התבקשה סקירה';

  @override
  String get activityPrReviewStale => 'צריך לרענן את הסקירה';

  @override
  String get activityTicketAssigned => 'כרטיס הוקצה';

  @override
  String get activityTicketChanged => 'סטטוס הכרטיס השתנה';

  @override
  String get activityMeetingSoon => 'פגישה מתחילה בקרוב';

  @override
  String get activityCalendarExpired => 'פג תוקף החיבור ללוח השנה';

  @override
  String get activityRigControl => 'השליטה במתחם השתנתה';

  @override
  String get activityRigClosed => 'המתחם נעצר';

  @override
  String get mobileSpacesSearch => 'חיפוש מרחבים';

  @override
  String get mobileSpacesArchived => 'בארכיון';

  @override
  String get mobileSpacesActive => 'פעיל';

  @override
  String get mobileSpacesNew => 'מרחב חדש';

  @override
  String get mobileSpacesManage => 'ניהול המרחב';

  @override
  String get mobileSpacesName => 'שם המרחב';

  @override
  String get mobileSpacesAgents => 'סוכנים';

  @override
  String get mobileSpacesMembers => 'אנשים';

  @override
  String get mobileSpacesRepos => 'מאגרים';

  @override
  String get mobileSpacesAllRepos => 'כל המאגרים המקושרים';

  @override
  String get mobileSpacesNoRepos => 'אין מאגרים';

  @override
  String get mobileSpacesBaseBranch => 'ענף בסיס (אופציונלי)';

  @override
  String get mobileSpacesDefaultBranch => 'ענף ברירת מחדל';

  @override
  String get mobileSpacesMode => 'מצב';

  @override
  String get mobileSpacesModeChat => 'צ\'אט';

  @override
  String get mobileSpacesModeReview => 'סקירה (לקריאה בלבד)';

  @override
  String get mobileSpacesModePlan => 'תכנון (לקריאה בלבד)';

  @override
  String get mobileSpacesModeOrchestrate => 'תזמור';

  @override
  String get mobileSpacesAutonomy => 'דריסת רמת העצמאות';

  @override
  String get mobileSpacesAutonomyInherited => 'בירושה';

  @override
  String get mobileSpacesAutonomyPropose => 'הצעות בלבד';

  @override
  String get mobileSpacesAutonomyApproval => 'פעולה באישור';

  @override
  String get mobileSpacesAutonomyFreely => 'פעולה חופשית';

  @override
  String get mobileSpacesAutonomyNotice =>
      'דריסה אינה יכולה לעקוף בקשות אישור או סירובים של מדיניות הפעולות. רק מנהלי סביבת העבודה יכולים לשנות אותה.';

  @override
  String get mobileSpacesArchive => 'העברת המרחב לארכיון';

  @override
  String get mobileSpacesReopen => 'פתיחת המרחב מחדש';

  @override
  String get mobileSpacesSave => 'שמור שינויים';

  @override
  String get mobileSpacesCreate => 'יצירת מרחב';

  @override
  String get mobileSpacesOperationFailed => 'לא ניתן לעדכן את המרחב';

  @override
  String get mobileSpacesMissing => 'המרחב לא נמצא בסביבת העבודה הזאת';

  @override
  String get mobileSpacesEmptyName => 'יש להזין שם למרחב';

  @override
  String get mobileSpacesNoMatches => 'אין מרחבים תואמים';

  @override
  String get mobileSpacesUnread => 'תשובת סוכן שלא נקראה';

  @override
  String get mobileSpacesNeedsInput => 'נדרשת תגובתך';

  @override
  String get mobileSpacesRunning => 'סוכן פועל';

  @override
  String get mobileSpacesNoAgents => 'אין סוכנים בסביבת העבודה הזאת';

  @override
  String get mobileSpacesNoMembers => 'אין חברים נוספים בסביבת העבודה';

  @override
  String get mobileSpacesRepoError => 'לא ניתן לטעון מאגרים';

  @override
  String get mobileSpacesRetry => 'נסה שוב';

  @override
  String get mobileSpacesBranchUnavailable =>
      'יש לבחור או להזין ענף בסיס כשיוצרים מרחב; אי אפשר לשנות ענף בסיס של מרחב קיים.';

  @override
  String get mobileSpacesArchivedEmpty => 'אין מרחבים בארכיון';

  @override
  String get mobileSpacesAllRepoWarning =>
      'מאגרים שיקושרו לסביבת העבודה בעתיד ייכללו גם במרחב הזה.';

  @override
  String get mobileSpacesCreatedRetry =>
      'המרחב נוצר. אפשר לנסות שוב להוסיף אנשים או לפתוח את דף הניהול שלו.';

  @override
  String get progressTitle => 'התקדמות';

  @override
  String get progressConversation => 'שיחה';

  @override
  String get progressLoadFailed => 'לא ניתן לטעון את ההתקדמות';

  @override
  String get progressUnavailable => 'השיחה אינה זמינה';

  @override
  String get progressUnavailableDescription =>
      'השיחה הזאת אינה בסביבת העבודה ובמרחב הפעילים. יש לחזור למרחב שלה כדי להמשיך.';

  @override
  String get progressSaveFailed => 'לא ניתן לעדכן את ההתקדמות';

  @override
  String get progressGoal => 'מטרה';

  @override
  String get progressNoGoal => 'לא הוגדר יעד עבודה';

  @override
  String get progressSetGoal => 'הגדרת יעד';

  @override
  String get progressEditGoal => 'עריכת היעד';

  @override
  String get progressClearGoal => 'ניקוי היעד';

  @override
  String get progressGoalRequired => 'יש להזין יעד לפני השמירה.';

  @override
  String get progressTodos => 'משימות';

  @override
  String get transcriptToolTodos => 'משימות';

  @override
  String get transcriptToolSearchMemory => 'חיפוש בזיכרון';

  @override
  String get transcriptToolRenderMedia => 'הצגת מדיה';

  @override
  String get progressNoTodos => 'אין עדיין משימות';

  @override
  String get progressNewTodo => 'משימה חדשה';

  @override
  String get progressAddTodo => 'הוספת משימה';

  @override
  String get progressEditTodo => 'עריכת משימה';

  @override
  String get progressTodoRequired => 'יש להזין משימה לפני השמירה.';

  @override
  String get progressTodoNoLongerExists =>
      'המשימה הוסרה. יש לטעון מחדש את הרשימה ולנסות שוב.';

  @override
  String get progressWorkspaceChanged =>
      'סביבת העבודה הפעילה השתנתה. יש לחזור לשיחה הזאת ולנסות שוב.';

  @override
  String progressRemoveTodo(String name) {
    return 'הסרת המשימה $name';
  }

  @override
  String get progressPending => 'ממתין';

  @override
  String get progressInProgress => 'בתהליך';

  @override
  String get progressCompleted => 'הושלם';

  @override
  String get progressMoveUp => 'העברת המשימה למעלה';

  @override
  String get progressMoveDown => 'העברת המשימה למטה';

  @override
  String get progressRunTree => 'הרצות סוכנים';

  @override
  String get progressNoRuns => 'אין עדיין הרצות בשיחה הזאת';

  @override
  String get progressRunning => 'פועל';

  @override
  String get progressFailed => 'נכשלה';

  @override
  String get progressUnknown => 'לא ידוע';

  @override
  String get progressHealthy => 'פעיל';

  @override
  String get progressBlocked => 'חסום';

  @override
  String get progressLooping => 'בלולאה';

  @override
  String get progressStalled => 'תקוע';

  @override
  String get progressDead => 'נעצר באופן בלתי צפוי';

  @override
  String get progressQuiet => 'אין עדיין פלט';

  @override
  String get progressCostReported => 'חיוב שדיווח הספק';

  @override
  String get progressCostNotional => 'מחיר מחירון משוער למינוי; אינו חשבונית';

  @override
  String get progressCostMixed => 'מקורות עלות מעורבים';

  @override
  String get progressCostEstimated => 'עלות מוערכת';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds שנ׳';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'מודל: $model · משך: $duration · עלות: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'התחיל $time';
  }

  @override
  String progressLiveness(String state) {
    return 'מצב: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'קלט: $input · פלט: $output טוקנים';
  }

  @override
  String get progressOutputPreviewLimited =>
      'מוצגים רק 6,000 התווים הראשונים של הפלט המובנה.';

  @override
  String progressRetryOf(String runId) {
    return 'ניסיון חוזר של הרצה $runId';
  }

  @override
  String get progressContext => 'הקשר ומגבלות';

  @override
  String get progressNoAgent => 'אין סוכן לבדיקה';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window טוקנים';
  }

  @override
  String get progressMeasured => 'הקשר שדווח בידי הספק בקריאה האחרונה';

  @override
  String get progressEstimated => 'הערכה מתוך השיחה השמורה וההקשר הקבוע';

  @override
  String get progressContextUnknown => 'עדיין לא דווח על שימוש בהקשר';

  @override
  String progressContextPercent(String percent) {
    return '$percent% מחלון ההקשר';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'מגבלה חודשית מוגדרת לסוכן: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'שיחה פעילה שמורה: כ-$tokens טוקנים';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'הקשר קבוע עבור $agent · $model';
  }

  @override
  String get progressContextSystem => 'הנחיית מערכת';

  @override
  String get progressContextRules => 'כללים';

  @override
  String get progressContextSkills => 'מיומנויות';

  @override
  String get progressContextTools => 'הגדרות כלים';

  @override
  String get progressContextMcp => 'כלי MCP';

  @override
  String get progressContextDeferred => 'כלים מושהים';

  @override
  String get progressContextSubagents => 'תתי-סוכנים';

  @override
  String get progressContextRunner => 'מריץ חיצוני';

  @override
  String get progressContextMemory => 'זיכרון';

  @override
  String get progressContextHistory => 'היסטוריית השיחה';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens טוקנים';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens טוקנים';
  }

  @override
  String get progressOutputs => 'פלטים אחרונים';

  @override
  String get progressNoOutputs => 'אין פלטים אחרונים של סוכנים';

  @override
  String get progressStructuredOutputsAbove =>
      'הפלטים המובנים של ההרצות מוצגים למעלה.';

  @override
  String get progressRecentOutputsOnly =>
      'מוצגות הודעות אחרונות בלבד. יש לפתוח את השיחה כדי לראות עבודה קודמת.';

  @override
  String get progressPlan => 'תכנון';

  @override
  String get progressArtifact => 'תוצר';

  @override
  String get progressResult => 'תוצאה';

  @override
  String get progressHideArtifact => 'הסתרת התוצר';

  @override
  String get progressReadArtifact => 'קריאת התוצר';

  @override
  String get progressArtifactUnavailable => 'התוצר כבר אינו זמין';

  @override
  String get progressArtifactPreviewLimited =>
      'מוצגת תצוגה מקדימה מוגבלת של התוצר.';

  @override
  String get progressDiagramSource => 'מקור התרשים';

  @override
  String progressOpenAttachment(String name) {
    return 'פתיחת $name';
  }

  @override
  String get progressOpenPlan => 'פתיחת התוכנית';

  @override
  String progressOpenDiff(String label) {
    return 'סקירת קבצים ששונו: $label';
  }

  @override
  String get progressViewMessage => 'הצגת ההודעה';

  @override
  String get pushTitle => 'התראות ברקע';

  @override
  String get pushIntro =>
      'אפשר לקבל התראה פרטית כשמשהו דורש את תשומת לבך, גם כשהאפליקציה סגורה. הפרטים נשארים בחיבור המוצפן שלך.';

  @override
  String get pushLoading => 'בודק הגדרות התראות…';

  @override
  String get pushError =>
      'לא ניתן לעדכן את ההתראות. יש לבדוק את החיבור ולנסות שוב.';

  @override
  String get pushEnable => 'הפעלת התראות';

  @override
  String get pushDisable => 'כיבוי ההתראות';

  @override
  String get pushQuiet => 'השהיית ההתראות במכשיר הזה';

  @override
  String get pushCategories => 'לקבל התראות על';

  @override
  String get pushCategoryAgents => 'סוכנים';

  @override
  String get pushCategoryMessages => 'הודעות';

  @override
  String get pushCategoryPullRequests => 'בקשות משיכה';

  @override
  String get pushCategoryTickets => 'כרטיסים';

  @override
  String get pushCategoryCalendar => 'לוח שנה';

  @override
  String get pushCategoryMachines => 'מכונות';

  @override
  String get pushSecureOrigin => 'התראות מחייבות HTTPS.';

  @override
  String get pushInstallIos =>
      'ב-iPhone או ב-iPad יש להוסיף את האפליקציה למסך הבית ולפתוח אותה משם כדי להפעיל התראות.';

  @override
  String get pushUnsupported => 'הדפדפן הזה אינו תומך בהתראות ברקע.';

  @override
  String get pushDenied =>
      'הדפדפן מדווח שההתראות חסומות. יש לבדוק את ההרשאה לאתר הזה ואת הגדרות ההתראות בדפדפן או במכשיר, ואז לרענן.';

  @override
  String get pushOsHint =>
      'הדפדפן צריך גם הרשאה להציג התראות בהגדרות המערכת של המכשיר.';

  @override
  String get pushServiceUnavailable =>
      'שירות ה-push של הדפדפן דחה את המינוי. דפדפנים מסוימים, כמו Brave, מכבים אותו כברירת מחדל: חפשו אפשרות להודעות push בהגדרות הפרטיות של הדפדפן ונסו שוב.';

  @override
  String get pushWorkerUnavailable =>
      'לא ניתן היה להפעיל את שירות ההתראות בדפדפן הזה. טענו מחדש את הדף ונסו שוב.';

  @override
  String get pushResubscribe => 'חיבור מחדש להתראות';

  @override
  String get pushStatusEnabled => 'ההתראות פועלות במכשיר הזה.';

  @override
  String get pushStatusDisabled => 'ההתראות כבויות במכשיר הזה.';

  @override
  String get credentialsTitle => 'חיבורים ופרטי גישה';

  @override
  String get credentialsIntro =>
      'יש לחבר את החשבונות שבהם משתמשים ההרצות והשילובים שלך. פרטי גישה סודיים נשמרים בשרת שלך, לא בטלפון הזה.';

  @override
  String get credentialsModelProviders => 'ספקי מודלים';

  @override
  String get credentialsOwnerOnly =>
      'רק הבעלים של השרת יכולים להוסיף, לחבר או להסיר פרטי גישה לספקי מודלים. המפתחות האלה משותפים לכל סביבות העבודה.';

  @override
  String get credentialsContactOwner =>
      'יש לבקש מהבעלים של השרת לחבר את הספק שנדרש להרצה החסומה שלך.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'ההתחברות ל-Claude Code מתבצעת דרך ממשק שורת הפקודה במחשב המארח. יש לבקש מהבעלים של השרת להשלים או לחדש את ההתחברות לחשבון במסוף של המארח; אי אפשר לעשות זאת בטלפון הזה.';

  @override
  String get credentialsYourForgeAccounts => 'חשבונות שירותי המאגרים שלך';

  @override
  String get credentialsYourTicketingAccount => 'חשבון ניהול הכרטיסים שלך';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'כרטיסים מקומיים אינם דורשים התחברות. אם סביבת העבודה שלך משתמשת ב-Linear, אפשר לחבר אותו כאן.';

  @override
  String get credentialsMembershipRequired =>
      'יש להצטרף לסביבת עבודה כדי לנהל את פרטי הגישה שלך לשירותי מאגרים או לניהול כרטיסים. יש לבקש גישה ממנהל סביבת העבודה.';

  @override
  String get credentialsSwitchWorkspace =>
      'הקישור הזה מפנה לסביבת עבודה אחרת. יש לעבור אליה לפני שמשנים פרטי גישה.';

  @override
  String get credentialsReturnToInbox =>
      'אחרי חיבור פרטי הגישה, אפשר לחזור לתיבת הדואר הנכנס ולנסות שוב להריץ את הפעולה שנחסמה. המארח בודק גם הרצות מושהות באופן אוטומטי.';

  @override
  String get credentialsLoadFailed =>
      'לא ניתן לטעון חיבורים. יש לבדוק את החיבור לשרת ולנסות שוב.';

  @override
  String get credentialsOperationFailed =>
      'לא ניתן לשנות את החיבור הזה. יש לבדוק את החיבור לשרת, את הגישה שלך ואת פרטי הגישה, ולנסות שוב.';

  @override
  String get credentialsConnected => 'מחובר';

  @override
  String get credentialsNotConnected => 'לא מחובר';

  @override
  String credentialsSignedInAs(String username) {
    return 'מחובר בתור $username';
  }

  @override
  String get credentialsAccount => 'חשבון מחובר';

  @override
  String get credentialsStoredKey => 'מפתח שמור';

  @override
  String get credentialsActive => 'פעיל';

  @override
  String get credentialsRemove => 'הסר';

  @override
  String get credentialsRemoveConfirm =>
      'להסיר את פרטי הגישה השמורים שלך? ייתכן שיהיה צורך להתחבר שוב.';

  @override
  String get credentialsApiKey => 'מפתח API';

  @override
  String get credentialsApiKeyHint => 'יש להדביק מפתח API של הספק';

  @override
  String get credentialsBrowserLogin => 'התחברות דרך הדפדפן';

  @override
  String get credentialsSignInAgain => 'יש להתחבר שוב';

  @override
  String get credentialsWaitingForLogin => 'ממתינים לאישור בדפדפן שלך…';

  @override
  String get credentialsLoginTimedOut =>
      'תוקף ההתחברות פג. יש להתחיל ניסיון התחברות חדש.';

  @override
  String get credentialsCopyCode => 'העתקת הקוד';

  @override
  String get credentialsDeviceCodeHint =>
      'יש לאשר את הקוד הזה בדף של הספק. חשוב להשאיר את המסך פתוח בזמן שהשרת משלים את ההתחברות.';

  @override
  String get credentialsPasteRedirect => 'קוד הרשאה או כתובת URL להפניה מחדש';

  @override
  String get credentialsPasteRedirectHint =>
      'יש להדביק את הקוד או את כתובת ה-URL המלאה להפניה מחדש מהספק';

  @override
  String get credentialsCompleteLogin => 'השלמת ההתחברות';

  @override
  String get credentialsRedirectUnavailable =>
      'לא ניתן להגיע בצורה מאובטחת מטלפון לכתובת החזרה מהדפדפן של השרת הזה. יש לבקש מהבעלים של השרת להגדיר כתובת חזרה ציבורית ב-HTTPS, או להוסיף אסימון גישה במקום.';

  @override
  String get credentialsUpdateToken => 'עדכון אסימון גישה';

  @override
  String get credentialsAddToken => 'הוספת אסימון גישה';

  @override
  String get credentialsPersonalToken => 'אסימון גישה אישי';

  @override
  String get credentialsPersonalTokenHint => 'יש להדביק אסימון גישה אישי';

  @override
  String get credentialsHostManaged =>
      'החיבור הזה מגיע מאפליקציית השרת או מהסביבה שלו. רק הבעלים של השרת יכולים לשנות אותו שם; עדיין אפשר להוסיף אסימון גישה משלך.';

  @override
  String get credentialsStopWatching => 'הפסקת המעקב';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'תוקף הכניסה ל-Claude Code פג';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'הריצה נעצרה כי החשבון שלה כבר לא עובר אימות. היכנסו שוב ואז נסו שוב את התור.';

  @override
  String get transcriptSignInExpiredTitle => 'תוקף הכניסה לספק פג';

  @override
  String get transcriptSignInExpiredBody =>
      'הריצה נעצרה כי פרטי ההתחברות של הספק כבר לא עובדים. חברו אותו מחדש בהגדרות ← ספקים ואז נסו שוב את התור.';
}
